gc()
title = "tyCache Control"
try(DestroyDialog tcControl) catch()

Global selOnly = true 
rollout tcControl title height:550 width:260
(
	checkbox selOnlyChk "SELECTED ONLY" checked:on tooltip:"Checked : apply modifications to the selected tyCaches.\n\nUnchecked : apply modifications to all tyCaches in the scene."
	button helpBtn "Help" pos:[200,05] height:15
	subrollout displayParam "Display" 
	on selOnlyChk changed arg do (selOnly = arg)
	on helpBtn pressed do messageBox("This script will allow you to control your tyCache objects.\n\nYou can modify the display, render and timing parameters separately.\n\nMost of the settings are the same as for tyCache, so you can refer to the documentation available on the tyFlow website.\n\nFor the additional parameters there are tooltips to help you, do not hesitate to use it.\n\nCreated by Victor Burtman. If you want to submit a bug or a suggestion, please send an email to victorburtman@gmail.com")title:title
)

rollout tyCachesInScene "tyCaches List"
(
	multiListBox mlb "tyCaches in scene"
	button refreshBtn "Refresh" pos:[20,165]
	
	button selectAll "Sel. All" pos:[80,165] tooltip:"Select all items in the list"
	button selectBtn "Sel. in Scene" pos:[130,165] tooltip:"Select in scene the selected items in the list"
	local tyCachesList = #()
	fn refreshList listbox bool =
	(
		if bool == true do (messageBox("tyCache(s) might have been deleted. Automatic refresh of the list.")title:title)
		
		tyCachesList = for tc in objects where classof tc.baseObject == tyCache collect tc
		listbox.items = for tc in tyCachesList collect tc.name
		listbox.text = "tyCaches in scene : " + tyCachesList.count as string
	)
	
	on tyCachesInScene open do refreshList mlb false-- Collect all tyCaches in the list when we open the script
	
	on refreshBtn pressed do refreshList mlb false -- Collect all tyCaches in the list when we refresh the list
	
	on mlb rightClick do mlb.selection = #() -- Clear selection when right click
	
	on mlb doubleClicked arg do -- Select item in scene when double clicked
	(
		try(select tyCachesList[arg]) 
		catch (refreshList mlb true)
	)
	
	on selectAll pressed do (mlb.selection = for i = 1 to mlb.items.count collect i) -- Select all items in list
	
	on selectBtn pressed do -- Select in scene the selected items in list
	(
		toSelect = #()
		for i in mlb.selection do
		(
			for o = 1 to tyCachesList.count do
			(
				if o == i do append toSelect tyCachesList[o]
			)
		)
		try(select toSelect) 
		catch (refreshList mlb true)
	)
) 

