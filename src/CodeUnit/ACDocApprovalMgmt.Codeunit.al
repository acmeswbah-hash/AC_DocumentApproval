codeunit 77112 "Document Approval Management"
{
    // This codeunit provides high-level procedures for the Document Approval UI
    // and triggers workflow events. Logic for status changes and approval entry 
    // creation is now consolidated in codeunit 77101 "Document Approval Workflow".

    var
        WorkflowMgmt: Codeunit "Workflow Management";
        AlreadyApprovedErr: Label 'This document has already been approved.';
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        PendingApprovalErr: Label 'There is an approval request pending for this document.';
        ApprovalRequestSentMsg: Label 'An approval request has been sent.';
        DocumentReopenedMsg: Label 'The document has been reopened.';

    procedure SendForApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        // Validate document has lines and amount
        DocumentApprovalHeader.ValidateForApproval();

        // Check if approval workflow is enabled
        if not IsDocumentApprovalWorkflowEnabled(DocumentApprovalHeader) then
            Error(NoWorkflowEnabledErr);

        // Check current status
        if DocumentApprovalHeader.Status = DocumentApprovalHeader.Status::Approved then
            Error(AlreadyApprovedErr);

        if DocumentApprovalHeader.Status = DocumentApprovalHeader.Status::"Pending Approval" then
            Error(PendingApprovalErr);

        // Trigger the workflow event
        OnSendForApproval(DocumentApprovalHeader);

        // Refresh record to get updated status from workflow
        if DocumentApprovalHeader.Get(DocumentApprovalHeader."No.") then;

        Message(ApprovalRequestSentMsg);
    end;

    procedure CancelApprovalRequest(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        // Trigger the workflow event
        OnCancelApproval(DocumentApprovalHeader);
        
        // Refresh record
        if DocumentApprovalHeader.Get(DocumentApprovalHeader."No.") then;
    end;

    procedure ReopenDocument(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
        if DocumentApprovalHeader.Status = DocumentApprovalHeader.Status::Approved then
            Error(AlreadyApprovedErr);

        DocumentApprovalHeader.Status := DocumentApprovalHeader.Status::Open;
        DocumentApprovalHeader.Modify(true);

        Message(DocumentReopenedMsg);
    end;

    procedure IsDocumentApprovalWorkflowEnabled(var DocumentApprovalHeader: Record "Document Approval Header"): Boolean
    var
        DocumentApprovalWorkflow: Codeunit "Document Approval Workflow";
    begin
        exit(WorkflowMgmt.CanExecuteWorkflow(DocumentApprovalHeader, DocumentApprovalWorkflow.GetSendDocApprovalForApprovalEventCode()));
    end;

    // ============================================
    // INTEGRATION EVENTS
    // ============================================

    [IntegrationEvent(false, false)]
    procedure OnSendForApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
    end;

    // The manual approval procedures (CreateApprovalRequest, etc.) have been removed 
    // to ensure standard BC Workflow engine is used exclusively.
}
