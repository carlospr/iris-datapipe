*DataPipe* is an **InterSystems IRIS** application which provides a set of re-usable components you can use to handle incoming data flow into ingestion, staging and operation phases in a homogeneus and flexible way.

<img src="img/datapipe-diagram.png">

Want to contribute to this project? See [CONTRIB.md](./CONTRIB.md)

# QuickStart
* Have a look at [CONTRIB.md](./CONTRIB.md) to build your local development environment (Docker).
* Also, check out the Angular UI project at [datapipeUI](https://github.com/intersystems-ib/iris-datapipeUI).

# Installation
1) Install [IPM package manager](https://github.com/intersystems/ipm) if you don't have already done it.
2) Create a new namespace (e..g `DPIPE`)
3) Switch to the namespace you want to install DataPipe.
4) Install DataPipe using ipm:

```
DPIPE> zpm
zpm:TEST> install iris-datapipe
```
