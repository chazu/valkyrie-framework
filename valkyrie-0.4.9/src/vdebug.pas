{$INCLUDE valkyrie.inc}
// @abstract(Debugging unit for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(May 7, 2004)
//
// Core debuging engine for Valkyrie. Used by almost all
// files in the Valkyrie library. Implements Logging, Errors,
// and Warnings. All debug data is written to log.txt.
//
// vdebug also defines the @link(Debug) boolean constant. If set to
// True a lot of additional Log informations are generated.
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

unit vdebug;
interface
uses classes, sysutils;

type TLogLevel = ( LCRITICAL, LERROR, LWARNING, LINFO, LDEBUG, LTRACE );
type TWritelnFunction = procedure ( const Message : AnsiString );


const
// The global Debug
    Debug : Boolean = True;
// The global LogLevel
    LogLevel : TLogLevel = LINFO;
// Log file name
    LogFileName : AnsiString = 'log.txt';
// Error log file name
    ErrorLogFileName : AnsiString = 'error.log';
// Console write function, set to something (or nil) different on GUI systems.
// By default set to Writeln in initialization.
    DebugWriteln : TWritelnFunction = nil;

// Calls a critical error, and halts execution.
procedure CritError(const CritErrorString : Ansistring);
// Issues a warning.
procedure Warning  (const WarningString   : Ansistring);
// Logs a string into the logfile.
procedure Log      (const LogString       : Ansistring);
// Calls a critical error, and halts execution. Parameters handled via vutil.VFormat.
procedure CritError(const CritErrorString : Ansistring; const param : array of Const);
// Issues a warning. Parameters handled via vutil.VFormat.
procedure Warning  (const WarningString   : Ansistring; const param : array of Const);
// Logs a string into the logfile. Parameters handled via vutil.VFormat.
procedure Log      (const LogString       : Ansistring; const param : array of Const);


// Logs a string into the logfile.
procedure Log      (Level : TLogLevel; const LogString       : Ansistring);
// Logs a string into the logfile. Parameters handled via vutil.VFormat.
procedure Log      (Level : TLogLevel; const LogString       : Ansistring; const param : array of Const);

// Error log open
procedure ErrorLogOpen( const Severity, Message : String );
// Error log write line (formatted)
procedure ErrorLogWriteln( const Text : String; const Fmt : array of const );
// Error log write line
procedure ErrorLogWriteln( const Text : String );
// Error log close
procedure ErrorLogClose;

// Converts a array of const VType to string debug representation.
// Exception safe.
function DebugToString( VT : PVarRec ) : AnsiString;

// Converts a variant to string.
// Exception safe.
function DebugToString( const V : Variant ) : AnsiString;

// Converts a array of const to string debug representation
// Exception safe.
function DebugToString( const arr : array of const ) : AnsiString;

implementation
uses variants, vutil;

var LogFile   : Text;
    ErrorFile : Text;


//const LogName : array[TLogLevel] of string = (
//  'CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'TRACE'
//);

procedure DefaultDebugWriteln( const Message: AnsiString );
begin
  Writeln( Message );
end;

procedure DoWriteln( const Message: AnsiString );
begin
  if Assigned( DebugWriteln ) then
    DebugWriteln( Message );
end;

procedure CritError(const CritErrorString : Ansistring);
begin
  Writeln(LogFile,'Critical Error: ',CritErrorString);
  DoWriteln('Critical Error: '+CritErrorString);
  Flush(LogFile);
  Readln;
  Halt(0);
end;

procedure Warning  (const WarningString   : Ansistring);
begin
  Writeln(LogFile,'Warning: ',WarningString);
{  if Console <> nil then
  begin
    Console.Print('Warning: '+WarningString);
    Console.Call;
  end
  else
  begin}
    DoWriteln('Warning: '+WarningString);
    Readln;
  //end;
  Flush(LogFile);
end;

procedure Log      (const LogString       : Ansistring);
begin
  if LogLevel < LINFO then Exit;
  Log( LINFO, LogString );
end;

procedure CritError(const CritErrorString: Ansistring; const param: array of const);
begin
  CritError(VFormat(CritErrorString,param));
end;

procedure Warning(const WarningString: Ansistring; const param: array of const);
begin
  Warning(VFormat(WarningString,param));
end;

procedure Log(const LogString: Ansistring; const param: array of const);
begin
  if LogLevel < LINFO then Exit;
  Log( LINFO, VFormat(LogString,param));
end;

procedure Log(Level : TLogLevel; const LogString       : Ansistring);
begin
  if Level > LogLevel then Exit;
  //if Console <> nil then Console.Print(LogString);
  Writeln(LogFile,LogString);
  Flush(LogFile);
end;

procedure Log(Level : TLogLevel; const LogString: Ansistring; const param: array of const);
begin
  if Level > LogLevel then Exit;
  Log(LogLevel,VFormat(LogString,param));
end;

