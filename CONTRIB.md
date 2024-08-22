
Please, go through the following steps if you want to contribute to this project:

1. Report an issue. Describe it as much as possible.
2. Fork the repository, create a new branch.
3. Develop your changes, make sure all unit tests are working. Add new unit tests as needed.
4. Create a pull request.

# Development Environment
Build:
```bash
docker compose build
```

Run:
```bash
docker compose up
```

IRIS instance:
* *Credentials*: `superuser` / `SYS`
* *URL*: http://localhost:52773/csp/sys/UtilHome.csp

See [README.md](./README.md), QuickStart section.

# Utils
Generate 100 sample hl7 files for processing in test production:
```objectscript
do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(100)
```

Generate 100 REST requests for processing in test production:
```objectscript
do ##class(DataPipe.Test.REST.Helper).SendHTTPRequests(100)
```

Delete `DataPipe.Data.*` data:
```objectscript
do ##class(DataPipe.Test.Helper).KillData()
```

# Unit Tests
Open an IRIS interactive session:
```bash
docker exec -it datapipe bash
iris session IRIS
```

Run all unit tests:
```objectscript
zn "dpipe"
set ^UnitTestRoot = "/app/src/DataPipe/UnitTest"
do ##class(%UnitTest.Manager).RunTest("", "/nodelete")
```

Run an specific test case:
```objectscript
zn "dpipe"
set ^UnitTestRoot = "/app/src/DataPipe/UnitTest"
do ##class(%UnitTest.Manager).RunTest(":DataPipe.UnitTest.HL7:TestDone", "/nodelete")
```

# Testing Upgrade from previous versions to DataPipe2

Run a container with a brand new IRIS (upgrade)
```bash
docker compose -f upgrade.yml up -d
```

Install ipm
```bash
docker compose -f upgrade.yml exec -it iris bash
iris session iris
zn "USER"
set r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
```

Install previous datapipe version
```bash
zpm "install iris-datapipe"
```

Generate data:
* Start Test Production
* Send some messages
```objectscript
do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(10)
```

Stop Production

Install latest local datapipe version
```objectscript
zpm "load /app"
```

Delete WebApp "/dpipe/api/rf2"

Migrate `DataPipe.Data.Pipe` (this could be found also in `^DataPipe.Data.InboxI("FlowIdx")`)):
```sql
INSERT INTO DataPipe_Data.Pipe (Code, Description)
select distinct pipe, 'Migrated' from %IGNOREINDEX * datapipe_data.inbox
```

Rebuild indices:
```objectscript
write ##class(DataPipe.Data.Inbox).%BuildIndices($lb("PipeIdx"))
```
