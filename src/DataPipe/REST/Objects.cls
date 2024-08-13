Class DataPipe.REST.Objects Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <!-- Preferences -->
    <Route Url="/DataPipe.Data.Preference/:scope/:owner/:key" Method="PUT" Call="SetPreference"/>
    <Route Url="/DataPipe.Data.Preference/:scope/:owner/:key" Method="GET" Call="GetPreference"/>
    <!-- Pipe -->
    <Route Url="/DataPipe.Data.Pipe/:id" Method="PUT" Call="UpdatePipe"/>
    <Route Url="/DataPipe.Data.Pipe" Method="POST" Call="CreatePipe"/>
</Routes>
}

/// Sets a user preference
ClassMethod SetPreference(scope As %String, owner As %String, key As %String) As %Status
{
    set ret = $$$OK
    try {
        if (scope'="user") {
            // allow only setting user level preferences
            set %response.Status=..#HTTP401UNAUTHORIZED
            quit
        }
        if ($zcvt(owner,"L")'=$zcvt($username,"L")) {
            // allow setting only own preferences
			set %response.Status=..#HTTP401UNAUTHORIZED
			quit
		}
        set obj = ##class(DataPipe.Data.Preference).PkIdxOpen(scope, owner, key)
        if '$isobject(obj) {
            set obj = ##class(DataPipe.Data.Preference).%New()
            set obj.Scope = scope
            set obj.Owner = owner
            set obj.Key = key
        }

        // parse body
        set body = {}.%FromJSON(%request.Content)
        
        // save value
        set obj.Value = body.value
        $$$ThrowOnError(obj.%Save())
        set %response.Status = ..#HTTP200OK

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Get a user preference
ClassMethod GetPreference(scope As %String, owner As %String, key As %String) As %Status
{
    set ret = $$$OK
    try {
        if (scope'="user") {
            // allow only setting user level preferences
            set %response.Status=..#HTTP401UNAUTHORIZED
            quit
        }
        set obj = ##class(DataPipe.Data.Preference).PkIdxOpen(scope, owner, key)
        if '$isobject(obj) {
            set %response.Status = ..#HTTP404NOTFOUND
            quit
        }
        set value = obj.Value

        // prepare actual response
        set rsp = {}

        // preferences can be like:
        // simple: value
        // complex (for filters): value1|extraProp1_1|extraProp1_2~value2|extraProp2_1|extraProp2_2
        set extraPropertiesNum = ##class(DataPipe.Data.Preference).getExtraPropertiesNum(value)
	    for i = 1: 1: extraPropertiesNum {
		    set setting = rsp.%Set("ExtraProperty" _ i, [])
	    }

        // add value to response
	    set rsp.Value = []
        set valueList = $listfromstring(value, "~")
        set ptr = 0, arrayIdx = 0
        while $listNext(valueList, ptr, valueObj) {
            set value = $piece(valueObj, "|")
            do rsp.Value.%Push(value)

            for i = 1: 1: extraPropertiesNum {
                set extraPropertyValue = $piece(valueObj, "|", i + 1)
                set setting = rsp.%Set("ExtraProperty" _ i, rsp.%Get("ExtraProperty"_i).%Set(arrayIdx, extraPropertyValue))
            }
            do $i(arrayIdx)
        }

        // write response
        write rsp.%ToJSON()
        set %response.Status = ..#HTTP200OK

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
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
