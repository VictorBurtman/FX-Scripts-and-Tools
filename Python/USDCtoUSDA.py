# ==========================
# ||  USDC to USDA Converter
# ||  Convert a binary USDC file to a human-readable USDA (ASCII) file
# ||  Author: Victor Burtman, 2025
# ||  victorburtman@gmail.com
# ==========================

from pxr import Usd, UsdUtils, Sdf
import sys
import os
import shutil
import tempfile
import re

# ========== CONFIGURATION ==========
# Modify these paths as needed
USDC_FILE_PATH = r"C:\Projects\MyProject\Assets\seahorse\seahorse_anim_mtl_variant.usdc"  # Path to your .usdc file
USDA_OUTPUT_PATH = r"C:\Projects\MyProject\Assets\seahorse\seahorse_anim_mtl_variant.usda"  # Output .usda path
# ===================================


def convert_usdc_to_usda(input_path, output_path):
    """
    Converts a USDC (binary) file to a USDA (ASCII) file.

    Args:
        input_path (str): Path to the input USDC file.
        output_path (str): Path to the output USDA file.

    Returns:
        bool: True if conversion succeeded, False otherwise.
    """
    try:
        # Check that the input file exists
        if not os.path.exists(input_path):
            print(f"❌ Error: Input file not found: '{input_path}'")
            return False

        # Validate the input file extension
        input_ext = os.path.splitext(input_path)[1].lower()
        if input_ext not in ['.usd', '.usdc']:
            print(f"❌ Error: Input file must be a USD file (.usd or .usdc)")
            return False

        # Create the output directory if it does not exist
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
            print(f"📁 Created output directory: {output_dir}")

        print(f"🔄 Converting...")
        print(f"   Input:  {input_path}")
        print(f"   Output: {output_path}")

        # Open the USD stage from the input file
        stage = Usd.Stage.Open(input_path)
        if not stage:
            print(f"❌ Error: Could not open USD file: '{input_path}'")
            return False

        # Export the stage as USDA (ASCII format)
        success = stage.Export(output_path, addSourceFileComment=False)

        if success:
            print(f"✅ Conversion successful!")
            print(f"📄 USDA file created: {output_path}")

            # Display file size comparison
            input_size = os.path.getsize(input_path)
            output_size = os.path.getsize(output_path)
            print(f"📊 Input file size:  {input_size:,} bytes")
            print(f"📊 Output file size: {output_size:,} bytes")

            return True
        else:
            print(f"❌ Error: Export to '{output_path}' failed.")
            return False

    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False


def validate_usd_file(file_path):
    """
    Validates a USD file by opening it and inspecting its root prims.

    Args:
        file_path (str): Path to the USD file.

    Returns:
        bool: True if the file is valid, False otherwise.
    """
    try:
        stage = Usd.Stage.Open(file_path)
        if not stage:
            return False

        print(f"🔍 Validating USD file...")
        print(f"   - Pseudo-root: {stage.GetPseudoRoot()}")
        print(f"   - Root prims:  {len(list(stage.GetPseudoRoot().GetChildren()))}")

        # List the first few root prims
        root_prims = list(stage.GetPseudoRoot().GetChildren())
        if root_prims:
            print(f"   - Prims found:")
            for prim in root_prims[:5]:  # Cap at 5 prims
                print(f"     • {prim.GetName()} ({prim.GetTypeName()})")
            if len(root_prims) > 5:
                print(f"     ... and {len(root_prims) - 5} more")

        return True

    except Exception as e:
        print(f"❌ Validation error: {str(e)}")
        return False


def get_file_format(file_path):
    """
    Determines the format of a USD file by inspecting its header bytes.

    Args:
        file_path (str): Path to the USD file.

    Returns:
        str: 'usdc' for binary, 'usda' for ASCII, 'unknown' if undetermined.
    """
    try:
        with open(file_path, 'rb') as f:
            header = f.read(100)

        # Binary USDC files start with this magic bytes sequence
        if header.startswith(b'PXR-USDC'):
            return 'usdc'
        elif b'#usda' in header or header.startswith(b'#usda'):
            return 'usda'
        else:
            return 'unknown'

    except Exception:
        return 'unknown'


def main():
    """Main function — detects format, validates input, and runs the conversion."""

    print("=" * 60)
    print("🔧 USDC TO USDA CONVERTER")
    print("=" * 60)

    # Guard against unconfigured paths
    if not USDC_FILE_PATH or not USDA_OUTPUT_PATH:
        print("❌ Error: Please set USDC_FILE_PATH and USDA_OUTPUT_PATH in the configuration.")
        return

    # Detect the format of the input file
    input_format = get_file_format(USDC_FILE_PATH)
    print(f"📋 Detected format: {input_format.upper()}")

    # Warn the user if the input is already ASCII
    if input_format == 'usda':
        print("⚠️  Warning: The input file is already in USDA (ASCII) format.")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            print("🛑 Conversion cancelled.")
            return

    # Validate the input file before converting
    if not validate_usd_file(USDC_FILE_PATH):
        print("❌ The input file is not a valid USD file.")
        return

    # Run the conversion
    print("\n" + "-" * 40)
    success = convert_usdc_to_usda(USDC_FILE_PATH, USDA_OUTPUT_PATH)

    if success:
        print("\n🎉 Conversion complete!")

        # Validate the output file
        print("\n" + "-" * 40)
        print("🔍 Validating output file...")
        if validate_usd_file(USDA_OUTPUT_PATH):
            print("✅ Output USDA file is valid.")
        else:
            print("⚠️  Warning: The output file may have issues.")
    else:
        print("\n❌ Conversion failed.")

    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()