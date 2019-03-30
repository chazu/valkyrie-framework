{$INCLUDE valkyrie.inc}
// @abstract(Data file classes for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @cvs($Author: chaos-dev $)
// @cvs($Date: 2008-01-14 22:16:41 +0100 (Mon, 14 Jan 2008) $)
//
// Introduces data file handling classes, with compression and encryption.
//
//  @html <div class="license">
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the GNU Library General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or (at your
//  option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
//  for more details.
//
//  You should have received a copy of the GNU Library General Public License
//  along with this library; if not, write to the Free Software Foundation,
//  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//  @html </div>

unit vdf;
interface
uses vnode, Classes, SysUtils, zstream, vds, idea;

type

TVDFClumpFlags = set of (vdfCompressed,vdfEncrypted);

TVDFHeader = packed record
  Signature : string[8];
  Version   : DWord;
  Files     : DWord;
end;

TVDFClumpHeader = packed record
  Size  : DWord;
  Pos   : DWord;
  Dir   : string[64];
  Name  : string[64];
  Flags : TVDFClumpFlags;
  FType : DWord;
end;

TVDCHArray = array of TVDFClumpHeader;

TVDFLoader = procedure(Stream : TStream; Name : AnsiString; Size : DWord) of Object;

TVDFLoaders = specialize TArray<TVDFLoader>;

{ TVDataFile }

TVDataFile = class(TVObject)
  DKKey   : TIDEAKey;
  constructor Create(FileName : Ansistring);
  function GetFile(FileName : Ansistring; DirName : Ansistring = '') : TStream;
  function GetFileSize(FileName : Ansistring; DirName : Ansistring = '') : Int64;
  function FileExists(FileName : Ansistring; DirName : Ansistring = '') : Boolean;
  procedure Load(PackageID : AnsiString = '');
  procedure LoadFile(FileName : Ansistring; PackageID : AnsiString = '');
  procedure RegisterLoader(LoaderID : DWord; Loader : TVDFLoader);
  destructor Destroy; override;
  private
  procedure LoadFile( FileID : DWord );
  function GetFileID(FileName,Dir : Ansistring) : DWord; overload;
  private
  FStream  : TFileStream;
  FData    : TVDCHArray;
  FFiles   : DWord;
  FName    : Ansistring;
  FLoaders : TVDFLoaders;
end;

{ TVDataStream }

TVDataStream = class(TFileStream)
  public
  ChunkSize : int64;
  public
  constructor Create(nFileName : Ansistring; cSize, cPosition : DWord); reintroduce;
end;

{ TVCDataStream }

TVCDataStream = class(TDecompressionStream)
  private
  FileStream : TFileStream;
  public
  ChunkSize : int64;
  constructor Create(nFileName : Ansistring; cSize, cPosition : DWord); reintroduce;
  destructor Destroy; override;
end;

{ TVEDataStream }

TVEDataStream = class(TIDEADeCryptStream)
  private
  FileStream : TFileStream;
  public
  ChunkSize : int64;
  public
  constructor Create(nFileName : Ansistring; cSize, cPosition : DWord; const cKey : TIDEAKey); reintroduce;
  destructor Destroy; override;
end;

{ TVECDataStream }

TVECDataStream = class(TDecompressionStream)
  private
  FileStream : TFileStream;
  DEStream   : TIDEADeCryptStream;
  public
  ChunkSize  : int64;
  public
  constructor Create(nFileName : Ansistring; cSize, cPosition : DWord; const cKey : TIDEAKey); reintroduce;
  destructor Destroy; override;
end;


const VDF_SIGNATURE = 'VDFILE02';

implementation

uses vutil;


{ TVDataFile }

constructor TVDataFile.Create(FileName : Ansistring);
var Header : TVDFHeader;
    Count  : DWord;
begin
  FName := FileName;
  Log('Loading "'+FName+'"...');
  try
    FStream := TFileStream.Create(FileName,fmOpenRead);
  except
    CritError('Can''t open Valkyrie Data File "'+FName+'"!');
  end;
  {$HINTS OFF}
  FStream.Read(Header,SizeOf(Header));
  {$HINTS ON}
  if Header .Signature<> VDF_SIGNATURE then CritError('Corrupted Valkyrie Data File "'+FName+'"!');
  FFiles := Header.Files;
  if FFiles = 0 then Exit;
  SetLength(FData,FFiles);
  for Count := 0 to FFiles-1 do
    FStream.Read(FData[Count],SizeOf(TVDFClumpHeader));
  Log('Loaded "'+FName+'" ('+IntToStr(Count+1)+' files).');
  FreeAndNil(FStream);
  
  FLoaders := TVDFLoaders.Create();
end;

function TVDataFile.GetFile(FileName: Ansistring; DirName: Ansistring): TStream;
var ID : DWord;
begin
  ID := GetFileID(FileName,DirName);
  
  if (vdfCompressed in FData[ID].Flags) and (vdfEncrypted in FData[ID].Flags) then
    GetFile := TVECDataStream.Create(FName,FData[ID].Size,FData[ID].Pos,DKKey)
  else
  if vdfCompressed in FData[ID].Flags then
    GetFile := TVCDataStream.Create(FName,FData[ID].Size,FData[ID].Pos)
  else
  if vdfEncrypted in FData[ID].Flags then
    GetFile := TVEDataStream.Create(FName,FData[ID].Size,FData[ID].Pos,DKKey)
  else
    GetFile := TVDataStream.Create(FName,FData[ID].Size,FData[ID].Pos);
end;

function TVDataFile.GetFileSize(FileName: Ansistring; DirName: Ansistring): Int64;
var ID : DWord;
begin
  ID := GetFileID(FileName,DirName);
  Exit(FData[ID].Size);
end;

function TVDataFile.FileExists(FileName: Ansistring; DirName: Ansistring): Boolean;
var Count : DWord;
begin
  for Count := 0 to FFiles-1 do
    if (FData[Count].Dir = DirName) and (FileName = FData[Count].Name) then Exit(True);
  Exit(False);
end;

procedure TVDataFile.Load(PackageID : AnsiString);
var Count    : DWord;
begin
  Log('VDF extraction ('+PackageID+')');

  for Count := 0 to FFiles-1 do
  begin
    if (FData[Count].Dir <> PackageID) then Continue;
    if (FData[Count].FType = 0)        then Continue;
    LoadFile( Count );
  end;
  Log('VDF extraction completed ('+PackageID+')');
end;

procedure TVDataFile.LoadFile(FileName: Ansistring; PackageID: AnsiString);
var ID    : DWord;
begin
  Log('VDF extraction ('+PackageID+'/'+FileName+')');
  ID := GetFileID(FileName,PackageID);
  LoadFile(ID);
  Log('VDF extraction complete ('+PackageID+'/'+FileName+')');
end;

procedure TVDataFile.RegisterLoader(LoaderID: DWord; Loader: TVDFLoader);
begin
  FLoaders[LoaderID] := Loader;
end;


destructor TVDataFile.Destroy;
begin
  FreeAndNil(FLoaders);
  inherited Destroy;
end;

procedure TVDataFile.LoadFile(FileID: DWord);
var DStream  : TStream;
    LSize    : DWord;
    Loader   : TVDFLoader;
begin
  if (FLoaders[FData[FileID].FType] = nil) then
    CritError('Unregistered loader : "'+IntToStr(FData[FileID].FType)+'"!"');
  Loader   := FLoaders[FData[FileID].FType];
  DStream := GetFile(FData[FileID].Name,FData[FileID].Dir);
  LSize   := FData[FileID].Size;
  Loader(DStream,FData[FileID].Name,LSize);
  FreeAndNil(DStream);
end;

function TVDataFile.GetFileID(FileName, Dir: Ansistring): DWord;
var Count : DWord;
begin
  for Count := 0 to FFiles-1 do
    if (Dir = FData[Count].Dir) and (FileName = FData[Count].Name) then Exit(Count);
  raise EFOpenError.Create('File "'+Dir+'/'+FileName+'" not found in VDF "'+FName+'"!');
end;

{ TVDataStream }

constructor TVDataStream.Create(nFileName: Ansistring; cSize, cPosition: DWord);
begin
  inherited Create(nFileName,fmOpenRead);
  Seek(cPosition,soFromBeginning);
  ChunkSize := cSize;
end;

{ TVCDataStream }

constructor TVCDataStream.Create(nFileName: Ansistring; cSize, cPosition: DWord);
begin
  FileStream := TFileStream.Create(nFileName,fmOpenRead);
  FileStream.Seek(cPosition,soFromBeginning);
  inherited Create(FileStream);
  ChunkSize := cSize;
end;

destructor TVCDataStream.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FileStream);
end;

{ TVEDataStream }

constructor TVEDataStream.Create(nFileName: Ansistring; cSize,
  cPosition: DWord; const cKey: TIDEAKey);
begin
  FileStream := TFileStream.Create(nFileName,fmOpenRead);
  FileStream.Seek(cPosition,soFromBeginning);
  inherited Create(cKey,FileStream);
  ChunkSize := cSize;
end;

destructor TVEDataStream.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FileStream);
end;

{ TVECDataStream }

constructor TVECDataStream.Create(nFileName: Ansistring; cSize,
  cPosition: DWord; const cKey: TIDEAKey);
begin
  FileStream := TFileStream.Create(nFileName,fmOpenRead);
  FileStream.Seek(cPosition,soFromBeginning);
  DEStream := TIDEADeCryptStream.Create(cKey,FileStream);
  inherited Create(DEStream);
  ChunkSize := cSize;
end;

destructor TVECDataStream.Destroy;
begin
//  inherited Destroy;
// Memory leak here -- unfortunately TDecompression stream destroy calls Seek :/

  FreeAndNil(DEStream);
  FreeAndNil(FileStream);
end;

end.

