{$INCLUDE valkyrie.inc}
// @abstract(LuaSystem class for Valkyrie)
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

unit vluasystem;
interface
uses classes, vlualibrary, vutil, vdebug, vsystem, vlua, vluastate, vluatype, vdf, vgenerics, vluatable;

type
   ELuaException = vlualibrary.ELuaException;
   PLua_State    = vlualibrary.PLua_State;
   PluaL_Reg     = vlualibrary.PluaL_Reg;
   LuaL_Reg      = vlualibrary.luaL_Reg;
   TLuaSystemErrorFunc = procedure( const Message : AnsiString );
   TLuaSystemPrintFunc = procedure( const Text : AnsiString ) of object;

type TLuaClassInfo = class(TObject)
    constructor Create( const Proto, Storage : AnsiString );
    procedure RegisterHook( HookID : Byte; const HookName : AnsiString );
    function GetHook( HookID : Byte ) : AnsiString;
  private
    FProto   : AnsiString;
    FStorage : AnsiString;
    FHooks   : array of AnsiString;
    FHookSet : TFlags;
    FHookMax : Byte;
  public
    property Hooks[ HookID : Byte ] : AnsiString read GetHook;
    property Proto   : AnsiString read FProto;
    property Storage : AnsiString read FStorage;
    property HookSet : TFlags     read FHookSet;
    property HookMax : Byte       read FHookMax;
  end;


type TLuaClassMap       = specialize TGHashMap<TLuaClassInfo>;
     TStringBoolMap     = specialize TGHashMap<Boolean>;
     TStringDataFileMap = specialize TGHashMap<TVDataFile>;
     TStringStringMap   = specialize TGHashMap<AnsiString>;
     TIntMap            = specialize TGHashMap<Integer>;

