{$include valkyrie.inc}
unit vgltextures;
interface

uses SysUtils, Classes,
     vnode, vgenerics, vimage, vglimage, vgltypes;

type TBoolArray   = specialize TGArray<Boolean>;
type TImageArray  = specialize TGObjectArray<TImage>;
type TIAssocArray = specialize TGHashMap<DWord>;
type TGLIDArray   = specialize TGArray<DWord>;
type TGLSizeArray = specialize TGArray<TGLVec2f>;

type TGLTextures = class( TVObject )
  constructor Create( aDefaultBlend : Boolean = False );
  procedure LoadTextureFolder( const aFolder : AnsiString );
  procedure LoadTextureCallback( aStream : TStream; aName : Ansistring; aSize : DWord );
  procedure Upload;
  destructor Destroy; override;
  function AddImage( const aID : AnsiString; aImage : TImage; aBlend : Boolean ) : DWord;
protected
  function GetTexture( const aTextureID : AnsiString ) : DWord;
  function GetImage ( const aTextureID : AnsiString ) : TImage;
  function GetSize ( const aTextureID : AnsiString ) : TGLVec2f;
protected
  FBlend    : TBoolArray;
  FImages   : TImageArray;
  FGLIDs    : TGLIDArray;
  FNames    : TIAssocArray;
  FSizes    : TGLSizeArray;
  FBlendDef : Boolean;
public
  property Textures[ const aIndex : AnsiString ] : DWord read GetTexture; default;
  property Images[ const aIndex : AnsiString ] : TImage read GetImage;
  property Sizes[ const aIndex : AnsiString ] : TGLVec2f read GetSize;
end;

implementation

{ TGLTextures }

constructor TGLTextures.Create( aDefaultBlend : Boolean = False );
begin
  inherited Create;
  FBlendDef := aDefaultBlend;
  FBlend    := TBoolArray.Create;
  FImages   := TImageArray.Create;
  FGLIDs    := TGLIDArray.Create;
  FNames    := TIAssocArray.Create;
  FSizes    := TGLSizeArray.Create;
end;

procedure TGLTextures.LoadTextureFolder ( const aFolder : AnsiString ) ;
var iName      : AnsiString;
    iSearchRec : TSearchRec;
begin
  if FindFirst(aFolder + PathDelim + '*.png',faAnyFile,iSearchRec) = 0 then
  repeat
    iName := iSearchRec.Name;
    Delete(iName,Length(iName)-3,4);
    AddImage( iName, LoadImage(aFolder + PathDelim + iSearchRec.Name ), FBlendDef );
  until (FindNext(iSearchRec) <> 0);
end;


procedure TGLTextures.LoadTextureCallback ( aStream : TStream; aName : Ansistring; aSize : DWord ) ;
var iName      : AnsiString;
begin
  iName := aName;
  Delete(iName,Length(iName)-3,4);
  AddImage( iName, LoadImage( aStream, aSize ), FBlendDef );
end;

procedure TGLTextures.Upload;
var iIndex : DWord;
    iImage : TImage;
begin
  if FImages.Size = 0 then Exit;
  FGLIDs.Reserve( FImages.Size );
  FSizes.Reserve( FImages.Size );
  for iIndex := 0 to FImages.Size-1 do
  begin
    iImage := FImages[iIndex];
    FGLIDs[ iIndex ] := UploadImage( iImage, FBlend[iIndex] );
    FSizes[ iIndex ] := TGLVec2f.Create( iImage.RawX / iImage.SizeX, iImage.RawY / iImage.SizeY );
  end;
end;

destructor TGLTextures.Destroy;
begin
  FreeAndNil( FImages );
  FreeAndNil( FGLIDs );
  FreeAndNil( FBlend );
  FreeAndNil( FNames );
  FreeAndNil( FSizes );
  inherited Destroy;
end;

function TGLTextures.AddImage ( const aID : AnsiString; aImage : TImage;
  aBlend : Boolean ) : DWord;
begin
  Result := FImages.Push( aImage ) - 1;
  FBlend.Push( aBlend );
  FNames[ aID ] := Result;
end;

function TGLTextures.GetTexture ( const aTextureID : AnsiString ) : DWord;
begin
  Exit( FGLIDs[ FNames[ aTextureID ] ] );
end;

function TGLTextures.GetImage ( const aTextureID : AnsiString ) : TImage;
begin
  Exit( FImages[ FNames[ aTextureID ] ] );
end;

function TGLTextures.GetSize ( const aTextureID : AnsiString ) : TGLVec2f;
begin
  Exit( FSizes[ FNames[ aTextureID ] ] );
end;

end.

