from DataPipe import Model, ModelException
from dataclasses import dataclass
import json
import iris

@dataclass
class A08(Model):

    msg_id: str = None
    patient_id: str = None
    name: str = None
    surname1: str = None
    surname2: str = None
    birth_date: str = None
    administrative_sex: str = None
    ssn: str = None

    def serialize(self):
        # convert this object to a json string
        return json.dumps(self.__dict__)
    
    def deserialize(self, json_str):
        # populate this object from a json string
        self.__dict__ = json.loads(json_str)

    def normalize(self):
        # normalize this object
        # convert administrative_sex to M to H and F to M and None to ""
        conversion = {"M":"H","F":"M",None:""}
        # apply conversion
        administrative_sex = self.administrative_sex.upper()
        self.administrative_sex = conversion.get(administrative_sex, "")
        # for demo purposes raise an exception if name is Alfred or James or Kevin
        if self.name.upper() in ["ALFRED","JAMES","KEVIN"]:
            raise ModelException("Name is not valid")
        return self
        
    def validate(self):
        # create an iris.DataPipe.Data.ErrorInfo for each failed validation
        if self.administrative_sex is None or self.administrative_sex == "":
            self.add_error("VGEN","AdministrativeSex required")

        if self.birth_date is None or self.birth_date == "":
            self.add_error("V001","BirthDate required")
        else:
            year = int(self.birth_date[0:4])
            if year < 1930:
                self.add_error("V002","DOB must be greater than 1930")
            if year > 1983:
                self.add_error("W083","Warning! Older than 1983")

        # model is invalid if errors (not warnings) found
        for error in self.error_list:
            if "V" in error.Code[0]:
                raise ModelException("Model is invalid")
        return self.error_list
    
    def operation(self, operation_instance):
        """
        Perform operation
        """
        if isinstance(operation_instance, object):
            msg = iris.cls('Ens.StringContainer')._New()
            msg.StringValue = "Call production component during RunOperation() "
            operation_instance.SendRequestAsync("Dummy",msg)
        
    
    def get_operation(self):
        if 'FIFO' in self.msg_id:
            return "FIFO A08 Operation"
        return "A08 Operation"

