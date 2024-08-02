Class DataPipe.Test.REST.DT.PersonReqToModel Extends Ens.DataTransformDTL [ DependsOn = (DataPipe.Test.REST.Msg.PersonReq, DataPipe.Test.REST.Models.Person) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='DataPipe.Test.REST.Msg.PersonReq' targetClass='DataPipe.Test.REST.Models.Person' create='new' language='objectscript' >
<assign value='source.XRequestId' property='target.XRequestId' action='set' />
<assign value='source.SSN' property='target.SSN' action='set' />
<assign value='source.Name' property='target.Name' action='set' />
<assign value='source.Surname' property='target.Surname' action='set' />
<assign value='source.DOB' property='target.DOB' action='set' />
<assign value='source.Company' property='target.Company' action='set' />
<assign value='source.XForwardedHost' property='target.XForwardedHost' action='set' />
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
