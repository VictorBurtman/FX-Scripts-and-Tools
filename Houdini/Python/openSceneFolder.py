# ==========================
# ||  Open Scene Folder from Houdini shelf
# ||  Reveal the hip file in windows explorer
# ||  Author: Victor Burtman, 2023
# ||  victorburtman@gmail.com
# ||  https://github.com/VictorBurtman/FX-Scripts-and-Tools
# ==========================

import os
path = hou.hscriptExpression('$HIP')
path = os.path.realpath(path)
os.startfile(path)
#linux version change last line by this :
#os.system('xdg-open "%s"' % path)

