/// <summary>
/// Table Document Approval Line (ID 77101)
/// Stores line items for Document Approval documents.
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
                // Only validate status on actual changes, not on page load
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
            end;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                CalculateLineAmount();
            end;
        }
        field(5; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
            AutoFormatType = 2;

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                CalculateLineAmount();
            end;
        }
        field(6; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            Editable = false;
        }
        field(7; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true), Blocked = const(false));

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                if "Account No." <> '' then begin
                    GLAccount.Get("Account No.");
                    if Description = '' then
                        Description := CopyStr(GLAccount.Name, 1, MaxStrLen(Description));
                end;
            end;
        }
        field(8; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    TestStatusOpen();
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    var
        DocumentApprovalHeader: Record "Document Approval Header";
        DimensionMgmt: Codeunit DimensionManagement;
        StatusErr: Label 'You cannot modify lines because the document status is %1.', Comment = '%1 = Status';

    trigger OnInsert()
    begin
        TestStatusOpen();
    end;

    trigger OnModify()
    begin
        TestStatusOpen();
    end;

    trigger OnDelete()
    begin
        TestStatusOpen();
    end;

    trigger OnRename()
    begin
        Error('You cannot rename a Document Approval Line.');
    end;

    /// <summary>
    /// Tests if the parent document status allows modifications.
    /// </summary>
    local procedure TestStatusOpen()
    begin
        GetHeader();
        if (DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::Open) and
           (DocumentApprovalHeader.Status <> DocumentApprovalHeader.Status::Rejected)
        then
            Error(StatusErr, DocumentApprovalHeader.Status);
    end;

    /// <summary>
    /// Gets the parent document header.
    /// </summary>
    local procedure GetHeader()
    begin
        if DocumentApprovalHeader."No." <> "Document No." then
            DocumentApprovalHeader.Get("Document No.");
    end;

    /// <summary>
    /// Calculates the line amount based on quantity and unit price.
    /// </summary>
    local procedure CalculateLineAmount()
    begin
        "Line Amount" := 1 * "Unit Price";
    end;

    /// <summary>
    /// Validates a shortcut dimension code.
    /// </summary>
    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimensionMgmt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    /// <summary>
    /// Shows the dimension set entries for this line.
    /// </summary>
    procedure ShowDimensions()
    begin
        "Dimension Set ID" := DimensionMgmt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document No.", "Line No."));
    end;
}
