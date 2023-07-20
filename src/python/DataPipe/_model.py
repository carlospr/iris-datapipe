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
    
    def RunOperation(self,operation_instance):
        log = []
        self.error_list = []
        self.log_list = []
        try:
            self.operation(operation_instance)
        except Exception as e:
            self.add_error("OPERATION",str(e))
        if self.log_list:
            for line in self.log_list:
                self.add_error("OPERLOG",line)
        if self.error_list:
            for line in self.error_list:
                log.append(line)
        return log
    
    def GetOperation(self):
        return self.get_operation()

    ## Public Methods for Python
    @abc.abstractmethod
    def serialize(self):
        """
        Must be implemented by the subclass.
        It should return a string representation of the object.
        For example, a JSON string.
        """
        pass

    @abc.abstractmethod
    def deserialize(self,input):
        """
        Must be implemented by the subclass.
        It should return a new instance of the object.
        From the string representation of the object.
        For example, a JSON string.
        """
        pass

    @abc.abstractmethod
    def normalize(self):
        """
        Must be implemented by the subclass.
        It should update the object to a normalized state.
        With the data normalized.
        """
        pass

    @abc.abstractmethod
    def validate(self):
        """
        Must be implemented by the subclass.
        It should return a new instance of the object.
        With the data validated.
        """
        pass

    @abc.abstractmethod
    def operation(self,target_operation):
        """
        Must be implemented by the subclass.
        It runs an operation on the object.
        """
        pass

    @abc.abstractmethod
    def get_operation(self):
        """
        Must be implemented by the subclass.
        It returns the operation that can be run on the object.
        """
        pass