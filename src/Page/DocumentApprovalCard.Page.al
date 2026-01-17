/// <summary>
/// Page Document Approval Card (ID 77100)
/// Document card page for creating and viewing Document Approval documents.
/// </summary>
page 77100 "Document Approval Card"
{
    Caption = 'Document Approval';
    PageType = Document;
    SourceTable = "Document Approval Header";
    RefreshOnActivate = true;
    PromotedActionCategories = 'New,Process,Report,Approval,Navigate';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    var
                        NoSeries: Codeunit "No. Series";
                        DocumentApprovalSetup: Record "Document Approval Setup";
                    begin
                        if Rec."No." = '' then begin
                            DocumentApprovalSetup.Get();
                            DocumentApprovalSetup.TestField("Document Approval Nos.");
                            if NoSeries.LookupRelatedNoSeries(DocumentApprovalSetup."Document Approval Nos.", Rec."No. Series") then begin
                                Rec."No." := NoSeries.GetNextNo(Rec."No. Series", WorkDate(), true);
                                CurrPage.Update();
                            end;
                        end;
                    end;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document date.';
                    Importance = Promoted;
                    Editable = IsEditable;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type.';
                    Editable = IsEditable;
                }
                field("Document Description"; Rec."Document Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the document.';
                    MultiLine = true;
                    Editable = IsEditable;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the document.';
                    Importance = Promoted;
                    StyleExpr = StatusStyleTxt;
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of all lines.';
                    Importance = Promoted;
                    Style = Strong;
                }
            }
            part(Lines; "Document Approval Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
                Editable = IsEditable;
            }
            group(Administration)
            {
                Caption = 'Administration';

                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who created the document.';
                    Editable = false;
                }
                field("Created Date"; Rec."Created Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was created.';
                    Editable = false;
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who approved the document.';
                    Editable = false;
                    Visible = Rec.Status = Rec.Status::Approved;
                }
                field("Approved Date"; Rec."Approved Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was approved.';
                    Editable = false;
                    Visible = Rec.Status = Rec.Status::Approved;
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
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(77100), "Document No." = field("No.");
                Visible = ShowApprovalFactBox;
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
            group(Approval)
            {
                Caption = 'Approval';

                action(SendForApproval)
                {
                    ApplicationArea = All;
                    Caption = 'Send for Approval';
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Enabled = CanSendForApproval;
                    ToolTip = 'Send the document for approval.';

                    trigger OnAction()
                    var
                        DocumentApprovalMgmt: Codeunit "Document Approval Management";
                    begin
                        // Ensure any page changes are saved before starting the workflow
                        if Rec.Modify(true) then;
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
                    PromotedCategory = Category4;
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
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Enabled = CanApprove;
                    ToolTip = 'Approve the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                        CurrPage.Update(false);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Enabled = CanReject;
                    ToolTip = 'Reject the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);
                        CurrPage.Update(false);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Enabled = CanDelegate;
                    ToolTip = 'Delegate the approval to another approver.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(Rec.RecordId);
                        CurrPage.Update(false);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = All;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    Enabled = CanReopen;
                    ToolTip = 'Reopen the rejected document for editing.';

                    trigger OnAction()
                    var
                        DocumentApprovalMgmt: Codeunit "Document Approval Management";
                    begin
                        DocumentApprovalMgmt.ReopenDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Attachments)
            {
                Caption = 'Attachments';

                action(ManageAttachments)
                {
                    ApplicationArea = All;
                    Caption = 'Manage Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Add or view document attachments.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
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
                PromotedCategory = Category5;
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
        IsEditable: Boolean;
        CanSendForApproval: Boolean;
        CanCancelApproval: Boolean;
        CanApprove: Boolean;
        CanReject: Boolean;
        CanDelegate: Boolean;
        CanReopen: Boolean;
        ShowApprovalFactBox: Boolean;
        StatusStyleTxt: Text;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility();
        SetStatusStyle();
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetControlVisibility();
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Document is editable only when Open or Rejected
        IsEditable := (Rec.Status = Rec.Status::Open) or (Rec.Status = Rec.Status::Rejected);

        // Can send for approval when Open
        CanSendForApproval := (Rec.Status = Rec.Status::Open) and
                             DocumentApprovalMgmt.IsDocumentApprovalWorkflowEnabled(Rec);

        // Can cancel approval when Pending Approval
        CanCancelApproval := Rec.Status = Rec.Status::"Pending Approval";

        // Can approve/reject/delegate when Pending and user is approver
        CanApprove := (Rec.Status = Rec.Status::"Pending Approval") and
                      ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        CanReject := CanApprove;
        CanDelegate := CanApprove;

        // Can reopen when Rejected
        CanReopen := Rec.Status = Rec.Status::Rejected;

        // Show approval factbox when pending or approved
        ShowApprovalFactBox := (Rec.Status = Rec.Status::"Pending Approval") or
                               (Rec.Status = Rec.Status::Approved);
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