type TLuaSystem = class(TSystem)
    // Registers system execution.
    constructor Create( coverState : Plua_State = nil ); reintroduce;
    // Closes system execution.
    destructor Destroy; override;
    // Returns a value by table path
    function Defined( const Path : AnsiString ) : Boolean;
    // Returns a value by array of const
    function Defined( const Path : array of Const ) : Boolean;
    // Returns a table by table path
    function GetTable( const Path : AnsiString ) : TLuaTable;
    // Returns a table by array of const
    function GetTable( const Path : array of Const ) : TLuaTable;
    // Returns a table size by table path
    function GetTableSize( const Path : AnsiString ) : DWord;
    // Returns a table size by array of const
    function GetTableSize( const Path : array of Const ) : DWord;
    // Returns a value by table path
    function Get( const Path : AnsiString ) : Variant;
    // Returns a value by array of const
    function Get( const Path : array of Const ) : Variant;
    // Returns a value by table path
    function Get( const Path : AnsiString; const DefVal : Variant ) : Variant;
    // Returns a value by array of const
    function Get( const Path : array of Const; const DefVal : Variant ) : Variant;
    // Sets a value by table path
    procedure SetValue( const Path : AnsiString; const Value : Variant );
    // Sets a value by array of const
    procedure SetValue( const Path : array of Const; const Value : Variant );
    // Sets a value by table path
    procedure SetValue( const Path : AnsiString; aObject : TObject );
    // Sets a value by array of const
    procedure SetValue( const Path : array of Const; aObject : TObject );
    // Call a function
    function Call( const Path : array of Const; const Args : array of Const ) : Variant;
    // Call a function
    function Call( const Path : AnsiString; const Args : array of Const ) : Variant;
    // Returns the proto table of the object
    function GetProtoTable( aObj : TObject ) : TLuaTable;
    // Run a hook on a lua object
    function RunHook( Obj : ILuaReferencedObject; HookName : AnsiString; const Params : array of const ) : Variant;
    // Call a function in protected mode -- exceptions will be caught, logged,
    // reported to OnError. False will be returned on Error;
    function ProtectedCall( const Path : array of Const; const Args : array of Const ) : Variant;
    // Call a function in protected mode -- exceptions will be caught, logged,
    // reported to OnError. False will be returned on Error;
    function ProtectedCall( const Path : AnsiString; const Args : array of Const ) : Variant;
    // Run a hook on a lua object in protected mode (see above)
    function ProtectedRunHook( Obj : ILuaReferencedObject; HookName : AnsiString; const Params : array of const ) : Variant;
    // Register table functions
    procedure Register( const libname : AnsiString; const lr : PluaL_Reg );
    // Load raw Lua file
    procedure LoadFile(const FileName : AnsiString);
    // Load Lua code from a stream. WARNING - stream is invalid afterwards!
    procedure LoadStream( IST : TStream; StreamName : AnsiString; Size : DWord ); overload;
    // Load from a Valkyrie Datafile
    procedure LoadStream( DF : TVDataFile; const StreamName : AnsiString); overload;
    // Load from a Valkyrie Datafile
    procedure LoadStream( DF : TVDataFile; const DirName, FileName : AnsiString ); overload;
    // Inform of a recoverable error. No need to log the error here,
    // TLuaSystem handles it. Function should be overriden to react on
    // errors that are protected but unrecoverable, or for emiting them to the
    // user.
    // By default does nothing, or runs ErrorFunc if assigned.
    procedure OnError( const Message : AnsiString ); virtual;
    // Registers a lua module for "require" use
    procedure RegisterModule( const ModuleName : AnsiString; DF: TVDataFile );
    // Registers a raw lua module for "require" use. Module Path should end with pathsep,
    // or be empty. RawModules always take priority over compiled ones.
    procedure RegisterModule( const ModuleName, ModulePath: AnsiString);
    // Registers a Lua type.
    procedure RegisterType( AClass : TClass; const ProtoName, StorageName : AnsiString );
    // Return prototype name
    function GetClassInfo( AClass : TClass ) : TLuaClassInfo;
    // Return prototype name
    function GetProtoTable( AClass : TClass ) : AnsiString;
    // Return prototype name
    function GetStorageTable( AClass : TClass ) : AnsiString;
    // Registers an object in Lua space, returns a LuaID
    function RegisterObject( Obj : TObject ) : Integer;
    // Unregisters an object
    procedure UnRegisterObject( Obj: ILuaReferencedObject );
    // Returns memory in use (in KBytes)
    function GetMemoryKB : DWord;
    // Returns memory in use (in Bytes)
    function GetMemoryB : DWord;
    // Does a full garbage collection
    procedure CollectGarbage;
    // Sets a print function
    procedure SetPrintFunction( aPrintFunc : TLuaSystemPrintFunc );
    // Print if assigned
    procedure Print( const aText : AnsiString );
    // Execute and print results
    procedure ConsoleExecute( const aCode : AnsiString );
  protected
    FLuaState     : TLuaState;
    FState        : PLua_State;
    FLua          : TLua;
    FErrorFunc    : TLuaSystemErrorFunc;
    FPrintFunc    : TLuaSystemPrintFunc;
    FModuleNames  : TStringBoolMap;
    FDataFiles    : TStringDataFileMap;
    FRawModules   : TStringStringMap;
    FClassMap     : TLuaClassMap;
    FCallDefVal   : Variant;
    FDefines      : TIntMap;
  public
    property CallDefaultResult : Variant     read FCallDefVal write FCallDefVal;
    property Lua : TLua                      read FLua;
    property Raw : PLua_State                read FState;
    property State : TLuaState               read FLuaState;
    property ErrorFunc : TLuaSystemErrorFunc write FErrorFunc;
    property ModuleNames : TStringBoolMap    read FModuleNames;
    property Defines : TIntMap               read FDefines;

  private
    // Pushes the path, leaves the last element on top, returns -3.
    // if value is a global then returns LUA_GLOBALSINDEX
    function GetPath( const Path : AnsiString ) : Integer;
    // Pushes the path, leaves the last element on top, returns -3.
    // if value is a global then retursb LUA_GLOBALSINDEX
    function GetPath( const Path : array of Const ) : Integer;
    // Convert path to string
    function PathToString( const Path : array of Const ) : AnsiString;
    // Deep copy of lua object with copying of __ptr field
    procedure DeepPointerCopy( Index : Integer; Obj : Pointer );
  end;

const LuaSystem : TLuaSystem = nil;

implementation

uses variants, sysutils, strutils, math, vluaext;

