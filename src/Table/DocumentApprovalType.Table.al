/// <summary>
/// Table Document Approval Type (ID 77102)
/// Stores the document types available for Document Approvals.
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
        field(3; "Requires Attachment"; Boolean)
        {
            Caption = 'Requires Attachment';
            DataClassification = CustomerContent;
        }
        field(4; Active; Boolean)
        {
            Caption = 'Active';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
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
        CannotDeleteErr: Label 'You cannot delete %1 because it is used in one or more documents.', Comment = '%1 = ID';
    begin
        DocumentApprovalHeader.SetRange("Document Type", "ID");
        if not DocumentApprovalHeader.IsEmpty then
            Error(CannotDeleteErr, "ID");
    end;
}