procedure ErrorLogOpen(const Severity, Message: String);
begin
  Assign( ErrorFile, ErrorLogFileName );
  if FileExists( ErrorLogFileName )
    then Append( ErrorFile )
    else Rewrite( ErrorFile );
  Writeln( ErrorFile, '----------------------------------------------------------------------' );
  Writeln( ErrorFile, 'Timestamp   : ', DateTimeToStr(Now) );
  Writeln( ErrorFile, 'Error level : ', Severity );
  Writeln( ErrorFile, 'Message     : ', Message );
  Writeln( ErrorFile );
end;

procedure ErrorLogWriteln(const Text: String; const Fmt: array of const);
begin
  Writeln( ErrorFile, Format( Text, Fmt ) );
end;

procedure ErrorLogWriteln(const Text: String);
begin
  Writeln( ErrorFile, Text );
end;

procedure ErrorLogClose;
begin
  Writeln( ErrorFile, '----------------------------------------------------------------------' );
  Writeln( ErrorFile );
  Close( ErrorFile );
end;

function DebugToString(VT: PVarRec): AnsiString;
begin
try
  case VT^.vtype of
    vtinteger    : DebugToString := IntToStr( VT^.vinteger );
    vtint64      : DebugToString := IntToStr( VT^.vinteger );
    vtqword      : DebugToString := IntToStr( VT^.vinteger );
    vtboolean    : if VT^.vboolean then DebugToString := 'true' else DebugToString := 'false';
    vtchar       : DebugToString := VT^.vchar;
    vtextended   : DebugToString := FloatToStr( VT^.VExtended^ );
    vtString     : DebugToString := VT^.VString^;
    vtPointer    : DebugToString := '<pointer>';
    vtPChar      : DebugToString := VT^.VPChar;
    vtObject     : DebugToString := '<object>';
    vtClass      : DebugToString := '('+TClass(VT^.VClass).Classname+')';
    vtAnsiString : DebugToString := AnsiString(VT^.VAnsiString);
  else
      DebugToString := '<UNK:'+IntToStr(VT^.vtype)+'>';
  end;
except on e : Exception do
  DebugToString := 'exception on DebugToString'
end;
end;

function DebugToString ( const V : Variant ) : AnsiString;
begin
  case VarType(V) of
    varempty    : Exit('[empty]');
    varnull     : Exit('[null]');
    vardispatch : Exit('[dispatch]');
    varerror    : Exit('[error]');
    varvariant  : Exit('[variant]');
    varunknown  : Exit('[unknown]');
    varrecord   : Exit('[record]');
    varstrarg   : Exit('[strarg]');
    varany      : Exit('[any]');
    vartypemask : Exit('[typemask]');
    vararray    : Exit('[array]');
    varbyref    : Exit('[varbyref]');
  end;
  if VarType(V) > 256 then Exit('[array]');
  Exit( VarToStr( V ) );
end;

function DebugToString(const arr: array of const): AnsiString;
var i : Integer;
begin
try
  if High(arr) < 0 then
  begin
    Exit('()');
  end;
  DebugToString := '(';
  for i:=0 to High(arr) do
  begin
    if i <> 0 then DebugToString += ',';
    DebugToString += DebugToString(@(arr[i]));
  end;
  DebugToString += ')';
except on e : Exception do
  DebugToString := 'exception on DebugToString'
end;
end;

procedure UnhandledExceptionHandler(Obj : TObject; Addr: Pointer; FrameCount: Longint; Frames: PPointer);
var
  Message : String;
  i       : longint;

  procedure Dump( Msg : String );
  begin
    DoWriteln(Msg);
    ErrorLogWriteln(Msg);
  end;

begin
  ErrorLogOpen( 'FATAL EXCEPTION', 'Fatal exception encountered' );
  {$HINTS OFF}
  Dump('An unhandled exception occurred at $'+HexStr(PtrUInt(Addr),sizeof(PtrUInt)*2)+' :');
  {$HINTS ON}
  if Obj is exception then
   begin
     Message:=Exception(Obj).ClassName+' : '+Exception(Obj).Message;
     Dump(Message);
   end
  else
   Dump('Exception object '+Obj.ClassName+' is not of class Exception.');
  Dump(BackTraceStrFunc(Addr));
  if (FrameCount>0) then
    begin
      for i:=0 to FrameCount-1 do
        Dump(BackTraceStrFunc(Frames[i]));
    end;
  Dump('');
  ErrorLogClose;
end;


initialization

exceptproc := @UnhandledExceptionHandler;
DebugWriteln := @DefaultDebugWriteln;
Assign( LogFile, LogFileName );
Rewrite( LogFile );
Writeln( LogFile, '--- Logging start : '+TimeStamp+' ---' );

finalization
Writeln( LogFile, '--- Logging end   : '+TimeStamp+' ---' );
Close( LogFile );

end.

{ $Log
  -- 14.I.2006 Added AnsiString support
  -- Created 2.06.2003
}
