{$INCLUDE valkyrie.inc}
unit vlua;
interface
uses Variants, vlualibrary, vnode,vutil,classes,vdf;


type
  TStringToByteFunction = function(const s : AnsiString) : byte of object;
  ELuaException         = vlualibrary.ELuaException;


type
  Plua_State    = vlualibrary.Plua_State;
  TLuaErrorFunc = procedure ( const ErrorString : Ansistring ) of object;

{ TLua }

type TLua = class(TVObject)
  constructor Create( coverState : Plua_State = nil ); virtual;

  procedure LoadFile(const FileName : AnsiString);
  procedure StreamLoader(IST : TStream; StreamName : AnsiString;  Size : DWord);
  procedure StreamLoaderDestroy(IST : TStream; StreamName : AnsiString;  Size : DWord);
  procedure LoadStream( DF : TVDataFile; const StreamName : AnsiString); overload;
  procedure LoadStream( DF : TVDataFile; const DirName, FileName : AnsiString ); overload;

  function FunctionExists(const Name : AnsiString) : boolean;
  function Defined(const Name : AnsiString) : boolean;
  function Defined(const Name : AnsiString; Index : Variant) : boolean;
  procedure ExecuteString( const Code : AnsiString );
  function Execute(const Name : AnsiString; const args : Array of Variant ) : Variant;
  function Execute(const Name : AnsiString) : Variant;
  function TableExecute(const Table, Name : AnsiString; const args : Array of Variant ) : Variant;
  function TableExecute(const Table, Name : AnsiString) : Variant;
  function TableExecute(const Table : AnsiString; Index : Variant; const Name : AnsiString; const args : Array of Variant ) : Variant;
  function TableExecute(const Table : AnsiString; Index : Variant; const Name : AnsiString) : Variant;
  function ExecuteCommand(const Command : AnsiString) : boolean;
  procedure Register(const Name : AnsiString; Proc : lua_CFunction);
  procedure Register(const Key, Value : Variant);
  procedure Error(const ErrorString : Ansistring); virtual;
  destructor Destroy; override;

  procedure SetVariable( const Name : AnsiString; Value : Variant );
  function GetVariable( const Name : AnsiString) : Variant;

  procedure SetTableVariable( const Table : AnsiString; Index, Value : Variant );
  function GetTableVariable( const Table : AnsiString; Index : Variant ) : Variant;

  procedure SetTableVariable( const Table : AnsiString; Index : Variant; const Field : AnsiString; Value : Variant );
  function GetTableVariable( const Table : AnsiString; Index : Variant; const Field : AnsiString ) : Variant;

  procedure SetTableFunction( const Table : AnsiString; Index : Variant; Func : lua_CFunction );
  procedure SetTableFunction( const Table,Subtable : AnsiString; Index : Variant; Func : lua_CFunction );

  property Variables[ Index : AnsiString ] : Variant read GetVariable write SetVariable; default;
  property Table[ aTable : AnsiString; Index : Variant ] : Variant read GetTableVariable write SetTableVariable;
  property IndexedTable[ aTable : AnsiString; Index : Variant; Field : AnsiString ] : Variant read GetTableVariable write SetTableVariable;
public
  LuaState    : Plua_State;
  ErrorStr    : AnsiString;
  Owner       : Boolean;
  FErrorFunc  : TLuaErrorFunc;

public
  property NativeState : Plua_state read LuaState;
end;

{ TLuaTable }

TLuaTable = class(TVObject)
  constructor Create( aLua : TLua; aName : AnsiString );
  constructor Create( aLua : TLua; aName : AnsiString; aIndex : AnsiString );
  constructor Create( aLua : TLua; aName : AnsiString; aIndex : LongInt );
  constructor Create( aLua : TLua; aName : AnsiString; aIndex : Variant );
  function isFunction(const ID : AnsiString) : boolean;
  function Defined(const Name : AnsiString) : boolean;

  function getNumber(const ID : AnsiString) : LongInt;
  function getFloat(const ID : AnsiString) : Real;
  function getString(const ID : AnsiString) : AnsiString;
  function getChar(const ID : AnsiString) : Char;
  function getBoolean(const ID : AnsiString) : boolean;
  function getFlags(const ID : AnsiString) : TFlags;
  function getCharTranslation(const ID : AnsiString; const Translate : TStringToByteFunction) : TPrintableCharToByte;
  function getValue(const ID : AnsiString; const args : array of Variant ) : Variant;

