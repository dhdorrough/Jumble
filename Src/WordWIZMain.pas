unit WordWIZMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ExtCtrls, Grids, ovcbase, ovcef, ovcpb, ovcnf,
  Mask, ovcsf;

const
  WORDS_FILENAME = 'Words.txt';
//  MAX_PATH_LEN = 100;
  FIXEDCOUNT = 10;

type
  TCharSet = set of 'a'..'z';
  
  TfrmWordWizMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    PrintSetup1: TMenuItem;
    Print1: TMenuItem;
    N2: TMenuItem;
    SaveAs1: TMenuItem;
    Save1: TMenuItem;
    Open1: TMenuItem;
    New1: TMenuItem;
    Edit1: TMenuItem;
    N4: TMenuItem;
    Paste1: TMenuItem;
    Copy1: TMenuItem;
    Cut1: TMenuItem;
    N5: TMenuItem;
    Undo1: TMenuItem;
    Functions1: TMenuItem;
    lblStatus: TLabel;
    ReCreateWordList1: TMenuItem;
    StringGrid1: TStringGrid;
    ReloadWords1: TMenuItem;
    lblResults: TLabel;
    leAvailableLetters: TOvcSimpleField;
    edt1: TOvcSimpleField;
    edt2: TOvcSimpleField;
    edt3: TOvcSimpleField;
    edt4: TOvcSimpleField;
    edt5: TOvcSimpleField;
    edt6: TOvcSimpleField;
    edt7: TOvcSimpleField;
    btnScanForMatchingWords: TButton;
    ScanforMatchingWords1: TMenuItem;
    BuildPatterns1: TMenuItem;
    ovcNrChars: TOvcNumericField;
    edt8: TOvcSimpleField;
    edt9: TOvcSimpleField;
    EDT10: TOvcSimpleField;
    Label1: TLabel;
    procedure Exit1Click(Sender: TObject);
    procedure ReCreateWordList1Click(Sender: TObject);
    procedure btnScanForMatchingWordsClick(Sender: TObject);
    procedure BuildPatterns1Click(Sender: TObject);
    procedure ovcNrCharsChange(Sender: TObject);
    procedure leAvailableLettersChange(Sender: TObject);
    procedure edt1Change(Sender: TObject);
  private
    { Private declarations }
    fNrRead, fNrWritten: integer;
    fNrWords: integer;
    fPathCount: integer;
    fWordList: TStringList;
    fFixedLetters: array[1..FIXEDCOUNT] of TOvcSimpleField;
    fInhibited: boolean;
    FixedLetters: string[FIXEDCOUNT];
    procedure UpdateStatus(const Msg: string; BackColor: TColor = clBtnFace; FontColor: TColor = clWindowText);
    function PathsPerSecond(TotalElapsed: double): double;
    procedure NrCharsChanged;
    procedure LoadWordList;
    procedure FixedLettersChanged(n: integer);
  public
    { Public declarations }
    function CharSet(const aWord: string; var BadChars: boolean): TCharSet;
    Constructor Create(aOwner: TComponent); override;
  end;

var
  frmWordWizMain: TfrmWordWizMain;


implementation

uses
  MyUtils, Math;

{$R *.dfm}

const
  COL_NR     = 0;
  COL_NAME   = 1;
  MAXBITS    = 10;

var
  gRootPath: string;

  function TfrmWordWizMain.CharSet(const aWord: string; var BadChars: boolean): TCharSet;
  var
    i: integer;
    ch: char;
  begin { CharSet }
    result := [];
    if Length(aWord) > 2 then
      for i := 1 to Length(aWord) do
        begin
          ch := aWord[i];
          BadChars := (ch < 'a') or (ch > 'z');
          if not BadChars then
            begin
              if ch in ['A'..'Z'] then
                ch := chr(ord(ch) - ord('A') + ord('a'));
              result := result + [ch];
            end
          else
            EXIT;
        end
    else
      BadChars := true;
  end;  { CharSet }

