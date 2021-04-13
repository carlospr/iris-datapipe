Class DataPipe.Staging.BP.StagingManagerContext Extends Ens.BP.Context
{

/// Current Staging record
Property Staging As DataPipe.Data.Staging;

/// Model object
Property Model As DataPipe.Model;

/// Normalized Model object
Property NormModel As DataPipe.Model;

/// Oper request that will be sent to Oper layer
Property OperReq As DataPipe.Msg.OperReq;

/// Error text (in case of exception)
Property ErrorText As %String(MAXLEN = "");

/// 
/// Init Staging. Create a new Staging record
Method InitStaging(req As DataPipe.Msg.StagingReq) As %Status
{
    set ret = $$$OK
    try {
        set ..Staging = ##class(DataPipe.Data.Staging).%New()
        set ..Staging.SessionId = ..%Process.%SessionId
        set ..Staging.HeaderId = ..%Process.%PrimaryRequestHeader.%Id()
        set ..Staging.CreatedTS = $zdatetime($horolog, 3)
        set ..Staging.Ingestion = req.data
        set ..Staging.Ingestion.Inbox.LastStaging = ..Staging
        set ..Staging.Ingestion.Inbox.LastOper = ""
        set ..Staging.Ingestion.Inbox.Status = "STAGING"
        set ..Staging.Ingestion.Inbox.UpdatedTS = ..Staging.CreatedTS

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Deserialize model into object from Ingestion record
Method DeserializeModel() As %Status
{
    set ret = $$$OK
    try {
        set modelData = ..Staging.Ingestion.ModelData
        set modelName = ..Staging.Ingestion.ModelName
        set sc = $classmethod(modelName, "Deserialize", modelData, .obj)
        $$$ThrowOnError(sc)
        set ..Model = obj
         
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Normalize model and save it into Staging record
Method NormalizeModel() As %Status
{
    set ret = $$$OK
    try {
        // normalize
        $$$ThrowOnError(..Model.Normalize(.norm))
        // save normalized model in context
        set ..NormModel = norm
        // serialize normalized data
        $$$ThrowOnError(norm.Serialize(.stream))
        // store into staging data
        do ..Staging.ModelNormData.CopyFrom(stream)

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Validate model (after normalization)
Method ValidateModel() As %Status
{
    set ret = $$$OK
    try {
        set sc = ..NormModel.Validate(.errorList)
        if $$$ISOK(sc) {
            set ..Staging.Status = "VALID"
        } else {
            $$$LOGERROR($system.Status.GetOneStatusText(sc))
            
            // update status
            set ..Staging.Status = "INVALID"
            set ..Staging.Ingestion.Inbox.Status = "ERROR-STAGING"

            // serialize validation errors
            set ..Staging.ValidationErrors = errorList
            $$$ThrowOnError(..Staging.SerializeValidationErrors())
        }
        
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Save data
Method SaveData() As %Status
{
    quit ..Staging.%Save(1)
}

/// 
/// Build StagingReq message to send to the next layer
Method BuildOperReq() As %Status
{
    set ret = $$$OK
    try {
        set ..OperReq = ##class(DataPipe.Msg.OperReq).%New()
        set ..OperReq.data = ..Staging

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
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
        set ..Staging.Ingestion.Inbox.Status = "ERROR-STAGING"
        $$$ThrowOnError(..Staging.Ingestion.Inbox.%Save())

    } catch ex {
        $$$LOGERROR("INTERNAL ERROR: "_ex.DisplayString())
    }
}

Storage Default
{
<Data name="StagingManagerContextDefaultData">
<Subscript>"StagingManagerContext"</Subscript>
<Value name="1">
<Value>Staging</Value>
</Value>
<Value name="2">
<Value>Model</Value>
</Value>
<Value name="3">
<Value>OperReq</Value>
</Value>
<Value name="4">
<Value>ErrorText</Value>
</Value>
<Value name="5">
<Value>NormModel</Value>
</Value>
</Data>
<DefaultData>StagingManagerContextDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
