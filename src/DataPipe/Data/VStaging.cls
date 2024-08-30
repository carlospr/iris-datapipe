Class DataPipe.Data.VStaging [ ClassType = view, CompileAfter = DataPipe.Data.Staging, DdlAllowed, Owner = {SuperUser}, Not ProcedureBlock, SqlTableName = VStaging, ViewQuery = { select * from DataPipe_Data.Staging 
 	where Ingestion->Inbox->Pipe %inlist (DataPipe_Data.Pipe_PermittedPipes()) /*#OPTIONS {"DynamicSQL":1} */} ]
{

}
