{$INCLUDE valkyrie.inc}
unit vconuirl;
interface

uses Classes, SysUtils, vconui, vutil, vnode, viotypes, vioevent, vioconsole, vuitypes,
     vuielement, vuielements, vuiconsole, vrltools;

type TConUIHybridMenu = class( TConUIMenu )
  procedure Add( aItem : TUIMenuItem ); override;
  function OnKeyDown( const event : TIOKeyEvent ) : Boolean; override;
  procedure OnRedraw; override;
end;


type TConUIBarFullWindow = class( TUIElement )
  constructor Create( aParent : TUIElement; const aTitle, aFooter : TUIString );
  procedure SetStyle( aStyle : TUIStyle ); override;
  procedure OnRedraw; override;
  function OnCancel : Boolean; virtual;
  function OnKeyDown( const event : TIOKeyEvent ) : Boolean; override;
  function OnMouseDown( const event : TIOMouseEvent ) : Boolean; override;
protected
  FOnCancel    : TUINotifyEvent;
  FTitle       : TUIString;
  FFooter      : TUIString;
  FFrameChars  : AnsiString;
  FFrameColor  : TUIColor;
  FTitleColor  : TUIColor;
  FFooterColor : TUIColor;
public
  property OnCancelEvent : TUINotifyEvent write FOnCancel;
  property Footer : TUIString write FFooter;
end;

type TConUIPlotViewer = class( TUIElement )
  constructor Create( aParent : TUIElement; const aText : AnsiString; const aTextArea : TUIRect );
  procedure OnRedraw; override;
  procedure OnUpdate( aTime : DWord ); override;
  function OnKeyDown( const event : TIOKeyEvent ) : Boolean; override;
  function OnMouseDown( const event : TIOMouseEvent ) : Boolean; override;
protected
  FText      : TUIString;
  FTextArea  : TUIRect;
  FChunks    : TUIChunkList;
  FCharCount : DWord;
  FCharMax   : Integer;
  FStartTime : DWord;
  FSkip      : Boolean;
end;

type IConUIASCIIMap = interface
  function getASCII( const aCoord : TCoord2D ) : TIOGylph;
  function getColor( const aCoord : TCoord2D ) : TIOColor;
end;

type TConUIMapArea = class( TUIElement )
  constructor Create( aParent : TUIElement; aMap : IConUIASCIIMap = nil );
  constructor Create( aParent : TUIElement; aArea : TUIRect; aMap : IConUIASCIIMap = nil );
  procedure SetCenter( aCoord : TCoord2D );
  procedure SetShift( aShift : TUIPoint );
  procedure SetMap( aMap : IConUIASCIIMap );
  procedure Mark( aCoord : TCoord2D; aSign : char; aColor : byte );
  procedure ClearMarks;
  procedure OnRedraw; override;
  function Screen( aWorld : TCoord2D ) : TUIPoint; inline;
  function World( aScreen : TUIPoint ) : TCoord2D;  inline;
protected
  FMarkMap  : array of array of TIOGylph;
  FLength   : TUIPoint;
  FMap      : IConUIASCIIMap;
  FShift    : TUIPoint;
end;

implementation

uses math;

const Letters = 'abcdefghijklmnopqrstuvwxyz';

{ TConUIHybridMenu }

procedure TConUIHybridMenu.Add ( aItem : TUIMenuItem ) ;
begin
  aItem.Text := '[@<'+Letters[FCount+1]+'@>] '+ aItem.Text;
  inherited Add ( aItem ) ;
end;

function TConUIHybridMenu.OnKeyDown ( const event : TIOKeyEvent ) : Boolean;
var iSelection : Byte;
begin
  if (FCount > 0) and (event.ASCII in ['a'..Letters[FCount]]) then
  begin
    iSelection := (Ord(event.ASCII) - Ord('a')) + 1;
    SetSelected( iSelection );
    if FSelected = iSelection then OnConfirm;
    Exit( True );
  end;
  Result := inherited OnKeyDown ( event ) ;
end;

procedure TConUIHybridMenu.OnRedraw;
var iCon      : TUIConsole;
begin
  inherited OnRedraw;
  iCon.Init( TConUIRoot(FRoot).Renderer );
  if FSelected > 0 then
    iCon.DrawChar( FAbsolute.Pos + Point(-2, FSelected-1-FScroll),  FSelectedColor, '>' );
end;

constructor TConUIBarFullWindow.Create ( aParent : TUIElement; const aTitle,
  aFooter : TUIString ) ;
begin
  inherited Create( aParent, aParent.GetDimRect );
  FStyleClass := 'full_window';
  FEventFilter := [ VEVENT_KEYDOWN, VEVENT_MOUSEDOWN ];
  FFooter := aFooter;
  FTitle  := aTitle;