function print_value(L: Plua_State; index : Integer; Indent : Word = 0; Prefix : AnsiString = '') : Word;
var Lines : Byte;
begin
  index := lua_absindex(L,index);
  Prefix := StringOfChar(' ',Indent)+Prefix;
  case lua_type(L,index) of
    LUA_TNIL           : LuaSystem.Print(Prefix+'@Bnil');
    LUA_TBOOLEAN       : if lua_toboolean(L,index) then LuaSystem.Print(Prefix+'@Btrue') else LuaSystem.Print(Prefix+'@Bfalse');
    LUA_TLIGHTUSERDATA : LuaSystem.Print(Prefix+'@blightuserdata(@B0x'+hexstr(lua_touserdata(L,index))+'@b)');
    LUA_TNUMBER        : LuaSystem.Print(Prefix+'@L'+lua_tostring(L,index));
    LUA_TSTRING        : LuaSystem.Print(Prefix+'"'+lua_tostring(L,index)+'"');
    LUA_TFUNCTION      : LuaSystem.Print(Prefix+'@yfunction');
    LUA_TUSERDATA      : LuaSystem.Print(Prefix+'@yuserdata');
    LUA_TTHREAD        : LuaSystem.Print(Prefix+'@ythread');
    LUA_TTABLE         :
      begin
        LuaSystem.Print(Prefix+'@ytable@> = {');
        Indent += 2;
        Lines := 2;
        lua_pushnil(L);
        while lua_next(L, index) <> 0 do
        begin
          // key (index -2), 'value' (index -1)
          if lua_isnumber( L, -2 ) then
            Lines += print_value( L, -1, Indent, IntToStr(lua_tointeger( L, -2 ))+' = ')
          else
            Lines += print_value( L, -1, Indent, lua_tostring( L, -2 )+' = ');
          // remove value, keep key
          lua_pop(L, 1);
          if Lines > 8 then
          begin
            LuaSystem.Print(StringOfChar(' ',Indent)+'...');
            lua_pop(L, 1);
            break;
          end;
        end;
        if Lines <= 8 then LuaSystem.Print(StringOfChar(' ',Indent-2)+'}');
        Exit(Lines);
      end;
  end;
  Exit(1);
end;

function lua_valkyrie_print( L: Plua_State ) : Integer; cdecl;
var n : Integer;
begin
  if Assigned( LuaSystem.FPrintFunc ) then
  begin
    n := lua_gettop(L);
    if n <= 0 then Exit(0);
    for n := 1 to lua_gettop(L) do
      print_value(L,n);
  end;
  Result := 0;
end;

{ TLuaSystem }

function lua_valkyrie_require( L: Plua_State ) : Integer; cdecl;
var Arg      : AnsiString;
    Module   : AnsiString;
    Path     : AnsiString;
    FileName : AnsiString;
begin
  Log('LuaRequire, entering...');
  if lua_gettop(L) <> 1 then LuaSystem.OnError('Require has wrong amount of parameters!');
  Arg := lua_tostring( L, 1 );
  Log('LuaRequire("'+Arg+'")');

  if LuaSystem.FModuleNames.Exists(Arg) then Exit(0);

  Module := ExtractDelimited( 1, Arg, [':'] );
  Path := ExtractFilePath( Arg );
  if Module <> '' then
    Delete( Path, 1, Length( Module ) + 1 );

  if (Length(Path) > 0) and (Path[Length(Path)] = '/') then Delete(Path,Length(Path),1);
  FileName := ExtractFileName( Arg ) + '.lua';

  if Pos(':', FileName) > 0 then
    Delete( FileName, 1, Pos(':', FileName) );

  Log('LuaRequire( Module "'+Module+'", Path "'+Path+'", FileName "'+FileName+'")');

  if not LuaSystem.FRawModules.Exists(Module) then
  begin
    if not LuaSystem.FDataFiles.Exists(Module) then
      raise ELuaException.Create('require : Module "'+Module+'" not found!');
    LuaSystem.LoadStream( LuaSystem.FDataFiles[Module], Path, FileName );
  end
  else
  begin
    if Path <> '' then
      Path := LuaSystem.FRawModules[ Module ] + Path + DirectorySeparator + FileName
    else
      Path := LuaSystem.FRawModules[ Module ] + FileName;
    if not FileExists(Path) then
      raise ELuaException.Create('require : File "'+Path+'" not found!');
    LuaSystem.LoadFile( Path );
  end;

  LuaSystem.FModuleNames[ Arg ] := True;
  Exit( 0 );
