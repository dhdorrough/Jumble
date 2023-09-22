program WordWIZ;

uses
  WordWIZMain in 'Src\WordWIZMain.pas' {frmWordWizMain},
  MyUtils in '..\MyUtils\MyUtils.pas',
  Forms;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmWordWizMain, frmWordWizMain);
  Application.Run;
end.
