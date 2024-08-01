ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:latest-em
FROM $IMAGE

USER root

# create directory for databases
WORKDIR /opt/dpipe
RUN mkdir -p /opt/dpipe/db/DATA
RUN mkdir -p /opt/dpipe/db/CODE
RUN mkdir -p /opt/dpipe/data/input
RUN mkdir -p /opt/dpipe/data/archived
RUN chown -R irisowner:irisowner /opt/dpipe

# create directory for app
WORKDIR /opt/irisapp
RUN chown -R irisowner:irisowner /opt/irisapp

USER irisowner

# copy files to image
WORKDIR /opt/irisapp
COPY --chown=irisowner:irisowner iris.script iris.script
COPY --chown=irisowner:irisowner src src
COPY --chown=irisowner:irisowner install install
COPY --chown=irisowner:irisowner module.xml module.xml
COPY --chown=irisowner:irisowner Installer.cls Installer.cls

ENV PATH "/home/irisowner/.local/bin:/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"

RUN pip install iris-pex-embedded-python

## Python stuff
ENV IRISUSERNAME "SuperUser"
ENV IRISPASSWORD "SYS"
ENV IRISNAMESPACE "DPIPE"

# run iris.script
RUN iris start IRIS \
    && iris session IRIS < /opt/irisapp/iris.script \
    && iop -m /opt/irisapp/src/python/Demo/settings.py \
    && iris stop IRIS quietly