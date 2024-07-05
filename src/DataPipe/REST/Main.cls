Class DataPipe.REST.Main Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!-- restforms2 -->
<Map Prefix="/rf2" Forward="Form.REST.Main"/>
<!-- datapipe -->
<Route Url="/login" Method="POST" Call="doLogin"/>
<Route Url="/getUserInfo" Method="GET" Call="getUserInfo"/>
<Route Url="/inboxActivity" Method="GET" Call="getInboxActivitySummary"/>
<Route Url="/resendMessage/:headerId" Method="POST" Call="resendMessage"/>
<Route Url="/ignore/:id" Method="PUT" Call="ignore"/>
</Routes>
}

/// Return Inbox summary. This is used in dashboard (UI)
ClassMethod getInboxActivitySummary() As %Status
{
	set ret = $$$OK
	try {
		// TODO: handle parameters
		//
		// get parameters
		//set filter = $get(%request.Data("filter",1))
		//set collation = $get(%request.Data("collation",1))
		// where
		//$$$ThrowOnError(##class(Form.JSON.SQL).ParseWhere(filter, collation, "DataPipe.Data.Inbox", .where))

		// ok, errors query
		set sqlStatus = "select count(*) from DataPipe_Data.VInbox where Status %INLIST ? and Pipe = ? and Ignored = ?"
		set stmStatus = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(stmStatus.%Prepare(sqlStatus))

		// warning query
		set sqlWarning = "select count(*) from DataPipe_Data.VInbox where StagingStatus = ? and Pipe = ? and Ignored = ?"
		set stmWarning = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(stmWarning.%Prepare(sqlWarning))
		
		set permittedPipes = ##class(DataPipe.Data.Pipe).PermittedPipes()
		set jsonObj = {}

		for p=1:1:$listlength(permittedPipes) {
			set pipe = $listget(permittedPipes, p)

			set jsonPipe = { "errors": 0, "ok": 0, "warnings": 0 }
			
			// errors
			set result = stmStatus.%Execute($lb("ERROR-OPERATING","ERROR-STAGING","ERROR-INGESTING","ERROR-GENERAL"), pipe, 0)
			if result.%Next() {
				set jsonPipe.errors = result.%GetData(1)
			}
			// ok
			set result = stmStatus.%Execute($lb("DONE","OPERATING","STAGING","INGESTING"), pipe, 0)
			if result.%Next() {
				set jsonPipe.ok = result.%GetData(1)
			}
			// warning
			set result = stmWarning.%Execute("WARNING", pipe, 0)
			if result.%Next() {
				set jsonPipe.warnings = result.%GetData(1)
			}

			do jsonObj.%Set(pipe, jsonPipe)
		}

		do jsonObj.%ToJSON()
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Resend an Interop. message header
/// This method is used to repeat Ingestion, Staging or Operation layers
ClassMethod resendMessage(headerId As %String = "") As %Status
{
	set ret = $$$OK
    try {
		if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}

		do $system.Security.Login("_Ensemble")
        $$$ThrowOnError(##class(Ens.MessageHeader).NewDuplicatedMessage(.duplicatedHeader, headerId, ""))
		$$$ThrowOnError(##class(Ens.Queue).EnQueue(duplicatedHeader,1))

    } catch ex {
        set ret = ex.AsStatus()
    }
	
	return ret
}

/// Change inbox ignored status
ClassMethod ignore(id As %String) As %Status
{
	set ret = $$$OK
	try {
		if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}
		
		// open object
		set obj = ##class(DataPipe.Data.Inbox).%OpenId(id,,.sc)
		$$$ThrowOnError(sc)
			
		// return result
		write "{""result"": """_obj.Ignore()_"""}"	
				
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// DataPipe login
/// Authentication is already done at this point (e.g. Basic)
ClassMethod doLogin() As %Status
{
	return $$$OK
}

/// Retrive user info (e.g. specific DataPipe auth attribs.)
ClassMethod getUserInfo() As %Status
{
	set ret = $$$OK
	try {
		set jsonObj={}
		set jsonObj.username = $username
		do jsonObj.%Set("fullName", ##class(DataPipe.Auth).GetFullName())
		do jsonObj.%Set("permissions", ##class(DataPipe.Auth).GetPermissions())

		write jsonObj.%ToJSON()	
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
