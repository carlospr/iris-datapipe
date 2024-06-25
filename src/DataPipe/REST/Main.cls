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
<Route Url="/resendMessage/:headerId" Method="POST" Call="resendMessage"/>
<Route Url="/ignore/:id" Method="PUT" Call="ignore"/>
</Routes>
}

/// Resend an Interop. message header
/// This method is used to repeat Ingestion, Staging or Operation layers
ClassMethod resendMessage(headerId As %String = "") As %Status
{
	set ret = $$$OK
    try {
		if '##class(DataPipe.Auth).IsAdminUser() {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}

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
		if '##class(DataPipe.Auth).IsAdminUser() {
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
