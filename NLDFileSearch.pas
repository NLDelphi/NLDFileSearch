{
  :$ Author:  Jos Visser, aka GolezTrol /n
  :$ Date:    January 2003 /n
  :$ Web:     http://www.goleztrol.nl/ /n/n
  :$
  :$ For the latest version and feedback, visit the NLDFileSearch forum
  :$ at NLDelphi: /n/n
  :$
  :$ http://www.nldelphi.com/Forum/forumdisplay.php?forumid=73

  :: NLDFileSearch provides various easy ways to wrap around the FindFirst/
  :: FindNext APIs. Three procedures are implemented to easily obtain a list
  :: of files: /n/n
  ::
  :: - NLDEnumFiles /n
  :: Search a folder and report each found file to callback procedure of
  :: class method. /n/n
  ::
  :: - NLDGetFiles /n
  :: Search a folder and add each found file to a TStrings instance. /n/n
  ::
  :: These methods use descendants of the TNLDCustomFileSearch helper class.
  :: This customizable class does the actual searching and triggers an event for
  :: each file that matches the search criteria (Mask and Options)./n/n/n

  (this part is not being auto-documented, it's not really necessary and
  causes a lot of headaches when it comes to formatting the output)

  Changes:    Version and description
  ----------  -------------------------------------------------------------
  2004-03-29  1.2.1: PsychoMark:
              Fixed: inconsistency in SetOnFoundFile while SetOnFoundFileEx
              was missing. Added TNLDFileSearch class publishing OnFileFound(Ex)
              events.

              Converted classes into TComponent. For compatibility the
              constructor has been overloaded to allow ignoring of the AOwner
              parameter. Package and icon has been added for new TNLDFileSearch
              class.

              TNLDStringsFileSearch also descends from TNLDFileSearch now
              to make it useful (and compatible with TNLDFileSearch)
              as a component.

              Added: Delphi Component Help Builder-compatible documentation.
              See: http://www.thewsoft.com/

  2004-03-27  1.2: Goleztrol:
              Finally processed PsychoMarks changes (Thanks again
              multiplento PM)

              Fixed: MatchesFileMask now returns files without extention.

  2003-12-19  Major update by PsychoMark
              Added a lineair approach as default search method alongside
              the existing recursive code, eliminating the possibility of
              stack overflows. (See WalkDirNonRecursive method). The old
              method is still available by defining FSUSERECURSION.

              Added: the Ex callbacks/events which were on the todo list :).
              Added: define to completely eliminate dependency on the Forms unit.

  2003-02-01  1.1.1: GolezTrol: First release
              Changed some of the names.

              Fix: Only folders matching the mask were returned. This is
              now optional.

  2003-01-28  1.0: GolezTrol: Created
}

{
  For every define listed below the general rule is: you are free to define
  them below if you want to use them in every project, but the best way
  is to go to Project -> Properties -> Directories / Conditionals and add
  the name of the define to the "Conditional defines" list...

  Define NOFORMSPLEASE to remove the Forms unit. The consequence is that you
  soProcessMessages option is ignored. Useful for console or mini-apps.
}
{.$DEFINE NOFORMSPLEASE}

{
  Define FSUSERECURSION to use the old-style recursive approach of listing
  files. The disadvantage of this approach compared to the new lineair
  method is that it could produce a Stack Overflow for big nested
  directories. The only difference is in the order in which directories are
  processed; the old method steps through the directories in the order in
  which they are encountered, the new method means all subdirectories of
  a directory are searched for files, and only then does it recurse into
  sub-subdirectories.
}
{.$DEFINE FSUSERECURSION}


