Try(DestroyDialog BakeXMESH) Catch()
rollout BakeXMESH "Keyframe XMesh" width:150 height: 100
	(
		local StartFrame = 0
		local EndFrame = 0
		local PaddingFrame = 1
		label StartFRA "Start frame" pos:[10,10] 
		spinner StartSpn pos:[75,10] type:#integer fieldwidth:45 range:[-10000,10000,0]
		spinner EndSpn pos:[75,30] type:#integer fieldwidth:45 range:[-10000,10000,0]
		spinner PadSpn pos:[75,50] type:#integer fieldwidth:45 range:[1,50,0]
		label EndFRA "End frame" pos:[10,30]
		label PaddingFRA "Padding" pos:[10,50]
		button btnBake "Bake it !" pos:[15,75] width:120 height:20
		button btnhelp "?" tooltip:"How does this script works ?" width:10 height:20 pos:[05,75]
		
		on btnhelp pressed do messagebox ("Select one or severals XMeshLoader(s). The script will keyframe their Graph attribute using the start frame and the end frame you entered. \n\nThe padding can be used to increase the animation timing.") title:"Bake XMesh"
		
		on StartSpn changed TextStart do StartFrame = TextStart 
		
		on EndSpn changed TextEnd do EndFrame = TextEnd 
		
		on PadSpn changed TextPad do PaddingFrame = TextPad 
			
		on btnBake pressed do
		(
			if StartFrame < EndFrame then
			(
				for i in selection where classof i == XMeshLoader or classof i == Editable_mesh do
				(
					i.enablePlaybackGraph = on
					sliderTime = StartFrame as time
					i.playbackGraphTime = StartFrame
					with animate on
					(
						for o in StartFrame to EndFrame do
						(
							sliderTime += PaddingFrame
							i.playbackGraphTime += 1
						)
					)
				)
			)
			else messagebox ("Start frame can't be superior to end frame") title:"Bake XMesh"			
		)
	)
	createdialog BakeXMESH