end;

function lua_core_log(L: Plua_State): Integer; cdecl;
var State : TLuaState;
begin
  State.Init( L );
  Log( State.ToString(1) );
  Result := 0;
end;

function lua_core_define(L: Plua_State): Integer; cdecl;
var State : TLuaState;
begin
  State.Init( L );
  LuaSystem.FDefines[ State.ToString(1) ] := State.ToInteger(2);
  Result := 0;
end;

function lua_core_undefine(L: Plua_State): Integer; cdecl;
var State : TLuaState;
begin
  State.Init(L);
  LuaSystem.Defines.Remove(State.ToString(1));
  Result := 0;
end;

function lua_core_declare(L: Plua_State): Integer; cdecl;
begin
  if lua_gettop(L) < 1 then Exit(0);
  if lua_gettop(L) = 1 then lua_pushboolean( L, false );
  lua_settop( L, 2 );
  lua_rawset( L, LUA_GLOBALSINDEX );
  Result := 0;
end;

function lua_core_make_id(L: Plua_State): Integer; cdecl;
const ValidChars = ['a'..'z','_','-','A'..'Z','0','1'..'9'];
var State  : TLuaState;
    iName  : AnsiString;
    iCount : DWord;
begin
  State.Init(L);
  iName := LowerCase( State.ToString(1) );
  for iCount := 1 to Length(iName) do
    if not (iName[iCount] in ValidChars) then
      iName[iCount] := '_';
  State.Push(iName);
  Result := 1;
end;

const lua_core_lib : array[0..7] of luaL_Reg = (
    ( name : 'log';       func : @lua_core_log),
    ( name : 'define';    func : @lua_core_define),
    ( name : 'undefine';  func : @lua_core_undefine),
    ( name : 'declare';   func : @lua_core_declare),
    ( name : 'make_id';   func : @lua_core_make_id),
    ( name : 'require';   func : @lua_valkyrie_require),
    ( name : 'print';     func : @lua_valkyrie_print),
    ( name : nil;         func : nil; )
);

{ TLuaClassInfo }

constructor TLuaClassInfo.Create ( const Proto, Storage : AnsiString ) ;
begin
  FProto := Proto;
  FStorage := Storage;
  FHookSet := [];
  FHookMax := 0;
end;

procedure TLuaClassInfo.RegisterHook ( HookID : Byte; const HookName : AnsiString ) ;
begin
  if HookID > High(FHooks) then SetLength( FHooks, Max(Max( 2*Length( FHooks ), 16 ),HookID ) );
  FHooks[ HookID ] := HookName;
  Include( FHookSet, HookID );
  FHookMax := Max( FHookMax, HookID );
end;

function TLuaClassInfo.GetHook ( HookID : Byte ) : AnsiString;
begin
  if HookID > High(FHooks) then Exit('');
  Exit( FHooks[ HookID ] );
end;

constructor TLuaSystem.Create( coverState : Plua_State = nil );
begin
  inherited Create;
  LoadLua;
  FCallDefVal  := NULL;
  FLua         := TLua.Create( coverState );
  FState       := FLua.NativeState;
  FModuleNames := TStringBoolMap.Create;
  FDataFiles   := TStringDataFileMap.Create;
  FRawModules  := TStringStringMap.Create;
  FDefines     := TIntMap.Create( HashMap_RaiseAll );
  FErrorFunc   := nil;
  FClassMap    := TLuaClassMap.Create();
  FLuaState.Init( FState );
  vlua_register( FState, 'print', @lua_valkyrie_print );
  vlua_register( FState, 'core', lua_core_lib );
end;

destructor TLuaSystem.Destroy;
begin
  FreeAndNil( FModuleNames );
  FreeAndNil( FDataFiles );
  FreeAndNil( FRawModules );
  FreeAndNil( FClassMap );
  FreeAndNil( FDefines );
  inherited Destroy;
  LuaSystem := nil;
end;

function TLuaSystem.Defined(const Path: AnsiString): Boolean;
begin
  if not vlua_getpath( FState, Path ) then Exit( False );
  lua_pop( FState, 1 );
  Exit( True );
