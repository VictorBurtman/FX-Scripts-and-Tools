/*==========================
||  Copy Modifiers
||  Copy a modifier present on one object to selected objects.
||  Author: Victor Burtman 
||  www.victorburtman.com 
==========================*/

title = "Copy modifier"
try(destroydialog duppModifier)catch()
rollout duppModifier title
(
	local ChoosenObject = undefined 
	pickbutton pckObj "Pick an object" width:150 tooltip:""--filter:<function>] 
	spinner spnModNumber "Modifier stack: " type:#integer fieldwidth: 30 range:[1,100,1] enabled:false
	label lblmodName "" style_sunkenedge:true height:18 width:150 enabled:off
	radioButtons rdR "Copy the modifier on :" labels:#("top", "bottom") default:1 columns:2 align:#left tooltip:"" enabled:false
	checkbox chkCollapse "Collapse modifiers" checked:false enabled:false tooltip:"The entire stack modifiers will be collapsed"
	checkbox chkSaveFileAfter "Save file after processing" checked:true enabled:false --pos:[25,90]
	button btnOk "Do it !" enabled:false width:80 height:40
	button btnInfos "Infos" 
	
	on pckObj picked arg do 
	(
		ChoosenObject = arg
		pckObj.text = arg.name
		pckObj.tooltip = arg.name
		spnModNumber.enabled = on
		rdR.enabled = on
		lblmodName.enabled = on
		chkCollapse.enabled = on
		chkSaveFileAfter.enabled = on
		btnOk.enabled = true
		lblmodName.text = (ChoosenObject.modifiers[spnModNumber.value]) as string
	)
	
	on spnModNumber changed arg do try(lblmodName.text = (ChoosenObject.modifiers[spnModNumber.value]) as string)catch(messagebox("Can't access the choosen object. Maybe it's deleted ?")title:title)

	on btnOk pressed do 
	(
		numberTreated = 0
		if selection.count > 0 then
		(	
				the_test = true
				try(mod_to_copy = ChoosenObject.modifiers[spnModNumber.value])catch(the_test = false)
				if mod_to_copy != undefined and the_test == true then
				(
					for i in selection do 
					(	
						try(
							if rdR.state == 1 then (addModifier i mod_to_copy) else (addmodifier i mod_to_copy before:(i.modifiers.count))
							if chkCollapse.checked == true do maxOps.CollapseNodeTo i 1 true
							numberTreated += 1	
							)catch()
					)
					if chkSaveFileAfter.checked == true do (saveMaxFile (maxfilepath + maxfilename))
					messagebox("Done! The modifier has been copied on " + numberTreated as string + " objects")title:title
				)
				else messagebox ("No modifier to copy. Please make sure you're selecting a proper modifier and the choosen object is not deleted.")title:title
		)
		else messagebox ("Nothing is selected !")title:title
	)
	on btnInfos pressed do messagebox("Pick an object and use the spinner to navigate threw its modifiers. The choosen modifier will be copied on all your selected objects.")title:title
)
createdialog duppModifier