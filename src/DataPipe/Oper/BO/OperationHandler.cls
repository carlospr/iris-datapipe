Class DataPipe.Oper.BO.OperationHandler Extends Ens.BusinessOperation
{

Parameter ADAPTER;

Parameter INVOCATION = "Queue";

Method OperationHandler(pRequest As DataPipe.Msg.OperReq, Output pResponse As Ens.Response) As %Status
{
	set ret = $$$OK
	try {
		set inboxObj = pRequest.data.Ingestion.Inbox
        set operObj = inboxObj.LastOper

		// update Oper status
		set operObj.Status = "PROCESSING"
		$$$ThrowOnError(operObj.%Save())

		// deserialize model
		set modelData = pRequest.data.ModelNormData
        set modelName = pRequest.data.Ingestion.ModelName
        set sc = $classmethod(modelName, "Deserialize", modelData, .modelObj)
        $$$ThrowOnError(sc)

		// perform operation
		set sc = modelObj.RunOperation(.errorList, .operLog)
		if $$$ISOK(sc) {
			// update status
			set operObj.Status = "PROCESSED"
			set inboxObj.Status = "DONE"
		} else {
			// udpate status
			set operObj.Status = "ERROR"
			set inboxObj.Status = "ERROR-OPERATING"
			
			$$$LOGERROR($system.Status.GetOneStatusText(sc))

			// serialize errors
			set operObj.OperErrors = errorList
			$$$ThrowOnError(operObj.SerializeOperErrors())
		}	
		
		set operObj.OperLog = operLog
		$$$ThrowOnError(operObj.%Save())
		$$$ThrowOnError(sc)

		$$$ThrowOnError(inboxObj.%Save())

 	} catch ex {
		set ret = ex.AsStatus()
		// update Inbox status (error)
		set pRequest.data.Ingestion.Inbox.Status = "ERROR-OPERATING"
		do pRequest.data.Ingestion.Inbox.%Save()
	}
	quit ret
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="DataPipe.Msg.OperReq"> 
		<Method>OperationHandler</Method>
	</MapItem>
</MapItems>
}

}
