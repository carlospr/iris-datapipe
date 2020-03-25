Class DataPipe.Msg.StagingReq Extends Ens.Request
{

Property data As DataPipe.Data.Ingestion;

Storage Default
{
<Data name="StagingReqDefaultData">
<Subscript>"StagingReq"</Subscript>
<Value name="1">
<Value>data</Value>
</Value>
</Data>
<DefaultData>StagingReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
