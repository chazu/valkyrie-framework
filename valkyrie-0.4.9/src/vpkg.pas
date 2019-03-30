{$INCLUDE valkyrie.inc}
unit vpkg;
interface

uses
  vnode, Classes, SysUtils, zstream, vdf, vds, idea
  { add your units here };
  
type TVDataWriter = procedure (aFileName : AnsiString; FileType : DWord; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '') of Object;
type TVDWriterRec = record id : Byte; Writer : TVDataWriter; end;
     TVDWriters   = specialize TAssocArray<TVDWriterRec>;

type

{ TVDataCreator }

TVDataCreator = class(TVObject)
  Name     : AnsiString;
  Stream   : TFileStream;
  Header   : TVDFHeader;
  Data     : TVDCHArray;
  ASize    : DWord;
  EKey     : TIDEAKey;
  FileMark : ShortString;
  Writers  : TVDWriters;
  constructor Create(aFileName : AnsiString);
  procedure RegisterWriter(sID : AnsiString; id : DWord; Writer : TVDataWriter);
  procedure ExecuteScript(ScriptName : AnsiString; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
  procedure  AddLuaFile(aFileName : AnsiString; FileType : DWord; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
  procedure  AddTextFile(aFileName : AnsiString; FileType : DWord; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
  procedure  AddFile(aFileName : AnsiString; FileType : DWord; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
  procedure  AddDir(aDirName : AnsiString; FileType : DWord; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
  procedure  Add(aDir, aMask : AnsiString; Writer : TVDataWriter; FileType : DWord; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
  destructor Destroy; override;
  private
  function FileSize(FileName : AnsiString) : DWord;
  procedure  Flush;
  function FileToStream(FileHead : TVDFClumpHeader) : DWord;
  function TrueFileName(FileName : AnsiString) : AnsiString;
end;

implementation

uses vutil, strutils;

{ TVDataCreator }

constructor TVDataCreator.Create(aFileName: AnsiString);
begin
  Header.Signature := VDF_SIGNATURE;
  Header.Version   := 0;
  Header.Files     := 0;
  Stream           := nil;
  Name             := aFileName;
  ASize            := 256;
  FileMark         := '__compiled';
  Writers := TVDWriters.Create(False);
  SetLength(Data,ASize);
end;

procedure TVDataCreator.RegisterWriter(sID: AnsiString; id: DWord; Writer: TVDataWriter);
var WriterRec : TVDWriterRec;
begin
  WriterRec.id     := id;
  WriterRec.writer := Writer;
  Writers[sID] := WriterRec;
end;

procedure TVDataCreator.ExecuteScript(ScriptName: AnsiString; aFlags : TVDFClumpFlags = []; PackageName : AnsiString = '');
var TF        : Text;
    Command   : AnsiString;
    FileName  : AnsiString;
    WriterRec : TVDWriterRec;
begin
  Assign(TF,ScriptName);
  Reset(TF);
  while not EOF(TF) do
  begin
    Readln(TF,Command);
    Command := Trim(Command);
    FileName := ExtractDelimited(2,Command,[' ']);
    Command  := Copy2Symb(Command,' ');
    if not Writers.Exists(Command) then CritError('Writer "'+Command+'" undefined in script "'+ScriptName+'"!');
    WriterRec := Writers[Command];
    WriterRec.Writer(FileName,WriterRec.id,aFlags,PackageName);
  end;
  Close(TF);
end;

function TVDataCreator.FileSize(FileName : AnsiString) : DWord;
var TF : File of byte;
begin
  Assign(TF,FileName);
  Reset(TF);
  FileSize := System.FileSize(TF);
  Close(TF);
end;

procedure TVDataCreator.AddLuaFile(aFileName: AnsiString; FileType : DWord;
  aFlags: TVDFClumpFlags; PackageName: AnsiString);
var LuacExe    : string;
    Compiled   : string;
begin
  Log('Lua - Compiling '+aFileName+'...');
  LuacExe := FileSearch(
    {$ifdef WIN32} 'luac.exe' {$endif}
    {$ifdef UNIX} 'luac' {$endif}
    , GetEnvironmentVariable('PATH'));

  {$ifdef WIN32} if FileExists('luac.exe') then LuacExe := 'luac.exe'; {$endif}


  if LuacExe = '' then
    raise Exception.Create('luac executable not found on $PATH');

  Compiled := ExtractFileName(aFileName)+FileMark;
  Log('Lua - Compiling '+aFileName+'...');
  ExecuteProcess(LuacExe,' -o '+Compiled+' '+aFileName);
  
  AddFile(Compiled,FileType,aFlags,PackageName);
  Log('Lua - Compiled.');
end;

procedure TVDataCreator.AddTextFile(aFileName: AnsiString; FileType : DWord;
  aFlags: TVDFClumpFlags; PackageName: AnsiString);
var StringList : TStringArray;
    StringFile : TFileStream;
    Compiled   : string;
begin
  if not FileExists(aFileName) then raise EFOpenError.Create('File "'+aFileName+'" not found!');
  Log('Adding "'+aFileName+'"...');

  Compiled   := ExtractFileName(aFileName)+FileMark;
  StringList := TStringArray.Create;
  StringList.Read(aFileName);
  StringFile := TFileStream.Create(Compiled,fmCreate);
  StringList.WriteToStream(StringFile);
  FreeAndNil(StringFile);
  FreeAndNil(StringList);

  AddFile(Compiled,FileType,aFlags,PackageName);
end;

procedure TVDataCreator.AddFile(aFileName: AnsiString; FileType : DWord; aFlags: TVDFClumpFlags; PackageName : AnsiString = '');
begin
  if not FileExists(aFileName) then raise EFOpenError.Create('File "'+aFileName+'" not found!');
  Log('Adding "'+aFileName+'"...');

  if Header.Files+2 >= ASize then
  begin
    ASize := 2*ASize;
    SetLength(Data,ASize);
  end;
  
  with Data[Header.Files] do
  begin
    Name  := aFileName;
    Dir   := PackageName;
    Size  := FileSize(aFileName);
    Pos   := 0;
    FType := FileType;
    Flags := aFlags;
  end;
  

  Inc(Header.Files);
end;

procedure TVDataCreator.AddDir(aDirName: AnsiString; FileType : DWord; aFlags: TVDFClumpFlags; PackageName : AnsiString = '');
var SearchRec : TSearchRec;
begin
  Log('Adding directory "'+aDirName+'"...');
  if FindFirst(aDirName + PathDelim + '*',faAnyFile,SearchRec) = 0 then
  repeat
    if SearchRec.Name[1] = '.' then Continue;
    AddFile(aDirName + PathDelim + SearchRec.Name, FileType, aFlags, PackageName)
  until (FindNext(SearchRec) <> 0);
  FindClose(SearchRec);
end;

procedure TVDataCreator.Add(aDir,aMask: AnsiString; Writer: TVDataWriter; FileType: DWord; aFlags: TVDFClumpFlags;
  PackageName: AnsiString);
var SearchRec : TSearchRec;
begin
  if aDir <> '' then aDir += PathDelim;
  Log('Adding "'+ aDir + aMask+'"...');
  if FindFirst(aDir + aMask,faAnyFile,SearchRec) = 0 then
  repeat
    if SearchRec.Name[1] = '.' then Continue;
    Writer(aDir + SearchRec.Name, FileType, aFlags, PackageName );
  until (FindNext(SearchRec) <> 0);
  FindClose(SearchRec);
end;

procedure TVDataCreator.Flush;
var Count : DWord;
    CPos  : DWord;
const HEAD = SizeOf(TVDFHeader);
      CLPH = SizeOf(TVDFClumpHeader);
begin
  CPos := HEAD;
  CPos += Header.Files*CLPH;

  Stream := TFileStream.Create(Name,fmCreate);
  Stream.Write(Header,HEAD);
  Log('Header written - position = '+IntToStr(Stream.Position)+' = '+IntToStr(HEAD));
  for Count := 0 to Header.Files - 1 do
    Stream.Write(Data[Count],CLPH);
  Log('Chunk headers written - position = '+IntToStr(Stream.Position)+' = '+IntToStr(CPos));
  for Count := 0 to Header.Files - 1 do
  begin
    Log('Writing '+Data[Count].Name+' - position = '+IntToStr(Stream.Position)+' = '+IntToStr(CPos));
    Data[Count].Pos := CPos;
    CPos += FileToStream(Data[Count]);
    Data[Count].Name := ExtractFileName(TrueFileName(Data[Count].Name));
    Log('Written '+Data[Count].Name+' - position = '+IntToStr(Stream.Position)+' = '+IntToStr(CPos));
  end;
  Stream.Seek(HEAD,soFromBeginning);
  for Count := 0 to Header.Files - 1 do
    Stream.Write(Data[Count],CLPH);
  FreeAndNil(Stream);
end;

destructor TVDataCreator.Destroy;
begin
  Flush;
  FreeAndNil(Writers);
  inherited Destroy;
end;

function TVDataCreator.FileToStream(FileHead: TVDFClumpHeader) : DWord;
var FileStream : TStream;
    Filter  : TStream;
    Filter2 : TStream;
    Before  : DWord;
begin
  Before  := Stream.Position;
  Filter  := nil;
  Filter2 := nil;
  FileStream := TFileStream.Create(FileHead.Name,fmOpenRead);
  if (vdfEncrypted in FileHead.Flags) and (vdfCompressed in FileHead.Flags) then
  begin
    Filter := FileStream;
    Filter2 := TIDEAEncryptStream.Create(EKey,Stream);
    FileStream := TCompressionStream.Create(clDefault,Filter2,False);
    FileStream.CopyFrom(Filter,Filter.Size);
  end
  else
  if vdfEncrypted in FileHead.Flags then
  begin
    Filter := FileStream;
    FileStream := TIDEAEncryptStream.Create(EKey,Stream);
    FileStream.CopyFrom(Filter,Filter.Size);
  end
  else
  if vdfCompressed in FileHead.Flags then
  begin
    Filter := FileStream;
    FileStream := TCompressionStream.Create(clDefault,Stream,False);
    FileStream.CopyFrom(Filter,Filter.Size);
  end
  else
  begin
    Stream.CopyFrom(FileStream,FileStream.Size);
  end;
  FreeAndNil(Filter);
  FreeAndNil(FileStream);
  FreeAndNil(Filter2);
  Exit(Stream.Position - Before);
end;

function TVDataCreator.TrueFileName(FileName: AnsiString): AnsiString;
begin
  if RightStr(FileName,Length(FileMark)) = FileMark then
    Exit(LeftStr(FileName,Length(FileName)-Length(FileMark)))
  else Exit(FileName);
end;

end.

