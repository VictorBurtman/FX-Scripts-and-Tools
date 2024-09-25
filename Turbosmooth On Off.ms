Try(DestroyDialog TurnMod) Catch()
rollout TurnMod "Turbosmooth" width:150 height:390
(
	local Etat = 2
	local Etat_UseRender = false
	local Etat_OnlyViewport = false
	local NbrIterations = 1
	local NbrRenderIterations = 1
		
	label lbl_Infos "Selected objects" pos:[10,10]
	label lbl_NbrObj "" pos:[110,10]
	
	spinner spn_Iterations "" range:[0,20,1] type:#integer pos:[90,50] fieldWidth:30  
	spinner spn_RenderIterations "" range:[0,20,1] type:#integer pos:[90,70] fieldWidth:30 enabled:off
	checkbox chk_UseRenderI "Set Render Iters" pos:[23,90] checked:off tooltip:"Modify the render iterations number"
	Button btnOk "MODIFY ITERATIONS" pos:[10,120] width:130 height:20 tooltip:"Clic to modify the Turbosmooth(s) iterations on your selected objects"
	
	label lbl_Iterations "Iterations:" pos:[25,50]
	label lbl_RenderIterations "Render Iters:" pos:[25,70] 
	
	radiobuttons theRadiobuttons labels:#("Turn on","Turn off") default:2 pos:[10,180] columns:2 tooltip:"Turn on : activate Turbosmooth(s). Also activate the \"render iters\" option if it's not at 0 \r \rTurn off : desactivate Turbosmooth(s) and the \"render iters\" option"
	checkbox chk_OnlyInViewport "Affect viewport only" pos:[12,205] checked:off tooltip:"Will just set \"off in viewport\"" enabled:on
	Button btnOk2 "MODIFY ACTIVATION" pos:[10,235] width:130 height:20 tooltip:"Clic to modify the Turbosmooth(s) activation on your selected objects"
	
	groupbox grp_NumberIterations "Edit" pos:[05,30] width:140 height:120
	groupbox grp_OnOff "Activation" pos:[05,160] width:140 height:100
	
	progressbar rename_progress width:140 align:#center --pos:[12,205]
	label lbl_separate "---------------------"
	button btn_AddTurbosmooth "Add Turbosmooth" tooltip:"Add a Turbosmooth on selected obj with specified parameters" width:120
	button btn_delTurbosmooth "Delete Turbosmooths" tooltip:"Delete Turbosmooths on selected obj" width:120
	button btn_HelpTurbo "Help" tooltip:"How does this script works ?"
	
 -- fonctions pour l'affichage du nombre d'objets selectionnés
	
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
		else lbl_NbrObj.text = 0 as string
	)
	on TurnMod open do
	(	
		gc()
		callbacks.removeScripts id:#AutoRefresh
		callbacks.addScript #selectionSetChanged "TurnMod.printSelNumber()" id:#AutoRefresh				
		printSelNumber ()
	)
	on TurnMod close do callbacks.removeScripts id:#AutoRefresh
