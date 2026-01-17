/// <summary>
/// Page Document Approval Subform (ID 77102)
/// Subform page for entering Document Approval lines.
/// </summary>
page 77102 "Document Approval Subform"
{
    Caption = 'Document Approval Lines';
    PageType = ListPart;
    SourceTable = "Document Approval Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    MultipleNewLines = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("S. No."; Rec."S. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequence number of the line.';
                    Editable = false;
                    Width = 5;
                }
                field("Line Description"; Rec."Line Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the item.';
                    ShowMandatory = true;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount for this line.';
                    ShowMandatory = true;
                    BlankZero = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertLine)
            {
                ApplicationArea = All;
                Caption = 'Insert Line';
                Image = InsertFromCheckJournal;
                ToolTip = 'Insert a new line.';

                trigger OnAction()
                begin
                    Rec.Init();
                    Rec.Insert(true);
                end;
            }
            action(DeleteLine)
            {
                ApplicationArea = All;
                Caption = 'Delete Line';
                Image = Delete;
                ToolTip = 'Delete the selected line.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    if not Rec.IsEmpty then
                        Rec.DeleteAll(true);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        // Auto-assign line number
        Rec."Line No." := GetNextLineNo();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(true);
        exit(true);
    end;

    local procedure GetNextLineNo(): Integer
    var
        DocApprovalLine: Record "Document Approval Line";
    begin
        DocApprovalLine.SetRange("Document No.", Rec."Document No.");
        if DocApprovalLine.FindLast() then
            exit(DocApprovalLine."Line No." + 10000)
        else
            exit(10000);
    end;
}
