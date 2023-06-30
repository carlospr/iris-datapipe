import abc

import iris

class ModelException(Exception):
    def __init__(self, message, errors):
        super().__init__(message)
        self.errors = errors

class _Model(metaclass=abc.ABCMeta):

    error_list = []
    log_list = []

    ## Helper Methods
    def add_error(self, code, text):
        ret = iris.cls('DataPipe.Data.ErrorInfo')._New()
        ret.Code = code
        ret.Desc = text
        self.error_list.append(ret)

    def add_log(self, text):
        self.log_list.append(text)

    ## Public Methods for ObjectScript
    def Serialize(self):
        stream = iris.cls('%Stream.GlobalCharacter')._New()
        # for each chunk of 1024 characters
        for i in range(0, len(self.serialize()), 1024):
            # write the chunk to the stream
            stream.Write(self.serialize()[i:i+1024])
        return stream
    
    def Deserialize(self,input):
        string = ""
        self.error_list = []
        while not input.AtEnd:
            string += input.Read(1024)
        return self.deserialize(string)
    
    def Normalize(self):
        return self.normalize()
    
    def Validation(self):
        try:
            self.validate()
        except Exception as e:
            self.add_error("VALIDATION",str(e))
        return self.error_list
    
    def RunOperation(self,error,log,operation_instance):
        try:
            self.operation(operation_instance)
            if self.error_list:
                error = self.error_list
            if self.log_list:
                log = self.log_list
        except Exception as e:
            raise e
        return 1
    
    def GetOperation(self):
        return self.get_operation()

    ## Public Methods for Python
    @abc.abstractmethod
    def serialize(self):
        pass

    @abc.abstractmethod
    def deserialize(self,input):
        pass

    @abc.abstractmethod
    def normalize(self):
        pass

    @abc.abstractmethod
    def validate(self):
        pass

    @abc.abstractmethod
    def operation(self,target_operation):
        pass

    @abc.abstractmethod
    def get_operation(self):
        pass