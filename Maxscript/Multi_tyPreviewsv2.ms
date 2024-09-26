try (destroydialog test)catch()
rollout test "Multi-Files tyPreviews" width:520 height:510
(
	dotNetControl lv "system.windows.forms.listView" pos:[5,5] width:500 height:200
	groupbox grp1 "Add Files" pos:[5,210] width:140 height:290
	groupbox grp2 "Previews Settings" pos:[150,210] width:140 height:200
	
	checkbox chk_Fname " by FileName" checked:off pos:[13,235] align:#right
	edittext SearchNameFile "" pos:[13,255] width:90 height:15 text: "filter name" tooltip:"Search by name" enabled:off
	checkbox chk_FnameInvert "In" checked:off pos:[108,257] tooltip:"invert this filter" align:#left enabled:off
	
	checkbox chk_FAuthor " by Author" checked:off pos:[13,285] tooltip:"Will need admin privileges in some cases"
	edittext SearchOwnerFile "" pos:[13,305] width:90 height:15 text: "filter author" tooltip:"Search by author" enabled:off
	checkbox chk_FAuthorInvert "In" checked:off pos:[108,307] tooltip:"invert this filter" align:#left enabled:off
	
	checkbox chk_Recursiv "Search in subfolders" checked:on tooltip:"Will recursively look for files into all subfolders (when picking a folder only)" pos:[13,400]
	checkbox chk_max "MAX" checked:on pos:[13,340]
	checkbox chk_xmesh "XMesh" checked:off pos:[58,340]
	checkbox chk_fbx "FBX" checked:off pos:[13,360]
	checkbox chk_obj "OBJ" checked:off pos:[58,360]
	checkbox chk_ABC "ABC" checked:off pos:[13,380]
	checkbox chk_tyCache "tyCache" checked:off pos:[58,380] enabled:on
	
	button btnChooseFolder "FOLDER..." width:100 height:30 pos:[13,425]  tooltip:"Import files into a folder, using the filters options above" 
	button btnChooseFiles "FILES..." width:100 height:30 pos:[13,460] tooltip:"Import specific files" 

	button btn_Clear "Clear List" pos:[310,215] 
	button btn_RemoveSel "Remove sel" pos:[375,215] 
	label lbl_NumberFiles " 0" align:#left style_sunkenedge:true width:45 height:20 pos:[455,215] 
	radioButtons rdR_choosePrevFolder "Save in:" pos:[165,235] width:82 height:30 labels:#("Files Location(s)", "Custom Location") default:1 columns:1 align:#left tooltip:"" offsets:#([0,5], [0,10]) 
	button btn_PreviewsFolder "..." pos:[178,298] width:90 height:20 enabled:off tooltip:"Choose custom preview export folder"
	radioButtons rdR_Resolution "Resolution:" pos:[165,335] width:82 height:30 labels:#("Full", "Half") default:1 columns:2 align:#left tooltip:"" offsets:#([0,5], [10,5]) 
	checkbox chk_play "Play previews" checked:off enabled:on pos:[165,385] tooltip:"Control whether or not the preview file will be opened after export completes"
	
	label lbl_Progress "" align:#left style_sunkenedge:false width:125 height:20 pos:[348,435] 
	progressbar rename_progress width:185 height:25 align:#center pos:[318,462]
	
	button btn_MAKE "MAKE PREVIEWS !" tooltip:"" width:155 height:70 pos:[328,270] enabled:off
	button btn_Help "?" tooltip:"How does this script works ?" pos:[490,270] 
	
	fn tyPreviewSettings cam output_path resolution playPr = (tyPreview camera_node:cam appearance_mode:1 appearance_style:0 overlay_frame:true output_filename:output_path resolution_width:(renderWidth/resolution) resolution_height: (renderHeight/resolution) output_openAfterCompletion: playPr)
	fn defColor r g b = ((dotNetClass "System.Drawing.Color").FromArgb r g b)
	local maxBC = defColor 215 215 215
	local maxFC = defColor 5 5 5
	local rows = #()
	local listFiles = #()
	local customFolder = undefined
	local olditems=#()
	local nbrErrors = 0
	local OwnerFilterWord =   "SPIRIT" + "\\" + sysInfo.username -- sysInfo.computername + "\\" + sysInfo.username
	local NameFilterWord = ""
	local Reso = 1
	local filesTypesArray = #()
	local playPrev = chk_play.checked
	
	local filtersSelectFiles = "Max(*.max)|*.max|XMesh(*.xmesh)|*.xmesh|FBX(*.FBX)|*.FBX|Obj(*.obj)|*.obj|Alembic(*.ABC)|*.ABC|tyCache(*.tyc)|*.tyc" --specify the filter 
	local normalfont = dotNetObject "System.Drawing.Font" "Microsoft Sans Serif" 11 \
        (dotNetClass "System.Drawing.FontStyle").Regular (dotNetClass "System.Drawing.GraphicsUnit").Pixel
	local boldfont = dotNetObject "System.Drawing.Font" "Microsoft Sans Serif" 11 \
        (dotNetClass "System.Drawing.FontStyle").Bold (dotNetClass "System.Drawing.GraphicsUnit").Pixel
       	
	fn initLv lv = 
	(
		lv.backcolor = maxBC 
		lv.forecolor = maxFC
		lv.height = 200
		lv.view = (dotNetClass "system.windows.forms.view").details
		lv.FullRowSelect=true
		lv.GridLines=true
		lv.MultiSelect=true
		lv.CheckBoxes=false
		lv.HideSelection = false 
		lv.IsAccessible=true
		lv.LabelEdit=false --true
		Lv.columns.add "No." 50
		Lv.columns.add "FILES" 1000
		lv.AllowColumnReorder = false
	)
	
	fn getFileOwner f = 
	(
		local fileInfo = dotNetObject "System.IO.FileInfo" f
		local fileAccessControl = fileInfo.getAccessControl()
		local NTAccountType = dotNetClass "System.Security.Principal.NTAccount"
		local fileOwner = fileAccessControl.getOwner NTAccountType
		fileOwner.value
	)

	fn getSequencesName f = (return trimRight (getFilenameFile f) "-0123456789,")
	
	on test open do
	(
		SearchOwnerFile.text = OwnerFilterWord -- "SPIRIT" + "\\" + sysInfo.username 
		gc()
		listFiles = #()
		initLv lv
		filesTypesArray = #(".max")
		try -- we test if tyflow is installed
		(
			newtyFlow = tyCache()
			delete newtyFlow
		)
		catch
		(
			DestroyDialog test 
			messagebox("Please install tyFlow plugin in order to use the tyPreview utility")title:"Multi tyPreviews"
		)
		try -- we test if XMeshLoader is installed
		(
			newXMeshLoader = XMeshLoader()
			delete newXMeshLoader
		)
		catch
		(		
			chk_xmesh.enabled = off
			filtersSelectFiles = "Max(*.max)|*.max|FBX(*.FBX)|*.FBX|Obj(*.obj)|*.obj|Alembic(*.ABC)|*.ABC|tyCache(*.tyc)|*.tyc" --specify the filter (without xmesh)
		)
		clearlistener()
	)
	on test close do pushPrompt ""

	on chk_max changed arg do if arg == true then appendifunique filesTypesArray ".max" else if findItem filesTypesArray ".max" != 0 do deleteItem filesTypesArray (findItem filesTypesArray ".max")
	on chk_xmesh changed arg do if arg == true then appendifunique filesTypesArray ".xmesh" else if findItem filesTypesArray ".xmesh" != 0 do deleteItem filesTypesArray (findItem filesTypesArray ".xmesh")
	on chk_fbx changed arg do if arg == true then appendifunique filesTypesArray ".fbx" else if findItem filesTypesArray ".fbx" != 0 do deleteItem filesTypesArray (findItem filesTypesArray ".fbx")
	on chk_obj changed arg do if arg == true then appendifunique filesTypesArray ".obj" else if findItem filesTypesArray ".obj" != 0 do deleteItem filesTypesArray (findItem filesTypesArray ".obj")
	on chk_ABC changed arg do if arg == true then appendifunique filesTypesArray ".ABC" else if findItem filesTypesArray ".ABC" != 0 do deleteItem filesTypesArray (findItem filesTypesArray ".ABC")
	on chk_tyCache changed arg do if arg == true then appendifunique filesTypesArray ".tyc" else if findItem filesTypesArray ".tyc" != 0 do deleteItem filesTypesArray (findItem filesTypesArray ".tyc")
	
	on SearchOwnerFile entered txtName do OwnerFilterWord = txtName
		
	on SearchNameFile entered txtName do NameFilterWord = @"*" + txtName + @"*"
		
	on rdR_Resolution changed arg do if arg == 1 then Reso = 1 else Reso = 2
	
	on chk_Fname changed arg do
	(
		SearchNameFile.enabled = arg
		chk_FnameInvert.enabled = arg
	)
	
	on chk_FAuthor changed arg do
	(
		SearchOwnerFile.enabled = arg
		chk_FAuthorInvert.enabled = arg
	)
	
	on btnChooseFiles pressed do -- user choose files
	(
		theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog
		theDialog.title = "Select One Or More Files" --set the title
		theDialog.Multiselect = true --allow multiple files to be selected
		theDialog.Filter = filtersSelectFiles
		result = theDialog.showDialog() --display the dialog, get result into variable
		result.ToString() --when closed, convert the result to string
		result.Equals result.OK --returns TRUE if OK was pressed, FALSE otherwise
		result.Equals result.Cancel --returns TRUE if Cancel was pressed, FALSE otherwise 
		theFileNames = theDialog.fileNames --the selected filenames will be returned as an array	
		secureVar = 0
		if chk_Fname.checked == true and NameFilterWord != "" do -- if we filtred names files
		(
			tmp = #()
			if chk_FnameInvert.checked == false then tmp = for i in theFileNames where matchpattern (getfilenamefile i) pattern:NameFilterWord collect i else tmp = for i in theFileNames where not matchpattern (getfilenamefile i) pattern:NameFilterWord collect i
			theFileNames = tmp
		)
		
		if chk_FAuthor.checked == true and OwnerFilterWord != "" do -- if we filtred owner files
		(
			tempFilesSecure = makeUniqueArray theFileNames
			try
			(
				tmp = #()
				if chk_FAuthorInvert.checked == false then tmp = for i in theFileNames where getFileOwner i == OwnerFilterWord collect i else tmp = for i in theFileNames where getFileOwner i != OwnerFilterWord collect i
				theFileNames = tmp
			)
			catch
			(
				if queryBox "The author filter has failed. Maybe it's related to some admin privileges.\nDo you want to add files regardless to the Author filter ?" title:"Multi-Files tyPreviews" beep:true then theFileNames = tempFilesSecure else secureVar += 1
				chk_FAuthor.checked = false
				chk_FAuthorInvert.enabled = false
				SearchOwnerFile.enabled = false
			)
		)
		
		--tyCache
		tempoArraytyMesh = #()
		for i in theFileNames where (getfilenametype i) == ".tyc" and not matchpattern (getfilenamefile i) pattern:(@"*" + "tyMesh" + @"*") do append tempoArraytyMesh i -- tous les .tyc qui n'ont pas tymesh dans leur nom sont ajoutés dans une collection
		if tempoArraytyMesh.count > 0 do 
		(
			SequenceTyCacheNames = #()
			SequencesTyCacheFiles = #()
			for f in tempoArraytyMesh where finditem SequenceTyCacheNames (getSequencesName f) == 0 do
			(
				append SequenceTyCacheNames (getSequencesName f) -- pour le triage
				append SequencesTyCacheFiles f
			)
			nontyCacheTempArr = #()
			
			for t in theFileNames where (getfilenametype t) != ".tyc" do append nontyCacheTempArr t
					
			for sf in SequencesTyCacheFiles do append nontyCacheTempArr sf

			theFileNames = nontyCacheTempArr					
			--for i in tempoArraytyMesh do if findItem theFileNames i != 0 do deleteItem theFileNames (findItem theFileNames i)
		)
		
		
		--XMeshs
		tempoArrayXMesh = #()
		for x in theFileNames where (getfilenametype x) == ".xmesh" do append tempoArrayXMesh x
		if tempoArrayXMesh.count > 0 do -- si des fichiers xmesh sont presents, on les trie pour ne garder qu'un seul fichier xmesh par sequence 
		(
			SequencesNames = #() -- pour le triage
			SequencesFiles = #()
			for f in tempoArrayXMesh where findItem SequencesNames (getSequencesName f) == 0 do
			(
				append SequencesNames (getSequencesName f) -- pour le triage
				append SequencesFiles f
			)
			nonXMeshTempArr = #()
			for t in theFileNames where (getfilenametype t) != ".xmesh" do append nonXMeshTempArr t -- tous les non XMESH sont ajoutés dans l'array
					
			for sf in SequencesFiles do append nonXMeshTempArr sf -- les xmesh retenus sont aussi ajoutés dans l'array

			theFileNames = nonXMeshTempArr	-- l'array principale est reconstruite ici
		)				
		
		if theFileNames.count != 0 and secureVar == 0 then
		(
			btn_RemoveSel.enabled = on
			rename_progress.value = 0 
			rename_progress.color = [30,10,190]
			lbl_Progress.text = "" 
			
			ColorIterTest = 0
			rows = #()
			btn_MAKE.enabled = on
			for o in theFileNames do appendifunique listFiles o
			for i in listFiles do 
			(
				ColorIterTest += 1
				li = dotNetObject "System.Windows.Forms.ListViewItem" (ColorIterTest as string)
				li.UseItemStyleForSubItems = true
								
				colAdd=240+(if (mod ColorIterTest 2)==0 then 10 else -10)
				li.BackColor=li.backcolor.fromARGB colAdd colAdd colAdd
				
				li.subitems.add i
				appendifunique rows li  
			)
			lbl_NumberFiles.text = " " + listFiles.count as string
			lv.items.Clear()
			lv.items.addRange rows
		)
		else if listFiles.count == 0 do btn_MAKE.enabled = off
	)
		
	on btnChooseFolder pressed do -- user choose folder with max files inside
	(
		if filesTypesArray.count > 0 then
		(
			local theFiles = undefined
			PathFolder = getSavepath initialDir:(maxfilepath)
			if PathFolder != undefined do
			(
				lbl_Progress.text = "Searching..."
				theFiles = #()
				secureVar = 0
				
				for b in filesTypesArray do -- faire boucle pour tous les elements dans la list filesTypesArray et faire une variable avec le .type (donc le b de la boucle) et le remplacer dans la variable allmaxfiles
				(
					tempoArr = #()
					AllMaxFiles = PathFolder+ "\\*" + b as string
					if chk_Recursiv.checked == true then tempoArr = Getfiles AllMaxFiles recurse:true
					else tempoArr = (getFiles AllMaxFiles)
					for item in tempoArr do appendifunique theFiles item
				)
				
				if chk_Fname.checked == true and NameFilterWord != "" do -- if we filtred names files
				(
					tmp = #()
					if chk_FnameInvert.checked == false then tmp = for i in theFiles where matchpattern (getfilenamefile i) pattern:NameFilterWord collect i else tmp = for i in theFiles where not matchpattern (getfilenamefile i) pattern:NameFilterWord collect i
					theFiles = tmp
				)

				if chk_FAuthor.checked == true and OwnerFilterWord != "" do -- if we filtred owner files
				(
					tempFilesSecure = makeUniqueArray theFiles
					try
					(
						tmp = #()
						if chk_FAuthorInvert.checked == false then tmp = for i in theFiles where getFileOwner i == OwnerFilterWord collect i else tmp = for i in theFiles where getFileOwner i != OwnerFilterWord collect i
						theFiles = tmp
					)
					catch 
					(
						if queryBox "The author filter has failed. Maybe it's related to some admin privileges.\nDo you want to add files regardless to the Author filter ?" title:"Multi-Files tyPreviews" beep:true then theFiles = tempFilesSecure else secureVar += 1
						chk_FAuthor.checked = false
						chk_FAuthorInvert.enabled = false
						SearchOwnerFile.enabled = false
					)
				)
			
				--tyCache
				tempoArraytyMesh = #()
				for i in theFiles where (getfilenametype i) == ".tyc" and not matchpattern (getfilenamefile i) pattern:(@"*" + "tyMesh" + @"*") do append tempoArraytyMesh i -- tous les .tyc qui n'ont pas tymesh dans leur nom sont ajoutés dans une collection
				if tempoArraytyMesh.count > 0 do 
				(
					SequenceTyCacheNames = #()
					SequencesTyCacheFiles = #()
					for f in tempoArraytyMesh where finditem SequenceTyCacheNames (getSequencesName f) == 0 do
					(
						append SequenceTyCacheNames (getSequencesName f) -- pour le triage
						append SequencesTyCacheFiles f
					)
					nontyCacheTempArr = #()
					
					for t in theFiles where (getfilenametype t) != ".tyc" do append nontyCacheTempArr t
							
					for sf in SequencesTyCacheFiles do append nontyCacheTempArr sf

					theFiles = nontyCacheTempArr					
					--for i in tempoArraytyMesh do if findItem theFileNames i != 0 do deleteItem theFileNames (findItem theFileNames i)
				)
				
				--XMeshs
				tempoArrayXMesh = #()
				for x in theFiles where (getfilenametype x) == ".xmesh" do append tempoArrayXMesh x
				if tempoArrayXMesh.count > 0 do -- si des fichiers xmesh sont presents, on les trie pour ne garder qu'un seul fichier xmesh par sequence 
				(
					SequencesNames = #() -- pour le triage
					SequencesFiles = #()
					for f in tempoArrayXMesh where findItem SequencesNames (getSequencesName f) == 0 do
					(
						append SequencesNames (getSequencesName f) -- pour le triage
						append SequencesFiles f
					)
					
					nonXMeshTempArr = #()
					for t in theFiles where (getfilenametype t) != ".xmesh" do append nonXMeshTempArr t
					for sf in SequencesFiles do append nonXMeshTempArr sf

					theFiles = nonXMeshTempArr					
				)			
				lbl_Progress.text = ""
				if theFiles.count > 0 and secureVar == 0 then 
				(
					btn_RemoveSel.enabled = on
					rename_progress.value = 0 
					rename_progress.color = [30,10,190]
					lbl_Progress.text = "" 
		
					ColorIterTest = 0
					rows = #()
					btn_MAKE.enabled = on
					for o in theFiles do appendifunique listFiles o
					for i in listFiles do 
					(
						ColorIterTest += 1
						li = dotNetObject "ListViewItem"  (ColorIterTest as string)
						li.UseItemStyleForSubItems = true
						
						colAdd=240+(if (mod ColorIterTest 2)==0 then 10 else -10)
						li.BackColor=li.backcolor.fromARGB colAdd colAdd colAdd
						
						li.subitems.add i
						appendifunique rows li  
					)
					lbl_NumberFiles.text = " " + listFiles.count as string
					lv.items.Clear()
					lv.items.addRange rows
				)
				else if listFiles.count == 0 do btn_MAKE.enabled = off
			)
		) 
		else messagebox ("Select at least one type file when selecting a folder")title:"Multi-Files tyPreviews"
	)
	
	on chk_play changed arg do playPrev = arg -- user choose if he wants to play previews
	
	on lv ItemSelectionChanged arg do -- when user select items in list
	(
		for i in olditems do lv.items.item[i].font=normalfont
		a=lv.SelectedItems
		olditems=#()
		for i=0 to (a.count-1) do (j=a.item[i].index; append olditems j;lv.items.item[j].font=boldfont)  
	)	
	
	on btn_Clear pressed do -- user clean the list
	(
		btn_RemoveSel.enabled = on 
		listFiles = #()
		rows = #()
		lv.items.Clear()
		lbl_NumberFiles.text = " 0"
		
		rename_progress.value = 0 
		rename_progress.color = [30,10,190]
		lbl_Progress.text = "" 
	)
	
	on btn_RemoveSel pressed do -- user removes selected items from the list
	(
		if listFiles.count >0 do
		(
			rename_progress.value = 0 
			rename_progress.color = [30,10,190]
			lbl_Progress.text = "" 
			
			pushPrompt ("Removed indices: "+olditems as string)
			for i=olditems.count to 1 by -1 do deleteItem listFiles (olditems[i]+1)
			lv.Clear()
			Lv.columns.add "No." 50
			Lv.columns.add "FILES" 1000
			rows = #()
			ColorIterTest = 0
			for i in listFiles do 
			(
				ColorIterTest += 1
				li = dotNetObject "System.Windows.Forms.ListViewItem" (ColorIterTest as string)
				li.UseItemStyleForSubItems = true
									
				colAdd=240+(if (mod ColorIterTest 2)==0 then 10 else -10)
				li.BackColor=li.backcolor.fromARGB colAdd colAdd colAdd
					
				li.subitems.add i
				appendifunique rows li  
			)
			lbl_NumberFiles.text = " " + listFiles.count as string
			lv.items.Clear()
			lv.items.addRange rows
		)
        olditems=#()
        
	)
	
	on rdR_choosePrevFolder changed arg do -- user choose export preview location
	(
		if arg == 1 then btn_PreviewsFolder.enabled = false
		else btn_PreviewsFolder.enabled = true
	)
	
	on btn_PreviewsFolder pressed do -- user choose folder export preview
	(
		customFolder = getSavepath initialDir:(maxfilepath)
		if customFolder != undefined and isDirectoryWriteable customFolder then
		(
			btn_PreviewsFolder.text = customFolder
			btn_PreviewsFolder.tooltip = customFolder
		)
		else
		(
			btn_PreviewsFolder.text = "..."
			btn_PreviewsFolder.tooltip = ""
			customFolder = undefined
		)
	)
	on btn_PreviewsFolder rightclick do if customFolder != undefined do 
	(
		process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
		process.Start customFolder
	)
		
	on btn_MAKE pressed do -- user run the preview process
	(
		lv.selecteditems.clear()
		lv.Update()
		redMarkArrIndx = #()
		Nombre = listFiles.count
		nbrErrors = 0
		iter = 0
		rename_progress.value = 0 
		rename_progress.color = [30,10,190]
		minor = 0
		iteration = 0
		Canceled = 0
		if rdR_choosePrevFolder.state == 1 or rdR_choosePrevFolder.state == 2 and customFolder != undefined then -- if user has chosen a right location for exporting particle
		(
			clearlistener()
			for i in listFiles do 
			(
				if keyboard.escPressed do -- user can cancel the script (exit the loop)
				(
					if queryBox "Cancel Batch Preview ?" title:"Multi-Files tyPreviews" beep:true do 
					(
						Canceled = 1
						exit
					)
				)
				
				--- listview actualisation
				NombreMin = Nombre - 1 -- it's the listfile.count - 1
				iteration +=1
				lbl_Progress.text = "Progression : " + iteration as string + "/" + listFiles.count as string
				if iteration == 1 then minor = 0 else minor = iteration - 1
				minorminor = minor - 1
				if iteration > 1 do lv.Items.item[minorminor].Selected = false
				lv.EnsureVisible[minor]					
				lv.Items.item[minor].Selected = true
				lv.Focus()
				lv.Update()
				
				-- createpreview name
				if rdR_choosePrevFolder.state == 1 then folPreview =getFilenamePath i else folPreview = customFolder + "\\"
				namePreview = getfilenamefile i + "_preview.mp4"
				ScenePathOutputFile = folPreview + namePreview
				
				-- IMPORT IN MAX AND MAKE PREVIEW
				TypeFile = getFilenameType i
				if TypeFile == ".max" or TypeFile == ".MAX" then -- si c'est une scene max
				(
					callbacks.removeScripts id:#checkTimeCreation
					if (loadMaxFile i useFileUnits:true quiet:true) == true then
					(	
						-- on desactive le print des tyflows presents dans la scène
						tyFlowArray = #()
						try(tyFlowArray = for tfs in (getClassInstances tyFlow) collect tfs) catch()
						for tf in tyFlowArray do tf.printSummary = off
						-- on regarde si il y a des cameras
						Cams = for c in cameras where (superclassof c == camera) collect c
						if Cams.count > 0 then 
						(
							CamChoose = undefined
							if Cams.count == 1 then camChoose = Cams[1] else -- si il n'y a qu'une camera, on prend celle la 
							(
								-- si il y a plusieurs cameras
								pattCrop = @"*" + "crop" + @"*"
								itttt = 0
								for eachCam in Cams where matchpattern eachCam.name pattern:pattCrop do -- on regarde si l'une d'entre elle s'appelle cam crop
								(
									itttt += 1
									camChoose = eachCam -- on la choisit
									exit
								)
								if itttt == 0 do camChoose = Cams[1] -- si aucune ne s'appelle cam crop, on prend la premiere
							)
							tyPreviewSettings camChoose ScenePathOutputFile Reso playPrev
						)
						else 
						(
							viewport.setType #view_persp_user
							max zoomext sel
							viewport.SetRenderLevel #smoothhighlights
							tyPreviewSettings undefined ScenePathOutputFile Reso playPrev
						)
					)
					else 
					(
						print ("Impossible to open the file: " + i as string)
						nbrErrors +=1 
						append redMarkArrIndx iteration
					)
				)
				else -- si ce sont des fichiers
				(
					if doesfileexist i then
					(
						resetMaxFile #noprompt
						typeFileArr = #(".FBX",".fbx",".OBJ",".obj",".ABC",".abc")
						if findItem typeFileArr TypeFile != 0 do
						(
							FBXImporterSetParam "FillTimeline" true 
							ImportFile i #noPrompt
							sliderTime = (animationRange.end as integer/ ticksperframe )
							viewport.setType #view_persp_user
							max zoomext sel
							viewport.SetRenderLevel #smoothhighlights
							tyPreviewSettings undefined ScenePathOutputFile Reso playPrev
						)
						if TypeFile == ".XMESH" or TypeFile == ".xmesh" do
						(
							theXMeshLoader = XMeshLoader()
							theXMeshLoader.viewportSequenceID = 0
							theXMeshLoader.enableViewportMesh = true
							theXMeshLoader.displayMode = 0
							theXMeshLoader.limitToRange = on
							select theXMeshLoader
							theXMeshLoader.renderSequence = i
							
							-------------------------
							SequenceXMESH = #()
							ArrNumberSequence = #()
							patternSequence = trimRight (getFilenameFile i) "-0123456789," -- recupere le nom brut du fichier
							AllFilesXMesh = getFiles ((getfilenamepath i) + "\\*.xmesh") -- recupere tous les fichiers xmesh dans le dossier
							for A in AllFilesXMesh do -- et on garde que ceux qui ont le même nom brut (donc ceux de la meme sequence)
							(
								patternA = trimRight (getFilenameFile A) "0123456789,"
								if patternA == patternSequence do append SequenceXMESH A 
							)
							
							for XM in SequenceXMESH do -- On recupere les numéros de chaque fichier
							(
								rx = dotNetClass "System.Text.RegularExpressions.RegEx"
								if (rx.ismatch (getfilenamefile XM) "-[0-9]{4}") == true then -- si un nombre negatif est trouvé
								(
									matches	= rx.match (getfilenamefile XM) "-[0-9]{4}" -- on ajoute ce nombre
									valueN = matches.value
									append ArrNumberSequence (valueN as integer)
								)
								
								else if (rx.ismatch (getfilenamefile XM) "[0-9]{4}") == true do --sinon si on trouve un nombre positif
								(
									matches	= rx.match (getfilenamefile XM) "[0-9]{4}" -- on ajoute ce nombre
									valueN = matches.value
									append ArrNumberSequence (valueN as integer)
								)
							)
							if (amin ArrNumberSequence) != undefined then minVal = amin ArrNumberSequence as integer else minVal = 0 -- et on regarde le min et le max pour regler la timeline et la lecture du xmesh
							if (amax ArrNumberSequence) != undefined then maxVal = amax ArrNumberSequence as integer else maxVal = 100
								
							theXMeshLoader.rangeFirstFrame = minVal
							theXMeshLoader.rangeLastFrame = maxVal
							firstFrame = theXMeshLoader.rangeFirstFrame
							lastFrame = theXMeshLoader.rangeLastFrame
							myInterval = interval (minVal - 10) (maxVal + 10)
							animationRange = myInterval
							sliderTime = lastFrame / 2
							viewport.setType #view_persp_user
							max zoomext sel
							viewport.SetRenderLevel #smoothhighlights
							
							matLibPath = (getFilenamePath i) + "\\*.mat" -- si une material library existe on l'applique au xmeshloader
							matLibFiles = Getfiles matLibPath
							if matLibFiles.count > 0 do
							(
								if doesfileexist matLibFiles[1] do
								(
									theMatLib = loadTempMaterialLibrary matLibFiles[1]
									if theMatLib != undefined do theXMeshLoader.material = theMatLib[1]
								)
							)
							
							tyPreviewSettings undefined ScenePathOutputFile Reso playPrev
						)
						if TypeFile == ".tyc" do
						(
							newtyCache = tyCache()
							newtyCache.filename = i
							newtyCache.clamp = on
							newtyCache.keepInMemory = off
								
							-------
							SequenceTYCACHE = #()
							ArrNumberSequence2 = #()
							patternSequence = trimRight (getFilenameFile i) "-0123456789," -- recupere le nom brut du fichier
							AllFilesTYCACHE = getFiles ((getfilenamepath i) + "\\*.tyc") -- recupere tous les fichiers tycache dans le dossier
							for A in AllFilesTYCACHE where not matchpattern (getfilenamefile i) pattern:(@"*" + "tyMesh" + @"*") do -- et on garde que ceux qui ont le même nom brut (donc ceux de la meme sequence)
							(
								patternA = trimRight (getFilenameFile A) "-0123456789,"
								if patternA == patternSequence do append SequenceTYCACHE A 
							)
							
							for TC in SequenceTYCACHE do -- On recupere les numéros de chaque fichier
							(
								rx = dotNetClass "System.Text.RegularExpressions.RegEx"
								if (rx.ismatch (getfilenamefile TC) "-[0-9]{5}") == true then -- si un nombre negatif est trouvé
								(
									matches	= rx.match (getfilenamefile TC) "-[0-9]{5}" -- on ajoute ce nombre
									valueN = matches.value
									append ArrNumberSequence2 (valueN as integer)
								)
								else if (rx.ismatch (getfilenamefile TC) "[0-9]{5}") == true do --sinon si on trouve un nombre positif
								(
									matches	= rx.match (getfilenamefile TC) "[0-9]{5}" -- on ajoute ce nombre
									valueN = matches.value
									append ArrNumberSequence2 (valueN as integer)
								)
							)
							
							if (amin ArrNumberSequence2) != undefined then minVal = amin ArrNumberSequence2 as integer else minVal = 0 -- et on regarde le min et le max pour regler la timeline et la lecture du xmesh
							if (amax ArrNumberSequence2) != undefined then maxVal = amax ArrNumberSequence2 as integer else maxVal = 100
							newtyCache.clamp_start = minVal
							newtyCache.clamp_end = maxVal
							myInterval = interval (minVal - 10) (maxVal + 10)
							animationRange = myInterval
							sliderTime = maxVal / 2
							viewport.setType #view_persp_user
							max zoomext sel
							viewport.SetRenderLevel #smoothhighlights
							tyPreviewSettings undefined ScenePathOutputFile Reso playPrev
						)
					)
					else
					(
						print ("Impossible to import the file: " + i as string)
						nbrErrors +=1 
						append redMarkArrIndx iteration
					)
				)
				----------------------------------------	progress bar -------------------
				iter += 1
				prog = (100.0*(((iter as float)/Nombre) as float))
				rename_progress.value = (100.0*(((iter as float)/Nombre) as float))
				rename_progress.color = [200 - prog * 2,prog * 2,0]	
				------------------------------------------------------------------------------					
			)
			prompt = "Multi tyPreviews canceled at " + iteration as string
			if Canceled == 1 do pushPrompt prompt
		
			if nbrErrors > 0 then lbl_Progress.text = "Errors : " + nbrErrors as string + " (red lines)" else lbl_Progress.text = "Errors : " + nbrErrors as string
			if nbrErrors == 0 then btn_RemoveSel.enabled = on else btn_RemoveSel.enabled = off
			-----------------------
			rows = #()
			ColorIterTest2 = 0		
			
			for i in listFiles do -- red marks on the files lines that can't be open
			(
				ColorIterTest2 += 1
				
				ColorR = 255
				ColorG = 170
				ColorB = 150
				
				li = dotNetObject "ListViewItem" (ColorIterTest2 as string)
				li.UseItemStyleForSubItems = true
				
				if findItem redMarkArrIndx ColorIterTest2 == 0 then -- if no errors
				(
					colAdd=240+(if (mod ColorIterTest2 2)==0 then 10 else -10)
					li.BackColor=li.backcolor.fromARGB colAdd colAdd colAdd
				)
				else li.BackColor=li.backcolor.fromARGB ColorR ColorG ColorB -- if errors
						
				li.subitems.add i
				appendifunique rows li  
			)
			lv.items.Clear()
			lv.items.addRange rows
			olditems=#()		
			-------------------------
			gc()
		)
		else messagebox ("Choose an export folder") title:"Multi-Files tyPreviews"
	)
	on btn_Help pressed do messagebox ("! Save your scene first or run this script from an empty scene !\n\nThis script will open successively all the chosen files and make a tyPreview for each one.\n\nSTEP 1 : Clic on \"FILES...\" to choose specifics files and/or \"FOLDER...\" to get all the files into a folder. Do it as many times as you want in order to add all the needed files.\n\nThe \"by FileName\" and \"by Author\" filters will work when picking files or folders. On the other hand, the type files filters (MAX, XMesh, FBX...) will only work when picking a folder (since you can already search for specifics type files in the files explorer button). All the filters option must as well be checked BEFORE searching for files.\n\nSTEP 2 : Choose the previews settings (or leave it by default). You can right clic on the custom folder button to open it in explorer.\n\nSTEP 3 : Clic on \"MAKE PREVIEWS !\" to run the process.\n\n------ Good to know ------\n\ntyPreview will use the first camera found into the max scenes. In case there isn't at least one camera, it will use the active viewport as camera. For others type files, (obj, fbx...) it will simply import them and make a tyPreview of it.\n\nIf a file can't be open, it will be printed out into the maxscript listener and red marked in the listview.\n\nPress the echap keyboard to cancel the script.")title:"Multi-Files tyPreviews - Help"
)
createdialog test