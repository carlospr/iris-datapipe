Class DataPipe.Data.VInbox [ ClassType = view, CompileAfter = DataPipe.Data.Inbox, DdlAllowed, Owner = {SuperUser}, Not ProcedureBlock, SqlTableName = VInbox, ViewQuery = { select * from DataPipe_Data.Inbox 
 	where Pipe %inlist (DataPipe_Data.Pipe_PermittedPipes()) /*#OPTIONS {"DynamicSQL":1} */} ]
{

}
