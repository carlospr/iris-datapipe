Class DataPipe.Test.HL7.DT.A08Normalize Extends Ens.DataTransformDTL [ DependsOn = DataPipe.Test.HL7.Models.A08 ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='DataPipe.Test.HL7.Models.A08' targetClass='DataPipe.Test.HL7.Models.A08' create='new' language='objectscript' >
<assign value='source' property='target' action='set' />
<assign value='$case(source.AdministrativeSex, "M":"H", "F":"M", :"")' property='target.AdministrativeSex' action='set' >
<annotation>Normalize AdministrativeSex values</annotation>
</assign>
<if condition='..In(source.Name,##class(DataPipe.Test.HL7.Helper).NormalizationErrorNames())' >
<annotation>Simulate Normalization Errors</annotation>
<true>
<code>
<![CDATA[ $$$ThrowStatus($$$ERROR($$$GeneralError, "Simulated Normalization Error"))]]></code>
</true>
</if>
</transform>
}

}