end;

function TLuaSystem.Defined(const Path: array of const): Boolean;
begin
  if not vlua_getpath( FState, Path ) then Exit( False );
  lua_pop( FState, 1 );
  Exit( True );
end;

function TLuaSystem.GetTable ( const Path : AnsiString ) : TLuaTable;
begin
  Exit( TLuaTable.Create( Raw, Path ) );
end;

function TLuaSystem.GetTable ( const Path : array of const ) : TLuaTable;
begin
  Exit( TLuaTable.Create( Raw, Path ) );
end;

function TLuaSystem.GetTableSize ( const Path : AnsiString ) : DWord;
begin
  GetTableSize := 0;
  if not vlua_getpath( FState, Path ) then raise ELuaException.Create('Get('+Path+') failed!');
  if lua_istable( FState, -1 ) then
    GetTableSize := lua_objlen( FState, -1 );
  lua_pop( FState, 1 );
end;

function TLuaSystem.GetTableSize ( const Path : array of const ) : DWord;
begin
  GetTableSize := 0;
  if not vlua_getpath( FState, Path ) then raise ELuaException.Create('Get('+PathToString( Path )+') failed!');
  if lua_istable( FState, -1 ) then
    GetTableSize := lua_objlen( FState, -1 );
  lua_pop( FState, 1 );
end;

function TLuaSystem.Get(const Path: AnsiString): Variant;
begin
  if not vlua_getpath( FState, Path ) then raise ELuaException.Create('Get('+Path+') failed!');
  Get := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

function TLuaSystem.Get(const Path: array of const): Variant;
begin
  if not vlua_getpath( FState, Path ) then raise ELuaException.Create('Get('+PathToString( Path )+') failed!');
  Get := vlua_tovariant( FState, -1 );
  lua_pop( FState, 1 );
end;

function TLuaSystem.Get(const Path: AnsiString; const DefVal: Variant
  ): Variant;
begin
  if not vlua_getpath( FState, Path ) then Exit( DefVal );
  Get := vlua_tovariant( FState, -1, DefVal );
  lua_pop( FState, 1 );
end;

function TLuaSystem.Get(const Path: array of const; const DefVal: Variant
  ): Variant;
begin
  if not vlua_getpath( FState, Path ) then Exit( DefVal );
  Get := vlua_tovariant( FState, -1, DefVal );
  lua_pop( FState, 1 );
end;

procedure TLuaSystem.SetValue ( const Path : AnsiString; const Value : Variant ) ;
var Index : Integer;
begin
  Index := GetPath( Path );
  vlua_pushvariant( FState, Value );
  lua_rawset( FState, Index );
  if Index <> LUA_GLOBALSINDEX then lua_pop( FState, 1 );
end;

procedure TLuaSystem.SetValue ( const Path : array of const; const Value : Variant ) ;
var Index : Integer;
begin
  Index := GetPath( Path );
  vlua_pushvariant( FState, Value );
  lua_rawset( FState, Index );
  if Index <> LUA_GLOBALSINDEX then lua_pop( FState, 1 );
end;

procedure TLuaSystem.SetValue ( const Path : AnsiString; aObject : TObject ) ;
var Index : Integer;
begin
  Index := GetPath( Path );
  vlua_pushobject( FState, aObject );
  lua_rawset( FState, Index );
  if Index <> LUA_GLOBALSINDEX then lua_pop( FState, 1 );
end;

procedure TLuaSystem.SetValue ( const Path : array of const; aObject : TObject ) ;
var Index : Integer;
begin
  Index := GetPath( Path );
  vlua_pushobject( FState, aObject );
  lua_rawset( FState, Index );
  if Index <> LUA_GLOBALSINDEX then lua_pop( FState, 1 );
end;

function TLuaSystem.Call(const Path: array of const; const Args: array of const): Variant;
begin
  if not vlua_getpath( FState, Path ) then raise ELuaException.Create('Call('+PathToString( Path )+') not found!');
  try
    if not lua_isfunction( FState, -1 ) then raise ELuaException.Create('Call('+PathToString( Path )+') not a function!');
    vlua_pusharray( FState, Args );
    if lua_pcall( FState, High( Args ) + 1, 1, 0 ) <> 0 then  raise ELuaException.Create( 'Call('+PathToString( Path )+') Lua error : '+lua_tostring( FState, -1) );
    Call := vlua_tovariant( FState, -1, FCallDefVal );
  finally
    lua_pop( FState, 1 );
  end;
