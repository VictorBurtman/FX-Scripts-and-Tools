try(destroydialog duppAndLink)catch()
rollout duppAndLink "Duplicate and link"
(
	local ChoosenObject = undefined 
	pickbutton pckObj "Object to dupplicate" width:150 tooltip:"Pick here the object you want to dupplicate"--filter:<function>] 
	checkbox chkLink "Link to selection" checked:true enabled:false
	checkbox chkAlign "Align to selection" checked:true enabled:false
	checkbox chkPos "Position" checked:true enabled:false pos:[25,72]
	checkbox chkRot "Rotation" checked:true enabled:false pos:[25,90]
	checkbox chkScale "Scale" checked:true enabled:false pos:[25,108]
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
				for i in selection do 
				(	
					duppObj = copy ChoosenObject
					if chkAlign.checked == true do 
					(
						if chkPos.checked == true and chkRot.checked == true and chkScale.checked == true then duppObj.transform = i.transform -- align totalement
						else 
						(	
							if chkPos.checked == true do duppObj.pos = i.pos
							if chkRot.checked == true do (duppObj.rotation.x_rotation = i.rotation.x_rotation; duppObj.rotation.y_rotation = i.rotation.y_rotation; duppObj.rotation.z_rotation = i.rotation.z_rotation)
							if chkScale.checked == true do duppObj.scale = i.scale
						)
					)
					if chkLink.checked == true do duppObj.parent = i -- link
				)
			)else messagebox ("Can't access the object. Is it deleted ?")title:"Dupp And Link"
		)
		else messagebox ("Nothing is selected !")title:"Dupp And Link"
	)
	on btnInfos pressed do messagebox("This script will dupplicate an object and align / link it to every selected object.")title:"Dupp And Link"
)
createdialog duppAndLink