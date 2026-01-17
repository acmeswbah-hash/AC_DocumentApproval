/// <summary>
/// Page Document Approval List (ID 77101)
/// List page displaying all Document Approval documents.
/// </summary>
page 77101 "Document Approval List"
{
    Caption = 'Document Approvals';
    PageType = List;
    SourceTable = "Document Approval Header";
    CardPageId = "Document Approval Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    RefreshOnActivate = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type.';
                }
                field("Document Description"; Rec."Document Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the document.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of all lines.';
                    Style = Strong;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the document.';
                    StyleExpr = StatusStyleTxt;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who created the document.';
                }
                field("Created Date"; Rec."Created Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was created.';
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who approved the document.';
                }
                field("Approved Date"; Rec."Approved Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was approved.';
                }
            }
        }
        area(FactBoxes)
        {
            part(AttachmentFactBox; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(77100), "No." = field("No.");
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendForApproval)
            {
                ApplicationArea = All;
                Caption = 'Send for Approval';
                Image = SendApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = CanSendForApproval;
                ToolTip = 'Send the document for approval.';

                trigger OnAction()
                var
                    DocumentApprovalMgmt: Codeunit "Document Approval Management";
                begin
                    DocumentApprovalMgmt.SendForApproval(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelApprovalRequest)
            {
                ApplicationArea = All;
                Caption = 'Cancel Approval Request';
                Image = CancelApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = CanCancelApproval;
                ToolTip = 'Cancel the pending approval request.';

                trigger OnAction()
                var
                    DocumentApprovalMgmt: Codeunit "Document Approval Management";
                begin
                    DocumentApprovalMgmt.CancelApprovalRequest(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(ApprovalEntries)
            {
                ApplicationArea = All;
                Caption = 'Approval Entries';
                Image = Approvals;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View the approval entries for this document.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);
                end;
            }
        }
    }

    var
        DocumentApprovalMgmt: Codeunit "Document Approval Management";
        CanSendForApproval: Boolean;
        CanCancelApproval: Boolean;
        StatusStyleTxt: Text;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility();
        SetStatusStyle();
    end;

    local procedure SetControlVisibility()
    begin
        CanSendForApproval := (Rec.Status = Rec.Status::Open);
        //and DocumentApprovalMgmt.IsDocumentApprovalWorkflowEnabled(Rec);
        CanCancelApproval := Rec.Status = Rec.Status::"Pending Approval";
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Open:
                StatusStyleTxt := 'Standard';
            Rec.Status::"Pending Approval":
                StatusStyleTxt := 'Attention';
            Rec.Status::Approved:
                StatusStyleTxt := 'Favorable';
            Rec.Status::Rejected:
                StatusStyleTxt := 'Unfavorable';
        end;
    end;
}
