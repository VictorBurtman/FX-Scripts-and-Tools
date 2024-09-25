try (destroydialog tyPropertiesRollout)catch()
IsTFInstalled = true
try (tyPropMod = tyProperties()) catch (IsTFInstalled = false) -- we test if tyflow is installed
local title = "tyProperties Objects IDs"
rollout tyPropertiesRollout title height:145 width:200
(
	groupbox grp1 pos:[20,5] height:88 width:160
	radioButtons rdR "Stack modifier position" labels:#("top", "bottom") default:1 columns:2 align:#left tooltip:"" pos:[47,20]
	button ok_btn "Apply tyProperties" pos:[50,60] width:110 tooltip:"Assign tyProperties modifiers to your current selection with a custom float channel (named \"ObjID\") whose values corresponds the Objects IDs"
	button del_btn "Delete tyProperties"  pos:[50,110] width:110 tooltip:"Delete all tyProperties modifiers on selected objects"
	
	on ok_btn pressed do
	(
		if $ != undefined then
		(
			tyPropMod = tyProperties()
			for i in selection do
			(
				tyPropModUnique = copy tyPropMod
				tyPropModUnique.name = "tyProperties (Obj_ID)"
				if rdR.state == 1 then (addModifier i tyPropModUnique) else (addmodifier i tyPropModUnique before:(i.modifiers.count))
				
				tyPropModUnique.addNewListItem()
				tyPropModUnique.customfloatvalue = i.gbufferchannel
				tyPropModUnique.customFloatChannel = "ObjID"
				
			)
			messagebox ("tyProperties modifiers has been assigned to the current selection with a channel named \"ObjID\" whose values corresponds to the objects IDs.\n\nUse this Channel into a tyFlow export particle operator (Objects export mode) in order to keep properly the objects IDs on the exported nodes.") title:title
		) else messagebox("Nothing is selected")title:title
	)
	
	on del_btn pressed do 
	(
		if $ != undefined do 
		(
			numberdel = 0
			for theNode in selection do
			(
				for index = theNode.modifiers.count to 1 by -1 do
				(
					if ((classOf theNode.modifiers[index]) == tyProperties) do (deleteModifier theNode index ; numberdel +=1)
				)
			)
			messagebox (numberdel as string + " tyProperties has been deleted") title:title
			gc()
		)
	)
)
if IsTFInstalled == true then createdialog tyPropertiesRollout else messagebox ("Please install tyFlow plugin in order to use the tyProperties modifier")title:title


