{$INCLUDE valkyrie.inc}
// @abstract(Lua tools for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(April 29, 2011)
//
// THIS UNIT IS EXPERIMENTAL!
//
// TODO : set an OPTIONAL area clamping mechanism

unit vluatools;
interface
uses vlualibrary, vutil, vrltools, vluatype;

procedure RegisterTableAuxFunctions( L: Plua_State );
procedure RegisterMathAuxFunctions( L: Plua_State );
procedure RegisterUIDClass( L: Plua_State; const Name : AnsiString = 'uids' );
procedure RegisterCoordClass( L: Plua_State );
procedure RegisterAreaClass( L: Plua_State );
procedure RegisterAreaFull( L: Plua_State; Area : TArea );

// WARNING - use absolute indices!
function vlua_iscoord( L: Plua_State; Index : Integer ) : Boolean;
function vlua_tocoord( L: Plua_State; Index : Integer ) : TCoord2D;
function vlua_topcoord( L: Plua_State; Index : Integer ) : PCoord2D;
procedure vlua_pushcoord( L: Plua_State; const Coord : TCoord2D );
function vlua_isarea( L: Plua_State; Index : Integer ) : Boolean;
function vlua_toarea( L: Plua_State; Index : Integer ) : TArea;
function vlua_toparea( L: Plua_State; Index : Integer ) : PArea;
procedure vlua_pusharea( L: Plua_State; const Area : TArea );

function vlua_toflags_flat( L : Plua_State; Index : Integer ): TFlags;
function vlua_toflags_set( L : Plua_State; Index : Integer ): TFlags;
procedure vlua_pushflags_flat( L : Plua_State; const Flags : TFlags );
procedure vlua_pushflags_set( L : Plua_State; const Flags : TFlags );

function vlua_tochar( L : Plua_State; Index : Integer ) : Char;
function vlua_ischar( L : Plua_State; Index : Integer ) : Boolean;
procedure vlua_pushchar( L : Plua_State; aChar : Char );

procedure vlua_push( L : Plua_State; const Args: array of const );

function LuaCoord( const aCoord : TCoord2D ) : TLuaType;
function LuaCoord( aX,aY : Integer ) : TLuaType;
function LuaArea( const aArea : TArea ) : TLuaType;

implementation

uses Classes, SysUtils, vluastate, vluaext, vuid;

function vlua_toflags_flat( L : Plua_State; Index : Integer ): TFlags;
begin
  Index := lua_absindex( L, Index );
  vlua_toflags_flat := [];
  if lua_istable( L, Index ) then
  begin
    lua_pushnil( L );
    while (lua_next( L, Index ) <> 0) do
    begin
       Include( vlua_toflags_flat, lua_tointeger( L ,-1 ) );
       lua_pop( L, 1 );
    end;
  end;
end;

function vlua_toflags_set( L : Plua_State; Index : Integer ): TFlags;
begin
  Index := lua_absindex( L, Index );
  vlua_toflags_set := [];
  if lua_istable( L, Index ) then
  begin
    lua_pushnil( L );
    while (lua_next( L, Index ) <> 0) do
    begin
       Include( vlua_toflags_set, lua_tointeger( L ,-2 ) );
       lua_pop( L, 1 );
    end;
  end;
end;

procedure vlua_pushflags_flat( L : Plua_State; const Flags : TFlags );
var Size, Flag : Byte;
begin
  Size := 0;
  for Flag in Flags do
    Inc( Size );
  lua_createtable( L, Size, 0 );
  Size := 0;
  for Flag in Flags do
  begin
    Inc( Size );
    lua_pushinteger( L, Flag );
    lua_rawseti( L, -2, Size );
  end;
end;

procedure vlua_pushflags_set( L : Plua_State; const Flags : TFlags );
var Size, Flag : Byte;
begin
  Size := 0;
  for Flag in Flags do
    Inc( Size );
  lua_createtable( L, 0, Size );
  Size := 0;
  for Flag in Flags do
  begin
    lua_pushboolean( L, true );
    lua_rawseti( L, -2, Flag );
  end;
end;

const VALKYRIE_COORD = 'valkyrie.coord';
      VALKYRIE_AREA  = 'valkyrie.area';

type TLuaCoord = class( TLuaType )
  constructor Create( const aCoord : TCoord2D );
  constructor Create( aX,aY : Integer );
  procedure Push( L : PLua_state ); override;
private
  FCoord : TCoord2D;
end;

constructor TLuaCoord.Create( const aCoord : TCoord2D );
begin
  FCoord := aCoord
end;

constructor TLuaCoord.Create( aX,aY : Integer );
begin
  FCoord.x := aX;
  FCoord.y := aY;
end;

