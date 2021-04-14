/// UnitTests for DataPipe.Test.HL7 package
Class DataPipe.UnitTest.HL7 Extends %UnitTest.TestCase
{

/// ingestion BP in test production where test messages will be sent
Parameter TargetIngestion = "HL7 Ingestion";

/// secs to wait after sending a message to test production and checking the outcome 
Parameter WaitTime = .5;

/// secs to wait for a FIFO retry
Parameter WaitTimeFIFO = 5;

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
  set sc = ##class(DataPipe.Test.HL7.Helper).GenerateHL7(input, 0, "/app/data/ADTA08.hl7", "2.5:ADT_A01", .hl7)
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
    do $$$AssertEquals(inbox.LastStaging.ValidationErrorsJson, "[""V002: DOB must be greater than 1930"",""W083: Warning! Older than 1983""]")
    do $$$AssertEquals(inbox.LastOper, "")
}

/// DONE but Warning while validating model
Method TestDoneWarning()
{
    set input = { 
      "MsgId": "DoneWarning",
      "Name": "Test",
      "AdministrativeSex": "M",
      "DOB": "19800301"                   ; warning error. dob < 1983
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "DONE")
    do $$$AssertEquals(inbox.LastStaging.Status, "WARNING")
    do $$$AssertEquals(inbox.LastStaging.ValidationErrorsJson, "[""W083: Warning! Older than 1983""]")
    do $$$AssertEquals(inbox.LastOper.Status, "PROCESSED")
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

/// Ignored message
Method TestIgnored()
{
    // send a regular message
    set input = { 
      "MsgId": "Ignored",
      "Name": "Test",
      "AdministrativeSex": "M" 
    }
    do ..SendTestMessage(input, ..#TargetIngestion, .inbox)
    do $$$AssertEquals(inbox.Status, "DONE")
    do $$$AssertEquals(inbox.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox.LastOper.Status, "PROCESSED")

    // set inbox as ignored
    do $$$AssertStatusOK(inbox.Ignore())
    do $$$AssertEquals(inbox.Ignored, 1)

    // send again same message. must have same inbox, and set as ignored
    do ..SendTestMessage(input, ..#TargetIngestion, .newInbox)
    do $$$AssertEquals(newInbox.%Id(), inbox.%Id())
    do $$$AssertEquals(newInbox.Status, inbox.Status)
    do $$$AssertEquals(newInbox.UpdatedTS, inbox.UpdatedTS)
    do $$$AssertEquals(newInbox.LastIngestion.%Id(), inbox.LastIngestion.%Id())
    do $$$AssertEquals(newInbox.LastStaging.%Id(), inbox.LastStaging.%Id())
    do $$$AssertEquals(newInbox.LastOper.%Id(), inbox.LastOper.%Id())
    do $$$AssertEquals(newInbox.Ignored, 1)
}

/// FIFO + Ignored behaviour
Method TestFIFO()
{
    // msg1 - error processing, keep retrying
    set input1 = { 
      "MsgId": "FIFO-1-Error",
      "Name": ($piece(##class(DataPipe.Test.HL7.Helper).OperationErrorNames(), ",", 1)),
      "AdministrativeSex": "M"
    }
    do ..SendTestMessage(input1, ..#TargetIngestion, .inbox1)
    do $$$AssertEquals(inbox1.Status, "ERROR-OPERATING")
    do $$$AssertEquals(inbox1.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox1.LastOper.Status, "ERROR")
    do $$$AssertEquals(inbox1.Ignored, 0)
    do $$$LogMessage("waiting: fifo operation failing & retrying...")
    hang ..#WaitTimeFIFO

    // msg2 - queued
    set input2 = { 
      "MsgId": "FIFO-2-OK",
      "Name": "Test",
      "AdministrativeSex": "M"
    }
    do ..SendTestMessage(input2, ..#TargetIngestion, .inbox2)
    do $$$AssertEquals(inbox2.Status, "OPERATING")
    do $$$AssertEquals(inbox2.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox2.LastOper.Status, "N/A")

    // ignore msg1 => msg1 will be done, msg2 will be processed
    do $$$AssertStatusOK(inbox1.Ignore())
    do $$$AssertEquals(inbox1.Ignored, 1)
    do $$$LogMessage("waiting: inbox ignored, will be skipped on next retry...")
    hang ..#WaitTimeFIFO

    do $$$AssertStatusOK(inbox1.%Reload())
    do $$$AssertEquals(inbox1.Status, "DONE")
    do $$$AssertEquals(inbox1.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox1.LastOper.Status, "IGNORED")
    
    do $$$AssertStatusOK(inbox2.%Reload())
    do $$$AssertEquals(inbox2.Status, "DONE")
    do $$$AssertEquals(inbox2.LastStaging.Status, "VALID")
    do $$$AssertEquals(inbox2.LastOper.Status, "PROCESSED")
}

}
