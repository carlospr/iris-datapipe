Class DataPipe.Task.Purge Extends %SYS.Task.Definition
{

Parameter TaskName = "DataPipe.Task.Purge";

/// Number of days to keep in the database
Property DaysToKeep As %Integer [ InitialExpression = 30 ];

/// Task
Method OnTask() As %Status
{
    set ret = $$$OK
    try {
        do ..Log("=====================================")
		do ..Log("*DataPipe.Task.Purge Begin")
        $$$ThrowOnError(..DeleteData(..DaysToKeep))
        do ..Log("*DataPipe.Task.Purge End")

    } catch ex {
        set ret = ex.AsStatus()
        do ..Log("<ERROR> OnTask: "_$system.Status.GetOneErrorText(ret))
    }
    quit ret
}

/// Purge DataPipe data. Keeps data generated in the last <i>DaysToKeep</i> days.
/// Param <b>pDaysToKeep</b>: Number of days to keep in the database
/// Examples: 
///   do ##class(DataPipe.Task.Purge).DeleteData(0) ; delete all data
///   do ##class(DataPipe.Task.Purge).DeleteData(1) ; keep 1 day of data
ClassMethod DeleteData(pDaysToKeep As %Integer = 30) As %Status
{
    #define HasToBeDeleted(%inbox) ($isobject(%inbox) && (%inbox.Ignored || (%inbox.Status = "DONE")))

    set ret = $$$OK
    set %tDoNotDeleteDate = $zdate(+$horolog - pDaysToKeep, 3)_" 23:59:59"

    try {
        set (ntotal, ndeleted) = 0

        TSTART
        &sql(DECLARE cInbox CURSOR FOR
                select ID into :%tID
                from DataPipe_Data.Inbox
                where CreatedTS < :%tDoNotDeleteDate
                order by CreatedTS, ID)

        &sql(OPEN cInbox)
		quit:(SQLCODE '= 0)

        for {
            &sql(FETCH cInbox)
            quit:(SQLCODE '= 0)
            set ntotal = ntotal + 1

            set inboxItem = ##class(DataPipe.Data.Inbox).%OpenId(%tID)

            if $$$HasToBeDeleted(inboxItem) {
                // delete Ingestions->Stagings->Opers
                $$$ThrowOnError(..DeleteIngestions(inboxItem.Ingestions))
                // delete Inbox
				$$$ThrowOnError(##class(DataPipe.Data.Inbox).%DeleteId(inboxItem.%Id()))
                set ndeleted = ndeleted + 1
            }
        }
        &sql(CLOSE cInbox)
        TCOMMIT
        do ..Log("Total="_ntotal_", Deleted="_ndeleted_$$$NL)

    } catch ex {
        TROLLBACK
        set ret = ex.AsStatus()
        do ..Log("<ERROR> DeleteData: "_$system.Status.GetOneErrorText(ret))
    }
    quit ret
}

/// Delete ingestions and related objects (Ingestions->Stagings->Opers)
ClassMethod DeleteIngestions(ingestions As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Ingestion")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {
        for i = 1:1:ingestions.Count() {
            set ingestion = ingestions.GetAt(i)
            if $isobject(ingestion) {
                $$$ThrowOnError(..DeleteStagings(ingestion.Stagings))
				$$$ThrowOnError(##class(DataPipe.Data.Ingestion).%DeleteId(ingestion.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

/// Delete Stagings and related objects (Stagings->Opers)
ClassMethod DeleteStagings(stagings As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Staging")) As %Status [ Private ]
{
    set tSC = $$$OK
    try {
        for i = 1: 1: stagings.Count() {
            set staging = stagings.GetAt(i)
            if $isobject(staging) {
                $$$ThrowOnError(..DeleteOperations(staging.Opers))
				$$$ThrowOnError(##class(DataPipe.Data.Staging).%DeleteId(staging.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

/// Delete Opers
ClassMethod DeleteOperations(operations As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Oper")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {
        for i = 1: 1: operations.Count() {
            set operation = operations.GetAt(i)
            if $isobject(operation) {
				$$$ThrowOnError(##class(DataPipe.Data.Oper).%DeleteId(operation.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

/// Log a text message
ClassMethod Log(pText As %String, ByRef pInfo)
{
	set tText = $zdt($h,3)_": "_pText
	write !,tText
	zwrite:$d(pInfo) pInfo
}

}
