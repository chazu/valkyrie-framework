{$INCLUDE valkyrie.inc}
// @abstract(Generic data structures for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @cvs($Author: chaos-dev $)
//
// TODO: TGArray<AnsiString>.IndexOf wont work, because of raw comparison.
//       Non-raw comparison can be done, but them objects don't work (no
//       operator detection. Either do a dedicated TStringArray or separate
//       TGBuiltInArray.
unit vgenerics;
interface
uses types, sysutils;

type ERangeError       = class(Exception);
     ECollisionError   = class(Exception);
     EUndefinedError   = class(Exception);


type TRawPointerArray = class(TObject)
  protected
    FData     : PByte;
    FCount    : Integer;
    FCapacity : Integer;
    FItemSize : Integer;
  protected
    procedure CopyItem( aFrom, aTo : Pointer ); virtual;
    procedure DisposeOf( aItem : Pointer ); virtual;
    procedure DisposeOfRange( aFromIndex, aToIndex: Integer );
    procedure Expand;
    procedure ExpandTo( aCapacity : Integer );
    function InternalPush( aItem : Pointer ) : Integer;
    function InternalPop : Integer;
    function InternalTop : Pointer;
    procedure InternalPut( aIndex : Integer; aItem : Pointer );
    function InternalGet( aIndex : Integer ) : Pointer;
    procedure SetCapacity( aCapacity : Integer );
    procedure SetCount( aCount : Integer );
  public
    constructor Create( aItemSize : Integer = sizeof(Pointer) );
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure Reserve( aCapacity : Integer );

    property Items[Index: Integer] : Pointer read InternalGet write InternalPut; default;
    property ItemSize : Integer read FItemSize;
    property Size : Integer read FCount;
    property Capacity : Integer read FCapacity;
  end;

type
  generic TGArrayEnumerator<T> = object
  protected
    FArray    : TRawPointerArray;
    FPosition : Integer;
    function GetCurrent: T;
  public
    constructor Create( aArray : TRawPointerArray );
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  generic TGArray<T> = class(TRawPointerArray)
  public type
    TTypeArrayEnumerator = specialize TGArrayEnumerator<T>;
    TTypeArray = array[0..(MaxInt div 1024)] of T;
    PTypeArray = ^TTypeArray;
    TType      = T;
    PType      = ^T;
  var protected
    procedure CopyItem( aFrom, aTo : Pointer ); override;
    procedure DisposeOf( aItem : Pointer ); override;
    function GetData : PTypeArray;
  public
    constructor Create;
    function Push( const aItem : T ) : Integer;
    function Pop : T;
    function Top : T;
    procedure Put( aIndex : Integer; const aItem : T );
    function Get( aIndex : Integer ) : T;
    function IndexOf( const aItem : T ) : Integer;
    function GetEnumerator: TTypeArrayEnumerator;

    property Items[ Index: Integer ] : T read Get write Put; default;
    property Data : PTypeArray read GetData;
    property Size : Integer read FCount write SetCount;
    property Capacity : Integer read FCapacity write SetCapacity;
  end;

  generic TGObjectArray<T> = class(TRawPointerArray)
  public type
    TTypeArrayEnumerator = specialize TGArrayEnumerator<T>;
    TTypeArray = array[0..(MaxInt div 1024)] of T;
    PTypeArray = ^TTypeArray;
    TType      = T;
    PType      = ^T;
  var protected
    FManaged : Boolean;
    procedure CopyItem( aFrom, aTo : Pointer ); override;
    procedure DisposeOf( aItem : Pointer ); override;
    function GetData : PTypeArray;
  public
    constructor Create( aManaged : Boolean = True );
    function Push( const aItem : T ) : Integer;
    function Pop : T;
    function Top : T;
    procedure Put( aIndex : Integer; const aItem : T );
    function Get( aIndex : Integer ) : T;
    function IndexOf( const aItem : T ) : Integer;
    function GetEnumerator: TTypeArrayEnumerator;

    property Items[ Index: Integer ] : T read Get write Put; default;
    property Data : PTypeArray read GetData;
    property Size : Integer read FCount write SetCount;
    property Capacity : Integer read FCapacity write SetCapacity;
  end;

  TRawHashMap = class;
  TRawHashMapBucket = class( TObject )
  private
    FValues   : PByte;
    FKeys     : array of AnsiString;
    FItemSize : Integer;
    FCapacity : Integer;
    FCount    : Integer;
    FHashMap  : TRawHashMap;
  public
    constructor Create( aHashMap : TRawHashMap );
    procedure Add( const aKey : AnsiString; aValue : Pointer );
    function FindIndex( const aKey : AnsiString ) : Integer;
    function GetValue( const aKey : AnsiString ) : Pointer;
    function GetValue( aIndex : Integer ) : Pointer;
    procedure SetValue( aIndex : Integer; aValue : Pointer );
    function Remove( const aKey : AnsiString ) : Boolean;
    function GetKey( aIndex : Integer ) : AnsiString;
    destructor Destroy; override;

    property Count : Integer read FCount;
  end;

  THashMapPolicy = ( HashMap_NoRaise, HashMap_RaiseCollision, HashMap_RaiseUndefined, HashMap_RaiseAll );

  TRawHashMap = class( TObject )
  protected
    FPolicy    : THashMapPolicy;
    FBucket    : array of TRawHashMapBucket;
    FBuckets   : Integer;
    FCount     : Integer;
    FItemSize  : Integer;
    FLastQuery : AnsiString;
    FLastValue : Pointer;
  protected
    procedure CopyItem( aFrom, aTo : Pointer ); virtual;
    procedure DisposeOf( aItem : Pointer ); virtual;
    function Query( const aKey : AnsiString ) : Pointer;
    function Hash( const aKey : AnsiString ) : Integer;
    function InternalAdd( const aKey : AnsiString; aValue : Pointer ) : Boolean;
  public
    function LinearGet( aBIdx, aIIdx : Integer ) : Pointer;
    function BucketSize( aBIdx : Integer ) : Integer;
    constructor Create( aPolicy : THashMapPolicy = HashMap_NoRaise; aBuckets : Integer = 94; aItemSize : Integer = sizeof(Pointer) );
    procedure Clear;
    destructor Destroy; override;
    function Exists( const aKey : AnsiString ) : Boolean;
    function Remove( const aKey : AnsiString ) : Boolean;

    property ItemSize : Integer read FItemSize;
    property Buckets : Integer read FBuckets;
    property Size : Integer read FCount;
  end;

