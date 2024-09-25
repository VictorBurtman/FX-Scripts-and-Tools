-- Ce script paramètre le tyPreview ! Il a des settings par défaut (style de la preview, overlay etc.)

-- Si vous êtes dans un plan, le chemin de preview va directement dans le dossier de l'épisode > fx > previews > NomDeL'Operateur 
-- Si vous êtes dans une scène, le tyPreview va chercher le dossier de la scène
-- Si vous êtes dans un fichier non enregistré, le chemin de preview sera celui habituel (C:\Users\username\Documents\3dsMax\previews)
gc()
genericOutput = "$scenePath\$camera_$sceneFile_preview_$version.mp4"
if sysInfo.username != "thomasd" then appareanceStyle = 0 else appareanceStyle = 7 -- pour thomas
fn tyPreviewSettings outPutPath = (tyPreviewWindow overlay_frame:true output_filename:outPutPath resolution_width:(renderWidth) resolution_height:(renderHeight)) --appearance_style:appareanceStyle appearance_mode:1
if maxfilename != "" then -- si la scène est enregistrée
(
	c = filterString maxfilepath "\\"
	if c[1] == "S:" or c[1] == "isilon-100" then -- Sur le serveur de prods
	(
		local EpisodeNumber = ""
		local increment = 0
		local SecondIncrement = 0
		local TroisiemeIncrement = 0 -- JE DECLARE MA VALEUR ICI 
		local prodNameFind = ""
		local prodsNames = #("alice", "oum", "ag", "mco4", "grm", "arthur", "ggt2", "splat", "runes")

		rx = dotNetClass "System.Text.RegularExpressions.RegEx"
		if (EpisodeNumber = (rx.match maxfilepath "e[0-9]{3}").value)!= "" do increment += 1  -- on récupère le numéro de l'épisode dans le chemin du fichier
		if (EpisodeFiltred = (rx.match maxfilename "e[0-9]{3}").value)!= "" do secondIncrement += 1 -- on récupère le numéro de l'épisode dans le nom du fichier
		if EpisodeFiltred != EpisodeNumber do EpisodeFiltred = EpisodeNumber -- si les deux sont differents, on garde celui du chemin
		
		if secondIncrement == 0 do-- si le nom du fichier ne permet pas de trouver l'épisode
		(
			if increment == 1 then -- mais que l'épisode peut etre trouvé dans le chemin de la scène
			(
				EpisodeFiltred = EpisodeNumber -- alors on prend pour numéro d'épisode celui trouvé dans le chemin
				SecondIncrement += 1 -- et on incremente cette valeur pour dire qu'on a bien trouvé un numero valide d'épisode
			)
			else if queryBox "Le numéro de l'épisode est introuvable dans le nom du fichier ou dans le chemin de la scène. Impossible de créer un chemin de preview custom. Voulez vous lancer quand même l'interface tyPreview ?" title:"tyPreview Custom Path" beep:true do
			(
				Pushprompt "Chemin de la preview défini dans le dossier de la scène et copié dans le presse-papier"
				setclipboardText maxfilepath
				tyPreviewSettings genericOutput
				process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
				process.Start maxfilepath
			)
		)
		if SecondIncrement == 1 do
		(
			tempArrayProdsNames = #()
			for i in ProdsNames do -- on regarde si un nom de prod se trouve dans le chemin du fichier
			(
				if findItem c "mco_local" != 0 do TroisiemeIncrement += 5
				for item in c where item == i do
				(
					if tempArrayProdsNames.count == 0 then
					(
						prodNameFind = item
						append tempArrayProdsNames item
						TroisiemeIncrement += 1
					)
					else if findItem tempArrayProdsNames item == 0 do TroisiemeIncrement += 1 -- si plusieurs noms de prods (différents) sont trouvés dans le chemin du fichier, on peut pas savoir de quelle prod il s'agit donc on incremente au dela de 1
				)
			)
			
			if prodNameFind != ""and TroisiemeIncrement == 1 then 
			(
				Pushprompt "Preview enregistrée dans le dossier de preview fx de l'épisode. Chemin copié dans le presse papier"
				pathPreview = "S:\\" + ProdNameFind+ "\\production\\" + EpisodeFiltred + "\\fx\\00_previews\\"
				NameUser = sysInfo.username + "\\"
			    pathPreviewUser = pathPreview + NameUser
				setclipboardText pathPreviewUser
				makeDir pathPreviewUser all:true
				namePreview = pathPreviewUser + (getfilenamefile maxfilename) +"_" + "$version" +"_.mp4"  -- 
				process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
				process.Start pathPreviewUser
				tyPreviewSettings namePreview
			)
			else 
			(
				Pushprompt "Prod introuvable dans le chemin du fichier. Chemin de la preview défini dans le dossier de la scène et copié dans le presse-papier" 
				setclipboardText maxfilepath
				tyPreviewSettings genericOutput
				process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
				process.Start maxfilepath
			)
		)
	)
	else
	(
		Pushprompt "Scène non enregistrée sur le serveur de prods (isilion ou S:). Chemin de la preview défini dans le dossier de la scène et copié dans le presse-papier"
		setclipboardText maxfilepath
		tyPreviewSettings genericOutput
		process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
		process.Start maxfilepath
	)
)
else -- si la scène n'est pas enregistrée
(
	maxVer = maxVersion()
	Pushprompt "Scène non enregistrée. Chemin de la preview défini dans le dossier de preview par defaut et copié dans le presse-papier"
	pathPrevStandard = "C:\\Users\\" + (sysInfo.username) + "\\Documents\\3ds Max "+ maxVer[8] as string + "\\previews\\_preview_$version_.mp4" 
	--messagebox (pathPrevStandard)
	DossierPrevStandard = "C:\\Users\\" + (sysInfo.username) + "\\Documents\\3ds Max " + maxVer[8] as string +"\\previews\\"
	setclipboardText DossierPrevStandard
	tyPreviewSettings pathPrevStandard
	process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
	process.Start DossierPrevStandard
)


