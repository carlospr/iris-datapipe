Class DataPipe.Test.Helper Extends %RegisteredObject
{

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
        
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

}
