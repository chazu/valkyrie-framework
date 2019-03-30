{$INCLUDE valkyrie.inc}
unit vluastate;
interface

uses vlualibrary, typinfo, Variants, Classes, SysUtils, vrltools, vluatools, vluatype, vutil;

type
  ELuaStateException = class(EException);
  ELuaException      = vlualibrary.ELuaException;
  Plua_State         = vlualibrary.Plua_State;

const GLOBALSINDEX  = -10002;


type

{ TLuaState }

TLuaState = object
    constructor Init( State : Pointer );
    constructor Create;
    procedure Reset;
    function StackSize : LongInt;
    procedure Error( const Message : AnsiString );
    procedure PopRaise( PopAmount : Integer; const Message : AnsiString );
    function ToString( Index : Integer ) : AnsiString; overload;
    function ToInteger( Index : Integer ) : Integer; overload;
    function ToFloat( Index : Integer ) : Single; overload;
    function ToBoolean( Index : Integer ) : Boolean; overload;
    function ToChar( Index : Integer ) : Char;
    function ToFlags( Index : Integer ) : TFlags;
    function ToVariant( Index : Integer ) : Variant;
    function ToObject( Index : Integer ) : TObject;
    function ToObjectOrNil( Index : Integer ) : TObject;
    function ToStringArray( Index : Integer ) : TAnsiStringArray;
    function ToCoord( Index : Integer ) : TCoord2D;
    function ToArea( Index : Integer ) : TArea;

    function ToString( Index : Integer; const DValue : AnsiString ) : AnsiString; overload;
    function ToInteger( Index : Integer; DValue : Integer ) : Integer; overload;
    function ToFloat( Index : Integer;   DValue : Single  ) : Single; overload;
    function ToBoolean( Index : Integer; DValue : Boolean ) : Boolean; overload;

    function IsNil( Index : Integer ) : Boolean;
    function IsNumber( Index : Integer ) : Boolean;
    function IsBoolean( Index : Integer ) : Boolean;
    function IsString( Index : Integer ) : Boolean;
    function IsTable( Index : Integer ) : Boolean;
    function IsObject( Index : Integer ) : Boolean;
    function IsCoord( Index : Integer ) : Boolean;
    function IsArea( Index : Integer ) : Boolean;

    function GetField( Index : Integer; const Key : Variant ) : Variant;
    function GetField( Index : Integer; const Key, DValue : Variant ) : Variant;
    procedure SetField( Index : Integer; const Key, Value : Variant );
    function RawGetField( Index : Integer; const Key : Variant ) : Variant;
    function RawGetField( Index : Integer; const Key, DValue : Variant ) : Variant;
    procedure RawSetField( Index : Integer; const Key, Value : Variant );

    procedure Push( Value : Single ); overload;
    procedure Push( const Value : AnsiString ); overload;
    procedure Push( Value : Boolean ); overload;
    procedure Push( Value : LongInt ); overload;
    procedure Push( Value : ILuaReferencedObject ); overload;
    procedure Push(const Args: array of const); overload;
    procedure PushCoord( Value : TCoord2D );
    procedure PushArea( Value : TArea );
    procedure PushNil;
    procedure PushVariant( Value : Variant );
    procedure PushUserdata( Value : Pointer );
    procedure PushReference( Value : Integer );
    procedure PushNewLuaObject( const Name : AnsiString; const ConstructorParams : array of const );
    procedure RegisterEnumValues( EnumTypeInfo : PTypeInfo; UpperCase : Boolean = True; Index : Integer = GLOBALSINDEX );
    procedure SetPrototypeTable(Obj: ILuaReferencedObject; const FieldName : AnsiString = 'proto' );
    function  RunHook( Obj : ILuaReferencedObject; HookName : AnsiString; const Params : array of const ) : Variant;
    function  CallFunction( Name : AnsiString; const Params : array of const; idx : Integer = GLOBALSINDEX ) : Variant;
    destructor Done;
    procedure SubTableToStream( Obj : ILuaReferencedObject; const Name : AnsiString; OSt : TStream );
    procedure SubTableFromStream( Obj : ILuaReferencedObject; const Name : AnsiString; ISt : TStream );
    function GetLuaProperty( Obj : ILuaReferencedObject; const aPropertyName : AnsiString ) : Variant;
    procedure SetLuaProperty( Obj : ILuaReferencedObject; const aPropertyName : AnsiString; aValue : Variant );

    // Register raw function
    procedure Register( const Name : AnsiString; Proc : lua_CFunction );
    // Register table function
    procedure Register( const LibName, Name : AnsiString; Proc : lua_CFunction );
    // Register table functions
    procedure Register( const libname : AnsiString; const lr : PluaL_Reg );

