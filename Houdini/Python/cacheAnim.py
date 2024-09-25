#Bunch of operations and cache the geometry
#it will look for 2 specific nodes to cache (character and environment in this specific case), but you can adapt it to your own needs :)

import hou

##### ANIM #####
outAnim = hou.node("/obj/anim-export/OUT_anim")
node = outAnim.inputs()[0]

#Create filecache node
fc = node.createOutputNode("filecache", "animCache_FX")
fcPath = fc.path()

#load filecache preset
hscriptExpression = "oppresetload " + fcPath + " CACHE_PERSOS"
hou.hscript(hscriptExpression) 

#Create retime node
rt = fc.createOutputNode("retime", "interpolateAnim_FX")
rtPath = rt.path()

#load retime preset
hscriptExpression = "oppresetload " + rtPath + " CACHE_PERSOS"
hou.hscript(hscriptExpression) 

#Create timeshift node
ts = rt.createOutputNode("timeshift", "clampFrame_FX")
tsPath = ts.path()

#load timeshift preset
hscriptExpression = "oppresetload " + tsPath + " CACHE_PERSOS"
hou.hscript(hscriptExpression)

#get clamp parm
startF = ts.parm("frange1") 
endF = ts.parm("frange2")

#get frame range 
frange = hou.playbar.frameRange()

#set clamp parm
startF.set(frange[0])
endF.set(frange[1])

#connect to null OUT ANIM
null = node.outputs()[0]
null.setInput(0, ts)

#execute cache
execParm = fc.parm("execute")
execParm.pressButton()  

#------------------------------------------

##### LAYOUT #####
outLayout = hou.node("/obj/layout-export/OUT_layout")
node = outLayout.inputs()[0]

#create filecache
fc = node.createOutputNode("filecache", "FX_filecache_LAYOUT")
fcPath = fc.path()

#load the filecache preset
hscriptExpression = "oppresetload " + fcPath + " CACHE_LAYOUT"
hou.hscript(hscriptExpression) 

#create timeshift
ts = fc.createOutputNode("timeshift", "FX_timeshift_LAYOUT")
tsPath = ts.path()
#set frame to current frame
frameParm = ts.parm("frame")
frameParm.deleteAllKeyframes() 

#connect to the null
null = node.outputs()[0]
null.setInput(0, ts)

#execute cache
execParm = fc.parm("execute")
execParm.pressButton()