//  procedure setNumber(const ID : AnsiString; v : LongInt );
//  procedure setFloat(const ID : AnsiString; v : Real );
  procedure setString(ID : AnsiString; v : AnsiString );
//  procedure setBoolean(const ID : AnsiString; v : boolean );
//  procedure setFlags(const ID : AnsiString; v : TFlags );

  function Execute(const ID : AnsiString; const args : Array of Variant ) : Variant;
  function Execute(const ID : AnsiString) : Variant;

  procedure SetVariable( const Name : AnsiString; Value : Variant );
  function GetVariable( const Name : AnsiString) : Variant;

  property Variables[ Index : AnsiString ] : Variant read GetVariable write SetVariable; default;

  destructor Destroy; override;

  procedure WriteToStream( OSt : TStream );
  procedure ReadFromStream( ISt : TStream );
private
  mLua  : TLua;
  mName : AnsiString;
  mPop  : Byte;
public
  property LuaState : TLua read mLua;
end;

implementation
uses SysUtils, strutils, vdebug, vluaext;

function lua_math_random(L: Plua_State): Integer; cdecl;
var Args : Byte;
    Arg1 : LongInt;
    Arg2 : LongInt;
begin
  Args := lua_gettop(L);
  case Args of
    0 : lua_pushnumber( L, Random );
    1 : lua_pushnumber( L, Random( Round(lua_tonumber(L, 1)) ) + 1 );
    2 : begin
          Arg1 := Round(lua_tonumber(L, 1));
          Arg2 := Round(lua_tonumber(L, 2));
          if Arg2 >= Arg1 then
            lua_pushnumber( L, Random( Arg2-Arg1+1 ) + Arg1 )
          else
            lua_pushnumber( L, Random( Arg1-Arg2+1 ) + Arg2 )
        end;
    else Exit(0);
  end;
  Result := 1;
end;

constructor TLua.Create( coverState : Plua_State = nil );
begin
  LoadLua;
  if coverState = nil then
  begin
    LuaState := lua_open;
    luaopen_base(LuaState);
    luaopen_string(LuaState);
    luaopen_table(LuaState);
    luaopen_math(LuaState);
    Owner := True;
  end
  else
  begin
    Owner := False;
    LuaState := coverState;
  end;

  FErrorFunc  := nil;
  SetTableFunction('math','random',@lua_math_random);
end;

procedure TLua.LoadFile(const FileName : AnsiString);
begin
  if luaL_dofile(LuaState, PChar(FileName)) <> 0 then
    raise ELuaException.Create(lua_tostring(LuaState,-1));
end;

procedure TLua.LoadStream(DF: TVDataFile; const StreamName: AnsiString);
var Stream : TStream;
    Size   : Int64;
begin
  Stream := DF.GetFile(StreamName);
  Size   := DF.GetFileSize(StreamName);
  StreamLoaderDestroy(Stream,StreamName,Size);
end;

procedure TLua.LoadStream(DF: TVDataFile; const DirName, FileName: AnsiString);
var Stream : TStream;
    Size   : Int64;
begin
  Stream := DF.GetFile(FileName,DirName);
  Size   := DF.GetFileSize(FileName,DirName);
  StreamLoaderDestroy(Stream,FileName,Size);
end;

