Class DataPipe.Test.REST.DT.PersonReqToInboxAttributes Extends Ens.DataTransformDTL [ DependsOn = (DataPipe.Test.REST.Msg.PersonReq, DataPipe.Data.InboxAttributes) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='DataPipe.Test.REST.Msg.PersonReq' targetClass='DataPipe.Data.InboxAttributes' create='new' language='objectscript' >
<assign value='source.XRequestId' property='target.MsgId' action='set' />
<assign value='source.Company' property='target.Element' action='set' />
<assign value='source.SSN' property='target.Subject' action='set' />
<assign value='source.XForwardedHost' property='target.Source' action='set' />
</transform>
}

}
