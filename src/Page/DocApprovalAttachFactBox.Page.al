/// <summary>
/// Page Doc. Approval Attach. FactBox (ID 77106)
/// Custom attachment factbox for Document Approval with attach capability.
/// </summary>
page 77106 "Doc. Approval Attach. FactBox"
{
    Caption = 'Attachments';
    PageType = CardPart;

    layout
    {
        area(Content)
        {
            group(Attachments)
            {
                ShowCaption = false;

                field(DocumentCount; StrSubstNo('%1 file(s) attached', AttachmentCount))
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    ToolTip = 'Shows the number of files attached to this document. Click to view all attachments.';
                    Editable = false;
                    Style = Strong;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        OpenAttachments();
                    end;
                }
            }
            group(FileList)
            {
                ShowCaption = false;
                Visible = AttachmentCount > 0;

                field(File1; FileName1)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Visible = FileName1 <> '';

                    trigger OnDrillDown()
                    begin
                        DownloadFile(1);
                    end;
                }
                field(File2; FileName2)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Visible = FileName2 <> '';

                    trigger OnDrillDown()
                    begin
                        DownloadFile(2);
                    end;
                }
                field(File3; FileName3)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Visible = FileName3 <> '';

                    trigger OnDrillDown()
                    begin
                        DownloadFile(3);
                    end;
                }
                field(MoreFiles; MoreFilesText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Visible = AttachmentCount > 3;
                    Style = Subordinate;

                    trigger OnDrillDown()
                    begin
                        OpenAttachments();
                    end;
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
                Caption = 'Attach';
                Image = Attach;
                ToolTip = 'Attach a file to this document.';

                trigger OnAction()
                begin
                    AttachNewFile();
                end;
            }
            action(ViewAll)
            {
                ApplicationArea = All;
                Caption = 'View All';
                Image = Documents;
                ToolTip = 'View all attached documents.';

                trigger OnAction()
                begin
                    OpenAttachments();
                end;
            }
        }
    }

    var
        GlobalDocumentNo: Code[20];
        AttachmentCount: Integer;
        FileName1: Text[100];
        FileName2: Text[100];
        FileName3: Text[100];
        MoreFilesText: Text;
        FileId1: Integer;
        FileId2: Integer;
        FileId3: Integer;

    /// <summary>
    /// Sets the document number and refreshes the attachment list.
    /// </summary>
    procedure SetDocumentNo(NewDocumentNo: Code[20])
    begin
        GlobalDocumentNo := NewDocumentNo;
        RefreshAttachments();
    end;

    local procedure RefreshAttachments()
    var
        DocumentAttachment: Record "Document Attachment";
        Counter: Integer;
    begin
        // Reset
        AttachmentCount := 0;
        FileName1 := '';
        FileName2 := '';
        FileName3 := '';
        MoreFilesText := '';
        FileId1 := 0;
        FileId2 := 0;
        FileId3 := 0;

        if GlobalDocumentNo = '' then
            exit;

        // Count and get attachments
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Document Approval Header");
        DocumentAttachment.SetRange("No.", GlobalDocumentNo);
        AttachmentCount := DocumentAttachment.Count;

        if AttachmentCount = 0 then
            exit;

        // Get first 3 file names
        Counter := 0;
        if DocumentAttachment.FindSet() then
            repeat
                Counter += 1;
                case Counter of
                    1:
                        begin
                            FileName1 := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
                            FileId1 := DocumentAttachment.ID;
                        end;
                    2:
                        begin
                            FileName2 := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
                            FileId2 := DocumentAttachment.ID;
                        end;
                    3:
                        begin
                            FileName3 := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
                            FileId3 := DocumentAttachment.ID;
                        end;
                end;
            until (DocumentAttachment.Next() = 0) or (Counter >= 3);

        if AttachmentCount > 3 then
            MoreFilesText := StrSubstNo('... and %1 more', AttachmentCount - 3);
    end;

    local procedure AttachNewFile()
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentApprovalHeader: Record "Document Approval Header";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        RecRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        if GlobalDocumentNo = '' then begin
            Message('Please save the document before attaching files.');
            exit;
        end;

        // Get the header record
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

        // Refresh the display
        RefreshAttachments();

        Message('File "%1" has been attached.', FileName);
    end;

    local procedure DownloadFile(FileIndex: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        FileId: Integer;
    begin
        case FileIndex of
            1:
                FileId := FileId1;
            2:
                FileId := FileId2;
            3:
                FileId := FileId3;
        end;

        if FileId = 0 then
            exit;

        if not DocumentAttachment.Get(FileId) then
            exit;

        if not DocumentAttachment."Document Reference ID".HasValue then
            exit;

        FileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";

        TempBlob.CreateOutStream(OutStr);
        DocumentAttachment."Document Reference ID".ExportStream(OutStr);

        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, 'Download File', '', 'All Files (*.*)|*.*', FileName);
    end;

    local procedure OpenAttachments()
    var
        DocumentAttachmentDetails: Page "Document Attachment Details";
        DocumentApprovalHeader: Record "Document Approval Header";
        RecRef: RecordRef;
    begin
        if GlobalDocumentNo = '' then
            exit;

        if not DocumentApprovalHeader.Get(GlobalDocumentNo) then
            exit;

        RecRef.GetTable(DocumentApprovalHeader);
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();

        // Refresh after closing
        RefreshAttachments();
    end;
}
