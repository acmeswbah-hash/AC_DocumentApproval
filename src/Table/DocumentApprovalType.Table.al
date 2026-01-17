/// <summary>
/// Table Document Approval Type (ID 77103)
/// Stores the document types for Document Approval documents.
/// </summary>
table 77103 "Document Approval Type"
{
    Caption = 'Document Approval Type';
    DataClassification = CustomerContent;
    LookupPageId = "Document Approval Types";
    DrillDownPageId = "Document Approval Types";

    fields
    {
        field(1; "ID"; Code[20])
        {
            Caption = 'ID';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "ID", Description)
        {
        }
        fieldgroup(Brick; "ID", Description)
        {
        }
    }

    trigger OnDelete()
    var
        DocumentApprovalHeader: Record "Document Approval Header";
        CannotDeleteErr: Label 'You cannot delete %1 because it is used in one or more Document Approval documents.', Comment = '%1 = Document Type ID';
    begin
        DocumentApprovalHeader.SetRange("Document Type", "ID");
        if not DocumentApprovalHeader.IsEmpty then
            Error(CannotDeleteErr, "ID");
    end;
}
