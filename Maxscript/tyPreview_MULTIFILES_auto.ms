try(destroydialog MultiPreview) catch()
rollout MultiPreview "Multi-Files Previews" width:400 height:430
(
	button btn_FilesFOLDER "FILES / FOLDER..." width:100 height:30 pos:[13,20]  tooltip:"Choose a folder or choose some max files" 
	checkbox chk_OnlyFX "Only FX" checked:on tooltip:"Only files with \"FX\" in their filename will be treated" pos:[120,35]
	--multilistbox mtl_FilesToPrev
	label lbl_NumberFiles text:"okiii" align:#left style_sunkenedge:true width:35 height:16 pos:[156,203.4] 
	button btn_Clear "Clear List" pos:[13,200] 
	button btn_RemoveSel "Remove sel" pos:[80,200] 
	radioButtons rdR_choosePrevFolder "Export Previews in:" pos:[16,238] width:82 height:30 labels:#("Scenes Folders", "Custom Folder") default:1 columns:1 align:#left tooltip:""
	button btn_PreviewsFolder "..." pos:[16,290] width:60 height:30 enabled:off tooltip:"Choose custom preview export folder"
	button btn_MAKE "MAKE PREVIEWS !" tooltip:"" width:110 height:40 pos:[45,350] enabled:off
	button btn_Help "Help" tooltip:"How does this script works ?"
	
	dotNetControl lv "ListView" pos:[5,80] width:300 height:80
	
	getproperties 
	--fn defColor r g b = ((dotNetClass "System.Drawing.Color").FromArgb r g b)
	--local maxBC = defColor 60 60 60, maxFC = defColor 200 200 200
	
	
 	on MultiPreview open do
	(  
		lv.columns.add ("ProductName", 100)
		--lv.backcolor = maxBC ; lv.forecolor = maxFC
	--	lv.view = (dotNetClass "View").details
	--	lv.HideSelection = true ; lv.height = 200
	--	AddColumns lv #("No.", "Virtual Files")
 	--	PopulateList lv (randomVFGen cnt:30 viritualPathName:@"C:\temp\viritualFileNameCollections\")
		--lv.width =autoResizeColumn lv columns:2
	)
	
	
	on btn_Files pressed do -- créer un bouton pour ca 
	(
		theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog
		theDialog.title = "Select One Or More Files OR select a folder" --set the title
		theDialog.Multiselect = true --allow multiple files to be selected
		theDialog.Filter = "Max(*.max)|*.max" --specify the filter 
		--theDialog.DefaultExt = (maxfilepath)
		result = theDialog.showDialog() --display the dialog, get result into variable
		result.ToString() --when closed, convert the result to string
		result.Equals result.OK --returns TRUE if OK was pressed, FALSE otherwise
		result.Equals result.Cancel --returns TRUE if Cancel was pressed, FALSE otherwise
		theFilenames = theDialog.fileNames --the selected filenames will be returned as an array	
	)
	
on btn_FilesFOLDER pressed do 
(
PathFolder = getSavepath initialDir:(maxfilepath)
searchSubDirs=(dotnetClass "System.IO.SearchOption")
sFiles=dotnetClass "System.IO.Directory"
theFiles=(sFiles.GetFiles  @"D:\RESSOURCES\SCRIPTS\MaxScripts\autoPreview"  "*.max" searchSubDirs.AllDirectories)
if theFiles.count > 0 then 
(
	AddColumns lv #("No.", "Virtual Files")
	print theFiles
	--lv.ListItems = theFiles
	--mtl_FilesToPrev.items = theFiles
	
	
)
)
)
createdialog MultiPreview