end;

function TLuaSystem.Call(const Path: AnsiString; const Args: array of const): Variant;
begin
  if not vlua_getpath( FState, Path ) then raise ELuaException.Create('Call('+Path+') not found!');
  try
    if not lua_isfunction( FState, -1 ) then raise ELuaException.Create('Call('+Path+') not a function!');
    vlua_pusharray( FState, Args );
    if lua_pcall( FState, High( Args ) + 1, 1, 0 ) <> 0 then  raise ELuaException.Create( 'Call('+Path+') Lua error : '+lua_tostring( FState, -1) );
    Call := vlua_tovariant( FState, -1, FCallDefVal );
  finally
    lua_pop( FState, 1 );
  end;
end;

function TLuaSystem.GetProtoTable ( aObj : TObject ) : TLuaTable;
begin
  Exit( TLuaTable.Create( Raw, [ FClassMap[ aObj.ClassName ].Storage, (aObj as ILuaReferencedObject).GetID ] ) );

end;

function TLuaSystem.RunHook(Obj: ILuaReferencedObject; HookName: AnsiString; const Params: array of const): Variant;
begin
  State.Init( Raw );
  RunHook := State.RunHook( Obj, HookName, Params );
end;

function TLuaSystem.ProtectedCall(const Path: array of const; const Args: array of const): Variant;
begin
  try
    Exit( Call( Path, Args ) );
  except on e : Exception do
  begin
    ErrorLogOpen('ERROR','Lua call '+DebugToString(@Path[High(Path)])+' caught '+e.ClassName+'!');
    ErrorLogWriteln('Call path     : '+PathToString( Path ));
    ErrorLogWriteln('Call params   : '+DebugToString( Args ));
    ErrorLogWriteln('Error message : '+e.Message);
    ErrorLogClose;
    ProtectedCall := False;
    OnError( PathToString( Path ) + ' -- ' + e.Message );
  end;
  end;
end;

function TLuaSystem.ProtectedCall(const Path: AnsiString; const Args: array of const): Variant;
begin
  try
    Exit( Call( Path, Args ) );
  except on e : Exception do
  begin
    ErrorLogOpen('ERROR','Lua call '+Path+' caught '+e.ClassName+'!');
    ErrorLogWriteln('Call path     : '+Path );
    ErrorLogWriteln('Call params   : '+DebugToString( Args ));
    ErrorLogWriteln('Error message : '+e.Message);
    ErrorLogClose;
    ProtectedCall := False;
    OnError( Path + ' -- ' + e.Message );
  end;
  end;
end;

function TLuaSystem.ProtectedRunHook(Obj: ILuaReferencedObject; HookName: AnsiString; const Params: array of const): Variant;
begin
  try
    ProtectedRunHook := FLuaState.RunHook( Obj, HookName, Params );
  except
    on e : Exception do
    begin
      ErrorLogOpen('ERROR','Lua hook '+HookName+' caught '+e.ClassName+'!');
      ErrorLogWriteln('Call path     : '+Obj.GetProtoTable+'['+Obj.GetID+'].'+HookName );
      ErrorLogWriteln('Call params   : '+DebugToString( Params ));
      ErrorLogWriteln('Error message : '+e.Message);
      ErrorLogClose;
      ProtectedRunHook := False;
      OnError( Obj.GetProtoTable+'['+Obj.GetID+'].'+HookName + ' -- ' + e.Message );
    end;
  end;
end;

procedure TLuaSystem.Register(const libname: AnsiString; const lr: PluaL_Reg);
begin
  vlua_register( FState, libname, lr );
end;

procedure TLuaSystem.LoadFile( const FileName: AnsiString );
begin
  if luaL_dofile( FState, PChar(FileName) ) <> 0 then
    raise ELuaException.Create( lua_tostring(FState,-1) );
end;

