try(destroydialog separateByMatID)catch()
rollout separateByMatID "Sort by Obj/Mat ID" width:200
(
	local titleMessagebox = "Sort by Obj/Mat ID"
	local layerName = "Sorted_By_Obj_ID"
	local ObjNames = "Object_Name_"
	local searchObjType = Editable_Poly
	local functSearch = polyop.getFaceMatID	
	radiobuttons rdbSortType "Sorting:"	labels:#("Object ID", "Material ID")
	spinner IDSpn "Value: " range:[-1000,1000,0] type:#integer fieldwidth: 40 pos:[14,50]
	checkbox chkBaseObj "Base object" checked:on tooltip:"Will ignore the stack modifier when looking for Editable_Mesh and Editable_Poly" enabled:0
	edittext edtLayerName "Layer Name: " text:"Sorted_By_Obj_ID"
	checkbox chkRenameObj "Rename found objs" checked:off 
	edittext edtObjName "Objects Name: " text:"Object_Name_" enabled:off
	checkbox chkSaveFile "Save file after processing" checked:off
	button doItBtn "Do it !" width:100 height:40
	progressbar rename_progress width:185 height:25 align:#center
	button helpBtn "help" tooltip:"How does this script works ?"
	on chkRenameObj changed arg do edtObjName.enabled = arg
	on edtLayerName entered arg do layerName = arg 
	on edtObjName entered arg do ObjNames = arg
	on chkCreateLayer changed arg do edtLayerName.enabled = arg
	
	on rdbSortType changed arg do
	(
		chkBaseObj.enabled = arg - 1
		if arg == 1 then layerName = "Sorted_By_Obj_ID" else layerName = "Sorted_By_Mat_ID" 
		edtLayerName.text = layerName
	)
	on doItBtn pressed do
	(
		if selection.count > 0 then
		(
			doItBtn.text = "Processing..."
			
			--- layer ---
			layername = edtLayerName.text
			exportLayer = LayerManager.getLayerFromName layername
			if exportLayer == undefined do exportLayer = LayerManager.newLayerFromName layername
			-----------
			iter2 = 0
			iter = 0
			arrayToProcess = #()
			
			if rdbSortType.state == 1 then arrayToProcess = for obj in selection collect obj
			else arrayToProcess = for obj in selection where (if chkBaseObj.checked == false then ((classof obj) == Editable_Mesh or (classof obj) == Editable_Poly or (classof obj) == PolyMeshObject) else ((classof obj.baseobject) == Editable_Mesh or (classof obj.baseobject) == Editable_Poly or (classof obj.baseobject) == PolyMeshObject)) collect obj
			
			for obj in arrayToProcess do
			(
				iter2 += 1
				if rdbSortType.state == 1 then compareProcess = (obj.gbufferchannel) else (if (classof obj) == Editable_Mesh then functSearch = getFaceMatID else functSearch = polyop.getFaceMatID ; compareProcess = (functSearch obj 1))
				if compareProcess == IDSpn.value do (iter +=1;numberFormat = formattedprint iter format:"03d"; if chkRenameObj.checked == true do obj.name = (ObjNames + numberFormat as string);exportLayer.addnode obj)
				
				----------------------------------------	progress bar -------------------
				prog = (100.0*(((iter2 as float)/arrayToProcess.count) as float))
				rename_progress.value = prog
				rename_progress.color = [200 - prog * 2,prog * 2,0]	
				------------------------------------------------------------------------------		
			)
			doItBtn.text = "Do it !"
			gc()
			if chkSaveFile.checked == true do saveMaxFile (maxfilepath + maxfilename)
			
			messagebox ("Done ! " + iter as string + " objets found !") title:titleMessagebox
			
		) else messagebox("Nothing is Selected")title:titleMessagebox
	)
	on helpBtn pressed do messagebox ("Compare the Object ID of each selected object or the material ID of the first face of each selected object (Editable Mesh or Editable Poly) to the chosen value. If both values are matching, the object is moved in a new layer.") title:titleMessagebox
)
createdialog separateByMatID 