codeunit 77101 "Document Approval Workflow"
{
    // This codeunit consolidates all workflow logic for Document Approvals.
    // It handles:
    // 1. Workflow Events (WHEN)
    // 2. Workflow Responses (THEN)
    // 3. Workflow Template (Default structure)
    // 4. Integration with standard Approvals Mgmt.

    var
        WorkflowMgmt: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowSetup: Codeunit "Workflow Setup";

        // Workflow Code
        DocumentApprovalWorkflowCodeTxt: Label 'DOC-APPROV-WF', Locked = true;
        DocumentApprovalWorkflowDescTxt: Label 'Document Approval Workflow';

        // Event Descriptions
        SendDocApprovalForApprovalEventDescTxt: Label 'Approval of an Employee Document is requested.';
        ApproveDocApprovalEventDescTxt: Label 'An Employee Document approval request is approved.';
        RejectDocApprovalEventDescTxt: Label 'An Employee Document approval request is rejected.';
        DelegateDocApprovalEventDescTxt: Label 'An Employee Document approval request is delegated.';
        CancelDocApprovalEventDescTxt: Label 'An Employee Document approval request is canceled.';

        // Custom Response Descriptions
        CreateDocApprovalRequestsDescTxt: Label 'Create an approval request for the document.';

        // Errors/Messages
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';

    // =========================================
    // WORKFLOW EVENT CODES
    // =========================================

    procedure GetSendDocApprovalForApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendDocumentApproval'));
    end;

    procedure GetApproveDocApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnApproveDocumentApproval'));
    end;

    procedure GetRejectDocApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnRejectDocumentApproval'));
    end;

    procedure GetDelegateDocApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnDelegateDocumentApproval'));
    end;

    procedure GetCancelDocApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelDocumentApproval'));
    end;

    // Custom Response Codes
    procedure GetCreateDocApprRequestsCode(): Code[128]
    begin
        exit(UpperCase('CreateDocApprovalRequests'));
    end;

    // =========================================
    // ADD EVENTS TO LIBRARY
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    begin
        WorkflowEventHandling.AddEventToLibrary(GetSendDocApprovalForApprovalEventCode(), Database::"Document Approval Header", SendDocApprovalForApprovalEventDescTxt, 0, true);
        WorkflowEventHandling.AddEventToLibrary(GetCancelDocApprovalEventCode(), Database::"Document Approval Header", CancelDocApprovalEventDescTxt, 0, true);

        // Sub-events (not entry points)
        WorkflowEventHandling.AddEventToLibrary(GetApproveDocApprovalEventCode(), Database::"Document Approval Header", ApproveDocApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(GetRejectDocApprovalEventCode(), Database::"Document Approval Header", RejectDocApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(GetDelegateDocApprovalEventCode(), Database::"Document Approval Header", DelegateDocApprovalEventDescTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsesToLibrary()
    begin
        WorkflowResponseHandling.AddResponseToLibrary(GetCreateDocApprRequestsCode(), Database::"Document Approval Header", CreateDocApprovalRequestsDescTxt, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            GetApproveDocApprovalEventCode():
                WorkflowEventHandling.AddEventPredecessor(GetApproveDocApprovalEventCode(), GetSendDocApprovalForApprovalEventCode());
            GetRejectDocApprovalEventCode():
                WorkflowEventHandling.AddEventPredecessor(GetRejectDocApprovalEventCode(), GetSendDocApprovalForApprovalEventCode());
            GetDelegateDocApprovalEventCode():
                WorkflowEventHandling.AddEventPredecessor(GetDelegateDocApprovalEventCode(), GetSendDocApprovalForApprovalEventCode());
            GetCancelDocApprovalEventCode():
                WorkflowEventHandling.AddEventPredecessor(GetCancelDocApprovalEventCode(), GetSendDocApprovalForApprovalEventCode());
        end;
    end;

    // =========================================
    // APPROVALS MGMT. INTEGRATION (CRITICAL FIXES)
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        DocumentApprovalHeader: Record "Document Approval Header";
    begin
        if RecRef.Number <> Database::"Document Approval Header" then
            exit;

        RecRef.SetTable(DocumentApprovalHeader);
        DocumentApprovalHeader.CalcFields("Total Amount");

        ApprovalEntryArgument."Table ID" := Database::"Document Approval Header";
        ApprovalEntryArgument."Record ID to Approve" := RecRef.RecordId;
        ApprovalEntryArgument."Document No." := DocumentApprovalHeader."No.";
        ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::" "; // Important: Stay consistent
        ApprovalEntryArgument.Amount := DocumentApprovalHeader."Total Amount";
        ApprovalEntryArgument."Amount (LCY)" := DocumentApprovalHeader."Total Amount";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure OnAddWorkflowTableRelationsToLibrary()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalEntry: Record "Approval Entry";
    begin
        WorkflowSetup.InsertTableRelation(
            Database::"Document Approval Header",
            0,
            Database::"Approval Entry",
            ApprovalEntry.FieldNo("Record ID to Approve")
        );
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    begin
        case ResponseFunctionName of
            WorkflowResponseHandling.SetStatusToPendingApprovalCode():
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SetStatusToPendingApprovalCode(), GetSendDocApprovalForApprovalEventCode());
            WorkflowResponseHandling.CreateApprovalRequestsCode():
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CreateApprovalRequestsCode(), GetSendDocApprovalForApprovalEventCode());
            WorkflowResponseHandling.SendApprovalRequestForApprovalCode():
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), GetSendDocApprovalForApprovalEventCode());
            WorkflowResponseHandling.CancelAllApprovalRequestsCode():
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode(), GetCancelDocApprovalEventCode());
            WorkflowResponseHandling.OpenDocumentCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(), GetCancelDocApprovalEventCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
                    // Support standard responses
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(), WorkflowResponseHandling.CancelAllApprovalRequestsCode());
                end;
            WorkflowResponseHandling.ReleaseDocumentCode():
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.ReleaseDocumentCode(), WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
            
            // Custom Response Predecessors
            GetCreateDocApprRequestsCode():
                WorkflowResponseHandling.AddResponsePredecessor(GetCreateDocApprRequestsCode(), GetSendDocApprovalForApprovalEventCode());
        end;
    end;

    // This ensures standard responses like "Release Document" and "Open Document" work for our table
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    begin
        if RecRef.Number = Database::"Document Approval Header" then begin
            UpdateStatus(RecRef, "Document Approval Status"::Approved);
            Handled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', false, false)]
    local procedure OnOpenDocument(RecRef: RecordRef; var Handled: Boolean)
    begin
        if RecRef.Number = Database::"Document Approval Header" then begin
            UpdateStatus(RecRef, "Document Approval Status"::Open);
            Handled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure OnExecuteWorkflowResponse(var ResponseExecuted: Boolean; Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        if ResponseExecuted then
            exit;

        if ResponseWorkflowStepInstance."Function Name" = GetCreateDocApprRequestsCode() then begin
            CreateApprovalEntries(Variant, ResponseWorkflowStepInstance);
            ResponseExecuted := true;
        end;
    end;

    local procedure CreateApprovalEntries(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        ApprovalsMgmt.CreateApprovalRequests(RecRef, WorkflowStepInstance);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', false, false)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    begin
        if RecRef.Number = Database::"Document Approval Header" then begin
            UpdateStatus(RecRef, "Document Approval Status"::"Pending Approval");
            IsHandled := true;
        end;
    end;

    local procedure UpdateStatus(RecRef: RecordRef; NewStatus: Enum "Document Approval Status")
    var
        DocumentApprovalHeader: Record "Document Approval Header";
    begin
        RecRef.SetTable(DocumentApprovalHeader);
        DocumentApprovalHeader.Status := NewStatus;
        if NewStatus = NewStatus::Approved then begin
            DocumentApprovalHeader."Approved By" := CopyStr(UserId, 1, 50);
            DocumentApprovalHeader."Approved Date" := Today;
        end;
        DocumentApprovalHeader.Modify(true);
    end;

    // =========================================
    // WORKFLOW TEMPLATE CREATION
    // =========================================

    procedure CreateDocumentApprovalWorkflowTemplate(): Boolean
    var
        Workflow: Record Workflow;
    begin
        exit(InsertDocumentApprovalWorkflowTemplate(Workflow));
    end;

    local procedure InsertDocumentApprovalWorkflowTemplate(var Workflow: Record Workflow): Boolean
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowCode: Code[20];
    begin
        WorkflowCode := DocumentApprovalWorkflowCodeTxt;

        // Check/Create Workflow record
        if not Workflow.Get(WorkflowCode) then begin
            Workflow.Init();
            Workflow.Code := WorkflowCode;
            Workflow.Description := DocumentApprovalWorkflowDescTxt;
            Workflow.Category := 'FIN';
            Workflow.Template := false;
            Workflow.Enabled := false;
            Workflow.Insert(true);
        end else begin
            // Clear existing steps to rebuild
            WorkflowStep.SetRange("Workflow Code", WorkflowCode);
            WorkflowStep.DeleteAll(true);
        end;

        // --- STEP SEQUENCE ---

        // 1. WHEN Approval of a Document is requested
        InsertWorkflowStep(WorkflowCode, 1, GetSendDocApprovalForApprovalEventCode(), 0, true);

        // 2. THEN Set Status to Pending Approval
        InsertWorkflowStep(WorkflowCode, 2, WorkflowResponseHandling.SetStatusToPendingApprovalCode(), 1, false);

        // 3. THEN Create an approval request (Custom Response)
        InsertWorkflowStep(WorkflowCode, 3, GetCreateDocApprRequestsCode(), 2, false);
        SetApprovalArgument(WorkflowCode, 3); // Sets Direct Approver by default

        // 4. THEN Send approval request
        InsertWorkflowStep(WorkflowCode, 4, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), 3, false);

        // 5. WHEN Approval is approved
        InsertWorkflowStep(WorkflowCode, 5, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), 4, false);

        // 6. THEN Release the document
        InsertWorkflowStep(WorkflowCode, 6, WorkflowResponseHandling.ReleaseDocumentCode(), 5, false);

        // 7. WHEN Approval is rejected
        InsertWorkflowStep(WorkflowCode, 7, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), 4, false);

        // 8. THEN Open the document
        InsertWorkflowStep(WorkflowCode, 8, WorkflowResponseHandling.OpenDocumentCode(), 7, false);

        // 9. WHEN Approval is cancelled
        InsertWorkflowStep(WorkflowCode, 9, GetCancelDocApprovalEventCode(), 0, true);

        // 10. THEN Cancel all requests
        InsertWorkflowStep(WorkflowCode, 10, WorkflowResponseHandling.CancelAllApprovalRequestsCode(), 9, false);

        // 11. THEN Open the document
        InsertWorkflowStep(WorkflowCode, 11, WorkflowResponseHandling.OpenDocumentCode(), 10, false);

        exit(true);
    end;

    local procedure InsertWorkflowStep(WorkflowCode: Code[20]; StepID: Integer; FunctionName: Code[128]; PreviousStepID: Integer; EntryPoint: Boolean)
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := WorkflowCode;
        WorkflowStep.ID := StepID;
        WorkflowStep."Function Name" := FunctionName;
        WorkflowStep."Previous Workflow Step ID" := PreviousStepID;
        WorkflowStep."Entry Point" := EntryPoint;
        if not EntryPoint then
            WorkflowStep."Sequence No." := 1;

        if EntryPoint then
            WorkflowStep.Type := WorkflowStep.Type::"Event"
        else
            WorkflowStep.Type := WorkflowStep.Type::Response;

        WorkflowStep.Insert(true);
    end;

    local procedure SetApprovalArgument(WorkflowCode: Code[20]; StepID: Integer)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if not WorkflowStep.Get(WorkflowCode, StepID) then
            exit;

        WorkflowStepArgument.Init();
        WorkflowStepArgument.ID := CreateGuid();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::Response;
        WorkflowStepArgument."Approver Type" := WorkflowStepArgument."Approver Type"::Approver;
        WorkflowStepArgument."Approver Limit Type" := WorkflowStepArgument."Approver Limit Type"::"Direct Approver";
        WorkflowStepArgument.Insert(true);

        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify(true);
    end;

    // =========================================
    // UI TRIGGERS
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Approval Management", 'OnSendForApproval', '', false, false)]
    local procedure OnSendForApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        WorkflowMgmt.HandleEvent(GetSendDocApprovalForApprovalEventCode(), DocumentApprovalHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Approval Management", 'OnCancelApproval', '', false, false)]
    local procedure OnCancelApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        WorkflowMgmt.HandleEvent(GetCancelDocApprovalEventCode(), DocumentApprovalHeader);
    end;
}
