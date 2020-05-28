Class DataPipe.REST.Main Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
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

}
