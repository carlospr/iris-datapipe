Class DataPipe.REST.Main Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/resendMessage/:headerId" Method="POST" Call="resendMessage"/>
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

}