procedure TLua.StreamLoader(IST : TStream; StreamName : AnsiString;  Size : DWord);
var Buf  : PByte;
begin
  Log('Loading LUA stream -- "'+StreamName+'" ('+IntToStr(Size)+'b)');
  GetMem(Buf,Size);
  Log('Reading "'+StreamName+'" ('+IntToStr(IST.Position)+'-'+IntToStr(IST.Position+Size)+')');
  IST.ReadBuffer(Buf^,Size);
  if luaL_loadbuffer(LuaState,PChar(Buf),Size,PChar(StreamName)) <> 0 then
    begin
      ErrorStr := lua_tostring(LuaState,-1);
      Error(StreamName+': '+ErrorStr);
      lua_pop(LuaState,1);
    end
  else
    if lua_pcall(LuaState, 0, 0, 0)  <> 0 then
    begin
      ErrorStr := lua_tostring(LuaState,-1);
      Error(StreamName+': '+ErrorStr);
      lua_pop(LuaState,1);
    end;

  FreeMem(Buf);
  Log('Loaded "'+StreamName+'" ('+IntToStr(Size)+'b)');
end;

procedure TLua.StreamLoaderDestroy(IST: TStream; StreamName: AnsiString; Size: DWord);
var Buf  : PByte;
begin
  Log('Loading LUA stream -- "'+StreamName+'" ('+IntToStr(Size)+'b)');
  GetMem(Buf,Size);
  Log('Reading "'+StreamName+'" ('+IntToStr(IST.Position)+'-'+IntToStr(IST.Position+Size)+')');
  IST.ReadBuffer(Buf^,Size);
  FreeAndNil(ISt);
  if luaL_loadbuffer(LuaState,PChar(Buf),Size,PChar(StreamName)) <> 0 then
    begin
      ErrorStr := lua_tostring(LuaState,-1);
      Error(StreamName+': '+ErrorStr);
      lua_pop(LuaState,1);
    end
  else
    if lua_pcall(LuaState, 0, 0, 0)  <> 0 then
    begin
      ErrorStr := lua_tostring(LuaState,-1);
      Error(StreamName+': '+ErrorStr);
      lua_pop(LuaState,1);
    end;

  FreeMem(Buf);
  Log('Loaded "'+StreamName+'" ('+IntToStr(Size)+'b)');

end;


function TLua.FunctionExists( const Name : AnsiString ) : boolean;
begin
  Exit( vlua_functionexists( LuaState, Name, LUA_GLOBALSINDEX ) );
end;

function TLua.Defined(const Name: AnsiString): boolean;
begin
  lua_pushansistring(LuaState, Name);
  lua_rawget(LuaState, LUA_GLOBALSINDEX );
  Result := not lua_isnil( LuaState, lua_gettop(LuaState) );
  lua_pop( LuaState, 1 );
end;

function TLua.Defined(const Name : AnsiString; Index : Variant) : boolean;
begin
  lua_pushansistring(LuaState, Name);
  lua_rawget(LuaState, LUA_GLOBALSINDEX );
  if not lua_istable( LuaState, lua_gettop(LuaState) ) then
  begin
    lua_pop( LuaState, 1 );
    Exit( False );
  end;
  vlua_pushvariant(LuaState, Index);
  lua_rawget(LuaState, -2);
  Result := not lua_isnil( LuaState, lua_gettop(LuaState) );
  lua_pop( LuaState, 2 );
end;

procedure TLua.ExecuteString(const Code: AnsiString);
var ErrorMsg : AnsiString;
begin
  if luaL_dostring( LuaState, PChar(Code) ) <> 0 then
  begin
    ErrorMsg := lua_tostring( LuaState, -1 );
    Error('Error: '+ErrorMsg);
    lua_pop( LuaState, 1 );
  end;
end;


function TLua.Execute(const Name : AnsiString; const args : array of Variant
  ) : Variant;
begin
  Exit( vlua_callfunction( LuaState, Name, args ) );
end;

function TLua.Execute(const Name : AnsiString) : Variant;
begin
  Exit( vlua_callfunction( LuaState, Name, [] ) );
