Class DataPipe.Data.InboxAttributes Extends (%RegisteredObject, %XML.Adaptor)
{

Property Source As %String;

Property Flow As %String;

Property MsgId As %String;

Property Element As %String;

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
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
