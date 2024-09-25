try(destroydialog CalculatePercent)catch()
title = "Calculate Percent"
rollout CalculatePercent title height:150 width:400
(
	spinner spn1 pos:[5,10] range:[0,10000,0] fieldWidth:50
	spinner spn2 "% of " pos:[70,10] range:[0,10000,0] fieldWidth:50
	label lbl1 "= 0.0" pos:[230,10] style_sunkenedge:true width:70 height:17
	
	spinner spn3 pos:[5,40] range:[0,10000,0] fieldWidth:50
	spinner spn4 " of " pos:[70,40] range:[0,10000,0] fieldWidth:50
	label lbl2 "= 0.0 %" pos:[170,40] style_sunkenedge:true width:90 height:17
	
	spinner spn5 "Difference of % between " pos:[8,70] range:[-10000,10000,0] fieldWidth:50
	spinner spn6 "and  " pos:[185,70] range:[-10000,10000,0] fieldWidth:50
	label lbl3 "= 0.0 %" pos:[275,70] style_sunkenedge:true width:90 height:17
	button btnHelp "Help" pos:[10, 100]
	
	on spn1 changed arg do lbl1.text = "= " + (spn2.value * (spn1.value / 100)) as string
	
	on spn2 changed arg do lbl1.text = "= " + (spn2.value * (spn1.value / 100)) as string
	
	on spn3 changed arg do if spn4.value > 0 then lbl2.text = "= " + ((spn3.value / spn4.value) * 100) as string  + " %" else lbl2.text = "= 0.0 %"
	
	on spn4 changed arg do if spn4.value > 0 then lbl2.text = "= " + ((spn3.value / spn4.value) * 100) as string  + " %" else lbl2.text = "= 0.0 %"
	
	on spn5 changed arg do if spn5.value == 0 and spn6.value == 0 or spn5.value == 0 and spn6.value != 0 then lbl3.text = "= 0.0 %" else lbl3.text =  "= " + (((spn6.value - spn5.value) / spn5.value) * 100) as string + " %"
	
	on spn6 changed arg do if spn5.value == 0 and spn6.value == 0 or spn5.value == 0 and spn6.value != 0 then lbl3.text = "= 0.0 %" else lbl3.text =  "= " + (((spn6.value - spn5.value) / spn5.value) * 100) as string + " %"
	
	on btnHelp pressed do messagebox ("First formula : V2 * (V1 / 100)\n\nSecond formula : (V1 / V2) * 100\n\nThird formula : ((V2 - V1) / V1) x 100")title:title
)
createdialog CalculatePercent
