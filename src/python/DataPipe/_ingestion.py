from datetime import datetime
from DataPipe._model import _Model, ModelException

from grongier.pex import BusinessProcess

import iris

import inspect

import os

class _Ingestion(BusinessProcess):

    # mapping from iris.DataPipe.Data.InboxAttributes to dict
    _att = {"Flow":"flow","Source":"source","MsgId":"msg_id","Element":"element","Subject":"subject"}

    def ingest(self):
        try:
            self.init_inbox()
            if not self.inbox.Ignored:
                self.init_ingestion()
                self.serialize_model()
                self.save_data()
                self.build_staging_req()
            else:
                self.log_warning(f"Ignoring Inbox {self.inbox._Id()} because has been set as ignored before")
        except Exception as ex:
            raise ex
        
    def init_inbox(self):

        inbox_obj = iris.ref(None)
        iris.cls('DataPipe.Data.Inbox').GetByKeyAttributes(
                self._dict_to_inbox_attributes(self.inbox_attributes),
                inbox_obj
            )
        inbox_obj = inbox_obj.value
        if inbox_obj is None or inbox_obj == "":
            # return new inbox 
            inbox_obj = iris.cls('DataPipe.Data.Inbox')._New()
            inbox_obj.CreatedTS = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            inbox_obj.UpdatedTS = inbox_obj.CreatedTS
        else:
            # return existing inbox
            inbox_obj.UpdatedTS = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        inbox_obj.PopulateAttributes(self._dict_to_inbox_attributes(self.inbox_attributes))
        self.inbox = inbox_obj


    def init_ingestion(self):

        self.ingestion = iris.cls('DataPipe.Data.Ingestion')._New()
        self.ingestion.SessionId = self.iris_handle._SessionId
        self.ingestion.HeaderId = self.iris_handle._PrimaryRequestHeader._Id()
        self.ingestion.CreatedTS = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.inbox.Ingestions.Insert(self.ingestion)
        self.inbox.LastIngestion = self.ingestion
        self.inbox.LastStaging = ""
        self.inbox.LastOper = ""
        self.inbox.Status = "INGESTING"
        self.inbox.UpdatedTS = self.ingestion.CreatedTS

        # check model object
        if not self.model:
            raise ModelException("Model object is not defined")
        if not isinstance(self.model, _Model):
            raise ModelException("Model object is not instance of _Model")
        
    def serialize_model(self):
        self.ingestion.ModelIsPython = 1
        self.ingestion.ModelModule = self.model.__module__
        self.ingestion.ModelName = self.model.__class__.__name__
        # get the class path from the model with the file name
        self.ingestion.ModelClassPath = os.path.dirname(inspect.getfile(self.model.__class__))
        self.ingestion.ModelData = self.model.Serialize()

    def save_data(self):
        self.inbox._Save(1)
        self.ingestion._Save(1)

    def build_staging_req(self):
        self.staging_req = iris.cls('DataPipe.Msg.StagingReq')._New()
        self.staging_req.data = self.ingestion

    def get_error_info(self):
        try:
            # get error
            # errorText = iris.Status.GetOneStatusText(self._context._lastError)
            # if self._context._lastFault != "":
            #     errorText = self._context._lastFault
            errorText = self.iris_handle._LastError
            self.log_error(errorText)
            self.error_text = errorText

            # update status
            self.ingestion.Inbox.Status = "ERROR-INGESTING"
            self.ingestion.Inbox._Save()
        except Exception as ex:
            self.log_error("INTERNAL ERROR: " + str(ex))

    def _inbox_attributes_to_dict(self, inbox_attributes: 'iris.DataPipe.Data.InboxAttributes'):
        ret = {}
        for att in self._att:
            ret[self._att[att]] = getattr(inbox_attributes, att)
        return ret
    
    def _dict_to_inbox_attributes(self, dict):
        ret = iris.cls('DataPipe.Data.InboxAttributes')._New()
        for att in self._att:
            setattr(ret, att, dict[self._att[att]])
        return ret
    
    def _datetime_to_string(self, dt: 'datetime'):
        return dt.strftime("%Y-%m-%d %H:%M:%S")
