Class DataPipe.Oper.BO.OperationHandler Extends Ens.BusinessOperation
{

Parameter ADAPTER;

Parameter INVOCATION = "Queue";

/// OperRequest that is being processed in the Business Operation
Property OperRequest As DataPipe.Msg.OperReq;

Method OperationHandler(pRequest As DataPipe.Msg.OperReq, Output pResponse As Ens.Response) As %Status
{
	set ret = $$$OK
	try {
		set ..OperRequest = pRequest
		set inboxObj = pRequest.data.Ingestion.Inbox

		// reload inbox - in case user has set inbox as ignored in other process (UI)
		do pRequest.data.Ingestion.Inbox.%Reload()
        set operObj = inboxObj.LastOper

		// update Oper status
		set operObj.Status = "PROCESSING"
		$$$ThrowOnError(operObj.%Save())

		// deserialize model
        if pRequest.data.Ingestion.ModelIsPython {
            // Set python path
            do ##class(DataPipe.Helper).SetPythonPath(pRequest.data.Ingestion.ModelClassPath)
            set modelObj = ##class(DataPipe.Helper).GetPythonInstance(pRequest.data.Ingestion.ModelModule, pRequest.data.Ingestion.ModelName)
            do modelObj.Deserialize(pRequest.data.ModelNormData)
			set errorList = ""
			set operLog = ""

        } else {
			set modelData = pRequest.data.ModelNormData
			set modelName = pRequest.data.Ingestion.ModelName
			set sc = $classmethod(modelName, "Deserialize", modelData, .modelObj)
			$$$ThrowOnError(sc)
		}

		set operLog = ""
		set operationSC = $$$OK

		// inbox ignored - avoid operation
        if inboxObj.Ignored {
			set inboxObj.Status = "DONE"
			set operObj.Status = "IGNORED"
		
		// not ignored - perfom operation	
		} else {
			if pRequest.data.Ingestion.ModelIsPython {
				// Python doesn't support byref parameters, so we return error list and oper log as strings
				try {
					set operationSC = $$$OK
					set pythonList = modelObj.RunOperation(##this)
					set errorList = ##class(%ListOfDataTypes).%New()
					set operLog = ##class(%Stream.GlobalCharacter).%New()
                	for i=1:1:pythonList.Count() {
						set err = pythonList.GetAt(i)
						if err.Code = "OPERATION"
						{   
							set operationSC = $$$ERROR($$$GeneralError, err.Desc)
						} if err.Code = "OPERLOG" {
							do operLog.WriteLine(err.Desc)
						} else {
							do errorList.Insert(err)
						}
                	}
				} catch ex {
					set operationSC = ex.AsStatus()
				}
			} else {
				set operationSC = modelObj.RunOperation(.errorList, .operLog, ##this, .delayedProcessing)
			}
			set operObj.Retries = operObj.Retries + 1
			if $$$ISOK(operationSC) {
				if delayedProcessing=0 {
					set operObj.Status = "PROCESSED"
					set inboxObj.Status = "DONE"
				}
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
