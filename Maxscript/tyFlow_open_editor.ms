tyFlowArray = for i in (getClassInstances tyFlow) collect i 
if tyFlowArray.count != 0 then tyFlowArray[1].editor_open()
else 
(
	newtyFlow = tyFlow()
	newtyFlow.editor_open()
	newtyFlow.showName = on	
	newtyFlow.printSimSummary = off
	select newtyFlow
)
