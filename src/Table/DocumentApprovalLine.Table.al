/// <summary>
/// Table Document Approval Line (ID 77101)
/// Stores the line details for Document Approval documents.
/// </summary>
table 77101 "Document Approval Line"
{
    Caption = 'Document Approval Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            TableRelation = "Document Approval Header"."No.";

            trigger OnValidate()
            begin
                GetHeader();
                TestStatusOpen();
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "S. No."; Integer)
        {
            Caption = 'S. No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Line Description"; Text[250])
        {
            Caption = 'Line Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(5; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Line Amount" < 0 then
                    Error(NegativeAmountErr);
            end;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "S. No.")
        {
        }
    }

    var
        DocumentApprovalHeader: Record "Document Approval Header";
        NegativeAmountErr: Label 'Line Amount must be greater than or equal to zero.';
        StatusErr: Label 'You cannot modify lines because the document status is %1.', Comment = '%1 = Status';

    trigger OnInsert()
    begin
        TestStatusOpen();
        AssignSequenceNo();
    end;

    trigger OnModify()
    begin
        // We removed TestStatusOpen from here to allow system modifications
        // Field-level validations and OnDelete still enforce the lock.
    end;

    trigger OnDelete()
    begin
        TestStatusOpen();
    end;

    trigger OnRename()
    begin
        Error('You cannot rename a Document Approval line.');
    end;

    /// <summary>
    /// Gets the parent header record.
    /// </summary>
    local procedure GetHeader()
    begin
        if "Document No." <> '' then
            DocumentApprovalHeader.Get("Document No.");
    end;

    /// <summary>
    /// Tests if the parent document status allows modifications.
    /// </summary>
    procedure TestStatusOpen()
    begin
        GetHeader();
        if (DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::Open) and (DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::Rejected) then
            Error(StatusErr, DocumentApprovalHeader.Status);
    end;

    /// <summary>
    /// Assigns the sequence number for display purposes.
    /// </summary>
    local procedure AssignSequenceNo()
    var
        DocApprovalLine: Record "Document Approval Line";
        MaxSeqNo: Integer;
    begin
        DocApprovalLine.SetRange("Document No.", "Document No.");
        if DocApprovalLine.FindLast() then
            MaxSeqNo := DocApprovalLine."S. No.";

        "S. No." := MaxSeqNo + 1;
    end;
}
