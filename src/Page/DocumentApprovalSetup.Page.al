/// <summary>
/// Page Document Approval Setup (ID 77103)
/// Setup page for Document Approval configuration.
/// </summary>
page 77103 "Document Approval Setup"
{
    Caption = 'Document Approval Setup';
    PageType = Card;
    SourceTable = "Document Approval Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Document Approval Nos."; Rec."Document Approval Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for Document Approval documents.';
                    ShowMandatory = true;
                }
            }
            group(Instructions)
            {
                Caption = 'Instructions';

                label(WorkflowInstructions)
                {
                    ApplicationArea = All;
                    Caption = 'After configuring the number series, you need to:';
                    Style = Strong;
                }
                label(Step1)
                {
                    ApplicationArea = All;
                    Caption = '1. Go to Workflows and create a new workflow from the "Document Approval Workflow" template.';
                }
                label(Step2)
                {
                    ApplicationArea = All;
                    Caption = '2. Configure the Approval User Setup with appropriate approvers and limits.';
                }
                label(Step3)
                {
                    ApplicationArea = All;
                    Caption = '3. Enable the workflow to start using Document Approvals.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(DocumentApprovalTypes)
            {
                ApplicationArea = All;
                Caption = 'Document Approval Types';
                Image = Category;
                RunObject = page "Document Approval Types";
                ToolTip = 'Configure the document types available for Document Approvals.';
            }
            action(Workflows)
            {
                ApplicationArea = All;
                Caption = 'Workflows';
                Image = Workflow;
                RunObject = page "Workflows";
                ToolTip = 'Open the Workflows page to configure the Document Approval workflow.';
            }
            action(ApprovalUserSetup)
            {
                ApplicationArea = All;
                Caption = 'Approval User Setup';
                Image = UserSetup;
                RunObject = page "Approval User Setup";
                ToolTip = 'Configure the approval users and their limits.';
            }
            action(NumberSeries)
            {
                ApplicationArea = All;
                Caption = 'Number Series';
                Image = NumberSetup;
                RunObject = page "No. Series";
                ToolTip = 'Configure number series for documents.';
            }
        }
        area(Processing)
        {
            action(InitializeSetup)
            {
                ApplicationArea = All;
                Caption = 'Initialize Setup';
                Image = Setup;
                ToolTip = 'Initialize the setup record if it does not exist.';

                trigger OnAction()
                begin
                    if Rec.IsEmpty then begin
                        Rec.Init();
                        Rec.Insert();
                        Message('Setup record has been initialized. Please configure the number series.');
                    end else
                        Message('Setup record already exists.');
                end;
            }
            action(CreateWorkflow)
            {
                ApplicationArea = All;
                Caption = 'Create/Refresh Workflow';
                Image = CreateWorkflow;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create or refresh the Document Approval workflow template and its steps.';

                trigger OnAction()
                var
                    DocApprovalWorkflow: Codeunit "Document Approval Workflow";
                begin
                    if DocApprovalWorkflow.CreateDocumentApprovalWorkflowTemplate() then
                        Message('Document Approval workflow template has been created/refreshed successfully. Please enable it in the Workflows page.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
