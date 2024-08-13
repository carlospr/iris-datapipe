Class DataPipe.REST.Objects Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/DataPipe.Data.Pipe/:id" Method="PUT" Call="UpdatePipe"/>
    <Route Url="/DataPipe.Data.Pipe" Method="POST" Call="CreatePipe"/>
</Routes>
}

/// Updates a Pipe
ClassMethod UpdatePipe(id As %String) As %Status
{
    set ret = $$$OK
    try {
        if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}

        set obj = ##class(DataPipe.Data.Pipe).%OpenId(id)
        if '$isobject(obj) {
            set %response.Status = ..#HTTP404NOTFOUND
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Pipe does not exist"))
        }
        
        // parse body
        set body = {}.%FromJSON(%request.Content)
        $$$ThrowOnError(obj.%JSONImport(body))
        
        // save
        $$$ThrowOnError(obj.%Save())
        set %response.Status = ..#HTTP200OK

    } catch ex {
        set ret = ex.AsStatus() 
    }  
 
    return ret
}

/// Creates a Pipe
ClassMethod CreatePipe() As %Status
{
    set ret = $$$OK

    if '##class(%SYSTEM.Security).Check("DP_ADMIN", "USE") {
        set %response.Status=..#HTTP401UNAUTHORIZED
        quit
	}

    try {
        set obj = ##class(DataPipe.Data.Pipe).%New()
        
        // parse body
        set body = {}.%FromJSON(%request.Content)
        $$$ThrowOnError(obj.%JSONImport(body))

        // save
        $$$ThrowOnError(obj.%Save())
        set %response.Status = ..#HTTP201CREATED
        do obj.%JSONExport()
        
    } catch ex {
        set ret = ex.DisplayString() 
    }  
    
    return ret
}

}