protected
    procedure PushPrototypeTable( Obj : ILuaReferencedObject );
  protected
    FState      : Pointer;
    FOwner      : Boolean;
    FStartStack : Integer;
  public
    property Stack[ Index : Integer ] : Variant read ToVariant;
  end;

implementation

uses vdebug, vluaext;

{ TLuaState }

constructor TLuaState.Init(State: Pointer);
begin
  FState      := State;
  FOwner      := False;
  FStartStack := lua_gettop( FState );
end;

constructor TLuaState.Create;
begin
  FState := lua_open();
end;

procedure TLuaState.Reset;
begin
  lua_settop( FState, FStartStack );
end;

function TLuaState.StackSize: LongInt;
begin
  Exit( lua_gettop( FState ) );
end;

procedure TLuaState.Error(const Message: AnsiString);
begin
  luaL_error( FState, PChar(Message));
end;

procedure TLuaState.PopRaise(PopAmount: Integer; const Message: AnsiString);
begin
  lua_pop( FState, PopAmount );
  raise ELuaStateException.Create(Message);
end;

function TLuaState.ToString(Index: Integer): AnsiString;
begin
  Exit( lua_tostring( FState, Index ) );
end;

function TLuaState.ToInteger(Index: Integer): Integer;
begin
  Exit( lua_tointeger( FState, Index ) );
end;

function TLuaState.ToFloat(Index: Integer): Single;
begin
  Exit( lua_tonumber( FState, Index ) );
end;

function TLuaState.ToBoolean(Index: Integer): Boolean;
begin
  Exit( lua_toboolean( FState, Index ) );
end;

function TLuaState.ToVariant( Index : Integer ): Variant;
begin
  Exit( vlua_tovariant( FState, Index ) );
end;

function TLuaState.ToChar( Index: Integer ): Char;
begin
  Exit( vlua_tochar( FState, Index ) );
end;

function TLuaState.ToFlags( Index: Integer ): TFlags;
begin
  Exit( vlua_toflags_flat( FState, Index ) );
end;

function TLuaState.ToObject(Index: Integer): TObject;
begin
  ToObject := vlua_toobject( FState, Index );
  if ToObject = nil then Error( 'Object expected as parameter '+IntToStr(Index)+'!');
end;

function TLuaState.ToObjectOrNil(Index: Integer): TObject;
begin
  ToObjectOrNil := vlua_toobject( FState, Index );
end;

function TLuaState.ToStringArray(Index: Integer): TAnsiStringArray;
begin
  Exit( vlua_tostringarray( FState, Index ) );
end;

function TLuaState.ToCoord(Index: Integer): TCoord2D;
begin
  Exit( vlua_tocoord( FState, lua_absindex( FState, Index ) ) );
end;

function TLuaState.ToArea(Index: Integer): TArea;
begin
  Exit( vlua_toarea( FState, lua_absindex( FState, Index ) ) );
end;

function TLuaState.ToString(Index: Integer; const DValue: AnsiString
  ): AnsiString;
begin
  if lua_type( FState, Index ) = LUA_TSTRING
     then Exit( lua_tostring( FState, Index ) )
     else Exit( DValue );
end;

function TLuaState.ToInteger(Index: Integer; DValue: Integer): Integer;
begin
  if lua_type( FState, Index ) = LUA_TNUMBER
     then Exit( lua_tointeger( FState, Index ) )
     else Exit( DValue );
end;

function TLuaState.ToFloat(Index: Integer; DValue: Single): Single;
begin
  if lua_type( FState, Index ) = LUA_TNUMBER
     then Exit( lua_tonumber( FState, Index ) )
     else Exit( DValue );
end;

function TLuaState.ToBoolean(Index: Integer; DValue: Boolean): Boolean;
begin
  if lua_type( FState, Index ) = LUA_TBOOLEAN
     then Exit( lua_toboolean( FState, Index ) )
     else Exit( DValue );
end;

function TLuaState.IsNil(Index: Integer): Boolean;
begin
  Exit( lua_isnil( FState, Index ) or lua_isnone( FState, Index ) );
end;

function TLuaState.IsNumber(Index: Integer): Boolean;
begin
  Exit( lua_type( FState, Index ) = LUA_TNUMBER );
end;

function TLuaState.IsBoolean(Index: Integer): Boolean;
begin
  Exit( lua_type( FState, Index ) = LUA_TBOOLEAN );
end;

function TLuaState.IsString(Index: Integer): Boolean;
begin
  Exit( lua_type( FState, Index ) = LUA_TSTRING );
end;

function TLuaState.IsTable(Index: Integer): Boolean;
begin
  Exit( lua_type( FState, Index ) = LUA_TTABLE );
end;

function TLuaState.IsObject(Index: Integer): Boolean;
begin
  Exit( vlua_isobject( FState, Index ) );
end;

function TLuaState.IsCoord(Index: Integer): Boolean;
begin
  Exit( vlua_iscoord( FState, lua_absindex( FState, Index ) ) );
