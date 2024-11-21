/*==========================
||  Dupplicate and Link
||  Dupplicate an object and align / link it to every selected object.
||  Author: Victor Burtman 
||  www.victorburtman.com 
==========================*/

title = "Clones on target"
try(destroydialog duppAndLink)catch()
rollout duppAndLink title width:200
(
	local ChoosenObject = undefined 

	pickbutton pckObj "Object to duplicate" width:150 height:30 tooltip:"Pick here the object you want to dupplicate"--filter:<function>] 
	radiobuttons rdbCopyInstance "Mode" labels:#("Copy", "Instance") columns:2 enabled:false
	checkbox chkAlign "Align to selection" checked:true enabled:false
	checkbox chkPos "Position" checked:true enabled:false offset:[15,0]-- pos:[25,50]
	checkbox chkRot "Rotation" checked:true enabled:false offset:[15,0]-- pos:[25,70]
	checkbox chkScale "Scale" checked:true enabled:false offset:[15,0]  --pos:[25,90]

	
	checkbox chkLink "Link to selection" checked:true enabled:false
	checkbox chkName "Get Target Name" checked:false enabled:false
	checkbox chkSel "Select Dupplicates" checked:false enabled:false tooltip:"Will select all the dupplicates objects after the selection"
	button btnOk "Do it !" enabled:false width:80 height:40
	button btnInfos "Infos" 
	
	on pckObj picked arg do 
	(
		ChoosenObject = arg
		pckObj.text = arg.name
		pckObj.tooltip = arg.name
		btnOk.enabled = true
		chkLink.enabled = true
		chkAlign.enabled = true
		chkName.enabled = true
		chkSel.enabled = true
		rdbCopyInstance.enabled = true
		if chkAlign.checked == true do
		(
			chkPos.enabled = true
			chkRot.enabled = true
			chkScale.enabled = true
		)
	)
	
	on chkAlign changed arg do 
	(
		chkPos.enabled = arg
		chkRot.enabled = arg
		chkScale.enabled = arg	
	)

	on btnOk pressed do 
	(
		if selection.count > 0 then
		(
			is_valid_obj = true
			try(buff = ChoosenObject.gbufferchannel) catch(is_valid_obj = false)
			if is_valid_obj == true then
			(

				local sel= #()
				local dupps = #()


				sel = for i in selection collect i 
				for i = 1 to sel.count do 
				(	
					duppObj
					target = sel[i]
					
					if rdbCopyInstance.state == 1 then duppObj = copy ChoosenObject else duppObj = instance ChoosenObject

					if chkAlign.checked == true do 
					(
						if chkPos.checked == true and chkRot.checked == true and chkScale.checked == true then duppObj.transform = target.transform -- align totalement
						else 
						(	
							if chkPos.checked == true do duppObj.pos = target.pos
							if chkRot.checked == true do (duppObj.rotation.x_rotation = target.rotation.x_rotation; duppObj.rotation.y_rotation = target.rotation.y_rotation; duppObj.rotation.z_rotation = target.rotation.z_rotation)
							if chkScale.checked == true do duppObj.scale = target.scale
						)
					)
					if chkLink.checked == true do duppObj.parent = target -- link
					if chkName.checked == true do duppObj.name = target.name + "_" + (formattedprint i format:"03d")
					append dupps duppObj 
				)
				if chkSel.checked == true do
				(
					clearselection()
					select dupps 
				)
				
			)else messagebox ("Can't access the object. Is it deleted ?")title:title
		)
		else messagebox ("Nothing is selected !")title:title
	)
	on btnInfos pressed do messagebox("This script will dupplicate an object and align / link it to every selected object.")title:title
)
createdialog duppAndLink