{
  Determine if we're going to need FileCtrl to use DirectoryExists amongst
  others. Instead of checking for Delphi 6, we check for Delphi 2-5. The
  advantage to this approach is that future Delphi versions will need no
  adjustment (assuming that they don't move the function back again :)).
  Not a clue on Delphi.NET though...
}
{$IFDEF VER130} {$DEFINE D5ORLOWER} {$ENDIF}
{$IFDEF VER125} {$DEFINE D5ORLOWER} {$ENDIF}
{$IFDEF VER120} {$DEFINE D5ORLOWER} {$ENDIF}
{$IFDEF VER110} {$DEFINE D5ORLOWER} {$ENDIF}
{$IFDEF VER100} {$DEFINE D5ORLOWER} {$ENDIF}
{$IFDEF VER93}  {$DEFINE D5ORLOWER} {$ENDIF}
{$IFDEF VER90}  {$DEFINE D5ORLOWER} {$ENDIF}

unit NLDFileSearch;


interface
uses
  {$IFDEF D5ORLOWER}
  FileCtrl,
  {$ENDIF}
  Classes,
  SysUtils,
  Masks;

type
  {
    :$ Provides various search options.

    :: soRecursive        Search the subdirectories as well. /n
    :: soNoDirs           Return files only. /n
    :: soDirsOnly         Return directories only. /n
    ::                    This flag is ignored if soNoDirs is set. /n
    :: soExcludePath      Return the filename only. /n
    :: soRelativePaths    Return the filename, including the relative /n
    ::                    path, excluding the leading path separator. /n
    ::                    This flag is ignored if soExcludePaths is set. /n
    :: soUseMaskForDirs   Apply the mask to directories as well as files. /n
    :: soProcessMessages  Call Application.ProcessMessages in each iteration. /n
  }
  TFSOption = (soRecursive, soNoDirs, soDirsOnly, soExcludePath,
               soRelativePaths, soUseMaskForDirs, soProcessMessages);

  {
    :$ Provides various search options.

    :: See TFSOption for more a detailed description of each option.
  }
  TFSOptions = set of TFSOption;

  {
    :$ Determines the action to perform next.

    :: This type is used in various events to determine the course of action.
    :: Set it to cCancel to stop further processing, cNextFile to continue as
    :: usual and cEnterFolder to recurse into the current directory.
  }
  TFSContinue = (cCancel, cNextFile, cEnterFolder);

  {
    :$ Callback procedure for found files.

    :: The FileName indicates the current file or directory name. Depending
    :: on the Options set for the corresponding TNLDCustomFileSearch object
    :: it may or may not include the (relative or absolute) path name.
  }
  TNLDFoundFileProc     = procedure(const FileName: string;
                                    Attributes: Integer; var Continue: TFSContinue);

  {
    :$ Extended callback procedure for found files.

    :: Passes the complete TSearchRec structure to the callback procedure.
    :: For more information, see TNLDFoundFileProc.
  }
  TNLDFoundFileExProc   = procedure(const FileName: String;
                                    const SearchRec: TSearchRec;
                                    var Continue: TFSContinue);

  {
    :$ Event for found files.

    :: The FileName indicates the current file or directory name. Depending
    :: on the Options set for the corresponding TNLDCustomFileSearch object
    :: it may or may not include the (relative or absolute) path name.
  }
  TNLDFoundFileEvent    = procedure(const FileName: string;
                                    Attributes: Integer;
                                    var Continue: TFSContinue) of object;

  {
    :$ Extended event for found files.

    :: Passes the complete TSearchRec structure to the event.
    :: For more information, see TNLDFoundFileEvent.
  }
  TNLDFoundFileExEvent  = procedure(const FileName: String;
                                    const SearchRec: TSearchRec;
                                    var Continue: TFSContinue) of object;


  {
    :$ Base class for file searches.

    :: When a file is found in the EnumFiles method the OnFoundFile event is
    :: raised. Descendants can override DoFoundFile to respond to found files.
  }
  TNLDCustomFileSearch  = class(TComponent)
  private
    FOnFoundFile:     TNLDFoundFileEvent;
    FOnFoundFileEx:   TNLDFoundFileExEvent;
    FTerminated:      Boolean;
    FMask:            TMask;
  protected
    procedure InitializeMask(const Mask: string);
    procedure FinalizeMask();
    function MatchesFileMask(Filename: string; IsDir: Boolean): Boolean;

    function GetTerminated(): Boolean;
    procedure DoFoundFile(FileName: string; SR: TSearchRec;
                          var DoContinue: TFSContinue); virtual;

    procedure SetOnFoundFile(const Value: TNLDFoundFileEvent); virtual;
    procedure SetOnFoundFileEx(const Value: TNLDFoundFileExEvent); virtual;

    procedure EnumFiles(Path: string; Options: TFSOptions);

    //:$ Raised when a file or directory is found.
    property OnFoundFile:     TNLDFoundFileEvent    read FOnFoundFile
                                                    write SetOnFoundFile;

    //:$ Raised when a file or directory is found.
    property OnFoundFileEx:   TNLDFoundFileExEvent  read FOnFoundFileEx
                                                    write SetOnFoundFileEx;
  public
    //:$ Creates a new TNLDCustomFileSearch instance
    constructor Create(AOwner: TComponent); overload; override;

    //:$ Creates a new TNLDCustomFileSearch instance without an owner set
    constructor Create(); reintroduce; overload;

    //:$ Disposes of an object instance.
    //:: Do not call Destroy directly. Call Free instead. Free verifies that
    //:: the object reference is not nil before calling Destroy.
    destructor Destroy(); override;

    //:$ Termines an active search.
    //:: Calling Terminate while in an EnumFiles loop will break out of the
    //:: loop, ignoring any remaining files. Calling Terminate in any other
    //:: condition does not have any effect.
    procedure Terminate(); virtual;
  end;

  {
    :$ Non-visual component for performing file searches.
  }
  TNLDFileSearch  = class(TNLDCustomFileSearch)
  private
    FMask:            String;
    FOptions:         TFSOptions;
    FPath:            String;
  protected
    procedure SetPath(const Value: String); virtual;
  public
    //:$ Starts the enumeration of files.
    //:: For each file found, the OnFileFound and OnFileFoundEx events will
    //:: be raised. You may call Terminate to cancel the search.
    procedure Search(); virtual;
  published
    //:$ Determines the mask to use when searching for files.
    //:: The mask may contain wildchars (* and ?, DOS style).
    property Mask:      String      read FMask    write FMask;

    //:$ Specifies the options.
    //:: For more information, see TFSOption
    property Options:   TFSOptions  read FOptions write FOptions;

    //:$ Specifies the path to search.
    //:: Note that unlike the usual approach, this path should NOT include
    //:: the mask, it should be set seperately using the Mask property.
    //:: This decision was made to compensate for easier design-time
    //:: configuration.
    property Path:      String      read FPath    write SetPath;

    property OnFoundFile;
    property OnFoundFileEx;
  end;

  {
    :$ Allows file searches using a callback procedure.

    :: Instead of events you may provide a callback procedure unrelated to
    :: an object.
  }
  TNLDEnumFiles = class(TNLDCustomFileSearch)
  private
    FFoundFileProc:   TNLDFoundFileProc;
    FFoundFileExProc: TNLDFoundFileExProc;
  protected
    procedure DoFoundFile(FileName: string; SR: TSearchRec;
                          var DoContinue: TFSContinue); override;
  public
    //:$ Specifies the callback procedure to call when a file is found
    property FoundFileProc:   TNLDFoundFileProc         read FFoundFileProc
                                                        write FFoundFileProc;

    //:$ Specifies the extended callback procedure to call when a file is found
    property FoundFileProcEx: TNLDFoundFileExProc       read FFoundFileExProc
                                                        write FFoundFileExProc;
  published
    property OnFoundFile;
    property OnFoundFileEx;
  end;

  {
    :$ Fills a TStrings descendant with the files found.
  }
  TNLDStringsFileSearch = class(TNLDFileSearch)
  private
    FStrings:   TStrings;
  protected
    procedure DoFoundFile(FileName: string; SR: TSearchRec;
                          var DoContinue: TFSContinue); override;
  public
    //:$ Specifies the TStrings descendant to write the file names to.
    property Strings:   TStrings read FStrings write FStrings;
  end;

  {
    :$ Search a folder using a callback procedure

    :: Specify the path (including trailing backslash) + optional mask in the
    :: Path parameter. The specified Callback procedure will be called for each
    :: encountered file.
  }
  procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileProc;
                         Options: TFSOptions); overload;

  {
    :$ Search a folder using an extended callback procedure

    :: Specify the path (including trailing backslash) + optional mask in the
    :: Path parameter. The specified Callback procedure will be called for each
    :: encountered file.
  }
  procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileExProc;
                         Options: TFSOptions); overload;


  {
    :$ Search a folder using a method event

    :: Specify the path (including trailing backslash) + optional mask in the
    :: Path parameter. The specified Callback event will be called for each
    :: encountered file.
  }
  procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileEvent;
                         Options: TFSOptions); overload;

  {
    :$ Search a folder using an extended method event

    :: Specify the path (including trailing backslash) + optional mask in the
    :: Path parameter. The specified Callback event will be called for each
    :: encountered file.
  }
  procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileExEvent;
                         Options: TFSOptions); overload;

  {
    :$ Search a folder and write all files to the specified list

    :: Specify the path (including trailing backslash) + optional mask in the
    :: Path parameter. The specified TStrings descendant will be filled
    :: with the found files.
  }
  procedure NLDGetFiles(Path: string; List: TStrings; Options: TFSOptions);