end;

function TLuaState.IsArea(Index: Integer): Boolean;
begin
  Exit( vlua_isarea( FState, lua_absindex( FState, Index ) ) );
end;

function TLuaState.GetField(Index: Integer; const Key: Variant): Variant;
begin
  Index := lua_absindex( FState, Index );
  vlua_pushvariant( FState, Key );
  lua_gettable( FState, Index );
  if lua_isnil( FState, -1 ) then PopRaise( 1, 'TLuaState.GetField - key '+Key+' not present in table!' );
  GetField := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

function TLuaState.GetField(Index: Integer; const Key, DValue: Variant
  ): Variant;
begin
  Index := lua_absindex( FState, Index );
  vlua_pushvariant( FState, Key );
  lua_gettable( FState, Index );
  if lua_isnil( FState, -1 )
     then GetField := DValue
     else GetField := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

procedure TLuaState.SetField(Index: Integer; const Key, Value: Variant);
begin
  Index := lua_absindex( FState, Index );
  vlua_pushvariant( FState, Key );
  vlua_pushvariant( FState, Value );
  lua_settable( FState, Index );
end;

function TLuaState.RawGetField(Index: Integer; const Key: Variant): Variant;
begin
  Index := lua_absindex( FState, Index );
  vlua_pushvariant( FState, Key );
  lua_rawget( FState, Index );
  if lua_isnil( FState, -1 ) then PopRaise( 1, 'TLuaState.GetField - key '+Key+' not present in table!' );
  RawGetField := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

function TLuaState.RawGetField(Index: Integer; const Key, DValue: Variant
  ): Variant;
begin
  Index := lua_absindex( FState, Index );
  vlua_pushvariant( FState, Key );
  lua_rawget( FState, Index );
  if lua_isnil( FState, -1 )
     then RawGetField := DValue
     else RawGetField := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

procedure TLuaState.RawSetField(Index: Integer; const Key, Value: Variant);
begin
  Index := lua_absindex( FState, Index );
  vlua_pushvariant( FState, Key );
  vlua_pushvariant( FState, Value );
  lua_rawset( FState, Index );
end;

procedure TLuaState.Push(Value: Single);
begin
  lua_pushnumber( FState, Value );
end;

procedure TLuaState.Push(const Value: AnsiString);
begin
  lua_pushansistring( FState, Value );
end;

procedure TLuaState.Push(Value: Boolean);
begin
  lua_pushboolean( FState, Value );
end;

procedure TLuaState.Push(Value: LongInt);
begin
  lua_pushinteger( FState, Value );
end;

procedure TLuaState.Push(Value: ILuaReferencedObject);
begin
  if Value = nil
     then lua_pushnil( FState )
     else lua_rawgeti( FState, LUA_REGISTRYINDEX, Value.GetLuaIndex );
end;

procedure TLuaState.PushNil;
begin
  lua_pushnil( FState );
end;

procedure TLuaState.PushVariant(Value: Variant);
begin
  vlua_pushvariant( FState, Value );
end;

procedure TLuaState.PushUserdata(Value: Pointer);
begin
  lua_pushlightuserdata( FState, Value );
end;

procedure TLuaState.PushReference(Value: Integer);
begin
  lua_rawgeti( FState, LUA_REGISTRYINDEX, Value );
end;

procedure TLuaState.PushNewLuaObject(const Name: AnsiString;
  const ConstructorParams: array of const);
begin
  lua_getglobal( FState, Name );
  lua_pushansistring( FState, 'new' );
  lua_rawget( FState, -2 );
  lua_insert( FState, -2 ); // swap table,function
  lua_pop( FState, 1 ); // pop table
  vlua_push( FState, ConstructorParams );
  if lua_pcall( FState, High( ConstructorParams ) + 1, 1, 0 ) <> 0 then
    PopRaise( 1, 'Lua constructor error : '+lua_tostring( FState, -1) );
  // leave the object on stack
end;

procedure TLuaState.RegisterEnumValues(EnumTypeInfo: PTypeInfo; UpperCase : Boolean; Index : Integer );
begin
  vlua_registerenumvalues( FState, Index, EnumTypeInfo, UpperCase );
end;

procedure TLuaState.Push(const Args: array of const);
begin
  vlua_push( FState, Args );
end;

procedure TLuaState.PushCoord(Value: TCoord2D);
begin
  vlua_pushcoord( FState, Value );
end;

procedure TLuaState.PushArea(Value: TArea);
begin
  vlua_pusharea( FState, Value );
end;

function TLuaState.RunHook(Obj: ILuaReferencedObject; HookName: AnsiString;
  const Params: array of const): Variant;
