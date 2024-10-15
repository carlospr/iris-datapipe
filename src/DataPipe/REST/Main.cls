Class DataPipe.REST.Main Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!-- restforms2 -->
<Map Prefix="/rf2" Forward="Form.REST.Main"/>
<!-- object operations (e.g. CRUD) -->
<Map Prefix="/objects" Forward="DataPipe.REST.Objects"/>
<!-- other actions -->
<Route Url="/login" Method="POST" Call="doLogin"/>
<Route Url="/getUserInfo" Method="GET" Call="getUserInfo"/>
<Route Url="/inboxActivity" Method="GET" Call="getInboxActivitySummary"/>
<Route Url="/repeat" Method="POST" Call="multiRepeat"/>
<Route Url="/ignore" Method="PUT" Call="multiIgnore"/>
<Route Url="/operRequest/:headerId" Method="PUT" Call="updateOperRequest"/>
</Routes>
}

/// Return Inbox summary. This is used in dashboard (UI)
/// Example:
/// {
///   "HL7-ADT": { "ok": 174, "errors": 126,"inprogress": 0, "warnings": 19 },
///   "REST-API": { "ok": 478, "errors": 22, "inprogress": 0, "warnings": 78 }
/// }
ClassMethod getInboxActivitySummary() As %Status
{
	set ret = $$$OK
	try {
		// get parameters
		set updatedTSFrom = $tr($get(%request.Data("UpdatedTSFrom",1)),"TZ"," ")
		set updatedTSTo = $tr($get(%request.Data("UpdatedTSTo",1)), "TZ", " ")

		// status query
		set sqlStatus = "select pipe, count(id1) from DataPipe_Data.VInbox where Status %INLIST ? and Ignored = ? and UpdatedTS between TO_POSIXTIME(?, 'YYYY-MM-DD HH24:MI:SS') and TO_POSIXTIME(?, 'YYYY-MM-DD HH24:MI:SS') group by Pipe"
		set stmStatus = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(stmStatus.%Prepare(sqlStatus))

		// warning query
		set sqlWarning = "select pipe, count(id1) from DataPipe_Data.VInbox where StagingStatus = ? and Ignored = ? and UpdatedTS between TO_POSIXTIME(?, 'YYYY-MM-DD HH24:MI:SS') and TO_POSIXTIME(?, 'YYYY-MM-DD HH24:MI:SS') group by Pipe"
		set stmWarning = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(stmWarning.%Prepare(sqlWarning))

		kill tmp

		// ok
		set result = stmStatus.%Execute($lb("DONE"), 0, updatedTSFrom, updatedTSTo)
		while result.%Next() {
			set pipe = result.%GetData(1), count = result.%GetData(2)
			set tmp(pipe, "ok") = count
		}
		
		// in progress
		set result = stmStatus.%Execute($lb("OPERATING","STAGING","INGESTING"), 0, updatedTSFrom, updatedTSTo)
		while result.%Next() {
			set pipe = result.%GetData(1), count = result.%GetData(2)
			set tmp(pipe, "inprogress") = count
		}

		// errors
		set result = stmStatus.%Execute($lb("ERROR-OPERATING","ERROR-STAGING","ERROR-INGESTING","ERROR-GENERAL"), 0, updatedTSFrom, updatedTSTo)
		while result.%Next() {
			set pipe = result.%GetData(1), count = result.%GetData(2)
			set tmp(pipe, "errors") = count
		}

		// warning
		set result = stmWarning.%Execute("WARNING", 0, updatedTSFrom, updatedTSTo)
		while result.%Next() {
			set pipe = result.%GetData(1), count = result.%GetData(2)
			set tmp(pipe, "warnings") = count
		}

		set jsonObj = {}

		set pipe=""
		for {
			set pipe=$order(tmp(pipe))
			quit:pipe=""
			set ok=$get(tmp(pipe, "ok"),0), errors=$get(tmp(pipe, "errors"),0), inprogress=$get(tmp(pipe, "inprogress"),0), warnings=$get(tmp(pipe, "warnings"),0)
			do jsonObj.%Set(pipe, {"ok": (ok), "errors": (errors), "inprogress": (inprogress), "warnings": (warnings)} )
		}
		
		do jsonObj.%ToJSON()
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Repeat an Inbox Ingestion, Staging or Operation
/// This is used from UI: multi-select some inbox records and click "Repeat"
/// 
/// Input:
///   { 
///     "ids": [ 10, 33 ], 		/* inbox ids */		
///     "type": "ingestion" 	/* ingestion|staging|operation */
///   }
/// Output:
///   { "ok": { total: 2 , "ids": [ 10, 33 ] }
///   { "error": { total: 0, "ids": [] }
ClassMethod multiRepeat() As %Status
{
	set ret = $$$OK
    try {
		if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}
		new $namespace
		set defaultNs = $namespace

		// parse body
        set input = {}.%FromJSON(%request.Content)
		set output = { "ok": { "total": 0, "ids": [] },  "error": { "total": 0, "ids": [] }}

		set iter = input.ids.%GetIterator()
		while iter.%GetNext(.key, .value) { 
			set id = value

			try {
				// open object
				set obj = ##class(DataPipe.Data.Inbox).%OpenId(id,,.sc)
				$$$ThrowOnError(sc)

				// get header
				set headerId = ""
				if input.type="ingestion" {
					set headerId = obj.LastIngestion.HeaderId
				} elseif input.type="staging" {
					set headerId = obj.LastStaging.HeaderId
				} elseif input.type="operation" {
					set headerId = obj.LastOper.HeaderId
				} else {
					$$$ThrowStatus($$$ERROR($$$GeneralError, "Invalid type"))
				}
				
				// change namespace, this is used when DataPipe is mapped to multiple namespaces
				if obj.Namespace'="" {
					set $namespace = obj.Namespace
				} else {
					set $namespace = defaultNs
				}

				// resend interop message
				;do $system.Security.Login("_Ensemble")
        		$$$ThrowOnError(##class(Ens.MessageHeader).NewDuplicatedMessage(.duplicatedHeader, headerId, ""))
				$$$ThrowOnError(##class(Ens.Queue).EnQueue(duplicatedHeader,1))

				set output.ok.total = output.ok.total + 1
				do output.ok.ids.%Push(id)

			} catch exErr {
				set output.error.total = output.error.total + 1
				do output.error.ids.%Push(id)
			}
		}

		// return result
		write output.%ToJSON()

    } catch ex {
        set ret = ex.AsStatus()
    }
	
	return ret
}

/// Change Inbox visibility status (Ignore property)
/// This is used from UI: multi-select some inbox records and click "Hide"
/// 
/// Input:
///   { 
///     "ids": [ 10, 33 ]	/* inbox ids */ 
///   }
/// Output:
///   { "ok": { total: 2 , "ids": [ 10, 33 ] }
///   { "error": { total: 0, "ids": [] }
ClassMethod multiIgnore() As %Status
{
	set ret = $$$OK
	try {
		if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}
		
		// parse body
        set input = {}.%FromJSON(%request.Content)
		set output = { "ok": { "total": 0, "ids": [] },  "error": { "total": 0, "ids": [] }}

		set iter = input.ids.%GetIterator()
		while iter.%GetNext(.key, .value) { 
			set id = value

			try {
				// open object
				set obj = ##class(DataPipe.Data.Inbox).%OpenId(id,,.sc)
				$$$ThrowOnError(sc)
				// change visibility
				$$$ThrowOnError(obj.Ignore())

				set output.ok.total = output.ok.total + 1
				do output.ok.ids.%Push(id)

			} catch exErr {
				set output.error.total = output.error.total + 1
				do output.error.ids.%Push(id)
			}
		}
			
		// return result
		write output.%ToJSON()	
				
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

/// Updates an OperRequest.
/// This is used when manually editing normalized data
ClassMethod updateOperRequest(headerId As %String = "") As %Status
{
	set ret = $$$OK
    try {
		if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}

		// get header and operRequest message
		set header = ##class(Ens.MessageHeader).%OpenId(headerId)
		set operRequest = ##class(DataPipe.Msg.OperReq).%OpenId(header.MessageBodyId)

		// override normalized data 
		$$$ThrowOnError(operRequest.data.ModelNormData.CopyFromAndSave(%request.Content))
		
		// resend OperRequest
		do $system.Security.Login("_Ensemble")
        $$$ThrowOnError(##class(Ens.MessageHeader).NewDuplicatedMessage(.duplicatedHeader, headerId, ""))
		$$$ThrowOnError(##class(Ens.Queue).EnQueue(duplicatedHeader,1))

    } catch ex {
        set ret = ex.AsStatus()
    }
	
	return ret
}

}
