Class DataPipe.UnitTest.Helper Extends %RegisteredObject
{

ClassMethod FindInboxByMsgId(msgId As %String, Output inbox) As %Status
{
    set ret = $$$OK
	try {
		set inbox="", inboxId=""

		set sql = "select top 1 id from DataPipe_Data.VInbox where MsgId=?"
		set statement = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(statement.%Prepare(sql))

		set result = statement.%Execute(msgId)
		if result.%Next() {
			set inboxId = result.%GetData(1)
			set inbox = ##class(DataPipe.Data.Inbox).%OpenId(inboxId)
		}
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
