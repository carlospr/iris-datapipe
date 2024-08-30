Class DataPipe.Data.Inbox Extends (%Persistent, InboxAttributes, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Inbox";

Parameter OBJPERMISSIONS As %String = "R";

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

Index PkIdx On (Source, Pipe, MsgId) [ Unique ];

Index StatusIdx On Status [ Type = bitmap ];

Index IgnoredIdx On Ignored [ Type = bitmap ];

Index UpdatedTSIdx On UpdatedTS;

Index StagingStatusIdx On StagingStatus [ Type = bitmap ];

Index OperStatusIdx On OperStatus [ Type = bitmap ];

Index SourceIdx On Source [ Type = bitmap ];

Index PipeIdx On Pipe [ Type = bitmap ];

Index MsgIdIdx On MsgId;

Index ElementIdx On Element;

Index SubjectIdx On Subject;

/// Open callback. Check user can access record in view
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	set id = ..%Id()
    &sql(SELECT id INTO :idObj FROM DataPipe_Data.VInbox WHERE id = :id)
	if idObj="" $$$ThrowStatus($$$ERROR($$$GeneralError, "Not authorized"))
	return $$$OK
}

/// RESTForms2 query /form/objects/DataPipe.Data.Inbox/custom/find
ClassMethod customqueryFIND() As %String
{
	// get parameters
	set filter = $get(%request.Data("filter",1))
	set collation = $get(%request.Data("collation",1))

	// where
	$$$ThrowOnError(##class(Form.JSON.SQL).ParseWhere(filter, collation, "DataPipe.Data.Inbox", .where))
	$$$ThrowOnError(##class(Form.JSON.SQL).ParseOrderBy(%request.Get("orderby"), "DataPipe.Data.Inbox", .orderBy))
	
	set sql = "SELECT UpdatedTS, Id, Source, Pipe, MsgId, Element, Subject, Ignored, Status, StagingStatus, OperStatus, ValidationErrors JSON@ValidationErrors, OperErrors JSON@OperErrors, OperRetries FROM DataPipe_Data.VInbox "_where_orderBy
	return sql
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

		set sql = "select %id from DataPipe_Data.Inbox where Source=? and Pipe->Code=? and MsgId=?"
		set statement = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(statement.%Prepare(sql))

		set result = statement.%Execute(att.Source, att.Pipe.Code, att.MsgId)
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
<Value>Pipe</Value>
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
