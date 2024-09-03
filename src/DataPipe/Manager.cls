Class DataPipe.Manager
{

ClassMethod UpdateOperation(inboxId As %String, delayedProcessing As %Boolean, updSC As %Status, updErrorList As %List, updLog As %Stream.Object) As %Status
{
    set ret = $$$OK
    try {
        set inboxObj = ##class(DataPipe.Data.Inbox).%OpenId(inboxId)
        set operObj = inboxObj.LastOper

        if $$$ISOK(updSC) {
            if delayedProcessing=0 {
                set operObj.Status = "PROCESSED"
                set inboxObj.Status = "DONE"
            }
        } else {
            set operObj.Status = "ERROR"
            set inboxObj.Status = "ERROR-OPERATING"
            // serialize errors
            set operObj.OperErrors = updErrorList
            $$$ThrowOnError(operObj.SerializeOperErrors())
        }
        set inboxObj.UpdatedTS = $zdatetime($horolog,3)

		// append operation log
		if $isobject(operObj.OperLog) {
			do operObj.OperLog.MoveToEnd()
			do operObj.OperLog.CopyFrom(updLog)
		} else {
			set operObj.OperLog = updLog
		}

		$$$ThrowOnError(operObj.%Save())
		$$$ThrowOnError(inboxObj.%Save())

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

}
