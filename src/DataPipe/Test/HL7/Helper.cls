Class DataPipe.Test.HL7.Helper Extends %RegisteredObject
{

/// Generate multiple test ADT HL7 Files
/// do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(100)
ClassMethod GenerateFilesHL7ADT(nfiles As %Integer = 100, outputDir As %String = "/app/data/input/", template As %String = "/app/data/ADTA08.hl7", docType As %String = "2.5:ADT_A01") As %Status
{
    set ret = $$$OK

    try {
        for i=1:1:nfiles {
            // generate random hl7 test file from template
            $$$ThrowOnError(..GenerateHL7({}, template, docType, .hl7))

            // write hl7 file to test production input directory
            $$$ThrowOnError(hl7.OutputToFile(outputDir_"file"_$tr($zts,",.","")_".hl7"))
        }
    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Generate a test hl7 file based on input values
/// - input: DynamicObject which can, optionally, specify properties such as MsgId, PatientId, etc. 
ClassMethod GenerateHL7(input As %DynamicObject = {{}}, template As %String, docType As %String, Output hl7) As %Status
{
    set ret = $$$OK
    try {
        // default values for input
        if input.MsgId="" set input.MsgId = $zconvert(##class(%PopulateUtils).StringMin(3,3),"U")_##class(%PopulateUtils).Integer(99999,999999)
        if input.PatientId="" set input.PatientId = ##class(%PopulateUtils).Integer(99999,999999)
        if input.Name="" set input.Name = ##class(%PopulateUtils).FirstName(1)
        if input.Surname1="" set input.Surname1 = ##class(%PopulateUtils).FirstName()
        if input.Surname2="" set input.Surname2 = ##class(%PopulateUtils).LastName()
        if input.DOB="" set input.DOB = ##class(DataPipe.Test.HL7.Functions).DateToHL7Date(##class(%PopulateUtils).Date($horolog-(365*40)))
        if input.AdministrativeSex="" set input.AdministrativeSex = ##class(%PopulateUtils).ValueList(",M,F,")
        if input.SSN="" set input.SSN = ##class(%PopulateUtils).SSN()
        
        // load template hl7 message
        set hl7 = ##class(EnsLib.HL7.Message).ImportFromFile(template,,.sc)
        $$$ThrowOnError(sc)
        set hl7.DocType = docType

        // set values into message
        do hl7.SetValueAt(input.MsgId, "MSH:10")
        do hl7.SetValueAt(input.PatientId, "PID:2.1")
        do hl7.SetValueAt(input.Name, "PID:5(1).2")
        do hl7.SetValueAt(input.Surname1, "PID:5(1).1.1")
        do hl7.SetValueAt(input.Surname2, "PID:5(1).3")
        do hl7.SetValueAt(input.DOB, "PID:7.1")
        do hl7.SetValueAt(input.AdministrativeSex, "PID:8")
        do hl7.SetValueAt(input.SSN, "PID:19")

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Patient names that will provoke an Ingestion error in test production
ClassMethod IngestionErrorNames() As %String
{
    quit "Edgar,Dick,Xavier"
}

/// Patient names that will provoke a Normalization error in test production
ClassMethod NormalizationErrorNames() As %String
{
    quit "Alfred,James,Kevin"
}

/// Patient names that will provoke an Operation error in test production
ClassMethod OperationErrorNames() As %String
{
    quit "Joe,Martin,Emilio,David,Charles,Bart"
}

}
