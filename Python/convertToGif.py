# ==========================
# ||  Video to GIF Converter
# ||  Converts a video file to an animated GIF at its original framerate
# ||  Author: Victor Burtman, 2025
# ||  victorburtman@gmail.com
# ==========================

import imageio
import os
import numpy as np
from PIL import Image

# ========== CONFIGURATION ==========
# Modify these values as needed
PATH_FILE = r"C:\Projects\MyProject\scenes\REF\MDL\my_video.mp4"  # Path to your video file
RESOLUTION_SCALE = 50  # Output resolution as a percentage of the original (e.g. 50 = half size)
# ===================================

# Derive the output GIF path from the input filename
output_gif = os.path.splitext(PATH_FILE)[0] + ".gif"

# Read the video and extract its framerate
video = imageio.get_reader(PATH_FILE)
fps = video.get_meta_data()["fps"]

# Resize each frame according to RESOLUTION_SCALE, then export as an animated GIF
frames = []
for frame in video:
    img = Image.fromarray(frame)
    new_width  = int(img.width  * RESOLUTION_SCALE / 100)
    new_height = int(img.height * RESOLUTION_SCALE / 100)
    img = img.resize((new_width, new_height), Image.LANCZOS)
    frames.append(np.array(img))

imageio.mimsave(output_gif, frames, fps=fps)

print(f"✅ GIF created: {output_gif}")