var Count : DWord;
begin
  PushPrototypeTable( Obj );

  lua_pushansistring( FState, HookName );
  lua_rawget( FState, -2 );
  if not lua_isfunction( FState, -1) then PopRaise( 3, Obj.GetProtoTable+'['+Obj.GetID+'].'+HookName+' not found!');

  lua_rawgeti(FState, LUA_REGISTRYINDEX, Obj.GetLuaIndex);
  if not lua_istable( FState, -1 ) then PopRaise( 4, 'Object not found!');

  Count := High( Params ) + 2;
  Push( Params );

  if lua_pcall( FState, Count, 1, 0 ) <> 0 then PopRaise( 3, 'Lua error : '+lua_tostring( FState, -1 ) );

  RunHook := vlua_tovariant( FState, -1 );
  lua_pop( FState, 2 );
end;

function TLuaState.CallFunction( Name : AnsiString;
    const Params : array of const; idx : Integer = GLOBALSINDEX ) : Variant;
var Index : Integer;
begin
  Index := lua_absindex( FState, idx );
  lua_pushansistring( FState, Name );
  lua_rawget( FState, Index );
  if not lua_isfunction( FState, -1) then PopRaise( 1, Name+' not found!');

  Push( Params );

  if lua_pcall( FState, High( Params ) + 1, 1, 0 ) <> 0 then PopRaise( 1, 'Lua error : '+lua_tostring( FState, -1) );
  CallFunction := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

procedure TLuaState.SubTableToStream(Obj: ILuaReferencedObject;
  const Name: AnsiString; OSt: TStream);
begin
  lua_rawgeti( FState, LUA_REGISTRYINDEX, Obj.GetLuaIndex );
  lua_getfield( FState, -1, PChar(Name) );
  if not lua_istable( FState, -1 ) then PopRaise( 1, Name+' is not a valid table!');
  vlua_tabletostream( FState, -1, Ost );
  lua_pop( FState, 2 );
end;

procedure TLuaState.SubTableFromStream(Obj: ILuaReferencedObject;
  const Name: AnsiString; ISt: TStream);
begin
  lua_rawgeti( FState, LUA_REGISTRYINDEX, Obj.GetLuaIndex );
  lua_getfield( FState, -1, PChar(Name) );
  if not lua_istable( FState, -1 ) then PopRaise( 1, Name+' is not a valid table!');
  vlua_tablefromstream( FState, -1, Ist );
  lua_pop( FState, 2 );
end;

function TLuaState.GetLuaProperty ( Obj : ILuaReferencedObject; const aPropertyName : AnsiString ) : Variant;
begin
  Push( Obj );
  lua_getfield( FState, -1, '__props' );
  if not lua_istable( FState, -1 ) then PopRaise( 2, 'Object has no __props!');
  lua_getfield( FState, -1, PChar(aPropertyName) );
  GetLuaProperty := vlua_tovariant( FState, -1 );
  lua_pop( FState, 3 );
end;

procedure TLuaState.SetLuaProperty ( Obj : ILuaReferencedObject; const aPropertyName : AnsiString; aValue : Variant ) ;
begin
  Push( Obj );
  lua_getfield( FState, -1, '__props' );
  if not lua_istable( FState, -1 ) then PopRaise( 2, 'Object has no __props!');
  vlua_pushvariant( FState, aValue );
  lua_setfield( FState, -2, PChar(aPropertyName) );
  lua_pop( FState, 2 );
end;

procedure TLuaState.Register(const Name: AnsiString; Proc: lua_CFunction);
begin
  vlua_register( FState, name, proc );
end;

procedure TLuaState.Register(const LibName, Name: AnsiString; Proc: lua_CFunction);
begin
  vlua_register( FState, libname, name, proc );
end;

procedure TLuaState.Register(const libname: AnsiString; const lr: PluaL_Reg);
begin
  vlua_register( FState, libname, lr );
end;

procedure TLuaState.SetPrototypeTable(Obj: ILuaReferencedObject; const FieldName : AnsiString = 'proto' );
begin
  Push( Obj );
  lua_pushansistring( FState, FieldName );
  PushPrototypeTable( Obj );
  lua_rawset( FState, -3 );
  lua_pop( FState, 1 );
end;

destructor TLuaState.Done;
begin
  if FOwner then lua_close( FState );
end;

procedure TLuaState.PushPrototypeTable(Obj: ILuaReferencedObject);
begin
  lua_getglobal( FState, Obj.GetProtoTable );
  if not lua_istable( FState, -1 ) then PopRaise( 1, Obj.GetProtoTable+' is not a valid table!');
  lua_pushansistring( FState, Obj.GetID );
  lua_gettable( FState, -2 );
  if not lua_istable( FState, -1 ) then PopRaise( 2, Obj.GetProtoTable+'['+Obj.GetID+'] is not a valid table!');
  lua_insert( FState, -2 ); // swap
  lua_pop( FState, 1 ); // free base table
end;

end.

