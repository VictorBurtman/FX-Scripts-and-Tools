pView = particleFlow.OpenParticleView()
array_sel = #()
for sel_obj in pView.selected do append array_sel sel_obj

count = array_sel.count
array_sel_indexArray = for i_all_op = 1 to count collect i_all_op

for i = 1 to count do
(
	try (array_sel [array_sel_indexArray[i]].Random_Seed = random 1 15000)
	catch()
)		