Class DataPipe.Data.VOper [ ClassType = view, CompileAfter = DataPipe.Data.Oper, DdlAllowed, Owner = {SuperUser}, Not ProcedureBlock, SqlTableName = VOper, ViewQuery = { select * from DataPipe_Data.Oper 
 	where Staging->Ingestion->Inbox->Pipe %inlist (DataPipe_Data.Pipe_PermittedPipes()) /*#OPTIONS {"DynamicSQL":1} */} ]
{

}
