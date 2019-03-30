{$INCLUDE valkyrie.inc}
// @abstract(Sound system for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(May 03, 2009)
//
// Implements an abstract sound system for Valkyrie
//
// Default behaviour for music is stoping the previous song before
// playing a new one.

unit vsound;

interface

uses Classes, SysUtils, vutil, vsystem, vds;

type ESoundException  = class( EException );
     TVSPtrArray      = specialize TArray<Pointer>;
     TVSDWordArray    = specialize TArray<DWord>;
     TVSExtArray      = specialize TArray<string>;
     TVSIntAssocArray = specialize TAssocArray<LongInt>;

// The basic sound class, published as the singleton @link(Sound).
// Should be initialized and disposed via TSystems.
type

{ TSound }

TSound = class(TSystem)
       // Initializes the Sound system.
       constructor Create; override;
       // Adds a MIDI/MOD file
       procedure RegisterMusic(const FileName : Ansistring; mID : Word);
       // Adds a WAV file
       procedure RegisterSample(const FileName : Ansistring; mID : Word);
       // Adds a MIDI/MOD file
       procedure RegisterMusic(const FileName : Ansistring; mID : Ansistring);
       // Adds a WAV file
       procedure RegisterSample(const FileName : Ansistring; mID : Ansistring);
       // Adds a MIDI/MOD file
       procedure RegisterMusic(Stream: TStream; Size : DWord; mID: Word; aMusicType : AnsiString = '.mid');
       // Adds a WAV file
       procedure RegisterSample(Stream : TStream; Size : DWord; mID : Word);
       // Adds a MIDI/MOD file
       procedure RegisterMusic(Stream : TStream; Size : DWord; mID : Ansistring; aMusicType : AnsiString = '.mid');
       // Adds a WAV file
       procedure RegisterSample(Stream : TStream; Size : DWord; mID : Ansistring);
       //
       function MusicExists(mID : Ansistring) : boolean;
       //
       function SampleExists(mID : Ansistring) : boolean;
       //
       function MusicID(mID : Ansistring) : Word;
       //
       function SampleID(mID : Ansistring) : Word;
       // Plays a MIDI/MOD song
       procedure PlayMusic(mID : Word);
       // Plays a MIDI/MOD song once
       procedure PlayMusicOnce(mID : Word);
       // Plays a sample once
       procedure PlaySample(mID : Word; Volume : Byte = 128; Pan : Integer = -1 );
       // Plays a sample once
       procedure PlaySample(mID : Ansistring; Volume : Byte = 128; Pan : Integer = -1);
       // Stops all MIDI/MOD songs
       procedure Silence;
       // Deinitializes the Sound system.
       destructor Destroy; override;
       // Sets the volume of the music.
       procedure SetMusicVolume(Volume : Byte);
       // Sets the volume of the sound effects.
       procedure SetSoundVolume(Volume : Byte);
       // Gets the volume of the music.
       function GetMusicVolume : Byte;
       // Gets the volume of the sound effects.
       function GetSoundVolume : Byte;
       //
       procedure Reset;
       // Utility Alias for VDF
       procedure MusicStreamLoader(Stream : TStream; Name : Ansistring; Size : DWord);
       // Utility Alias for VDF
       procedure SampleStreamLoader(Stream : TStream; Name : Ansistring; Size : DWord);
       // Alloctes memory and stores it in the cache
       function GetCacheMem( Size : DWord ) : Pointer;
     protected
       // Implementation of Music Loading
       function LoadMusic( const aFileName : AnsiString; Streamed : Boolean ) : Pointer; virtual; abstract;
       // Implementation of Sound Loading
       function LoadSound( const aFileName : AnsiString ) : Pointer; virtual; abstract;
       // Implementation of Music Loading
       function LoadMusicStream( Stream : TStream; Size : DWord; Streamed : Boolean ) : Pointer; virtual; abstract;
       // Implementation of Sound Loading
       function LoadSoundStream( Stream : TStream; Size : DWord ) : Pointer; virtual; abstract;
       // Implementation of Music Freeing
       procedure FreeMusic( aData : Pointer; const aType : String ); virtual; abstract;
       // Implementation of Sound Freeing
       procedure FreeSound( aData : Pointer ); virtual; abstract;
       // Implementation of get error
       function GetError( ) : AnsiString; virtual; abstract;
       // Implementation of play Sound
       procedure PlaySound( aData : Pointer; aVolume : Byte; aPan : Integer = -1 ); virtual; abstract;
       // Implementation of play Sound
       procedure PlayMusic( aData : Pointer; const aType : string; aRepeat : Boolean = True ); virtual; abstract;
       // Implementation of StopMusic
       procedure StopMusic( aData : Pointer; const aType : string ); virtual; abstract;
       // Implementation of StopSound
       procedure StopSound(); virtual; abstract;	   
       // Implementation of VolumeMusic
       procedure VolumeMusic( aData : Pointer; const aType : string; aVolume : Byte ); virtual; abstract;
     protected
       MusicPlaying : Word;
       MusicArray   : TVSPtrArray;
       MusicType    : TVSExtArray;
       MusicNames   : TVSIntAssocArray;
       MusicMax     : Word;
       SampleArray  : TVSPtrArray;
       SampleNames  : TVSIntAssocArray;
       SampleMax    : Word;
       MusicVolume  : Byte;
       SoundVolume  : Byte;
       CacheData    : TVSPtrArray;
       CacheSize    : TVSDWordArray;
     end;