end;

function TLua.TableExecute(const Table, Name : AnsiString;
  const args : array of Variant) : Variant;
begin
  lua_getglobal( LuaState, Table );
  TableExecute := vlua_callfunction( LuaState, Name, args, -2 );
  lua_pop( LuaState, 1 );
end;

function TLua.TableExecute(const Table, Name : AnsiString) : Variant;
begin
  Exit( TableExecute( Table, Name, [] ) );
end;

function TLua.TableExecute(const Table : AnsiString; Index : Variant;
  const Name : AnsiString; const args : array of Variant) : Variant;
begin
  lua_getglobal( LuaState, Table );
  vlua_pushvariant( LuaState, Index );
  lua_gettable( LuaState, -2 );
  TableExecute := vlua_callfunction( LuaState, Name, args, -2 );
  lua_pop( LuaState, 2);
end;

function TLua.TableExecute(const Table : AnsiString; Index : Variant;
  const Name : AnsiString) : Variant;
begin
  Exit( TableExecute( Table, Index, Name, [] ) );
end;

function TLua.ExecuteCommand(const Command : AnsiString) : boolean;
var Ansi,Args,Arg : AnsiString;
    Count         : Byte;
begin
  Ansi := Copy2Symb(Command,'(');
  Args := ExtractDelimited(2,Command,['(',')']);

  if Args = '' then Exit(Execute(Ansi));

  lua_getglobal(LuaState, Ansi);

  Count := 1;
  repeat
    ///////////////////// MAY BE OPTIMIZED USING SPLIT INSTEAD OF Parameter
    Arg := ExtractDelimited(Count,Args,[',']);

    ///////////////////// NO  ERROR CHECKING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if Arg = '' then Break;
    Arg := Trim(Arg);
    case Arg[1] of
      '-','0'..'9' : lua_pushnumber(LuaState,StrToInt(Arg));
      'T','t'      : lua_pushboolean(LuaState,true);
      'F','f'      : lua_pushboolean(LuaState,false);
      ''''         : begin Ansi := ExtractDelimited(2,Arg,['''']); lua_pushansistring(LuaState,Ansi); end;
      '"'          : begin Ansi := ExtractDelimited(2,Arg,['"']);  lua_pushansistring(LuaState,Ansi); end;
      else Log('Invalid command arguments passed to ExecuteCommand : '+Command);
    end;
    Inc(Count);
  until Arg = '';

  if lua_pcall(LuaState, Count-1,0,0) <> 0 then
  begin
    ErrorStr := lua_tostring(LuaState,-1);
    Error(Command+': '+ErrorStr);
    lua_pop(LuaState,1);
    Exit(False);
  end;
  Exit(True);
end;

procedure TLua.Register(const Name : AnsiString; Proc : lua_CFunction);
begin
  lua_register(LuaState, Name, Proc);
end;

procedure TLua.Register(const Key, Value: Variant);
begin
  vlua_pushvariant( LuaState, key );
  vlua_pushvariant( LuaState, value );
  lua_rawset( LuaState, LUA_GLOBALSINDEX );
end;

procedure TLua.Error(const ErrorString: Ansistring);
begin
  if Assigned( FErrorFunc ) then
    FErrorFunc( ErrorString )
  else
    Log('LuaError: '+ErrorString);
end;

destructor TLua.Destroy;
begin
  if Owner then
  begin
    lua_close(LuaState);
    Log('Lua closed.');
  end;
  inherited Destroy;
end;

procedure TLua.SetVariable(const Name : AnsiString; Value : Variant);
begin
  lua_pushansistring( LuaState, Name );
  vlua_pushvariant( LuaState, value );
  lua_rawset( LuaState, LUA_GLOBALSINDEX );
end;

function TLua.GetVariable(const Name : AnsiString) : Variant;
begin
  lua_getglobal( LuaState, Name );
  try
    GetVariable := vlua_tovariant( LuaState,-1 );
  finally
    lua_pop( LuaState, 1 );
  end;
  if VarIsNull(GetVariable) then GetVariable := '';
