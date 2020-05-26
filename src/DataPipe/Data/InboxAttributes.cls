Class DataPipe.Data.InboxAttributes Extends (%RegisteredObject, %XML.Adaptor)
{

/// data source
Property Source As %String(MAXLEN = "");

/// data workflow
Property Flow As %String(MAXLEN = "");

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
		if ((..Source="")||(..Flow="")||(..MsgId="")) {
			$$$ThrowStatus($$$ERROR($$$GeneralError, "Inbox Source, Flow and MsgId are required"))
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
		set ..Source = att.Source
		set ..Flow = att.Flow
		set ..MsgId = att.MsgId
		set ..Element = att.Element
		set ..Subject = att.Subject
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
