from bp import HL7Ingestion

CLASSES = {
    "DataPipe.Python.HL7Ingestion": HL7Ingestion
}

PRODUCTIONS = [
    {
    "DataPipe.Python.Production": {
        "@Name": "DataPipe.Python.Production",
        "@TestingEnabled": "true",
        "@LogGeneralTraceEvents": "true",
        "Description": "",
        "ActorPoolSize": "2",
        "Setting": [
            {
                "@Target": "Adapter",
                "@Name": "ShutdownTimeout",
                "#text": "5"
            },
            {
                "@Target": "Adapter",
                "@Name": "UpdateTimeout",
                "#text": "5"
            }
        ],
        "Item": [
            {
                "@Name": "HL7 In",
                "@Category": "Ingestion",
                "@ClassName": "EnsLib.HL7.Service.FileService",
                "@PoolSize": "1",
                "@Enabled": "true",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": "",
                "Setting": [
                    {
                        "@Target": "Adapter",
                        "@Name": "ArchivePath"
                    },
                    {
                        "@Target": "Adapter",
                        "@Name": "FilePath",
                        "#text": "/app/data/input"
                    },
                    {
                        "@Target": "Adapter",
                        "@Name": "FileSpec",
                        "#text": "*.hl7"
                    },
                    {
                        "@Target": "Host",
                        "@Name": "TargetConfigNames",
                        "#text": "HL7 Ingestion"
                    },
                    {
                        "@Target": "Host",
                        "@Name": "MessageSchemaCategory",
                        "#text": "2.5"
                    }
                ]
            },
            {
                "@Name": "HL7 Staging",
                "@Category": "Staging",
                "@ClassName": "DataPipe.Staging.BP.StagingManager",
                "@PoolSize": "1",
                "@Enabled": "true",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": "",
                "Setting": {
                    "@Target": "Host",
                    "@Name": "TargetConfigName",
                    "#text": "HL7 Oper"
                }
            },
            {
                "@Name": "HL7 Oper",
                "@Category": "Oper",
                "@ClassName": "DataPipe.Oper.BP.OperManager",
                "@PoolSize": "1",
                "@Enabled": "true",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": ""
            },
            {
                "@Name": "A08 Operation",
                "@Category": "Oper",
                "@ClassName": "DataPipe.Oper.BO.OperationHandler",
                "@PoolSize": "1",
                "@Enabled": "true",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": ""
            },
            {
                "@Name": "HL7 Ingestion",
                "@Category": "Ingestion",
                "@ClassName": "DataPipe.Python.HL7Ingestion",
                "@PoolSize": "1",
                "@Enabled": "true",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": ""
            },
            {
                "@Name": "FIFO A08 Operation",
                "@Category": "Oper",
                "@ClassName": "DataPipe.Oper.BO.OperationHandler",
                "@PoolSize": "1",
                "@Enabled": "true",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": "",
                "Setting": [
                    {
                        "@Target": "Host",
                        "@Name": "FailureTimeout",
                        "#text": "-1"
                    },
                    {
                        "@Target": "Host",
                        "@Name": "ReplyCodeActions",
                        "#text": "E=R"
                    },
                    {
                        "@Target": "Host",
                        "@Name": "RetryInterval",
                        "#text": "3"
                    }
                ]
            },
            {
                "@Name": "Dummy",
                "@Category": "",
                "@ClassName": "EnsLib.File.PassthroughOperation",
                "@PoolSize": "1",
                "@Enabled": "false",
                "@Foreground": "false",
                "@Comment": "",
                "@LogTraceEvents": "false",
                "@Schedule": ""
            }
        ]
    }
}
]

if __name__ == '__main__':
    from grongier.pex import Utils
    Utils.set_classes_settings(CLASSES)
    Utils.set_productions_settings(PRODUCTIONS)