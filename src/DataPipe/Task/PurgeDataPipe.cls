Class DataPipe.Task.PurgeDataPipe Extends %SYS.Task.Definition
{

Parameter TaskName = "DataPipe.Task.PurgeDataPipe";

Property DaysToKeep As %Integer [ InitialExpression = 30 ];

Method OnTask() As %Status
{
    quit ##class(DataPipe.Util.DataPipeUtils).RemoveDataPipeInfo(..DaysToKeep)
}

}