implementation
{$IFNDEF NOFORMSPLEASE}
uses
  Forms;
{$ENDIF}


{========================================
  Wrapper functions
========================================}
procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileProc;
                       Options: TFSOptions);
begin
  with TNLDEnumFiles.Create do
  try
    FoundFileProc := CallBack;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileEvent;
                       Options: TFSOptions);
begin
  with TNLDEnumFiles.Create do
  try
    OnFoundFile := CallBack;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileExProc;
                       Options: TFSOptions);
begin
  with TNLDEnumFiles.Create do
  try
    FoundFileProcEx := CallBack;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

procedure NLDEnumFiles(Path: string; CallBack: TNLDFoundFileExEvent;
                       Options: TFSOptions);
begin
  with TNLDEnumFiles.Create do
  try
    OnFoundFileEx := CallBack;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

procedure NLDGetFiles(Path: string; List: TStrings;
                      Options: TFSOptions);
begin
  List.Clear;
  with TNLDStringsFileSearch.Create do
  try
    Strings := List;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;


{========================================
  TNLDCustomFileSearch
========================================}
constructor TNLDCustomFileSearch.Create(AOwner: TComponent);
begin
  // Placeholder for virtual method...
  inherited;
end;

constructor TNLDCustomFileSearch.Create();
begin
  Create(nil);
