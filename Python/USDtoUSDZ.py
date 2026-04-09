# ==========================
# ||  USD to USDZ Converter
# ||  Convert a USD to USDZ by including all its textures
# ||  Author: Victor Burtman, 2025
# ||  victorburtman@gmail.com
# ||  https://github.com/VictorBurtman/FX-Scripts-and-Tools
# ==========================

from pxr import Usd, UsdUtils, Sdf
import sys
import os
import shutil
import tempfile
import re

# ========== CONFIGURATION ==========
# Modify these paths as needed
USD_FILE_PATH = r"C:\Projects\MyProject\Models\character\USD\Stages\Character_01.usd"  # Path to your .usd file
USDZ_OUTPUT_PATH = r"C:\Projects\MyProject\Models\character\USD\Stages\Output.usdz"    # Output .usdz path (optional)
# ===================================

def find_texture_paths(usd_file):
    """
    Finds all texture paths referenced in a USD file.

    Args:
        usd_file (str): Path to the USD file.

    Returns:
        list: List of found texture file paths.
    """
    texture_paths = []

    try:
        # Read the USD file as plain text to extract asset paths
        with open(usd_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Match asset reference patterns of the form @path/to/texture@
        pattern = r'@([^@]+\.(jpg|jpeg|png|tiff|tga|exr|hdr|bmp))@'
        matches = re.findall(pattern, content, re.IGNORECASE)

        for match in matches:
            texture_path = match[0]  # First capture group contains the path

            # Convert relative paths to absolute paths
            if not os.path.isabs(texture_path):
                texture_path = os.path.join(os.path.dirname(usd_file), texture_path)

            # Normalize the path
            texture_path = os.path.normpath(texture_path)

            if os.path.exists(texture_path):
                texture_paths.append(texture_path)
                print(f"🖼️  Texture found: {texture_path}")
            else:
                print(f"⚠️  Texture not found: {texture_path}")

    except Exception as e:
        print(f"Error while searching for textures: {e}")

    return texture_paths


def create_usdz_with_textures(usd_file, usdz_file):
    """
    Converts a USD file to USDZ, bundling all referenced textures.

    Args:
        usd_file (str): Path to the source .usd file.
        usdz_file (str): Path to the output .usdz file.

    Returns:
        bool: True if conversion succeeded, False otherwise.
    """
    try:
        # Check that the source file exists
        if not os.path.exists(usd_file):
            print(f"Error: File not found: {usd_file}")
            return False

        # Locate all referenced textures
        texture_paths = find_texture_paths(usd_file)

        if texture_paths:
            print(f"📦 Creating USDZ package with {len(texture_paths)} texture(s)")

            # Use a temporary directory to stage the package contents
            with tempfile.TemporaryDirectory() as temp_dir:
                # Copy the USD file into the temp directory
                temp_usd = os.path.join(temp_dir, os.path.basename(usd_file))
                shutil.copy2(usd_file, temp_usd)

                # Copy each texture alongside the USD file
                for texture_path in texture_paths:
                    texture_name = os.path.basename(texture_path)
                    temp_texture = os.path.join(temp_dir, texture_name)
                    shutil.copy2(texture_path, temp_texture)
                    print(f"📋 Copying {texture_name}")

                # Rewrite texture paths in the USD file to use relative references
                update_usd_texture_paths(temp_usd, texture_paths)

                # Package the staged USD file — UsdUtils will pick up adjacent textures automatically
                success = UsdUtils.CreateNewUsdzPackage(temp_usd, usdz_file)
        else:
            print("📦 Creating USDZ package (no textures found)")
            # No textures — straightforward conversion
            success = UsdUtils.CreateNewUsdzPackage(usd_file, usdz_file)

        if success:
            print(f"✓ Success: {usdz_file} created")
            if os.path.exists(usdz_file):
                size = os.path.getsize(usdz_file) / 1024 / 1024
                print(f"  File size: {size:.2f} MB")
            return True
        else:
            print(f"✗ Error: Could not create {usdz_file}")
            return False

    except Exception as e:
        print(f"✗ Conversion error: {e}")
        return False


def update_usd_texture_paths(usd_file, original_texture_paths):
    """
    Rewrites absolute texture paths in a USD file to relative (filename-only) references.

    Args:
        usd_file (str): Path to the USD file to update.
        original_texture_paths (list): List of original absolute texture paths.
    """
    try:
        with open(usd_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Replace each absolute path with just the filename
        for texture_path in original_texture_paths:
            texture_name = os.path.basename(texture_path)

            # Handle backslash-style paths
            old_pattern = f'@{re.escape(texture_path)}@'
            new_pattern = f'@{texture_name}@'
            content = re.sub(old_pattern, new_pattern, content, flags=re.IGNORECASE)

            # Also handle forward-slash normalized paths
            normalized_path = texture_path.replace('\\', '/')
            old_pattern_norm = f'@{re.escape(normalized_path)}@'
            content = re.sub(old_pattern_norm, new_pattern, content, flags=re.IGNORECASE)

        # Write the updated file
        with open(usd_file, 'w', encoding='utf-8') as f:
            f.write(content)

        print("✏️  Texture paths updated to relative references")

    except Exception as e:
        print(f"Error while updating texture paths: {e}")


def create_usdz(usd_file, usdz_file):
    """
    Entry point for the USD-to-USDZ conversion.
    """
    return create_usdz_with_textures(usd_file, usdz_file)


def main():
    """Main function — resolves input/output paths and triggers conversion."""

    # Accept paths from command-line arguments or fall back to the config variables above
    if len(sys.argv) == 3:
        usd_file = sys.argv[1]
        usdz_file = sys.argv[2]
    elif len(sys.argv) == 1:
        usd_file = USD_FILE_PATH

        # Use the configured output path if provided, otherwise derive it from the input filename
        if USDZ_OUTPUT_PATH:
            usdz_file = USDZ_OUTPUT_PATH
        else:
            base_name = os.path.splitext(usd_file)[0]
            usdz_file = base_name + ".usdz"
    else:
        print("Usage: python USDtoUSDZ.py [input.usd] [output.usdz]")
        print("Or set USD_FILE_PATH and USDZ_OUTPUT_PATH directly in the script.")
        print("Example: python USDtoUSDZ.py my_model.usd my_model.usdz")
        sys.exit(1)

    # Guard against an unconfigured input path
    if not usd_file or usd_file == r"C:\path\to\your\file.usd":
        print("❌ Error: Please set USD_FILE_PATH in the script configuration.")
        sys.exit(1)

    # Ensure the output file carries the correct extension
    if not usdz_file.endswith('.usdz'):
        usdz_file += '.usdz'

    print(f"📁 Input:  {usd_file}")
    print(f"📁 Output: {usdz_file}")

    # Run the conversion
    success = create_usdz(usd_file, usdz_file)

    if success:
        print(f"\n🎉 Conversion complete!")
        print(f"Output file: {usdz_file}")
    else:
        print(f"\n❌ Conversion failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()
