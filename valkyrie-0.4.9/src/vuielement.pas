{$INCLUDE valkyrie.inc}
unit vuielement;
interface
uses SysUtils, vnode, viotypes, vuitypes, vioevent, vgenerics;

type

TUIRoot = class;
TUIElement = class;
TUIElementEnumerator        = specialize TGNodeEnumerator<TUIElement>;
TUIElementReverseEnumerator = specialize TGNodeReverseEnumerator<TUIElement>;

TUINotifyEvent           = function ( aSender : TUIElement ) : Boolean of object;
TUIOnEventEvent          = function ( aSender : TUIElement; const event : TIOEvent ) : Boolean of object;
TUIOnKeyEventEvent       = function ( aSender : TUIElement; const event : TIOKeyEvent ) : Boolean of object;
TUIOnMouseEventEvent     = function ( aSender : TUIElement; const event : TIOMouseEvent ) : Boolean of object;
TUIOnMouseMoveEventEvent = function ( aSender : TUIElement; const event : TIOMouseMoveEvent ) : Boolean of object;
TUIOnSystemEventEvent    = function ( aSender : TUIElement; const event : TIOSystemEvent ) : Boolean of object;

TVariantHashMap   = specialize TGHashMap<Variant>;

TUIStyle = class( TVObject )
  constructor Create( const aStyleID : AnsiString );
  procedure Add( const aClass,aID : AnsiString; aValue : Variant );
  function GetVariant( const aClass, aID : AnsiString ) : Variant;
  destructor Destroy; override;
private
  FStyleID    : AnsiString;
  FVariantMap : TVariantHashMap;
public
  property Variants[ const aClass, aID : AnsiString ] : Variant read GetVariant; default;
end;

TUIElement = class( TNode, IIOElement )
  constructor Create( aParent : TUIElement; const aArea : TUIRect ); reintroduce;
  procedure BeforeDestruction; override;
  procedure AfterConstruction; override;
  procedure ParentChanged; override;

  procedure Render( aForceRedraw : Boolean );
  procedure OnRender; virtual;
  procedure OnRedraw; virtual;
  procedure OnUpdate( aTime : DWord ); virtual;

  function OnEvent( const event : TIOEvent ) : Boolean; virtual;
  function OnKeyDown( const event : TIOKeyEvent ) : Boolean; virtual;
  function OnKeyUp( const event : TIOKeyEvent ) : Boolean; virtual;
  function OnMouseDown( const event : TIOMouseEvent ) : Boolean; virtual;
  function OnMouseUp( const event : TIOMouseEvent ) : Boolean; virtual;
  function OnMouseMove( const event : TIOMouseMoveEvent ) : Boolean; virtual;
  function OnSystem( const event : TIOSystemEvent ) : Boolean; virtual;

  function ProcessEventUp( const event : TIOEvent; aProcessStop : TUIElement = nil ) : Boolean;
  function ProcessEventDown( const event : TIOEvent ) : Boolean;
  procedure SetVisible( aVisible : Boolean ); virtual;
  procedure SetEnabled( aEnabled : Boolean ); virtual;
  procedure SetCodedContent( aCodedContent : Boolean ); virtual;
  procedure SetEventFilter( aEventFilter  : TIOEventTypeSet ); virtual;
  function IsVisible : Boolean; virtual;
  function IsEnabled : Boolean; virtual;
  function GetEnumerator: TUIElementEnumerator;
  function Reverse : TUIElementReverseEnumerator;
  procedure SetArea( const aArea : TUIRect );
  procedure SetDim( const aDim : TUIPoint );
  procedure SetPos( const aPos : TUIPoint );
  procedure SetPadding( const aPadding : TUIPoint );
  function Contains( const aPoint : TUIPoint ) : Boolean;
  function GetElement( const aPoint : TUIPoint ) : TUIElement; virtual;
  function GetAvailableDim : TUIRect; virtual;
  function GetDimRect : TUIRect;
  destructor Destroy; override;
  procedure SetStyle( aStyle : TUIStyle ); virtual;
  procedure SetBackColor( const aValue : TUIColor ); virtual;
  procedure SetForeColor( const aValue : TUIColor ); virtual;
