/// <summary>
/// Table Extension Doc Approval Attach (ID 77100)
/// Extends Document Attachment to support Document Approval Header.
/// </summary>
tableextension 77100 "Doc Approval Attach" extends "Document Attachment"
{
    fields
    {
        // No additional fields needed, just extending the table relationship
    }

    /// <summary>
    /// Initializes attachment for Document Approval Header.
    /// </summary>
    procedure InitFromDocumentApproval(DocumentApprovalHeader: Record "Document Approval Header")
    begin
        Rec."Table ID" := Database::"Document Approval Header";
        Rec."No." := DocumentApprovalHeader."No.";
    end;
}