const Sound : TSound = nil;

implementation

{ TSound }

constructor TSound.Create;
begin
  inherited Create;
  MusicArray   := TVSPtrArray.Create(50);
  SampleArray  := TVSPtrArray.Create(50);
  MusicNames   := TVSIntAssocArray.Create();
  SampleNames  := TVSIntAssocArray.Create();
  MusicType    := TVSExtArray.Create(50);
  MusicMax     := 1;
  MusicPlaying := 0;
  SampleMax    := 1;
  MusicVolume  := 100;
  SoundVolume  := 100;
  CacheData    := TVSPtrArray.Create(16);
  CacheSize    := TVSDWordArray.Create(16);
  if UpCase(Self.ClassName) = 'TSOUND' then ESoundException.Create( 'Plain TSound system initialized!' );
end;

procedure TSound.RegisterMusic(const FileName: Ansistring; mID: Word);
var Ext : AnsiString;
begin
  if MusicArray[mID] <> nil then raise ESoundException.Create( 'Trying to redefine Music ID#' + IntToStr(mID) + '!' );

  Ext             := ExtractFileExt( FileName );
  MusicArray[mID] := LoadMusic( FileName, (Ext = '.ogg') or (Ext = '.mp3') or (Ext = '.wav'));
  MusicType[mID]  := Ext;

  if MusicArray[mID] = nil then raise ESoundException.Create( 'RegisterMusic('+Filename+'): '+GetError());
  if mID > MusicMax then MusicMax := mID;
end;

procedure TSound.RegisterSample(const  FileName: Ansistring; mID: Word);
begin
  if SampleArray[mID] <> nil then raise ESoundException.Create( 'Trying to redefine Sample ID#' + IntToStr(mID) + '!' );
  SampleArray[mID] := LoadSound( FileName );
  if SampleArray[mID] = nil then raise ESoundException.Create( 'RegisterSample('+ Filename + '): '+GetError());
  if mID > SampleMax then SampleMax := mID;
end;

procedure TSound.RegisterMusic(const FileName: Ansistring; mID: Ansistring);
begin
  MusicNames[mID] := MusicMax+1;
  RegisterMusic(FileName,MusicMax+1);
end;

procedure TSound.RegisterSample(const FileName: Ansistring; mID: Ansistring);
begin
  SampleNames[mID] := SampleMax+1;
  RegisterSample(FileName,SampleMax+1);
end;

procedure TSound.RegisterMusic(Stream: TStream; Size : DWord; mID: Word; aMusicType : AnsiString = '.mid');
begin
  if MusicArray[mID] <> nil then raise ESoundException.Create( 'Trying to redefine Music ID#' + IntToStr(mID) + '!' );

  MusicArray[mID] := LoadMusicStream( Stream, Size, (aMusicType = '.ogg') or (aMusicType = '.mp3') or (aMusicType = '.wav'));
  MusicType[mID]  := aMusicType; // HAX!

  if MusicArray[mID] = nil then raise ESoundException.Create( 'RegisterMusic(Stream): '+GetError());
  if mID > MusicMax then MusicMax := mID;
end;

procedure TSound.RegisterSample(Stream: TStream; Size : DWord; mID: Word);
begin
  if SampleArray[mID] <> nil then raise ESoundException.Create( 'Trying to redefine Sample ID#' + IntToStr(mID) + '!' );
  SampleArray[mID] := LoadSoundStream( Stream, Size );
  if SampleArray[mID] = nil then raise ESoundException.Create( 'RegisterSample(Stream): '+GetError());
  if mID > SampleMax then SampleMax := mID;
end;

procedure TSound.RegisterMusic(Stream: TStream; Size : DWord; mID: Ansistring; aMusicType : AnsiString = '.mid');
begin
  MusicNames[mID] := MusicMax+1;
  RegisterMusic(Stream,Size,MusicMax+1,aMusicType);
end;

procedure TSound.RegisterSample(Stream: TStream; Size : DWord; mID: Ansistring);
begin
  SampleNames[mID] := SampleMax+1;
  RegisterSample(Stream,Size,SampleMax+1);
end;

function TSound.MusicExists(mID: Ansistring): boolean;
begin
  Exit(MusicNames.Exists(mID));
end;

function TSound.SampleExists(mID: Ansistring): boolean;
begin
  Exit(SampleNames.Exists(mID));
end;

function TSound.MusicID(mID: Ansistring): Word;
begin
  Exit( MusicNames[mID] );
end;

function TSound.SampleID(mID: Ansistring): Word;
begin
  Exit( SampleNames[mID] );
end;

