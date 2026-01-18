/// <summary>
/// Page Document Approval List (ID 77101)
/// List page for viewing all Document Approval documents.
/// </summary>
page 77101 "Document Approval List"
{
    Caption = 'Document Approvals';
    PageType = List;
    SourceTable = "Document Approval Header";
    CardPageId = "Document Approval Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
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
                field("Document Type Description"; Rec."Document Type Description")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the document type.';
                }
                field("Document Description"; Rec."Document Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the document.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the document.';
                    StyleExpr = StatusStyleTxt;
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of all lines.';
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
                    Visible = false;
                }
                field("Approved Date"; Rec."Approved Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was approved.';
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(77100), "Document No." = field("No.");
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
            systempart(Links; Links)
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
                ToolTip = 'Send the selected document for approval.';

                trigger OnAction()
                var
                    DocApprovalMgmt: Codeunit "Document Approval Management";
                begin
                    DocApprovalMgmt.SendForApproval(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelApprovalRequest)
            {
                ApplicationArea = All;
                Caption = 'Cancel Approval';
                Image = CancelApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = CanCancelApproval;
                ToolTip = 'Cancel the pending approval request.';

                trigger OnAction()
                var
                    DocApprovalMgmt: Codeunit "Document Approval Management";
                begin
                    DocApprovalMgmt.CancelApprovalRequest(Rec);
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

    trigger OnAfterGetCurrRecord()
    begin
        SetControlVisibility();
    end;

    local procedure SetControlVisibility()
    begin
        CanSendForApproval := (Rec.Status = Rec.Status::Open) and
                             DocumentApprovalMgmt.IsDocumentApprovalWorkflowEnabled(Rec);
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
            else
                StatusStyleTxt := 'Standard';
        end;
    end;
}
