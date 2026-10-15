FX TOOLKIT NETWORK - cible : 3ds Max 2022 / Python 3 / PySide2

INSTALLATION
Glisser dist/FXToolkit_Network.mzp dans un viewport de 3ds Max.
La barre FX apparait en haut. Elle est deplacable et detachable.
Ses dix boutons appellent des macros de la categorie FX :
Patafix, PrepFX, Vecmap, Toolbox, tyFlow Open, Scene Path, Caches Path, Footages Path,
tyPreview, GeoInspector Pro.
Les outils avec icones utilisent les fichiers originaux, sauf PrepFX dont
le nouveau symbole est un cube turquoise avec une coche. Les autres ont
un bouton texte. tyPreview n'a pas d'icone.

Les macros, les icones et le code de la barre sont installes dans les
dossiers utilisateur de Max. Aucun droit administrateur n'est requis.
Le script de demarrage recree la barre apres un redemarrage de Max.
La barre est une QToolBar PySide integree a Max ; son contenu se configure
dans tools.json puis en reconstruisant le MZP. Les macros peuvent aussi etre
placees sur des barres CUI natives via Customize User Interface > FX.
Une reinstallation actualise la meme barre sans en creer une deuxieme.
La position personnalisee de la barre entre sessions n'est pas garantie.
Les installations independantes anterieures ne sont pas supprimees.

RESEAU
Les chemins de reference figurent dans tools.json. Les outils sont lus sur
Q: au clic ; le MZP ne copie pas leurs sources sur chaque poste.
Le lecteur Q: n'est pas necessaire pour installer la barre.
Il doit etre monte et accessible pour lancer les outils reseau.
Une erreur indique le chemin exact si le fichier est absent.
Vecmap necessite vecmap.py ET le dossier vecmap_lib sur le serveur.
Les dependances propres aux outils restent celles de leurs projets.

DEPLOIEMENT SERVEUR
Decompresser dist/FXToolkit_Server.zip et copier ses dossiers 00_Lib et Scene dans Q:\fx\fx_tools\3dsMax\.
Conserver le fichier 00_Lib\productions.cfg s'il a deja ete personnalise.
Les deux paquets a distribuer sont FXToolkit_Network.mzp pour les postes
et FXToolkit_Server.zip pour le serveur (bibliotheque et productions).
Les depots sources et le lecteur Q: ne sont pas modifies par le build.

GEOINSPECTOR PRO
Le fichier attendu est :
Q:\fx\fx_tools\3dsMax\Systems\GeoinspectorPro\GeoInspector Pro.mse
Le .mse existant est utilise, comme dans le paquet original. Les images
internes et les icones GeoInspector sont installees dans #userIcons.
Le lanceur GeoInspector est inclus dans FXToolkit_Network.mzp.
Le script serveur deja installe ne figure plus dans le ZIP serveur.

CACHES PATH / BIBLIOTHEQUE PARTAGEE
Le bouton lance Q:\fx\fx_tools\3dsMax\Scene\Caches_path\cache_path.ms,
qui charge la bibliotheque 00_Lib\FXSceneContext.ms,
detecte la production, l'episode et le shot de la scene sauvegardee,
cree les dossiers de cache manquants puis copie le chemin dans le pressepapier.
Pour une prod Max : <racine>\<episode>\fx\3D_Sources\<shot>
Pour pipeline=maya_shots : <racine>\<episode>\<shot>\fx\wip\3d\datas
3D_Sources (avec un s) et le departement fx sont fixes.
Le registre 00_Lib\productions.cfg contient directement les cinq productions
Alice2, BES2, Borrowers, Oum3 et smurfs. Il est relu a chaque appel.
Modifier cette liste ne necessite pas de reconstruire le MZP.
Aucun fichier example.cfg n'est distribue.
PrepFX reste inchange : conserver son ancien prepFX.cfg jusqu'a l'adaptation
ulterieure de son lecteur. Durant cette transition, les changements communs
aux deux outils doivent etre reportes dans les deux fichiers.
Une scene non sauvegardee, hors production, ambigue ou incoherente produit
une erreur. Un lecteur indisponible ou un echec de creation ne copie rien.
La racine de production et l'episode doivent deja exister (ainsi que le shot
pour Maya) ; les dossiers de caches sont crees recursivement si necessaire.
L'API MAXScript et son utilisation depuis Python sont documentees dans
server/00_Lib/README.txt dans le depot. Le ZIP serveur contient uniquement
00_Lib/FXSceneContext.ms, 00_Lib/productions.cfg,
Scene/Caches_path/cache_path.ms et Scene/Footages_path/footages_path.ms.

BOUTONS DE CHEMINS
Les trois boutons sont adjacents : Scene Path, Caches Path, Footages Path.
Scene Path est le nouveau nom de Copy Path : il copie le dossier de la scene.
Les identifiants internes des macros restent stables pour les raccourcis.
Footages Path lance Scene\Footages_path\footages_path.ms et utilise la meme
bibliotheque pour copier le dossier des footages du shot :
- Max : <racine footage>\<episode>\rendu-compo\<shot>\<episode>sr<num>_FX
- Maya : <racine footage>\<episode>\<shot>\fx\wip\fx3d
Pour Maya, le chemin s'arrete a fx3d, sans sous-dossier de version.
Sans racine footage configuree, la racine scenes est utilisee comme dans PrepFX.
Footages Path copie le chemin attendu sans creer de dossiers ni ouvrir Explorer.
Caches Path conserve la creation des dossiers de caches manquants.
Deployer la bibliotheque mise a jour et les deux scripts reseau avant de cliquer
sur ces boutons. Le MZP contient uniquement leurs lanceurs.

