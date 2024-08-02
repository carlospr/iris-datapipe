Class DataPipe.Test.REST.DT.PersonNormalize Extends Ens.DataTransformDTL [ DependsOn = DataPipe.Test.REST.Models.Person ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='DataPipe.Test.REST.Models.Person' targetClass='DataPipe.Test.REST.Models.Person' create='copy' language='objectscript' >
<if condition='..In(source.Name,##class(DataPipe.Test.HL7.Helper).NormalizationErrorNames())' >
<annotation>Simulate Normalization Errors</annotation>
<true>
<code>
<![CDATA[ $$$ThrowStatus($$$ERROR($$$GeneralError, "Simulated Normalization Error"))]]></code>
</true>
</if>
<assign value='..ToLower(source.Company)' property='target.Company' action='set' />
<assign value='..ToLower(source.Surname)' property='target.Surname' action='set' />
<assign value='..ToLower(source.Name)' property='target.Name' action='set' />
</transform>
}

}
