
-- This script allows to create a multimaterial whose every sub contian a texture (the one we choosed previously). If the texture is animated (Coordinates, colors, size, etc.), each sub will fit to a specific animation state
Try(DestroyDialog Collapse_Map_Sub) Catch()
title = "Collapse Map"
rollout Collapse_Map_Sub title width:168 height: 350		
(
	local First_Frame = (animationRange.start as integer)/TicksPerFrame
	local Last_Frame = (animationRange.end as integer)/TicksPerFrame
	
	local choosenmap = undefined 
	local custommap = undefined
	
	local Etat_Diffuse = on
	local Etat_Opacity = off
	local Etat_SecondMapAnim = off
	local Etat_twosided = on	
	local Etat_ShowViewport = on
	local Amount_selfillu = 100
	local ColorA = color 85 85 85
	
	groupbox grp_General "General Settings" height:148 width:155 pos:[5,8]
	groupbox grp_Standard "Material Settings" height:88 width:155 pos:[5,168]
	
	spinner First_Frame_Spn "Frame " pos:[10,35] type:#integer fieldwidth:35 range:[-999,999,animationRange.start] 
	spinner Last_Frame_Spn " to " pos:[90,35] type:#integer fieldwidth:35 range:[-999,999,animationRange.end] 
	checkbox diffuse_chk "Diffuse" pos:[10,60] checked:on
	checkbox opacity_chk "Opacity" pos:[80,60] checked:off
	mapbutton choosemap "<<First Map>>" tooltip:"Select Map" width:120 pos:[20,85]
	mapbutton mbt_custommap "<<Second Map>>" tooltip:"Select a second map (optionnal)" width:120 pos:[20,110] enabled:on
	checkbox chk_secondmapAnim "Second map is animated" tooltip:"Check this if you want your second map to be animated" enabled:off
	checkbox twosidded_chk "2-Sided" pos:[10,188] checked:on
	checkbox showshaded_chk "Show in viewport"  pos:[10,208] checked:on
	Spinner self_illu_spn "Self-illu " pos:[13,231] range:[0,100,100] fieldwidth:40 type:#integer 
	colorpicker theColor1 color:[85,85,85] modal:false pos:[105,229.5] tooltip:"choose diffuse color of the material"
	
	button ok_btn "Proceed" pos:[30,263]enabled:false width:100 height:30
	
	progressbar progress_bar width:140 align:#center pos:[12,303]
	button help_btn "?" tooltip:"help"
	label wait_label "" pos:[117,326]
	
	on First_Frame_Spn changed arg do -- the user enter first frame
	(
		if First_Frame_Spn.value < animationRange.start do First_Frame_Spn.value = animationRange.start
		if First_Frame_Spn.value > animationRange.end do First_Frame_Spn.value = animationRange.end
		if First_Frame_Spn.value > Last_Frame_Spn.value do Last_Frame_Spn.value = First_Frame_Spn.value
		First_Frame =	First_Frame_Spn.value
	)

	on Last_Frame_Spn changed arg do -- the user enter last frame
	(
		if Last_Frame_Spn.value < animationRange.start do Last_Frame_Spn.value = animationRange.start
		if Last_Frame_Spn.value < First_Frame_Spn.value do First_Frame_Spn.value = Last_Frame_Spn.value
		if Last_Frame_Spn.value > animationRange.end do Last_Frame_Spn.value = animationRange.end
		Last_Frame = Last_Frame_Spn.value
	)
	
	on diffuse_chk changed Diff_State do -- quand on coche diffuse
	(
		if Diff_State == true then Etat_Diffuse = on else Etat_Diffuse = off
		if Diff_State == true and opacity_chk.checked == true then 
		(
			mbt_custommap.enabled = off 
			chk_secondmapAnim.enabled = off
		)
		else 
		(
			mbt_custommap.enabled = on 
			if custommap != undefined do chk_secondmapAnim.enabled = on	
		)
	)
	
	on opacity_chk changed Opa_State do -- quand on coche opacity
	(
		if Opa_State == true then Etat_Opacity = on else Etat_Opacity = off
		if Opa_State == true and diffuse_chk.checked == true then 
		(
			mbt_custommap.enabled = off 
			chk_secondmapAnim.enabled = off
		)
		else 
		(
			mbt_custommap.enabled = on
			if custommap != undefined do chk_secondmapAnim.enabled = on
		)
	)
		
	on choosemap picked texmap do -- Quand on choisit la map principale
	(
		choosenmap = texmap
		if superclassof texmap == textureMap then 
		(
			choosemap.text = classof texmap as string
			choosemap.tooltip = classof texmap as string + " will be pluged into the checked chanel"
			ok_btn.enabled = true
		)
		else 
		(
			ok_btn.enabled = false
			messagebox ("Please choose a texture map") title:title
		)
	)
	
	on mbt_custommap picked texmap do -- Quand on choisit la map secondaire
	(
		chk_secondmapAnim.enabled = on
		custommap = texmap
		if superclassof texmap == textureMap then 
		(
			mbt_custommap.text = classof texmap as string
			mbt_custommap.tooltip = classof texmap as string + " will be pluged into the unchecked chanel"
		)
		else 
		(
			chk_secondmapAnim.enabled = off
			ok_btn.enabled = false
			messagebox ("Please choose a texture map") title:title
		)
	)
	
	on chk_secondmapAnim changed State do if State == on then Etat_SecondMapAnim = on else Etat_SecondMapAnim == off	-- si on coche "Second map is animated"
	
	-- material settings 
	on twosidded_chk changed TwoSided_State do if TwoSided_State == true then Etat_twosided = on else Etat_twosided = off
	on showshaded_chk changed ShowShaded_State do if ShowShaded_State == true then Etat_ShowViewport = on else Etat_ShowViewport = off
	on self_illu_spn changed arg do Amount_selfillu = self_illu_spn.value
	on theColor1 changed new_color_A do ColorA = new_color_A	
	------------------------------	
		
	on ok_btn pressed do -- quand on clique sur proceed
	(
		if Etat_Diffuse == on or Etat_Opacity == on then -- on v�rifie que la map principale est assign�e un canal au moins (diff ou opa)
		(
			local submaterial_Array = #()
			
			sliderTime = First_Frame as time
			Multisub = multimaterial ()
			Multisub.name = "Multisub_FX_"
			Multisub.numsubs = Last_Frame as integer - First_Frame as integer
			iter = 0
			
			copy_de_map = copy choosenmap
			deleteKeys copy_de_map #allKeys

			if Etat_SecondMapAnim == on and superclassof custommap == textureMap do
			(				
				copy_de_secondmap = copy custommap
				deleteKeys copy_de_secondmap #allKeys
			)
			
			wait_label.text = ""
			
			for i = First_Frame as integer to Last_Frame as integer do
			(
				sliderTime = i as time
				----- Creation du standard material
				standard_mat = standard ()
				standard_mat.name = "Submat_" + i as string 
				if Etat_twosided == on then standard_mat.twoSided = on else standard_mat.twoSided = off
				if Etat_ShowViewport == on then showTextureMap standard_mat on else showTextureMap standard_mat off
				standard_mat.selfIllumAmount = Amount_selfillu
				standard_mat.diffuse = ColorA
				
				-- map principale
				noise_map = copy copy_de_map
				noise_map.name = classof choosenmap as string + "_" + i as string 
				
				--(map principale)
				-- general coordonnees 
				Try(	noise_map.coords.coordType = choosenmap.coords.coordType) Catch()
				Try(	noise_map.coords.mapChannel = choosenmap.coords.mapChannel) Catch()
				Try(	noise_map.coords.offset = choosenmap.coords.offset) Catch()
				Try(	noise_map.coords.Tiling = choosenmap.coords.Tiling) Catch() 
				Try(	noise_map.coords.angle = choosenmap.coords.angle) Catch()
				Try(	noise_map.coords.blur = choosenmap.coords.blur) Catch()
				Try(	noise_map.coords.blur_Offset = choosenmap.coords.blur_Offset) Catch() 
					
				Try(	noise_map.coords.U_Offset = choosenmap.coords.U_Offset) Catch()
				Try(	noise_map.coords.V_Offset = choosenmap.coords.V_Offset) Catch()
				Try(	noise_map.coords.realWorldScale = choosenmap.coords.realWorldScale) Catch()
				Try(	noise_map.coords.U_Tiling = choosenmap.coords.U_Tiling) Catch()
				Try(	noise_map.coords.V_Tiling = choosenmap.coords.V_Tiling) Catch()
				Try(	noise_map.coords.U_angle = -choosenmap.coords.U_angle) Catch()
				Try(	noise_map.coords.V_angle = choosenmap.coords.V_angle) Catch()
				Try(	noise_map.coords.W_angle = choosenmap.coords.W_angle) Catch()
				Try(	noise_map.direction = choosenmap.direction) Catch()
				Try(	noise_map.ior = choosenmap.ior) Catch()
				Try(	noise_map.mtlIOROverride = choosenmap.mtlIOROverride) Catch()
	
					--pour le noise
				Try(	noise_map.type = choosenmap.type) Catch()
				Try(	noise_map.thresholdHigh = choosenmap.thresholdHigh) Catch()
				Try(	noise_map.thresholdLow = choosenmap.thresholdLow) Catch()
				Try(	noise_map.phase = choosenmap.phase) Catch()
				Try(	noise_map.size = choosenmap.size) Catch()
				Try(	noise_map.color1 = choosenmap.color1) Catch()
				Try(	noise_map.color2 = choosenmap.color2) Catch()
						
					-- pour le cellular
				Try(	noise_map.cellColor = choosenmap.cellColor) Catch() 
				Try(	noise_map.variation = choosenmap.variation) Catch()
				Try(	noise_map.divColor1 = choosenmap.divColor1) Catch()
				Try(	noise_map.divColor2 = choosenmap.divColor2) Catch()
				Try(	noise_map.size = choosenmap.size) Catch()
				Try(	noise_map.spread = choosenmap.spread) Catch()
				Try(	noise_map.smooth = choosenmap.smooth) Catch()
				Try(	noise_map.lowThresh = choosenmap.lowThresh) Catch()
				Try(	noise_map.midThresh = choosenmap.midThresh) Catch()
				Try(	noise_map.highThresh = choosenmap.highThresh) Catch()
				Try(	noise_map.type = choosenmap.type) Catch() 
				Try(	noise_map.fractal = choosenmap.fractal) Catch() 
				Try(	noise_map.iteration = choosenmap.iteration) Catch() 
				Try(	noise_map.adaptive = choosenmap.adaptive) Catch()
					
					--pour le gradient 
				Try(	noise_map.color3 = choosenmap.color3) Catch()
				Try(	noise_map.gradienttype = choosenmap.gradienttype) Catch()
				Try(	noise_map.color2pos = choosenmap.color2pos) Catch()
				Try(	noise_map.noisetype = choosenmap.noisetype) Catch()
				Try(	noise_map.noiseamount = choosenmap.noiseamount) Catch()
				Try(	noise_map.noisesize = choosenmap.noisesize) Catch()
				Try(	noise_map.noisePhase = choosenmap.noisePhase) Catch()
				Try(	noise_map.noiseLevels = choosenmap.noiseLevels) Catch()
				Try(	noise_map.noiseThresholdLow = choosenmap.noiseThresholdLow) Catch()
				Try(	noise_map.noiseThresholdHigh = choosenmap.noiseThresholdHigh) Catch()
				Try(	noise_map.noiseThresholdSmooth = choosenmap.noiseThresholdSmooth) Catch()

					-- autres
				Try(	noise_map.mult_spin = choosenmap.mult_spin) Catch()
				Try(	noise_map.bump_spin = choosenmap.bump_spin) Catch()
				Try(	noise_map.width = choosenmap.width) Catch()
				Try(	noise_map.age1 = choosenmap.age1) Catch()
				Try(	noise_map.age2 = choosenmap.age2) Catch()
				Try(	noise_map.age3 = choosenmap.age3) Catch()
				Try(	noise_map.sharp = choosenmap.sharp) Catch()
				Try(	noise_map.level = choosenmap.level) Catch()
				Try(	noise_map.saturation1 = choosenmap.saturation1) Catch()
				Try(	noise_map.saturation2 = choosenmap.saturation2) Catch()
				Try(	noise_map.Background_Color = choosenmap.Background_Color) Catch()
				Try(	noise_map.blurOffset = choosenmap.blurOffset) Catch()
				Try(	noise_map.near = choosenmap.near) Catch()
				Try(	noise_map.far = choosenmap.far) Catch()
				Try(	noise_map.red = choosenmap.red) Catch()
				Try(	noise_map.green = choosenmap.green) Catch()
				Try(	noise_map.blue = choosenmap.blue) Catch()
				Try(	noise_map.exponent = choosenmap.exponent) Catch()
				Try(	noise_map.base = choosenmap.base) Catch()
				Try(	noise_map.swirl = choosenmap.swirl) Catch()
				Try(	noise_map.Color_Contrast = choosenmap.Color_Contrast) Catch()
				Try(	noise_map.Swirl_Intensity = choosenmap.Swirl_Intensity) Catch()
				Try(	noise_map.Swirl_Amount = choosenmap.Swirl_Amount) Catch()
				Try(	noise_map.Twist = choosenmap.Twist) Catch()
				Try(	noise_map.Constant_Detail = choosenmap.Constant_Detail) Catch()
				Try(	noise_map.Center_Position_X = choosenmap.Center_Position_X) Catch()
				Try(	noise_map.Center_Position_Y = choosenmap.Center_Position_Y) Catch()
				Try(	noise_map.Random_Seed = choosenmap.Random_Seed) Catch()
				Try(	noise_map.numWaveSets = choosenmap.numWaveSets) Catch()
				Try(	noise_map.waveLenMax = choosenmap.waveLenMax) Catch()
				Try(	noise_map.Amplitude = choosenmap.Amplitude) Catch()
				Try(	noise_map.waveRadius = choosenmap.waveRadius) Catch()
				Try(	noise_map.waveLenMin = choosenmap.waveLenMin) Catch()
				Try(	noise_map.mult_spin = choosenmap.mult_spin) Catch()
				Try(	noise_map.crop_u = choosenmap.crop_u) Catch()
				Try(	noise_map.crop_v = choosenmap.crop_v) Catch()
				Try(	noise_map.crop_h = choosenmap.crop_h) Catch()
				Try(	noise_map.crop_w = choosenmap.crop_w) Catch()
				Try(	noise_map.fillcolor = choosenmap.fillcolor) Catch()
				Try(	noise_map.outlinecolor = choosenmap.outlinecolor) Catch()
				Try(	noise_map.count = choosenmap.count) Catch()
				Try(	noise_map.outlinewidth = choosenmap.outlinewidth) Catch()
				Try(	noise_map.bgcolor = choosenmap.bgcolor) Catch()
				Try(	noise_map.manualheight = choosenmap.manualheight) Catch()
				Try(	noise_map.strength = choosenmap.strength) Catch()
				Try(	noise_map.iterations = choosenmap.iterations) Catch()
				Try(	noise_map.solidcolor = choosenmap.solidcolor) Catch()
				
				
				-----------------------------
				if Etat_SecondMapAnim == on and superclassof custommap == textureMap do 
				(
					-- map secondaire
					second_optional_map = copy copy_de_secondmap
					second_optional_map.name = classof custommap as string + "_" + i as string 
					
				--(map secondaire)
				-- general coordonnees 
				Try(	second_optional_map.coords.coordType = custommap.coords.coordType) Catch()
				Try(	second_optional_map.coords.mapChannel = custommap.coords.mapChannel) Catch()
				Try(	second_optional_map.coords.offset = custommap.coords.offset) Catch()
				Try(	second_optional_map.coords.Tiling = custommap.coords.Tiling) Catch() 
				Try(	second_optional_map.coords.angle = custommap.coords.angle) Catch()
				Try(	second_optional_map.coords.blur = custommap.coords.blur) Catch()
				Try(	second_optional_map.coords.blur_Offset = custommap.coords.blur_Offset) Catch() 
					
				Try(	second_optional_map.coords.U_Offset = custommap.coords.U_Offset) Catch()
				Try(	second_optional_map.coords.V_Offset = custommap.coords.V_Offset) Catch()
				Try(	second_optional_map.coords.realWorldScale = custommap.coords.realWorldScale) Catch()
				Try(	second_optional_map.coords.U_Tiling = custommap.coords.U_Tiling) Catch()
				Try(	second_optional_map.coords.V_Tiling = custommap.coords.V_Tiling) Catch()
				Try(	second_optional_map.coords.U_angle = -custommap.coords.U_angle) Catch()
				Try(	second_optional_map.coords.V_angle = custommap.coords.V_angle) Catch()
				Try(	second_optional_map.coords.W_angle = custommap.coords.W_angle) Catch()
				Try(	second_optional_map.direction = custommap.direction) Catch()
				Try(	second_optional_map.ior = custommap.ior) Catch()
				Try(	second_optional_map.mtlIOROverride = custommap.mtlIOROverride) Catch()
	
					--pour le noise
				Try(	second_optional_map.type = custommap.type) Catch()
				Try(	second_optional_map.thresholdHigh = custommap.thresholdHigh) Catch()
				Try(	second_optional_map.thresholdLow = custommap.thresholdLow) Catch()
				Try(	second_optional_map.phase = custommap.phase) Catch()
				Try(	second_optional_map.size = custommap.size) Catch()
				Try(	second_optional_map.color1 = custommap.color1) Catch()
				Try(	second_optional_map.color2 = custommap.color2) Catch()
						
					-- pour le cellular
				Try(	second_optional_map.cellColor = custommap.cellColor) Catch() 
				Try(	second_optional_map.variation = custommap.variation) Catch()
				Try(	second_optional_map.divColor1 = custommap.divColor1) Catch()
				Try(	second_optional_map.divColor2 = custommap.divColor2) Catch()
				Try(	second_optional_map.size = custommap.size) Catch()
				Try(	second_optional_map.spread = custommap.spread) Catch()
				Try(	second_optional_map.smooth = custommap.smooth) Catch()
				Try(	second_optional_map.lowThresh = custommap.lowThresh) Catch()
				Try(	second_optional_map.midThresh = custommap.midThresh) Catch()
				Try(	second_optional_map.highThresh = custommap.highThresh) Catch()
				Try(	second_optional_map.type = custommap.type) Catch() 
				Try(	second_optional_map.fractal = custommap.fractal) Catch() 
				Try(	second_optional_map.iteration = custommap.iteration) Catch() 
				Try(	second_optional_map.adaptive = custommap.adaptive) Catch()
					
					--pour le gradient 
				Try(	second_optional_map.color3 = custommap.color3) Catch()
				Try(	second_optional_map.gradienttype = custommap.gradienttype) Catch()
				Try(	second_optional_map.color2pos = custommap.color2pos) Catch()
				Try(	second_optional_map.noisetype = custommap.noisetype) Catch()
				Try(	second_optional_map.noiseamount = custommap.noiseamount) Catch()
				Try(	second_optional_map.noisesize = custommap.noisesize) Catch()
				Try(	second_optional_map.noisePhase = custommap.noisePhase) Catch()
				Try(	second_optional_map.noiseLevels = custommap.noiseLevels) Catch()
				Try(	second_optional_map.noiseThresholdLow = custommap.noiseThresholdLow) Catch()
				Try(	second_optional_map.noiseThresholdHigh = custommap.noiseThresholdHigh) Catch()
				Try(	second_optional_map.noiseThresholdSmooth = custommap.noiseThresholdSmooth) Catch()

					-- autres
				Try(	second_optional_map.mult_spin = custommap.mult_spin) Catch()
				Try(	second_optional_map.bump_spin = custommap.bump_spin) Catch()
				Try(	second_optional_map.width = custommap.width) Catch()
				Try(	second_optional_map.age1 = custommap.age1) Catch()
				Try(	second_optional_map.age2 = custommap.age2) Catch()
				Try(	second_optional_map.age3 = custommap.age3) Catch()
				Try(	second_optional_map.sharp = custommap.sharp) Catch()
				Try(	second_optional_map.level = custommap.level) Catch()
				Try(	second_optional_map.saturation1 = custommap.saturation1) Catch()
				Try(	second_optional_map.saturation2 = custommap.saturation2) Catch()
				Try(	second_optional_map.Background_Color = custommap.Background_Color) Catch()
				Try(	second_optional_map.blurOffset = custommap.blurOffset) Catch()
				Try(	second_optional_map.near = custommap.near) Catch()
				Try(	second_optional_map.far = custommap.far) Catch()
				Try(	second_optional_map.red = custommap.red) Catch()
				Try(	second_optional_map.green = custommap.green) Catch()
				Try(	second_optional_map.blue = custommap.blue) Catch()
				Try(	second_optional_map.exponent = custommap.exponent) Catch()
				Try(	second_optional_map.base = custommap.base) Catch()
				Try(	second_optional_map.swirl = custommap.swirl) Catch()
				Try(	second_optional_map.Color_Contrast = custommap.Color_Contrast) Catch()
				Try(	second_optional_map.Swirl_Intensity = custommap.Swirl_Intensity) Catch()
				Try(	second_optional_map.Swirl_Amount = custommap.Swirl_Amount) Catch()
				Try(	second_optional_map.Twist = custommap.Twist) Catch()
				Try(	second_optional_map.Constant_Detail = custommap.Constant_Detail) Catch()
				Try(	second_optional_map.Center_Position_X = custommap.Center_Position_X) Catch()
				Try(	second_optional_map.Center_Position_Y = custommap.Center_Position_Y) Catch()
				Try(	second_optional_map.Random_Seed = custommap.Random_Seed) Catch()
				Try(	second_optional_map.numWaveSets = custommap.numWaveSets) Catch()
				Try(	second_optional_map.waveLenMax = custommap.waveLenMax) Catch()
				Try(	second_optional_map.Amplitude = custommap.Amplitude) Catch()
				Try(	second_optional_map.waveRadius = custommap.waveRadius) Catch()
				Try(	second_optional_map.waveLenMin = custommap.waveLenMin) Catch()
				Try(	second_optional_map.mult_spin = custommap.mult_spin) Catch()
				Try(	second_optional_map.crop_u = custommap.crop_u) Catch()
				Try(	second_optional_map.crop_v = custommap.crop_v) Catch()
				Try(	second_optional_map.crop_h = custommap.crop_h) Catch()
				Try(	second_optional_map.crop_w = custommap.crop_w) Catch()
				Try(	second_optional_map.fillcolor = custommap.fillcolor) Catch()
				Try(	second_optional_map.outlinecolor = custommap.outlinecolor) Catch()
				Try(	second_optional_map.count = custommap.count) Catch()
				Try(	second_optional_map.outlinewidth = custommap.outlinewidth) Catch()
				Try(	second_optional_map.bgcolor = custommap.bgcolor) Catch()
				Try(	second_optional_map.manualheight = custommap.manualheight) Catch()
				Try(	second_optional_map.strength = custommap.strength) Catch()
				Try(	second_optional_map.iterations = custommap.iterations) Catch()
				Try(	second_optional_map.solidcolor = custommap.solidcolor) Catch()
				)
				-----------------------------
					
				if Etat_Diffuse == on do standard_mat.diffusemap = noise_map -- Map principale est plug�e en Diff
				if Etat_Opacity == on do standard_mat.opacityMap = noise_map -- Map principale est plug�e en Opacit�
					
				if Etat_Diffuse == off or Etat_Opacity == off and superclassof custommap == textureMap do -- Si on a selectionn� qu'un canal pour la map principale et qu'une deuxi�me map a �t� choisie, elle sera assign�e � l'autre canal
				(
					-- ou bien
					if Etat_Diffuse == off and Etat_SecondMapAnim == off do standard_mat.diffusemap = custommap -- Map secondaire plug�e en Diff
					if Etat_Opacity == off and Etat_SecondMapAnim == off do standard_mat.opacityMap = custommap -- Map secondaire plug�e en Opacit�
					
					--ou bien
					if Etat_Diffuse == off and Etat_SecondMapAnim == on do standard_mat.diffusemap = second_optional_map -- Map Secondaire ANIMEE plug�e en Diff
					if Etat_Opacity == off and Etat_SecondMapAnim == on do standard_mat.opacityMap = second_optional_map -- Map Secondaire ANIMEE plug�e en Opacit�
				)	
				append submaterial_Array standard_mat
					
				----------------------------------------	progress bar -------------------
				iter += 1
				Nombre = Multisub.numsubs 
				prog = (100.0*(((iter as float)/Nombre) as float))
				progress_bar.value = (100.0*(((iter as float)/Nombre) as float))
				progress_bar.color = [80 - prog * 2,prog * 2,0]	
				------------------------------------------------------------------------------
			)
			
			Multisub.materialList = submaterial_Array
			sphere_temoin = sphere ()
			sphere_temoin.name = "Sphere_Multimaterial_"
			sphere_temoin.renderable = off
			sphere_temoin.material = Multisub
			addmodifier sphere_temoin (Materialmodifier())
			
			sliderTime = 0f
			local nombre_frame = Last_Frame as integer - First_Frame as integer
				
			with animate on
			(
				ind = 1
				for i = 1 to nombre_frame do
				(
					sphere_temoin.modifiers[#Material].materialID = ind
					ind += 1
					sliderTime += 1
					wait_label.text = "Wait..."					
				)
			)
			
			sliderTime = 0f
			select sphere_temoin
			wait_label.text = "Ok"
			gc()
		)
		else messagebox ("You mush choose Diffuse or Opacity (or both)") title:title
	)	
	on help_btn pressed do messagebox ("The purpose of this script is to catch a texture animation at each frame in an individual submaterial. You can animate the textures map's coordinates parameters and most of the usuals parameters such as size, colors, phase, etc.\n\nThis script works with any texture map. It will create a multi-material whose number of sub corresponds to the frame range you have chosen. Every sub is a standard material with the specified maps pluged into his diffuse and/or opacity channels. You can load two maps : the first one will be pluged into the selected channel(s) (diffuse and/or opacity). Second map is optionnal and will be pluged into the unselected channel (it can also be animated of course).\n\nClic on <<First Map>> to load a texture map. You can't drag and drop from the material editor, so you need first to apply your texture on an object (or put the texture in the compact material editor), so the browser can find it.\n\nAfter Proceeding, the script create a sphere and apply the multimaterial on it, that's how you get it. It also apply an animated material modifier.\n\nFeel free to use and modify the script.\n\nContact : victorburtman@gmail.com")title:title	
)
createdialog Collapse_Map_Sub