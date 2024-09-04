Class DataPipe.Manager
{

/// Use this method to perform an update to a Inbox Operation stage
/// inboxId: id of Inbox
/// delayedProcessing: 0 if this is supposed to be the last update and you want to consider the Inbox DONE if OK, 1 if there will be further updates
/// updSC: status of the update ($$$OK or error)
/// updErrorList: list of errors
/// updLog: stream with a log that will be appended to the Inbox Operation
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
