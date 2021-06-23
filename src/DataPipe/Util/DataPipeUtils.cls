Import DataPipe.Data

Class DataPipe.Util.DataPipeUtils Extends %RegisteredObject [ Language = objectscript ]
{

// zw ##class(DataPipe.Util.DataPipeUtils).RemoveDataPipeInfo(1)

/// Deletes the info processed pDaysToKeep days or more ago<br>
/// Param <b>pDaysToKeep</b>: Number of days to keep in the database. Default 30
ClassMethod RemoveDataPipeInfo(pDaysToKeep As %Integer = 30) As %Status
{
    #define HasToBeDeleted(%inbox) ($isobject(%inbox) && (%inbox.Ignored || (%inbox.Status = "DONE")))

    set tSC = $$$OK

    set %tDoNotDeleteDate = $zdt($h - pDaysToKeep _ ",0", 3)

    try {
 
        TSTART

        &sql(declare C1 cursor for
                select ID into :%tID
                from DataPipe_Data.Inbox
                where CreatedTS < :%tDoNotDeleteDate
                order by CreatedTS, ID)

        &sql(open C1)
		quit:(SQLCODE '= 0)

        &sql(fetch C1)

        while (SQLCODE = 0) {

            set inboxItem = ##class(Inbox).%OpenId(%tID)

            if $$$HasToBeDeleted(inboxItem) {

                $$$ThrowOnError(..DeleteIngestions(inboxItem.Ingestions))
				$$$ThrowOnError(##class(Inbox).%DeleteId(inboxItem.%Id()))
            }

            &sql(fetch C1)
        }
            
        &sql(close C1)

        TCOMMIT
    } catch ex {

        TROLLBACK

        set tSC = ex.AsStatus()
    }

    quit tSC
}

ClassMethod DeleteIngestions(ingestions As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Ingestion")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {

        for i = 1: 1: ingestions.Count() {

            set ingestion = ingestions.GetAt(i)

            if $isobject(ingestion) {

                $$$ThrowOnError(..DeleteStagings(ingestion.Stagings))
				$$$ThrowOnError(##class(Ingestion).%DeleteId(ingestion.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

ClassMethod DeleteStagings(stagings As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Staging")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {

        for i = 1: 1: stagings.Count() {

            set staging = stagings.GetAt(i)

            if $isobject(staging) {

                $$$ThrowOnError(..DeleteOperations(staging.Opers))
				$$$ThrowOnError(##class(Staging).%DeleteId(staging.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

ClassMethod DeleteOperations(operations As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Oper")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {

        for i = 1: 1: operations.Count() {

            set operation = operations.GetAt(i)

            if $isobject(operation) {

				$$$ThrowOnError(##class(Oper).%DeleteId(operation.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

}
