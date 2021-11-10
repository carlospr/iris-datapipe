ARG IMAGE=store/intersystems/irishealth-community:2021.1.0.215.3
FROM $IMAGE

USER root
COPY irissession.sh /
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /irissession.sh
RUN chmod u+x /irissession.sh
RUN mkdir -p /opt/dpipe/db/DATA
RUN mkdir -p /opt/dpipe/db/CODE
RUN mkdir -p /opt/dpipe/data/input
RUN mkdir -p /opt/dpipe/data/archived
RUN chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/dpipe

USER irisowner

# download RESTForms2
# check RESTForms2 repo. it has zpm installation also available!
WORKDIR /tmp 
# use this version, latest on intersystems-community have some breaking differences on OperErrorsJson fields, etc.
RUN wget https://github.com/isc-afuentes/RESTForms2/archive/master.tar.gz
RUN tar -zxvf master.tar.gz
WORKDIR /tmp/RESTForms2-master

# copy dpipe source code
WORKDIR /app
COPY src src

SHELL ["/irissession.sh"]
RUN \
  # install RESTForms2
  do $SYSTEM.OBJ.Load("/tmp/RESTForms2-master/src/Form/Installer.cls", "ck") \
  set vars("Namespace")="DPIPE" \
  set vars("CreateNamespace")="yes" \
  set vars("DataDBPath")="/opt/dpipe/db/DATA" \
  set vars("CodeDBPath")="/opt/dpipe/db/CODE" \
  set vars("WebApp")="/dpipe/api/rf2" \
  set vars("SourcePath")="/tmp/RESTForms2-master/src/" \
  set sc = ##class(Form.Installer).Run(.vars) \
  zn "DPIPE" \
  # install datapipe 
  kill vars \
  do $SYSTEM.OBJ.Load("/app/src/DataPipe/Installer.cls", "ck") \
  set vars("Namespace")="DPIPE"  \
  set vars("WebApp")="/dpipe/api" \
  set vars("SourcePath")="/app/src" \
  set vars("StartTestProduction")="yes" \
  set sc = ##class(DataPipe.Installer).Run(.vars) 
  
# bringing the standard shell back
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]