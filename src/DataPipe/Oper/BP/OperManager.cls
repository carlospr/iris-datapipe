/// 
Class DataPipe.Oper.BP.OperManager Extends Ens.BusinessProcessBPL [ DependsOn = DataPipe.Oper.BP.OperManagerContext ]
{

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='DataPipe.Msg.OperReq' response='Ens.Response' contextsuperclass='DataPipe.Oper.BP.OperManagerContext' height='2000' width='2000' >
<sequence xend='200' yend='1000' >
<scope xpos='200' ypos='250' xend='200' yend='900' >
<code name='Init Oper' xpos='200' ypos='350' >
<![CDATA[ $$$ThrowOnError(context.InitOper(request))]]>
</code>
<code name='Calc TargetOperation' xpos='200' ypos='450' >
<![CDATA[ $$$ThrowOnError(context.CalcTargetOperation())]]>
</code>
<code name='Save Data' xpos='200' ypos='550' >
<![CDATA[ $$$ThrowOnError(context.SaveData())]]>
</code>
<call name='Dispatch to Operation' target='@context.TargetOperation' async='1' xpos='200' ypos='650' >
<request type='DataPipe.Msg.OperReq' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='Ens.Response' />
</call>
<faulthandlers>
<catchall xpos='200' ypos='750' xend='200' yend='450' >
<code name='Get Error Info' xpos='200' ypos='250' >
<![CDATA[ do context.GetErrorInfo()]]>
</code>
<alert name='Alert' value='context.ErrorText' xpos='200' ypos='350' />
</catchall>
</faulthandlers>
</scope>
</sequence>
</process>
}

}
