title = "Materials to Mtl Switcher"	
try (destroydialog tyPropertiesRollout)catch()
IsTFInstalled = true
try (tyPropMod = tyProperties()) catch (IsTFInstalled = false) -- we test if tyflow is installed

rollout tyPropertiesRollout title height:230 width:200
(
	local Multisub = VRaySwitchMtl ()
	groupbox grp1 pos:[20,5] height:150 width:160
	
	button ok_btn "Create Vray Mtl Switcher" pos:[40,20] width:130 tooltip:"Combine the materials of each selected object into a Vray Mtl Switcher."
	
	Checkbox typrop_chk "Assign tyProperties" checked:on pos:[47,55] tooltip:"Will assign a tyProperties modifiers to each object with a custom float value corresponding to their material location in the multisub"
	radioButtons rdR "Stack modifier position" labels:#("top", "bot") default:1 columns:2 align:#left tooltip:"" pos:[50,80] offsets:#([0,2.5], [5,2.5]) 
	button apply_btn "Apply Mtl Switcher" enabled:false width:110  pos:[47,125] 
	button del_btn "Delete tyProperties" pos:[47,170] width:110 tooltip:"Delete all tyProperties modifiers on selected objects"
	button help_btn "Help"
	
	on ok_btn pressed do
	(
		if $ != undefined then
		(
			mat = #()
			for i in selection do appendIfUnique mat i.material
			if mat.count <= 10 then
			(
				material_list = #()
				Multisub.name = "MatSwitcher_FX_"
				gen_mat = standard()
				gen_mat.name= "no_material_mat"
				
				tyPropMod = tyProperties()
				
				toTen = 10 - mat.count
				
				for i = 1 to (selection.count + toTen) do -- on est sur de faire 10 iterations
				(
					valInArr = i
					current_object = selection[i] 
					if current_object != undefined then
					(
						if current_object.material != undefined then 
						(
							appendIfUnique material_list current_object.material  -- on ajoute le material à la liste si il n'y est pas deja 
							valInArr = findItem material_list current_object.material --on recupere sa position dans l'array pour la donner au typrop
						)
						else 
						(
							append material_list (copy gen_mat)
							valInArr = material_list.count
						)
						if typrop_chk.checked == True do
						(
							
							tyPropModUnique = copy tyPropMod
							tyPropModUnique.name = "tyProperties (MatSwitcher)" ; tyPropModUnique.custFloatChannels.count = 1 ; tyPropModUnique.custFloatVals.count = 1
							tyPropModUnique.custFloatVals[1] = valInArr
							tyPropModUnique.custFloatChannels[1] = "matSwitcher"
							if rdR.state == 1 then (addModifier current_object tyPropModUnique) else (addmodifier current_object tyPropModUnique before:(current_object.modifiers.count))
						)
					)
					else append material_list (copy gen_mat)
				)
				
				--messageBox (material_list.count as string)
				Multisub.switchMtl = material_list
				apply_btn.enabled = True
				extension_message = "\n\ntyProperties modifiers has been assigned to the current selection with a channel named \"matSwitcher\" whose values corresponds to each material object location in the vray material switcher. You can use this channel in tyFlow."
				if typrop_chk.checked == False do extension_message = ""
				messagebox ("A Vray Mtl Switcher containing " + selection.count as string + " sub materials has been created. You can apply it on any object using the \"APPLY Multisub\" button." + extension_message) title:title 
			)
			else (messagebox("Can't create a Vray Material Switcher with more than 10 materials.")title:title)
			
		) else messagebox("Nothing is selected")title:title 
	)
	
	on apply_btn pressed do if $ != undefined then
	(
		$.material = Multisub 
		messagebox("Applied on selection !")title:title
	)
	else messagebox("Nothing is selected")title:title

	on typrop_chk changed arg do rdR.enabled = typrop_chk.checked
	on del_btn pressed do 
	(
		if $ != undefined do 
		(
			numberdel = 0
			for theNode in selection do
			(
				for index = theNode.modifiers.count to 1 by -1 do
				(
					if ((classOf theNode.modifiers[index]) == tyProperties) do (deleteModifier theNode index ; numberdel +=1)
				)
			)
			messagebox (numberdel as string + " tyProperties has been deleted") title:"tyProperties Objects IDs"
			gc()
		)
	)
	
	on help_btn pressed do messagebox("This script will combine the materials of each selected object into a vray material switcher (max 10 materials). It can also assign a tyProperties modifier to each object with a custom float value corresponding to their material location in the mtl switcher. This channel can then be used in tyFlow.")title:title
)
if IsTFInstalled == true then createdialog tyPropertiesRollout else messagebox ("Please install tyFlow plugin in order to use this script")title:title

clearListener()	
