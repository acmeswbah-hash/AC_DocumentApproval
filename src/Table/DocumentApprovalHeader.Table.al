/// <summary>
/// Table Document Approval Header (ID 77100)
/// Stores the header information for Document Approval documents.
/// </summary>
table 77100 "Document Approval Header"
{
    Caption = 'Document Approval Header';
    DataClassification = CustomerContent;
    LookupPageId = "Document Approval List";
    DrillDownPageId = "Document Approval List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetSetup();
                    NoSeries.TestManual(DocumentApprovalSetup."Document Approval Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(3; "Document Type"; Code[20])
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            TableRelation = "Document Approval Type"."ID";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(4; "Document Description"; Text[250])
        {
            Caption = 'Document Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(5; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            //DataClassification = CustomerContent;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Document Approval Line"."Line Amount" where("Document No." = field("No.")));
        }
        field(6; Status; Enum "Document Approval Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            Editable = false;
        }
        field(8; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9; "Created Date"; Date)
        {
            Caption = 'Created Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "Approved Date"; Date)
        {
            Caption = 'Approved Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "Last Modified By User ID"; Code[50])
        {
            Caption = 'Last Modified By User ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "Date-Time Sent for Approval"; DateTime)
        {
            Caption = 'Date-Time Sent for Approval';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "Pending Approver User ID"; Code[50])
        {
            Caption = 'Pending Approver User ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
        key(Key3; "Document Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Document Description", Status, "Total Amount")
        {
        }
        fieldgroup(Brick; "No.", "Document Description", Status, "Total Amount")
        {
        }
    }

    var
        DocumentApprovalSetup: Record "Document Approval Setup";
        DocumentApprovalLine: Record "Document Approval Line";
        StatusErr: Label 'You cannot modify the document because the status is %1.', Comment = '%1 = Status';
        DeleteLinesQst: Label 'All related lines will be deleted. Do you want to continue?';
        HasSetup: Boolean;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GetSetup();
            DocumentApprovalSetup.TestField("Document Approval Nos.");
            "No." := NoSeries.GetNextNo(DocumentApprovalSetup."Document Approval Nos.", WorkDate(), true);
            "No. Series" := DocumentApprovalSetup."Document Approval Nos.";
        end;

        if "Document Date" = 0D then
            "Document Date" := WorkDate();

        "Created By" := CopyStr(UserId, 1, MaxStrLen("Created By"));
        "Created Date" := Today;
    end;

    trigger OnModify()
    begin
        // We removed TestStatusOpen from here to allow system modifications (like status changes or background updates)
        // while the document is locked. Field-level validations and OnDelete still enforce the lock.
    end;

    trigger OnDelete()
    begin
        TestStatusOpen();

        DocumentApprovalLine.SetRange("Document No.", "No.");
        if not DocumentApprovalLine.IsEmpty then
            if not Confirm(DeleteLinesQst) then
                Error('');
        DocumentApprovalLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error('You cannot rename a Document Approval document.');
    end;

    /// <summary>
    /// Tests if the document status is Open, allowing modifications.
    /// </summary>
    procedure TestStatusOpen()
    begin
        if (Status <> Status::Open) and (Status <> Status::Rejected) then
            Error(StatusErr, Status);
    end;

    /// <summary>
    /// Retrieves the Document Approval Setup record.
    /// </summary>
    local procedure GetSetup()
    begin
        if not HasSetup then begin
            DocumentApprovalSetup.Get();
            HasSetup := true;
        end;
    end;

    /// <summary>
    /// Calculates and returns the total amount from lines.
    /// </summary>
    procedure GetTotalAmount(): Decimal
    var
        DocApprovalLine: Record "Document Approval Line";
        TotalAmt: Decimal;
    begin
        DocApprovalLine.SetRange("Document No.", "No.");
        if DocApprovalLine.FindSet() then
            repeat
                TotalAmt += DocApprovalLine."Line Amount";
            until DocApprovalLine.Next() = 0;
        exit(TotalAmt);
    end;

    /// <summary>
    /// Validates that the document has at least one line before submission.
    /// </summary>
    procedure ValidateForApproval()
    var
        DocApprovalLine: Record "Document Approval Line";
        NoLinesErr: Label 'You must enter at least one line before submitting for approval.';
        ZeroAmountErr: Label 'The total amount must be greater than zero.';
    begin
        DocApprovalLine.SetRange("Document No.", "No.");
        if DocApprovalLine.IsEmpty then
            Error(NoLinesErr);

        CalcFields("Total Amount");
        if "Total Amount" <= 0 then
            Error(ZeroAmountErr);
    end;
}
