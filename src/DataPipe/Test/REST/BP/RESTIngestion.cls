/// 
Class DataPipe.Test.REST.BP.RESTIngestion Extends Ens.BusinessProcessBPL [ DependsOn = DataPipe.Ingestion.BP.IngestionManagerContext ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='DataPipe.Test.REST.Msg.PersonReq' response='Ens.Response' contextsuperclass='DataPipe.Ingestion.BP.IngestionManagerContext' height='2000' width='2000' >
<sequence xend='200' yend='1450' >
<scope xpos='200' ypos='250' xend='200' yend='800' >
<annotation><![CDATA[REST use case:
- input = msg received in REST service
- output = Model, InboxAttributes]]></annotation>
<transform name='PersonReq To InboxAttributes' class='DataPipe.Test.REST.DT.PersonReqToInboxAttributes' source='request' target='context.InboxAttributes' xpos='200' ypos='350' />
<code name='Set InboxAttributes' xpos='200' ypos='450' >
<![CDATA[ do context.InboxAttributes.PipeSetObjectId("REST-API")]]>
</code>
<transform name='PersonReq to Model' class='DataPipe.Test.REST.DT.PersonReqToModel' source='request' target='context.Model' xpos='200' ypos='550' />
<faulthandlers>
<catchall xpos='200' ypos='650' xend='200' yend='350' >
<code xpos='200' ypos='250' >
<![CDATA[ set errorText = $system.Status.GetOneStatusText(..%Context.%LastError)   
 if ..%Context.%LastFault'="" {
   set errorText = ..%Context.%LastFault
 }
 $$$LOGERROR(errorText)]]>
</code>
</catchall>
</faulthandlers>
</scope>
<scope xpos='200' ypos='900' xend='200' yend='1350' >
<annotation><![CDATA[DataPipe components]]></annotation>
<code name='Ingestion Manager' xpos='200' ypos='1000' >
<![CDATA[ $$$ThrowOnError(context.IngestionManager())]]>
</code>
<call name='To Staging' target='REST Staging' async='1' xpos='200' ypos='1100' >
<request type='DataPipe.Msg.StagingReq' >
<assign property="callrequest" value="context.StagingReq" action="set" languageOverride="" />
</request>
<response type='Ens.Response' />
</call>
<faulthandlers>
<catchall xpos='200' ypos='1200' xend='200' yend='450' >
<code name=' Get Error Info' xpos='200' ypos='250' >
<![CDATA[ do context.GetErrorInfo()]]>
</code>
<alert name='Alert' value='context.ErrorText' xpos='200' ypos='350' />
</catchall>
</faulthandlers>
</scope>
</sequence>
</process>
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
