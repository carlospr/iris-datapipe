Class DataPipe.Data.VIngestion [ ClassType = view, CompileAfter = DataPipe.Data.Ingestion, DdlAllowed, Owner = {SuperUser}, Not ProcedureBlock, SqlTableName = VIngestion, ViewQuery = { select * from DataPipe_Data.Ingestion 
 	where Inbox->Pipe %inlist (DataPipe_Data.Pipe_PermittedPipes()) /*#OPTIONS {"DynamicSQL":1} */} ]
{

}
