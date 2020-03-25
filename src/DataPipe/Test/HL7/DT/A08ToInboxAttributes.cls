Class DataPipe.Test.HL7.DT.A08ToInboxAttributes Extends Ens.DataTransformDTL [ DependsOn = (EnsLib.HL7.Message, DataPipe.Data.InboxAttributes) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='EnsLib.HL7.Message' targetClass='DataPipe.Data.InboxAttributes' sourceDocType='2.5:ADT_A01' create='new' language='objectscript' >
<assign value='source.{MSH:MessageControlID}' property='target.MsgId' action='set' />
<assign value='source.{PID:PatientID.IDNumber}' property='target.Element' action='set' />
</transform>
}

}
