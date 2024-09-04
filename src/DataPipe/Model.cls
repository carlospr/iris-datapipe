Class DataPipe.Model [ Abstract ]
{

Method Serialize(Output stream) As %Status
{
    Quit $$$ERROR($$$NotImplemented)
}

ClassMethod Deserialize(stream As %Stream.Object, Output obj) As %Status
{
    Quit $$$ERROR($$$NotImplemented)
}

Method Normalize(Output obj As DataPipe.Model) As %Status
{
    Quit $$$ERROR($$$NotImplemented)
}

Method Validate(Output errorList As %List) As %Status
{
    Quit $$$ERROR($$$NotImplemented)
}

Method GetOperation() As %Status
{
    Quit $$$ERROR($$$NotImplemented)
}

Method RunOperation(Output errorList As %List, Output log As %Stream.Object, bOperation As Ens.BusinessOperation = "", Output delayedProcessing As %Boolean = 0) As %Status
{
    Quit $$$ERROR($$$NotImplemented)
}

}
