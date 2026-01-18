/// <summary>
/// Page Doc. Approval Attachments (ID 77105)
/// Custom attachments page for Document Approval with proper filtering.
/// </summary>
page 77105 "Doc. Approval Attachments"
{
    Caption = 'Document Attachments';
    PageType = List;
    SourceTable = "Document Attachment";
    // Pre-filter to only Document Approval Header records (Table ID 77100)
    SourceTableView = where("Table ID" = const(77100));
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the attached file.';

                    trigger OnDrillDown()
                    begin
                        DownloadFile();
                    end;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the file extension of the attachment.';
                }
                field("File Type"; Rec."File Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the attached file.';
                }
                field("Attached By"; Rec."Attached By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who attached this file.';
                }
                field("Attached Date"; Rec."Attached Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the file was attached.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AttachFile)
            {
                ApplicationArea = All;
                Caption = 'Attach File';
                Image = Attach;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Attach a new file to this document.';

                trigger OnAction()
                begin
                    AttachNewFile();
                end;
            }
            action(Download)
            {
                ApplicationArea = All;
                Caption = 'Download';
                Image = Download;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Download the selected attachment.';

                trigger OnAction()
                begin
                    DownloadFile();
                end;
            }
            action(DeleteFile)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Delete the selected attachment.';

                trigger OnAction()
                begin
                    DeleteAttachment();
                end;
            }
        }
    }

    var
        GlobalDocumentNo: Code[20];

    /// <summary>
    /// Sets the document number and applies the filter.
    /// </summary>
    procedure SetDocumentNo(NewDocumentNo: Code[20])
    begin
        GlobalDocumentNo := NewDocumentNo;
        // Apply filter immediately when document no is set
        if GlobalDocumentNo <> '' then
            Rec.SetRange("No.", GlobalDocumentNo);
    end;

    trigger OnOpenPage()
    begin
        // Ensure filter is applied (in case SetDocumentNo was called before page variables were ready)
        if GlobalDocumentNo <> '' then
            Rec.SetRange("No.", GlobalDocumentNo);
    end;

    local procedure AttachNewFile()
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentApprovalHeader: Record "Document Approval Header";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        if GlobalDocumentNo = '' then begin
            Message('Document number is not set.');
            exit;
        end;

        if not DocumentApprovalHeader.Get(GlobalDocumentNo) then begin
            Message('Document %1 not found.', GlobalDocumentNo);
            exit;
        end;

        // Upload the file
        if not UploadIntoStream('Select a file to attach', '', 'All Files (*.*)|*.*', FileName, InStr) then
            exit;

        if FileName = '' then
            exit;

        // Copy to TempBlob
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        // Get RecRef for the header
        RecRef.GetTable(DocumentApprovalHeader);

        // Use standard BC method to save attachment
        TempBlob.CreateInStream(InStr);
        DocumentAttachment.SaveAttachmentFromStream(InStr, RecRef, FileName);

        // Commit and refresh
        Commit();

        // Re-apply filter and update
        Rec.SetRange("No.", GlobalDocumentNo);
        CurrPage.Update(false);

        Message('File "%1" has been attached.', FileName);
    end;

    local procedure DownloadFile()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
    begin
        if Rec."File Name" = '' then
            exit;

        if not Rec."Document Reference ID".HasValue then begin
            Message('File content not found.');
            exit;
        end;

        FileName := Rec."File Name" + '.' + Rec."File Extension";

        TempBlob.CreateOutStream(OutStr);
        Rec."Document Reference ID".ExportStream(OutStr);

        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, 'Download File', '', 'All Files (*.*)|*.*', FileName);
    end;

    local procedure DeleteAttachment()
    var
        CannotDeleteErr: Label 'You can only delete attachments that you have uploaded. This file was attached by %1.';
        DeleteConfirmQst: Label 'Are you sure you want to delete "%1"?';
        CurrentUserId: Code[50];
    begin
        if Rec."File Name" = '' then
            exit;

        CurrentUserId := CopyStr(UserId, 1, 50);

        // Check permission
        if Rec."Attached By" <> CurrentUserId then
            Error(CannotDeleteErr, Rec."Attached By");

        if not Confirm(DeleteConfirmQst, false, Rec."File Name" + '.' + Rec."File Extension") then
            exit;

        Rec.Delete(true);
        CurrPage.Update(false);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        CannotDeleteErr: Label 'You can only delete attachments that you have uploaded. This file was attached by %1.';
        CurrentUserId: Code[50];
    begin
        CurrentUserId := CopyStr(UserId, 1, 50);

        if Rec."Attached By" <> CurrentUserId then
            Error(CannotDeleteErr, Rec."Attached By");

        exit(true);
    end;
}
