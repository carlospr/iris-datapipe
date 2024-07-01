DataPipe an interoperability framework to ingest data in InterSystems IRIS in a flexible way.

<img src="img/datapipe-diagram2.png" width="800" />

# QuickStart

## Run container
```
docker compose up -d
```

## Create Data Pipes
Your data will be processed using "Data Pipes". Each data pipe has its own Code, Description and optionally a Security Resource that will be required to query the pipe.

Create some sample data pipes using SQL:

* Log-in to the [Management Portal](http://localhost:52773/csp/sys/UtilHome.csp) using `superuser` / `SYS`.
* Go to [System Explorer > SQL](http://localhost:52773/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=DPIPE) and run:

```sql
-- create a pipe for HL7 ADT messages. User need to have permissions on DP_PIPE_HL7ADT resource to query this pipe.
INSERT INTO DataPipe_Data.Pipe (Code, Description, SecurityResource) values ('HL7-ADT', 'Sample HL7 Pipe', 'DP_PIPE_HL7ADT')
```

```sql
-- create a pipe for a dummy REST API
INSERT INTO DataPipe_Data.Pipe (Code, Description) values ('DUMMY-API', 'A REST API Pipe')
```

## Start an interoperability production
Data Pipe uses interoperability framework, so you need to start an interoperability production.

Open [DataPipe.Test.Production](http://localhost:52773/csp/dpipe/EnsPortal.ProductionConfig.zen?PRODUCTION=DataPipe.Test.Production) and click `Start`.


## Generate some sample data
Now you can generate some sample data that will be processed in your pipes.

* Open an interactive [WebTerminal](http://localhost:52773/terminal/) session.
* Generate sample `HL7-ADT` messages

```objectscript
do ##class(DataPipe.Test.HL7.Helper).GenerateFilesHL7ADT(100)
```

You can have a look at the [DataPipe.Test.Production](http://localhost:52773/csp/dpipe/EnsPortal.ProductionConfig.zen?PRODUCTION=DataPipe.Test.Production) and see how messages has been processed.


## DataPipeUI
DataPipe also includes an UI which will give use a clear vision of the data you have just processed.

Follow these steps to run [datapipeUI](https://github.com/intersystems-ib/iris-datapipeUI).

1. In other directory, clone [datapipeUI](https://github.com/intersystems-ib/iris-datapipeUI) repository

```
git clone https://github.com/intersystems-ib/iris-datapipeUI
```

2. Run UI container:

```
cd iris-datapipeUI
docker compose up -d
```

3. Log-in the UI at http://localhost:8080 using `dpadmin` / `demo`

<img src="img/iris-datapipeUI.gif" />


# Ingest data using DataPipe

## Model
You need to define a model for the data you want to ingest. 
A model a class that extends from [DataPipe.Model.cls](src/DataPipe/Model.cls) where you must implement some methods.

<img src="img/datapipe-model.png" width="200" />

In your model you will implement:
* How to serialize / deserialize your data (e.g. using JSON or XML).
* How to Normalize and Validate your data.
* And finally, what operation you want to run with your data after it is normalized and validated.

You can find a full example in [DataPipe.Test.HL7.Models.A08.cls](src/DataPipe/Test/HL7/Models/A08.cls)

## Interoperability components
After defining your model, you can develop your interoperability production using DataPipe components.

<img src="img/datapipe-components.png" width="800" />

You need to implement an **Ingestion process** which must provide:
* `Input > InboxAttributes` transformation: here you extract the attributes that describe your input data. You will be able to search data using these attributes.
* `Input > Model` transformation: transform your incoming data into the DataPipe model you have previously defined.

Rest of the components are provided by DataPipe and they will call your model methods.

You can have a look at a full example in [DataPipe.Test.Production.cls](src/DataPipe/Test/Production.cls)

# Installation
1) Install [IPM package manager](https://github.com/intersystems/ipm) if you don't have already done it.
2) Create a new namespace (e.g. `DPIPE`)
3) Switch to the namespace you want to install DataPipe.
4) Install DataPipe using ipm:

```
DPIPE> zpm
zpm:DPIPE> install iris-datapipe
```

Want to contribute to this project? See [CONTRIB.md](./CONTRIB.md)
