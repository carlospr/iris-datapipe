Class DataPipe.Test.HL7.Models.A08 Extends (%RegisteredObject, %XML.Adaptor, %JSON.Adaptor, DataPipe.Model)
{

Property MsgId As %String;

Property PatientId As %String;

Property Name As %String;

Property Surname1 As %String;

Property Surname2 As %String;

Property DOB As %Date;

Property AdministrativeSex As %String;

Property SSN As %String;

/// Serialize to json
Method Serialize(Output stream) As %Status
{
    set ret = $$$OK
    try {
        // serialize to json
        $$$ThrowOnError(..%JSONExportToStream(.tmpStream))
        
        // format json
        set formatter = ##class(%JSON.Formatter).%New()
        $$$ThrowOnError(formatter.FormatToStream(tmpStream, .stream))

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Deserialize from json
ClassMethod Deserialize(stream As %Stream.Object, Output obj) As %Status
{
    set ret = $$$OK
    try {
        set obj = ..%New()
        $$$ThrowOnError(obj.%JSONImport(stream, .obj))

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Normalize model
Method Normalize(Output obj As DataPipe.Model) As %Status
{
    set ret = $$$OK
    try {
        // call normalizaton data transform
        set sc = $classmethod("DataPipe.Test.HL7.DT.A08Normalize", "Transform", $this, .obj)
        $$$ThrowOnError(sc)

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Validate model
Method Validate(Output errorList As %List) As %Status
{
    #define AddError(%list, %code, %desc) set error = ##class(DataPipe.Data.ErrorInfo).%New() set error.Code=%code set error.Desc=%desc do %list.Insert(error)
	
    set ret = $$$OK
    try {
        set errorList = ##class(%ListOfObjects).%New()

        // administrative sex
        if ..AdministrativeSex="" $$$AddError(errorList, "VGEN", "AdministrativeSex required")

        // date of birth
        if ..DOB="" { 
            $$$AddError(errorList, "V001", "DOB required")
        }
        else {
            set yearDOB = $extract($zdate(..DOB,8),1,4)
            if (yearDOB < 1930) $$$AddError(errorList, "V002", "DOB must be greater than 1930")
            if (yearDOB < 1983) $$$AddError(errorList, "W083", "Warning! Older than 1983")
        }

        // model is invalid if errors (not warnings) found
        for i=1:1:errorList.Count() {
            set error = errorList.GetAt(i)
            set errorCode = error.Code

            // in this sample model, all warnings start with "W"
            if errorCode'["W" {
                $$$ThrowStatus($$$ERROR($$$GeneralError, "Invalid"))
            }
		}
       
    } catch ex {
        set ret = ex.AsStatus()
    }

    quit ret
}

/// Return the Business Operation name that will run the operation with the model
/// Each Business Operation can be used to hold different queues
Method GetOperation() As %Status
{
    // use FIFO BO (failure timeout=-1) when MsgId contains FIFO
    if ..MsgId["FIFO" {
        quit "FIFO A08 Operation"
    }

    // use regular BO
    quit "A08 Operation"
}

/// Run final operation with the model
/// This method can be used to persit data from the model to an operational data store
Method RunOperation(Output errorList As %List, Output log As %Stream.Object) As %Status
{
    #define AddError(%list, %code, %desc) set error = ##class(DataPipe.Data.ErrorInfo).%New() set error.Code=%code set error.Desc=%desc do %list.Insert(error)
    #define AddLog(%log, %msg) do %log.WriteLine("["_$zdt($h,3)_"] "_%msg)
	
    set errorList = ##class(%ListOfObjects).%New()
    set log = ##class(%Stream.GlobalCharacter).%New()

    set ret = $$$OK
    try {
        TSTART
        $$$AddLog(log, "Transaction Started")

        // simulate an operation error
        if ##class(Ens.Util.FunctionSet).In(..Name, ##class(DataPipe.Test.HL7.Helper).OperationErrorNames()) {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Simulated Operation Error"))
        }

        // store serialized model
        $$$ThrowOnError(..Serialize(.stream))
        set ^zDataPipe($i(^zDataPipe)) = stream.Read()
        $$$AddLog(log, "Model Stored in ^zDataPipe("_$get(^zDataPipe)_")")

        TCOMMIT
        $$$AddLog(log, "Transaction Commited")

    } catch ex {
        TROLLBACK 
        $$$AddLog(log, "Rollback!")

        set ret = ex.AsStatus()
        $$$AddLog(log, "Error catched: "_$system.Status.GetOneStatusText(ret))

        // include exception errors into errorList
        do $system.Status.DecomposeStatus(ret, .errors)
		for i=1:1:errors {
			$$$AddError(errorList, "Exception", errors(i))
		}
    }
    quit ret
}

}
