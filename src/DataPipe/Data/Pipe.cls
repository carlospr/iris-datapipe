Class DataPipe.Data.Pipe Extends (%Persistent, %XML.Adaptor, Form.Adaptor)
{

Parameter FORMNAME = "Pipe";

Parameter OBJPERMISSIONS As %String = "R";

Parameter DISPLAYPROPERTY As %String = "Code";

Parameter FORMORDERBY As %String = "Code";

/// Code of Pipe (Primary Key)
Property Code As %String;

/// Description
Property Description As %String(MAXLEN = 255);

/// Security Resource that is required to read this Pipe
Property SecurityResource As %String;

Index CodeIdx On Code [ IdKey ];

/// RESTForms2 query /form/objects/DataPipe.Data.Pipe/custom/find
ClassMethod customqueryFIND() As %String
{
	// get parameters
	set filter = $get(%request.Data("filter",1))
	set collation = $get(%request.Data("collation",1))
	
	// filter permitted pipes only
	set permittedPipes = ##class(DataPipe.Data.Pipe).PermittedPipes()
	if $listlength(permittedPipes) > 0 {
        set:filter'="" filter = filter_" "
		set filter = "Code in "_$listtostring(permittedPipes, "~")
	}

	// where
	$$$ThrowOnError(##class(Form.JSON.SQL).ParseWhere(filter, collation, "DataPipe.Data.Pipe", .where))
	
	set sql = "SELECT Code, Description FROM DataPipe_Data.Pipe "_where
	return sql
}

/// Returns actual pipes that user is permitted to use
/// zwrite ##class(DataPipe.Data.Pipe).PermittedPipes()
/// SELECT DataPipe_Data.Pipe_PermittedPipes()
ClassMethod PermittedPipes(pPermission As %String = "READ") As %List [ SqlProc ]
{
	set sql = "select %id, SecurityResource from DataPipe_Data.Pipe"
	set statement = ##class(%SQL.Statement).%New()
	$$$ThrowOnError(statement.%Prepare(sql))

	set result = statement.%Execute()
	set permittedPipes = ""
	while result.%Next() {
		set pipeId = result.%GetData(1)
		set resource = result.%GetData(2)
		if ((resource="") || ##class(%SYSTEM.Security).Check(resource, pPermission)) {
			set permittedPipes = permittedPipes_$lb(pipeId)
		}
	}
  	return permittedPipes
}

Storage Default
{
<Data name="PipeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>SecurityResource</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.PipeD</DataLocation>
<DefaultData>PipeDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.PipeD</IdLocation>
<IndexLocation>^DataPipe.Data.PipeI</IndexLocation>
<StreamLocation>^DataPipe.Data.PipeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
