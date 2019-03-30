{$include valkyrie.inc}
unit vglfontimage;
interface
uses SysUtils, Classes, vfontimage, vsdllibrary, vimage, vglimage, vgltypes;

type TGLFontImage = class( TFontImage )
    constructor Create( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord; aCount : DWord; aBlend : Boolean; aAlt : Boolean );
    constructor Create( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord; aCount : DWord; aBlend : Boolean; aAlt : Boolean; aWidthData : PByte );
    procedure Upload( aBlend : Boolean );
    procedure SetTexCoord( out aTexCoord : TGLRawQTexCoord; aChar : Char; aAlt : Boolean = False );
    destructor Destroy; override;
  private
    procedure Recalc;
    procedure GenerateQTexCoord( out aTexCoord : TGLRawQTexCoord; aIndex : DWord );
  private
    FGLGylphWidth  : Single;
    FGLGylphHeight : Single;
    FGLImageWidth  : Single;
    FGLImageHeight : Single;
    FGLTexture     : DWord;
    FGLQTexCoords  : array of TGLRawQTexCoord;
  public
    property GLTexture : DWord read FGLTexture;
  end;

function LoadFontImage( const aFileName : Ansistring; aBlend : Boolean ) : TGLFontImage;
function LoadFontImage( const aFileName, aMetricsFile : Ansistring; aBlend : Boolean ) : TGLFontImage;
function LoadFontImage( aStream : TStream; aSize : DWord; aBlend : Boolean ) : TGLFontImage;
function LoadFontImage( aStream : TStream; aSize : DWord; aMetrics : TStream; aBlend : Boolean ) : TGLFontImage;
function LoadFontImage( aSDLSurface : PSDL_Surface; aBlend : Boolean ) : TGLFontImage;
function LoadFontImage( aSDLSurface : PSDL_Surface; aMetrics : PByte; aBlend : Boolean ) : TGLFontImage;

implementation

uses math, vmath, vsdlimagelibrary;

{ TGLFontImage }

constructor TGLFontImage.Create ( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord;
  aCount : DWord; aBlend : Boolean; aAlt : Boolean ) ;
begin
  inherited Create ( aImage, aImageWidth, aImageHeight, aPerLine, aCount, aAlt ) ;
  Upload( aBlend );
  Recalc;
end;

constructor TGLFontImage.Create ( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord;
  aCount : DWord; aBlend : Boolean; aAlt : Boolean; aWidthData : PByte ) ;
begin
  inherited Create ( aImage, aImageWidth, aImageHeight, aPerLine, aCount, aAlt, aWidthData ) ;
  Upload( aBlend );
  Recalc;
end;

procedure TGLFontImage.Upload( aBlend : Boolean );
begin
  FGLTexture := UploadImage( FImage, aBlend );
end;

procedure TGLFontImage.SetTexCoord( out aTexCoord : TGLRawQTexCoord; aChar : Char; aAlt : Boolean );
var iIndex : DWord;
begin
  iIndex := Clamp( Ord( aChar )-32, 0, FSetSize-1 );
  if aAlt and FAltPresent then iIndex += FSetSize;
  aTexCoord := FGLQTexCoords[ iIndex ];
end;

destructor TGLFontImage.Destroy;
begin
  inherited Destroy;
end;

procedure TGLFontImage.Recalc;
var iIndex : DWord;
    iCount : DWord;
begin
  FGLImageWidth  := FImageWidth  / FImage.SizeX;
  FGLImageHeight := FImageHeight / FImage.SizeY;
  FGLGylphWidth  := FGylphWidth  / FImage.SizeX;
  FGLGylphHeight := FGylphHeight / FImage.SizeY;

  iCount := FSetSize;
  if FAltPresent then iCount *= 2;

  SetLength( FGLQTexCoords, iCount );

  for iIndex := 0 to iCount - 1 do
    GenerateQTexCoord( FGLQTexCoords[iIndex], iIndex );
end;

procedure TGLFontImage.GenerateQTexCoord ( out aTexCoord : TGLRawQTexCoord; aIndex : DWord );
var p1, p2 : TGLVec2f;
    tx, ty         : DWord;
begin
  tx := aIndex mod FGylphLine;
  ty := aIndex div FGylphLine;

  p1 := TGLVec2f.Create( tx * FGLGylphWidth, ty * FGLGylphHeight );
  p2 := TGLVec2f.Create( (tx+1) * FGLGylphWidth, (ty+1) * FGLGylphHeight );

  aTexCoord.Init( p1, p2 );
end;

function LoadFontImage ( const aFileName : Ansistring; aBlend : Boolean ) : TGLFontImage;
begin
  LoadSDLImage;
  Exit( LoadFontImage( IMG_LoadOrThrow( PChar( aFileName ) ), aBlend ) );
end;

function LoadFontImage ( const aFileName, aMetricsFile : Ansistring; aBlend : Boolean ) : TGLFontImage;
var iMFile : TStream;
    iFFile : TStream;
begin
  LoadSDLImage;
  iFFile := TFileStream.Create( aMetricsFile, fmOpenRead );
  iMFile := TFileStream.Create( aFileName, fmOpenRead );
  Result := LoadFontImage( iFFile, iFFile.Size, iMFile, aBlend );
  FreeAndNil( iMFile );
  FreeAndNil( iFFile );
end;

function LoadFontImage ( aStream : TStream; aSize : DWord; aBlend : Boolean ) : TGLFontImage;
begin
  LoadSDLImage;
  Exit( LoadFontImage( IMG_LoadRWOrThrow( SDL_RWopsFromStream( aStream, aSize ), 0 ), aBlend ) );
end;

function LoadFontImage ( aStream : TStream; aSize : DWord; aMetrics : TStream; aBlend : Boolean ) : TGLFontImage;
var iMetrics : PByte;
    iCount   : DWord;
begin
  LoadSDLImage;
  iCount := aMetrics.ReadDWord;
  iMetrics := GetMem( iCount );
  aMetrics.Read( iMetrics^, iCount );
  Result := LoadFontImage( IMG_LoadRWOrThrow( SDL_RWopsFromStream( aStream, aSize ), 0 ), iMetrics, aBlend );
  FreeMem( iMetrics, iCount );
end;

function LoadFontImage ( aSDLSurface : PSDL_Surface; aBlend : Boolean ) : TGLFontImage;
var iImage : TImage;
begin
  iImage := LoadImage( aSDLSurface );
  Exit( TGLFontImage.Create( iImage, aSDLSurface^.w, aSDLSurface^.h, 32, 256-32, aBlend, False ) );
end;

function LoadFontImage ( aSDLSurface : PSDL_Surface; aMetrics : PByte; aBlend : Boolean  ) : TGLFontImage;
var iImage : TImage;
begin
  iImage := LoadImage( aSDLSurface );
  Exit( TGLFontImage.Create( iImage, aSDLSurface^.w, aSDLSurface^.h, 16, 128, aBlend, True, aMetrics ) );
end;

end.

