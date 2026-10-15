"""Export the generated PrepFX artwork to Max BMP/alpha strips, PNG and ICO.

Only resizing and file-format conversion; the generated design/alpha is retained.
Requires Pillow: python -m pip install Pillow
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent


def export():
    source = Image.open(ROOT / "assets" / "prepfx-source.png").convert("RGBA")
    destination = ROOT / "package" / "icons"
    for size in (16, 24):
        icon = source.resize((size, size), Image.Resampling.LANCZOS)
        # 3ds Max uses straight RGB plus a separate 8-bit alpha bitmap.
        icon.convert("RGB").save(destination / ("prepfx_%di.bmp" % size))
        icon.getchannel("A").convert("RGB").save(destination / ("prepfx_%da.bmp" % size))
    logo = source.resize((256, 256), Image.Resampling.LANCZOS)
    logo.save(destination / "prepfx_logo_square.png")
    logo.save(destination / "prepfx_icon.ico", sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])


if __name__ == "__main__":
    export()
