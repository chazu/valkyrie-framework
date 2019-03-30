{$INCLUDE valkyrie.inc}
unit vluavalue;
interface
uses Classes, SysUtils, Variants, vrltools, vutil, vlualibrary;

type TLuaValue = object
  constructor Create( L : PLua_State; aIndex : ShortInt );

  function ToString : AnsiString; overload;
  function ToInteger : Integer; overload;
  function ToFloat : Single; overload;
  function ToBoolean : Boolean; overload;
  function ToChar : Char; overload;
  function ToFlags : TFlags; overload;
  function ToVariant : Variant; overload;
  function ToObject : TObject; overload;
  function ToObjectOrNil : TObject; overload;
  function ToStringArray : TAnsiStringArray; overload;
  function ToCoord : TCoord2D; overload;
  function ToArea : TArea; overload;

  function ToString( const DValue : AnsiString ) : AnsiString; overload;
  function ToInteger( DValue : Integer ) : Integer; overload;
  function ToFloat( DValue : Single  ) : Single; overload;
  function ToBoolean( DValue : Boolean ) : Boolean; overload;
  function ToChar( DValue : Char ) : Char; overload;
  function ToFlags( const DValue : TFlags ) : TFlags; overload;
  function ToVariant( const DValue : Variant ) : Variant; overload;
  function ToCoord( const DValue : TCoord2D ) : TCoord2D; overload;
  function ToArea( const DValue : TArea ) : TArea; overload;

  function IsNil : Boolean;
  function IsNumber : Boolean;
  function IsBoolean : Boolean;
  function IsString : Boolean;
  function IsTable : Boolean;
  function IsObject : Boolean;
  function IsCoord : Boolean;
  function IsArea : Boolean;

private
  FIndex : ShortInt;
  FType  : ShortInt;
  FState : PLua_State;
public
  property LuaType : ShortInt read FType;
  property Index : ShortInt read FIndex;
end;

implementation
uses vluaext, vluatools, vluatype;

{ TLuaValue }

constructor TLuaValue.Create ( L : PLua_State; aIndex : ShortInt ) ;
begin
  FState := L;
  FIndex := lua_absindex( L, aIndex );
  FType  := lua_type( L, FIndex );
end;

function TLuaValue.ToString : AnsiString;
begin
  Exit( lua_tostring( FState, FIndex ) );
end;

function TLuaValue.ToInteger : Integer;
begin
  Exit( lua_tointeger( FState, FIndex ) );
end;

function TLuaValue.ToFloat : Single;
begin
  Exit( lua_tonumber( FState, FIndex ) );
end;

function TLuaValue.ToBoolean : Boolean;
begin
  Exit( lua_toboolean( FState, FIndex ) );
end;

function TLuaValue.ToVariant : Variant;
begin
  Exit( vlua_tovariant( FState, FIndex ) );
end;

function TLuaValue.ToChar: Char;
begin
  Exit( vlua_tochar( FState, FIndex ) );
end;

function TLuaValue.ToFlags: TFlags;
begin
  Exit( vlua_toflags_flat( FState, FIndex ) );
end;

function TLuaValue.ToObject : TObject;
begin
  ToObject := vlua_toobject( FState, FIndex );
  if ToObject = nil then luaL_error( FState, 'Object expected!');
end;

function TLuaValue.ToObjectOrNil : TObject;
begin
  ToObjectOrNil := vlua_toobject( FState, FIndex );
end;

function TLuaValue.ToStringArray : TAnsiStringArray;
begin
  Exit( vlua_tostringarray( FState, FIndex ) );
end;

function TLuaValue.ToCoord : TCoord2D;
begin
  Exit( vlua_tocoord( FState, FIndex ) );
end;

function TLuaValue.ToArea : TArea;
begin
  Exit( vlua_toarea( FState, FIndex ) );
end;

function TLuaValue.ToString( const DValue: AnsiString ): AnsiString;
begin
  if FType = LUA_TSTRING
     then Exit( lua_tostring( FState, FIndex ) )
     else Exit( DValue );
end;

function TLuaValue.ToInteger( DValue: Integer ): Integer;
begin
  if FType = LUA_TNUMBER
     then Exit( lua_tointeger( FState, FIndex ) )
     else Exit( DValue );
end;

function TLuaValue.ToFloat( DValue: Single ): Single;
begin
  if FType = LUA_TNUMBER
     then Exit( lua_tonumber( FState, FIndex ) )
     else Exit( DValue );
end;

function TLuaValue.ToBoolean( DValue: Boolean ): Boolean;
begin
  if FType = LUA_TBOOLEAN
     then Exit( lua_toboolean( FState, FIndex ) )
     else Exit( DValue );
end;

function TLuaValue.ToChar( DValue : Char ) : Char; overload;
begin
  if vlua_ischar( FState, FIndex )
     then Exit( vlua_tochar( FState, FIndex ) )
     else Exit( DValue );
end;

function TLuaValue.ToFlags( const DValue : TFlags ) : TFlags; overload;
begin
  if (FType = LUA_TTABLE)
     then Exit( vlua_toflags_flat( FState, FIndex ) )
     else Exit( DValue );
end;

function TLuaValue.ToVariant( const DValue : Variant ) : Variant; overload;
begin
  Exit( vlua_tovariant( FState, FIndex, DValue ) );
end;

function TLuaValue.ToCoord( const DValue : TCoord2D ) : TCoord2D; overload;
begin
  if vlua_iscoord( FState, FIndex )
     then Exit( vlua_tocoord( FState, FIndex ) )
     else Exit( DValue )
end;

function TLuaValue.ToArea( const DValue : TArea ) : TArea; overload;
begin
  if vlua_isarea( FState, FIndex )
     then Exit( vlua_toarea( FState, FIndex ) )
     else Exit( DValue )
end;


function TLuaValue.IsNil : Boolean;
begin
  Exit( lua_isnil( FState, FIndex ) or lua_isnone( FState, FIndex ) );
end;

function TLuaValue.IsNumber : Boolean;
begin
  Exit( FType = LUA_TNUMBER );
end;

function TLuaValue.IsBoolean : Boolean;
begin
  Exit( FType = LUA_TBOOLEAN );
end;

function TLuaValue.IsString : Boolean;
begin
  Exit( FType = LUA_TSTRING );
end;

function TLuaValue.IsTable : Boolean;
begin
  Exit( FType = LUA_TTABLE );
end;

function TLuaValue.IsObject : Boolean;
begin
  Exit( vlua_isobject( FState, FIndex ) );
end;

function TLuaValue.IsCoord : Boolean;
begin
  Exit( vlua_iscoord( FState, FIndex ) );
end;

function TLuaValue.IsArea : Boolean;
begin
  Exit( vlua_isarea( FState, FIndex ) );
end;

end.

