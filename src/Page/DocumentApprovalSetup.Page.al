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
                Caption = 'Setup Instructions';

                label(WorkflowInstructions)
                {
                    ApplicationArea = All;
                    Caption = 'Follow these steps to set up Document Approval workflow:';
                    Style = Strong;
                }
                label(Step1)
                {
                    ApplicationArea = All;
                    Caption = '1. Configure the Number Series above.';
                }
                label(Step2)
                {
                    ApplicationArea = All;
                    Caption = '2. Click "Register Workflow Responses" to register response combinations.';
                }
                label(Step3)
                {
                    ApplicationArea = All;
                    Caption = '3. Click "Create/Refresh Workflow" to create the workflow template.';
                }
                label(Step4)
                {
                    ApplicationArea = All;
                    Caption = '4. Configure Approval User Setup with appropriate approvers.';
                }
                label(Step5)
                {
                    ApplicationArea = All;
                    Caption = '5. Go to Workflows page and Enable the "DOC-APPROV-WF" workflow.';
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
            action(RegisterWorkflowResponses)
            {
                ApplicationArea = All;
                Caption = '1. Register Workflow Responses';
                Image = Register;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Register the workflow response combinations. Run this FIRST before creating the workflow.';

                trigger OnAction()
                var
                    DocApprovalWorkflow: Codeunit "Document Approval Workflow";
                begin
                    DocApprovalWorkflow.RegisterWorkflowResponseCombinations();
                end;
            }
            action(CleanupWorkflowEvents)
            {
                ApplicationArea = All;
                Caption = 'Cleanup Workflow Events';
                Image = ClearLog;
                ToolTip = 'Clean up orphaned workflow events. Run this if you see "already exists" errors.';

                trigger OnAction()
                var
                    DocApprovalWorkflow: Codeunit "Document Approval Workflow";
                begin
                    DocApprovalWorkflow.CleanupOrphanedWorkflowEvents();
                end;
            }
            action(CreateWorkflow)
            {
                ApplicationArea = All;
                Caption = '2. Create/Refresh Workflow';
                Image = CreateWorkflow;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Create or refresh the Document Approval workflow. Run this AFTER registering responses.';

                trigger OnAction()
                var
                    DocApprovalWorkflow: Codeunit "Document Approval Workflow";
                begin
                    if DocApprovalWorkflow.CreateDocumentApprovalWorkflowTemplate() then
                        Message('Document Approval workflow has been created/refreshed successfully.\n\nNext steps:\n1. Go to Workflows page\n2. Open DOC-APPROV-WF\n3. Enable the workflow');
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
