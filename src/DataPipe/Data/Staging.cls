Class DataPipe.Data.Staging Extends (%Persistent, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Staging";

Parameter OBJPERMISSIONS As %String = "CRUD";

Parameter DISPLAYPROPERTY As %String = "Id";

Parameter FORMORDERBY As %String = "Id";

/// *Calculated* Id. %ID value projected to JSON
Property Id As %Integer(%JSONINCLUDE = "OUTPUTONLY") [ Calculated, SqlComputeCode = { set {*}={%%ID}}, SqlComputed ];

/// Normalized data model (serialized)
Property ModelNormData As %Stream.GlobalCharacter;

/// Validation Errors
Property ValidationErrors As list Of ErrorInfo;

/// Json Serialized ValidationErrors. Used in UI.
Property ValidationErrorsJson As %String(MAXLEN = "");

/// SessionId that triggered the Staging layer
Property SessionId As %String;

/// Interop. HeaderId that triggered the Staging
Property HeaderId As %String;

/// Created
Property CreatedTS As %TimeStamp;

/// Staging layer status
Property Status As %String(VALUELIST = ",N/A,VALID,INVALID,WARNING") [ InitialExpression = "N/A" ];

/// parent Ingestion
Relationship Ingestion As Ingestion(%JSONREFERENCE = "ID") [ Cardinality = one, Inverse = Stagings ];

/// Related Opers
Relationship Opers As Oper(%JSONREFERENCE = "ID") [ Cardinality = many, Inverse = Staging ];

/// Index
Index IngestionIndex On Ingestion;

/// Classmethod used by RESTForms2 query /form/objects/DataPipe.Data.Staging/find
ClassMethod queryFIND() As %String
{
  quit "Id, CreatedTS, HeaderId, Status, ValidationErrorsJson JSON@ValidationErrorsJson"
}

/// Serialize validation errors. Serialized errors will be used in UI.
/// This method must be called after modifying validation errors.
Method SerializeValidationErrors() As %Status
{
	set ret = $$$OK
	set jsonArr=[]
	try {
    set count = ..ValidationErrors.Count()
	for i=1:1:count {
      set code = ..ValidationErrors.GetAt(i).Code
      set desc = ..ValidationErrors.GetAt(i).Desc
      set jsonError = code_": "_desc
      do jsonArr.%Push(jsonError)
	}
	set ..ValidationErrorsJson = jsonArr.%ToJSON()
		
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit ret
}

Storage Default
{
<Data name="StagingDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ModelNormData</Value>
</Value>
<Value name="3">
<Value>ValidationErrors</Value>
</Value>
<Value name="4">
<Value>SessionId</Value>
</Value>
<Value name="5">
<Value>HeaderId</Value>
</Value>
<Value name="6">
<Value>CreatedTS</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>ValidationErrorsJson</Value>
</Value>
<Value name="9">
<Value>Ingestion</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.StagingD</DataLocation>
<DefaultData>StagingDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.StagingD</IdLocation>
<IndexLocation>^DataPipe.Data.StagingI</IndexLocation>
<StreamLocation>^DataPipe.Data.StagingS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