rollout displayParameters "Display" 
(
	groupbox grp_1 "Display as" pos:[10,10] height:370 width:200 
	radiobuttons displayTypeRdb pos:[20,40] labels:#("Meshes", "Bounding Box") columns:2 default:1 offsets:#([0,0],[-11,0]) tooltip:"" 
	checkbox simplifyMeshesChk "Simplify meshes" pos:[20,75] checked:off tooltip:""
	spinner MaxFacesSpn "Max faces:" range:[1,10000000000,10000] pos:[35,100] type:#integer fieldWidth:40 enabled:off
	spinner DisplayPercentSpn "Particles Display %: " range:[0,100,100] pos:[20,130] type:#float fieldWidth:40 enabled:on
	checkbox ptcAsDotsChk "Particles as dots"pos:[20,155] checked:off 
	
	groupbox grp_2 "tyCache Elements (to render)" pos:[20,180] height:50 width:180 
	checkbox loadPtcChk "Particles" checked:on pos:[30,205]
	checkbox loadMeshesChk "Meshes" checked:on pos:[110,205]
	checkbox useGpuChk "Use GPU Instancing" pos:[20,240] checked:on tooltip:""
	checkbox ignoreUvwChk "Ignore UVW Over." pos:[20,260] checked:on tooltip:""
	label coordLbl "Coordinates: " pos:[20,295]
	radiobuttons coordRdb pos:[90,295] labels:#("Local", "World") columns:3 default:1 
	checkbox keepFrameChk "Keep frames in RAM" pos:[20,325] checked:on 
	checkbox showIconChk "Show icon(s)" pos:[20,355] checked:on tooltip:""
	
	button newSeqBtn "Sequence..." pos:[60,390] width:100 height:20 tooltip:"You can choose a new tyCache sequence"
	
	button applyDisplayBtn "Apply" pos:[60,420] width:100 height:40
	
	local newSeqPath = undefined
	
	on simplifyMeshesChk changed arg do MaxFacesSpn.enabled = arg

	on useGpuChk changed arg do ignoreUvwChk.enabled = arg
	
	on newSeqBtn pressed do 
	(
		newSeqPath = getOpenFileName caption: "Choose a file" types:"tyCache File(*.tyc)|*.tyc" -- get the path in a variable
		if newSeqPath != undefined then (newSeqBtn.text = newSeqPath ; newSeqBtn.tooltip = newSeqPath)
		else (newSeqBtn.text = "Sequence..." ; newSeqBtn.tooltip = "You can choose a new tyCache sequence" ; newSeqPath = undefined)
	)
	
	on applyDisplayBtn pressed do 
	(
		---- Get the tyCaches (either selected or every tyCaches in the scene)
		Array_tyCache = #()
		if selOnly == false then for tc in (getClassInstances tyCache) do append Array_tyCache tc else for tc in selection where classof tc.baseobject == tyCache do append Array_tyCache tc
		---------------------------
		
		if Array_tyCache.count > 0 then
		(
			for i in Array_tyCache do 
			(
				i.displayMode = displayTypeRdb.state - 1
				i.displaySimplifyMeshes = simplifyMeshesChk.state
				i.displaySimplifyMeshesMaxFaces = MaxFacesSpn.value
				i.displayPercent = DisplayPercentSpn.value
				i.displayAsDots = ptcAsDotsChk.state
				i.elementsParticles = loadPtcChk.state
				i.elementsMeshes = loadMeshesChk.state
				i.gpuInstancing = useGpuChk.state
				i.ignoreMapping = ignoreUvwChk.state
				i.Coordinates = coordRdb.state - 1
				i.keepInMemory = keepFrameChk.state
				i.showIcon = showIconChk.state
				if newSeqPath != undefined do i.filename = newSeqPath
			)
			displayTempPrompt ("Display modifications applied on " + (Array_tyCache.count as string) + " tyCache(s) !") 10000
			--messagebox ("Display modifications applied on " + (Array_tyCache.count as string) + " tyCache(s) !")title:title 
		)
		else messagebox ("No tyCache to apply modification on")title:title 
	)
)

rollout renderParameters "Render"
(
	groupbox grp_2 "Render as" pos:[10,10] height:145 width:200 
	radiobuttons renderTypeRdb pos:[20,40] labels:#("Meshes", "Instances") columns:2 default:1 offsets:#([0,0],[5,0]) tooltip:"" 
	groupbox grp_3 "Interfaces" pos:[20,65] height:50 width:180 
	checkbox vrayInterfaceChk "Vray" pos:[30,90] checked:on
	checkbox ptcInterfaceChk "Particle" pos:[100, 90] checked:off
	spinner renderPercentSpn "Render %: " range:[0,100,100] pos:[20,130] type:#float fieldWidth:40 enabled:on
	button applyRenderBtn "Apply" width:100 height:40 pos:[60,170]
	
	
	on applyRenderBtn pressed do 
	(
		---- Get the tyCaches (either selected or every tyCaches in the scene)
		Array_tyCache = #()
		if selOnly == false then for tc in (getClassInstances tyCache) do append Array_tyCache tc else for tc in selection where classof tc.baseobject == tyCache do append Array_tyCache tc
		---------------------------
		
		if Array_tyCache.count > 0 then
		(
			for i in Array_tyCache do 
			(
				i.renderMode = renderTypeRdb.state - 1
				i.renderVRayInterface = vrayInterfaceChk.state
				i.particleInterfaceEnabled = ptcInterfaceChk.state
				i.renderpercent = renderPercentSpn.value
			)
			displayTempPrompt ("Render modifications applied on " + (Array_tyCache.count as string) + " tyCache(s) !") 10000
			--messagebox ("Render modifications applied on " + (Array_tyCache.count as string) + " tyCache(s) !")title:title 
		)
		else messagebox ("No tyCache to apply modification on")title:title 
	)
)	

