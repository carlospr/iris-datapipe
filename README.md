
# DEVELOPMENT

## Run
Run containers:
```
docker-compose up
```

## Test
In IRIS:
Generate hl7 sample messages:
```
do ##class(DataPipe.Test.Helper).GenerateFilesHL7ADT(100)
```

Delete data (if needed):
```
do ##class(DataPipe.Test.Helper).KillData()
```

## datapipeUI
Credentials: superuser/SYS

http://localhost:4200/datapipe