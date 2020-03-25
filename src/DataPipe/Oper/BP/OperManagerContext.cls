Class DataPipe.Oper.BP.OperManagerContext Extends Ens.BP.Context
{

/// Current Oper record
Property Oper As DataPipe.Data.Oper;

/// Model object
Property Model As DataPipe.Model;

/// Name of the Business Operation to send the OperRequest to final operation
Property TargetOperation As %String;

/// Error text (in case of exception)
Property ErrorText As %String(MAXLEN = "");

/// 
/// Init Oper. Create a new Oper record
Method InitOper(req As DataPipe.Msg.OperReq) As %Status
{
    set ret = $$$OK
    try {
        set ..Oper = ##class(DataPipe.Data.Oper).%New()
        set ..Oper.SessionId = ..%Process.%SessionId
        set ..Oper.HeaderId = ..%Process.%PrimaryRequestHeader.%Id()
        set ..Oper.CreatedTS = $zdatetime($horolog, 3)
        set ..Oper.Staging = req.data
        set ..Oper.Staging.Ingestion.Inbox.LastOper = ..Oper

        set ..Oper.Staging.Ingestion.Inbox.Status = "OPERATING"
        set ..Oper.Staging.Ingestion.Inbox.UpdatedTS = ..Oper.CreatedTS 

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Deserialize normalized data model from Staging
Method DeserializeModel() As %Status
{
    set ret = $$$OK
    try {
        set modelData = ..Oper.Staging.ModelNormData
        set modelName = ..Oper.Staging.Ingestion.ModelName
        set sc = $classmethod(modelName, "Deserialize", modelData, .obj)
        $$$ThrowOnError(sc)
        set ..Model = obj
         
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Calculate which TargetOperation (BO) use to send the OperRequest for final processing
Method CalcTargetOperation() As %Status
{
    set ret = $$$OK
    try {
        $$$ThrowOnError(..DeserializeModel())
        set ..TargetOperation = ..Model.GetOperation()

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Save data
Method SaveData() As %Status
{
    quit ..Oper.%Save(1)
}

/// 
/// Error handling in BP
Method GetErrorInfo()
{
    try {
        // get error
        set errorText = $system.Status.GetOneStatusText(..%Context.%LastError)   
        if ..%Context.%LastFault'="" {
            set errorText = ..%Context.%LastFault
        }
        $$$LOGERROR(errorText)
        set ..ErrorText = errorText

        // update status
        set ..Oper.Staging.Ingestion.Inbox.Status = "ERROR-OPER"
        $$$ThrowOnError(..Oper.Staging.Ingestion.Inbox.%Save())

    } catch ex {
        $$$LOGERROR("INTERNAL ERROR: "_ex.DisplayString())
    }
}

Storage Default
{
<Data name="OperManagerContextDefaultData">
<Subscript>"OperManagerContext"</Subscript>
<Value name="1">
<Value>Oper</Value>
</Value>
<Value name="2">
<Value>Model</Value>
</Value>
<Value name="3">
<Value>TargetOperation</Value>
</Value>
<Value name="4">
<Value>ErrorText</Value>
</Value>
</Data>
<DefaultData>OperManagerContextDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
