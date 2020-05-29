Class DataPipe.Ingestion.BP.IngestionManagerContext Extends Ens.BP.Context
{

/// !IMPORTANT. BP must fill this property
/// Model object
Property Model As DataPipe.Model;

/// !IMPORTANT. BP must fill this property
/// Attributes to get/create a related Inbox record
Property InboxAttributes As DataPipe.Data.InboxAttributes;

/// Current Ingestion record
Property Ingestion As DataPipe.Data.Ingestion;

/// Related Inbox record
Property Inbox As DataPipe.Data.Inbox;

/// Staging request that will be sent to Staging layer
Property StagingReq As DataPipe.Msg.StagingReq;

/// Error text (in case of exception)
Property ErrorText As %String(MAXLEN = "");

/// IngestionManager
/// This method must be called from BP after filling Ingestion and Model properties
Method IngestionManager() As %Status
{
    set ret = $$$OK
    try {
        $$$ThrowOnError(..InitInbox())
        // avoid ingesting ignored inboxes
        if '..Inbox.Ignored {
            $$$ThrowOnError(..InitIngestion())
            $$$ThrowOnError(..SerializeModel())
            $$$ThrowOnError(..SaveData())
            $$$ThrowOnError(..BuildStagingReq())
        } else {
           $$$LOGWARNING("Ignoring Inbox "_inbox.%Id()_" because has been set as ignored before") 
        }
        
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Init Inbox. Create or Open an Inbox record
Method InitInbox() As %Status
{
    set ret = $$$OK
    try {
        $$$ThrowOnError(##class(DataPipe.Data.Inbox).GetByKeyAttributes(..InboxAttributes, .inboxObj))
        if '$isobject(inboxObj) {			
			// return new inbox 
			set inboxObj = ##class(DataPipe.Data.Inbox).%New()
            set inboxObj.CreatedTS = $zdatetime($horolog,3)
            set inboxObj.UpdatedTS = inboxObj.CreatedTS
		} else {
			// return existing inbox
            set inboxObj.UpdatedTS = $zdatetime($horolog,3)
		}
        
        $$$ThrowOnError(inboxObj.PopulateAttributes(..InboxAttributes))
        set ..Inbox = inboxObj

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Init Ingestion. Create a new Ingestion record
Method InitIngestion() As %Status
{
    set ret = $$$OK
    try {
        set ..Ingestion = ##class(DataPipe.Data.Ingestion).%New()
        set ..Ingestion.SessionId = ..%Process.%SessionId
        set ..Ingestion.HeaderId = ..%Process.%PrimaryRequestHeader.%Id()
        set ..Ingestion.CreatedTS = $zdatetime($horolog, 3)
        do ..Inbox.Ingestions.Insert(..Ingestion)
        set ..Inbox.LastIngestion = ..Ingestion
        set ..Inbox.LastStaging = ""
        set ..Inbox.LastOper = ""
        set ..Inbox.Status = "INGESTING"
        set ..Inbox.UpdatedTS = ..Ingestion.CreatedTS

        // check model object
        if '$isobject(..Model) {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Model object is required"))
        }
        if '..Model.%Extends("DataPipe.Model") {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Model object must extend DataPipe.Model"))
        }

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Serialize model into Ingestion record
Method SerializeModel() As %Status
{
    set ret = $$$OK
    try {
        $$$ThrowOnError(..Model.Serialize(.stream))
        set ..Ingestion.ModelName = $classname(..Model)
        set ..Ingestion.ModelData = stream
        
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Save all Inbox related data (deep)
Method SaveData() As %Status
{
    quit ..Inbox.%Save(1)
}

/// Build StagingReq message to send to the next phase
Method BuildStagingReq() As %Status
{
    set ret = $$$OK
    try {
        set ..StagingReq = ##class(DataPipe.Msg.StagingReq).%New()
        set ..StagingReq.data = ..Ingestion
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

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
        set ..Ingestion.Inbox.Status = "ERROR-INGESTING"
        $$$ThrowOnError(..Ingestion.Inbox.%Save())

    } catch ex {
        $$$LOGERROR("INTERNAL ERROR: "_ex.DisplayString())
    }
}

Storage Default
{
<Data name="InboxManagerContextDefaultData">
<Subscript>"InboxManagerContext"</Subscript>
<Value name="1">
<Value>MyName</Value>
</Value>
<Value name="2">
<Value>Inbox</Value>
</Value>
<Value name="3">
<Value>Ingestion</Value>
</Value>
<Value name="4">
<Value>StageInput</Value>
</Value>
<Value name="5">
<Value>StageModel</Value>
</Value>
<Value name="6">
<Value>Model</Value>
</Value>
<Value name="7">
<Value>StagingReq</Value>
</Value>
<Value name="8">
<Value>InboxAttributes</Value>
</Value>
<Value name="9">
<Value>ErrorText</Value>
</Value>
</Data>
<DefaultData>InboxManagerContextDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
