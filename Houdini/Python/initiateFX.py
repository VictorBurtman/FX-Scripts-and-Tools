
### Will merge animated geometry and environnement in your context ###
### EXECUTE IT IN A HOUDINI PYTHON SOP NODE ###
### feel free to use it and adapt it to your own needs###

### GET CURRENT CONTEXT ###
desktop = hou.ui.curDesktop()
pane = desktop.paneTabUnderCursor()
current_context = pane.pwd()

### CREATE OBJECT MERGE ANIM
animMerge = current_context.createNode('object_merge')
animMerge.setName("ANIM")
rouge = hou.Color(1,0,0)
animMerge.setColor(rouge) 
pos = (0,0) 
animMerge.setPosition(pos)
outAnimPath = "/obj/anim-export/OUT_anim"
path = animMerge.parm("objpath1")
path.set(outAnimPath) 

### CREATE OBJECT MERGE LAYOUT
layoutMerge = current_context.createNode('object_merge')
layoutMerge.setName("LAYOUT")
layoutMerge.setColor(rouge) 
pos = (4,0) 
layoutMerge.setPosition(pos)
outLayoutPath = "/obj/layout-export/OUT_layout"
path = layoutMerge.parm("objpath1")
path.set(outLayoutPath) 

#CREATE NULL OUTPUT NODE
noir = hou.Color(0,0,0)
nl = animMerge.createOutputNode("null", "OUT_FX_")
nl.setColor(noir)
pos = (0,-5) 
nl.setPosition(pos)  

#CREATE CONVERT ANIM
convertAnim = animMerge.createOutputNode("convert", "convertAnim")
pos = (-2,-2) 
convertAnim.setPosition(pos)

#CREATE CONVERT LAYOUT
convertLayout = layoutMerge.createOutputNode("convert", "convertLayout")
pos = (4,-2) 
convertLayout.setPosition(pos)
 
#CREATE BLAST ANIM
blastAnim = convertAnim.createOutputNode("blast", "blastAnim")
pos = (-2,-3) 
blastAnim.setPosition(pos)
blPath = blastAnim.path()
#load blast preset
hscriptExpression = "oppresetload " + blPath + " blastPath"
hou.hscript(hscriptExpression)
  
#CREATE BLAST LAYOUT
blastLayout = convertLayout.createOutputNode("blast", "blastLayout")
pos = (4,-3) 
blastLayout.setPosition(pos)
blPath = blastLayout.path()
#load blast preset
hscriptExpression = "oppresetload " + blPath + " blastPath"
hou.hscript(hscriptExpression)