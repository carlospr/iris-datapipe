ARG IMAGE=store/intersystems/irishealth-community:2019.4.0.383.0
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
RUN wget https://github.com/intersystems-community/RESTForms2/archive/master.tar.gz
RUN tar -zxvf master.tar.gz
WORKDIR /tmp/RESTForms2-master

# copy dpipe source code
WORKDIR /app
COPY src src

# download zpm package manager
RUN mkdir -p /tmp/deps \
 && cd /tmp/deps \
 && wget -q https://pm.community.intersystems.com/packages/zpm/latest/installer -O zpm.xml

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
  # install zpm
  Do $system.OBJ.Load("/tmp/deps/zpm.xml", "ck") \
  zpm "install webterminal" \
  # install datapipe
  do $SYSTEM.OBJ.Load("/app/src/DataPipe/Installer.cls", "ck") \
  set sc = ##class(App.Installer).Run()

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]