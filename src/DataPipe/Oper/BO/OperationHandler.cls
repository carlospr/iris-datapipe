Class DataPipe.Oper.BO.OperationHandler Extends Ens.BusinessOperation
{

Parameter ADAPTER;

Parameter INVOCATION = "Queue";

Method OperationHandler(
	pRequest As DataPipe.Msg.OperReq,
	Output pResponse As Ens.Response) As %Status
{
	set ret = $$$OK
	try {
		set inboxObj = pRequest.data.Ingestion.Inbox
		// reload inbox - in case user has set inbox as ignored in other process (UI)
		do pRequest.data.Ingestion.Inbox.%Reload()
        set operObj = inboxObj.LastOper

		// update Oper status
		set operObj.Status = "PROCESSING"
		$$$ThrowOnError(operObj.%Save())

		// deserialize model
		set modelData = pRequest.data.ModelNormData
        set modelName = pRequest.data.Ingestion.ModelName
        set sc = $classmethod(modelName, "Deserialize", modelData, .modelObj)
        $$$ThrowOnError(sc)

		set operLog = ""
		set operationSC = $$$OK

		// inbox ignored - avoid operation
        if inboxObj.Ignored {
			set inboxObj.Status = "DONE"
			set operObj.Status = "IGNORED"
		
		// not ignored - perfom operation	
		} else {
			set operationSC = modelObj.RunOperation(.errorList, .operLog, ##this)
			set operObj.Retries = operObj.Retries + 1
			if $$$ISOK(operationSC) {
				set operObj.Status = "PROCESSED"
				set inboxObj.Status = "DONE"
			} else {
				set operObj.Status = "ERROR"
				set inboxObj.Status = "ERROR-OPERATING"

				// serialize errors
				set operObj.OperErrors = errorList
				$$$ThrowOnError(operObj.SerializeOperErrors())
			}
		}
		
		set inboxObj.UpdatedTS = $zdatetime($horolog,3)

		// append operation log
		if $isobject(operObj.OperLog) {
			do operObj.OperLog.MoveToEnd()
			do operObj.OperLog.CopyFrom(operLog)
		} else {
			set operObj.OperLog = operLog
		}

		$$$ThrowOnError(operObj.%Save())
		$$$ThrowOnError(inboxObj.%Save())
		
		$$$ThrowOnError(operationSC)

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