type
  generic TGHashMapEnumerator<T> = class(TObject)
  protected
    FHashMap     : TRawHashMap;
    FBIdx, FIIdx : Integer;
    FISize       : Integer;
    FCurrent     : Pointer;
    function GetCurrent: T;
  public
    constructor Create( aHashMap : TRawHashMap );
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  generic TGHashMap<T> = class(TRawHashMap)
  public type
    TTypeHashMapEnumerator = specialize TGHashMapEnumerator<T>;
  var protected
    procedure CopyItem( aFrom, aTo : Pointer ); override;
    procedure DisposeOf( aItem : Pointer ); override;
  public
    constructor Create( aPolicy : THashMapPolicy = HashMap_NoRaise; aBuckets : Integer = 94 );
    procedure Put( const aKey : AnsiString; const aValue : T );
    function Get( const aKey : AnsiString ) : T;
    function Get( const aKey : AnsiString; const DefVal : T ) : T;

    function GetEnumerator: TTypeHashMapEnumerator;
    property Items[ const aKey : Ansistring ] : T read Get write Put; default;
  end;

  generic TGObjectHashMap<T> = class(TRawHashMap)
  public type
    TTypeHashMapEnumerator = specialize TGHashMapEnumerator<T>;
  var protected
    procedure CopyItem( aFrom, aTo : Pointer ); override;
    procedure DisposeOf( aItem : Pointer ); override;
  protected
    FManaged : Boolean;
  public
    constructor Create( aManaged : Boolean = True; aPolicy : THashMapPolicy = HashMap_NoRaise; aBuckets : Integer = 94 );
    procedure Put( const aKey : AnsiString; const aValue : T );
    function Get( const aKey : AnsiString ) : T;

    function GetEnumerator: TTypeHashMapEnumerator;
    property Items[ const aKey : Ansistring ] : T read Get write Put; default;
  end;

  type TRawRingBuffer = class(TObject)
  protected
    FData     : PByte;
    FCount    : Integer;
    FCapacity : Integer;
    FItemSize : Integer;
    FStart    : Integer;
  protected
    procedure CopyItem( aFrom, aTo : Pointer ); virtual;
    procedure DisposeOf( aItem : Pointer ); virtual;
    procedure DisposeOfRange( aFromIndex, aToIndex: Integer );
    function InternalPushFront( aItem : Pointer ) : Integer;
    function InternalPushBack( aItem : Pointer ) : Integer;
    function InternalPopFront : Integer;
    function InternalPopBack : Integer;
    function InternalFront : Pointer;
    function InternalBack : Pointer;
    procedure InternalPut( aIndex : Integer; aItem : Pointer );
    function InternalGet( aIndex : Integer ) : Pointer;
  public
    constructor Create( aCapacity : Integer; aItemSize : Integer = sizeof(Pointer) );
    destructor Destroy; override;
    procedure Clear; virtual;

    property Items[Index: Integer] : Pointer read InternalGet write InternalPut; default;
    property ItemSize : Integer read FItemSize;
    property Size     : Integer read FCount;
    property Capacity : Integer read FCapacity;
  end;

  generic TGRingBufferEnumerator<T> = object
  protected
    FBuffer   : TRawRingBuffer;
    FPosition : Integer;
    function GetCurrent: T;
  public
    constructor Create( aBuffer : TRawRingBuffer );
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  generic TGRingBufferReverseEnumerator<T> = object
  protected
    FBuffer   : TRawRingBuffer;
    FPosition : Integer;
    function GetCurrent: T;
  public
    constructor Create( aBuffer : TRawRingBuffer );
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
    // Allows to be used as enumerator
    function GetEnumerator : TGRingBufferReverseEnumerator;
  end;

  generic TGRingBuffer<T> = class(TRawRingBuffer)
  public type
    TTypeRingBufferEnumerator        = specialize TGRingBufferEnumerator<T>;
    TTypeRingBufferReverseEnumerator = specialize TGRingBufferReverseEnumerator<T>;
    TTypeRingBuffer = array[0..(MaxInt div 1024)] of T;
    PTypeRingBuffer = ^TTypeRingBuffer;
    TType      = T;
    PType      = ^T;
  var protected
    procedure CopyItem( aFrom, aTo : Pointer ); override;
    procedure DisposeOf( aItem : Pointer ); override;
    function GetData : PTypeRingBuffer;
  public
    constructor Create( aCapacity : Integer );
    function PushFront( const aItem : T ) : Integer;
    function PushBack( const aItem : T ) : Integer;
    function PopFront : T;
    function PopBack : T;
    function Front : T;
    function Back : T;
    procedure Put( aIndex : Integer; const aItem : T );
    function Get( aIndex : Integer ) : T;
    function GetEnumerator: TTypeRingBufferEnumerator;
    function Reverse: TTypeRingBufferReverseEnumerator;

    property Items[ Index: Integer ] : T read Get write Put; default;
    property Data : PTypeRingBuffer  read GetData;
    property Size : Integer          read FCount;
    property Capacity : Integer      read FCapacity;
  end;

  generic TGObjectRingBuffer<T> = class(TRawRingBuffer)
  public type
    TTypeRingBufferEnumerator        = specialize TGRingBufferEnumerator<T>;
    TTypeRingBufferReverseEnumerator = specialize TGRingBufferReverseEnumerator<T>;
    TTypeRingBuffer = array[0..(MaxInt div 1024)] of T;
    PTypeRingBuffer = ^TTypeRingBuffer;
    TType      = T;
    PType      = ^T;
  var protected
    FManaged : Boolean;
    procedure CopyItem( aFrom, aTo : Pointer ); override;
    procedure DisposeOf( aItem : Pointer ); override;
    function GetData : PTypeRingBuffer;
  public
    constructor Create( aCapacity : Integer; aManaged : Boolean = True );
    function PushFront( const aItem : T ) : Integer;
    function PushBack( const aItem : T ) : Integer;
    function PopFront : T;
    function PopBack : T;
    function Front : T;
    function Back : T;
    procedure Put( aIndex : Integer; const aItem : T );
    function Get( aIndex : Integer ) : T;
    function GetEnumerator: TTypeRingBufferEnumerator;
    function Reverse: TTypeRingBufferReverseEnumerator;

    property Items[ Index: Integer ] : T read Get write Put; default;
    property Data : PTypeRingBuffer  read GetData;
    property Size : Integer          read FCount;
    property Capacity : Integer      read FCapacity;
  end;

