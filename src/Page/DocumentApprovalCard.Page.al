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
                field("Document Type"; DocumentTypeDisplayText)
                {
                    ApplicationArea = All;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the document type.';
                    Editable = IsEditable;

                    trigger OnValidate()
                    var
                        DocApprovalType: Record "Document Approval Type";
                    begin
                        if DocApprovalType.Get(DocumentTypeDisplayText) then begin
                            Rec.Validate("Document Type", DocApprovalType."ID");
                            DocumentTypeDisplayText := DocApprovalType.Description;
                        end else begin
                            DocApprovalType.SetRange(Description, DocumentTypeDisplayText);
                            if DocApprovalType.FindFirst() then begin
                                Rec.Validate("Document Type", DocApprovalType."ID");
                                DocumentTypeDisplayText := DocApprovalType.Description;
                            end else
                                Error('Document Type "%1" not found.', DocumentTypeDisplayText);
                        end;
                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DocApprovalType: Record "Document Approval Type";
                        DocApprovalTypes: Page "Document Approval Types";
                    begin
                        DocApprovalTypes.LookupMode := true;
                        if DocApprovalTypes.RunModal() = Action::LookupOK then begin
                            DocApprovalTypes.GetRecord(DocApprovalType);
                            Rec.Validate("Document Type", DocApprovalType."ID");
                            DocumentTypeDisplayText := DocApprovalType.Description;
                            CurrPage.Update(true);
                        end;
                        exit(false);
                    end;
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
                field(AttachmentCount; AttachmentCountText)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    ToolTip = 'Shows the number of attachments. Click to manage attachments.';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = AttachmentCount > 0;

                    trigger OnDrillDown()
                    begin
                        OpenAttachments();
                    end;
                }
            }
            part(Lines; "Document Approval Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
                Editable = IsEditable;
            }
            group(ApprovalInfo)
            {
                Caption = 'Approval Information';
                Visible = (Rec.Status = Rec.Status::"Pending Approval") or (Rec.Status = Rec.Status::Approved);

                field("Date-Time Sent for Approval"; Rec."Date-Time Sent for Approval")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the document was sent for approval.';
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
            group(Administration)
            {
                Caption = 'Administration';
                Visible = false;

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
            }
        }
        area(FactBoxes)
        {
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
            group(AttachmentsGroup)
            {
                Caption = 'Attachments';

                action(AttachFile)
                {
                    ApplicationArea = All;
                    Caption = 'Attach File';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Attach files to this document.';

                    trigger OnAction()
                    begin
                        OpenAttachments();
                    end;
                }
            }
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
                        DocApprovalMgmt: Codeunit "Document Approval Management";
                    begin
                        CurrPage.SaveRecord();
                        Rec.Modify(true);
                        Commit();

                        DocApprovalMgmt.SendForApproval(Rec);

                        CurrPage.Close();
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
                        DocApprovalMgmt: Codeunit "Document Approval Management";
                    begin
                        DocApprovalMgmt.CancelApprovalRequest(Rec);
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
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Enabled = CanApprove;
                    ToolTip = 'Approve the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        DocApprovalWorkflow: Codeunit "Document Approval Workflow";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);

                        Rec.Get(Rec."No.");
                        DocApprovalWorkflow.CheckAndUpdateApprovalStatus(Rec);

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
                    ToolTip = 'Reopen the document for editing.';

                    trigger OnAction()
                    var
                        DocApprovalMgmt: Codeunit "Document Approval Management";
                    begin
                        DocApprovalMgmt.ReopenDocument(Rec);
                        CurrPage.Update(false);
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
        DocumentTypeDisplayText: Text[100];
        AttachmentCount: Integer;
        AttachmentCountText: Text;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility();
        SetStatusStyle();
        UpdateDocumentTypeDisplay();
        UpdateAttachmentCount();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlVisibility();
        SetStatusStyle();
        UpdateDocumentTypeDisplay();
        UpdateAttachmentCount();
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetControlVisibility();
        DocumentTypeDisplayText := '';
        AttachmentCount := 0;
        AttachmentCountText := '0 files';
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        IsEditable := Rec.Status in [Rec.Status::Open, Rec.Status::Rejected];

        CanSendForApproval := (Rec.Status = Rec.Status::Open) and
                             DocumentApprovalMgmt.IsDocumentApprovalWorkflowEnabled(Rec) and
                             (Rec."No." <> '');

        CanCancelApproval := Rec.Status = Rec.Status::"Pending Approval";

        if Rec.Status = Rec.Status::"Pending Approval" then begin
            CanApprove := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
            CanReject := CanApprove;
            CanDelegate := CanApprove;
        end else begin
            CanApprove := false;
            CanReject := false;
            CanDelegate := false;
        end;

        CanReopen := Rec.Status in [Rec.Status::Rejected, Rec.Status::Approved];

        ShowApprovalFactBox := Rec.Status in [Rec.Status::"Pending Approval", Rec.Status::Approved];
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

    local procedure UpdateDocumentTypeDisplay()
    var
        DocApprovalType: Record "Document Approval Type";
    begin
        if Rec."Document Type" <> '' then begin
            if DocApprovalType.Get(Rec."Document Type") then
                DocumentTypeDisplayText := DocApprovalType.Description
            else
                DocumentTypeDisplayText := Rec."Document Type";
        end else
            DocumentTypeDisplayText := '';
    end;

    local procedure UpdateAttachmentCount()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        AttachmentCount := 0;
        if Rec."No." <> '' then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", 77100);
            DocumentAttachment.SetRange("No.", Rec."No.");
            AttachmentCount := DocumentAttachment.Count;
        end;

        if AttachmentCount = 1 then
            AttachmentCountText := '1 file attached'
        else
            AttachmentCountText := StrSubstNo('%1 files attached', AttachmentCount);
    end;

    local procedure OpenAttachments()
    var
        DocumentAttachment: Record "Document Attachment";
        DocApprovalAttachments: Page "Doc. Approval Attachments";
    begin
        // Save the record first if it's new
        if Rec."No." = '' then begin
            Rec.Insert(true);
            Commit();
        end else begin
            CurrPage.SaveRecord();
            if Rec.Modify(true) then;
            Commit();
        end;

        // Set document no filter before running
        DocApprovalAttachments.SetDocumentNo(Rec."No.");
        DocApprovalAttachments.RunModal();

        // Refresh attachment count
        UpdateAttachmentCount();
        CurrPage.Update(false);
    end;
}