end;

procedure TLua.SetTableVariable(const Table : AnsiString; Index,Value : Variant);
begin
  lua_getglobal( LuaState, Table );
  vlua_pushvariant( LuaState, Index );
  vlua_pushvariant( LuaState, value );
  lua_settable( LuaState, -3);
  lua_pop( LuaState, 1);
end;

function TLua.GetTableVariable(const Table : AnsiString; Index : Variant ) : Variant;
begin
  lua_getglobal( LuaState, Table );
  vlua_pushvariant( LuaState, Index );
  lua_gettable( LuaState, -2 );
  try
    GetTableVariable := vlua_tovariant( LuaState, -1 );
  finally
    lua_pop( LuaState, 2 );
  end;
  if VarIsNull(GetTableVariable) then GetTableVariable := '';
end;

procedure TLua.SetTableVariable(const Table : AnsiString; Index : Variant; const Field : AnsiString; Value : Variant);
begin
  lua_getglobal( LuaState, Table );
  vlua_pushvariant( LuaState, Index );
  lua_gettable( LuaState, -2 );
  lua_pushansistring( LuaState, Field );
  vlua_pushvariant( LuaState, value );
  lua_settable( LuaState, -3 );
  lua_pop( LuaState, 2);
end;

function TLua.GetTableVariable(const Table : AnsiString; Index : Variant; const Field : AnsiString) : Variant;
begin
  lua_getglobal( LuaState, Table );
  vlua_pushvariant( LuaState, Index );
  lua_gettable( LuaState, -2 );
  lua_pushansistring( LuaState, Field );
  lua_gettable( LuaState, -2 );
  try
    GetTableVariable := vlua_tovariant( LuaState, -1 );
  finally
    lua_pop( LuaState, 3 );
  end;
  if VarIsNull(GetTableVariable) then GetTableVariable := '';
end;

procedure TLua.SetTableFunction(const Table: AnsiString; Index: Variant; Func: lua_CFunction);
begin
  lua_getglobal( LuaState, Table );
  if not lua_istable(LuaState, -1) then
  begin
    lua_createtable(LuaState, 0, 1);
    lua_setglobal( LuaState, Table );

    // reset table on stack
    lua_pop(LuaState, 1);
    lua_getglobal( LuaState, Table );
  end;

  vlua_pushvariant(LuaState, Index);
  lua_pushcfunction(LuaState, Func);
  lua_rawset(LuaState, -3);
  lua_pop(LuaState, 1);
end;

procedure TLua.SetTableFunction(const Table,SubTable: AnsiString; Index: Variant; Func: lua_CFunction);
begin
  lua_getglobal( LuaState, Table );
  if not lua_istable(LuaState, -1) then
  begin
    lua_createtable(LuaState, 0, 1);
    lua_setglobal( LuaState, Table );

    // reset table on stack
    lua_pop(LuaState, 1);
    lua_getglobal( LuaState, Table );
  end;

  lua_getfield( LuaState, -1, Pchar(SubTable) );
  if not lua_istable(LuaState, -1) then
  begin
    lua_createtable(LuaState, 0, 1);
    lua_setfield( LuaState, -3, Pchar(SubTable) );

    // reset table on stack
    lua_pop(LuaState, 1);
    lua_getfield( LuaState, -1, Pchar(SubTable) );
  end;

  vlua_pushvariant(LuaState, Index);
  lua_pushcfunction(LuaState, Func);
  lua_rawset(LuaState, -3);
  lua_pop(LuaState, 2);
end;

{ TLuaTable }

constructor TLuaTable.Create(aLua: TLua; aName: AnsiString);
begin
  mName := aName;
  mLua  := aLua;
  lua_getglobal( mLua.LuaState, mName );
  mPop := 1;
  if not lua_istable( mLua.LuaState, -1) then raise ELuaException.Create(mName+' is not a valid table!');
