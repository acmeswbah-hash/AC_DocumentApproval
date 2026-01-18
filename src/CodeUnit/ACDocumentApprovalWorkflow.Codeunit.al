codeunit 77101 "Document Approval Workflow"
{
    // This codeunit consolidates all workflow logic for Document Approvals.

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
        CancelDocApprovalEventDescTxt: Label 'An Employee Document approval request is canceled.';

    // =========================================
    // WORKFLOW EVENT CODES
    // =========================================

    procedure GetSendDocApprovalForApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendDocumentApprovalForApproval'));
    end;

    procedure GetCancelDocApprovalEventCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelDocumentApprovalApproval'));
    end;

    // =========================================
    // ADD EVENTS TO LIBRARY
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    begin
        SafeAddEventToLibrary(
            GetSendDocApprovalForApprovalEventCode(),
            Database::"Document Approval Header",
            SendDocApprovalForApprovalEventDescTxt,
            0,
            true);

        SafeAddEventToLibrary(
            GetCancelDocApprovalEventCode(),
            Database::"Document Approval Header",
            CancelDocApprovalEventDescTxt,
            0,
            true);
    end;

    local procedure SafeAddEventToLibrary(FunctionName: Code[128]; TableID: Integer; Description: Text[250]; RequestPageID: Integer; UsedForRecordChange: Boolean)
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        if WorkflowEvent.Get(FunctionName) then
            exit;

        WorkflowEvent.Reset();
        WorkflowEvent.SetRange(Description, Description);
        if not WorkflowEvent.IsEmpty then
            exit;

        Clear(WorkflowEvent);
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := FunctionName;
        WorkflowEvent."Table ID" := TableID;
        WorkflowEvent.Description := Description;
        WorkflowEvent."Request Page ID" := RequestPageID;
        WorkflowEvent."Used for Record Change" := UsedForRecordChange;
        if WorkflowEvent.Insert(false) then;
    end;

    // =========================================
    // ADD EVENT PREDECESSORS
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(
                    WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                    GetSendDocApprovalForApprovalEventCode());

            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(
                    WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                    GetSendDocApprovalForApprovalEventCode());

            WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(
                    WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                    GetSendDocApprovalForApprovalEventCode());

            GetCancelDocApprovalEventCode():
                WorkflowEventHandling.AddEventPredecessor(
                    GetCancelDocApprovalEventCode(),
                    GetSendDocApprovalForApprovalEventCode());
        end;
    end;

    // =========================================
    // ADD TABLE RELATIONS
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure OnAddWorkflowTableRelationsToLibrary()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        WorkflowSetup.InsertTableRelation(
            Database::"Document Approval Header",
            0,
            Database::"Approval Entry",
            ApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    // =========================================
    // ADD RESPONSE PREDECESSORS
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    begin
        case ResponseFunctionName of
            WorkflowResponseHandling.SetStatusToPendingApprovalCode():
                WorkflowResponseHandling.AddResponsePredecessor(
                    WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
                    GetSendDocApprovalForApprovalEventCode());

            WorkflowResponseHandling.CreateApprovalRequestsCode():
                WorkflowResponseHandling.AddResponsePredecessor(
                    WorkflowResponseHandling.CreateApprovalRequestsCode(),
                    GetSendDocApprovalForApprovalEventCode());

            WorkflowResponseHandling.SendApprovalRequestForApprovalCode():
                WorkflowResponseHandling.AddResponsePredecessor(
                    WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
                    GetSendDocApprovalForApprovalEventCode());

            WorkflowResponseHandling.CancelAllApprovalRequestsCode():
                WorkflowResponseHandling.AddResponsePredecessor(
                    WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
                    GetCancelDocApprovalEventCode());

            WorkflowResponseHandling.OpenDocumentCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(
                        WorkflowResponseHandling.OpenDocumentCode(),
                        GetCancelDocApprovalEventCode());
                    WorkflowResponseHandling.AddResponsePredecessor(
                        WorkflowResponseHandling.OpenDocumentCode(),
                        WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
                end;

            WorkflowResponseHandling.ReleaseDocumentCode():
                WorkflowResponseHandling.AddResponsePredecessor(
                    WorkflowResponseHandling.ReleaseDocumentCode(),
                    WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());

            WorkflowResponseHandling.RejectAllApprovalRequestsCode():
                WorkflowResponseHandling.AddResponsePredecessor(
                    WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
                    WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
        end;
    end;

    // =========================================
    // APPROVALS MGMT. INTEGRATION
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
        ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::" ";
        ApprovalEntryArgument.Amount := DocumentApprovalHeader."Total Amount";
        ApprovalEntryArgument."Amount (LCY)" := DocumentApprovalHeader."Total Amount";
    end;

    // =========================================
    // RESPONSE HANDLERS
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', false, false)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        DocumentApprovalHeader: Record "Document Approval Header";
    begin
        if RecRef.Number <> Database::"Document Approval Header" then
            exit;

        RecRef.SetTable(DocumentApprovalHeader);
        DocumentApprovalHeader.Status := DocumentApprovalHeader.Status::"Pending Approval";
        DocumentApprovalHeader."Date-Time Sent for Approval" := CurrentDateTime;
        DocumentApprovalHeader.Modify(true);

        Variant := DocumentApprovalHeader;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        DocumentApprovalHeader: Record "Document Approval Header";
    begin
        if RecRef.Number <> Database::"Document Approval Header" then
            exit;

        RecRef.SetTable(DocumentApprovalHeader);
        DocumentApprovalHeader.Status := DocumentApprovalHeader.Status::Approved;
        DocumentApprovalHeader."Approved By" := CopyStr(UserId, 1, MaxStrLen(DocumentApprovalHeader."Approved By"));
        DocumentApprovalHeader."Approved Date" := Today;
        DocumentApprovalHeader.Modify(true);

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', false, false)]
    local procedure OnOpenDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        DocumentApprovalHeader: Record "Document Approval Header";
    begin
        if RecRef.Number <> Database::"Document Approval Header" then
            exit;

        RecRef.SetTable(DocumentApprovalHeader);
        DocumentApprovalHeader.Status := DocumentApprovalHeader.Status::Open;
        DocumentApprovalHeader."Approved By" := '';
        DocumentApprovalHeader."Approved Date" := 0D;
        DocumentApprovalHeader."Date-Time Sent for Approval" := 0DT;
        DocumentApprovalHeader.Modify(true);

        Handled := true;
    end;

    // =========================================
    // UI TRIGGERS
    // =========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Approval Management", 'OnSendForApproval', '', false, false)]
    local procedure HandleOnSendForApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        WorkflowMgmt.HandleEvent(GetSendDocApprovalForApprovalEventCode(), DocumentApprovalHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Approval Management", 'OnCancelApproval', '', false, false)]
    local procedure HandleOnCancelApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        WorkflowMgmt.HandleEvent(GetCancelDocApprovalEventCode(), DocumentApprovalHeader);
    end;

    // =========================================
    // HELPER: Check and update document status after approval
    // Called from the page after approval action
    // =========================================

    procedure CheckAndUpdateApprovalStatus(var DocumentApprovalHeader: Record "Document Approval Header")
    var
        ApprovalEntry: Record "Approval Entry";
        HasPendingApprovals: Boolean;
    begin
        if DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::"Pending Approval" then
            exit;

        // Check if there are any pending approvals left
        ApprovalEntry.SetRange("Table ID", Database::"Document Approval Header");
        ApprovalEntry.SetRange("Record ID to Approve", DocumentApprovalHeader.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        HasPendingApprovals := not ApprovalEntry.IsEmpty;

        // If no more pending approvals, set status to Approved
        if not HasPendingApprovals then begin
            DocumentApprovalHeader.Status := DocumentApprovalHeader.Status::Approved;
            DocumentApprovalHeader."Approved By" := CopyStr(UserId, 1, MaxStrLen(DocumentApprovalHeader."Approved By"));
            DocumentApprovalHeader."Approved Date" := Today;
            DocumentApprovalHeader.Modify(true);
        end;
    end;

    // =========================================
    // MANUAL REGISTRATION OF RESPONSE COMBINATIONS
    // =========================================

    procedure RegisterWorkflowResponseCombinations()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        // For Send Document Approval Event
        InsertEventResponseCombination(GetSendDocApprovalForApprovalEventCode(), WorkflowResponseHandling.SetStatusToPendingApprovalCode());
        InsertEventResponseCombination(GetSendDocApprovalForApprovalEventCode(), WorkflowResponseHandling.CreateApprovalRequestsCode());
        InsertEventResponseCombination(GetSendDocApprovalForApprovalEventCode(), WorkflowResponseHandling.SendApprovalRequestForApprovalCode());
        InsertEventResponseCombination(GetSendDocApprovalForApprovalEventCode(), WorkflowResponseHandling.ShowMessageCode());

        // For Cancel Document Approval Event
        InsertEventResponseCombination(GetCancelDocApprovalEventCode(), WorkflowResponseHandling.CancelAllApprovalRequestsCode());
        InsertEventResponseCombination(GetCancelDocApprovalEventCode(), WorkflowResponseHandling.OpenDocumentCode());
        InsertEventResponseCombination(GetCancelDocApprovalEventCode(), WorkflowResponseHandling.ShowMessageCode());

        // For standard approval events
        InsertEventResponseCombination(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), WorkflowResponseHandling.ReleaseDocumentCode());
        InsertEventResponseCombination(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), WorkflowResponseHandling.OpenDocumentCode());
        InsertEventResponseCombination(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), WorkflowResponseHandling.RejectAllApprovalRequestsCode());
        InsertEventResponseCombination(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(), WorkflowResponseHandling.SendApprovalRequestForApprovalCode());

        Message('Workflow response combinations have been registered successfully.\nPlease close and reopen the Workflows page.');
    end;

    local procedure InsertEventResponseCombination(EventCode: Code[128]; ResponseCode: Code[128])
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombination.Type::Response);
        WFEventResponseCombination.SetRange("Function Name", ResponseCode);
        WFEventResponseCombination.SetRange("Predecessor Type", WFEventResponseCombination."Predecessor Type"::"Event");
        WFEventResponseCombination.SetRange("Predecessor Function Name", EventCode);
        if not WFEventResponseCombination.IsEmpty then
            exit;

        WFEventResponseCombination.Init();
        WFEventResponseCombination.Type := WFEventResponseCombination.Type::Response;
        WFEventResponseCombination."Function Name" := ResponseCode;
        WFEventResponseCombination."Predecessor Type" := WFEventResponseCombination."Predecessor Type"::"Event";
        WFEventResponseCombination."Predecessor Function Name" := EventCode;
        if WFEventResponseCombination.Insert(false) then;
    end;

    // =========================================
    // CLEANUP PROCEDURE
    // =========================================

    procedure CleanupOrphanedWorkflowEvents()
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        if WorkflowEvent.Get(GetSendDocApprovalForApprovalEventCode()) then
            WorkflowEvent.Delete(false);

        if WorkflowEvent.Get(GetCancelDocApprovalEventCode()) then
            WorkflowEvent.Delete(false);

        WorkflowEvent.Reset();
        WorkflowEvent.SetRange(Description, SendDocApprovalForApprovalEventDescTxt);
        WorkflowEvent.DeleteAll(false);

        WorkflowEvent.Reset();
        WorkflowEvent.SetRange(Description, CancelDocApprovalEventDescTxt);
        WorkflowEvent.DeleteAll(false);

        Message('Cleanup complete. Now re-open the Workflows page to reinitialize.');
    end;

    // =========================================
    // WORKFLOW TEMPLATE CREATION
    // =========================================

    procedure CreateDocumentApprovalWorkflowTemplate(): Boolean
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowRule: Record "Workflow Rule";
        WorkflowCode: Code[20];
        SendEventStepID: Integer;
        SetPendingStepID: Integer;
        CreateRequestsStepID: Integer;
        SendRequestStepID: Integer;
        ApproveEventStepID: Integer;
        ReleaseStepID: Integer;
        RejectEventStepID: Integer;
        RejectRequestStepID: Integer;
        ReopenOnRejectStepID: Integer;
        DelegateEventStepID: Integer;
        SendDelegateStepID: Integer;
        CancelEventStepID: Integer;
        CancelRequestStepID: Integer;
        ReopenOnCancelStepID: Integer;
    begin
        WorkflowCode := DocumentApprovalWorkflowCodeTxt;

        // First, register the response combinations
        RegisterWorkflowResponseCombinations();

        // Delete existing workflow if exists
        if Workflow.Get(WorkflowCode) then begin
            Workflow.Enabled := false;
            Workflow.Modify();

            WorkflowStep.SetRange("Workflow Code", WorkflowCode);
            WorkflowStep.DeleteAll(true);

            WorkflowRule.SetRange("Workflow Code", WorkflowCode);
            WorkflowRule.DeleteAll(true);
        end else begin
            Workflow.Init();
            Workflow.Code := WorkflowCode;
            Workflow.Description := DocumentApprovalWorkflowDescTxt;
            Workflow.Category := 'APPROVALS';
            Workflow.Template := false;
            Workflow.Enabled := false;
            Workflow.Insert(true);
        end;

        // BRANCH 1: Send for Approval Flow
        SendEventStepID := InsertWorkflowEventStep(WorkflowCode, GetSendDocApprovalForApprovalEventCode(), 0, true);
        InsertEventCondition(WorkflowCode, SendEventStepID);

        SetPendingStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.SetStatusToPendingApprovalCode(), SendEventStepID);
        CreateRequestsStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.CreateApprovalRequestsCode(), SetPendingStepID);
        SetApprovalArgument(WorkflowCode, CreateRequestsStepID);
        SendRequestStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), CreateRequestsStepID);

        // BRANCH 2: Approval Approved Flow
        ApproveEventStepID := InsertWorkflowEventStep(WorkflowCode, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), SendRequestStepID, false);
        ReleaseStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.ReleaseDocumentCode(), ApproveEventStepID);

        // BRANCH 3: Approval Rejected Flow
        RejectEventStepID := InsertWorkflowEventStep(WorkflowCode, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), SendRequestStepID, false);
        RejectRequestStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.RejectAllApprovalRequestsCode(), RejectEventStepID);
        ReopenOnRejectStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.OpenDocumentCode(), RejectRequestStepID);

        // BRANCH 4: Approval Delegated Flow
        DelegateEventStepID := InsertWorkflowEventStep(WorkflowCode, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(), SendRequestStepID, false);
        SendDelegateStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), DelegateEventStepID);

        // BRANCH 5: Cancel Approval Flow
        CancelEventStepID := InsertWorkflowEventStep(WorkflowCode, GetCancelDocApprovalEventCode(), 0, true);
        InsertEventCondition(WorkflowCode, CancelEventStepID);
        CancelRequestStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.CancelAllApprovalRequestsCode(), CancelEventStepID);
        ReopenOnCancelStepID := InsertWorkflowResponseStep(WorkflowCode, WorkflowResponseHandling.OpenDocumentCode(), CancelRequestStepID);

        exit(true);
    end;

    local procedure InsertWorkflowEventStep(WorkflowCode: Code[20]; EventCode: Code[128]; PreviousStepID: Integer; IsEntryPoint: Boolean): Integer
    var
        WorkflowStep: Record "Workflow Step";
        NextID: Integer;
    begin
        NextID := GetNextStepID(WorkflowCode);

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := WorkflowCode;
        WorkflowStep.ID := NextID;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep."Function Name" := EventCode;
        WorkflowStep."Entry Point" := IsEntryPoint;
        WorkflowStep."Previous Workflow Step ID" := PreviousStepID;
        WorkflowStep.Insert(true);

        exit(NextID);
    end;

    local procedure InsertWorkflowResponseStep(WorkflowCode: Code[20]; ResponseCode: Code[128]; PreviousStepID: Integer): Integer
    var
        WorkflowStep: Record "Workflow Step";
        NextID: Integer;
    begin
        NextID := GetNextStepID(WorkflowCode);

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := WorkflowCode;
        WorkflowStep.ID := NextID;
        WorkflowStep.Type := WorkflowStep.Type::Response;
        WorkflowStep."Function Name" := ResponseCode;
        WorkflowStep."Entry Point" := false;
        WorkflowStep."Previous Workflow Step ID" := PreviousStepID;
        WorkflowStep."Sequence No." := 1;
        WorkflowStep.Insert(true);

        exit(NextID);
    end;

    local procedure GetNextStepID(WorkflowCode: Code[20]): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        if WorkflowStep.FindLast() then
            exit(WorkflowStep.ID + 1);
        exit(1);
    end;

    local procedure InsertEventCondition(WorkflowCode: Code[20]; StepID: Integer)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if not WorkflowStep.Get(WorkflowCode, StepID) then
            exit;

        WorkflowStepArgument.Init();
        WorkflowStepArgument.ID := CreateGuid();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::"Event";
        WorkflowStepArgument."Table No." := Database::"Document Approval Header";
        WorkflowStepArgument.Insert(true);

        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify(true);
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
        WorkflowStepArgument."Table No." := Database::"Document Approval Header";
        WorkflowStepArgument."Link Target Page" := Page::"Document Approval Card";
        WorkflowStepArgument."Workflow User Group Code" := '';
        WorkflowStepArgument.Insert(true);

        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify(true);
    end;

    // =========================================
    // HELPER: Check if workflow is enabled
    // =========================================

    procedure IsDocumentApprovalWorkflowEnabled(var DocumentApprovalHeader: Record "Document Approval Header"): Boolean
    begin
        exit(WorkflowMgmt.CanExecuteWorkflow(DocumentApprovalHeader, GetSendDocApprovalForApprovalEventCode()));
    end;
}