procedure TSound.PlayMusic(mID: Word);
begin
  if MusicPlaying <> 0 then Silence;
  if MusicArray[mID] = nil then raise ESoundException.Create('Trying play non-existent Music ID#'+IntToStr(mID)+'!');
  PlayMusic( MusicArray[mID], MusicType[mID] );
  MusicPlaying := mID;
end;

procedure TSound.PlayMusicOnce(mID: Word);
begin
  if MusicPlaying <> 0 then Silence;
  if MusicArray[mID] = nil then raise ESoundException.Create('Trying play non-existent Music ID#'+IntToStr(mID)+'!');
  PlayMusic( MusicArray[mID], MusicType[mID], False );
  MusicPlaying := mID;
end;


procedure TSound.PlaySample( mID: Word; Volume : Byte = 128; Pan : Integer = -1 );
begin
  if SampleArray[mID] = nil then raise ESoundException.Create('Trying play non-existent Sample ID#'+IntToStr(mID)+'!');

  if Volume = 128 then
    Volume := SoundVolume
  else
    Volume := Round(Volume*(SoundVolume/128.0));

  PlaySound( SampleArray[mID], Volume, Pan );
end;

procedure TSound.PlaySample( mID: Ansistring; Volume : Byte = 128; Pan : Integer = -1 );
begin
  PlaySample( SampleNames[mID], Volume, Pan );
end;

procedure TSound.Silence;
begin
  StopMusic( MusicArray[MusicPlaying], MusicType[MusicPlaying] );
  MusicPlaying := 0;
end;

destructor TSound.Destroy;
var iCount : Word;
begin
 for iCount := 1 to MusicMax do
    if MusicArray[iCount] <> nil then
      FreeMusic( MusicArray[iCount], MusicType[iCount] );
  for iCount := 1 to SampleMax do
    if SampleArray[iCount] <> nil then
       FreeSound( SampleArray[iCount] );
  if not CacheData.isEmpty then
  for iCount := 0 to CacheData.Count do
    FreeMem( CacheData[iCount], CacheSize[iCount] );
  FreeAndNil( MusicArray );
  FreeAndNil( SampleArray );
  FreeAndNil( MusicNames );
  FreeAndNil( SampleNames );
  FreeAndNil( MusicType );
  inherited Destroy;
end;

procedure TSound.SetMusicVolume(Volume: Byte);
begin
  MusicVolume := Volume;
  VolumeMusic( MusicArray[MusicPlaying], MusicType[MusicPlaying], Volume );
end;

procedure TSound.SetSoundVolume(Volume: Byte);
begin
  SoundVolume := Volume;
end;

function TSound.GetMusicVolume: Byte;
begin
  Exit(MusicVolume);
end;

function TSound.GetSoundVolume: Byte;
begin
  Exit(SoundVolume);
end;

procedure TSound.Reset;
var iCount : DWord;
begin
   for iCount := 1 to MusicMax do
     if MusicArray[iCount] <> nil then
       FreeMusic( MusicArray[iCount], MusicType[iCount] );
   for iCount := 1 to SampleMax do
     if SampleArray[iCount] <> nil then
        FreeSound( SampleArray[iCount] );
   if not CacheData.isEmpty then
   for iCount := 0 to CacheData.Count do
     FreeMem( CacheData[iCount], CacheSize[iCount] );

   FreeAndNil( MusicArray );
   FreeAndNil( SampleArray );
   FreeAndNil( MusicNames );
   FreeAndNil( SampleNames );
   FreeAndNil( MusicType );
   FreeAndNil( CacheData );
   FreeAndNil( CacheSize );
   MusicArray   := TVSPtrArray.Create(50);
   SampleArray  := TVSPtrArray.Create(50);
   MusicNames   := TVSIntAssocArray.Create();
   SampleNames  := TVSIntAssocArray.Create();
   MusicType    := TVSExtArray.Create(50);
   CacheData    := TVSPtrArray.Create(16);
   CacheSize    := TVSDWordArray.Create(16);
   MusicMax     := 1;
   MusicPlaying := 0;
   SampleMax    := 1;
   MusicVolume  := 100;
   SoundVolume  := 100;
end;

procedure TSound.MusicStreamLoader(Stream: TStream; Name: Ansistring;
  Size: DWord);
var Ext : AnsiString;
begin
  Ext := ExtractFileExt(Name);
  RegisterMusic( Stream, Size, LeftStr( Name, Length(Name) - Length(Ext) ), Ext );
end;

procedure TSound.SampleStreamLoader(Stream: TStream; Name: Ansistring;
  Size: DWord);
var Ext : AnsiString;
begin
  Ext := ExtractFileExt(Name);
  RegisterSample( Stream, Size, LeftStr( Name, Length(Name) - Length(Ext) ) );
end;

function TSound.GetCacheMem(Size: DWord): Pointer;
begin
  GetCacheMem := GetMem(Size);
  if GetCacheMem = nil then Exit;
  CacheData.Push( GetCacheMem );
  CacheSize.Push( Size );
end;


end.