protected
  function DirtyAndTrue : Boolean;
  function GetStyleValue ( const aElementID : AnsiString ) : Variant;
  procedure RecalcDimensions; virtual;
  function FindRoot : TUIRoot;
protected
  FDimensions   : TUIPoint;
  FPosition     : TUIPoint;
  FPadding      : TUIPoint;
  FAbsolute     : TUIRect;
  FFullscreen   : Boolean;
  FEnabled      : Boolean;
  FVisible      : Boolean;
  FDirty        : Boolean;
  FRoot         : TUIRoot;
  FCodedContent : Boolean;
  FStyleClass   : AnsiString;
  FStyle        : TUIStyle;
  FForeColor    : TUIColor;
  FBackColor    : TUIColor;
  FEventFilter  : TIOEventTypeSet;

  FOnKeyDown    : TUIOnKeyEventEvent;
  FOnKeyUp      : TUIOnKeyEventEvent;
  FOnMouseDown  : TUIOnMouseEventEvent;
  FOnMouseUp    : TUIOnMouseEventEvent;
  FOnMouseMove  : TUIOnMouseMoveEventEvent;
  FOnSystem     : TUIOnSystemEventEvent;
public
  property Dirty        : Boolean    read FDirty        write FDirty;
  property Visible      : Boolean    read FVisible      write SetVisible;
  property Enabled      : Boolean    read FEnabled      write SetEnabled;
  property Fullscreen   : Boolean    read FFullscreen   write FFullscreen;

  property CodedContent : Boolean    read FCodedContent write SetCodedContent;
  property Root         : TUIRoot    read FRoot;
  property Padding      : TUIPoint   read FPadding      write SetPadding;
  property Dim          : TUIPoint   read FDimensions   write SetDim;
  property Pos          : TUIPoint   read FPosition     write SetPos;
  property AbsDim       : TUIRect    read FAbsolute;
  property Style        : TUIStyle   read FStyle        write SetStyle;
  property StyleClass   : AnsiString read FStyleClass;

  property StyleValue[ const aElementID : AnsiString ] : Variant read GetStyleValue;

  property ForeColor   : TUIColor        read FForeColor   write SetForeColor;
  property BackColor   : TUIColor        read FBackColor   write SetBackColor;
  property EventFilter : TIOEventTypeSet read FEventFilter write SetEventFilter;

  property OnKeyDownEvent    : TUIOnKeyEventEvent       write FOnKeyDown;
  property OnKeyUpEvent      : TUIOnKeyEventEvent       write FOnKeyUp;
  property OnMouseDownEvent  : TUIOnMouseEventEvent     write FOnMouseDown;
  property OnMouseUpEvent    : TUIOnMouseEventEvent     write FOnMouseUp;
  property OnMouseMoveEvent  : TUIOnMouseMoveEventEvent write FOnMouseMove;
  property OnSystemEvent     : TUIOnSystemEventEvent    write FOnSystem;
end;

type TUIRoot = class( TUIElement )
  constructor Create( aArea : TUIRect );
  procedure DeviceChanged; virtual;
  procedure ElementDestroyed( aElement : TUIElement ); virtual;
  procedure ParentChanged; override;
  procedure GrabInput( aEventRoot : TUIElement );
  function GetDefaultStyle : TUIStyle; virtual;
  function IsVisible : Boolean; override;
  function IsEnabled : Boolean; override;
protected
  FEventRoot : TUIElement;
end;

const UIPrintableChars : TUICharSet = [' '..'~'];

implementation

uses vutil;

{ TUIStyle }

constructor TUIStyle.Create( const aStyleID : AnsiString );
begin
  inherited Create;
  FStyleID    := aStyleID;
  FVariantMap := TVariantHashMap.Create;
end;

procedure TUIStyle.Add ( const aClass,aID : AnsiString; aValue : Variant ) ;
begin
  if aClass = ''
     then FVariantMap[ aID ] := aValue
     else FVariantMap[ aClass+'.'+aID ] := aValue;
