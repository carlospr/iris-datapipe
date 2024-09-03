Class DataPipe.Msg.OperReq Extends Ens.Request
{

Property data As DataPipe.Data.Staging;

/// Returns the Inbox Id related to this OperReq
Method GetInboxId() As %String
{
   return ..data.Ingestion.Inbox.%Id()
}

Storage Default
{
<Data name="OperReqDefaultData">
<Subscript>"OperReq"</Subscript>
<Value name="1">
<Value>data</Value>
</Value>
</Data>
<DefaultData>OperReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
