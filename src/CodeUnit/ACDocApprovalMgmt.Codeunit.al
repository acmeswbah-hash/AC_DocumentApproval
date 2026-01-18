/// <summary>
/// Codeunit Document Approval Management (ID 77112)
/// Manages Document Approval workflow actions.
/// </summary>
codeunit 77112 "Document Approval Management"
{
    // Integration Events for workflow
    [IntegrationEvent(false, false)]
    procedure OnSendForApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    begin
    end;

    /// <summary>
    /// Sends the document for approval.
    /// </summary>
    procedure SendForApproval(var DocumentApprovalHeader: Record "Document Approval Header")
    var
        DocApprovalWorkflow: Codeunit "Document Approval Workflow";
        NotOpenErr: Label 'You can only send a document for approval when the status is Open.';
        WorkflowNotEnabledErr: Label 'No approval workflow is enabled for this document type.';
    begin
        // Validate status
        if DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::Open then
            Error(NotOpenErr);

        // Validate workflow is enabled
        if not DocApprovalWorkflow.IsDocumentApprovalWorkflowEnabled(DocumentApprovalHeader) then
            Error(WorkflowNotEnabledErr);

        // Validate document has lines
        DocumentApprovalHeader.ValidateForApproval();

        // Trigger workflow event
        OnSendForApproval(DocumentApprovalHeader);
    end;

    /// <summary>
    /// Cancels the approval request.
    /// </summary>
    procedure CancelApprovalRequest(var DocumentApprovalHeader: Record "Document Approval Header")
    var
        NotPendingErr: Label 'You can only cancel approval for documents with Pending Approval status.';
    begin
        // Validate status
        if DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::"Pending Approval" then
            Error(NotPendingErr);

        // Trigger workflow event
        OnCancelApproval(DocumentApprovalHeader);
    end;

    /// <summary>
    /// Reopens the document for editing.
    /// Can be used on Rejected or Approved documents.
    /// </summary>
    procedure ReopenDocument(var DocumentApprovalHeader: Record "Document Approval Header")
    var
        ReopenConfirmQst: Label 'Are you sure you want to reopen this document? The approval history will be preserved but the document will need to be sent for approval again.';
        StatusErr: Label 'You can only reopen documents with Rejected or Approved status.';
    begin
        // Validate status - allow reopen from Rejected or Approved
        if not (DocumentApprovalHeader.Status in [DocumentApprovalHeader.Status::Rejected, DocumentApprovalHeader.Status::Approved]) then
            Error(StatusErr);

        // Confirm reopen
        if not Confirm(ReopenConfirmQst) then
            exit;

        // Reset document to Open status
        DocumentApprovalHeader.Status := DocumentApprovalHeader.Status::Open;
        DocumentApprovalHeader."Approved By" := '';
        DocumentApprovalHeader."Approved Date" := 0D;
        DocumentApprovalHeader."Date-Time Sent for Approval" := 0DT;
        DocumentApprovalHeader.Modify(true);

        Message('Document has been reopened and can now be edited and sent for approval again.');
    end;

    /// <summary>
    /// Checks if the Document Approval workflow is enabled.
    /// </summary>
    procedure IsDocumentApprovalWorkflowEnabled(var DocumentApprovalHeader: Record "Document Approval Header"): Boolean
    var
        DocApprovalWorkflow: Codeunit "Document Approval Workflow";
    begin
        exit(DocApprovalWorkflow.IsDocumentApprovalWorkflowEnabled(DocumentApprovalHeader));
    end;
}