implementation

{ TPointerVector }

procedure TRawPointerArray.CopyItem ( aFrom, aTo : Pointer ) ;
begin
  System.Move( aFrom^, aTo^, FItemSize );
end;

procedure TRawPointerArray.DisposeOf ( aItem : Pointer ) ;
begin
  // no-op
end;

procedure TRawPointerArray.DisposeOfRange ( aFromIndex, aToIndex : Integer ) ;
var Current, Stop : PByte;
begin
  Current := FData + aFromIndex * FItemSize;
  Stop    := FData + aToIndex   * FItemSize;
  while ( true ) do
  begin
    DisposeOf( Current );
    if Current = Stop then Break;
    Current += FItemSize;
  end;
end;

procedure TRawPointerArray.Expand;
begin
  if FCapacity = 0
    then SetCapacity( 4 )
    else SetCapacity( FCapacity * 2 );
end;

procedure TRawPointerArray.ExpandTo ( aCapacity : Integer ) ;
var NewCapacity : Integer;
begin
  NewCapacity := 4;
  while NewCapacity < aCapacity do NewCapacity *= 2;
  SetCapacity( NewCapacity );
end;

function TRawPointerArray.InternalPush ( aItem : Pointer ) : Integer;
begin
  if FCount = FCapacity then Expand;
  CopyItem( aItem, FData+FCount*FItemSize );
  Inc( FCount );
  Exit( FCount );
end;

function TRawPointerArray.InternalPop : Integer;
begin
  if FCount = 0 then raise ERangeError.Create('Pop on empty array called!');
  Dec( FCount );
  DisposeOf( FData + FCount*FItemSize  );
  Exit( FCount );
end;

function TRawPointerArray.InternalTop : Pointer;
begin
  if FCount = 0 then raise ERangeError.Create('Top on empty array called!');
  Exit( FData + (FCount-1)*FItemSize );
end;

procedure TRawPointerArray.InternalPut( aIndex : Integer; aItem : Pointer );
var Target : PByte;
begin
  if aIndex >= FCapacity then ExpandTo( aIndex+1 );
  if aIndex >= FCount then SetCount( aIndex+1 );
  Target := FData+aIndex*FItemSize;
  CopyItem( aItem, Target );
end;

function TRawPointerArray.InternalGet( aIndex : Integer ) : Pointer;
begin
  if aIndex >= FCount then raise ERangeError.Create('Get called out of array range!');
  Exit( FData+aIndex*FItemSize );
end;

