public class AttachFilesToCarService {
    
    public class RequestWrapper {
        @InvocableVariable(required=true label='Case Id (source)')
        public Id sourceRecordId; // Case Id
        
        @InvocableVariable(required=true label='Car Service Id (target)')
        public Id targetRecordId; // Car Service Id
    }
    
    @InvocableMethod(label='Copy Files From Case To Car Service' 
                      description='Duplicates file attachments from a Case (via its EmailMessages) to a related Car Service record')
    public static void copyFiles(List<RequestWrapper> requests) {
        
        Set<Id> sourceIds = new Set<Id>();
        Map<Id, Id> targetIdBySourceId = new Map<Id, Id>();
        
        for (RequestWrapper req : requests) {
            if (req.sourceRecordId != null && req.targetRecordId != null) {
                sourceIds.add(req.sourceRecordId);
                targetIdBySourceId.put(req.sourceRecordId, req.targetRecordId);
            }
        }
        
        if (sourceIds.isEmpty()) {
            return;
        }
        
        Map<Id, Id> caseIdByEmailMessageId = new Map<Id, Id>();
        for (EmailMessage em : [
            SELECT Id, ParentId 
            FROM EmailMessage 
            WHERE ParentId IN :sourceIds
        ]) {
            caseIdByEmailMessageId.put(em.Id, em.ParentId);
        }
        
        if (caseIdByEmailMessageId.isEmpty()) {
            return; 
        }
        
        List<Attachment> sourceAttachments = [
            SELECT Id, Name, Body, ContentType, ParentId
            FROM Attachment
            WHERE ParentId IN :caseIdByEmailMessageId.keySet()
        ];
        
        if (sourceAttachments.isEmpty()) {
            return;
        }
        
        List<Attachment> newAttachments = new List<Attachment>();
        
        for (Attachment sourceAtt : sourceAttachments) {
            Id caseId = caseIdByEmailMessageId.get(sourceAtt.ParentId);
            Id targetId = targetIdBySourceId.get(caseId);
            
            if (targetId == null) {
                continue;
            }
            
            Attachment newAtt = new Attachment();
            newAtt.Name = sourceAtt.Name;
            newAtt.Body = sourceAtt.Body;
            newAtt.ContentType = sourceAtt.ContentType;
            newAtt.ParentId = targetId;
            newAttachments.add(newAtt);
        }
        
        if (!newAttachments.isEmpty()) {
            insert newAttachments;
        }
    }
}