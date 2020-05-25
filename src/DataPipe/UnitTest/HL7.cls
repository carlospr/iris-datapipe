/// UnitTests for DataPipe.Test.HL7 package
Class DataPipe.UnitTest.HL7 Extends %UnitTest.TestCase
{

/// ingestion BP in test production where test messages will be sent
Parameter TargetIngestion = "HL7 Ingestion";

/// wait after sending a message to test production and checking the outcome 
Parameter WaitTime = .5;

/// Delete data after running tests
Method OnAfterAllTests() As %Status
{
  quit ##class(DataPipe.Test.Helper).KillData()
}

/// Send an HL7 Test message.
/// input: DynamicObject that specify main properties
/// target: target business host to send the message in the test production
/// inbox (output): related Inbox record 
Method SendTestMessage(input As %DynamicObject, target As %String, Output inbox) As %Status
{
  // create test message
  set sc = ##class(DataPipe.Test.HL7.Helper).GenerateHL7(input, "/app/data/ADTA08.hl7", "2.5:ADT_A01", .hl7)
  do $$$AssertStatusOK(sc, "created test hl7 message")

  // send message
  set sc = ##class(EnsLib.Testing.Service).SendTestRequest(target, hl7, .rsp, .sessionId, 1)
  do $$$AssertStatusOK(sc, "sent message to "_target)
  hang ..#WaitTime  ; wait after sending a message, as BP are not sync.

  // check values
  set sc = ##class(DataPipe.UnitTest.Helper).FindInboxByMsgId(input.MsgId, .inbox)
  do $$$AssertStatusOK(sc, "FindInboxByMsgId. MsgId="_input.MsgId)
  do $$$AssertEquals($isobject(inbox), 1, "inbox found. Id="_inbox.Id)
}

/// ERROR-INGESTING after error on DT while converting input to Model
Method TestErrorIngesting()
{
    set input = { 
      "MsgId": "ErrorIngesting",
      "Name": ($piece(##class(DataPipe.Test.HL7.Helper).IngestionErrorNames(), ",", 1)),
      "AdministrativeSex": "M"
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "ERROR-INGESTING")
    do $$$AssertEquals(inbox.LastStaging, "")
    do $$$AssertEquals(inbox.LastOper, "")
}

/// ERROR-STAGING after error while normalizing model data
Method TestErrorStagingNormalization()
{
    set input = { 
      "MsgId": "ErrorStagingNormalization",
      "Name": ($piece(##class(DataPipe.Test.HL7.Helper).NormalizationErrorNames(), ",", 1)),
      "AdministrativeSex": "M" 
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "ERROR-STAGING")
    do $$$AssertEquals(inbox.LastStaging.Status, "N/A")
    do $$$AssertEquals(inbox.LastOper, "")
}

/// ERROR-STAGING after error while validating model data
Method TestErrorStagingValidation()
{
    set input = { 
      "MsgId": "ErrorStagingValidation",
      "Name": "Test",
      "AdministrativeSex": "M",
      "DOB": "19140301"                   ; validation error. dob < 1930
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "ERROR-STAGING")
    do $$$AssertEquals(inbox.LastStaging.Status, "INVALID")
    do $$$AssertEquals(inbox.LastStaging.ValidationErrorsJson, "[""V002: DOB must be greater than 1930""]")
    do $$$AssertEquals(inbox.LastOper, "")
}

/// ERROR-OPERATING after error while trying to run operation on the model
Method TestErrorOperating()
{
    set input = { 
      "MsgId": "ErrorOperating",
      "Name": ($piece(##class(DataPipe.Test.HL7.Helper).OperationErrorNames(), ",", 1)),
      "AdministrativeSex": "M"
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "ERROR-OPERATING")
    do $$$AssertEquals(inbox.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox.LastOper.Status, "ERROR")
}

/// DONE record processed correctly
Method TestDone()
{
    set input = { 
      "MsgId": "Done",
      "Name": "Test",
      "AdministrativeSex": "M" 
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "DONE")
    do $$$AssertEquals(inbox.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox.LastOper.Status, "PROCESSED")
}

}
