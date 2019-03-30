{$INCLUDE valkyrie.inc}
// @abstract(LuaGameNode class for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @cvs($Author: chaos-dev $)
//
//  @html <div class="license">
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the GNU Library General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or (at your
//  option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
//  for more details.
//
//  You should have received a copy of the GNU Library General Public License
//  along with this library; if not, write to the Free Software Foundation,
//  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//  @html </div>
//
// TODO - unwrap TLuaState calls for efficiency

unit vluagamenode;
interface
uses Classes, vnode, vutil, vluastate, vlua, vluanode;

type
TLuaGameNode = class;

TLuaGameNodeEnumerator = specialize TGNodeEnumerator< TLuaGameNode >;

TLuaGameNode = class( TLuaNode )
  // Standard constructor, zeroes all fields.
  constructor Create( const aID : AnsiString ); reintroduce;
  // Stream constructor, reads UID, and ID from stream, should be overriden.
  constructor CreateFromStream( Stream : TStream ); override;
  // Write Node to stream (UID and ID) should be overriden.
  procedure WriteToStream( Stream : TStream ); override;
  // Returns a property value from Lua __props of this instance
  function GetLuaProperty( const Index : AnsiString ) : Variant;
  // Sets a property value in Lua __props of this instance
  procedure SetLuaProperty( const Index : AnsiString; Value : Variant );
  // Returns a property value from Lua __props of this instance
  function GetLuaProtoValue( const Index : AnsiString ) : Variant;
  // destructor
  destructor Destroy; override;
  // Return enumerator
  function GetEnumerator : TLuaGameNodeEnumerator;
  // Runs a script from the registered table by id and with self
  function RunHook( Hook : Word; const Args : array of Const ) : Variant;
  // Returns whether the object has the passed hook
  function HasHook( Hook : Word ) : Boolean;
  // Returns whether the object has the passed flag
  function GetFlag( aFlag : Byte ) : Boolean;
  // Returns whether the object has the passed flag
  procedure SetFlag( aFlag : Byte; aValue : Boolean );
  // Register API -- WARNING - registers TableName metatable!
  class procedure RegisterLuaAPI( const TableName : AnsiString );
protected
  // Hooks
  FHooks : TFlags;
  // Flags
  FFlags : TFlags;
public
  // Lua Properties
  property LuaProperties[ const Index : AnsiString ] : Variant read GetLuaProperty write SetLuaProperty;
  // Lua Properties
  property LuaProto[ const Index : AnsiString ] : Variant read GetLuaProtoValue;
  // Flags property
  property Flags[ Index : Byte ] : Boolean read GetFlag write SetFlag;
  // Hooks property
  property Hooks[ Index : Word ] : Boolean read HasHook;
end;

implementation
uses vluasystem, vuid, vlualibrary, typinfo;

{ TLuaGameNode }

constructor TLuaGameNode.Create ( const aID : AnsiString ) ;
var Count : Byte;
begin
  inherited Create;
  if UIDs <> nil then FUID := UIDs.Register( Self );
  FID := aID;
  FHooks := [];
  FFlags := [];
  LuaSystem.State.SetPrototypeTable( Self, '__proto' );

  with TLuaTable.Create( LuaSystem.Lua, GetProtoTable, ID ) do
  try
    with TLuaClassInfo( LuaClassInfo ) do
    for Count := 0 to HookMax do
      if Count in HookSet then
        if isFunction(Hooks[ Count ]) then
          Include( FHooks, Count );
    FFlags := getFlags( 'flags' );
  finally
    Free;
  end;

end;

constructor TLuaGameNode.CreateFromStream ( Stream : TStream ) ;
begin
  inherited CreateFromStream ( Stream ) ;
  if ( UIDs <> nil ) and ( FUID <> 0 ) then
    UIDs.Register( Self, FUID );

  Stream.Read( FFlags, SizeOf(FFlags) );
  Stream.Read( FHooks, SizeOf(FHooks) );

  LuaSystem.State.SetPrototypeTable( Self, '__proto' );
  LuaSystem.State.SubTableFromStream( Self ,'__props', Stream );
end;

procedure TLuaGameNode.WriteToStream ( Stream : TStream ) ;
begin
  inherited WriteToStream ( Stream ) ;
  Stream.Write( FFlags, SizeOf(FFlags) );
  Stream.Write( FHooks, SizeOf(FHooks) );

  LuaSystem.State.SubTableToStream( Self ,'__props', Stream );
end;

function TLuaGameNode.GetLuaProperty ( const Index : AnsiString ) : Variant;
begin
  Exit( LuaSystem.State.GetLuaProperty( Self, Index ) );
end;

procedure TLuaGameNode.SetLuaProperty ( const Index : AnsiString; Value : Variant ) ;
begin
  LuaSystem.State.SetLuaProperty( Self, Index, Value );
end;

function TLuaGameNode.GetLuaProtoValue ( const Index : AnsiString ) : Variant;
begin
  Exit( LuaSystem.Get( [ GetProtoTable, ID, Index ] ) );
end;

destructor TLuaGameNode.Destroy;
begin
  inherited Destroy;
end;

function TLuaGameNode.GetEnumerator : TLuaGameNodeEnumerator;
begin
  GetEnumerator.Create(Self);
end;

function TLuaGameNode.RunHook ( Hook : Word; const Args : array of const ) : Variant;
begin
  if Hook in FHooks then
    RunHook := LuaSystem.ProtectedRunHook( Self, TLuaClassInfo( LuaClassInfo ).Hooks[ Hook ], Args );
  Exit( false );
end;

function TLuaGameNode.HasHook ( Hook : Word ) : Boolean;
begin
  Exit( Hook in FHooks );
end;

function TLuaGameNode.GetFlag ( aFlag : Byte ) : Boolean;
begin
  Exit( aFlag in FFlags );
end;

procedure TLuaGameNode.SetFlag ( aFlag : Byte; aValue : Boolean ) ;
begin
  if aValue
    then Include( FFlags, aFlag )
    else Exclude( FFlags, aFlag );
end;

function lua_game_node_flags_get(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    go      : TLuaGameNode;
begin
  State.Init( L );
  if State.StackSize < 2 then Exit(0);
  go := State.ToObject(1) as TLuaGameNode;
  State.Push( State.ToInteger(2) in go.FFlags);
  Result := 1;
end;

function lua_game_node_flags_set(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    go      : TLuaGameNode;
    Flag    : byte;
begin
  State.Init( L );
  if State.StackSize < 3 then Exit(0);
  go := State.ToObject(1) as TLuaGameNode;
  Flag := State.ToInteger(2);
  if State.ToBoolean(3) then
    Include(go.FFlags,Flag)
  else
    Exclude(go.FFlags,Flag);
  Result := 0;
end;

function lua_game_node_property_set(L: Plua_State): Integer; cdecl;
var State  : TLuaState;
    GNode  : TObject;
    Prop   : AnsiString;
begin
  State.Init(L);
  lua_settop( L, 3 );

  // check __props
  lua_getfield( L, 1, '__props' );
  lua_pushvalue( L, 2 ); // key
  lua_rawget( L, -2 );
  if not lua_isnil( L, -1 ) then
  begin
    lua_settop( L, 4 ); // leave __props
    lua_pushvalue( L, 2 ); // key
    lua_pushvalue( L, 3 ); // value
    lua_rawset( L, -3 );
    Exit(0);
  end;

  lua_settop( L, 3 );
  // check game object -- TODO - unwrap ToObject and ToString for efficiency
  GNode := State.ToObject(1) as TLuaGameNode;
  Prop := State.ToString(2);
  if GetPropInfo( GNode.ClassType, Prop ) = nil then
    State.Error('Unknown property "'+Prop+'" requested on object of type '+GNode.ClassName+'!');
  SetPropValue( GNode as GNode.ClassType, Prop, State.ToVariant(3) );
  Result := 0;
end;

function lua_game_node_property_get(L: Plua_State): Integer; cdecl;
var State : TLuaState;
    GNode : TObject;
    Prop  : AnsiString;
    Res   : Variant;
    PInfo : ^TPropInfo;
begin
  State.Init(L);
  lua_settop( L, 2 );

  // check __props
  lua_getfield( L, 1, '__props' );
  lua_pushvalue( L, 2 ); // key
  lua_rawget( L, -2 );
  if not lua_isnil( L, -1 ) then Exit(1);
  lua_settop( L, 2 );

  // check game object TODO - unwrap ToObject and ToString for efficiency
  GNode := State.ToObject(1) as TLuaGameNode;
  Prop := State.ToString(2);
  PInfo := GetPropInfo(GNode, Prop);
  if PInfo = nil then
    State.Error('Unknown property "'+Prop+'" requested on object of type '+GNode.ClassName+'!');
  Res := GetPropValue(GNode as GNode.ClassType, Prop, False );
  if PInfo^.PropType^.Kind = tkBool then VarCast( Res, Res, varBoolean );
  State.PushVariant( Res );
  Result := 1;
end;

function lua_game_node_property_add(L: Plua_State): Integer; cdecl;
begin
  lua_settop( L, 3 );
  lua_getfield( L, 1, '__props' );
  lua_pushvalue( L, 2 ); // key
  if lua_isnoneornil( L, 3 ) then
    lua_pushboolean( L, true )
  else
    lua_pushvalue( L, 3 );
  lua_rawset( L, -3 );
  Result := 0;
end;

function lua_game_node_property_remove(L: Plua_State): Integer; cdecl;
begin
  lua_settop( L, 3 );
  lua_getfield( L, 1, '__props' );
  lua_pushvalue( L, 2 ); // key
  lua_pushnil( L );
  lua_rawset( L, -3 );
  Result := 0;
end;

function lua_game_node_property_has(L: Plua_State): Integer; cdecl;
begin
  lua_settop( L, 2 );
  lua_getfield( L, 1, '__props' );
  lua_pushvalue( L, 2 ); // key
  lua_rawget( L, -2 );
  lua_pushboolean( L, not lua_isnil( L, -1 ) );
  Result := 1;
end;

const lua_game_node_lib : array[0..5] of luaL_Reg = (
      ( name : 'get_property';    func : @lua_game_node_property_get),
      ( name : 'set_property';    func : @lua_game_node_property_set),
      ( name : 'add_property';    func : @lua_game_node_property_add),
      ( name : 'has_property';    func : @lua_game_node_property_has),
      ( name : 'remove_property'; func : @lua_game_node_property_remove),
      ( name : nil;               func : nil; )
);

class procedure TLuaGameNode.RegisterLuaAPI ( const TableName : AnsiString ) ;
var L : PLua_State;
begin
  LuaSystem.Register( TableName, lua_game_node_lib );

  L := LuaSystem.Raw;

  lua_getglobal( L, TableName );
    // props container
    lua_pushstring( L, '__props');
    lua_newtable( L );
    lua_rawset( L, -3 );

    // flags metatable
    lua_pushstring( L, 'flags');
    lua_newtable( L );
      lua_createtable( L, 0, 2 );
        lua_pushcfunction( L, @lua_game_node_flags_get );
        lua_setfield( L, -2, '__index' );
        lua_pushcfunction( L, @lua_game_node_flags_set );
        lua_setfield( L, -2, '__newindex' );
      lua_setmetatable( L, -2 );
    lua_rawset( L, -3 );

    // properties
    lua_createtable( L, 0, 2 );
      lua_pushcfunction( L, @lua_game_node_property_get );
      lua_setfield( L, -2, '__index' );
      lua_pushcfunction( L, @lua_game_node_property_set );
      lua_setfield( L, -2, '__newindex' );
    lua_setmetatable( L, -2 );

  lua_pop( L, 1 );
end;

end.

