Pflows = for PF in objects where classof PF == PF_Source collect PF
	
if Pflows.count > 0 then
(	
	pView = particleFlow.OpenParticleView()
	particleFlow.beginEdit()
	pView.selected = Pflows
	particleFlow.endEdit()

	actionMan.executeAction 135018554 "32771"
	pView = particleFlow.OpenParticleView()
	particleFlow.forceRedrawParticleView pView

	X_Pos = 50
	Y_Pos = 50

	for i in Pflows do
	(
		X_Pos += 700
		i.SetPViewLocation X_Pos Y_Pos
		select i
	)
)
else
(
	messagebox ("No PF Source, can't Lay Out") title:"Lay Out Horizontally"
)