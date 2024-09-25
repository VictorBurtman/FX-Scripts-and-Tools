Try(DestroyDialog Map_Time_Color) Catch()
rollout Map_Time_Color "Map control" width:165 height: 270		
(
	local FrameMap = 0 
	local ShowErrors_State = false
	
	local ColorA = color 85 85 85
	local ColorB = color 97 97 97
	local Createmix_State = true
	
	label lbl_Infos "Selected" pos:[10,10]
	label lbl_NbrObj "" pos:[60,10]
	
	button info_btn_1 "?" width:15 height:15 pos:[130,10] tooltip:"infos"
	button ok_btn_1 "OK" width:50 height:50 pos:[100,50] --tooltip:""
	spinner FrameSpn "Time " pos:[10,65] type:#integer fieldwidth:35 range:[-9999,9999,0] 
	checkbox chkErrors "Show errors" pos:[10,85] tooltip:"If you want to be sure that diffuse and opacity chanels contains a mix or a bitmap"
	groupbox grp_time "TIME MAP" width:155 height:75 pos:[5,35]
	
	colorpicker theColor1 "Color 1:" color:[85,85,85] modal:false pos:[13,150]
	colorpicker theColor2 "Color 2:" color:[97,97,97] modal:false pos:[13,175]
	button ok_btn_2 "OK" width:50 height:50 pos:[100,147] --tooltip:""
	progressbar rename_progress width:140 align:#center pos:[12,205]
	checkbox chk_create_mix "create mix" tooltip:"If there is bitmap in diffuse chanel, create a mix with this bitmap as mask" checked:true
	groupbox grp_color "COLOR MAP" width:155 height:120 pos:[5,125]
	
---------------------------------------
	
	fn printSelNumber =
	(
		if $ != undefined then
		(
			for s in selection do 
			(
				count = selection.count
				lbl_NbrObj.text = count as string
			)
		)
		else
		(
			lbl_NbrObj.text = 0 as string
		)
	)	
	on Map_Time_Color open do
	(	
		gc()
		callbacks.removeScripts id:#AutoRefresh
		callbacks.addScript #selectionSetChanged "Map_Time_Color.printSelNumber()" id:#AutoRefresh				
		printSelNumber ()
	)
	on Map_Time_Color close do callbacks.removeScripts id:#AutoRefresh
-----------------------------------------------------------------------
	
	on info_btn_1 pressed do messagebox ("TIME MAP : [Standard mat] Change the bitmaps start frame in diffuse and opacity chanels of selected objects. If there is a mix in theses chanels with a bitmap as mask, it will be applied to it. \n\nCOLOR MAP : [Standard and standard in multisubs] Change all the mix colors of selected objects in diffuses chanels.") title:"About this script"
	
	on FrameSpn changed Framing do FrameMap = Framing

	on chkErrors changed Checked do ShowErrors_State = Checked
	
	on ok_btn_1 pressed do
	(
		if $ != undefined do
		(
			Materials = for i in selection where classof i.material == standard collect i.material
			for u in Materials do
			(
				iter_ = 0
				dif_map = u.diffusemap
				op_map = u.opacityMap
				
				if classof dif_map == bitmaptexture do dif_map.starttime = FrameMap as time
				if classof op_map == bitmaptexture do op_map.starttime = FrameMap as time
					
				if classof dif_map == mix and classof dif_map.mask == bitmaptexture do dif_map.mask.starttime = FrameMap as time
				if classof op_map == mix and classof op_map.mask == bitmaptexture do op_map.mask.starttime = FrameMap as time
					
				if ShowErrors_State == true do
				(
					if dif_map != undefined and classof dif_map != bitmaptexture and classof dif_map != mix do -- Si la diff map n'est ni un mix ni une bitmap
					(
						MapInDiffuse = classof dif_map as string
						messagebox ("There is a " + MapInDiffuse + " in diffuse chanel of \"" + U as string + "\". This script only works on bitmaps and mix.") title:"Oh no :'(" 
					)
					
					-- si dans la diffuse ET dans l'opacity, il y a un mix sans bitmap
					if dif_map != undefined and op_map != undefined do if classof dif_map == mix and classof op_map == mix and classof op_map.mask != bitmaptexture and classof dif_map.mask != bitmaptexture do 
					(
						messagebox ("Diffuse and opacity maps of \"" + U as string + "\" are mix without bitmaps in there mask chanel") title:"Oh no :'("
						iter_ += 1
					)
					
					-- si dans la diffuse OU dans l'opacity, il y a un mix sans bitmap
					if iter_ == 0 do
					(
						if dif_map != undefined do if classof dif_map == mix and classof dif_map.mask != bitmaptexture do messagebox ("The diffuse map of \"" + U as string + "\" is a mix without bitmap in his mask chanel") title:"Oh no :'("
						if op_map != undefined do if classof op_map == mix and classof op_map.mask != bitmaptexture do messagebox ("The opacity map of \"" + U as string + "\" is a mix without bitmap in his mask chanel") title:"Oh no :'("
					)
					
					if op_map != undefined do if classof op_map != bitmaptexture and classof op_map != mix do  -- Si l'opacity map n'est ni un mix ni une bitmap
					(
						MapInOpacity = classof op_map as string
						messagebox ("There is a " + MapInOpacity + " in opacity chanel of \"" + U as string + "\". This script only works on bitmaps and mix.") title:"Oh no :'(" 
					)
					
					if op_map == undefined and dif_map == undefined do messagebox ("No diffuse and opacity in \"" + U as string +"\"") title:"Oh no :'(" -- si il n'y a aucune map dans la diffuse et l'opacity
				)
			)
		)
	)	
	---------------------------------------------------------------
	on theColor1 changed new_color_A do ColorA = new_color_A
	on theColor2 changed new_color_B do ColorB = new_color_B
	on chk_create_mix changed Checked do Createmix_State = Checked
		
	on ok_btn_2 pressed do
	(
		if $ != undefined do
		(
			iter = 0
			local Total_Mix = #()

			for i in selection where classof i.material == standard and classof i.material.diffuseMap == mix do append Total_Mix i.material.diffuseMap -- Ajoute à l'array les mix des standards
				
			Multi_Materials = for i in selection where classof i.material == multimaterial collect i.material -- on recupere tous les multi materiaux
			for o in Multi_Materials do -- on récupere les mix dans les standards reliés aux multis mat
			(
				Liste = o.materialList
				for SubMat in Liste where classof SubMat == standard and classof SubMat.diffuseMap == mix do append Total_Mix SubMat.diffuseMap -- on ajoute les mix dans une collection
			)
			
			if Createmix_State == true do 
			(
				for i in selection where classof i.material == standard and classof i.material.diffuseMap == bitmaptexture do 
				(
					temp = i.material.diffuseMap
					NewMix = Mix ()
					i.material.diffuseMap = NewMix
					i.material.diffuseMap.mask = temp
					append Total_Mix i.material.diffuseMap
				)
			)
			
			for o in Total_Mix do
			(
				o.color1 = ColorA
				o.color2 = ColorB
				----------------------------------------	progress bar -------------------
				iter += 1
				Nombre = Total_Mix.count 
				prog = (100.0*(((iter as float)/Nombre) as float))
				rename_progress.value = (100.0*(((iter as float)/Nombre) as float))
				rename_progress.color = [200 - prog * 2,prog * 2,0]	
				------------------------------------------------------------------------------
			)
			
		)
	)	
	
)
createdialog Map_Time_Color
setFocus Map_Time_Color.FrameSpn