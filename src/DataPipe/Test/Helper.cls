Class DataPipe.Test.Helper Extends %RegisteredObject
{

ClassMethod QuickStart() As %Status
{
    set ret = $$$OK
    try {
        // create sample pipes
        write !,"Creating pipes: HL7-ADT, REST-API ..."
        &sql(INSERT INTO DataPipe_Data.Pipe (Code, Description, SecurityResource) values ('HL7-ADT', 'Sample HL7 Pipe', 'DP_PIPE_HL7ADT'))
        &sql(INSERT INTO DataPipe_Data.Pipe (Code, Description) values ('REST-API', 'A REST API Pipe'))

        // generate sample data
        write !,"Creating sample HL7-ADT data ..."
        do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(300)
        write !,"Creating sample REST-API data ..."
        do ##class(DataPipe.Test.REST.Helper).SendHTTPRequests(500)

        write !,"Done."
        
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// 
/// !IMPORTANT. Use only on development environment
/// Kill all data
/// do ##class(DataPipe.Test.Helper).KillData()
ClassMethod KillData() As %Status
{
    set ret = $$$OK

    try {
        $$$ThrowOnError(##class(DataPipe.Data.Oper).%KillExtent())
        $$$ThrowOnError(##class(DataPipe.Data.Staging).%KillExtent())
        $$$ThrowOnError(##class(DataPipe.Data.Ingestion).%KillExtent())
        $$$ThrowOnError(##class(DataPipe.Data.Inbox).%KillExtent())
        $$$ThrowOnError(##class(DataPipe.Data.Pipe).%KillExtent())
        
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

}