end;

constructor TLuaTable.Create(aLua: TLua; aName: AnsiString; aIndex : AnsiString);
begin
  Create( aLua, aName );
  lua_pushansistring( mLua.LuaState, aIndex );
  lua_gettable( mLua.LuaState, -2 );  // get tid[key]
  mPop := 2;
  if not lua_istable(mLua.LuaState, -1) then raise ELuaException.Create(mName+'['+aIndex+'] not found!');
end;

constructor TLuaTable.Create(aLua: TLua; aName: AnsiString; aIndex: LongInt);
begin
  Create( aLua, aName );
  lua_pushnumber( mLua.LuaState, aIndex );
  lua_gettable( mLua.LuaState, -2 );  // get tid[key]
  mPop := 2;
  if not lua_istable(mLua.LuaState, -1) then raise ELuaException.Create(mName+'['+IntToStr(aIndex)+'] not found!');
end;

constructor TLuaTable.Create(aLua: TLua; aName: AnsiString; aIndex: Variant);
begin
  Create( aLua, aName );
  vlua_pushvariant( mLua.LuaState, aIndex );
  lua_gettable( mLua.LuaState, -2 );  // get tid[key]
  mPop := 2;
  if not lua_istable(mLua.LuaState, -1) then raise ELuaException.Create(mName+'['+IntToStr(aIndex)+'] not found!');
end;

function TLuaTable.getNumber(const ID: AnsiString): LongInt;
begin
  lua_pushansistring( mLua.LuaState, ID );
  lua_gettable(mLua.LuaState, -2);  // get background[key] */
  if (not lua_isnumber(mLua.LuaState, -1))
    then getNumber := 0
    else getNumber := Round(lua_tonumber(mLua.LuaState, -1));
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.getFloat(const ID: AnsiString): Real;
begin
  lua_pushansistring(mLua.LuaState, ID);
  lua_gettable(mLua.LuaState, -2);  // get background[key] */
  if (not lua_isnumber(mLua.LuaState, -1))
    then getFloat := 0
    else getFloat := lua_tonumber(mLua.LuaState, -1);
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.getString(const ID: AnsiString): Ansistring;
begin
  lua_pushansistring(mLua.LuaState, ID);
  lua_gettable(mLua.LuaState, -2);  // get background[key]
  if lua_isstring(mLua.LuaState,-1) then
    getString := lua_tostring(mLua.LuaState,-1)
  else
    getString := '';
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.getChar(const ID: AnsiString): Char;
begin
  lua_pushansistring(mLua.LuaState, ID);
  lua_gettable(mLua.LuaState, -2);  // get background[key]
  if lua_isstring(mLua.LuaState,-1) and (lua_objlen(mLua.LuaState,-1) = 1) then
    getChar := lua_tostring(mLua.LuaState,-1)[1]
  else
    getChar := ' ';
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.getBoolean(const ID: AnsiString): boolean;
begin
  lua_pushansistring(mLua.LuaState, ID);
  lua_gettable(mLua.LuaState, -2);  // get background[key] */
  getBoolean := lua_toboolean(mLua.LuaState, -1);
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.isFunction(const ID: AnsiString): boolean;
begin
  Exit( vlua_functionexists( mLua.LuaState, ID, -2 ) );
end;

function TLuaTable.Defined(const Name: AnsiString): boolean;
begin
  lua_pushansistring(mLua.LuaState, Name);
  lua_gettable(mLua.LuaState, -2);
  Result := not lua_isnil( mLua.LuaState, lua_gettop(mLua.LuaState) );
  lua_pop( mLua.LuaState, 1 );
end;

