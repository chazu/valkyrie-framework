{$include valkyrie.inc}
unit vcolor;
interface

type

{ TColor }

TColor = packed object
  R : Byte;
  G : Byte;
  B : Byte;
  A : Byte;
  procedure Init( aR, aG, Ab : Byte; aA : Byte = 255 );
  function toDWord : DWord;
end;

function ColorMix( A, B : TColor ) : TColor;
function NewColor( aR, aG, Ab : Byte; aA : Byte = 255 ) : TColor;
function NewColor( Color16 : Byte ) : TColor;
function ScaleColor( A : TColor; Scale : Byte ) : TColor;
function ScaleColor( A : TColor; Scale : Single ) : TColor;


const
  ColorZero      : TColor = ( r : 0;   g : 0;   b : 0;   a : 0; );
  ColorBlack     : TColor = ( r : 0;   g : 0;   b : 0;   a : 255; );
  ColorRed       : TColor = ( r : 255; g : 0;   b : 0;   a : 255; );
  ColorGreen     : TColor = ( r : 0;   g : 255; b : 0;   a : 255; );
  ColorBlue      : TColor = ( r : 0;   g : 0;   b : 255; a : 255; );
  ColorWhite     : TColor = ( r : 255; g : 255; b : 255; a : 255; );

implementation

uses math;

const StandardColors : array[0..15] of array[0..2] of Byte = (
      ( 0,   0,   0 ),
      ( 0,   0,   160 ),
      ( 0,   160, 0 ),
      ( 0,   160, 160 ),
      ( 160, 0,   0 ),
      ( 160, 0,   160 ),
      ( 160, 160, 0 ),
      ( 200, 200, 200 ),
      ( 128, 128, 128 ),
      ( 0,   0,   255 ),
      ( 0,   255, 0 ),
      ( 0,   255, 255 ),
      ( 255, 0,   0 ),
      ( 255, 0,   255 ),
      ( 255, 255, 0 ),
      ( 255, 255, 255 )
      );

function ColorMix(A, B: TColor): TColor;
begin
  ColorMix.R := Round(A.R / 255.0 * B.R );
  ColorMix.G := Round(A.G / 255.0 * B.G );
  ColorMix.B := Round(A.B / 255.0 * B.B );
  ColorMix.A := 255;
end;

function NewColor(aR, aG, Ab: Byte; aA: Byte): TColor;
begin
  NewColor.R := aR;
  NewColor.G := aG;
  NewColor.B := aB;
  NewColor.A := aA;
end;

function NewColor(Color16: Byte): TColor;
begin
  NewColor.R := StandardColors[Color16][0];
  NewColor.G := StandardColors[Color16][1];
  NewColor.B := StandardColors[Color16][2];
  NewColor.A := 255;
end;

function ScaleColor(A: TColor; Scale : Byte ): TColor;
begin
  ScaleColor.R := Round(A.R / 255.0 * Scale );
  ScaleColor.G := Round(A.G / 255.0 * Scale );
  ScaleColor.B := Round(A.B / 255.0 * Scale );
  ScaleColor.A := 255;
end;

function ScaleColor(A: TColor; Scale: Single): TColor;
begin
  ScaleColor.R := Min( Round(A.R * Scale ), 255 );
  ScaleColor.G := Min( Round(A.G * Scale ), 255 );
  ScaleColor.B := Min( Round(A.B * Scale ), 255 );
  ScaleColor.A := 255;
end;

{ TColor }

procedure TColor.Init(aR, aG, Ab: Byte; aA: Byte);
begin
  R := aR;
  G := aG;
  B := aB;
  A := aA;
end;

function TColor.toDWord: DWord;
begin
   toDWord := PDWord(@Self)^;
end;

end.

