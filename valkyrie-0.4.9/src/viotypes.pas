{$INCLUDE valkyrie.inc}
unit viotypes;
interface
uses Classes, SysUtils, vutil, vnode, vioevent, vgltypes;

type TIOColor         = DWord;
type TIOCursorType    = ( VIO_CURSOR_SMALL, VIO_CURSOR_HALF, VIO_CURSOR_BLOCK );
type TIORect          = TRectangle;
type TIOPoint         = TPoint;
type TIOGylph         = Word;

type TIOTerminateEventHandler = function : Boolean of object;
type TIOInterrupt = function( aEvent : TIOEvent ) : Boolean of object;
type TIOInterrupts = array[0..IOKeyCodeMax] of TIOInterrupt;

type TIODriver = class( TVObject )
  function PollEvent( out aEvent : TIOEvent ) : Boolean; virtual; abstract;
  function PeekEvent( out aEvent : TIOEvent ) : Boolean; virtual; abstract;
  function EventPending : Boolean; virtual; abstract;
  procedure SetEventMask( aMask : TIOEventType ); virtual; abstract;
  procedure Sleep( Milliseconds : DWord ); virtual; abstract;
  procedure PreUpdate; virtual; abstract;
  procedure PostUpdate; virtual; abstract;
  function GetMs : DWord; virtual; abstract;
  function GetSizeX : DWord; virtual; abstract;
  function GetSizeY : DWord; virtual; abstract;
  function GetMousePos( var aResult : TIOPoint) : Boolean; virtual; abstract;
  function GetMouseButtonState( var aResult : TIOMouseButtonSet) : Boolean; virtual; abstract;
  function GetModKeyState : TIOModKeySet; virtual; abstract;
  procedure SetTitle( const aLongTitle : AnsiString; const aShortTitle : AnsiString = '' ); virtual; abstract;
  procedure ClearInterrupts;
  procedure RegisterInterrupt( aCode : TIOKeyCode; aInterrupt : TIOInterrupt );
protected
  FOnQuit     : TIOInterrupt;
  FInterrupts : TIOInterrupts;
public
  property OnQuitEvent : TIOInterrupt write FOnQuit;
end;

type IIOElement = interface['viotypes.iioelement']
  procedure OnUpdate( aTime : DWord );
  function OnEvent( const event : TIOEvent ) : Boolean;
end;

//type TIODeviceCap     = ( VIO_DEV_OPENGL, VIO_DEV_MOUSE, VIO_DEV_KEYUP );
//type TIODeviceCapSet  = set of TIODeviceCap;

type EIOException = class(Exception);
type EIOSupportException = class(EIOException);

const
  Black        = 0;    DarkGray     = 8;
  Blue         = 1;    LightBlue    = 9;
  Green        = 2;    LightGreen   = 10;
  Cyan         = 3;    LightCyan    = 11;
  Red          = 4;    LightRed     = 12;
  Magenta      = 5;    LightMagenta = 13;
  Brown        = 6;    Yellow       = 14;
  LightGray    = 7;    White        = 15;
  ColorNone    = $EFFFFFFF;

const GLFloatColors : array[0..15] of TGLFloatColor = (
      ( Data : ( 0.0, 0.0, 0.0 ) ),
      ( Data : ( 0.0, 0.0, 0.6 ) ),
      ( Data : ( 0.0, 0.6, 0.0 ) ),
      ( Data : ( 0.0, 0.6, 0.6 ) ),
      ( Data : ( 0.6, 0.0, 0.0 ) ),
      ( Data : ( 0.6, 0.0, 0.6 ) ),
      ( Data : ( 0.6, 0.6, 0.0 ) ),
      ( Data : ( 0.8, 0.8, 0.8 ) ),
      ( Data : ( 0.5, 0.5, 0.5 ) ),
      ( Data : ( 0.0, 0.0, 1.0 ) ),
      ( Data : ( 0.0, 1.0, 0.0 ) ),
      ( Data : ( 0.0, 1.0, 1.0 ) ),
      ( Data : ( 1.0, 0.0, 0.0 ) ),
      ( Data : ( 1.0, 0.0, 1.0 ) ),
      ( Data : ( 1.0, 1.0, 0.0 ) ),
      ( Data : ( 1.0, 1.0, 1.0 ) )
      );

const GLFloatColors4 : array[0..15] of TGLFloatColor4 = (
      ( Data : ( 0.0, 0.0, 0.0, 1.0 ) ),
      ( Data : ( 0.0, 0.0, 0.6, 1.0 ) ),
      ( Data : ( 0.0, 0.6, 0.0, 1.0 ) ),
      ( Data : ( 0.0, 0.6, 0.6, 1.0 ) ),
      ( Data : ( 0.6, 0.0, 0.0, 1.0 ) ),
      ( Data : ( 0.6, 0.0, 0.6, 1.0 ) ),
      ( Data : ( 0.6, 0.6, 0.0, 1.0 ) ),
      ( Data : ( 0.8, 0.8, 0.8, 1.0 ) ),
      ( Data : ( 0.5, 0.5, 0.5, 1.0 ) ),
      ( Data : ( 0.0, 0.0, 1.0, 1.0 ) ),
      ( Data : ( 0.0, 1.0, 0.0, 1.0 ) ),
      ( Data : ( 0.0, 1.0, 1.0, 1.0 ) ),
      ( Data : ( 1.0, 0.0, 0.0, 1.0 ) ),
      ( Data : ( 1.0, 0.0, 1.0, 1.0 ) ),
      ( Data : ( 1.0, 1.0, 0.0, 1.0 ) ),
      ( Data : ( 1.0, 1.0, 1.0, 1.0 ) )
      );


const ColorNames : array[0..15] of AnsiString =
        ('BLACK',     'BLUE',     'GREEN',    'CYAN',        'RED',
         'MAGENTA',   'BROWN',    'LIGHTGRAY','DARKGRAY',    'LIGHTBLUE',
         'LIGHTGREEN','LIGHTCYAN','LIGHTRED', 'LIGHTMAGENTA','YELLOW',
         'WHITE');

const BBColorNames : array[0..15] of AnsiString =
        ('#333',   'navy',  'green',  'teal',   'maroon',
         'purple', 'olive', 'silver', 'gray',   'blue',
         'lime',   'aqua',  'red',    'fuchsia','yellow',
         'white');

const ColorCodes : array[0..15] of Char =
        ('D','b','g','c','r','v','n','l','d','B','G','C','R','V','y','L');

function IOGylph( aChar : Char; aColor : Byte ) : TIOGylph;

implementation

function IOGylph ( aChar : Char; aColor : Byte ) : TIOGylph;
begin
  Exit( Ord(aChar) + 256 * aColor );
end;

{ TIODriver }

procedure TIODriver.ClearInterrupts;
var iCount : Word;
begin
  FOnQuit := nil;
  for iCount := 0 to High(FInterrupts) do FInterrupts[iCount] := nil;
end;

procedure TIODriver.RegisterInterrupt ( aCode : TIOKeyCode; aInterrupt : TIOInterrupt );
begin
  FInterrupts[aCode] := aInterrupt;
end;

end.

