{$INCLUDE valkyrie.inc}
// @abstract(LuaNode class for Valkyrie)
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

unit vluanode;
interface
uses Classes, vnode, vutil, vluatype;

type

{ TLuaNode }

TLuaNode = class( TNode, ILuaReferencedObject )
  // Standard constructor, zeroes all fields.
  constructor Create; override;
  // Stream constructor, reads UID, and ID from stream, should be overriden.
  constructor CreateFromStream( Stream : TStream ); override;
  // Write Node to stream (UID and ID) should be overriden.
  procedure WriteToStream( Stream : TStream ); override;
  // destructor
  destructor Destroy; override;
  function GetLuaIndex   : Integer;
  function GetID         : AnsiString;
  function GetProtoTable : AnsiString;
  function GetProtoName  : AnsiString;
  class procedure RegisterLuaAPI( const TableName : AnsiString );
protected
  FLuaIndex     : LongInt;
  FLuaClassInfo : Pointer;
public
  property LuaClassInfo : Pointer read FLuaClassInfo;
end;

implementation
uses vlualibrary, vluasystem, vluastate;

{ TLuaNode }

constructor TLuaNode.Create;
begin
  inherited Create;
  FLuaIndex := LuaSystem.RegisterObject( Self );
  FLuaClassInfo := LuaSystem.GetClassInfo( Self.ClassType );
end;

constructor TLuaNode.CreateFromStream ( Stream : TStream ) ;
begin
  inherited CreateFromStream ( Stream ) ;
  FLuaIndex := LuaSystem.RegisterObject( Self );
  FLuaClassInfo := LuaSystem.GetClassInfo( Self.ClassType );
end;

procedure TLuaNode.WriteToStream ( Stream : TStream ) ;
begin
  inherited WriteToStream ( Stream ) ;
end;

destructor TLuaNode.Destroy;
begin
  inherited Destroy;
  if LuaSystem <> nil then
    LuaSystem.UnRegisterObject( Self );
end;

function TLuaNode.GetLuaIndex: Integer;
begin
  Exit( FLuaIndex );
end;

function TLuaNode.GetID: AnsiString;
begin
  Exit( FID );
end;

function TLuaNode.GetProtoTable : AnsiString;
begin
  Exit( TLuaClassInfo(FLuaClassInfo).Storage );
end;

function TLuaNode.GetProtoName : AnsiString;
begin
  Exit( TLuaClassInfo(FLuaClassInfo).Proto );
end;


function lua_luanode_get_type(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    LuaNode : TLuaNode;
begin
  State.Init(L);
  LuaNode := State.ToObject(1) as TLuaNode;
  State.Push( LuaSystem.GetProtoTable( LuaNode.ClassType ) );
  Result := 1;
end;

function lua_luanode_get_id(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    LuaNode : TLuaNode;
begin
  State.Init(L);
  LuaNode := State.ToObject(1) as TLuaNode;
  State.Push( LuaNode.ID );
  Result := 1;
end;

function lua_luanode_get_uid(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    LuaNode : TLuaNode;
begin
  State.Init(L);
  LuaNode := State.ToObject(1) as TLuaNode;
  State.Push( LongInt(LuaNode.UID) );
  Result := 1;
end;

function lua_luanode_get_parent(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    LuaNode : TLuaNode;
begin
  State.Init(L);
  LuaNode := State.ToObject(1) as TLuaNode;
  State.Push( LuaNode.Parent as ILuaReferencedObject );
  Result := 1;
end;

function lua_luanode_get_child_count(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    LuaNode : TLuaNode;
begin
  State.Init(L);
  LuaNode := State.ToObject(1) as TLuaNode;
  State.Push( LongInt(LuaNode.ChildCount) );
  Result := 1;
end;

function lua_luanode_children_closure(L: Plua_State): Integer; cdecl;
var State     : TLuaState;
    Parent    : TNode;
    Next      : TNode;
    Current   : TLuaNode;
begin
  State.Init( L );
  Parent    := TObject( lua_touserdata( L, lua_upvalueindex(1) ) ) as TLuaNode;
  Next      := TObject( lua_touserdata( L, lua_upvalueindex(2) ) ) as TLuaNode;

  Current := Next as TLuaNode;
  if Next <> nil then Next := Next.Next as TLuaNode;
  if Next = Parent.Child then Next := nil;
  lua_pushlightuserdata( L, Next );
  lua_replace( L, lua_upvalueindex(2) );

  State.Push( Current );
  Exit( 1 );
end;

function lua_luanode_children_filter_closure(L: Plua_State): Integer; cdecl;
var State     : TLuaState;
    Parent    : TNode;
    Next      : TNode;
    Current   : TLuaNode;
    Filter    : AnsiString;
begin
  State.Init( L );
  Parent    := TObject( lua_touserdata( L, lua_upvalueindex(1) ) ) as TLuaNode;
  Next      := TObject( lua_touserdata( L, lua_upvalueindex(2) ) ) as TLuaNode;
  Filter    := lua_tostring( L, lua_upvalueindex(3) );

  repeat
    Current := Next as TLuaNode;
    if Next <> nil then Next := Next.Next;
    if Next = Parent.Child then Next := nil;
  until (Current = nil) or (Current.GetProtoName = Filter);

  lua_pushlightuserdata( L, Next );
  lua_replace( L, lua_upvalueindex(2) );

  State.Push( Current );
  Exit( 1 );
end;

// iterator
function lua_luanode_children(L: Plua_State): Integer; cdecl;
var State   : TLuaState;
    LuaNode : TLuaNode;
begin
  State.Init(L);
  LuaNode := State.ToObject(1) as TLuaNode;
  lua_pushlightuserdata( L, LuaNode );
  lua_pushlightuserdata( L, LuaNode.Child );
  if lua_isstring( L, 2 ) then
  begin
    lua_pushvalue( L, 2 );
    lua_pushcclosure( L, @lua_luanode_children_filter_closure, 3 );
  end
  else
    lua_pushcclosure( L, @lua_luanode_children_closure, 2 );
  Exit( 1 );
end;

const lua_luanode_lib : array[0..6] of luaL_Reg = (
      ( name : 'get_type';        func : @lua_luanode_get_type),
      ( name : 'get_id';          func : @lua_luanode_get_id),
      ( name : 'get_uid';         func : @lua_luanode_get_uid),
      ( name : 'get_parent';      func : @lua_luanode_get_parent),
      ( name : 'get_child_count'; func : @lua_luanode_get_child_count),
      ( name : 'children';        func : @lua_luanode_children),
      ( name : nil;               func : nil; )
);

class procedure TLuaNode.RegisterLuaAPI ( const TableName : AnsiString ) ;
begin
  LuaSystem.Register( TableName, lua_luanode_lib );
end;

end.

