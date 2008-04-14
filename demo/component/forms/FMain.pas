unit FMain;

interface
uses
  Windows,
  Forms,
  Classes,
  Controls,
  StdCtrls,
  NLDFileSearch;

type
  TfrmMain = class(TForm)
    cmdNormal:              TButton;
    cmdProcessMessages:     TButton;
    cmdUpdate:              TButton;
    fsSearch:               TNLDStringsFileSearch;
    lstFiles:               TListBox;
    lblMask:                TLabel;
    txtMask:                TEdit;
    chkRecursive:           TCheckBox;
    chkRelative:            TCheckBox;
    cmdCancel:              TButton;
    chkIgnoreDirs:          TCheckBox;

    procedure cmdNormalClick(Sender: TObject);
    procedure cmdProcessMessagesClick(Sender: TObject);
    procedure cmdUpdateClick(Sender: TObject);
    procedure cmdCancelClick(Sender: TObject);
  private
    procedure SetupFileSearch();
  end;

implementation

{$R *.dfm}

procedure TfrmMain.SetupFileSearch;
var
  cPath:      array[0..255] of Char;
  pOptions:   TFSOptions;

begin
  lstFiles.Items.Clear();

  // Use Windows directory
  FillChar(cPath, SizeOf(cPath), #0);
  GetWindowsDirectory(@cPath, SizeOf(cPath));

  fsSearch.Path := String(cPath);
  fsSearch.Mask := txtMask.Text;

  // Set options
  pOptions      := fsSearch.Options;

  if chkRecursive.Checked then
    Include(pOptions, soRecursive)
  else
    Exclude(pOptions, soRecursive);

  if chkRelative.Checked then
    Include(pOptions, soRelativePaths)
  else
    Exclude(pOptions, soRelativePaths);

  if chkIgnoreDirs.Checked then
    Include(pOptions, soNoDirs)
  else
    Exclude(pOptions, soNoDirs);

  fsSearch.Options  := pOptions;

  // Set destination
  fsSearch.Strings  := lstFiles.Items;
end;


procedure TfrmMain.cmdNormalClick;
begin
  Screen.Cursor := crHourglass;
  try
    SetupFileSearch();

    fsSearch.Options  := fsSearch.Options - [soProcessMessages];
    fsSearch.Search();
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.cmdProcessMessagesClick;
begin
  cmdCancel.Enabled := True;
  Screen.Cursor     := crHourglass;
  try
    SetupFileSearch();

    fsSearch.Options  := fsSearch.Options + [soProcessMessages];
    fsSearch.Search();
  finally
    Screen.Cursor     := crDefault;
    cmdCancel.Enabled := False;
  end;
end;

procedure TfrmMain.cmdUpdateClick;
begin
  Screen.Cursor := crHourglass;
  try
    lstFiles.Items.BeginUpdate();
    try
      SetupFileSearch();

      fsSearch.Options  := fsSearch.Options - [soProcessMessages];
      fsSearch.Search();
    finally
      lstFiles.Items.EndUpdate();
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.cmdCancelClick;
begin
  fsSearch.Terminate();
end;

end.
