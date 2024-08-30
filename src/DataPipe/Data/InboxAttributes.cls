Class DataPipe.Data.InboxAttributes Extends (%RegisteredObject, %XML.Adaptor)
{

/// data source
Property Source As %String(MAXLEN = "");

/// data pipe
Property Pipe As Pipe;

/// message identifier
Property MsgId As %String(MAXLEN = "");

/// data element (e.g. visitnumber)
Property Element As %String(MAXLEN = "");

/// data subject (e.g. patient)
Property Subject As %String(MAXLEN = "");

Method IsValid() As %Status
{
	set ret = $$$OK
	try {
		if ((..Source="")||(..Pipe="")||(..MsgId="")) {
			$$$ThrowStatus($$$ERROR($$$GeneralError, "Inbox Source, Pipe and MsgId are required"))
		}

	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

Method PopulateAttributes(att As InboxAttributes) As %Status
{
	set ret = $$$OK
	try {
		// if Pipe is already an object
		if (($isobject(att.Pipe)) && ($classname(att.Pipe)="DataPipe.Data.Pipe")) {
			set ..Pipe = att.Pipe
		}
		// if not, assume is the id of an DataPipe.Data.Pipe object
		else {
			do ..PipeSetObjectId(att.Pipe)
		}

		// at this point, Pipe must be a valid object
		if (('$isobject(..Pipe)) || ($classname(..Pipe)'="DataPipe.Data.Pipe")) {
			$$$ThrowStatus($$$ERROR($$$GeneralError, "Invalid Pipe specified ("_..Pipe_")"))
		}

		set ..Source = att.Source
		set ..MsgId = att.MsgId
		set ..Element = att.Element
		set ..Subject = att.Subject
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