constructor TfrmWordWizMain.Create(aOwner: TComponent);
begin
  inherited;
  gRootPath := ExtractFilePath(ParamStr(0));
  LoadWordList;
  ovcNrChars.AsInteger := Length(leAvailableLetters.AsString);
  FixedLettersChanged(ovcNrChars.AsInteger);
  fFixedLetters[1] := edt1;
  fFixedLetters[2] := edt2;
  fFixedLetters[3] := edt3;
  fFixedLetters[4] := edt4;
  fFixedLetters[5] := edt5;
  fFixedLetters[6] := edt6;
  fFixedLetters[7] := edt7;
  fFixedLetters[8] := edt8;
  fFixedLetters[9] := edt9;
  fFixedLetters[FIXEDCOUNT] := edt10;
end;

procedure TfrmWordWizMain.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmWordWizMain.UpdateStatus(const Msg: string; BackColor, FontColor: TColor);
begin
  lblStatus.Caption    := Msg;
  lblStatus.Color      := BackColor;
  lblStatus.Font.Color := FontColor;
  Application.ProcessMessages;
end;



function TfrmWordWizMain.PathsPerSecond(TotalElapsed: double): double;
var
  Hours, Minutes, Seconds, MSec: word;
  TotalSeconds: integer;
begin { TotalSeconds }
  DecodeTime(TotalElapsed, Hours, Minutes, Seconds, MSec);
  TotalSeconds := ((Hours *3600) + (Minutes * 60) + Seconds);

  if TotalSeconds > 0 then
    result := fPathCount / TotalSeconds
  else
    result := 0;
end;  { TotalSeconds }

procedure TfrmWordWizMain.ReCreateWordList1Click(Sender: TObject);
var
  InFile, OutFile: TextFile;
  InfileName, OutFileName: string;
  Line: string;
  aCharSet: TCharSet;
  BadChars: boolean;
begin
  InFileName := WORDS_FILENAME;
  AssignFile(InFile, InFileName);
  Reset(InFile);
  OutfileName := UniqueFileName(InFileName);
  AssignFile(OutFile, OutFileName);
  Rewrite(OutFile);
  fNrRead := 0;
  fNrWritten := 0;
  try
    while not Eof(InFile) do
      begin
        ReadLn(InFile, Line);
        inc(fNrRead);
        aCharSet := CharSet(Line, BadChars);
        if not BadChars then
          begin
            WriteLn(OutFile, Line);
            inc(fNrWritten);
          end;
      end;
  finally
    CloseFile(InFile);
    CloseFile(OutFile);
    UpdateStatus(Format('%d words read, %d words written, %d words skipped',
                        [fNrRead, fNrWritten, fNrRead-fNrWritten]));
  end;
end;

  function BitCount(aWord: word): byte;
  var
    i: integer;
  begin
    result := 0;
    for i := 0 to MAXBITS-1 do
      begin
        if (aWord and 1) = 1 then // bit is set
          inc(result);
        aWord := aWord shr 1;
      end;
  end;

procedure TfrmWordWizMain.btnScanForMatchingWordsClick(Sender: TObject);
const
  COL_NR = 0;
  COL_WORD = 1;
