Class DataPipe.Test.REST.BS.ApiService Extends (%CSP.REST, Ens.BusinessService)
{

XData UrlMap
{
<Routes>
    <Route Url="/message" Method="POST" Call="NewMessage"/>
</Routes>
}

/// Common
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
    set %response.ContentType = "application/json"
    Quit $$$OK
}

ClassMethod NewMessage() As %Status
{
    set ret = $$$OK
    try {
        // request body
        set body = %request.Content

        // create interop message from incoming body
        set msg = ##class(DataPipe.Test.REST.Msg.PersonReq).%New()
        $$$ThrowOnError(msg.%JSONImport(body))

        // set some msg fields using HTTP header values
        set msg.XRequestId = %request.GetCgiEnv("HTTP_X_REQUEST_ID")
        set msg.XForwardedHost = %request.GetCgiEnv("HTTP_X_FORWARDED_FOR")

        // process SurgifitResultReq in interoperability production Business Service
        $$$ThrowOnError(##class(Ens.Director).CreateBusinessService("REST API In",.service))
        $$$ThrowOnError(service.OnProcessInput(msg))

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Override this method to process incoming data. Do not call SendRequestSync/Async() from outside this method (e.g. in a SOAP Service or a CSP page).
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	set ret = $$$OK
    try {
        $$$ThrowOnError(..SendRequestAsync("REST Ingestion", pInput))

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

}
