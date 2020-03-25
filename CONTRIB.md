
# DEVELOPMENT ENVIRONMENT
```
docker-compose up
```


# UNIT TESTS
```
zn "dpipe"
set ^UnitTestRoot = "/app/src/DataPipe/UnitTest"
do ##class(%UnitTest.Manager).RunTest("", "/nodelete")
```


# UTILITIES
## Generate test data
Generate hl7 sample messages:
```
do ##class(DataPipe.Test.Helper).GenerateFilesHL7ADT(100)
```

## Delete data
```
do ##class(DataPipe.Test.Helper).KillData()
```


# UI
Credentials: superuser/SYS

http://localhost:4200/datapipe

## angular/cli commands used
```
ng new DataPipeUI --directory=frontend --routing=true --skipGit --style=scss
ng add @angular/material
ng generate module shared
npm install --save bootstrap

ng generate module auth --routing
ng generate component auth/login
ng generate component auth/logout
ng generate service auth/auth

ng generate service shared/alert
ng generate component shared/alert-display

ng generate module about --routing
ng generate component about/about

ng generate module datapipe --routing
ng generate component datapipe/inbox-list
ng generate service datapipe/datapipe
ng generate component datapipe/inbox-detail
ng generate component datapipe/viewstream-dialog
ng generate component datapipe/inbox-info
ng generate component datapipe/inbox-history

ng generate component shared/confirm-dialog
```