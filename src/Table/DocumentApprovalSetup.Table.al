/// <summary>
/// Table Document Approval Setup (ID 77102)
/// Stores the setup configuration for Document Approval.
/// </summary>
table 77102 "Document Approval Setup"
{
    Caption = 'Document Approval Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Document Approval Nos."; Code[20])
        {
            Caption = 'Document Approval Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestSingleRecord();
    end;

    /// <summary>
    /// Ensures only one setup record exists.
    /// </summary>
    local procedure TestSingleRecord()
    var
        DocumentApprovalSetup: Record "Document Approval Setup";
    begin
        if not DocumentApprovalSetup.IsEmpty then
            Error('A setup record already exists.');
    end;
}
