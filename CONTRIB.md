
Please, go through the following steps if you want to contribute to this project:

1. Report an issue. Describe it as much as possible.
2. Fork the repository, create a new branch.
3. Develop your changes, make sure all unit tests are working. Add new unit tests as needed.
4. Create a pull request.

# Development Environment
Build:
```
docker-compose build
```

Run:
```
docker-compose up
```

IRIS instance:
* *Credentials*: `superuser` / `SYS`
* *URL*: http://localhost:52773/csp/sys/UtilHome.csp


# Unit Tests
Open an IRIS interactive session:
```console
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
do ##class(%UnitTest.Manager).RunTest(":DataPipe.UnitTest.HL7", "/nodelete")
```

# Utils
Generate 100 sample hl7 files for processing in test production:
```objectscript
do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(100, 1)
```

Delete `DataPipe.Data.*` data:
```objectscript
do ##class(DataPipe.Test.Helper).KillData()
```
