/// <summary>
/// Codeunit Doc. Attachment Event Handler (ID 77115)
/// Handles events for Document Attachments to enforce delete permissions.
/// Only the user who uploaded a file can delete it (before approval).
/// </summary>
codeunit 77115 "Doc. Attachment Event Handler"
{
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteDocumentAttachment(var Rec: Record "Document Attachment"; RunTrigger: Boolean)
    var
        DocumentApprovalHeader: Record "Document Approval Header";
        CurrentUserId: Code[50];
        CannotDeleteErr: Label 'You can only delete attachments that you have uploaded. This file was attached by %1.';
        CannotDeleteApprovedErr: Label 'You cannot delete attachments from an approved document.';
    begin
        // Only apply this logic to Document Approval Header attachments
        if Rec."Table ID" <> Database::"Document Approval Header" then
            exit;

        // Get current user
        CurrentUserId := CopyStr(UserId, 1, 50);

        // Check if document is approved - don't allow delete on approved documents
        if DocumentApprovalHeader.Get(Rec."No.") then begin
            if DocumentApprovalHeader.Status = DocumentApprovalHeader.Status::Approved then
                Error(CannotDeleteApprovedErr);
        end;

        // Check if current user is the one who attached the file
        if Rec."Attached By" <> CurrentUserId then
            Error(CannotDeleteErr, Rec."Attached By");
    end;
}