var
  mwn: integer;    // main list word number
  swn: integer;    // sublist word number

  RequiredLetters: TCharSet;
  BadChars: boolean;
  SubList: TStringList;

  Saved_Cursor: TCursor;

  function UsesAll(aWord, Available: string): boolean;
  var
    i: integer;
    ch: char;
    idx: integer;
  begin
    for i := 1 to length(aWord) do
      begin
        ch := aWord[i];
        idx := pos(ch, available);
        if idx > 0 then
          Delete(available, Idx, 1)     // remove from the characters that we must use
        else
          begin
            result := false;
            exit
          end;
      end;
    result := available = '';
  end;

  function MatchesFixed(aWord: string): boolean;
  var
    i: integer;
  begin
    result := true;
    for i := 1 to Length(FixedLetters) do
      if FixedLetters[i] <> ' ' then
        if aWord[i] <> FixedLetters[i] then
          begin
            result := false;
            exit;
          end;
  end;


  function WordMatches(aWord: string; Available: string; WordLen: byte): boolean;
  var
    BadChars: boolean;
    LettersInWord, MissingLetters, UnNeededLetters: TCharSet;
  begin
    result            := false;
    LettersInWord     := CharSet(aWord, BadChars);
    RequiredLetters   := CharSet(Available, BadChars);
    MissingLetters    := RequiredLetters - LettersInWord;
    UnNeededLetters   := LettersInWord - RequiredLetters;
    if (MissingLetters = []) and
       (UnNeededLetters = []) and
       (UsesAll(aWord, Available)) and
       MatchesFixed(aWord) then
      result := true;
  end;

  procedure BuildStringsOfLength(len: integer; SubList: TStringList; BaseWord: string);
  var
    wn: integer;  // word number
    bn: integer;  // bit number
    idxs: integer; // char number source
    idxd: integer; // char number destination
    BitSet: integer;
    Temp: string[FIXEDCOUNT];
    LoopHi: integer;
  begin
    LoopHi := Trunc(Power(2, Length(BaseWord))) - 1;  // all subsets of the original letters
    SetLength(Temp, Len);
    for wn := 1 to LoopHi do
      if BitCount(wn) = Len then
        begin
          idxd := 1; BitSet := wn;
          for bn := 0 to MAXBITS-1 do
            begin
            if (BitSet and 1) = 1 then // this bit is set so we want the corresponding letter from the base chars
              begin
                idxs := Length(BaseWord) - bn;  // working from right to left
                Temp[idxd] := BaseWord[idxs];
                inc(idxd);
              end;
              BitSet := BitSet shr 1;
              if BitSet = 0 then
                Break;
            end;
          SubList.Add(Temp);
        end;
  end;

  function AlreadyInList(aWord: string): boolean;
  var
    r : integer;
  begin
    result := false;
    with StringGrid1 do
      for r := 1 to RowCount do
        if Cells[COL_WORD, r] = aWord then
          begin
            result := true;
            Exit;
          end;
  end;

begin { btnScanForMatchingWordsClick }
  Saved_Cursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    with StringGrid1 do
      begin
        RowCount := 1;
        Cells[COL_NR, 0] := '#';
        Cells[COL_WORD, 0] := 'Word';
      end;

    SubList := TStringList.Create;
    try
      BuildStringsOfLength(ovcNrChars.AsInteger, SubList, leAvailableLetters.Text);

      for mwn := 0 to fWordList.Count-1 do
        begin
          for swn := 0 to SubList.Count-1 do
            if WordMatches(fWordList[mwn], SubList[swn], ovcNrChars.AsInteger) and
               (not AlreadyInList(fWordList[mwn])) then
              with StringGrid1 do
                begin
                  Cells[COL_NR, RowCount]   := IntToStr(RowCount);
                  Cells[COL_WORD, RowCount] := fWordList[mwn];
                  RowCount := RowCount + 1;
                end;
          if (mwn mod 1000) = 0 then
            begin
              lblResults.Caption := Format('%d/%d (%5.2n)', [mwn, fWordList.Count, mwn / fWordList.Count]);
              Application.ProcessMessages;
            end;
        end;
    finally
      lblResults.Caption := Format('Complete. %d words found', [StringGrid1.RowCount-1]);
      SubList.Free;
    end;
  finally
    Screen.Cursor := Saved_Cursor;
  end;
end;  { btnScanForMatchingWordsClick }

procedure TfrmWordWizMain.LoadWordList;
var
  InFile: TextFile;
  InfileName: string;
  Line: string;
