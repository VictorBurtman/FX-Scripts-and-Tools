Try(DestroyDialog lockUnlock) Catch()
rollout lockUnlock "John Unlock" width:120 height:63
(
	button btn1 "Lock selection" pos:[18,10] width:85 height:20
	button btn2 "Unlock selection" pos:[18,37] width:85 height:20
	on btn1 pressed do setTransformLockFlags selection #all
	on btn2 pressed do setTransformLockFlags selection #none
)
createDialog lockUnlock style:#(#style_titlebar, #style_toolwindow, #style_sysmenu)