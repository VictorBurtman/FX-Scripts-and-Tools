clearListener()
gc()
title = "Export tyFlows"
try(DestroyDialog tyFlowExport) catch()

tfs = #() -- tyFlows in the scene
selectedTfs = #() -- tyFlows selected in the list

--for i in objects where classof i.baseObject == tyFlow do append tfs i
	
modes = #(#("Objects","none","none","exportObjects"),#("PRT",".prt","PRTFilename","exportPRT"),#("tyCache",".tyc","tyCacheFilename","exportTyCache"),#("Alembic Point Cloud",".abc","alembicFilename","exportAlembic_PC"),#("Alembic Mesh",".abc","alembicMeshFilename","exportAlembic_Mesh"),#("VRay Proxy",".vrmesh", "vrmeshFilename","exportVRay"),#("tyCache Splines",".tyc","tyCacheFilename","exportTyCache"))	

rollout tyFlowExport title height:540 width:260
(
	multiListBox mlb "tyFlow(s) in scene"
	button refreshBtn "Refresh" pos:[20,165]
	
	button helpBtn "Help" pos:[200,05] height:15
	button selectAll "Sel. All" pos:[80,165] tooltip:"Select all items in the list"
	button selectBtn "Sel. in Scene" pos:[130,165] tooltip:"Select in scene the selected items in the list"
	subrollout displayParam "Display" 
	

	fn refreshList listbox bool =
	(
		tfs = #()
		if bool == true do (messageBox("tyCache(s) might have been deleted. Automatic refresh of the list.")title:title)
		
		tfs = for tf in objects where classof tf.baseObject == tyFlow collect tf
		--for tf in tfs do append tfs tf
		listbox.items = for tf in tfs collect tf.name
		listbox.text = "tyFlows in scene : " + tfs.count as string
	)
	
	on tyFlowExport open do refreshList mlb false
		
	on refreshBtn pressed do 
	(
		refreshList mlb false
		mlb.selection = #()
		selectedTfs = #()
	)
		
	on selectAll pressed do 
	(
		selectedTfs = #()
		mlb.selection = for i = 1 to mlb.items.count collect i
		selectedTfs = tfs
			
	) -- Select all items in list
	
	
	on mlb selectionEnd do 
	(
		refreshList mlb false
		selectedTfs = #()
		for i in mlb.selection do
		(
			for o = 1 to tfs.count do
			(
				if o == i do append selectedTfs tfs[o]
			)
		)
	)
	
	on mlb rightClick do 
	(
		mlb.selection = #()
		selectedTfs = #()
	)
	on mlb doubleClicked arg do 
	(
		try(select selectedTfs) 
		catch (refreshList mlb true)
	)
	
	on selectBtn pressed do -- Select in scene the selected items in list
	(
		try(select selectedTfs) 
		catch (refreshList mlb true)
	)
	
	on helpBtn pressed do 
	(
		messagebox("This script allows you to add Export Particles operators in multiples tyFlows.\nIt also allows to batch the exports.\n\nCreated by Victor Burtman")title:title
	)
	
)

