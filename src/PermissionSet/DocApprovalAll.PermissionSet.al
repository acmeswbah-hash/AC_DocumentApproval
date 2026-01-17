/// <summary>
/// Permission Set Doc Approval All (ID 77100)
/// Provides full access to Document Approval objects.
/// </summary>
permissionset 77100 "Doc Approval All"
{
    Caption = 'Document Approval - Full Access';
    Assignable = true;

    Permissions =
        table "Document Approval Header" = X,
        table "Document Approval Line" = X,
        table "Document Approval Setup" = X,
        table "Document Approval Type" = X,
        tabledata "Document Approval Header" = RIMD,
        tabledata "Document Approval Line" = RIMD,
        tabledata "Document Approval Setup" = RIMD,
        tabledata "Document Approval Type" = RIMD,
        page "Document Approval Card" = X,
        page "Document Approval List" = X,
        page "Document Approval Subform" = X,
        page "Document Approval Setup" = X,
        page "Document Approval Types" = X;
}