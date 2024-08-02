Class DataPipe.Test.REST.Helper Extends %RegisteredObject
{

Parameter HOST = "localhost";

Parameter PORT = 52773;

Parameter TIMEOUT = 2;

Parameter USERNAME = "superuser";

Parameter PASSWORD = "SYS";

ClassMethod SendHTTPRequests(pNumRequests As %Integer = 1) As %Status
{
    set ret = $$$OK
    try {
        for i=1:1:pNumRequests {
            set body = {
                "SSN": (##class(%PopulateUtils).SSN()),
                "Name": (##class(%PopulateUtils).FirstName()),
                "Surname": (##class(%PopulateUtils).LastName()),
                "Company": (##class(%PopulateUtils).Company()),
                "DOB": ($zdate(##class(%PopulateUtils).Date($horolog-(365*50)), 3)) 
            }
        
            set headers("X-Forwarded-For") = "client-"_##class(%PopulateUtils).Syllable()
            set headers("X-Request-ID") = $system.Util.CreateGUID()

            set sc = ..Post("/test/api/message", .headers, body, .resp)
            $$$ThrowOnError(sc)

            if resp.StatusCode '= 200 {
                $$$ThrowStatus($$$ERROR($$$GeneralError, "Received HTTP StatusCode="_resp.StatusCode))
            }
            
            //set rspBody = {}.%FromJSON(resp.Data.Read())
        } 
  
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

ClassMethod Post(location As %String, ByRef headers As %List, body As %DynamicObject, Output response As %Net.HttpResponse) As %Status
{
  set ret = $$$OK
  try {
    // build http request
    set httpRequest = ##class(%Net.HttpRequest).%New()
    set httpRequest.Server = ..#HOST
    set httpRequest.Port = ..#PORT
    set httpRequest.Timeout = ..#TIMEOUT

    // add auth
    set auth = "Basic "_$system.Encryption.Base64Encode(..#USERNAME _":"_..#PASSWORD)
    do httpRequest.SetHeader("Authorization", auth)

    // add any other headers
    set header = ""
    for {
        set header = $order(headers(header))
        quit:header=""
        do httpRequest.SetHeader(header, headers(header))
    }

    // add body
    set json = body.%ToJSON()
    do httpRequest.EntityBody.Write(json)
    
    // send request
    $$$ThrowOnError(httpRequest.Post(location))

    // get response
    set response = httpRequest.HttpResponse

  } catch ex {
		set ret = ex.AsStatus()
  }
  quit ret
}

}