end;

destructor TUIStyle.Destroy;
begin
  FreeAndNil( FVariantMap );
  inherited Destroy;
end;

function TUIStyle.GetVariant ( const aClass, aID : AnsiString ) : Variant;
var iSearchID : AnsiString;
begin
  iSearchID := aClass+'.'+aID;
  if FVariantMap.Exists( iSearchID ) then Exit( FVariantMap[ iSearchID ] );
  if FVariantMap.Exists( aID ) then Exit( FVariantMap[ aID ] );
  raise EIOException.Create( ClassName + ' : not element "'+aID+'" not found in style "'+FStyleID+'"!')
end;

{ TUIRoot }

constructor TUIRoot.Create ( aArea : TUIRect ) ;
begin
  inherited Create( nil, aArea );
  FDimensions := aArea.Dim;
  FPosition   := aArea.Pos;
  FAbsolute   := aArea;
  FEventRoot  := Self;
end;

procedure TUIRoot.DeviceChanged;
begin
  // no-op
end;

procedure TUIRoot.ElementDestroyed ( aElement : TUIElement );
begin
  if FEventRoot = aElement then FEventRoot := Self;
end;

procedure TUIRoot.ParentChanged;
begin
  // no-op
end;

procedure TUIRoot.GrabInput ( aEventRoot : TUIElement ) ;
begin
  if aEventRoot = nil then aEventRoot := Self;
  FEventRoot := aEventRoot;
end;

function TUIRoot.GetDefaultStyle : TUIStyle;
begin
  Exit( FStyle );
end;

function TUIRoot.IsVisible : Boolean;
begin
  Exit( FVisible );
end;

function TUIRoot.IsEnabled : Boolean;
begin
  Exit( FEnabled );
end;

{ TUIElement }

constructor TUIElement.Create ( aParent : TUIElement; const aArea : TUIRect ) ;
begin
  inherited Create;
  FEventFilter := [];

  FRoot       := nil;
  FStyle      := nil;
  FVisible    := True;
  FEnabled    := True;
  FFullscreen := False;

  FPosition     := aArea.Pos;
  FDimensions   := aArea.Dim;
  FAbsolute     := aArea;
  FPadding      := PointZero;

  FCodedContent := True;

  FOnKeyDown    := nil;
  FOnKeyUp      := nil;
  FOnMouseDown  := nil;
  FOnMouseUp    := nil;
  FOnMouseMove  := nil;
  FOnSystem     := nil;

  FForeColor    := 0;
  FBackColor    := 0;
  FStyleClass   := 'default';
  FDirty := True;

  if aParent <> nil then
    aParent.Add( Self )
  else
    if not (Self is TUIRoot) then
      raise EIOException.Create(ClassName+' : Element created without parent!')
end;

procedure TUIElement.BeforeDestruction;
begin
  inherited BeforeDestruction;
  if FRoot <> nil then FRoot.ElementDestroyed( Self );
end;

procedure TUIElement.AfterConstruction;
begin
  inherited AfterConstruction;
  if not (Self is TUIRoot) then SetStyle( FRoot.GetDefaultStyle );
end;

procedure TUIElement.ParentChanged;
begin
  FRoot := FindRoot;
  if FRoot = nil then raise EIOException.Create(ClassName+' : Element created without Root parent!');
  RecalcDimensions;
end;

procedure TUIElement.Render( aForceRedraw : Boolean );
var iElement : TUIElement;
begin
  if FDirty or aForceRedraw then OnRedraw;
  OnRender;
  for iElement in Self do
    if iElement.FEnabled and iElement.FVisible then
      iElement.Render( aForceRedraw );
end;

procedure TUIElement.OnRender;
begin
end;

procedure TUIElement.OnRedraw;
begin
  FDirty := False;
end;

procedure TUIElement.OnUpdate ( aTime : DWord );
var iElement : TUIElement;
    iVisible : Boolean;