end;

destructor TNLDCustomFileSearch.Destroy();
begin
  FinalizeMask;
  inherited;
end;


procedure TNLDCustomFileSearch.DoFoundFile(FileName: string; SR: TSearchRec;
                                           var DoContinue: TFSContinue);
begin
  if Assigned(OnFoundFile) then
    OnFoundFile(FileName, SR.Attr, DoContinue);

  if Assigned(OnFoundFileEx) then
    OnFoundFileEx(FileName, SR, DoContinue);
end;


procedure TNLDCustomFileSearch.EnumFiles(Path: string; Options: TFSOptions);
{ Extracts a mask from the given path and searches the path for files matching
  the mask. Triggers the OnFoundFile event for each file. }
var
  Mask: string;
  DoContinue: TFSContinue;

  {$IFDEF FSUSERECURSION}
  procedure WalkDir(Dir: string);
  { Reads files from a given path. Dir is the relative path from Path.
    Calls the OnFoundFile events when a file is found, matching the options. }
  var
    SR: TSearchRec;
    Res: Integer;
    IsDir: Boolean;
    FileName: string;
  begin
    Res := FindFirst(Path + Dir + '*.*', faAnyFile, SR);
    try
      while (Res = 0) and not GetTerminated do
      begin
        try
          if (SR.Name = '.') or (SR.Name = '..') then
            Continue;
          IsDir := SR.Attr and faDirectory <> 0;
          if IsDir then
          begin
            if soUseMaskForDirs in Options then
              if not MatchesFileMask(SR.Name, True) then
                Continue;
            DoContinue := cEnterFolder
          end else
          begin
            if not MatchesFileMask(SR.Name, False) then
              Continue;
            DoContinue := cNextFile;
          end;

          FileName := SR.Name;
          if not (soExcludePath in Options) then
          begin
            FileName := Dir + FileName;
            if not (soRelativePaths in Options) then
              FileName := Path + FileName;
          end;

          {$IFNDEF NOFORMSPLEASE}
          if soProcessMessages in Options then
            Application.ProcessMessages;
          {$ENDIF}

          // If it is not a folder, or folders are allowed then
          if not IsDir or not (soNoDirs in Options) then
            // If it is a folder or other files are allowed then
            if IsDir or not (soDirsOnly in Options) then
              // FoundFile!
              DoFoundFile(FileName, SR, DoContinue);

          if DoContinue = cCancel then
          begin
            Terminate;
            Break;
          end;

          if IsDir and (soRecursive in Options) and
              (DoContinue = cEnterFolder) then
            WalkDir(Dir + SR.Name + '\');
        finally
          Res := FindNext(SR);
        end;
      end;
    finally
      FindClose(SR);
    end;
  end;
  {$ENDIF}

  {$IFNDEF FSUSERECURSION}
  procedure WalkDirNonRecursive();
  { The non-recursive approach works simple: keep a list of found directories
    and process each one in the order in which they were found. This means
    events for subdirectories will be raised after the full path has been
    processed. If you don't want the non-recursive method for some reason,
    simply define FSUSERECURSION }
  var
    slDirs:         TStringList;
    sPath:          string;
    srResult:       TSearchRec;
    bDir:           Boolean;
    sFilename:      string;

  begin
    slDirs  := TStringList.Create();
    try
      slDirs.Add('');

      while slDirs.Count > 0 do
      begin
        sPath := slDirs[0];
        slDirs.Delete(0);

        // Get all files
        if FindFirst(Path + sPath + '*.*', faAnyFile, srResult) = 0 then
        try
          repeat
            if (srResult.Name = '.') or (srResult.Name = '..') then
              Continue;

            bDir := (srResult.Attr and faDirectory) = faDirectory;
            if bDir then
            begin
              if soUseMaskForDirs in Options then
                if not MatchesFileMask(srResult.Name, True) then
                  Continue;

              DoContinue := cEnterFolder
            end else
            begin
              if not MatchesFileMask(srResult.Name, False) then
                Continue;

              DoContinue := cNextFile;
            end;

            sFilename := srResult.Name;

            if not (soExcludePath in Options) then
            begin
              sFileName := sPath + sFileName;

              if not (soRelativePaths in Options) then
                sFileName := Path + sFileName;
            end;

            {$IFNDEF NOFORMSPLEASE}
            if soProcessMessages in Options then
              Application.ProcessMessages;
            {$ENDIF}

            // If it is not a folder, or folders are allowed then
            if (not bDir) or (not (soNoDirs in Options)) then
              // If it is a folder or other files are allowed then
              if (bDir) or (not (soDirsOnly in Options)) then
                // FoundFile!
                DoFoundFile(sFilename, srResult, DoContinue);

            if DoContinue = cCancel then begin
              Terminate();
              break;
            end;

            if (bDir) and (soRecursive in Options) and
               (DoContinue = cEnterFolder) then
              slDirs.Add(sPath + srResult.Name + '\');
          until (GetTerminated()) or (FindNext(srResult) <> 0);
        finally
          FindClose(srResult);
        end;
      end;
    finally
      FreeAndNil(slDirs);
    end;
  end;
  {$ENDIF}

begin
  if soDirsOnly in Options then
    Include(Options, soUseMaskForDirs);
  Mask := ExtractFileName(Path);
  if Mask = '' then
    Mask := '*.*';
  Path := ExtractFilePath(Path);
  FTerminated := False;

  InitializeMask(Mask);
  {$IFDEF FSUSERECURSION}
    WalkDir('')
  {$ELSE}
    WalkDirNonRecursive();
  {$ENDIF}
  FinalizeMask;
end;

procedure TNLDCustomFileSearch.FinalizeMask();
begin
  FreeAndNil(FMask);
end;

function TNLDCustomFileSearch.GetTerminated(): Boolean;
begin
  Result := FTerminated{$IFNDEF NOFORMSPLEASE} or Application.Terminated{$ENDIF};
end;

procedure TNLDCustomFileSearch.InitializeMask(const Mask: string);
begin
  FinalizeMask;
  FMask := TMask.Create(Mask);
end;

function TNLDCustomFileSearch.MatchesFileMask(Filename: string; IsDir: Boolean): Boolean;
var
  Ext: string;
begin
  // Do some processing to allow files without extention to be found in
  // the *.* mask. Directories don't have extentions, even if the name contains
  // a period.
  if not IsDir then
  begin
    Ext := ExtractFileExt(Filename);
    if (Ext = '') or (Pos(' ', Ext) > 0) then
      FileName := FileName + '.';
  end else
    FileName := FileName + '.';
  Result := FMask.Matches(Filename);
end;


procedure TNLDCustomFileSearch.SetOnFoundFile(const Value: TNLDFoundFileEvent);
begin
  FOnFoundFile    := Value;
end;

procedure TNLDCustomFileSearch.SetOnFoundFileEx(const Value: TNLDFoundFileExEvent);
begin
  FOnFoundFileEx  := Value;
end;


procedure TNLDCustomFileSearch.Terminate();
begin
  FTerminated     := True;
end;


{========================================
  TNLDEnumFiles
========================================}
procedure TNLDEnumFiles.DoFoundFile(FileName: string; SR: TSearchRec;
                                    var DoContinue: TFSContinue);
begin
  inherited;

  if Assigned(FFoundFileProc) then
    FFoundFileProc(FileName, SR.Attr, DoContinue);

  if Assigned(FFoundFileExProc) then
    FFoundFileExProc(FileName, SR, DoContinue);
end;


{========================================
  TNLDFileSearch
========================================}
procedure TNLDFileSearch.Search();
begin
  if not DirectoryExists(FPath) then
    raise EFOpenError.Create('The specified Path does not exist!');

  EnumFiles(FPath + FMask, FOptions);
end;


procedure TNLDFileSearch.SetPath(const Value: String);
begin
  {$IFDEF D5ORLOWER}
  FPath := IncludeTrailingBackslash(Value);
  {$ELSE}
  FPath := IncludeTrailingPathDelimiter(Value);
  {$ENDIF}
end;


{========================================
  TNLDStringsFileSearch
========================================}
procedure TNLDStringsFileSearch.DoFoundFile(FileName: string; SR: TSearchRec;
                                            var DoContinue: TFSContinue);
begin
  inherited;

  if Assigned(FStrings) then
    FStrings.Add(FileName);
end;

end.