rollout createExport "CREATE OPERATORS" 
(
	checkbox conditionChk "Only if no Export Operator is found" checked:true tooltip:"Only add an Export Particles operator in the flows that don't already have one"
	dropdownlist exportTypeDrp "" width:130 enabled:True pos:[12,30]
	radiobuttons pathRdb "Export Path" labels:#("Scene Folder", "Custom Path") columns:1 default:1 offsets:#([0,3], [0,7])  pos:[13,60]
	button pathBtn "Export Folder..." width:100 height:20 enabled:false tooltip:"" pos:[115,95]
	
	button createExportOperator "Create Export Operators" width:200 height:50 pos:[12,130] 
	
	local folder = maxfilepath
	
	on createExport open do 
	(
		tmp = for i in modes collect i[1]
		exportTypeDrp.items = tmp
		exportTypeDrp.selection = 3
	)
		
	on pathRdb changed state do
	(
		state = state as integer -1 
		pathBtn.enabled = state
	)
	

	on pathBtn pressed do 
	(
		folder = getSavepath initialDir:maxfilepath
		if folder != "" and folder != undefined then
		(
			pathBtn.text = folder
			pathBtn.tooltip = folder
		)
		else
		(
			pathBtn.text = "Export Folder..."
			pathBtn.tooltip = ""
		)
	)
	
	on exportTypeDrp selected state do
	(
		if exportTypeDrp.selection == 1 then 
		(
			pathRdb.enabled = false 
			pathBtn.enabled = false 
		)
		else 
		(
			pathRdb.enabled = True
			if pathRdb.state == 1 then pathBtn.enabled = off else pathBtn.enabled = on
		)
	)
	
	on createExportOperator pressed do
	(
		count = 0
		check = true
		if selectedTfs.count > 0 then
		(
			if maxfilepath == "" and pathRdb.state == 1 do
			(
				check = queryBox ("Scene file is not saved, export path won't be complete. Continue ?") title:title
			)
			
			if check == true do
			(
				for i in selectedTfs do -- for each tyFlow
				(
					exportExist = 0
					mustCreate = True
					
					-- looking for an export particles
					pnames = getpropnames i
					for properties in pnames do 
					(
						p = getproperty i properties
						if (classof p == tyEvent) do 
						(
							opnames = getpropnames p
							for o in opnames where (o == #Export_Particles) do 
							(
								exportExist += 1 
								break
							)
							if exportExist > 0 do break 
						)
					)
					
					if conditionChk.state == true and exportExist > 0 do mustCreate = False
			
					if mustCreate == True do
					(
						--add an export particle operator 
						ev1 = i.addEvent()
						ev1.setName "EXPORT"
						expt = ev1.addOperator "export particles" -1
						
						
						if (modes[exportTypeDrp.selection][2]) !="none" do
						(
							exportPath = folder + "\\" + i.name + "\\export_" + modes[exportTypeDrp.selection][2] -- define export path
							expt.exportMode = exportTypeDrp.selection as integer -1 --define the type of export
							setProperty expt modes[exportTypeDrp.selection][3] exportPath
						)
						count += 1
					)
				)
				messagebox (count as string + " Export Particles Operators has been created")title:title
			)
		)
		else messagebox("Selection is empty")title:title
	)
	
	
)

rollout Export "EXPORT THE PARTICLES" 
(
	radiobuttons whichExportRdb "" labels:#("All Export operators", "Only in \"EXPORT\" events ") columns:1 default:1 offsets:#([0,3], [0,8]) tooltip:"All : Every export particles operators will be evaluated.\n\nOnly in \"EXPORTS\" events : Only Export Particles Operators in events named \"EXPORT\" will be evaluated"
	button exportParticlesBtn "Export Particles" width:200 height:50 pos:[12,57] 
	
	on exportParticlesBtn pressed do
	(
		count = 0
		if selectedTfs.count > 0 then
		(
			for i in selectedTfs do -- for each tyFlow
			(
				pnames = getpropnames i -- get properties names of tyFlows
				for properties in pnames do 
				(
						shouldLaunched = True
					
						isInExportEvent = properties == #EXPORT or properties == #Export
					
						if (whichExportRdb.state == 2 and isInExportEvent == False) do shouldLaunched = False
					
						if shouldLaunched == True do
						(
							p = getproperty i properties
							
							if (classof p == tyEvent) do -- for each event
							(
								opnames = getpropnames p -- get properties names of the event
								for o in opnames where (o == #Export_Particles) do 
								(
									op = getproperty p o -- get the export particles operator
									mode = getProperty op "exportMode" -- get its mode (tyCache, PRT...)
									export = getProperty op modes[mode+1][4] -- retrieve the right function
									export() --execute the export function
									count += 1
								)
					
							)
						)
					)
			)
			messageBox(count as string + " Export Particles have been proceed")title:title
		)
		else messagebox("Selection is empty")title:title
		
		
	)
)

createdialog tyFlowExport
AddSubRollout tyFlowExport.displayParam createExport rolledUp:false
AddSubRollout tyFlowExport.displayParam Export rolledUp:false
tyFlowExport.displayParam.height += 500