---------------------------------------------------------------------------
	
	
	on chk_UseRenderI changed theState_UseRender do -- Checkbox "Set render iters"
	(
		Etat_UseRender = theState_UseRender
		
		if Etat_UseRender == false do spn_RenderIterations.enabled = off
		if Etat_UseRender == true do spn_RenderIterations.enabled = on
	)
	
	on chk_OnlyInViewport changed theState_OnlyViewport do Etat_OnlyViewport = theState_OnlyViewport -- Checkbox "Affect viewport only"
	
	on spn_Iterations changed Iterations_ do NbrIterations = Iterations_-- spinner Iterations

	on spn_RenderIterations changed Iterations_R do NbrRenderIterations = Iterations_R-- spinner Render_Iterations
	
	on theRadiobuttons changed arg do -- Radiobutton "Turn On, Turn Off"
	(
		Etat = theRadiobuttons.state
		if Etat == 1 do chk_OnlyInViewport.enabled = off
		if Etat == 1 do chk_OnlyInViewport.checked = off
		if Etat == 2 do chk_OnlyInViewport.enabled = on
		if Etat == 1 do Etat_OnlyViewport = false
	)

	on btnOk pressed do -- Premier boutton OK (définit les iterations du turbosmooth)
	(
		Nombre = 0
		iter = 0
		rename_progress.value = 0 
		rename_progress.color = [30,10,190]
		if $ != undefined do
		(
			for o in $ where superclassof o == GeometryClass do for m in o.modifiers where classOf m == turboSmooth do Nombre +=1 -- on compte le nombre de turbosmooth
				
			for o in $ where superclassof o == GeometryClass do  
			(						
				for m in o.modifiers where classof m == turboSmooth do
				(
					m.iterations = NbrIterations 
					if Etat_UseRender == true do m.RenderIterations = NbrRenderIterations

					----------------------------------------	progress bar -------------------
					iter += 1
					--Nombre = selection.count as float
					prog = (100.0*(((iter as float)/Nombre) as float))
					rename_progress.value = (100.0*(((iter as float)/Nombre) as float))
					rename_progress.color = [200 - prog * 2,prog * 2,0]	
					------------------------------------------------------------------------------
				)
			)	
		)
	)

	on btnOk2 pressed do -- Deuxième bouton OK (gère l'activation du turbosmooth)
	(
		Nombre = 0
		iter = 0
		rename_progress.value = 0 
		rename_progress.color = [30,10,190]
		
		if $ != undefined do
		(
			for o in $ where superclassof o == GeometryClass do for m in o.modifiers where classOf m == turboSmooth do Nombre +=1 -- on compte le nombre de turbosmooth
				
			if Etat_OnlyViewport == false then -- si "affect viewport only" est décoché
			(
				if Etat == 1 then -- si turn on est coché
				(		
					for o in $ where superclassof o == GeometryClass do  
					(
						for m in o.modifiers where classOf m == turboSmooth do -- Active le turbosmooth, au rendu et dans le viewport	
						(									
							m.enabledInViews = true
							m.enabled = true
							if m.RenderIterations != 0 do m.useRenderIterations = on	
								
							----------------------------------------	progress bar -------------------
							iter += 1
							prog = (100.0*(((iter as float)/Nombre) as float))
							rename_progress.value = (100.0*(((iter as float)/Nombre) as float))
							rename_progress.color = [200 - prog * 2,prog * 2,0]	
							------------------------------------------------------------------------------			
						)
					)
				)
				
				if Etat == 2 then -- si turn off est coché
				(
					for o in $ where superclassof o == GeometryClass do
					(
						for m in o.modifiers where classOf m == turboSmooth do
						(
							m.enabled = false
							m.useRenderIterations = off		
							----------------------------------------	progress bar -------------------
							iter += 1
							--Nombre = selection.count as float
							prog = (100.0*(((iter as float)/Nombre) as float))
							rename_progress.value = (100.0*(((iter as float)/Nombre) as float))
							rename_progress.color = [200 - prog * 2,prog * 2,0]	
							------------------------------------------------------------------------------		
						)						
					)
				)
			)
			else -- si "affect viewport only" est coché (ne peut fonctionner qu'avec le turn off)
			(
				for o in $ where superclassof o == GeometryClass do  
				(
					for m in o.modifiers where classOf m == turboSmooth do
					(
						m.enabled = true -- on reactive tout 
						m.enabledInViews = true
						m.enabledInViews = false -- puis on désactive dans le viewport
						
						----------------------------------------	progress bar -------------------
						iter += 1
						--Nombre = selection.count as float
						prog = (100.0*(((iter as float)/Nombre) as float))
						rename_progress.value = (100.0*(((iter as float)/Nombre) as float))
						rename_progress.color = [200 - prog * 2,prog * 2,0]	
						------------------------------------------------------------------------------		
					)
				)
			)
		)
	)
	
	on btn_delTurbosmooth pressed do 
	(
		if $ != undefined do 
		(
			numberdel = 0
			for theNode in selection do
			(
				for index = theNode.modifiers.count to 1 by -1 do
				(
					if ((classOf theNode.modifiers[index]) == turbosmooth) do (deleteModifier theNode index; numberdel +=1)
				)
			)
			messagebox (numberdel as string + " turbosmooths has been deleted") title:"Turbosmooth Controler"
			gc()
		)
	)
	
	on btn_AddTurbosmooth pressed do
	(
		ModTurbo = turbosmooth()
		ModTurbo.name = "CustomTurbosmooth"
		ModTurbo.iterations = NbrIterations 
		if Etat_UseRender == true do 
		(
			ModTurbo.useRenderIterations = on
			ModTurbo.RenderIterations = NbrRenderIterations
		)
		
		if Etat == 1 then ModTurbo.enabled = true
		else ModTurbo.enabled = false
		
		if Etat_OnlyViewport == true do
		(
			ModTurbo.enabled = true -- on reactive tout 
			ModTurbo.enabledInViews = true
			ModTurbo.enabledInViews = false -- puis on désactive dans le viewport
		)
		
		for i in selection do	addmodifier i ModTurbo
	)
	
	on btn_HelpTurbo pressed do messagebox ("With this script you can :\n\n-- Modify the Turbosmooth(s) on your selected objects (edit the iterations and the activation parameters)\n\n-- Delete all the Turbomooths on your selected objects\n\n-- Add an instancied Turbosmooth on all your selected objects, according to the parameters specified in the script")title:"Turbosmooth Controler"
)

createdialog TurnMod