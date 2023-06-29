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
        if ..Staging.Ingestion.ModelIsPython {
            // Set python path
            do ##class(DataPipe.Helper).SetPythonPath(..Staging.Ingestion.ModelClassPath)
            set ..Model = ##class(DataPipe.Helper).GetPythonInstance(..Staging.Ingestion.ModelModule, ..Staging.Ingestion.ModelName)
            do ..Model.Deserialize(..Staging.Ingestion.ModelData)

        } else {
            set modelData = ..Staging.Ingestion.ModelData
            set modelName = ..Staging.Ingestion.ModelName
            set sc = $classmethod(modelName, "Deserialize", modelData, .obj)
            $$$ThrowOnError(sc)
            set ..Model = obj
        }
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
        if ..Staging.Ingestion.ModelIsPython {
            set ..NormModel = ##class(%SYS.Python).%New()
            // normalize
            set ..NormModel = ..Model.Normalize()
            // serialize normalized data
            set stream = ..NormModel.Serialize()
            // store into staging data
            do ..Staging.ModelNormData.CopyFrom(stream)
        } else {
            // normalize
            $$$ThrowOnError(..Model.Normalize(.norm))
            // save normalized model in context
            set ..NormModel = norm
            // serialize normalized data
            $$$ThrowOnError(norm.Serialize(.stream))
            // store into staging data
            do ..Staging.ModelNormData.CopyFrom(stream)
        }

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
        set sc = $$$OK
        if ..Staging.Ingestion.ModelIsPython {
            try {
                set errorList = ..NormModel.validate()
                // Embedded python have a clunky way of handeling list
                // I have tried build %ListOfDataTypes from python and it does not work
                // So I have to build the list here
                set list = ##class(%ListOfDataTypes).%New()
                for i=1:1:errorList.Count() {
                    do list.Insert(errorList.GetAt(i))
                }
                set errorList = list
            } catch ex {
                set sc = ex.AsStatus()
                // set the error list based on the exception
                set errorList = ##class(%ListOfDataTypes).%New()
                set err = ##class(DataPipe.Data.ErrorInfo).%New()
                set err.Code = "PYTHON-VALIDATION-ERROR"
                set err.Desc = $system.Status.GetOneStatusText(sc)
                do errorList.Insert(err)
            }
        } else {
            set sc = ..NormModel.Validate(.errorList)
        }
        if $$$ISOK(sc) {
            set ..Staging.Status = "VALID"
            if errorList.Count() > 0 {
                set ..Staging.Status = "WARNING"
            }
        } else {
            $$$LOGERROR($system.Status.GetOneStatusText(sc))
            
            // update status
            set ..Staging.Status = "INVALID"
            set ..Staging.Ingestion.Inbox.Status = "ERROR-STAGING"
        }

        // serialize validation errors
        set ..Staging.ValidationErrors = errorList
        $$$ThrowOnError(..Staging.SerializeValidationErrors())

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// Save data
Method SaveData() As %Status
{
    set ret = $$$OK
    try {
        // save actual staging data
        $$$ThrowOnError(..Staging.%Save(1))
        
        // force dummy inbox update to re-calculate all calculated properties
        set id = ..Staging.Ingestion.Inbox.%Id()
        &sql(update DataPipe_Data.Inbox set UpdatedTS = UpdatedTS where %id=:id)

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
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