constructor TRawPointerArray.Create ( aItemSize : Integer ) ;
begin
  inherited Create;
  FItemSize := aItemSize;
  FCount    := 0;
  FCapacity := 0;
  FData     := nil;
end;

destructor TRawPointerArray.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TRawPointerArray.Clear;
begin
  if Assigned(FData) then
  begin
    SetCount( 0 );
    SetCapacity( 0 );
  end;
end;

procedure TRawPointerArray.Reserve ( aCapacity : Integer ) ;
begin
  if (aCapacity > FCapacity) then SetCapacity( aCapacity );
end;

procedure TRawPointerArray.SetCapacity ( aCapacity : Integer ) ;
begin
  if (aCapacity < FCount) then raise ERangeError.Create('SetCapacity call lower than Count!');
  if (aCapacity = FCapacity) then Exit;
  ReallocMem( FData, aCapacity * FItemSize );
  FillChar( (FData + (FCapacity * FItemSize))^, ( aCapacity - FCapacity) * FItemSize, #0 );
  FCapacity := aCapacity;
end;

procedure TRawPointerArray.SetCount ( aCount : Integer ) ;
begin
  if (aCount < 0) {or (NewCount > MaxListSize)} then
    raise ERangeError.Create('SetCount out of range!');
  if aCount > FCapacity then SetCapacity( aCount );
  if aCount < FCount then
    DisposeOfRange(aCount, FCount-1);
  FCount := aCount;
end;

{ TGPArrayEnumerator }

function TGArrayEnumerator.GetCurrent : T;
begin
  Result := T(FArray.Items[FPosition]^);
end;

constructor TGArrayEnumerator.Create ( aArray : TRawPointerArray ) ;
begin
  FArray    := aArray;
  FPosition := -1;
end;

function TGArrayEnumerator.MoveNext : Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FArray.Size;
end;

{ TGArray }

procedure TGArray.CopyItem( aFrom, aTo : Pointer );
begin
  T(aTo^) := T(aFrom^);
end;

procedure TGArray.DisposeOf ( aItem : Pointer );
begin
  Finalize(T(aItem^));
end;

function TGArray.GetData : PTypeArray;
begin
  Exit( PTypeArray(FData) )
end;

constructor TGArray.Create;
begin
  inherited Create( SizeOf( T ) );
end;

function TGArray.Push ( const aItem : T ) : Integer;
begin
  Exit( InternalPush( @aItem ) );
end;

function TGArray.Pop : T;
begin
  Pop := T(InternalTop^);
  InternalPop;
end;

function TGArray.Top : T;
begin
  Exit( T(InternalTop^) );
end;

procedure TGArray.Put ( aIndex : Integer; const aItem : T ) ;
begin
  InternalPut(aIndex, @aItem);
end;

function TGArray.Get ( aIndex : Integer ) : T;
begin
  Exit( T(InternalGet( aIndex )^) );
end;

function TGArray.IndexOf ( const aItem : T ) : Integer;
begin
  IndexOf := 0;
  while (IndexOf < FCount) and (CompareByte(PType(FData)[IndexOf],aItem,FItemSize) <> 0) do
    Inc(IndexOf);
  if IndexOf = FCount then
    IndexOf := -1;
end;

function TGArray.GetEnumerator : TTypeArrayEnumerator;
begin
  GetEnumerator.Create( Self );
end;

{ TGObjectArray }

procedure TGObjectArray.CopyItem( aFrom, aTo : Pointer );
begin
  if FManaged and (T(aTo^) <> T(nil)) then T( aTo^ ).Free;
  T(aTo^) := T(aFrom^);
end;

procedure TGObjectArray.DisposeOf ( aItem : Pointer ) ;
begin
  if FManaged and (T(aItem^) <> T(nil)) then T( aItem^ ).Free;
end;

function TGObjectArray.GetData : PTypeArray;
begin
  Exit( PTypeArray(FData) );
end;

constructor TGObjectArray.Create ( aManaged : Boolean ) ;
begin
  inherited Create( SizeOf( T ) );
  FManaged := aManaged;
end;

function TGObjectArray.Push ( const aItem : T ) : Integer;
begin
  Exit( InternalPush( @aItem ) );
end;

function TGObjectArray.Pop : T;
begin
  Pop := T(InternalTop^);
  InternalPop;
  if FManaged then Exit( T(nil) );
end;

function TGObjectArray.Top : T;
begin
  Exit( T(InternalTop^) );
end;

procedure TGObjectArray.Put ( aIndex : Integer; const aItem : T ) ;
begin
  InternalPut( aIndex, @aItem );
end;

function TGObjectArray.Get ( aIndex : Integer ) : T;
begin
  Exit( T(InternalGet( aIndex )^) );
end;

{$HINTS OFF}
function TGObjectArray.IndexOf ( const aItem : T ) : Integer;
begin
  IndexOf := 0;
  while (IndexOf < FCount) and (PType(FData)[IndexOf] <> aItem) do
    Inc(IndexOf);
  if IndexOf = FCount then
    IndexOf := -1;
end;
{$HINTS ON}

function TGObjectArray.GetEnumerator : TTypeArrayEnumerator;
begin
  GetEnumerator.Create( Self );
end;

{ TRawHashMapBucket }

constructor TRawHashMapBucket.Create ( aHashMap : TRawHashMap ) ;
begin
  inherited Create;
  FHashMap  := aHashMap;
  FValues   := nil;
  FCount    := 0;
  FCapacity := 0;
  FItemSize := aHashMap.ItemSize;
end;

procedure TRawHashMapBucket.Add ( const aKey : AnsiString; aValue : Pointer ) ;
var NewCapacity : Integer;
begin
  if FCount = FCapacity then
  begin
    if FCapacity = 0
      then NewCapacity := 4
      else NewCapacity := 2*FCapacity;
    ReallocMem( FValues, NewCapacity*FItemSize );
    SetLength( FKeys, NewCapacity );
    FillChar( (FValues + (FCapacity * FItemSize))^, ( NewCapacity - FCapacity) * FItemSize, #0 );
    FCapacity := NewCapacity;
  end;
  FKeys[ FCount ] := aKey;
  FHashMap.CopyItem(aValue, FValues+FCount*FItemSize);
  Inc(FCount);
end;

function TRawHashMapBucket.FindIndex ( const aKey : AnsiString ) : Integer;
var Idx : DWord;
begin
  FindIndex := -1;
  if FCount > 0 then
    for Idx := 0 to FCount-1 do
      if FKeys[ Idx ] = aKey then
        Exit( Idx );
end;

function TRawHashMapBucket.GetValue ( const aKey : AnsiString ) : Pointer;
var Idx : Integer;
begin
  if FCount > 0 then
    for Idx := 0 to FCount-1 do
      if FKeys[ Idx ] = aKey then
        Exit( FValues + Idx * FItemSize );
  Exit( nil );
end;

function TRawHashMapBucket.GetValue ( aIndex : Integer ) : Pointer;
begin
  Exit( FValues + aIndex * FItemSize );
end;

procedure TRawHashMapBucket.SetValue ( aIndex : Integer; aValue : Pointer );
begin
  FHashMap.CopyItem( aValue, FValues+aIndex*FItemSize );
end;

function TRawHashMapBucket.Remove ( const aKey : AnsiString ) : Boolean;
var Idx : Integer;
begin
  Idx := FindIndex( aKey );
  if Idx = -1 then Exit( False );
  Dec( FCount );
  FHashMap.DisposeOf( FValues+Idx*FItemSize  );
  if Idx <> FCount then
  begin
    System.Move( (FValues+FCount*FItemSize)^, (FValues+Idx*FItemSize)^, FItemSize );
    FKeys[ Idx ] := FKeys[ FCount ];
  end;
  Exit( True );
end;

function TRawHashMapBucket.GetKey ( aIndex : Integer ) : AnsiString;
begin
  Exit( FKeys[ aIndex ] );
end;

destructor TRawHashMapBucket.Destroy;
var Idx : Integer;
begin
  if FCount > 0 then
  begin
    for Idx := 0 to FCount-1 do
      FHashMap.DisposeOf( FValues + Idx * FItemSize );
  end;
  FreeMem( FValues );
  inherited Destroy;
end;

{ TRawHashMap }

procedure TRawHashMap.CopyItem ( aFrom, aTo : Pointer ) ;
begin
  System.Move(aFrom^, aTo^, FItemSize);
end;

procedure TRawHashMap.DisposeOf ( aItem : Pointer ) ;
begin
  // noop
end;

constructor TRawHashMap.Create ( aPolicy : THashMapPolicy; aBuckets : Integer; aItemSize : Integer ) ;
var Idx : Integer;
begin
  FPolicy    := aPolicy;
  FCount     := 0;
  FItemSize  := aItemSize;
  FBuckets   := aBuckets;
  FLastQuery := '';
  FLastValue := nil;

  SetLength( FBucket, FBuckets );
  for Idx := 0 to FBuckets-1 do
    FBucket[ Idx ] := nil;
end;

procedure TRawHashMap.Clear;
var Idx : Integer;
begin
  for Idx := 0 to FBuckets-1 do
    FreeAndNil( FBucket[ Idx ] );
  FCount     := 0;
  FLastQuery := '';
  FLastValue := nil;
end;

destructor TRawHashMap.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TRawHashMap.LinearGet( aBIdx, aIIdx : Integer ) : Pointer;
begin
  Exit( FBucket[ aBIdx ].GetValue( aIIdx ) );
end;

function TRawHashMap.BucketSize( aBIdx : Integer ) : Integer;
begin
  if FBucket[ aBIdx ] = nil then Exit( 0 );
  Exit( FBucket[ aBIdx ].Count );
end;

function TRawHashMap.Exists ( const aKey : AnsiString ) : Boolean;
begin
  Exit( Query( aKey ) <> nil );
end;

function TRawHashMap.Remove ( const aKey : AnsiString ) : Boolean;
var BIdx : Integer;
begin
  BIdx := Hash( aKey );
  if FBucket[ BIdx ] = nil then Exit( false );
  if FBucket[ BIdx ].Remove( aKey ) then
  begin
    Dec( FCount );
    Exit( True );
  end
  else
    Exit( False );
end;

function TRawHashMap.Query( const aKey : AnsiString ) : Pointer;
var BIdx : Integer;
begin
  if aKey = FLastQuery then Exit( FLastValue );
  BIdx := Hash( aKey );
  if FBucket[ BIdx ] = nil then Exit( nil );
  FLastValue := FBucket[ BIdx ].GetValue( aKey );
  Exit( FLastValue );
end;

function TRawHashMap.Hash ( const aKey : AnsiString ) : Integer;
var i : Byte;
begin
  FLastQuery := aKey;
  FLastValue := nil;
  Hash := 0;
  if Length( aKey ) > 0 then
  for i := 1 to Length(aKey) do
    Hash := ( Hash * 31 + Ord(aKey[i]) ) mod $FFFF;
  Hash := Hash mod FBuckets;
end;

function TRawHashMap.InternalAdd ( const aKey : AnsiString; aValue : Pointer ) : Boolean;
var BIdx : Integer;
    IIdx : Integer;
begin
  BIdx := Hash( aKey );
  FLastQuery := '';
  if FBucket[ BIdx ] = nil then
  begin
    FBucket[ BIdx ] := TRawHashMapBucket.Create(Self);
    IIdx := -1;
  end
  else
    IIdx := FBucket[ BIdx ].FindIndex( aKey );
  if IIdx <> -1 then
  begin
    if (FPolicy = HashMap_RaiseAll) or (FPolicy = HashMap_RaiseCollision)
      then raise ECollisionError.Create('Key '+aKey+' already exists in HashMap!')
      else
      begin
        FBucket[ BIdx ].SetValue( IIdx, aValue );
        Exit( False );
      end;
  end
  else
  begin
    Inc( FCount );
    FBucket[ BIdx ].Add( aKey, aValue );
    Exit( True );
  end;
end;

function TGHashMapEnumerator.GetCurrent: T;
begin
  Exit( T(FCurrent^) );
end;

constructor TGHashMapEnumerator.Create( aHashMap : TRawHashMap );
begin
  FHashMap := aHashMap;
  FBIdx    := -1;
  FIIdx    := -1;
  FISize   := 0;
end;

function TGHashMapEnumerator.MoveNext: Boolean;
begin
  Inc( FIIdx );
  if FIIdx = FISize then
  begin
    FISize := 0;
    FIIdx  := 0;
  end;
  while FISize = 0 do
  begin
    Inc(FBIdx);
    if FBIdx = FHashMap.Buckets then Exit( False );
    FISize := FHashMap.BucketSize( FBIdx );
  end;
  FCurrent := FHashMap.LinearGet( FBIdx, FIIdx );
  Exit( True );
end;

procedure TGHashMap.CopyItem( aFrom, aTo : Pointer );
begin
  T(aTo^) := T(aFrom^);
end;

procedure TGHashMap.DisposeOf( aItem : Pointer );
begin
  Finalize(T(aItem^));
end;

constructor TGHashMap.Create( aPolicy : THashMapPolicy = HashMap_NoRaise; aBuckets : Integer = 94 );
begin
  inherited Create( aPolicy, aBuckets, SizeOf(T) );
end;

procedure TGHashMap.Put( const aKey : AnsiString; const aValue : T );
begin
  InternalAdd( aKey, @aValue );
end;

function TGHashMap.Get( const aKey : AnsiString ) : T;
var Ptr : Pointer;
begin
  Ptr := Query( aKey );
  if Ptr <> nil
    then Exit( T(Ptr^) )
    else if (FPolicy = HashMap_RaiseAll) or (FPolicy = HashMap_RaiseUndefined)
      then raise EUndefinedError.Create('Key '+aKey+' undefined in HashMap!')
      else FillByte(Get, 0, sizeof(T));
end;

function TGHashMap.Get( const aKey : AnsiString; const DefVal : T ) : T;
var Ptr : Pointer;
begin
  Ptr := Query( aKey );
  if Ptr <> nil
    then Exit( T(Ptr^) )
    else Exit( DefVal );
end;

function TGHashMap.GetEnumerator: TTypeHashMapEnumerator;
begin
  GetEnumerator := TTypeHashMapEnumerator.Create( Self );
end;

procedure TGObjectHashMap.CopyItem( aFrom, aTo : Pointer );
begin
  if FManaged and (T(aTo^) <> T(nil)) then T( aTo^ ).Free;
  T(aTo^) := T(aFrom^);
end;

procedure TGObjectHashMap.DisposeOf( aItem : Pointer );
begin
  if FManaged and (T(aItem^) <> T(nil)) then
    T(aItem^).Free;
end;

constructor TGObjectHashMap.Create( aManaged : Boolean = True; aPolicy : THashMapPolicy = HashMap_NoRaise; aBuckets : Integer = 94 );
begin
  inherited Create( aPolicy, aBuckets, SizeOf(T) );
  FManaged := aManaged;
end;

procedure TGObjectHashMap.Put( const aKey : AnsiString; const aValue : T );
begin
  InternalAdd( aKey, @aValue );
end;

function TGObjectHashMap.Get( const aKey : AnsiString ) : T;
var Ptr : Pointer;
begin
  Ptr := Query( aKey );
  if Ptr <> nil
    then Exit( T(Ptr^) )
    else if (FPolicy = HashMap_RaiseAll) or (FPolicy = HashMap_RaiseUndefined)
      then raise EUndefinedError.Create('Key '+aKey+' undefined in HashMap!')
      else Exit( T(nil) );
end;

function TGObjectHashMap.GetEnumerator: TTypeHashMapEnumerator;
begin
  GetEnumerator := TTypeHashMapEnumerator.Create( Self );
end;

{ TRawRingBuffer }

procedure TRawRingBuffer.CopyItem ( aFrom, aTo : Pointer ) ;
begin
  System.Move( aFrom^, aTo^, FItemSize );
end;

procedure TRawRingBuffer.DisposeOf ( aItem : Pointer ) ;
begin
  // no-op
end;

procedure TRawRingBuffer.DisposeOfRange ( aFromIndex, aToIndex : Integer ) ;
var Current, Switch, Stop : PByte;
begin
  Current := FData + aFromIndex    * FItemSize;
  Stop    := FData + aToIndex      * FItemSize;
  Switch  := FData + (FCapacity-1) * FItemSize;
  while ( true ) do
  begin
    DisposeOf( Current );
    if Current = Stop then Break;
    if Current = Switch
      then Current := FData
      else Current += FItemSize;
  end;
end;

function TRawRingBuffer.InternalPushFront ( aItem : Pointer ) : Integer;
var Position : Integer;
begin
  if FStart = 0
    then Position := FCapacity-1
    else Position := FStart-1;
  CopyItem( aItem, FData+Position*FItemSize );
  FStart := Position;
  if FCount <> FCapacity then
    Inc( FCount );
  Exit( FCount );
end;

function TRawRingBuffer.InternalPushBack ( aItem : Pointer ) : Integer;
var Position : Integer;
begin
  Position := ( FStart + FCount ) mod FCapacity;
  CopyItem( aItem, FData+Position*FItemSize );
  if FCount = FCapacity then
    FStart := (FStart + 1) mod FCapacity
  else
    Inc( FCount );
  Exit( FCount );
end;

function TRawRingBuffer.InternalPopFront : Integer;
var Position : Integer;
begin
  if FCount = 0 then raise ERangeError.Create('PopFront on empty array called!');
  Dec( FCount );
  Position := ( FStart + 1 ) mod FCapacity;
  DisposeOf( FData + FStart*FItemSize  );
  FStart := Position;
  Exit( FCount );
end;

function TRawRingBuffer.InternalPopBack : Integer;
var Position : Integer;
begin
  if FCount = 0 then raise ERangeError.Create('PopBack on empty array called!');
  Dec( FCount );
  Position := ( FStart + FCount ) mod FCapacity;
  DisposeOf( FData + Position*FItemSize  );
  Exit( FCount );
end;


function TRawRingBuffer.InternalFront : Pointer;
begin
  if FCount = 0 then raise ERangeError.Create('Front on empty array called!');
  Exit( FData + FStart*FItemSize );
end;

function TRawRingBuffer.InternalBack : Pointer;
begin
  if FCount = 0 then raise ERangeError.Create('Front on empty array called!');
  Exit( FData + ( ( FStart + FCount - 1 ) mod FCapacity ) * FItemSize );
end;

procedure TRawRingBuffer.InternalPut ( aIndex : Integer; aItem : Pointer ) ;
var Position : Integer;
begin
  if aIndex >= 0 then
  begin
    if aIndex > FCount then ERangeError.Create('Put index out of range!');
    Position := ( FStart + aIndex ) mod FCapacity;
  end
  else
  begin
    if -aIndex > FCount then ERangeError.Create('Put index out of range!');
    Position := ( FStart + FCount + aIndex ) mod FCapacity;
  end;
  CopyItem( aItem, FData + Position*FItemSize );
end;

function TRawRingBuffer.InternalGet ( aIndex : Integer ) : Pointer;
var Position : Integer;
begin
  if aIndex >= 0 then
  begin
    if aIndex > FCount then ERangeError.Create('Get index out of range!');
    Position := ( FStart + aIndex ) mod FCapacity;
  end
  else
  begin
    if -aIndex > FCount then ERangeError.Create('Get index out of range!');
    Position := ( FStart + FCount + aIndex ) mod FCapacity;
  end;
  Exit( FData+Position*FItemSize );
end;

constructor TRawRingBuffer.Create ( aCapacity : Integer; aItemSize : Integer ) ;
begin
  FItemSize := aItemSize;
  FCount    := 0;
  FStart    := 0;
  FCapacity := aCapacity;
  FData     := nil;
  ReallocMem( FData, aCapacity * FItemSize );
  FillChar( FData^, FCapacity * FItemSize, #0 );
end;

destructor TRawRingBuffer.Destroy;
begin
  Clear;
  ReallocMem( FData, 0 );
  inherited Destroy;
end;

procedure TRawRingBuffer.Clear;
begin
  if FCount > 0 then
  begin
    DisposeOfRange( FStart, ( FStart + FCount - 1 ) mod FCapacity );
    FCount    := 0;
    FStart    := 0;
  end;
end;

{ TGRingBufferEnumerator }

function TGRingBufferEnumerator.GetCurrent : T;
begin
  Result := T(FBuffer.Items[FPosition]^);
end;

constructor TGRingBufferEnumerator.Create ( aBuffer : TRawRingBuffer ) ;
begin
  FBuffer   := aBuffer;
  FPosition := -1;
end;

function TGRingBufferEnumerator.MoveNext : Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FBuffer.Size;
end;

{ TGRingBufferReverseEnumerator }

function TGRingBufferReverseEnumerator.GetCurrent : T;
begin
  Result := T(FBuffer.Items[FPosition]^);
end;

constructor TGRingBufferReverseEnumerator.Create ( aBuffer : TRawRingBuffer ) ;
begin
  FBuffer := aBuffer;
  FPosition := 0;
end;

function TGRingBufferReverseEnumerator.MoveNext : Boolean;
begin
  Dec(FPosition);
  Result := -FPosition <= FBuffer.Size;
end;

function TGRingBufferReverseEnumerator.GetEnumerator : TGRingBufferReverseEnumerator;
begin
  Exit( Self );
end;

{ TGRingBuffer }

procedure TGRingBuffer.CopyItem ( aFrom, aTo : Pointer ) ;
begin
  T(aTo^) := T(aFrom^);
end;

procedure TGRingBuffer.DisposeOf ( aItem : Pointer ) ;
begin
  Finalize(T(aItem^));
end;

function TGRingBuffer.GetData : PTypeRingBuffer;
begin
  Exit( PTypeRingBuffer(FData) )
end;

constructor TGRingBuffer.Create ( aCapacity : Integer ) ;
begin
  inherited Create( aCapacity, SizeOf(T) );
end;

function TGRingBuffer.PushFront ( const aItem : T ) : Integer;
begin
  Exit( InternalPushFront( @aItem ) );
end;

function TGRingBuffer.PushBack ( const aItem : T ) : Integer;
begin
  Exit( InternalPushBack( @aItem ) );
end;

function TGRingBuffer.PopFront : T;
begin
  PopFront := T(InternalFront^);
  InternalPopFront;
end;

function TGRingBuffer.PopBack : T;
begin
  PopBack := T(InternalBack^);
  InternalPopBack;
end;

function TGRingBuffer.Front : T;
begin
  Exit( T(InternalFront^) );
end;

function TGRingBuffer.Back : T;
begin
  Exit( T(InternalBack^) );
end;

procedure TGRingBuffer.Put ( aIndex : Integer; const aItem : T ) ;
begin
  InternalPut(aIndex, @aItem);
end;

function TGRingBuffer.Get ( aIndex : Integer ) : T;
begin
  Exit( T(InternalGet( aIndex )^) );
end;

function TGRingBuffer.GetEnumerator : TTypeRingBufferEnumerator;
begin
  GetEnumerator.Create( Self );
end;

function TGRingBuffer.Reverse : TTypeRingBufferReverseEnumerator;
begin
  Reverse.Create( Self );
end;

{ TGObjectRingBuffer }

procedure TGObjectRingBuffer.CopyItem ( aFrom, aTo : Pointer ) ;
begin
  if FManaged and (T(aTo^) <> T(nil)) then T( aTo^ ).Free;
  T(aTo^) := T(aFrom^);
end;

procedure TGObjectRingBuffer.DisposeOf ( aItem : Pointer ) ;
begin
  if FManaged and (T(aItem^) <> T(nil)) then T( aItem^ ).Free;
end;

function TGObjectRingBuffer.GetData : PTypeRingBuffer;
begin
  Exit( PTypeRingBuffer(FData) );
end;

constructor TGObjectRingBuffer.Create ( aCapacity : Integer; aManaged : Boolean ) ;
begin
  inherited Create( aCapacity, SizeOf( T ) );
  FManaged := aManaged;
end;

function TGObjectRingBuffer.PushFront ( const aItem : T ) : Integer;
begin
  Exit( InternalPushFront( @aItem ) );
end;

function TGObjectRingBuffer.PushBack ( const aItem : T ) : Integer;
begin
  Exit( InternalPushBack( @aItem ) );
end;

function TGObjectRingBuffer.PopFront : T;
begin
  PopFront := T(InternalFront^);
  InternalPopFront;
  if FManaged then Exit( T(nil) );
end;

function TGObjectRingBuffer.PopBack : T;
begin
  PopBack := T(InternalBack^);
  InternalPopBack;
  if FManaged then Exit( T(nil) );
end;

function TGObjectRingBuffer.Front : T;
begin
  Exit( T(InternalFront^) );
end;

function TGObjectRingBuffer.Back : T;
begin
  Exit( T(InternalBack^) );
end;

procedure TGObjectRingBuffer.Put ( aIndex : Integer; const aItem : T ) ;
begin
  InternalPut(aIndex, @aItem);
end;

function TGObjectRingBuffer.Get ( aIndex : Integer ) : T;
begin
  Exit( T(InternalGet( aIndex )^) );
end;

function TGObjectRingBuffer.GetEnumerator : TTypeRingBufferEnumerator;
begin
  GetEnumerator.Create( Self );
end;

function TGObjectRingBuffer.Reverse : TTypeRingBufferReverseEnumerator;
begin
  Reverse.Create( Self );
end;

end.