rollout timingParameters "Timing"
(
	groupbox grp_2 "Time" pos:[10,10] height:475 width:200
	checkbox offsetChk "Frame offset:" pos:[20,35] checked:off 
	spinner frameoffsetSpn " " pos:[105,35] type:#integer range:[-10000,10000,0] fieldwidth:38 enabled:false
	dropdownlist typeOffsetDrp "" pos:[160,34] items:#("Set", "Add") selection:1 width:45 enabled:false tooltip:"Control whether the frame offset value will be setted or added to the current value"
	spinner randomOffsetSpn "Random " pos:[20,60] type:#integer range:[0,10000,0] fieldwidth:40 enabled:false tooltip:"Randomise the offset value. By default, the random value can be positive or negative, but you can change that using the drop down list."
	dropdownlist randomiseDrp "" pos:[125,59] items:#("Both", "Positive", "Negative") selection:1 width:60 enabled:false
	checkbox cumulativeOffsetChk "Cumulative offset" pos:[20,89] checked:off enabled:off tooltip:"Multiply the offset value (including the random) by the iteration loop. Exemple : if you set the offset to 10, the first tyCache will have an offset of 10, the second 20, the third 30 etc."
	
	radiobuttons clampRdb "Clamp frame range:" pos:[20,125] labels:#("On", "No change", "Off") default:2 columns:3 offsets:#([0,10], [-16,10], [3,10]) tooltip:""
	radiobuttons rangeTypeRdb "" pos:[20,175] labels:#("Guess From Sequence", "Custom") default:1 columns:1 offsets:#([0,5], [0,10]) enabled:off tooltip:"Guess From Sequence : Will clamp the frame range according to the tyCache sequence duration"
	spinner startSpn "" pos:[85,201] type:#integer range:[-1000000,1000000,0] fieldwidth:38 enabled:off
	spinner endSpn "to " pos:[140,201] type:#integer range:[-1000000,1000000,100] fieldwidth:38 enabled:off
	radiobuttons outOfRangeRdb "Out-of-range" pos:[20,230] labels:#("Hold","Loop", "Blank") default:1 columns:3 offsets:#([0,5], [4,5], [8,5]) enabled:off
	
	groupbox grp_3 "Retimer" pos:[20,290] height:130 width:180 
	
	radiobuttons retimerRdb "" pos:[30,315] labels:#("On", "No change", "Off") default:2 columns:3 offsets:#([0,0], [-16,0], [3,0]) tooltip:""
	checkbox createRetimerKeyChk "Create Start / End keyframes" pos:[30,340] checked:off enabled:off tooltip:"Create two keyframes according to the tyCache sequence duration (start / end)"
	checkbox deletePreviousKeysChk "Delete previous keyframes" pos:[45,360] checked:off enabled:off tooltip:"Delete all retimer keys before creating new ones"
	checkbox speedChk "Speed %: "  pos:[30,390] enabled:false
	spinner speedSpn "" pos:[105,390] type:#float range:[-100000,100000,100] fieldwidth:60 enabled:false
	
	button applyMemoryBtn "Apply" pos:[60,435] width:100 height:40   
	
	local outOfRangeVal = 0

	on offsetChk changed arg do 
	(
		frameoffsetSpn.enabled = arg
		typeOffsetDrp.enabled = arg
		randomOffsetSpn.enabled = arg 
		randomiseDrp.enabled = arg
		cumulativeOffsetChk.enabled = arg
	)
	
	on clampRdb changed arg do
	(
		if arg == 1 then
		(
			outOfRangeRdb.enabled = true
			rangeTypeRdb.enabled = true
			if rangeTypeRdb.state == 2 do (startSpn.enabled = true ; endSpn.enabled = true)
		)
		else
		(
			outOfRangeRdb.enabled = false
			rangeTypeRdb.enabled = false
			startSpn.enabled = false ; endSpn.enabled = false
		)
	)
	
	on rangeTypeRdb changed arg do 
	(
		if arg == 2 then (startSpn.enabled = true ; endSpn.enabled = true)
		else (startSpn.enabled = false ; endSpn.enabled = false)
	)
	
	on startSpn changed arg do if startSpn.value > endSpn.value do endSpn.value = startSpn.value
	on endSpn changed arg do if endSpn.value < startSpn.value do startSpn.value = endSpn.value
		
	on outOfRangeRdb changed arg do outOfRangeVal = arg - 1
	
	on retimerRdb changed arg do 
	(
		if arg != 1 then -- if OFF or NO CHANGE
		(
			createRetimerKeyChk.enabled = false
			deletePreviousKeysChk.enabled = false 
			speedChk.enabled = false
			speedSpn.enabled = false
		)
		else -- if ON
		(
			createRetimerKeyChk.enabled = true
			speedChk.enabled = true
			if createRetimerKeyChk.checked == true do
			(
				deletePreviousKeysChk.enabled = true
			)
			if speedChk.checked == true do
			(
				speedSpn.enabled = true
			)
		)
	)
	on createRetimerKeyChk changed arg do -- CREATE KEYFRAMES
	(
		deletePreviousKeysChk.enabled = arg
		
		if arg == true do
		(
			speedChk.checked = false
			speedSpn.enabled = false
		)
	)
	on speedChk changed arg do -- SPEED 
	(
		speedSpn.enabled = arg
		if arg == true do 
		(
			createRetimerKeyChk.checked = false 
			deletePreviousKeysChk.enabled = false
		)
	)
	
	on applyMemoryBtn pressed do
	(
		---- Get the tyCaches (either selected or every tyCaches in the scene)
		Array_tyCache = #()
		if selOnly == false then for tc in (getClassInstances tyCache) do append Array_tyCache tc else for tc in selection where classof tc.baseobject == tyCache do append Array_tyCache tc
		---------------------------
		
		if Array_tyCache.count > 0 then 
		(
			if offsetChk.state == true or clampRdb.state != 2 or retimerRdb.state != 2 then
			(
				cumulativeIterration = 0
				---- Count For User 
				offsetUserCount = 0
				clampUserCount = 0 
				retimerUserCount = 0
				-------------------------
				for i in Array_tyCache do -- for each tyCache
				(
					minVal = 0
					maxVal = 100
					totalSequenceCount = 1
					cumulativeIterration += 1
					ranOffset = 0
					
					if offsetChk.state == true do -- OFFSET 
					(	
						if randomOffsetSpn.value > 0 then -- If random is superior to 0
						(
							ranOffset = random 0 randomOffsetSpn.value -- Return a positive random value 
							if randomiseDrp.selection == 1 do -- If we want a positive and negative value
							(
								randomChoose = random 0 1
								if randomChoose != 0 do ranOffset = - ranOffset -- there is a change that the value is negative
							)
							if randomiseDrp.selection == 3 do ranOffset = - ranOffset-- if we only want a negative value
						)
						else ranOffset = 0
						
						if cumulativeOffsetChk.state == false do cumulativeIterration = 1
							
						if typeOffsetDrp.selection == 1 then i.frameOffset = (frameoffsetSpn.value + ranOffset) * cumulativeIterration -- SET OFFSET
						else i.frameOffset = i.frameOffset + ((frameoffsetSpn.value + ranOffset) * cumulativeIterration) -- ADD TO OFFSET
						
						offsetUserCount += 1
					)
					
					if clampRdb.state == 1 or createRetimerKeyChk.state == true do ----- evaluate the sequence duration (how many frames)
					(
						if doesfileexist i.filename do
						(
							
							theFiles = getFiles ((getfilenamepath i.filename) + "\\*.tyc") -- get all tyCache files in the folder path
							
							theFiles = for f in theFiles where not matchpattern (getfilenamefile f) pattern:(@"*" + "tyMesh") collect f -- exclude the "tyMesh" file
							
							patternSequence = trimRight (getFilenameFile i.filename) "1234567890" -- GET THE BRUT NAME OF THE FILE (without digits)
							patternSequence = trimRight patternSequence "tyMesh" -- GET THE BRUT NAME OF THE FILE (without tyMesh) (in case the file used is the tyMesh and not the tyPart)
							if findString patternSequence "tyPart_" == undefined do (patternSequence = patternSequence + "tyPart_") -- If there is no tyPart in the name, we add it

							SequencetyCache = #()
							for a in theFiles do -- compare each brut name file to the pattern and keep them if they correspond
							(
								pattern = substring (getFilenameFile a) 1 ((getFilenameFile a).count - 5) -- remove the 5 last characters ("00000")
								if pattern == patternSequence do append SequencetyCache a 
							)			
							totalSequenceCount = SequencetyCache.count -- we get the total count of the tyCache sequence 

							
							--- Get the min and max frame of the tyCache sequence 
							rx = dotNetClass "System.Text.RegularExpressions.RegEx"
							theMinVal = rx.match (SequencetyCache[1]) "[0-9]{5}"
							theMaxVal = rx.match (SequencetyCache[totalSequenceCount]) "[0-9]{5}"
							minVal = (theMinVal.value) as integer
							maxVal = (theMaxVal.value) as integer
							------- END NUMBERING COUNT PROCESS 
						)
					)
					
					
					if clampRdb.state != 2 do -- CLAMP FRAME RANGE
					(
						clampUserCount += 1
						if clampRdb.state == 1 then 
						(
							i.clampFrameRange = true
							i.outOfRange = outOfRangeVal  -- Out of range
							
							if rangeTypeRdb.state == 2 then (i.clampFrameRangeStart = startSpn.value ; i.clampFrameRangeEnd = endSpn.value)
							else
							(
								if doesfileexist i.filename do
								(
									i.clampFrameRangeStart = minVal
									i.clampFrameRangeEnd = maxVal
								)
							)
							
						)else (i.clampFrameRange = false)
					)
					
					if retimerRdb.state != 2 do -- RETIMER 
					(
						retimerUserCount += 1
						if retimerRdb.state == 1 then -- turn on the retimer
						(
							i.retimerEnable = on 
							if createRetimerKeyChk.state == true do -- Create KeyFrames
							(
								if doesfileexist i.filename do -- if the tyCache sequence exists
								(
									i.retimerMode = 0
									controlFloat = linear_float()
									i.retimerFrame.controller = controlFloat
									if deletePreviousKeysChk.state == true do -- Delete Previously all retimer keys
									(
										deleteKeys controlFloat #allKeys
									)
									
									with animate on -- create retimer keys according to the tyCache sequence 
									(
										at time 0 i.retimerFrame = minVal
										at time (totalSequenceCount - 1) i.retimerFrame = maxVal
									)
								)
							)
							
							if speedChk.state == true do -- Set Speed 
							(
								i.retimerMode = 1
								i.retimerSpeed = speedSpn.value
							)
							
						) else i.retimerEnable = off -- turn off the retimer
					)
				)
				
				UserCountArr = #()	
				append UserCountArr offsetUserCount ; append UserCountArr clampUserCount ; append UserCountArr retimerUserCount
				displayTempPrompt ("Timings modifications applied on " + ((amax UserCountArr) as string) + " tyCache(s) !") 10000
				--messagebox ("Timings modifications applied on " + ((amax UserCountArr) as string) + " tyCache(s) !")title:title 
			)
			else messagebox ("Please choose at least one timing option")title:title 
		)
		else messagebox ("No tyCache to apply modification on")title:title 
	)
	
)

CreateDialog tcControl
AddSubRollout tcControl.displayParam tyCachesInScene rolledUp:false
AddSubRollout tcControl.displayParam displayParameters rolledUp:true
AddSubRollout tcControl.displayParam renderParameters rolledUp:true
AddSubRollout tcControl.displayParam timingParameters rolledUp:true

tcControl.displayParam.height += 500
clearListener()