unit vlibrary;
{$include valkyrie.inc}
interface

uses
  {$IFDEF UNIX} unix, dl, {$ENDIF}
  sysutils, dynlibs;


type
  ELibraryError = class( Exception );

  {$WARNINGS OFF}
  TLibrary = class
  public
    class function Load( const aName: AnsiString; aErrorReport : boolean = true ) : TLibrary;
  public
    destructor Destroy; override;
    function Get( const aSymbol : AnsiString ) : Pointer;
  private
    constructor Create( const AName : AnsiString; aHandle: TLibHandle );
  private
    FHandle : TLibHandle;
    FName   : AnsiString;
    FRaise  : Boolean;
  public
    property Name : AnsiString read FName;
  end;
  {$WARNINGS ON}

implementation

constructor TLibrary.Create( const aName: AnsiString; aHandle: TLibHandle );
begin
  inherited Create;
  FName   := aName;
  FHandle := aHandle;
  FRaise  := False;
end;

class function TLibrary.Load( const aName : AnsiString; aErrorReport : boolean ) : TLibrary;
var Handle: TLibHandle;
begin
 Handle := {$IFDEF UNIX} TLibHandle( dlopen( PChar(aName), RTLD_LAZY or RTLD_GLOBAL) );
           {$ELSE} LoadLibrary( aName ); {$ENDIF}
 if Handle = NilHandle then
 begin
  if aErrorReport
    then raise ELibraryError.Create( 'Can''t load library "' +aName+ '"' {$IFDEF UNIX} + ': ' + dlerror {$endif} )
    else Exit( nil );
 end
 else
   Load := Self.Create( aName, Handle);
 Load.FRaise := aErrorReport;
end;

function TLibrary.Get( const aSymbol : AnsiString ) : Pointer;
begin
  Get := GetProcedureAddress( FHandle, PChar( aSymbol ) );
  if (Get = nil) and FRaise then ELibraryError.Create('Symbol "'+aSymbol+'" not found in library "'+FName+'"!');
end;

destructor TLibrary.Destroy;
begin
  UnloadLibrary( FHandle );
  inherited Destroy;
end;

end.