procedure TLuaSystem.LoadStream( IST: TStream; StreamName: AnsiString; Size: DWord );
begin
  Log('Reading "'+StreamName+'" size ('+IntToStr(Size)+'bytes) ('+IntToStr(IST.Position)+'-'+IntToStr(IST.Position+Size)+')');
  if vlua_loadstream( FState, IST, Size, StreamName ) <> 0 then
    begin
      Lua.Error(StreamName+': '+lua_tostring(FState,-1));
      lua_pop(FState,1);
      Exit;
    end;
  FreeAndNil( ISt );
  if lua_pcall(FState, 0, 0, 0)  <> 0 then
  begin
    Lua.Error(StreamName+': '+lua_tostring(FState,-1));
    lua_pop(FState,1);
  end;

  Log('Loaded "'+StreamName+'" ('+IntToStr(Size)+'bytes)');
end;

procedure TLuaSystem.LoadStream(DF: TVDataFile; const StreamName: AnsiString);
var Stream : TStream;
    Size   : Int64;
begin
  Stream := DF.GetFile( StreamName );
  Size   := DF.GetFileSize( StreamName );
  LoadStream( Stream, StreamName, Size );
end;


procedure TLuaSystem.LoadStream(DF: TVDataFile; const DirName, FileName: AnsiString);
var Stream : TStream;
    Size   : Int64;
begin
  Stream := DF.GetFile( FileName, DirName );
  Size   := DF.GetFileSize( FileName, DirName );
  LoadStream( Stream, FileName, Size );
end;

procedure TLuaSystem.OnError(const Message: AnsiString);
begin
  if Assigned( FErrorFunc ) then FErrorFunc( Message );
end;

procedure TLuaSystem.RegisterModule( const ModuleName: AnsiString; DF: TVDataFile );
begin
  FDataFiles[ ModuleName ] := DF;
  Lua.Register('require', @lua_valkyrie_require );
end;

procedure TLuaSystem.RegisterModule( const ModuleName, ModulePath: AnsiString);
begin
  FRawModules[ ModuleName ] := ModulePath;
  Lua.Register('require', @lua_valkyrie_require );
end;

procedure TLuaSystem.RegisterType(AClass: TClass; const ProtoName, StorageName: AnsiString);
begin
  FClassMap[ AClass.ClassName ] := TLuaClassInfo.Create( ProtoName, StorageName );
end;

function TLuaSystem.GetClassInfo ( AClass : TClass ) : TLuaClassInfo;
begin
  GetClassInfo := FClassMap[ AClass.ClassName ];
  Assert( GetClassInfo <> nil );
end;

function TLuaSystem.GetProtoTable(AClass: TClass): AnsiString;
begin
  Exit( FClassMap[ AClass.ClassName ].Proto );
end;

function TLuaSystem.GetStorageTable(AClass: TClass): AnsiString;
begin
  Exit( FClassMap[ AClass.ClassName ].Storage );
end;

function TLuaSystem.RegisterObject(Obj: TObject): Integer;
begin
  lua_getglobal( FState, FClassMap[ Obj.ClassName ].Proto );
  if lua_isnil( FState, -1 ) then raise ELuaException.Create( Obj.ClassName + ' type not registered!' );
  DeepPointerCopy( -1, Obj );
  RegisterObject := luaL_ref( FState, LUA_REGISTRYINDEX );
  lua_pop( FState, 1);
end;

procedure TLuaSystem.UnRegisterObject(Obj: ILuaReferencedObject);
begin
  lua_rawgeti( FState, LUA_REGISTRYINDEX, Obj.GetLuaIndex );
  lua_pushstring( FState, '__ptr' );
  lua_pushboolean( FState, False );
  lua_rawset( FState, -3 );
  lua_pop( FState, 1 );
  luaL_unref( FState, LUA_REGISTRYINDEX, Obj.GetLuaIndex );
end;

function TLuaSystem.GetMemoryKB : DWord;
begin
  Exit( lua_gc( FState, LUA_GCCOUNT, 0 ) );
end;

function TLuaSystem.GetMemoryB : DWord;
begin
  Exit( 1024*lua_gc( FState, LUA_GCCOUNT, 0 ) + lua_gc( FState, LUA_GCCOUNTB, 0 ) );
end;

procedure TLuaSystem.CollectGarbage;
begin
  lua_gc( FState, LUA_GCCOLLECT, 0 );
