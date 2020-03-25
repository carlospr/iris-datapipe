/// 
Class DataPipe.Staging.BP.StagingManager Extends Ens.BusinessProcessBPL [ DependsOn = DataPipe.Staging.BP.StagingManagerContext ]
{

Property TargetConfigName As %String;

Parameter SETTINGS = "TargetConfigName:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

ClassMethod OnGetConnections(ByRef pArray As %String, pItem As Ens.Config.Item)
{
  Do pItem.PopulateModifiedSettings()
	Set (tValue,tIndex)="" For {
		Set tSetting = pItem.ModifiedSettings.GetNext(.tIndex) Quit:tIndex=""
		If tSetting.Name="TargetConfigName" Set tValue=tSetting.Value  Quit
	}
	For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
}

Storage Default
{
<Data name="StagingManagerDefaultData">
<Subscript>"StagingManager"</Subscript>
<Value name="1">
<Value>TargetConfigName</Value>
</Value>
</Data>
<DefaultData>StagingManagerDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='DataPipe.Msg.StagingReq' response='Ens.Response' contextsuperclass='DataPipe.Staging.BP.StagingManagerContext' height='2000' width='2000' >
<sequence xend='200' yend='1550' >
<scope xpos='200' ypos='250' xend='200' yend='1450' >
<code name='Init Staging' xpos='200' ypos='350' >
<![CDATA[ $$$ThrowOnError(context.InitStaging(request))]]>
</code>
<code name='Deserialize Model' xpos='200' ypos='450' >
<![CDATA[ $$$ThrowOnError(context.DeserializeModel())]]>
</code>
<code name='Normalize Model' xpos='200' ypos='550' >
<![CDATA[ $$$ThrowOnError(context.NormalizeModel())]]>
</code>
<code name='Validate Model' xpos='200' ypos='650' >
<![CDATA[ $$$ThrowOnError(context.ValidateModel())]]>
</code>
<code name='Save Data' xpos='200' ypos='750' >
<![CDATA[ $$$ThrowOnError(context.SaveData())]]>
</code>
<if name='Valid?' condition='context.Staging.Status="VALID"' xpos='200' ypos='850' xend='200' yend='1200' >
<true>
<code name='Build OperReq' xpos='200' ypos='950' >
<![CDATA[ $$$ThrowOnError(context.BuildOperReq())]]>
</code>
<call name='To Oper' target='@process.TargetConfigName' async='1' xpos='200' ypos='1050' >
<request type='DataPipe.Msg.OperReq' >
<assign property="callrequest" value="context.OperReq" action="set" />
</request>
<response type='Ens.Response' />
</call>
</true>
</if>
<faulthandlers>
<catchall xpos='200' ypos='1300' xend='200' yend='450' >
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