procedure TLuaCoord.Push( L : PLua_state );
begin
  vlua_pushcoord( L, FCoord );
  Free;
end;

type TLuaArea = class( TLuaType )
  constructor Create( const aArea : TArea );
  procedure Push( L : PLua_state ); override;
private
  FArea : TArea;
end;

constructor TLuaArea.Create( const aArea : TArea );
begin
  FArea := aArea;
end;

procedure TLuaArea.Push( L : PLua_state );
begin
  vlua_pusharea( L, FArea );
  Free;
end;

function vlua_tochar ( L : Plua_State; Index : Integer ) : Char;
begin
  if (lua_type( L, Index ) <> LUA_TSTRING) or
     (lua_objlen( L, Index ) < 1) then Exit( ' ' );
  Exit( lua_tostring( L, Index )[1] );
end;

function vlua_ischar ( L : Plua_State; Index : Integer ) : Boolean;
begin
  Exit( (lua_type( L, Index ) = LUA_TSTRING) and (lua_objlen( L, Index ) >= 1) )
end;

procedure vlua_pushchar ( L : Plua_State; aChar : Char ) ;
begin
  lua_pushlstring( L, @aChar, 1 );
end;

procedure vlua_push ( L : Plua_State; const Args : array of const ) ;
var NArgs, i : LongInt;
begin
  NArgs := High(Args);
  if NArgs >= 0 then
  for i:=0 to NArgs do
    if Args[i].vtype = vtObject
       then vlua_pushobject( L, Args[i].VObject )
       else vlua_pushvarrec( L, @Args[i].vtype);
end;

function LuaCoord( const aCoord : TCoord2D ) : TLuaType;
begin
  Exit( TLuaCoord.Create( aCoord ) );
end;

function LuaCoord( aX,aY : Integer ) : TLuaType;
begin
  Exit( TLuaCoord.Create( aX,aY ) );
end;

function LuaArea( const aArea : TArea ) : TLuaType;
begin
  Exit( TLuaArea.Create( aArea ) );
end;

// -------- Helper functions ------------------------------------------ //

function lua_tointeger_def( L: Plua_State; Index : Integer; DValue : Integer ) : Integer;
begin
  if lua_type( L, Index ) = LUA_TNUMBER
    then Exit( lua_tointeger( L, Index ) )
    else Exit( DValue );
end;

function vlua_iscoord( L: Plua_State; Index : Integer ) : Boolean;
begin
  Exit( luaL_testudata( L, Index, VALKYRIE_COORD ) <> nil );
end;

function vlua_tocoord( L: Plua_State; Index : Integer ) : TCoord2D;
var CoordPtr : PCoord2D;
begin
  CoordPtr := luaL_checkudata( L, Index, VALKYRIE_COORD );
  Exit( CoordPtr^ );
end;

function vlua_topcoord( L: Plua_State; Index : Integer ) : PCoord2D;
var CoordPtr : PCoord2D;
begin
  CoordPtr := luaL_checkudata( L, Index, VALKYRIE_COORD );
  Exit( CoordPtr );
end;

procedure vlua_pushcoord( L: Plua_State; const Coord : TCoord2D );
var CoordPtr : PCoord2D;
begin
  CoordPtr  := PCoord2D(lua_newuserdata(L, SizeOf(TCoord2D)));
  CoordPtr^ := Coord;

  luaL_getmetatable( L, VALKYRIE_COORD );
  lua_setmetatable( L, -2 );
end;

function vlua_isarea( L: Plua_State; Index : Integer ) : Boolean;
begin
  Exit( luaL_testudata( L, Index, VALKYRIE_AREA ) <> nil );
end;

function vlua_toarea( L: Plua_State; Index : Integer ) : TArea;
var AreaPtr : PArea;
begin
  AreaPtr := luaL_checkudata( L, Index, VALKYRIE_AREA );
  Exit( AreaPtr^ );
end;

function vlua_toparea( L: Plua_State; Index : Integer ) : PArea;
var AreaPtr : PArea;
begin
  AreaPtr := luaL_checkudata( L, Index, VALKYRIE_AREA );
  Exit( AreaPtr );
end;

procedure vlua_pusharea( L: Plua_State; const Area : TArea );
var AreaPtr : PArea;
begin
  AreaPtr  := PArea(lua_newuserdata(L, SizeOf(TArea)));
  AreaPtr^ := Area;

  luaL_getmetatable( L, VALKYRIE_AREA );
  lua_setmetatable( L, -2 );
end;


// -------- Coord functions ------------------------------------------- //

