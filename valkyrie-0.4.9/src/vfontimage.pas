{$include valkyrie.inc}
unit vfontimage;
interface
uses SysUtils, Classes, vimage;

type TFontImage = class
    constructor Create( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord; aCount : DWord; aAlt : Boolean );
    constructor Create( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord; aCount : DWord; aAlt : Boolean; aWidthData : PByte );
    destructor Destroy; override;
  protected
    FImage       : TImage;
    FFixedWidth  : Boolean;
    FImageWidth  : DWord;
    FimageHeight : DWord;
    FGylphLine   : DWord;
    FGylphCount  : DWord;
    FGylphHeight : Integer;
    FGylphWidth  : Integer;
    FSetSize     : DWord;
    FAltPresent  : Boolean;
    FWidthData   : array of Byte;
  public
    property Image : TImage read FImage;
    property GylphHeight : Integer read FGylphHeight;
    property GylphWidth  : Integer read FGylphWidth;
  end;

implementation

uses math;

{ TFontImage }

constructor TFontImage.Create ( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord; aCount : DWord; aAlt : Boolean ) ;
begin
  FImage       := aImage;
  FFixedWidth  := True;
  FImageWidth  := aImageWidth;
  FimageHeight := aImageHeight;
  FGylphLine   := aPerLine;
  FGylphCount  := aCount;
  FAltPresent  := aAlt;
  SetLength( FWidthData, 0 );

  FSetSize     := Ceil( FGylphCount / FGylphLine ) * FGylphLine;
  FGylphWidth  := FImageWidth div FGylphLine;
  if FAltPresent
    then FGylphHeight := aImageHeight div ((2*FSetSize) div FGylphLine)
    else FGylphHeight := aImageHeight div (FSetSize div FGylphLine);
end;

constructor TFontImage.Create ( aImage : TImage; aImageWidth : DWord; aImageHeight : DWord; aPerLine : DWord; aCount : DWord; aAlt : Boolean; aWidthData : PByte ) ;
begin
  FImage       := aImage;
  FFixedWidth  := True;
  FImageWidth  := aImageWidth;
  FimageHeight := aImageWidth;
  FGylphLine   := aPerLine;
  FGylphCount  := aCount;
  FAltPresent  := aAlt;
  SetLength( FWidthData, FGylphCount );
  system.Move( aWidthData^, FWidthData[ 0 ], FGylphCount );

  FSetSize     := Ceil( FGylphCount / FGylphLine ) * FGylphLine;
  FGylphWidth  := FImageWidth div FGylphLine;
  if FAltPresent
    then FGylphHeight := aImageHeight div (2*FSetSize)
    else FGylphHeight := aImageHeight div FSetSize;
end;

destructor TFontImage.Destroy;
begin
  FreeAndNil( FImage );
  inherited Destroy;
end;

end.

