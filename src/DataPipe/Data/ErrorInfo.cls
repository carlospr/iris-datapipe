Class DataPipe.Data.ErrorInfo Extends (%SerialObject, %XML.Adaptor, %JSON.Adaptor)
{

Property Code As %String(MAXLEN = "");

Property Desc As %String(MAXLEN = "");

Storage Default
{
<Data name="ErrorInfoState">
<Value name="1">
<Value>Code</Value>
</Value>
<Value name="2">
<Value>Desc</Value>
</Value>
</Data>
<State>ErrorInfoState</State>
<StreamLocation>^DataPipe.Data.ErrorInfoS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
