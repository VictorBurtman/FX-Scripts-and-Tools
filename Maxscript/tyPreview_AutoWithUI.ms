-- Ce script param�tre le tyPreview ! Il a des settings par d�faut (style de la preview, overlay etc.)

-- Si vous �tes dans un plan, le chemin de preview va directement dans le dossier de l'�pisode > fx > previews > NomDeL'Operateur 
-- Si vous �tes dans une sc�ne, le tyPreview va chercher le dossier de la sc�ne
-- Si vous �tes dans un fichier non enregistr�, le chemin de preview sera celui habituel (C:\Users\username\Documents\3dsMax\previews)
gc()
genericOutput = "$scenePath\$camera_$sceneFile_preview_$version.mp4"
if sysInfo.username != "thomasd" then appareanceStyle = 0 else appareanceStyle = 7 -- pour thomas
fn tyPreviewSettings outPutPath = (tyPreviewWindow overlay_frame:true output_filename:outPutPath resolution_width:(renderWidth) resolution_height:(renderHeight)) --appearance_style:appareanceStyle appearance_mode:1
if maxfilename != "" then -- si la sc�ne est enregistr�e
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
		if (EpisodeNumber = (rx.match maxfilepath "e[0-9]{3}").value)!= "" do increment += 1  -- on r�cup�re le num�ro de l'�pisode dans le chemin du fichier
		if (EpisodeFiltred = (rx.match maxfilename "e[0-9]{3}").value)!= "" do secondIncrement += 1 -- on r�cup�re le num�ro de l'�pisode dans le nom du fichier
		if EpisodeFiltred != EpisodeNumber do EpisodeFiltred = EpisodeNumber -- si les deux sont differents, on garde celui du chemin
		
		if secondIncrement == 0 do-- si le nom du fichier ne permet pas de trouver l'�pisode
		(
			if increment == 1 then -- mais que l'�pisode peut etre trouv� dans le chemin de la sc�ne
			(
				EpisodeFiltred = EpisodeNumber -- alors on prend pour num�ro d'�pisode celui trouv� dans le chemin
				SecondIncrement += 1 -- et on incremente cette valeur pour dire qu'on a bien trouv� un numero valide d'�pisode
			)
			else if queryBox "Le num�ro de l'�pisode est introuvable dans le nom du fichier ou dans le chemin de la sc�ne. Impossible de cr�er un chemin de preview custom. Voulez vous lancer quand m�me l'interface tyPreview ?" title:"tyPreview Custom Path" beep:true do
			(
				Pushprompt "Chemin de la preview d�fini dans le dossier de la sc�ne et copi� dans le presse-papier"
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
					else if findItem tempArrayProdsNames item == 0 do TroisiemeIncrement += 1 -- si plusieurs noms de prods (diff�rents) sont trouv�s dans le chemin du fichier, on peut pas savoir de quelle prod il s'agit donc on incremente au dela de 1
				)
			)
			
			if prodNameFind != ""and TroisiemeIncrement == 1 then 
			(
				Pushprompt "Preview enregistr�e dans le dossier de preview fx de l'�pisode. Chemin copi� dans le presse papier"
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
				Pushprompt "Prod introuvable dans le chemin du fichier. Chemin de la preview d�fini dans le dossier de la sc�ne et copi� dans le presse-papier" 
				setclipboardText maxfilepath
				tyPreviewSettings genericOutput
				process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
				process.Start maxfilepath
			)
		)
	)
	else
	(
		Pushprompt "Sc�ne non enregistr�e sur le serveur de prods (isilion ou S:). Chemin de la preview d�fini dans le dossier de la sc�ne et copi� dans le presse-papier"
		setclipboardText maxfilepath
		tyPreviewSettings genericOutput
		process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
		process.Start maxfilepath
	)
)
else -- si la sc�ne n'est pas enregistr�e
(
	maxVer = maxVersion()
	Pushprompt "Sc�ne non enregistr�e. Chemin de la preview d�fini dans le dossier de preview par defaut et copi� dans le presse-papier"
	pathPrevStandard = "C:\\Users\\" + (sysInfo.username) + "\\Documents\\3ds Max "+ maxVer[8] as string + "\\previews\\_preview_$version_.mp4" 
	--messagebox (pathPrevStandard)
	DossierPrevStandard = "C:\\Users\\" + (sysInfo.username) + "\\Documents\\3ds Max " + maxVer[8] as string +"\\previews\\"
	setclipboardText DossierPrevStandard
	tyPreviewSettings pathPrevStandard
	process = dotNetObject "System.Diagnostics.Process" -- ouvre le dossier, seulement s'il n'est pas deja ouvert
	process.Start DossierPrevStandard
)

