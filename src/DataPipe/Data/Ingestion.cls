Class DataPipe.Data.Ingestion Extends (%Persistent, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Ingestion";

Parameter OBJPERMISSIONS As %String = "R";

Parameter DISPLAYPROPERTY As %String = "Id";

Parameter FORMORDERBY As %String = "Id";

/// *Calculated* Id. %ID value projected to JSON
Property Id As %Integer(%JSONINCLUDE = "OUTPUTONLY") [ Calculated, SqlComputeCode = { set {*}={%%ID}}, SqlComputed ];

/// Model Is Python
Property ModelIsPython As %Boolean(%JSONINCLUDE = "NONE") [ InitialExpression = 0 ];

/// Model class name
Property ModelModule As %String(%JSONINCLUDE = "NONE", MAXLEN = "");

/// Model Module path
Property ModelClassPath As %String(%JSONINCLUDE = "NONE", MAXLEN = "");

/// Model class name 
Property ModelName As %String(MAXLEN = "");

/// Model serialized data
Property ModelData As %Stream.GlobalCharacter;

/// SessionId that triggered the Ingestion
Property SessionId As %String;

/// Interop. HeaderId that triggered the Ingestion
Property HeaderId As %String;

/// Created 
Property CreatedTS As %TimeStamp;

/// parent Inbox
Relationship Inbox As Inbox(%JSONREFERENCE = "ID") [ Cardinality = one, Inverse = Ingestions ];

/// Related Stagings
Relationship Stagings As Staging(%JSONREFERENCE = "ID") [ Cardinality = many, Inverse = Ingestion ];

/// Index
Index InboxIndex On Inbox;

/// RESTForms2 query /form/objects/DataPipe.Data.Ingestion/custom/find
ClassMethod customqueryFIND() As %String
{
	// get parameters
	set filter = $get(%request.Data("filter",1))
	set collation = $get(%request.Data("collation",1))
	
	// filter permitted pipes only
	$$$ThrowOnError(##class(DataPipe.Data.Pipe).GetPermittedPipes("READ", .permittedPipes))
	if $listlength(permittedPipes) > 0 {
		set filter = filter_" Inbox->Pipe in "_$listtostring(permittedPipes, "~")
	}

	// where
	$$$ThrowOnError(##class(Form.JSON.SQL).ParseWhere(filter, collation, "DataPipe.Data.Ingestion", .where))
	
	set sql = "SELECT Id, CreatedTS, HeaderId FROM DataPipe_Data.Ingestion "_where
	return sql
}

/// Read object and export to JSON
ClassMethod toJSON(id As %Integer = "") As %Status
{
	set ret = $$$OK
	try {
		// check that user can access this pipe
		$$$ThrowOnError(##class(DataPipe.Data.Pipe).GetPermittedPipes("READ", .permittedPipes))
		set idObj=""
		&sql(SELECT %id INTO :idObj FROM DataPipe_Data.Ingestion WHERE id = :id and Inbox->Pipe %inlist :permittedPipes)
		if idObj="" $$$ThrowStatus($$$ERROR($$$GeneralError, "Not authorized"))

		// return default restforms implementation
		return ##super(id)
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

Storage Default
{
<Data name="IngestionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>StageModel</Value>
</Value>
<Value name="3">
<Value>StageInput</Value>
</Value>
<Value name="4">
<Value>SessionId</Value>
</Value>
<Value name="5">
<Value>CreatedTS</Value>
</Value>
<Value name="6">
<Value>Inbox</Value>
</Value>
<Value name="7">
<Value>ModelName</Value>
</Value>
<Value name="8">
<Value>Input</Value>
</Value>
<Value name="9">
<Value>ModelClass</Value>
</Value>
<Value name="10">
<Value>Model</Value>
</Value>
<Value name="11">
<Value>ModelData</Value>
</Value>
<Value name="12">
<Value>HeaderId</Value>
</Value>
<Value name="13">
<Value>ModelIsPython</Value>
</Value>
<Value name="14">
<Value>ModelModule</Value>
</Value>
<Value name="15">
<Value>ModelClassPath</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.IngestionD</DataLocation>
<DefaultData>IngestionDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.IngestionD</IdLocation>
<IndexLocation>^DataPipe.Data.IngestionI</IndexLocation>
<StreamLocation>^DataPipe.Data.IngestionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