SHIFT+V / TYPREVIEW
L'installateur exporte le jeu de raccourcis courant avec actionMan,
conserve toutes ses transformations, retire les affectations Shift+V du
contexte principal uniquement, puis affecte Shift+V a FX_TyPreview.
Les raccourcis des autres contextes (ex. UV editor) restent inchanges.
Le jeu genere est recharge et reexporte pour verifier l'affectation.
En cas d'echec, le jeu sauvegarde est recharge et un message explique que
Shift+V n'a pas ete installe. La barre reste utilisable.
L'affectation a lieu a l'installation uniquement, pas a chaque demarrage.
Une reinstallation reapplique Shift+V ; vos modifications ulterieures ne
sont pas forcees au simple redemarrage de Max.

Sauvegardes : #userScripts\FXToolkit\backups\<date>\Before-FX.hsx
Jeu actif : #userScripts\FXToolkit\FX-tyPreview.hsx
Pour restaurer : Customize > Hotkey Editor > Load From File, puis choisir
le Before-FX.hsx voulu. Cela restaure tout le jeu a sa date de sauvegarde.
Pour n'annuler que Shift+V, utiliser le Hotkey Editor manuellement.

CONSTRUCTION
Python 3, aucune dependance externe :
  python build.py
Les deux archives sont reconstruites depuis les sources du present depot.
Le build ne depend plus du depot ou d'un ancien ZIP GeoInspector.
Les icones sont embarquees dans package/icons : le build normal est autonome.
Le visuel source PrepFX est conserve dans assets/prepfx-source.png.
Pour reexporter ses variantes BMP/alpha, PNG et ICO :
  python export_prepfx_icons.py
Cette exportation optionnelle necessite Pillow ; le build MZP reste autonome.
Pour changer un chemin, modifier tools.json puis reconstruire le paquet.
Tests hors Max : python -m unittest discover -s tests -p "test_*.py"

VERIFICATION DANS MAX 2022
1. Deployer le ZIP serveur, installer le MZP, verifier dix boutons et cinq icones.
2. Cliquer chaque outil avec Q: accessible ; tester Scene Path sur une scene
   sauvegardee et une scene sans chemin.
3. Verifier Shift+V dans le viewport puis dans le Hotkey Editor.
4. Reinstaller : une seule barre ; les autres raccourcis restent presents.
5. Redemarrer Max : la barre revient et Shift+V conserve son affectation.
6. Verifier le comportement hors reseau et la restauration Before-FX.hsx.
7. Tester Caches Path sur une scene Max puis Maya : chemin copie correct,
   creation des dossiers manquants et preservation des fichiers existants.
   Tester aussi une scene non sauvegardee et un chemin hors production.
Les tests Max Batch fournis peuvent verifier l'installation dans des
dossiers temporaires. Un test sous 2027 ne remplace pas une recette 2022.

RESULTATS DU 15 OCTOBRE 2026
Six tests Python reussis : contenu des archives, syntaxe Python 3.7,
preservation des autres raccourcis/contextes et reapplication sans doublon.
Test reel sous 3ds Max Batch 2027 (29.0.0.3590) reussi : installation MZP,
reinstallation, dix macros, une seule barre, cinq icones, affectation
Shift+V relue depuis Max, bootstrap de demarrage et Scene Path sans scene
sauvegardee.
Bibliotheque MAXScript testee dans Max Batch 2027 : les deux chemins studio
fournis, variantes de noms, CFG relu en direct, chemins UNC, cas invalides,
creation recursive et repetition sans perte de donnees. Ces tests utilisent
des dossiers temporaires ; ils ne modifient ni le reseau ni le pressepapier.
Max 2022 et l'execution des outils sur le serveur Q: restent a verifier.

SOURCES TECHNIQUES AUTODESK
actionMan 2022 (lecture/ecriture HSX, tables et contextes) :
https://help.autodesk.com/cloudhelp/2022/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Interfaces/Core-Interfaces/Core-Interfaces-Documentation/A/GUID-D33B4031-2AB2-4A84-BA96-6BA96DD5A042.html
IActionManager 2022 (HSX depuis 2020.1, sauvegarde des personnalisations) :
https://help.autodesk.com/cloudhelp/2022/ENU/Max-Developer-Help/cpp_ref/class_i_action_manager.html
UI Python 2022 / PySide2 / docking :
https://help.autodesk.com/cloudhelp/2022/ENU/MAXDEV-Python/files/MAXDEV_Python_creating_python_uis_html.html
Format XML recoupe avec les schemas et presets Autodesk locaux :
UI_ln/CUI/XSD/HotkeyTransformationSchema.xsd, Default.hsxb, MayaShortcuts.hsx.

PROVENANCE
Icones Patafix, Vecmap, GeoInspectorPro : max/icons de leurs depots.
Nouvelle icone PrepFX : outil imagegen integre, puis export des tailles et
formats avec Pillow. Prompt conserve dans assets/prepfx-generation.txt.
Icones tyFlow : archive FXToolkit.mzp fournie par l'utilisateur.
Le code des anciens installateurs est une reference technique ; les chemins
et le comportement de ce paquet suivent la demande courante.
