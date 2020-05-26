Class DataPipe.Test.HL7.DT.A08ToModel Extends Ens.DataTransformDTL [ DependsOn = (EnsLib.HL7.Message, DataPipe.Test.HL7.Models.A08) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='EnsLib.HL7.Message' targetClass='DataPipe.Test.HL7.Models.A08' sourceDocType='2.5:ADT_A01' create='new' language='objectscript' >
<assign value='source.{MSH:MessageControlID}' property='target.MsgId' action='set' />
<assign value='source.{PID:PatientID.IDNumber}' property='target.PatientId' action='set' />
<assign value='source.{PID:PatientName(1).GivenName}' property='target.Name' action='set' />
<assign value='source.{PID:PatientName(1).FamilyName.Surname}' property='target.Surname1' action='set' />
<assign value='source.{PID:PatientName(1).SecondandFurtherGivenNamesor}' property='target.Surname2' action='set' />
<assign value='source.{PID:AdministrativeSex}' property='target.AdministrativeSex' action='set' />
<assign value='source.{PID:SSNNumberPatient}' property='target.SSN' action='set' />
<assign value='##class(DataPipe.Test.HL7.Functions).HL7DateToDate(source.{PID:DateTimeofBirth.Time})' property='target.DOB' action='set' />
<if condition='..In(target.Name,##class(DataPipe.Test.HL7.Helper).IngestionErrorNames())' >
<annotation>Simulate Ingestion Errors</annotation>
<true>
<code>
<![CDATA[  $$$ThrowStatus($$$ERROR($$$GeneralError, "Simulated Ingestion Error"))]]></code>
</true>
</if>
</transform>
}

}