function TLuaTable.getFlags(const ID : AnsiString) : TFlags;
var idn : DWord;
begin
  getFlags := [];
  lua_pushansistring(mLua.LuaState, ID);
  lua_gettable(mLua.LuaState, -2);  // get beings[ID] */
  if lua_istable(mLua.LuaState, -1) then
  begin
    idn := lua_gettop(mLua.LuaState);
    // table is in the stack at index 't'
    lua_pushnil(mLua.LuaState);  // first key */
    while (lua_next(mLua.LuaState, idn) <> 0) do
    begin
       // uses 'key' (at index -2) and 'value' (at index -1) */
       if lua_isnumber(mLua.LuaState, -1) then
         Include(getFlags,Round(lua_tonumber(mLua.LuaState, -1)));
       // removes 'value'; keeps 'key' for next iteration */
       lua_pop(mLua.LuaState, 1);
    end;
  end;
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.getCharTranslation(const ID: AnsiString; const Translate : TStringToByteFunction): TPrintableCharToByte;
var idn : DWord;
    c   : Byte;
begin
  for c := Low(TPrintableCharToByte) to High(TPrintableCharToByte) do
    getCharTranslation[c] := 0;
  lua_pushansistring(mLua.LuaState, ID);
  lua_gettable(mLua.LuaState, -2);  // get beings[ID] */
  if lua_istable(mLua.LuaState, -1) then
  begin
    idn := lua_gettop(mLua.LuaState);
    // table is in the stack at index 't'
    lua_pushnil(mLua.LuaState);  // first key */
    while (lua_next(mLua.LuaState, idn) <> 0) do
    begin
       // uses 'key' (at index -2) and 'value' (at index -1) */
       if not lua_isnumber(mLua.LuaState, -1) then
         if Assigned( Translate ) then
           getCharTranslation[Ord(lua_tostring(mLua.LuaState, -2)[1])] := Translate(lua_tostring(mLua.LuaState, -1))
         else
           getCharTranslation[Ord(lua_tostring(mLua.LuaState, -2)[1])] := Round(lua_tonumber(mLua.LuaState, -1));
       // removes 'value'; keeps 'key' for next iteration */
       lua_pop(mLua.LuaState, 1);
    end;
  end;
  lua_pop(mLua.LuaState, 1);
end;

function TLuaTable.getValue(const ID: AnsiString; const args: array of Variant): Variant;
begin
  if isFunction( ID ) then
    Exit( Execute( ID, args ) )
  else
    Exit( GetVariable( ID ) );
end;

procedure TLuaTable.setString(ID : AnsiString; v : AnsiString);
begin
  lua_pushansistring(mLua.LuaState, ID);
  lua_pushansistring(mLua.LuaState, v);
  lua_settable(mLua.LuaState, -3);
end;

function TLuaTable.Execute(const ID : AnsiString; const args : array of Variant
  ) : Variant;
begin
  Exit( vlua_callfunction( mLua.LuaState, ID, args, -2 ) );
end;

function TLuaTable.Execute(const ID: AnsiString) : Variant;
begin
  Exit( vlua_callfunction( mLua.LuaState, ID, [], -2 ) );
end;

procedure TLuaTable.SetVariable(const Name : AnsiString; Value : Variant);
begin
  lua_pushansistring( mLua.LuaState, Name );
  vlua_pushvariant( mLua.LuaState, value );
  lua_settable( mLua.LuaState, -3);
end;

function TLuaTable.GetVariable(const Name : AnsiString) : Variant;
begin
  lua_pushansistring(mLua.LuaState, Name);
  lua_gettable(mLua.LuaState, -2);  // get background[key]
  try
    GetVariable := vlua_tovariant(mLua.LuaState,-1);
  finally
    lua_pop(mLua.LuaState, 1);
  end;
end;

destructor TLuaTable.Destroy;
begin
  lua_pop( mLua.LuaState, mPop );
  inherited Destroy;
end;


procedure TLuaTable.WriteToStream(OSt: TStream);
begin
  vlua_tabletostream( mLua.LuaState, -1, OSt );
end;

procedure TLuaTable.ReadFromStream(ISt: TStream);
begin
  vlua_tablefromstream( mLua.LuaState, -1, ISt );
end;

end.

