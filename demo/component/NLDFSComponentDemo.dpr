program NLDFSComponentDemo;

uses
  madExcept,
  madLinkDisAsm,
  Forms,
  FMain in 'Forms\FMain.pas' {frmMain};

{$R *.res}

var
  frmMain:    TfrmMain;

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
