/*==========================
||  Autorig tyBind 
||  Create a tyBind helper for each selected object that has a parent. Useful in a tyActor worflow. 
||	tyFlow plugin is required 
||  Author: Victor Burtman 
||  www.victorburtman.com 
==========================*/

title = "Auto RIG tyBind"
try(DestroyDialog AutotyBindRollout)catch()
rollout AutotyBindRollout title
(
	button do_it_btn "Create tyBinds"
	button help_btn "Help"
	
	on do_it_btn pressed do
	(
		if $ != undefined then
		(	
			increment = 0
			for i in selection do
			(
				if i.parent != undefined do
				(
					new_tybind = tyBind()
					new_tybind.transform = i.transform -- align 
					new_tybind.parent = i -- link
					new_tybind.objectANode = i -- add parent and children to the tyBind parameters 
					new_tybind.objectBNode = i.parent
					increment += 1
				)
			)
			if increment > 0 then messagebox (increment as string + " tyBinds has been created")title:title
			else messagebox ("No selected object has a parent")title:title
		)
		else messageBox ("Nothing is selected")title:title
	)
	on help_btn pressed do messagebox("This script will create a tyBind helper for each selected object that has a parent. It will automatically add to the tyBinds parameters both parent and children objects.\n\nThe tyBind will also be linked and aligned to the objects (it doesn't change anything but it is clearer in the viewport).\n\nScript by Victor Burtman")title:title
)
createdialog AutotyBindRollout