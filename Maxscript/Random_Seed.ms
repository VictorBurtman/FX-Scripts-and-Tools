/*
__MXSDOC__
[TITLE]
--Random Seed v2.0--

[DESCRIPTION]
Script permettant d'assigner une valeur aléatoire à tous les "seed" des opérateurs particle flow présent dans la scène

le bouton "lock" permet de verrouiller la valeur de seed du ou des opérateurs sélectionnés dans particle flow. Une fois lockés ces opérateurs seront ignorés lors du random seed
le bouton "unlock" permet de déverrouiller la valeur de seed du ou des opérateurs sélectionnés dans particle flow. Une fois délockés ces opérateurs seront de nouveau pris en compte lors du random seed

[CREATION INFO]
Benjamin CHAUVET
Mars 2013
__END__
*/

try(destroyDialog Random_Seed)catch()  
rollout Random_Seed "..:: Random Seed ::.." width:180 height:145 --définition de la boite de dialogue, nom et taille
	
	(
		
		---------------------------------------------------------	définition de la boite de dialogue flottante	--------------------------------------------------------------------
			local ThePos = [0,0]	
			local mousedd = false
			on Random_Seed lbuttonup pos do mousedd = false ;
			on Random_Seed lbuttondown pos do (mousedd = true ; ThePos = pos)
			on Random_Seed mousemove pos do  if mousedd do SetDialogPos  Random_Seed  (mouse.screenpos - thePos)
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------	définition du cadre et du bouton de fermeture de la boite de dialogue	--------------------------------------------
			
		GroupBox cadre_principal " Random Seed " pos:[10,10] width:160 height: 125 --création du cadre
		button Close_btn "X"  pos:[160,0] --création du bouton de fermeture
		button btn_random_all_seed ".: Random all seed :." pos:[30,35] tooltip:"créer un valeur aléatoire pour tous les 'seed' des opérateurs présent dans Particle Flow"
		label lab_separator "---- lock/unlock operator ----"
		button lock_seed_btn "Lock" pos:[30,85] width:50 tooltip:"lock la valeur de seed du/des opérateur(s) sélectionné(s)"
		button unlock_seed_btn "Unlock" pos:[100,85] width:50 tooltip:"unlock la valeur de seed du/des opérateur(s) sélectionné(s)"
		progressbar random_progress width:140 align:#center 
	
			
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
		---------------------------------------------------------------		définition de l'action du bouton random all seed	---------------------------------------------------------------
			
		on btn_random_all_seed pressed do
			(
				all_op_array = #()

				for pflow_op in helpers do
				(
					if findstring pflow_op.name "lockseed" == undefined then
					(
						append all_op_array pflow_op
					)
					else()
				)	

				count = all_op_array.count
				all_op_array_indexArray = for i_all_op = 1 to count collect i_all_op
		---------------------------------------------------------- execution du random all sur les opérateurs  --------------------------------------------------------------------------		
		
		for i = 1 to count do
			(
				prog =(100.0*(((i as float)/count)as float))
				random_progress.value = (100.0*(((i as float)/count) as float))
				random_progress.color = [200 - prog * 2,prog *2,0]
				try	(	all_op_array[all_op_array_indexArray[i]].Random_Seed = random 1 15000	)
				catch()
			)				
	
			)	
		----------------------------------------------------------	définition de l'action du bouton lock	--------------------------------------------------------------------------
		
		on lock_seed_btn pressed do
		(	
			random_progress.value = 0 
			array_temp = #()
			oldname = #()		
			for sel_obj in $'Particle View 001'.selected do append array_temp sel_obj
			for i=1 to array_temp.count do array_temp[i].name as string
			for i=1 to array_temp.count do append oldname array_temp[i].name as string
			for i=1 to array_temp.count do 
				(
					array_temp[i].name = uniquename oldname[i] + "_lockseed"	
					prog =(100.0*(((i as float)/array_temp.count)as float))
					random_progress.value = (100.0*(((i as float)/array_temp.count) as float))
					random_progress.color = [200 - prog * 2,prog *2,0]
				)
				
		)

		----------------------------------------------------------	définition de l'action du bouton unlock	--------------------------------------------------------------------------
		
		on unlock_seed_btn pressed do
		(
			random_progress.value = 0 
			array_temp = #()
			oldname = #()				
			for sel_obj in $'Particle View 001'.selected do append array_temp sel_obj
			for i=1 to array_temp.count do append oldname array_temp[i].name as string
			for i=1 to array_temp.count do
				(
					array_temp[i].name = substring oldname[i] 1 (oldname[i].count - 9)
					prog =(100.0*(((i as float)/array_temp.count)as float))
					random_progress.value = (100.0*(((i as float)/array_temp.count) as float))
					random_progress.color = [200 - prog * 2,prog *2,0]
				)
		)	

		----------------------------------------------------------	définition de l'action du bouton Close	--------------------------------------------------------------------------
		
		on Close_btn pressed do DestroyDialog  Random_Seed --bouton de fermeture de la boite de dialogue
				
	)
	
createdialog Random_Seed() Style:#() --création de la boite de dialogue