end;

procedure TConUIBarFullWindow.SetStyle ( aStyle : TUIStyle ) ;
begin
  inherited SetStyle ( aStyle ) ;

  FFrameChars := StyleValue[ 'frame_chars' ];
  FFrameColor := StyleValue[ 'frame_color' ];
  FTitleColor  := StyleValue[ 'title_color' ];
  FFooterColor := StyleValue[ 'footer_color' ];
end;

procedure TConUIBarFullWindow.OnRedraw;
var iCon   : TUIConsole;
    iTPos  : TUIPoint;
begin
  inherited OnRedraw;
  iCon.Init( TConUIRoot(FRoot).Renderer );
  iCon.ClearRect( FAbsolute, FBackColor );
  iCon.RawPrint( FAbsolute.TopLeft,    FFrameColor, StringOfChar(FFrameChars[1],FAbsolute.w+1) );
  iCon.RawPrint( FAbsolute.BottomLeft, FFrameColor, StringOfChar(FFrameChars[3],FAbsolute.w+1) );

  if FTitle <> '' then
  begin
    iTPos.Init( FAbsolute.x+(FAbsolute.w - Length( FTitle )) div 2, FAbsolute.y );
    iCon.Print( iTPos, FTitleColor, FBackColor, ' '+FTitle+' ', True );
  end;

  if FFooter <> '' then
  begin
    iTPos.Init( FAbsolute.x2-Length( FFooter )-2, FAbsolute.y2 );
    iCon.Print( iTPos, FFooterColor, FBackColor, '[ '+FFooter+' ]', True );
  end;
end;

function TConUIBarFullWindow.OnCancel : Boolean;
begin
  if Assigned( FOnCancel ) then Exit( FOnCancel( Self ) );
  Free;
  Exit( True );
end;

function TConUIBarFullWindow.OnKeyDown ( const event : TIOKeyEvent ) : Boolean;
begin
  if event.ModState <> [] then Exit( inherited OnKeyDown( event ) );
  case event.Code of
    VKEY_SPACE,
    VKEY_ESCAPE,
    VKEY_ENTER  : Exit( OnCancel );
  else Exit( inherited OnKeyDown( event ) );
  end;
end;

function TConUIBarFullWindow.OnMouseDown ( const event : TIOMouseEvent ) : Boolean;
begin
  if event.Button in [ VMB_BUTTON_LEFT, VMB_BUTTON_MIDDLE, VMB_BUTTON_RIGHT ] then
    OnCancel;
  Exit( True );
end;

constructor TConUIPlotViewer.Create ( aParent : TUIElement; const aText : AnsiString; const aTextArea : TUIRect ) ;
var i : DWord;
begin
  inherited Create( aParent, aParent.GetDimRect );
  FStyleClass  := 'plot_viewer';
  FEventFilter := [ VEVENT_KEYDOWN, VEVENT_MOUSEDOWN ];

  FText      := aText;
  FTextArea  := aTextArea;
  FCharCount := 0;
  FStartTime := 0;
  FSkip      := False;
  FCharMax   := 0;
end;

procedure TConUIPlotViewer.OnRedraw;
var iCon    : TUIConsole;
    i,ii,cc : LongInt;
    iChunk  : TUIChunk;
    iPos    : TUIPoint;
begin
  inherited OnRedraw;

  if FCharMax = 0 then
  begin
    FChunks    := TConUIRoot(FRoot).Console.Chunkify( FText, FTextArea.Dim, FForeColor );
    for i := 0 to High( FChunks ) do
      FCharMax += Length( FChunks[i].Content );
  end;

  iCon.Init( TConUIRoot(FRoot).Renderer );
  iCon.ClearRect( FAbsolute, Black );
  iPos := FTextArea.Pos;
  FCharCount := Min( FStartTime div 40, FCharMax );

  cc := FCharCount;
  ii := 0;
  i  := 0;
  repeat
    iChunk := FChunks[i];
    ii := Min( Length( iChunk.Content ), cc );
    if ii < Length( iChunk.Content ) then
      iChunk.Content := Copy( iChunk.Content, 1, ii );
    iCon.RawPrint( iPos+iChunk.Position, iChunk.Color, iChunk.Content );
    cc -= ii;
    Inc(i)
  until (cc = 0) or (i > High(FChunks));
end;

procedure TConUIPlotViewer.OnUpdate( aTime : DWord );
begin
  if FSkip
    then FStartTime += 20*aTime
    else FStartTime += aTime;

  TConUIRoot( FRoot ).NeedRedraw := True;
end;

