
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

# Test publishing & deploying using IPM
See [Testing packages for ZPM](https://community.intersystems.com/post/testing-packages-zpm)

Load module from local dev environment:
```objectscript
zpm "load /app"
```

Set up testing IPM repository:
```objectscript
zpm "repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42"
```

Search packages already published in testing IPM repository:
```objectscript
zpm "search"
```

Test publishing process:
```objectscript
zpm "iris-datapipe publish -verbose"
```

Search published package in testing IPM repository:
```objectscript
zpm "search"
```

Run a container with an IRIS instance
```bash
docker compose -f docker-compose.test.yml up -d
```

Install ipm
```bash
docker compose -f docker-compose.test.yml exec -it iris bash
iris session iris
zn "USER"
set r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
```

Set up testing IPM repository:
```objectscript
zpm "repo -n test -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42"
```

Search published packages:
```objectscript
zpm "search"
```

Install the package:
```objectscript
zpm "install iris-datapipe 2.0.0"
```

# Testing Upgrade from DataPipe 0.0.2 to DataPipe 2.x

Run a container with a brand new IRIS (upgrade)
```bash
docker compose -f docker-compose.test.yml up -d
```

Install ipm
```bash
docker compose -f docker-compose.test.yml exec -it iris bash
iris session iris
set r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
```

## Create a Pre-Upgrade situation
Install previous datapipe version
```bash
zpm "install iris-datapipe 0.0.2"
```

Start production

Generate data:
```objectscript
do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(100)
```

## Upgrade to new version

Stop Production

Create a temporary table to store Flows, they will be migrated into Pipes in new version
```sql
CREATE TABLE TempDataPipeMigration(Code CHAR(255) NOT NULL)
```
```sql
INSERT INTO TempDataPipeMigration (Code) SELECT DISTINCT Flow FROM DataPipe_Data.Inbox
```

Install latest local datapipe version
```objectscript
zpm "load /app"
```

Delete WebApp "/dpipe/api/rf2"

Migrate legacy Flows to Pipes:
```sql
INSERT INTO DataPipe_Data.Pipe (Code, Description) SELECT Code, 'Migrated' FROM TempDataPipeMigration
```

```sql
DROP TABLE TempDataPipeMigration
```

Rebuild indices:
```objectscript
write ##class(DataPipe.Data.Inbox).%BuildIndices($lb("PipeIdx"))
```

Setup security privileges as in [README.md](./README.md) *Users and privileges* section.

Enable CORS for deploying datapipe-UI:
```objectscript
do $system.OBJ.Load("/app/src/Form/REST/Abstract.cls", "ck") 
```

Make sure `CSPSystem` has read privileges on DataPipe database.

Deploy datapipe-UI changing `environment.ts` config as needed.

Start Production