begin
  InFileName := WORDS_FILENAME;
  AssignFile(InFile, InFileName);

  fNrWords := 0;
  Reset(InFile);

  try
    while not Eof(InFile) do
      begin
        ReadLn(InFile);
        Inc(fNrWords);
      end;

    fWordList := TStringList.Create;
    fWordList.Capacity := fNrWords;

    fNrWords := 0;
    
    Reset(InFile);
    while not Eof(InFile) do
      begin
        ReadLn(InFile, Line);
        fWordList.Add(Line);
        inc(fNrWords);
      end;
  finally
    CloseFile(InFile);
    lblStatus.Caption := Format('%d words loaded', [fNrWords]);
  end;
end;

procedure TfrmWordWizMain.BuildPatterns1Click(Sender: TObject);

var
  aWord, wn: Word;
  i: byte;
  Count: array[1..MAXBITS] of integer;
  List: array[3..10] of array[1..255] of integer;

begin
  for i := 1 to MAXBITS do
    Count[i] := 0;

  for wn := 1 to 1024 do
    begin
      case BitCount(wn) of
        3: begin Count[3] := Count[3] + 1; List[3][Count[3]] := wn end;
        4: begin Count[4] := Count[4] + 1; List[4][Count[4]] := wn end;
        5: begin Count[5] := Count[5] + 1; List[5][Count[5]] := wn end;
        6: begin Count[6] := Count[6] + 1; List[6][Count[6]] := wn end;
        7: begin Count[7] := Count[7] + 1; List[7][Count[7]] := wn end;
        8: begin Count[8] := Count[8] + 1; List[8][Count[8]] := wn end;
        9: begin Count[9] := Count[9] + 1; List[9][Count[9]] := wn end;
        10:begin Count[10] := Count[10] + 1; List[10][Count[10]] := wn end;
      end;
    end;
end;

procedure TfrmWordWizMain.NrCharsChanged;
var
  i, n: integer;
begin
  n := ovcNrChars.AsInteger;
  edt3.Visible := n >= 3;
  edt4.Visible := n >= 4;
  edt5.Visible := n >= 5;
  edt6.Visible := n >= 6;
  edt7.Visible := n >= 7;
  edt8.Visible := n >= 8;
  edt9.Visible := n >= 9;
  edt10.Visible := n >= 10;
//fInhibited := true;
  try
    FixedLettersChanged(n);
    for i := 1 to 10 do
      fFixedLetters[i].AsString := ' ';
  finally
//  fInhibited := false;
  end;
end;

procedure TfrmWordWizMain.FixedLettersChanged(n: integer);
var
  i: integer;
  ch: char;
begin
  lblStatus.Caption := '';
  lblStatus.Color   := clBtnFace;
  SetLength(FixedLetters, n);
  for i := 1 to n do
    begin
      if not Empty(fFixedLetters[i].AsString) then
        begin
          ch := ToLower(fFixedLetters[i].Text[1]);
          if pos(ch, leAvailableLetters.Text) = 0 then
            begin
              lblStatus.Caption := Format('Letter "%s" is not contained in %s',
                                          [ch, leAvailableLetters.Text]);
              lblStatus.Color   := clYellow;
              Exit;
            end
          else
            FixedLetters[i] := ToLower(ch)
        end
      else
        FixedLetters[i] := ' ';
    end;
end;

procedure TfrmWordWizMain.ovcNrCharsChange(Sender: TObject);
var
  i: integer;
begin
  NrCharsChanged;
end;

procedure TfrmWordWizMain.leAvailableLettersChange(Sender: TObject);
begin
  ovcNrChars.AsInteger := Length(leAvailableLetters.Text);
  NrCharsChanged;
end;

procedure TfrmWordWizMain.edt1Change(Sender: TObject);
begin
//if not fInhibited then
    FixedLettersChanged(ovcNrChars.AsInteger);
end;

end.
