Try(DestroyDialog Change_Time_Map) Catch()

rollout Change_Time_Map "Time Map" 
	
(
	local FrameMap = 0 
	local ShowErrors_State = false
	label lbl_Infos "Selected" pos:[10,10]
	label lbl_NbrObj "" pos:[60,10]
	button ok_btn "OK" width:50 height:50 pos:[100,25]
	spinner FrameSpn "Time " pos:[10,40] type:#integer fieldwidth:35 range:[-999,999,0]
	checkbox chkErrors "Show errors" pos:[10,60] tooltip:"This script work on \"standard materials\" : check if you want to know if the diff or opacity map arn't either a bitmap or a mix"
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
	
	on Change_Time_Map open do
	(	
		gc()
		callbacks.removeScripts id:#AutoRefresh
		callbacks.addScript #selectionSetChanged "Change_Time_Map.printSelNumber()" id:#AutoRefresh				
		printSelNumber ()
	)
	on Change_Time_Map close do
	(
		callbacks.removeScripts id:#AutoRefresh
	)
-----------------------------------------------------------------------
	on FrameSpn changed Framing do FrameMap = Framing

	on chkErrors changed Checked do 
	(
		ShowErrors_State = Checked
		print ShowErrors_State
	)
	
	on ok_btn pressed do
	(
		if $ != undefined do
		(
			Materials = for i in selection where classof i.material == standard collect i.material
			print Materials
			for u in Materials do
			(
				dif_map = u.diffusemap
				op_map = u.opacityMap
				
				if classof dif_map == bitmaptexture do dif_map.starttime = FrameMap as time
				if classof op_map == bitmaptexture do op_map.starttime = FrameMap as time
					
				if classof dif_map == mix and classof dif_map.mask == bitmaptexture do dif_map.mask.starttime = FrameMap as time
				if classof op_map == mix and classof op_map.mask == bitmaptexture do op_map.mask.starttime = FrameMap as time
				if ShowErrors_State == true do
				(
					if dif_map != undefined do if classof dif_map != bitmaptexture and classof dif_map != mix do messagebox ("There is a diffuse map in \" " + U as string + "\" but it's not a bitmap or a mix") title:"Oh no :'("
					if op_map != undefined do if classof op_map != bitmaptexture and classof op_map != mix do messagebox ("There is an opacity map in \" " + U as string + "\" but it's not a bitmap or a mix") title:"Oh no :'("
					if op_map == undefined and dif_map == undefined do messagebox ("No diffuse and opacity in \"" + U as string +"\"") title:"Oh no :'("
				)
			)
		)
	)
)

createDialog Change_Time_Map