function TConUIPlotViewer.OnKeyDown ( const event : TIOKeyEvent ) : Boolean;
begin
  if (not FSkip) and (Integer(FCharCount) < FCharMax) then
    FSkip := True
  else
    if event.Code in [ VKEY_ENTER, VKEY_ESCAPE, VKEY_SPACE ] then
      Free;

  Exit( True );
end;

function TConUIPlotViewer.OnMouseDown ( const event : TIOMouseEvent ) : Boolean;
begin
  if (not FSkip) and (Integer(FCharCount) < FCharMax) then
    FSkip := True
  else
    if event.Button in [ VMB_BUTTON_LEFT, VMB_BUTTON_MIDDLE, VMB_BUTTON_RIGHT ] then
      Free;

  Exit( True );
end;

{ TConUIMapArea }

constructor TConUIMapArea.Create ( aParent : TUIElement; aMap : IConUIASCIIMap ) ;
begin
  inherited Create( aParent, aParent.GetDimRect );
  FLength.Init(0,0);
  FShift.Init(0,0);
  SetMap(aMap);
  ClearMarks;
end;

constructor TConUIMapArea.Create ( aParent : TUIElement; aArea : TUIRect; aMap : IConUIASCIIMap ) ;
begin
  inherited Create( aParent, aArea );
  FLength.Init(0,0);
  FShift.Init(0,0);
  SetMap(aMap);
  ClearMarks;
end;

procedure TConUIMapArea.SetCenter( aCoord : TCoord2D ) ;
begin
  FShift.X := aCoord.X - FAbsolute.w div 2;
  FShift.Y := aCoord.Y - FAbsolute.h div 2;
end;

procedure TConUIMapArea.SetShift ( aShift : TUIPoint ) ;
begin
  FShift := aShift;
end;

procedure TConUIMapArea.SetMap ( aMap : IConUIASCIIMap ) ;
begin
  FMap := aMap;
end;

procedure TConUIMapArea.Mark( aCoord : TCoord2D; aSign : char; aColor : Byte );
var iPoint : TUIPoint;
begin
  iPoint := Screen(aCoord)-FAbsolute.Pos;
  if (iPoint.X < 0) or (iPoint.Y < 0) or (iPoint.X >= FAbsolute.w) or (iPoint.Y >= FAbsolute.h) then Exit;
  FMarkMap[iPoint.x,iPoint.y] := Ord(aSign) + 256*aColor;
end;

procedure TConUIMapArea.ClearMarks;
var x,y    : DWord;
    iReset : Boolean;
begin
  iReset := FLength <> FAbsolute.Dim;
  if iReset then SetLength( FMarkMap, FAbsolute.w );
  for x := 0 to FAbsolute.w-1 do
  begin
    if iReset then SetLength( FMarkMap[x],FAbsolute.h );
    for y := 0 to FAbsolute.h-1 do
       FMarkMap[x,y] := 0;
  end;
  FLength := FAbsolute.Dim;
end;

procedure TConUIMapArea.OnRedraw;
var x,y   : Word;
    iCon   : TUIConsole;
  procedure DrawTile( aScreen : TUIPoint );
  var iCoord   : TCoord2D;
      iPicture : TIOGylph;
  begin
    iCoord := World( aScreen );
//    if UIMAP_TRUECOLOR in FOptions
//      then Output.DrawPicture(sx,sy,FMap.getASCII(wx,wy),FMap.getColor(wx,wy))
    iPicture := FMap.getASCII( iCoord );
    iCon.DrawChar( aScreen, iPicture div 256, Char(iPicture mod 256) );
    iPicture := FMarkMap[aScreen.x-FAbsolute.Pos.x,aScreen.y-FAbsolute.Pos.y];
    if iPicture <> 0 then
      iCon.DrawChar( aScreen, iPicture div 256, Char(iPicture mod 256) );
  end;
begin
  inherited OnRedraw;
  iCon.Init( TConUIRoot(FRoot).Renderer );
  for x := FAbsolute.pos.x to FAbsolute.pos.x+FAbsolute.dim.x-1 do
    for y := FAbsolute.pos.y to FAbsolute.pos.y+FAbsolute.dim.y-1 do
      DrawTile(Point(x,y));
end;

function TConUIMapArea.Screen ( aWorld : TCoord2D ) : TUIPoint;
begin
  Screen := Point(aWorld.x,aWorld.y)-FShift+FAbsolute.pos-Point(1,1);
end;

function TConUIMapArea.World ( aScreen : TUIPoint ) : TCoord2D;
begin
  aScreen  := FShift+aScreen-FAbsolute.pos+Point(1,1);
  World.Create( aScreen.X, aScreen.Y );
end;


end.

