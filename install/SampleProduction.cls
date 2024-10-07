Class Test.SampleProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Test.SampleProduction" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Setting Target="Adapter" Name="ShutdownTimeout">5</Setting>
  <Setting Target="Adapter" Name="UpdateTimeout">5</Setting>
  <Item Name="REST API In" Category="" ClassName="DataPipe.Test.REST.BS.ApiService" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="REST Ingestion" Category="Ingestion" ClassName="DataPipe.Test.REST.BP.RESTIngestion" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="REST Staging" Category="Staging" ClassName="DataPipe.Staging.BP.StagingManager" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigName">REST Oper</Setting>
  </Item>
  <Item Name="REST Oper" Category="Oper" ClassName="DataPipe.Oper.BP.OperManager" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Person Operation" Category="Oper" ClassName="DataPipe.Oper.BO.OperationHandler" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="REST Delayed Oper Update" Category="" ClassName="DataPipe.Test.REST.BP.DelayedProcessing" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
</Production>
}

}
