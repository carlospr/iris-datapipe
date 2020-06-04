Class DataPipe.Data.Inbox Extends (%Persistent, InboxAttributes, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Inbox";

Parameter OBJPERMISSIONS As %String = "CRUD";

Parameter DISPLAYPROPERTY As %String = "Id";

Parameter FORMORDERBY As %String = "Id";

/// *Calculated* Id. %ID value projected to JSON
Property Id As %Integer(%JSONINCLUDE = "OUTPUTONLY") [ Calculated, SqlComputeCode = { set {*}={%%ID}}, SqlComputed ];

/// Status
Property Status As %String(VALUELIST = ",INGESTING,ERROR-INGESTING,STAGING,ERROR-STAGING,OPERATING,DONE,ERROR-OPERATING,ERROR-GENERAL");

/// Ignored
/// - New occurences of Inbox will not be ingested
/// - Not will be processed for operation
Property Ignored As %Boolean [ InitialExpression = 0 ];

/// Created
Property CreatedTS As %TimeStamp;

/// Updated
Property UpdatedTS As %TimeStamp;

/// Ref. to last Ingestion
Property LastIngestion As Ingestion(%JSONREFERENCE = "ID");

/// Ref. to last Staging 
Property LastStaging As Staging(%JSONREFERENCE = "ID");

/// Ref. to last Oper
Property LastOper As Oper(%JSONREFERENCE = "ID");

/// *Calculated* StagingStatus (from LastStaging). Used in queries from app
Property StagingStatus As %String(MAXLEN = "") [ SqlComputeCode = { set {StagingStatus} = ##class(DataPipe.Data.Inbox).CalcSqlFieldById("LastStaging->Status", "N/A", {%%ID})
}, SqlComputed, SqlComputeOnChange = %%UPDATE ];

/// *Calculated* OperStatus (from LastOper). Used in queries from app
Property OperStatus As %String(MAXLEN = "") [ SqlComputeCode = { set {OperStatus} = ##class(DataPipe.Data.Inbox).CalcSqlFieldById("LastOper->Status", "N/A", {%%ID})
}, SqlComputed, SqlComputeOnChange = %%UPDATE ];

/// *Calculated* ValidationErrorsJson (from LastStaging). Used in queries from app
Property ValidationErrors As %String(MAXLEN = "") [ SqlComputeCode = { set {ValidationErrors} = ##class(DataPipe.Data.Inbox).CalcSqlFieldById("LastStaging->ValidationErrorsJson", "", {%%ID})
}, SqlComputed, SqlComputeOnChange = %%UPDATE ];

/// *Calculated* OperErrorsJson (from LastOper). Used in queries from app
Property OperErrors As %String(MAXLEN = "") [ SqlComputeCode = { set {OperErrors} = ##class(DataPipe.Data.Inbox).CalcSqlFieldById("LastOper->OperErrorsJson", "", {%%ID})
}, SqlComputed, SqlComputeOnChange = %%UPDATE ];

/// *Calculated* OperRetries (from LastOper). Used in queries from app
Property OperRetries As %String(MAXLEN = "") [ SqlComputeCode = { set {OperRetries} = ##class(DataPipe.Data.Inbox).CalcSqlFieldById("LastOper->Retries", "0", {%%ID})
}, SqlComputed, SqlComputeOnChange = %%UPDATE ];

/// Related Ingestions
Relationship Ingestions As Ingestion(%JSONREFERENCE = "ID") [ Cardinality = many, Inverse = Inbox ];

Index PkIdx On (Source, Flow, MsgId) [ Unique ];

Index StatusIdx On Status [ Type = bitmap ];

Index IgnoredIdx On Ignored [ Type = bitmap ];

Index UpdatedTSIdx On UpdatedTS;

Index StagingStatusIdx On StagingStatus [ Type = bitmap ];

Index OperStatusIdx On OperStatus [ Type = bitmap ];

Index SourceIdx On Source [ Type = bitmap ];

Index FlowIdx On Flow [ Type = bitmap ];

Index MsgIdIdx On MsgId;

Index ElementIdx On Element;

Index SubjectIdx On Subject;

/// Classmethod used by RESTForms2 query /form/objects/DataPipe.Data.Inbox/find
ClassMethod queryFIND() As %String
{
  quit "UpdatedTS, Id, Source, Flow, MsgId, Element, Subject, Ignored, Status, StagingStatus, OperStatus, ValidationErrors, OperErrors, OperRetries "
}

/// Get an Inbox record, querying by key attributes
/// This method is used to determine if an Inbox record can be re-used
ClassMethod GetByKeyAttributes(att As InboxAttributes, Output obj As Inbox) As %Status
{
	set ret = $$$OK
	try {
		// valid inbox attributes?
		$$$ThrowOnError(att.IsValid())

		set obj="", inboxId=""

		set sql = "select %id from DataPipe_Data.Inbox where Source=? and Flow=? and MsgId=?"
		set statement = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(statement.%Prepare(sql))

		set result = statement.%Execute(att.Source, att.Flow, att.MsgId)
		if result.%Next() {
			set inboxId = result.%GetData(1)
			set obj = ..%OpenId(inboxId)
		}
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Calculate a SQL field given an Inbox ID
/// This method is used by calculated SQL fields
ClassMethod CalcSqlFieldById(field As %String, default As %String, id As %String) As %String
{
	set ret = default
	try {
		set sql = "select "_field_" from DataPipe_Data.Inbox where %id=?"
		set statement = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(statement.%Prepare(sql))

		set result = statement.%Execute(id)
		if result.%Next() {
			set ret = result.%GetData(1)
			if ret="" set ret=default
		}
		
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit ret
}

/// Change ignore status
Method Ignore() As %Status
{
	set ret = $$$OK
	try {
		set ..Ignored = '..Ignored
		$$$ThrowOnError(..%Save())
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

Storage Default
{
<Data name="InboxDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Source</Value>
</Value>
<Value name="3">
<Value>Flow</Value>
</Value>
<Value name="4">
<Value>MsgId</Value>
</Value>
<Value name="5">
<Value>Element</Value>
</Value>
<Value name="6">
<Value>Status</Value>
</Value>
<Value name="7">
<Value>CreatedTS</Value>
</Value>
<Value name="8">
<Value>UpdatedTS</Value>
</Value>
<Value name="9">
<Value>LastIngestion</Value>
</Value>
<Value name="10">
<Value>LastStaging</Value>
</Value>
<Value name="11">
<Value>LastOper</Value>
</Value>
<Value name="12">
<Value>StagingStatus</Value>
</Value>
<Value name="13">
<Value>OperStatus</Value>
</Value>
<Value name="14">
<Value>Ignored</Value>
</Value>
<Value name="15">
<Value>OperRetries</Value>
</Value>
<Value name="16">
<Value>Subject</Value>
</Value>
<Value name="17">
<Value>ValidationErrors</Value>
</Value>
<Value name="18">
<Value>OperErrors</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.InboxD</DataLocation>
<DefaultData>InboxDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.InboxD</IdLocation>
<IndexLocation>^DataPipe.Data.InboxI</IndexLocation>
<StreamLocation>^DataPipe.Data.InboxS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
