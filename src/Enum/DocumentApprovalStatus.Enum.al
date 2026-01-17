/// <summary>
/// Enum Document Approval Status (ID 77100)
/// Defines the possible statuses for a Document Approval document.
/// </summary>
enum 77100 "Document Approval Status"
{
    Extensible = true;
    Caption = 'Document Approval Status';

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; "Pending Approval")
    {
        Caption = 'Pending Approval';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
    value(4; Canceled)
    {
        Caption = 'Canceled';
    }
    value(5; InReview)
    {
        Caption = 'In Review';
    }
}