begin
  for iElement in Self do
    if iElement.IsEnabled then
    begin
      iVisible := iElement.FVisible;
      iElement.OnUpdate( aTime );
      if iElement.FDirty and iVisible then
        FDirty := True;
    end;
end;

function TUIElement.OnEvent ( const event : TIOEvent ) : Boolean;
begin
  if not FEnabled then Exit( False );

  case event.EType of
    VEVENT_KEYDOWN    : if Assigned( FOnKeyDown )   and FOnKeyDown( Self, event.Key )        then Exit( True );
    VEVENT_KEYUP      : if Assigned( FOnKeyUp )     and FOnKeyUp( Self, event.Key )          then Exit( True );
    VEVENT_MOUSEDOWN  : if Assigned( FOnMouseDown ) and FOnMouseDown( Self, event.Mouse )    then Exit( True );
    VEVENT_MOUSEUP    : if Assigned( FOnMouseUp )   and FOnMouseUp( Self, event.Mouse )      then Exit( True );
    VEVENT_MOUSEMOVE  : if Assigned( FOnMouseMove ) and FOnMouseMove( Self, event.MouseMove )then Exit( True );
  end;

  if not (event.EType in FEventFilter) then Exit( False );

  case event.EType of
    VEVENT_KEYDOWN    : Exit( OnKeyDown( event.Key ) );
    VEVENT_KEYUP      : Exit( OnKeyUp( event.Key ) );
    VEVENT_MOUSEDOWN  : Exit( OnMouseDown( event.Mouse ) );
    VEVENT_MOUSEUP    : Exit( OnMouseUp( event.Mouse ) );
    VEVENT_MOUSEMOVE  : Exit( OnMouseMove( event.MouseMove ) );
    VEVENT_SYSTEM     : Exit( OnSystem( event.System ) );
  end;
  Exit( False );
end;

function TUIElement.OnKeyDown ( const event : TIOKeyEvent ) : Boolean;
begin
  Exit( False );
end;

function TUIElement.OnKeyUp ( const event : TIOKeyEvent ) : Boolean;
begin
  Exit( False );
end;

function TUIElement.OnMouseDown ( const event : TIOMouseEvent ) : Boolean;
begin
  Exit( False );
end;

function TUIElement.OnMouseUp ( const event : TIOMouseEvent ) : Boolean;
begin
  Exit( False );
end;

function TUIElement.OnMouseMove ( const event : TIOMouseMoveEvent ) : Boolean;
begin
  Exit( False );
end;

function TUIElement.OnSystem ( const event : TIOSystemEvent ) : Boolean;
begin
  Exit( False );
end;

function TUIElement.ProcessEventUp ( const event : TIOEvent; aProcessStop : TUIElement = nil ) : Boolean;
begin
  if aProcessStop = nil then aProcessStop := FRoot;
  if Parent <> aProcessStop then
    with TUIElement(Parent) do
      if OnEvent( event ) or ProcessEventUp( event ) then
        Exit( True );
  Exit( False );
end;

function TUIElement.ProcessEventDown ( const event : TIOEvent ) : Boolean;
var iElement : TUIElement;
begin
  if FEnabled then
  for iElement in Self.Reverse do
    if iElement.ProcessEventDown( event ) or iElement.OnEvent( event ) then
      Exit( True );
  Exit( False )
end;

procedure TUIElement.SetVisible ( aVisible : Boolean ) ;
begin
  FVisible := aVisible;
  FDirty := True;
end;

procedure TUIElement.SetEnabled ( aEnabled : Boolean ) ;
begin
  FEnabled := aEnabled;
  FDirty := True;
end;

procedure TUIElement.SetCodedContent ( aCodedContent : Boolean ) ;
begin
  FCodedContent := aCodedContent;
end;

procedure TUIElement.SetEventFilter ( aEventFilter  : TIOEventTypeSet ) ;
begin
  FEventFilter := aEventFilter;
end;

function TUIElement.IsVisible : Boolean;
begin
  Result := FVisible and ( ( Parent = nil ) or ( TUIElement(Parent).IsVisible ) );
end;

