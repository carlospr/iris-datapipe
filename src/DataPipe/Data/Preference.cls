Class DataPipe.Data.Preference Extends (%Persistent, %JSON.Adaptor)
{

/// *Calculated* Id. %ID value projected to JSON
Property Id As %Integer(%JSONINCLUDE = "OUTPUTONLY") [ Calculated, SqlComputeCode = { Set {*}={%%ID}}, SqlComputed ];

Property Scope As %String(VALUELIST = ",user,system");

Property Owner As %String;

Property Key As %String;

Property Value As %String(MAXLEN = "");

Index PkIdx On (Scope, Owner, Key) [ Unique ];

/// Preference values can be like:
/// -Simple value:
/// "value"
/// -Storing fav filters values:
/// "value1|extraProp1_1|extraProp1_2~value2|extraProp2_1|extraProp2_2"
/// > The separator between values is ~
/// > The separator between properties within a value is |
/// > The value itself is the first property and is always returned in Value array, so we only need to know the number of extra properties, that's why it returns the number of elements - 1
/// > All the diferent values must have the same number of properties
ClassMethod getExtraPropertiesNum(settingValue As %String) As %Integer
{
	set firstValue = $piece(settingValue, "~")
	set propertiesNum = $length(firstValue, "|")
	quit propertiesNum - 1
}

Storage Default
{
<Data name="PreferenceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Scope</Value>
</Value>
<Value name="3">
<Value>Owner</Value>
</Value>
<Value name="4">
<Value>Key</Value>
</Value>
<Value name="5">
<Value>Value</Value>
</Value>
</Data>
<DataLocation>^DataPipe.Data.PreferenceD</DataLocation>
<DefaultData>PreferenceDefaultData</DefaultData>
<IdLocation>^DataPipe.Data.PreferenceD</IdLocation>
<IndexLocation>^DataPipe.Data.PreferenceI</IndexLocation>
<StreamLocation>^DataPipe.Data.PreferenceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
