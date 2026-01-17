/// <summary>
/// Page Document Approval Types (ID 77104)
/// List page for managing Document Approval Types.
/// </summary>
page 77104 "Document Approval Types"
{
    Caption = 'Document Approval Types';
    PageType = List;
    SourceTable = "Document Approval Type";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("ID"; Rec."ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier for the document type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the document type.';
                }
            }
        }
    }
}
