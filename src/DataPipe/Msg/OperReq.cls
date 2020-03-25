Class DataPipe.Msg.OperReq Extends Ens.Request
{

Property data As DataPipe.Data.Staging;

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
