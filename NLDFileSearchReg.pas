unit NLDFileSearchReg;

interface
uses
  Classes,
  NLDFileSearch;

  procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDFileSearch, TNLDStringsFileSearch]);
end;

end.
