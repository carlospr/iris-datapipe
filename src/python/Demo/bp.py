from DataPipe import IngestionProcess

from models import A08

class HL7Ingestion(IngestionProcess):

    def on_message(self, request:'iris.EnsLib.HL7.Message'):
        # first map the message to a model
        self.model = A08()
        self.model.msg_id = request.GetSegmentAt(1).GetValueAt(10)
        self.model.patient_id = request.GetSegmentAt(3).GetValueAt(2)
        self.model.name = request.GetSegmentAt(3).GetValueAt(5).split("^")[0]
        self.model.surname1 = request.GetSegmentAt(3).GetValueAt(5).split("^")[1]
        self.model.surname2 = request.GetSegmentAt(3).GetValueAt(5).split("^")[2]
        self.model.birth_date = request.GetSegmentAt(3).GetValueAt(7)
        self.model.administrative_sex = request.GetSegmentAt(3).GetValueAt(8)

        #them map attributes from the inbox
        self.inbox_attributes = {
            "flow": "HL7",
            "source": "HIS",
            "msg_id": request.GetSegmentAt(1).GetValueAt(10),
            "element":request.GetSegmentAt(4).GetValueAt(19),
            "subject":request.GetSegmentAt(3).GetValueAt(2)
        }

        # init the ingestion process
        self.ingest()

        # send to staging
        self.send_request_async("HL7 Staging", self.staging_req)

# for testing
# if __name__ == '__main__':
#     bp = HL7Ingestion()
#     import iris
#     msg = iris.cls('EnsLib.HL7.Message').ImportFromFile('/Users/grongier/git/datapipe/iris-datapipe/data/file6665459469713881531.hl7')
#     bp.on_message(msg)
#     bp.model.Normalize()
#     erro = bp.model.Validate()
#     print(erro)