function TUIElement.IsEnabled : Boolean;
begin
  Result := FEnabled and ( ( Parent = nil ) or ( TUIElement(Parent).IsEnabled ) );
end;

function TUIElement.GetEnumerator : TUIElementEnumerator;
begin
  GetEnumerator.Create( Self );
end;

function TUIElement.Reverse : TUIElementReverseEnumerator;
begin
  Reverse.Create( Self );
end;

procedure TUIElement.SetArea ( const aArea : TUIRect ) ;
begin
  FPosition     := aArea.Pos;
  FDimensions   := aArea.Dim;
  FAbsolute     := aArea;
  RecalcDimensions;
end;

procedure TUIElement.SetDim ( const aDim : TUIPoint ) ;
begin
  FDimensions := aDim;
  RecalcDimensions;
end;

procedure TUIElement.SetPos ( const aPos : TUIPoint ) ;
begin
  FPosition := aPos;
  RecalcDimensions;
end;

procedure TUIElement.SetPadding ( const aPadding : TUIPoint ) ;
begin
  FPadding := aPadding;
  RecalcDimensions;
end;

function TUIElement.Contains ( const aPoint : TUIPoint ) : Boolean;
begin
  Exit( aPoint in FAbsolute );
end;

function TUIElement.GetElement ( const aPoint : TUIPoint ) : TUIElement;
var iElement : TUIElement;
    iQuery   : TUIElement;
begin
  if (not FVisible) or (not FEnabled) then Exit( nil );
  if (not FFullscreen) and (not Contains( aPoint )) then Exit( nil );
  for iElement in Self.Reverse do
  begin
    iQuery := iElement.GetElement( aPoint );
    if iQuery <> nil then Exit( iQuery );
  end;
  Exit( Self );
end;

function TUIElement.GetAvailableDim : TUIRect;
begin
  Exit( Rectangle( PointZero, FDimensions ).Shrinked( FPadding.X, FPadding.Y ) );
end;

function TUIElement.GetDimRect : TUIRect;
begin
  Exit( Rectangle( PointZero, FDimensions ) );
end;

procedure TUIElement.SetStyle ( aStyle : TUIStyle ) ;
begin
  FStyle := aStyle;
  FForeColor := StyleValue['fore_color'];
  FBackColor := StyleValue['back_color'];
  FDirty := True;
end;

destructor TUIElement.Destroy;
begin
  if FRoot <> nil then FRoot.ElementDestroyed( Self );
  inherited Destroy;
end;

procedure TUIElement.SetBackColor ( const aValue : TUIColor );
begin
  FBackColor := aValue;
  FDirty := True;
end;

procedure TUIElement.SetForeColor ( const aValue : TUIColor );
begin
  FForeColor := aValue;
  FDirty := True;
end;

function TUIElement.DirtyAndTrue : Boolean;
begin
  FDirty := True;
  Exit( True );
end;

function TUIElement.GetStyleValue ( const aElementID : AnsiString ) : Variant;
begin
  Exit( Style[ FStyleClass, aElementID ] );
end;

procedure TUIElement.RecalcDimensions;
var iElement : TUIElement;
    iAvailable : TUIRect;
begin
  if Parent <> nil then
  begin
    iAvailable := TUIElement(Parent).GetAvailableDim;
    if FDimensions = PointZero then FDimensions := iAvailable.Dim;

    FDimensions := Min( iAvailable.Dim, FDimensions );
    FAbsolute.Pos := FPosition + iAvailable.Pos;
    FAbsolute.Dim := FDimensions;
    FAbsolute += TUIElement(Parent).FAbsolute.Pos;
    for iElement in Self do
      iElement.RecalcDimensions;
  end
  else
    FAbsolute := GetAvailableDim;
  for iElement in Self do
    iElement.RecalcDimensions;
  FDirty := True;
end;

function TUIElement.FindRoot : TUIRoot;
begin
  if (Self is TUIRoot) then Exit( TUIRoot( Self ) );
  if Parent = nil then Exit( nil );
  Exit( TUIElement(Parent).FindRoot );
end;

end.