end;

procedure TLuaSystem.SetPrintFunction ( aPrintFunc : TLuaSystemPrintFunc ) ;
begin
  FPrintFunc := aPrintFunc;
end;

procedure TLuaSystem.Print ( const aText : AnsiString ) ;
begin
  if Assigned( FPrintFunc ) then
    FPrintFunc( aText );
end;

procedure TLuaSystem.ConsoleExecute ( const aCode : AnsiString ) ;
var iError : AnsiString;
    iCode  : Integer;
    iStack : Integer;
    cmd    : AnsiString;
begin
  cmd := Trim(aCode);
  if length(cmd) = 0 then Exit;
  iStack := lua_gettop(FState);
  Print('@B('+IntToStr(iStack)+')> @l'+cmd);

  if cmd[1] = '=' then
  begin
    Delete(cmd,1,1);
    cmd := 'return '+cmd;
  end;

  iCode := luaL_loadstring(FState, PChar(cmd));
  if iCode = 0 then iCode := lua_pcall(FState, 0, LUA_MULTRET, 0);
  if iCode <> 0 then
  begin
    iError := lua_tostring(FState,-1);
    Print('@RError: @l'+iError);
    lua_pop(FState,1);
    Exit;
  end;

  if lua_gettop(FState) > iStack then
  for iCode := iStack+1 to lua_gettop(FState) do
    print_value(FState,iCode);
  lua_settop(FState,iStack);
end;

function TLuaSystem.GetPath ( const Path : AnsiString ) : Integer;
var RP   : Word;
begin
  RP := RPos( '.', Path );
  if RP < 1 then
  begin
    lua_pushansistring( FState, Path );
    Exit( LUA_GLOBALSINDEX );
  end
  else
  begin
    if not vlua_getpath( FState, LeftStr( Path, RP-1 ) ) then raise ELuaException.Create('Get('+Path+') failed!');
    lua_pushansistring( FState, Copy( Path, RP+1, Length( Path ) - RP ) );
    Exit( -3 );
  end;
end;

function TLuaSystem.GetPath ( const Path : array of const ) : Integer;
begin
  Assert( High( Path ) >= 0 );
  if High( Path ) = 0 then
  begin
    vlua_pushvarrec( FState, @Path[0] );
    Exit( LUA_GLOBALSINDEX );
  end
  else
  begin
    if not vlua_getpath( FState, Path, High(Path) - 1 ) then raise ELuaException.Create('Get('+PathToString( Path )+') failed!');
    vlua_pushvarrec( FState, @Path[High( Path )] );
    Exit( -3 );
  end;
end;

function TLuaSystem.PathToString(const Path: array of const): AnsiString;
var i : Integer;
begin
try
  If High(Path) < 0 then
  begin
    Exit('<empty>');
  end;
  PathToString := '';
  for i:=0 to High(Path) do
  begin
    if i <> 0 then PathToString += '.';
    PathToString += DebugToString(@(path[i]));
  end;
except on e : Exception do
  PathToString := 'exception on PathToString'
end;
end;

procedure TLuaSystem.DeepPointerCopy(Index: Integer; Obj : Pointer );
var HasFunctions : Boolean;
    HasMetatable : Boolean;
begin
  index := lua_absindex( FState, index );
  lua_newtable( FState );
  lua_pushnil( FState );
  HasFunctions := false;
  HasMetatable := false;

  while lua_next( FState, index ) <> 0 do
  begin
    if lua_isfunction( FState, -1 ) then HasFunctions := true
    else if lua_istable( FState, -1 ) then
    begin
      DeepPointerCopy( -1, Obj );
      lua_insert( FState, -2 );
      lua_pop( FState, 1 );
    end;
    lua_pushvalue( FState, -2 );
    lua_insert( FState, -2 );
    lua_settable( FState, -4 );
  end;

  if lua_getmetatable( FState, -2 ) then
  begin
    lua_setmetatable( FState, -2 );
    HasMetatable := true;
  end;

  if HasFunctions or HasMetatable then
  begin
    lua_pushstring( FState, '__ptr' );
    lua_pushlightuserdata( FState, Obj );
    lua_rawset( FState, -3 );
  end;
end;


end.

