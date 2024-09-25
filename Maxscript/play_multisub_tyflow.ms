clearlistener()
try (destroydialog mapanimMultisubTF)catch()
Title = "Play Multisubs Sequences as Material ID in tyFlow"
rollout mapanimMultisubTF Title width:380
(
	--checkbox chkMergetfmapanim "Merge mapanim tyFlow system" checked:on
	--checkbox chkApplyScript "Apply script to tyFlow" checked:onm
	--checkbox chkApplyMaterial "Apply material to tyFlow" checked:on
	
	groupbox grpRandom "Animation Speed" width:230 height:80 pos:[10,10]
	
	spinner spnPadding "Padding:" range:[1,50,1] type:#integer fieldwidth:30 pos:[25,35] tooltip:"Increasing this value will slow down the map animation (it's a division)"
	spinner spnRandomPadding "Random:" range:[1,50,1] type:#integer fieldwidth:30 pos:[25,60] tooltip:"Add random to the padding. To keep animation uniform across all particles, set the same value as the Padding."
	radiobuttons rdbRandomType labels:#("True Random", "Binary Random")  offsets:#([0,0], [0,5]) default:1 columns:1 pos:[130,35]align:#left tooltip:"True Random: The random value can be one of the two values and all the integers values in the interval.\n\nBinary Random: The random value can only be one of the two values."
	button okbtn "Do it !" width:70 height:50 pos:[250,25]
	button helpbtn "Help" tooltip:"How does this script works ?" pos:[330,25] height:50
	
	local padding = 1
	local paddingRandom = 1
	local trueRandom = "tf.GetRandInt(sInx, multiplier, multiplierRandom)" -- true random
	local falseRandom = "arrayRandom[tf.GetRandInt(sInx, 1, 3) - 1]" -- false random
	local randomChoise = trueRandom
	
	on chkMergetfmapanim changed arg do
	(
		chkApplyScript.enabled = arg
		chkApplyMaterial.enabled = arg
	)
	
	on spnPadding changed arg do padding = spnPadding.value
	on spnRandomPadding changed arg do paddingRandom = spnRandomPadding.value
	on rdbRandomType changed arg do (if rdbRandomType.state == 1 then randomChoise = trueRandom else randomChoise = falseRandom)
		
	on okbtn pressed do
	(
		if selection.count > 0 then
		(
			if maxfilepath != "" then
			(
				scriptExport = maxfilepath + @"scriptExport.cfg"
				submatArray = #()
				multisubsArray = for i in selection where classof i.material == multimaterial collect i.material
				sequencesNumber = multisubsArray.count
				sequencesDuration = #()

				if sequencesNumber > 0 then
				(
					for m in multisubsArray do
					(
						append sequencesDuration (m.numsubs)
						for s in (m.materialList) do append submatArray s
					)
					newMulti = multimaterial ()
					newMulti.numsubs = submatArray.count
					newMulti.materialList = submatArray
					newMulti.name = "TYFLOW Global MultiSub"
					newSphere = sphere()
					newSphere.material = newMulti
					newSphere.name = "MULTISUB IS APPLY ON IT"
					select newSphere
					
					-------------- script tf
					if doesfileexist scriptExport do deleteFile scriptExport
					sequencesNumber
					script = "public void simulationStart()\n{\n\n}\n\npublic void simulationStep()\n{\n\tint multiplier = " + padding as string +";\n\tint multiplierRandom = " + paddingRandom as string +" + 1;\n\tint[] arrayRandom = {multiplier, multiplierRandom};\n\n\tfor (int i = 0; i < eventParticleCount; i++)\n\t{\n\t\tint sInx = tf.GetSimIndex(i);\n\t\tfloat eventAge = tf.GetEventAge(sInx);\n\n\t\tfloat CustSeed = tf.GetCustomFloat(sInx, \"CSeed\");\n\n\t\tif (eventAge == 0)\n\t\t{\n\t\t\ttf.SetSeed(sInx,Convert.ToInt16(CustSeed));\n\t\t\ttf.SetCustomFloat(sInx, \"RandomByPtc\", "+ randomChoise +");\n\t\t\tint min = 1;\n\t\t\tint max = " + (sequencesNumber + 1) as string +";\n\t\t\tint random = tf.GetRandInt(sInx, min, max);\n\t\t\ttf.SetSimulationGroups(sInx, random);\n\t\t}"
					addition = 0
					for s = 1 to sequencesNumber do
					(
						maxtime = sequencesDuration[s] 
						if s == 1 do maxtime = 0
						addition = addition + maxtime
						debutboucle = "\n\n\t\t"
						if s != 1 do debutboucle = "\n\n\t\telse "
						ajout = "if (tf.GetSimulationGroups(sInx) == " + (s as string) + ")\n\t\t{\n\t\t\ttf.SetMatID(sInx, ((int)tf.GetEventAge(sInx) / Convert.ToInt16(tf.GetCustomFloat(sInx, \"RandomByPtc\"))) + " + addition as string + " + 1);\n\t\t\tif (eventAge == " + (sequencesDuration[s]) as string + " * tf.GetCustomFloat(sInx,\"RandomByPtc\")) {tf.DeleteParticle(sInx);}\n\t\t}"
						o = script + debutboucle +ajout
						script = o
					)
					
					finScript = "\n\t}\n}\n\npublic void simulationStepThreaded(int startInx, int endInx, int threadInx)\n{\n\n}\n\n\npublic void postSimulationStep()\n{\n\n}"
					setINISetting scriptExport "TYFLOW SCRIPT" "Here is the tyFlow Script (you can copy/paste it into a Script Operator)" ("\n\n" + script + finScript)
					
					process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
					process.Start maxfilepath
					shelllaunch "explorer.exe" scriptExport

					
					
					messagebox ("Done ! The new multisub object has been apply to the selected sphere object.\n\nThe tyFlow script generated has been writen in a .cfg file located in your current scene folder. Copy paste it in order to use it in a tyFlow script operator.") title:Title
				)
				else messagebox ("Can't find multisub on selected objects.")title:Title
			)
			else messagebox("You need to save your scene file.")title:Title
		)
		else messagebox("Nothing is selected.")title:Title
		gc()
		CompleteRedraw()
		RedrawViews()
	)
	on helpbtn pressed do messagebox("This script will combine all the multisubs affected to your selected objets and generate a tyFlow Script to play the different sequences.\n\nThe tyFlow Script will assign particles groups according to the different sequences in the Multisub and each one of them will play a materilal ID related to their event age property.\n\nThe scripts uses a channel named \"CSeed\" to randomise the animation speed value for each sequence.\n\nYou will need to create a Custom Properties operator to generate this float value outside the script.") title:Title
)
createdialog mapanimMultisubTF