function lua_coord_new( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord.Create( lua_tointeger_def(L,1,0), lua_tointeger_def(L,2,0) );
  vlua_pushcoord( L, Coord );
  Exit(1);
end;

function lua_coord_unm( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord := vlua_tocoord( L, 1 );
  vlua_pushcoord( L, NewCoord2D( -Coord.x, -Coord.y ) );
  Exit(1);
end;

function lua_coord_add( L: Plua_State): Integer; cdecl;
begin
  vlua_pushcoord( L, vlua_tocoord( L, 1 ) + vlua_tocoord( L, 2 ) );
  Exit(1);
end;

function lua_coord_sub( L: Plua_State): Integer; cdecl;
begin
  vlua_pushcoord( L, vlua_tocoord( L, 1 ) - vlua_tocoord( L, 2 ) );
  Exit(1);
end;

function lua_coord_mul( L: Plua_State): Integer; cdecl;
begin
  if vlua_iscoord( L, 1 ) then
    if vlua_iscoord( L, 2 ) then
      vlua_pushcoord( L, vlua_tocoord( L, 1 ) * vlua_tocoord( L, 2 ) )
    else
      vlua_pushcoord( L, vlua_tocoord( L, 1 ) * lua_tointeger( L, 2 ) )
  else
    vlua_pushcoord( L, vlua_tocoord( L, 2 ) * lua_tointeger( L, 1 ) );
  Exit(1);
end;

function lua_coord_eq( L: Plua_State): Integer; cdecl;
begin
  lua_pushboolean( L, vlua_tocoord( L, 1 ) = vlua_tocoord( L, 2 ) );
  Exit(1);
end;

function lua_coord_get( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord := vlua_tocoord( L, 1 );
  lua_pushinteger( L, Coord.x );
  lua_pushinteger( L, Coord.y );
  Exit(2);
end;

function lua_coord_tostring( L: Plua_State): Integer; cdecl;
begin
  lua_pushansistring( L, vlua_tocoord( L, 1 ).ToString );
  Exit(1);
end;

function lua_coord_abs( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord := vlua_tocoord( L, 1 );
  vlua_pushcoord( L, NewCoord2D( Abs(Coord.x), Abs(Coord.y) ) );
  Exit(1);
end;

function lua_coord_sign( L: Plua_State): Integer; cdecl;
begin
  vlua_pushcoord( L, vlua_tocoord( L, 1 ).Sign );
  Exit(1);
end;

function lua_coord_clone( L: Plua_State): Integer; cdecl;
begin
  vlua_pushcoord( L, vlua_tocoord( L, 1 ) );
  Exit(1);
end;

function lua_coord_distance( L: Plua_State): Integer; cdecl;
begin
  lua_pushinteger( L, Distance( vlua_tocoord( L, 1 ), vlua_tocoord( L, 2 ) ) );
  Exit(1);
end;

function lua_coord_real_distance( L: Plua_State): Integer; cdecl;
begin
  lua_pushnumber( L, RealDistance( vlua_tocoord( L, 1 ), vlua_tocoord( L, 2 ) ) );
  Exit(1);
end;

function lua_coord_random( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord.Random( vlua_tocoord( L, 1 ), vlua_tocoord( L, 2 ) );
  vlua_pushcoord( L, Coord );
  Exit(1);
end;

function lua_coord_random_shift( L: Plua_State ): Integer; cdecl;
var PCoord : PCoord2D;
begin
  PCoord := vlua_topcoord( L, 1 );
  PCoord^.RandomShift( lua_tointeger_def( L, 2, 1 ) );
  Exit(0);
end;

function lua_coord_random_shifted( L: Plua_State ): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord := vlua_tocoord( L, 1 );
  Coord.RandomShift( lua_tointeger_def( L, 2, 1 ) );
  vlua_pushcoord( L, Coord );
  Exit(1);
end;

function lua_coord_cross_coords_closure( L: Plua_State): Integer; cdecl;
var c   : PCoord2D;
    idx : Byte;
begin
  c    := vlua_topcoord( L, lua_upvalueindex(1) );
  idx  := lua_tointeger( L, lua_upvalueindex(2) );
  Inc(Idx);
  case idx of
    1 : c^.x -= 1;
    2 : c^.x += 2;
    3 : begin c^.x -= 1; c^.y -= 1; end;
    4 : c^.y += 2;
  end;
  lua_pushinteger( L, Idx );
  lua_replace( L, lua_upvalueindex(2) );
  if Idx > 4
    then lua_pushnil( L )
    else lua_pushvalue( L, lua_upvalueindex(1) );
  Exit(1);
end;

function lua_coord_cross_coords( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord := vlua_tocoord( L, 1 );
  vlua_pushcoord( L, Coord );
  lua_pushinteger( L, 0 );
  lua_pushcclosure(L, @lua_coord_cross_coords_closure, 2);
  Exit(1);
end;

function lua_coord_around_coords_closure( L: Plua_State): Integer; cdecl;
var c   : PCoord2D;
    idx : Byte;
begin
  c    := vlua_topcoord( L, lua_upvalueindex(1) );
  idx  := lua_tointeger( L, lua_upvalueindex(2) );
  Inc(Idx);
  case idx of
    1 : begin c^.x -= 1; c^.y -= 1; end;
    2 : c^.x += 1;
    3 : c^.x += 1;
    4 : c^.y += 1;
    5 : c^.y += 1;
    6 : c^.x -= 1;
    7 : c^.x -= 1;
    8 : c^.y -= 1;
  end;
  lua_pushinteger( L, Idx );
  lua_replace( L, lua_upvalueindex(2) );
  if Idx > 8
    then lua_pushnil( L )
    else lua_pushvalue( L, lua_upvalueindex(1) );
  Exit(1);
end;

function lua_coord_around_coords( L: Plua_State): Integer; cdecl;
var Coord : TCoord2D;
begin
  Coord := vlua_tocoord( L, 1 );
  vlua_pushcoord( L, Coord );
  lua_pushinteger( L, 0 );
  lua_pushcclosure(L, @lua_coord_around_coords_closure, 2);
  Exit(1);
end;


function lua_coord_index( L: Plua_State ): Integer; cdecl;
var PCoord : PCoord2D;
    Index  : AnsiString;
begin
  PCoord := vlua_topcoord( L, 1 );
  Index  := lua_tostring( L, 2 );
       if Index = 'x' then lua_pushinteger( L, PCoord^.x )
  else if Index = 'y' then lua_pushinteger( L, PCoord^.y )
  else
    begin
      lua_getglobal( L, 'coord' );
      lua_pushvalue( L, -2 );
      lua_rawget( L, -2 );
    end;
  Exit(1);
end;

function lua_coord_newindex( L: Plua_State ): Integer; cdecl;
var PCoord : PCoord2D;
    Index  : AnsiString;
    Value  : Integer;
begin
  PCoord := vlua_topcoord( L, 1 );
  Index  := lua_tostring( L, 2 );
  Value  := lua_tointeger_def( L, 3, 0 );
       if Index = 'x' then PCoord^.x := Value
  else if Index = 'y' then PCoord^.y := Value;
  Exit(0);
end;

// -------- Area functions -------------------------------------------- //

function lua_area_new( L: Plua_State): Integer; cdecl;
var Area : TArea;
begin
  if vlua_iscoord( L, 1 ) then
    if vlua_iscoord( L, 2 ) then
      begin
        Area.Create( vlua_tocoord(L,1), vlua_tocoord(L,2) );
        vlua_pusharea( L, Area );
        Exit(1);
      end;
  Area.Create(
    NewCoord2D( lua_tointeger_def(L,1,0), lua_tointeger_def(L,2,0) ),
    NewCoord2D( lua_tointeger_def(L,3,0), lua_tointeger_def(L,4,0) )
  );
  vlua_pusharea( L, Area );
  Exit(1);
end;

function lua_area_eq( L: Plua_State): Integer; cdecl;
var lhs, rhs : TArea;
begin
  lhs := vlua_toarea( L, 1 );
  rhs := vlua_toarea( L, 2 );
  lua_pushboolean( L, (lhs.a = rhs.a) and (lhs.b = rhs.b) );
  Exit(1);
end;

function lua_area_get( L: Plua_State): Integer; cdecl;
var Area : TArea;
begin
  Area := vlua_toarea( L, 1 );
  vlua_pushcoord( L, Area.a );
  vlua_pushcoord( L, Area.b );
  Exit(2);
end;

function lua_area_clone( L: Plua_State): Integer; cdecl;
begin
  vlua_pusharea( L, vlua_toarea( L, 1 ) );
  Exit(1);
end;

function lua_area_tostring( L: Plua_State): Integer; cdecl;
begin
  lua_pushansistring( L, vlua_toarea( L, 1 ).ToString );
  Exit(1);
end;

function lua_area_coords_closure( L: Plua_State): Integer; cdecl;
var Area : PArea;
    c    : PCoord2D;
begin
  Area := vlua_toparea( L, lua_upvalueindex(1) );
  c    := vlua_topcoord( L, lua_upvalueindex(2) );

  c^.x := c^.x + 1;
  if c^.x > Area^.b.x then
  begin
    c^.x := Area^.a.x;
    c^.y := c^.y + 1;
    if c^.y > Area^.b.y then begin lua_pushnil( L ); Exit(1); end
  end;

  vlua_pushcoord( L, c^ );
  Exit(1);
end;

function lua_area_coords( L: Plua_State): Integer; cdecl;
var Area : PArea;
    A    : TCoord2D;
begin
  Area := vlua_toparea( L, 1 );
  A := Area^.A;
  A.X := A.X - 1;
  vlua_pushcoord( L, A );
  lua_pushcclosure(L, @lua_area_coords_closure, 2);
  Exit(1);
end;

function lua_area_edges_closure( L: Plua_State): Integer; cdecl;
var Area : PArea;
    c    : PCoord2D;
begin
  Area := vlua_toparea( L, lua_upvalueindex(1) );
  c    := vlua_topcoord( L, lua_upvalueindex(2) );

  c^.x := c^.x + 1;
  if c^.x > Area^.b.x then
  begin
    c^.x := Area^.a.x;
    c^.y := c^.y + 1;
    if c^.y > Area^.b.y then begin lua_pushnil( L ); Exit(1); end
  end;
  if (c^.y <> Area^.a.y) and (c^.y <> Area^.b.y) and (c^.x = Area^.a.x + 1) then c^.x := Area^.b.x;

  vlua_pushcoord( L, c^ );
  Exit(1);
end;

function lua_area_edges( L: Plua_State): Integer; cdecl;
var Area : PArea;
    A    : TCoord2D;
begin
  Area := vlua_toparea( L, 1 );
  A := Area^.A;
  A.X := A.X - 1;
  vlua_pushcoord( L, A );
  lua_pushcclosure(L, @lua_area_edges_closure, 2);
  Exit(1);
end;

function lua_area_corners_closure( L: Plua_State): Integer; cdecl;
var Index : Integer;
begin
  Index := lua_tointeger( L, lua_upvalueindex(2) ) + 1;
  lua_pushinteger( L, Index );
  lua_replace( L, lua_upvalueindex(2) ); // update
  lua_rawgeti( L, lua_upvalueindex(1), Index ); // get value
  Exit(1);
end;

function lua_area_corners( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );

  lua_createtable(L, 4, 0);
  vlua_pushcoord( L, Area^.A );
  lua_rawseti( L, -2, 1 );
  vlua_pushcoord( L, Area^.TopRight );
  lua_rawseti( L, -2, 2 );
  vlua_pushcoord( L, Area^.BottomLeft );
  lua_rawseti( L, -2, 3 );
  vlua_pushcoord( L, Area^.B );
  lua_rawseti( L, -2, 4 );

  lua_pushnumber(L, 0);

  lua_pushcclosure(L, @lua_area_corners_closure, 2);
  Exit(1);
end;

function lua_area_random_coord( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  vlua_pushcoord( L, Area^.RandomCoord() );
  Exit(1);
end;

function lua_area_random_edge_coord( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  vlua_pushcoord( L, Area^.RandomEdgeCoord() );
  Exit(1);
end;

function lua_area_random_inner_edge_coord( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  vlua_pushcoord( L, Area^.RandomInnerEdgeCoord() );
  Exit(1);
end;

function lua_area_shrink( L: Plua_State): Integer; cdecl;
var Area   : PArea;
    Amount : Integer;
begin
  Area   := vlua_toparea( L, 1 );
  Amount := lua_tointeger_def( L, 2, 1 );
  Area^.Shrink( Amount );
  Exit(0);
end;

function lua_area_shrinked( L: Plua_State): Integer; cdecl;
var Area : PArea;
    Amount : Integer;
begin
  Area   := vlua_toparea( L, 1 );
  Amount := lua_tointeger_def( L, 2, 1 );
  vlua_pusharea( L, Area^.Shrinked( Amount ) );
  Exit(1);
end;

function lua_area_expand( L: Plua_State): Integer; cdecl;
var Area   : PArea;
    Amount : Integer;
begin
  Area   := vlua_toparea( L, 1 );
  Amount := lua_tointeger_def( L, 2, 1 );
  Area^.Expand( Amount );
  Exit(0);
end;

function lua_area_expanded( L: Plua_State): Integer; cdecl;
var Area : PArea;
    Amount : Integer;
begin
  Area   := vlua_toparea( L, 1 );
  Amount := lua_tointeger_def( L, 2, 1 );
  vlua_pusharea( L, Area^.Expanded( Amount ) );
  Exit(1);
end;

function lua_area_clamp( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  vlua_toparea( L, 2 )^.Clamp( Area^ );
  Exit(0);
end;

function lua_area_clamped( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  vlua_pusharea( L, Area^.Clamped( vlua_toparea( L, 2 )^ ) );
  Exit(1);
end;

function lua_area_fix( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  if Area^.a.x > Area^.b.x then Area^.a.x := Area^.b.x;
  if Area^.a.y > Area^.b.y then Area^.a.y := Area^.b.y;
  Exit(0);
end;

function lua_area_proper( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  lua_pushboolean( L, ( Area^.a.x <= Area^.b.x ) and ( Area^.a.y <= Area^.b.y ) );
  Exit(1);
end;

function lua_area_dim( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  vlua_pushcoord( L, Area^.b - Area^.a + UnitCoord2D );
  Exit(1);
end;

function lua_area_size( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
  lua_pushinteger( L, Area^.EnclosedArea );
  Exit(1);
end;

function lua_area_around( L: Plua_State): Integer; cdecl;
var Where  : TCoord2D;
    Amount : Integer;
begin
  Where  := vlua_tocoord( L, 1 );
  Amount := lua_tointeger_def( L, 2, 1 );
  vlua_pusharea( L, NewArea( Where, Amount ) );

  // TODO: CLAMP?

  Exit(1);
end;

function lua_area_clamp_coord( L: Plua_State): Integer; cdecl;
var Area : PArea;
    PC   : PCoord2D;
begin
  Area := vlua_toparea( L, 1 );
  PC   := vlua_topcoord( L, 2 );
  Area^.Clamp( PC^ );
  Exit(0);
end;

function lua_area_contains( L: Plua_State): Integer; cdecl;
var Area : PArea;
begin
  Area := vlua_toparea( L, 1 );
       if vlua_iscoord( L, 2 ) then
         lua_pushboolean( L, Area^.Contains( vlua_tocoord( L, 2 ) ) )
  else if vlua_isarea( L, 2 ) then
         lua_pushboolean( L, Area^.Contains( vlua_toarea( L, 2 ) ) )
  else
         luaL_argerror( L, 2, 'area or coord expected' );
  Exit(1);
end;

function lua_area_random_subarea( L: Plua_State): Integer; cdecl;
var Area : PArea;
    Dim  : PCoord2D;
begin
  Area := vlua_toparea( L, 1 );
  Dim  := vlua_topcoord( L, 2 );
  vlua_pusharea( L, Area^.RandomSubArea( Dim^ ) );
  Exit(1);
end;

function lua_area_is_edge( L: Plua_State): Integer; cdecl;
var Area : PArea;
    C    : PCoord2D;
begin
  Area := vlua_toparea( L, 1 );
  C    := vlua_topcoord( L, 2 );
  lua_pushboolean( L, Area^.isEdge( c^ ) );
  Exit(1);
end;

function lua_area_index( L: Plua_State ): Integer; cdecl;
var Area  : PArea;
    Index : AnsiString;
begin
  Area  := vlua_toparea( L, 1 );
  Index := lua_tostring( L, 2 );
       if Index = 'a' then vlua_pushcoord( L, Area^.a )
  else if Index = 'b' then vlua_pushcoord( L, Area^.b )
  else
    begin
      lua_getglobal( L, 'area' );
      lua_pushvalue( L, -2 );
      lua_rawget( L, -2 );
    end;
  Exit(1);
end;

function lua_area_newindex( L: Plua_State ): Integer; cdecl;
var Area  : PArea;
    Index : AnsiString;
    Value : TCoord2D;
begin
  Area  := vlua_toparea( L, 1 );
  Index := lua_tostring( L, 2 );
  Value := vlua_tocoord( L, 3 );
       if Index = 'a' then Area^.a := Value
  else if Index = 'b' then Area^.b := Value;
  Exit(0);
end;

// -------- Table functions ------------------------------------------- //

function lua_table_copy( L: Plua_State ): Integer; cdecl;
begin
  luaL_checktype( L, 1, LUA_TTABLE );
  lua_settop( L, 1 );
  lua_newtable(L);
  lua_pushnil(L);
  while ( lua_next( L, 1 ) <> 0 ) do
  begin
    lua_pushvalue(L, -2);
    lua_insert(L, -2);
    lua_settable(L, -4);
  end;
  Exit( 1 );
end;

function lua_table_icopy( L: Plua_State ): Integer; cdecl;
var i : Integer;
begin
  luaL_checktype( L, 1, LUA_TTABLE );
  lua_settop( L, 1 );
  lua_newtable(L);
  i := 0;
  while ( true ) do
  begin
    Inc( i );
    lua_rawgeti(L, 1, i);
    if ( lua_isnil( L, -1 ) ) then
    begin
      lua_pop( L, 1 );
      break;
    end;
    lua_rawseti(L, 2, i);
  end;
  Exit( 1 );
end;

function lua_table_merge( L: Plua_State ): Integer; cdecl;
begin
  luaL_checktype( L, 1, LUA_TTABLE );
  luaL_checktype( L, 2, LUA_TTABLE );
  lua_settop( L, 2 );
  lua_pushnil(L);
  while ( lua_next( L, 2 ) <> 0 ) do
  begin
    lua_pushvalue(L, -2);
    lua_insert(L, -2);
    lua_settable(L, 1);
  end;
  Exit( 0 );
end;

function lua_table_imerge( L: Plua_State ): Integer; cdecl;
var i : Integer;
begin
  luaL_checktype( L, 1, LUA_TTABLE );
  luaL_checktype( L, 2, LUA_TTABLE );
  lua_settop( L, 2 );
  i := 0;
  while ( true ) do
  begin
    Inc( i );
    lua_rawgeti(L, 2, i);
    if ( lua_isnil( L, -1 ) ) then
    begin
      lua_pop( L, 1 );
      break;
    end;
    lua_rawseti(L, 1, i);
  end;
  Exit( 0 );
end;

function lua_table_reversed( L: Plua_State ): Integer; cdecl;
var i, len : Integer;
begin
  luaL_checktype( L, 1, LUA_TTABLE );
  lua_settop( L, 1 );
  len := lua_objlen(L,1);
  i   := len;
  lua_createtable(L,len,0);
  while ( i <> 0 ) do
  begin
    lua_rawgeti(L, 1, i);
    lua_rawseti(L, 2, len-i+1);
    Dec( i );
  end;
  Exit( 1 );
end;

function lua_table_toset( L: Plua_State ): Integer; cdecl;
var i : Integer;
begin
  luaL_checktype( L, 1, LUA_TTABLE );
  lua_settop( L, 1 );
  lua_newtable(L);
  i := 0;
  while ( true ) do
  begin
    Inc( i );
    lua_rawgeti(L, 1, i);
    if ( lua_isnil( L, -1 ) ) then
    begin
      lua_pop( L, 1 );
      break;
    end;
    lua_pushboolean( L, true );
    lua_rawset(L, 2);
  end;
  Exit( 1 );
end;

// -------- Math functions -------------------------------------------- //

function lua_math_clamp( L: Plua_State ): Integer; cdecl;
var v,vmin,vmax : Double;
begin
  v    := luaL_checknumber(L, 1);
  vmin := luaL_optnumber(L,2,0);
  vmax := luaL_optnumber(L,3,1);
  if vmin > vmax then luaL_argerror( L, 2, 'min is larger than max!');
  if v < vmin then
    lua_pushnumber( L, vmin )
  else if v > vmax then
    lua_pushnumber( L, vmax )
  else
    lua_pushnumber( L, v );
  Result := 1;
end;

// -------- UID functions --------------------------------------------- //

function lua_uid_count( L: Plua_State ): Integer; cdecl;
begin
  lua_pushnumber( L, UIDs.Size );
  Result := 1;
end;

function lua_uid_get( L: Plua_State ): Integer; cdecl;
begin
  vlua_pushanyobject( L, UIDs.Get( lua_tointeger( L, 1 ) ) );
  Result := 1;
end;

function lua_uid_exists( L: Plua_State ): Integer; cdecl;
begin
  lua_pushboolean( L, UIDs.Get( lua_tointeger( L, 1 ) ) <> nil );
  Result := 1;
end;


// -------- Registration tables and functions ------------------------- //

const coordlib_f : array[0..13] of luaL_Reg = (
  ( name : 'new';            func : @lua_coord_new; ),
  ( name : 'get';            func : @lua_coord_get; ),
  ( name : 'abs';            func : @lua_coord_abs; ),
  ( name : 'sign';           func : @lua_coord_sign; ),
  ( name : 'clone';          func : @lua_coord_clone; ),
  ( name : 'distance';       func : @lua_coord_distance; ),
  ( name : 'real_distance';  func : @lua_coord_real_distance; ),
  ( name : 'random';         func : @lua_coord_random; ),
  ( name : 'random_shift';   func : @lua_coord_random_shift; ),
  ( name : 'random_shifted'; func : @lua_coord_random_shifted; ),
  ( name : 'tostring';       func : @lua_coord_tostring; ),
  ( name : 'cross_coords';   func : @lua_coord_cross_coords; ),
  ( name : 'around_coords';  func : @lua_coord_around_coords; ),
  ( name : nil;              func : nil; )
  );

const coordlib_m : array[0..8] of luaL_Reg = (
  ( name : '__add';      func : @lua_coord_add; ),
  ( name : '__sub';      func : @lua_coord_sub; ),
  ( name : '__unm';      func : @lua_coord_unm; ),
  ( name : '__mul';      func : @lua_coord_mul; ),
  ( name : '__eq';       func : @lua_coord_eq; ),
  ( name : '__index';    func : @lua_coord_index; ),
  ( name : '__newindex'; func : @lua_coord_newindex; ),
  ( name : '__tostring'; func : @lua_coord_tostring; ),
  ( name : nil;          func : nil; )
  );

const arealib_f : array[0..25] of luaL_Reg = (
  ( name : 'new';            func : @lua_area_new; ),
  ( name : 'get';            func : @lua_area_get; ),
  ( name : 'clone';          func : @lua_area_clone; ),
  ( name : 'tostring';       func : @lua_area_tostring; ),
  ( name : 'shrink';         func : @lua_area_shrink; ),
  ( name : 'shrinked';       func : @lua_area_shrinked; ),
  ( name : 'expand';         func : @lua_area_expand; ),
  ( name : 'expanded';       func : @lua_area_expanded; ),
  ( name : 'clamp';          func : @lua_area_clamp; ),
  ( name : 'clamped';        func : @lua_area_clamped; ),
  ( name : 'fix';            func : @lua_area_fix; ),
  ( name : 'proper';         func : @lua_area_proper; ),
  ( name : 'dim';            func : @lua_area_dim; ),
  ( name : 'size';           func : @lua_area_size; ),
  ( name : 'around';         func : @lua_area_around; ),
  ( name : 'clamp_coord';    func : @lua_area_clamp_coord; ),
  ( name : 'contains';       func : @lua_area_contains; ),
  ( name : 'is_edge';        func : @lua_area_is_edge; ),

  ( name : 'coords';         func : @lua_area_coords; ),
  ( name : 'edges';          func : @lua_area_edges; ),
  ( name : 'corners';        func : @lua_area_corners; ),

  ( name : 'random_subarea';          func : @lua_area_random_subarea; ),
  ( name : 'random_coord';            func : @lua_area_random_coord; ),
  ( name : 'random_edge_coord';       func : @lua_area_random_edge_coord; ),
  ( name : 'random_inner_edge_coord'; func : @lua_area_random_inner_edge_coord; ),

  ( name : nil;              func : nil; )
  );

const arealib_m : array[0..5] of luaL_Reg = (
  ( name : '__eq';       func : @lua_area_eq; ),
  ( name : '__index';    func : @lua_area_index; ),
  ( name : '__newindex'; func : @lua_area_newindex; ),
  ( name : '__tostring'; func : @lua_area_tostring; ),
  ( name : '__call';     func : @lua_area_coords; ),
  ( name : nil;          func : nil; )
  );

const tableauxlib_f : array[0..6] of luaL_Reg = (
  ( name : 'copy';      func : @lua_table_copy ),
  ( name : 'icopy';     func : @lua_table_icopy ),
  ( name : 'merge';     func : @lua_table_merge ),
  ( name : 'imerge';    func : @lua_table_imerge ),
  ( name : 'reversed';  func : @lua_table_reversed ),
  ( name : 'toset';     func : @lua_table_toset ),
  ( name : nil;         func : nil; )
  );

const mathauxlib_f : array[0..1] of luaL_Reg = (
  ( name : 'clamp';     func : @lua_math_clamp ),
  ( name : nil;         func : nil; )
  );

const uidlib_f : array[0..3] of luaL_Reg = (
  ( name : 'count';     func : @lua_uid_count ),
  ( name : 'get';       func : @lua_uid_get ),
  ( name : 'exists';    func : @lua_uid_exists ),
  ( name : nil;         func : nil; )
  );


procedure RegisterTableAuxFunctions(L: Plua_State);
begin
  luaL_register( L, 'table', tableauxlib_f );
  lua_pop( L, 1 );
end;

procedure RegisterMathAuxFunctions ( L : Plua_State ) ;
begin
  luaL_register( L, 'math', mathauxlib_f );
  lua_pop( L, 1 );
end;

procedure RegisterUIDClass( L: Plua_State; const Name : AnsiString = 'uids' );
begin
  luaL_register( L, PChar(Name), uidlib_f );
  lua_pop( L, 1 );
end;

procedure RegisterCoordClass( L: Plua_State );
begin
  luaL_newmetatable( L, VALKYRIE_COORD );
  luaL_register( L, nil, coordlib_m );
  luaL_register( L, 'coord', coordlib_f );

  vlua_pushcoord( L, ZeroCoord2D );
  lua_setfield( L, -2, 'ZERO' );

  vlua_pushcoord( L, UnitCoord2D );
  lua_setfield( L, -2, 'UNIT' );
  lua_pop( L, 1 );
end;

procedure RegisterAreaClass( L: Plua_State );
begin
  luaL_newmetatable( L, VALKYRIE_AREA );
  luaL_register( L, nil, arealib_m );
  luaL_register( L, 'area', arealib_f );
  lua_pop( L, 1 );
end;

procedure RegisterAreaFull(L: Plua_State; Area: TArea);
begin
  lua_getglobal( L, 'area' );
  vlua_pusharea( L, Area );
  lua_setfield( L, -2, 'FULL' );
  vlua_pusharea( L, Area.Shrinked() );
  lua_setfield( L, -2, 'FULL_SHRINKED' );
  lua_pop( L, 1 );
end;


end.

