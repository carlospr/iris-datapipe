/// 
Class DataPipe.Test.REST.BP.DelayedProcessing Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='DataPipe.Msg.OperReq' response='Ens.Response' height='2000' width='2000' >
<sequence xend='200' yend='450' >
<trace name='Trace' value='"Example of delayed operation update"' xpos='200' ypos='250' >
<annotation><![CDATA[Here you could call other Processes or Operations and perform the tasks you need]]></annotation>
</trace>
<code name='Update Operation' xpos='200' ypos='350' >
<annotation><![CDATA[Inbox record will be updated]]></annotation>
<![CDATA[ // simulate some time consuming task
 hang .2
 
 // create a new log entry
 set log = ##class(%Stream.GlobalCharacter).%New()
 do log.WriteLine("["_$zdt($h,3)_"] This has been updated later in other Business Process")
 
 // update inbox
 $$$ThrowOnError(##class(DataPipe.Manager).UpdateOperation(request.GetInboxId(), 0, $$$OK, "", log))]]>
</code>
</sequence>
</process>
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
