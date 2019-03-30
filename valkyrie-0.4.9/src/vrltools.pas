{$INCLUDE valkyrie.inc}
// @abstract(Roguelike Toolkit for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(Oct 14, 2006)
// @cvs($Author: chaos-dev $)
// @cvs($Date: 2008-10-14 19:45:46 +0200 (Tue, 14 Oct 2008) $)
//
// Gathers some useful functions for roguelike development in Valkyrie.
// As for the current state it's experimental.
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

unit vrltools;
interface
uses SysUtils, vmath, vutil, vds, vnode, vsystem;

const DIR_NONE      = 0;
      DIR_DOWNLEFT  = 1;
      DIR_DOWN      = 2;
      DIR_DOWNRIGHT = 3;
      DIR_LEFT      = 4;
      DIR_CENTER    = 5;
      DIR_RIGHT     = 6;
      DIR_UPLEFT    = 7;
      DIR_UP        = 8;
      DIR_UPRIGHT   = 9;

type TByteRange = object
  Min : Byte;
  Max : Byte;
  procedure Create( const nMin, nMax : Byte );
  function Diff : Byte;
  function Contains( const value : Integer ) : Boolean;
  function Random : Byte;
end;

function NewByteRange( const min, max : Byte ) : TByteRange;


type TDiceRoll = object
  amount : Word;
  sides  : Word;
  bonus  : Integer;
  procedure Init( namount, nsides : Word; nbonus : Integer = 0);
  procedure Init(const diecode : string);
  function Roll : LongInt;
  function toString : string;
  procedure fromString(diecode : string);
  function max : LongInt;
  function min : LongInt;
end;

function NewDiceRoll(namount,nsides : Word; nbonus : Integer = 0) : TDiceRoll;
function NewDiceRoll(const diecode : string) : TDiceRoll;

type

{ TCoord2D }

TCoord2D = object
  x : Integer;
  y : Integer;
  procedure Create(const nX,nY : Integer);
  function ifIncX( amount : integer ) : TCoord2D;
  function ifIncY( amount : integer ) : TCoord2D;
  function ifInc( incX,incY : integer ) : TCoord2D; overload;
  function ifInc( Horizontal : Boolean; value : integer ) : TCoord2D; overload;
  procedure Inc( Horizontal : Boolean; value : integer = 1); overload;
  procedure Inc( incX,incY : integer ); overload;
  function RandomShifted( Value : Byte = 1 ) : TCoord2D;
  procedure RandomShift( Value : Byte = 1 );
  procedure Random( Min, Max : TCoord2D );
  function Sign : TCoord2D;
  function Length : Integer;
  function ToString : AnsiString;
  function Horiz( Horizontal : Boolean ) : Integer; overload;
  procedure Horiz( Horizontal : Boolean; Value : Integer ); overload;

end;

TCoord2DArray = array of TCoord2D;

{ TCoord2DSet }

TCoord2DSet   = class(TSparseSet)
  procedure Add( Coord : TCoord2D );
  procedure Remove( Coord : TCoord2D );
  function contains( Coord : TCoord2D ) : Boolean;
end;


TDirection = object
  code : Byte;
  procedure Create( const dircode : Byte );
  procedure Create( const x,y : ShortInt );
  procedure Create( const a,b : TCoord2D );
  procedure CreateSmooth( const a,b : TCoord2D );
  procedure Random;
  procedure RandomSquare;
  function isSquare : Boolean;
  function isProper : Boolean;
  function X : ShortInt; inline;
  function Y : ShortInt; inline;
  procedure Reverse; inline;
  function Reversed : TDirection; inline;
  function Picture : char;
end;


TCellMethod          = procedure( where : TCoord2D ) of object;
TCellTranslateMethod = function( where : TCoord2D ) : Byte of object;

{ TArea }

TArea = object
  A,B : TCoord2D;
  procedure Create( const TopLeft,BottomRight : TCoord2D );
  function Contains( const Coord : TCoord2D ) : Boolean; overload;
  function Contains( const Area : TArea ) : Boolean; overload;
  function Collides( const Area : TArea ) : Boolean;
  function Area : Word;
  function EnclosedArea : Word;
  function Width : Word;
  function Height : Word;
  function RandomCoord : TCoord2D;
  function Center : TCoord2D;
  function NextCoord( var Coord : TCoord2D; Horiz : Boolean = True ) : Boolean;

  function isEdge( Coord : TCoord2D ) : boolean;
  function RandomEdgeCoord : TCoord2D;
  function RandomInnerEdgeCoord : TCoord2D;
  function RandomInnerCoord : TCoord2D;
  function RandomSubArea( aMin, aMax : TCoord2D ) : TArea;
  function RandomSubArea( aDim : TCoord2D ) : TArea;
  function RandomSubArea( aWidth, aHeight : TByteRange ) : TArea;
  function RandomSubArea( aWidth, aHeight : Word ) : TArea;

  procedure Clamp( var Coord : TCoord2D );
  procedure Clamp( var aArea : TArea );
  function Clamped( const Coord : TCoord2D ) : TCoord2D;
  function Clamped( const aArea : TArea ) : TArea;

  function Shrinked( i : Integer = 1 ) : TArea;
  procedure Shrink( i : Integer = 1 );
  function Expanded( i : Integer = 1 ) : TArea;
  procedure Expand( i : Integer = 1 );
  function Shrinked( x,y  : Integer ) : TArea;
  procedure Shrink( x,y : Integer );
  function Expanded( x,y : Integer ) : TArea;
  procedure Expand( x,y : Integer );

  property TopLeft : TCoord2D read A;
  property BottomRight : TCoord2D read B;
  function TopRight : TCoord2D;
  function BottomLeft : TCoord2D;

  function Corners : TCoord2DArray;

  procedure ForAllCells( aWhat : TCellMethod ); overload;
  procedure ForAllCells(aWhatArea: TArea; aWhat: TCellMethod); overload;

  function ToString : AnsiString;
end;

{ TAreaEnumerator }

TAreaEnumerator = object
private
  FCurrent : TCoord2D;
  FA, FB   : TCoord2D;
public
  constructor Create( const Area : TArea );
  function MoveNext : Boolean;
  property Current : TCoord2D read FCurrent;
end;

operator enumerator( a : TArea ) : TAreaEnumerator;

const ZeroCoord2D : TCoord2D = (
  x : 0;
  y : 0;
);

const UnitCoord2D : TCoord2D = (
  x : 1;
  y : 1;
);

function NewDirection( const x, y : ShortInt ) : TDirection; inline;
function NewDirection( const c1,c2 : TCoord2D ) : TDirection; inline;
function NewDirectionSmooth( const c1,c2 : TCoord2D ) : TDirection; inline;
function NewCoord2D( const x, y : Integer ) : TCoord2D; inline;
function NewArea( const TopLeft,BottomRight : TCoord2D ) : TArea; inline; overload;
function NewArea( const Center : TCoord2D; Radius : Word ) : TArea; inline; overload;

operator = (a,b : TCoord2D) r : boolean; inline;
operator + (a,b : TCoord2D) r : TCoord2D; inline;
operator - (a,b : TCoord2D) r : TCoord2D; inline;
operator + (a : TCoord2D; d : TDirection) r : TCoord2D; inline;
operator * (a,b : TCoord2D) r : TCoord2D; inline;
operator * (a : TCoord2D; b : Integer) r : TCoord2D; inline;
operator + (a : TArea; b : TCoord2D) r : TArea; inline;
operator - (a : TArea; b : TCoord2D) r : TArea; inline;

function RandomRange( Min,Max : LongInt ) : LongInt;

// Calculates the distance between x1,y1 and x2,y2 using a fast approximation
// algorithm instead of the standard triangulation.
function Distance( c1, c2 : TCoord2D ): word; {$IFDEF VINLINE} inline; {$ENDIF} overload;

function RealDistance( c1, c2 : TCoord2D ): Single; {$IFDEF VINLINE} inline; {$ENDIF}

function DirectionChar( const cFrom, cTo : TCoord2D ) : char;

type

PAutoTargetEntry = ^TAutoTargetEntry;
TAutoTargetEntry = record
  Target   : TCoord2D;
  Distance : Integer;
  Next     : PAutoTargetEntry;
  Prev     : PAutoTargetEntry;
end;

  
// Class for handling autotargeting in roguelikes

{ TAutoTarget }

TAutoTarget = class(TVObject)
  // Creates a new autotarget instance
  constructor Create( newSource : TCoord2D );
  // Adds a new target
  procedure AddTarget( distance : Integer; target : TCoord2D );
  // Adds a new target, calculating distance using Distance(defaultx,defaulty,x,y).
  procedure AddTarget( target : TCoord2D );
  // Selects given target as priority -- will be first in queue. The
  // procedure searches if the given target exists -- if not, it adds it at the
  // beginning, if so, removes it from the queue and adds at the beginning.
  procedure PriorityTarget( target : TCoord2D );
  // Resets the system -- GetNext after that will provide the closest target
  procedure Reset;
  // Returns the pointer to the first target.
  function First : TCoord2D;
  // Returns the pointer to current target.
  function Current : TCoord2D;
  // Moves to the next target and returns it's pointer.
  function Next : TCoord2D;
  // Moves to the previous target and returns it's pointer.
  // Previous to first is the most far away.
  function Prev : TCoord2D;
  // Frees all memory and destroys the object
  destructor Destroy; override;
  private
  function FindEntry( target : TCoord2D ) : PAutoTargetEntry;
  procedure InsertEntry( distance : Integer; target : TCoord2D );
  procedure RemoveEntry( Entry : PAutoTargetEntry );
  private
  FirstEntry   : PAutoTargetEntry;
  CurrentEntry : PAutoTargetEntry;
  Source       : TCoord2D;
end;

type PCoord2D = ^TCoord2D;
     PArea    = ^TArea;

implementation

uses vdebug;

procedure TDirection.Create( const dircode : Byte );
begin
  code := dircode;
end;

procedure TDirection.Create( const x, y : ShortInt );
begin
  code := ((8+x)-((y+1)*3));
end;

procedure TDirection.Create( const a, b : TCoord2D );
begin
  Create(Sgn(b.x-a.x),Sgn(b.y-a.y));
end;

procedure TDirection.CreateSmooth( const a,b : TCoord2D );
var d : TCoord2D;
begin
  d := b - a;
  Create( a, b );
  if d.x*d.y <> 0 then
  begin
    d.x := Abs(d.x);
    d.y := Abs(d.y);
    if d.x/d.y >= 1.9 then code := 5+X;
    if d.y/d.x >= 1.9 then code := 5-Y*3;
  end;
end;

procedure TDirection.Random;
begin
  Code := System.Random(8)+1;
  if Code = DIR_CENTER then Inc(Code);
end;

procedure TDirection.RandomSquare;
begin
  case System.Random(4) of
    0 : Code := DIR_UP;
    1 : Code := DIR_DOWN;
    2 : Code := DIR_LEFT;
    3 : Code := DIR_RIGHT;
  end;
end;

function TDirection.isSquare: Boolean;
begin
  Exit( Code in [ DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT ] );
end;

function TDirection.isProper: Boolean;
begin
  Exit( Code in [ 1..4,6..9 ] );
end;


function TDirection.X : ShortInt;
begin
 if Code = 0 then Exit(0);
 case Code mod 3 of
   0 : Exit(+1);
   2 : Exit(0);
   1 : Exit(-1);
 end;
end;

function TDirection.Y : ShortInt;
begin
 if Code = 0 then Exit(0);
 case Code of
   1..3 : Exit(+1);
   4..6 : Exit(0);
   7..9 : Exit(-1);
 end;
end;

procedure TDirection.Reverse;
begin
  Create( -X, -Y );
end;

function TDirection.Reversed : TDirection;
begin
  Result.Create( -X, -Y );
end;

function TDirection.Picture : char;
begin
  case Code of
    DIR_CENTER                 : Exit('+');
    DIR_LEFT   ,DIR_RIGHT      : Exit('-');
    DIR_UP     ,DIR_DOWN       : Exit('|');
    DIR_UPRIGHT,DIR_DOWNLEFT   : Exit('/');
    DIR_UPLEFT ,DIR_DOWNRIGHT  : Exit('\');
    else  Exit('.');
  end;
end;

operator enumerator(a: TArea): TAreaEnumerator;
begin
 Result.Create( a );
end;

function NewDirection( const x, y : ShortInt ) : TDirection; inline;
begin
  NewDirection.Create( x, y );
end;

function NewDirection(const c1, c2: TCoord2D): TDirection; inline;
begin
  NewDirection.Create(c1,c2);
end;

function NewDirectionSmooth ( const c1, c2 : TCoord2D ) : TDirection;
begin
  NewDirectionSmooth.CreateSmooth(c1,c2);
end;

function NewCoord2D( const x, y : Integer ) : TCoord2D; inline;
begin
  NewCoord2D.Create( x, y );
end;

function NewArea(const TopLeft, BottomRight: TCoord2D): TArea; inline; overload;
begin
  NewArea.Create( TopLeft, BottomRight );
end;

function NewArea(const Center: TCoord2D; Radius: Word): TArea; inline; overload;
begin
  NewArea.A := Center.ifInc(-Radius,-Radius);
  NewArea.B := Center.ifInc( Radius, Radius);
end;



procedure TCoord2D.Create( const nX, nY : Integer );
begin
  x := nX;
  y := nY;
end;

function TCoord2D.ifIncX(amount: integer): TCoord2D;
begin
  ifIncX.x := x+amount;
  ifIncX.y := y;
end;

function TCoord2D.ifIncY(amount: integer): TCoord2D;
begin
  ifIncY.x := x;
  ifIncY.y := y+amount;
end;

function TCoord2D.ifInc( incX, incY: integer ): TCoord2D;
begin
  ifInc.x := x + incX;
  ifInc.y := y + incY;
end;

function TCoord2D.ifInc(Horizontal: Boolean; value: integer): TCoord2D;
begin
  if Horizontal then
  begin
    ifInc.x := x + value;
    ifInc.y := y;
  end
  else
  begin
    ifInc.x := x;
    ifInc.y := y + value;
  end;
end;

procedure TCoord2D.Inc(Horizontal: Boolean; value: integer);
begin
  if Horizontal
    then x += value
    else y += value;
end;

procedure TCoord2D.Inc(incX, incY: integer);
begin
  x += incX;
  y += incY;
end;

function TCoord2D.RandomShifted(Value: Byte): TCoord2D;
begin
  RandomShifted.x := x + System.Random( 2*Value + 1 ) - Value;
  RandomShifted.y := y + System.Random( 2*Value + 1 ) - Value;
end;

procedure TCoord2D.RandomShift(Value: Byte);
begin
  x += System.Random( 2*Value + 1 ) - Value;
  y += System.Random( 2*Value + 1 ) - Value;
end;

procedure TCoord2D.Random(Min, Max: TCoord2D);
var Diff : TCoord2D;
begin
  Diff := Max - Min;
  x := System.Random( Diff.x + 1 ) + Min.x;
  y := System.Random( Diff.y + 1 ) + Min.y;
end;

function TCoord2D.Sign: TCoord2D;
begin
  Sign.x := Sgn(x);
  Sign.y := Sgn(y);
end;

function TCoord2D.Length: Integer;
begin
  Length := Round(Sqrt(x*x+y*y));
end;

function TCoord2D.ToString : AnsiString;
begin
  Exit( IntToStr(x) + ',' + IntToStr(y) );
end;

function TCoord2D.Horiz(Horizontal: Boolean): Integer;
begin
  if Horizontal then Exit(X) else Exit(Y);
end;

procedure TCoord2D.Horiz(Horizontal: Boolean; Value: Integer);
begin
  if Horizontal then X := Value else Y := Value;
end;


operator = (a,b : TCoord2D) r : boolean; inline;
begin
  r := (a.x = b.x) and (a.y = b.y);
end;

operator + (a,b : TCoord2D) r : TCoord2D; inline;
begin
  r.x := a.x + b.x;
  r.y := a.y + b.y;
end;

operator - (a,b : TCoord2D) r : TCoord2D; inline;
begin
  r.x := a.x - b.x;
  r.y := a.y - b.y;
end;

operator + (a : TCoord2D; d : TDirection) r : TCoord2D; inline;
begin
  r.x := a.x + d.x;
  r.y := a.y + d.y;
end;

operator * (a,b : TCoord2D) r : TCoord2D; inline;
begin
  r.x := a.x * b.x;
  r.y := a.y * b.y;
end;

operator * (a : TCoord2D; b : Integer) r : TCoord2D; inline;
begin
  r.x := a.x * b;
  r.y := a.y * b;
end;

operator + ( a : TArea; b : TCoord2D ) r : TArea;
begin
  r.a := a.a+b;
  r.b := a.b+b;
end;

operator - ( a : TArea; b : TCoord2D ) r : TArea;
begin
 r.a := a.a-b;
 r.b := a.b-b;
end;

function NewByteRange(const min, max: Byte): TByteRange;
begin
  NewByteRange.Min := min;
  NewByteRange.Max := max;
end;

function RandomRange(Min, Max: LongInt): LongInt;
begin
  Exit( Min + Random(Max - Min + 1) );
end;

function Distance( c1, c2 : TCoord2D ): word; {$IFDEF VINLINE} inline; {$ENDIF}
begin
  Distance := Round(Min(Abs(c2.x-c1.x),Abs(c2.y-c1.y)) div 2) + Max(Abs(c2.x-c1.x),Abs(c2.y-c1.y));
end;

function RealDistance(c1, c2: TCoord2D): Single;
begin
  RealDistance := Sqrt(Sqr(Abs(c2.x-c1.x)) + Sqr(Abs(c2.y-c1.y)));
end;

function DirectionChar( const cFrom, cTo: TCoord2D ) : char;
var xsign : ShortInt;
    ysign : ShortInt;
    dsign : ShortInt;
    cDiff : TCoord2D;
begin
  cDiff := cTo - cFrom;
  xsign := Sgn( cDiff.x );
  ysign := Sgn( cDiff.y );

  if (xsign = 0) and (ysign = 0) then Exit('*');
  if (xsign = 0) then Exit('|');
  if (ysign = 0) then Exit('-');

  dsign := xsign*ysign;
  if (dsign > 0) then Exit('\');
  Exit('/');
end;

function NewDiceRoll(namount, nsides: Word; nbonus: Integer = 0): TDiceRoll;
begin
  NewDiceRoll.Init(namount,nsides,nbonus);
end;

function NewDiceRoll(const diecode: string): TDiceRoll;
begin
  NewDiceRoll.Init(diecode);
end;

{ TAutoTarget }

constructor TAutoTarget.Create( newSource : TCoord2D );
begin
  FirstEntry   := nil;
  CurrentEntry := nil;
  
  Source := newSource;
end;

procedure TAutoTarget.AddTarget( distance : Integer; target : TCoord2D );
begin
  InsertEntry( distance, target );
  Reset;
end;

procedure TAutoTarget.AddTarget( target : TCoord2D );
begin
  InsertEntry( Distance( Source, Target ), Target );
  Reset;
end;

procedure TAutoTarget.PriorityTarget( target : TCoord2D );
begin
  RemoveEntry( FindEntry( target ) );
  AddTarget( -1, target );
end;

procedure TAutoTarget.Reset;
begin
  CurrentEntry := FirstEntry;
end;

function TAutoTarget.First: TCoord2D;
begin
  if CurrentEntry = nil then Exit();
  Exit(FirstEntry^.Target);
end;

function TAutoTarget.Current: TCoord2D;
begin
  if CurrentEntry = nil then Exit( Source );
  Exit(CurrentEntry^.Target);
end;

function TAutoTarget.Next: TCoord2D;
begin
  if CurrentEntry = nil then Exit( Source );
  CurrentEntry := CurrentEntry^.Next;
  Exit( CurrentEntry^.Target );
end;

function TAutoTarget.Prev: TCoord2D;
begin
  if CurrentEntry = nil then Exit( Source );
  CurrentEntry := CurrentEntry^.Prev;
  Exit( CurrentEntry^.Target );
end;

destructor TAutoTarget.Destroy;
begin
  while FirstEntry <> nil do
    RemoveEntry( FirstEntry );
end;

function TAutoTarget.FindEntry( target : TCoord2D ): PAutoTargetEntry;
var Scan   : PAutoTargetEntry;
begin
  if CurrentEntry = nil then Exit(nil);

  if FirstEntry^.Target = Target then Exit( FirstEntry );

  Scan := FirstEntry^.Next;
  while (Scan <> FirstEntry) and (Scan^.Target <> Target) do Scan := Scan^.Next;

  if Scan^.Target = Target then Exit(Scan);
  
  Exit(nil);
end;

procedure TAutoTarget.InsertEntry( distance : Integer; target : TCoord2D );
var Scan     : PAutoTargetEntry;
    NewEntry : PAutoTargetEntry;
begin
  if FirstEntry = nil then
  begin
    New(FirstEntry);
    FirstEntry^.Target   := Target;
    FirstEntry^.Distance := Distance;
    FirstEntry^.Next     := FirstEntry;
    FirstEntry^.Prev     := FirstEntry;
    Reset;
    exit;
  end;

  Scan := FirstEntry;
  while (Distance > Scan^.Distance) and (Scan^.Next <> FirstEntry) do Scan := Scan^.Next;

  New(NewEntry);
  NewEntry^.Target   := Target;
  NewEntry^.Distance := Distance;
  NewEntry^.Next     := Scan;
  NewEntry^.Prev     := Scan^.Prev;
  NewEntry^.Next^.Prev := NewEntry;
  NewEntry^.Prev^.Next := NewEntry;
  
  if NewEntry^.Distance <= FirstEntry^.Distance then FirstEntry := NewEntry;

  Reset;
end;

procedure TAutoTarget.RemoveEntry( Entry: PAutoTargetEntry );
begin
  if Entry = nil then Exit;

  if Entry^.Next <> Entry then
  begin
    if Entry = FirstEntry then FirstEntry := Entry^.Next;

    Entry^.Next^.Prev := Entry^.Prev;
    Entry^.Prev^.Next := Entry^.Next;
  end
  else FirstEntry := nil;
  Dispose(Entry);
  Reset;
end;

{ TDiceRoll }

procedure TDiceRoll.Init(namount, nsides: Word; nbonus: Integer = 0);
begin
  amount := namount;
  sides  := nsides;
  bonus  := nbonus;
end;

procedure TDiceRoll.Init(const diecode: string);
begin
  Init(0,0,0);
  fromString(diecode);
end;

function TDiceRoll.Roll: LongInt;
begin
  Exit(LongInt(Dice(amount,sides))+bonus);
end;

function TDiceRoll.toString: string;
begin
  toString := IntToStr(amount)+'d'+IntToStr(sides);
  if bonus > 0 then Exit(toString+'+'+IntToStr(bonus));
  if bonus < 0 then Exit(toString+IntToStr(bonus));
end;

procedure TDiceRoll.fromString(diecode : string);
var PartA,PartB : Ansistring;
begin
  if diecode = '' then
  begin
    Init(0,0);
    exit;
  end;
  if Pos('d',diecode) = 0 then
  begin
    Init(0,0,StrToInt(diecode));
    exit;
  end;
  split(diecode,parta,partb,'d');
  amount := StrToInt(parta);
  diecode := partb;
  if Pos('+',diecode) <> 0 then
  begin
    split(diecode,parta,partb,'+');
    sides := StrToInt(parta);
    bonus := StrToInt(partb);
  end
  else if Pos('-',diecode) <> 0 then
  begin
    split(diecode,parta,partb,'-');
    sides := StrToInt(parta);
    bonus := -StrToInt(partb);
  end
  else
  begin
    sides := StrToInt(diecode);
    bonus := 0;
  end;
end;

function TDiceRoll.Max : LongInt;
begin
  Exit( LongInt( amount * sides ) + bonus );
end;

function TDiceRoll.Min : LongInt;
begin
  Exit( amount + bonus );
end;

{ TArea }

procedure TArea.Create(const TopLeft, BottomRight: TCoord2D);
begin
  A := TopLeft;
  B := BottomRight;
end;

function TArea.Contains(const Coord: TCoord2D): Boolean;
begin
  Exit( ( Coord.x >= A.x ) and ( Coord.y >= A.y ) and
        ( Coord.x <= B.x ) and ( Coord.y <= B.y ) );
end;

function TArea.Contains(const Area: TArea): Boolean;
begin
  Exit( ( Area.A.x >= A.x ) and ( Area.A.y >= A.y ) and
        ( Area.B.x <= B.x ) and ( Area.B.y <= B.y ) );

end;

function TArea.Collides(const Area: TArea): Boolean;
var Coord : TCoord2D;
begin
  Coord.x := Max(Area.A.X, A.X);
  Coord.y := Max(Area.A.Y, A.Y);
  Exit( Contains(Coord) and Area.Contains(Coord) );
end;

function TArea.Area: Word;
begin
  Exit( Width * Height );
end;

function TArea.EnclosedArea: Word;
begin
  Exit( (Width + 1) * (Height + 1) );
end;

function TArea.Width: Word;
begin
  Exit( Max( B.x - A.x, 0 ) );
end;

function TArea.Height: Word;
begin
  Exit( Max( B.y - A.y, 0 ) );
end;

function TArea.RandomCoord: TCoord2D;
begin
  RandomCoord.Random( A, B );
end;

function TArea.Center: TCoord2D;
begin
  Center.x := A.x + ( ( B.x - A.x ) div 2 );
  Center.y := A.y + ( ( B.y - A.y ) div 2 );
end;

function TArea.NextCoord(var Coord: TCoord2D; Horiz: Boolean): Boolean;
begin
  NextCoord := True;
  if not Contains(Coord) then
    Coord := A
  else
  begin
    if Coord = B then Exit(False);
    Coord.Inc(Horiz);
    if Coord.x > B.x then Coord.Create(A.x,Coord.y + 1);
    if Coord.y > B.y then Coord.Create(Coord.x + 1,A.y);
  end;
end;

function TArea.isEdge(Coord: TCoord2D): boolean;
begin
  if ( ( Coord.x = A.x ) or ( Coord.x = B.x ) ) and ( Coord.y >= A.y ) and ( Coord.y <= B.y ) then Exit(True);
  if ( ( Coord.y = A.y ) or ( Coord.y = B.y ) ) and ( Coord.x >= A.x ) and ( Coord.x <= B.x ) then Exit(True);
  Exit( False );
end;

function TArea.RandomEdgeCoord : TCoord2D;
var Roll  : Word;
    Xs,Ys : Word;
begin
  Xs := (B.x-A.x+1);
  Ys := (B.y-A.y-1);
  Roll := Random(2*Xs+2*Ys);
  if ( Roll < 2*Xs ) then
  begin
    if ( Roll < Xs ) then
      RandomEdgeCoord.Create(Roll+A.x,A.y)
    else
      RandomEdgeCoord.Create(Roll-Xs+A.x,B.y);
  end
  else
  begin
    Roll -= 2*Xs;
    if ( Roll < Ys ) then
      RandomEdgeCoord.Create(A.x,A.y+Roll+1)
    else
      RandomEdgeCoord.Create(B.x,A.y+Roll-Ys+1);
  end
end;

function TArea.RandomInnerEdgeCoord : TCoord2D;
var Roll  : Word;
    Xs,Ys : Word;
begin
  Xs := (B.x-A.x-1);
  Ys := (B.y-A.y-1);
  Roll := Random(2*Xs+2*Ys);
  if ( Roll < 2*Xs ) then
  begin
    if ( Roll < Xs ) then
      RandomInnerEdgeCoord.Create(Roll+A.x+1,A.y)
    else
      RandomInnerEdgeCoord.Create(Roll-Xs+A.x+1,B.y);
  end
  else
  begin
    Roll -= 2*Xs;
    if ( Roll < Ys ) then
      RandomInnerEdgeCoord.Create(A.x,A.y+Roll+1)
    else
      RandomInnerEdgeCoord.Create(B.x,A.y+Roll-Ys+1);
  end
end;

function TArea.RandomInnerCoord: TCoord2D;
begin
  RandomInnerCoord.Random( A.ifInc(+1,+1), B.ifInc(-1,-1) );
end;

function TArea.RandomSubArea(aMin, aMax: TCoord2D): TArea;
var iDim : TCoord2D;
begin
  iDim.Random( aMin, aMax );
  RandomSubArea := RandomSubArea( iDim );
end;

function TArea.RandomSubArea(aDim: TCoord2D): TArea;
var iCoord : TCoord2D;
begin
  iCoord.Random( A, B - aDim );
  RandomSubArea.Create( iCoord, iCoord + aDim.ifInc(-1,-1) );
end;

{$OPTIMIZATION OFF}
function TArea.RandomSubArea( aWidth, aHeight: TByteRange ): TArea;
var iWidth, iHeight : Byte;
begin
  iWidth  := aWidth.Random;
  iHeight := aHeight.Random;
  RandomSubArea := RandomSubArea( iWidth, iHeight );
end;
{$OPTIMIZATION ON}

function TArea.RandomSubArea(aWidth, aHeight: Word): TArea;
var iWH    : TCoord2D;
begin
  iWH.Create( aWidth, aHeight );
  RandomSubArea := RandomSubArea( iWH );
end;


procedure TArea.Clamp(var Coord: TCoord2D);
begin
  Coord.x := vmath.Clamp( Coord.x, A.x, B.x );
  Coord.y := vmath.Clamp( Coord.y, A.y, B.y );
end;

procedure TArea.Clamp(var aArea: TArea);
begin
  Clamp( aArea.A );
  Clamp( aArea.B );
end;

function TArea.Clamped( const Coord: TCoord2D): TCoord2D;
begin
  Clamped.x := vmath.Clamp( Coord.x, A.x, B.x );
  Clamped.y := vmath.Clamp( Coord.y, A.y, B.y );
end;

function TArea.Clamped( const aArea: TArea): TArea;
begin
  Clamped.A := Clamped( aArea.A );
  Clamped.B := Clamped( aArea.B );
end;

function TArea.Shrinked(i: Integer): TArea;
begin
  Shrinked.A.x := A.x + i;
  Shrinked.A.y := A.y + i;
  Shrinked.B.x := B.x - i;
  Shrinked.B.y := B.y - i;
end;

procedure TArea.Shrink(i: Integer);
begin
  A.x += i;
  A.y += i;
  B.x -= i;
  B.y -= i;
end;

function TArea.Expanded(i: Integer): TArea;
begin
  Expanded.A.x := A.x - i;
  Expanded.A.y := A.y - i;
  Expanded.B.x := B.x + i;
  Expanded.B.y := B.y + i;
end;

procedure TArea.Expand(i: Integer);
begin
  A.x -= i;
  A.y -= i;
  B.x += i;
  B.y += i;
end;

function TArea.Shrinked ( x, y : Integer ) : TArea;
begin
  Shrinked.A.x := A.x + x;
  Shrinked.A.y := A.y + y;
  Shrinked.B.x := B.x - x;
  Shrinked.B.y := B.y - y;
end;

procedure TArea.Shrink ( x, y : Integer ) ;
begin
  A.x += x;
  A.y += y;
  B.x -= x;
  B.y -= y;
end;

function TArea.Expanded ( x, y : Integer ) : TArea;
begin
  Expanded.A.x := A.x - x;
  Expanded.A.y := A.y - y;
  Expanded.B.x := B.x + x;
  Expanded.B.y := B.y + y;
end;

procedure TArea.Expand ( x, y : Integer ) ;
begin
  A.x += x;
  A.y += y;
  B.x -= x;
  B.y -= y;
end;

function TArea.TopRight: TCoord2D;
begin
  TopRight.x := B.x;
  TopRight.y := A.y;
end;

function TArea.BottomLeft: TCoord2D;
begin
  BottomLeft.x := A.x;
  BottomLeft.y := B.y;
end;

function TArea.Corners: TCoord2DArray;
begin
  SetLength( Corners, 4 );
  Corners[0] := A;
  Corners[1] := TopRight;
  Corners[2] := B;
  Corners[3] := BottomLeft;
end;

procedure TArea.ForAllCells(aWhat: TCellMethod);
var c : TCoord2D;
begin
  for c in Self do aWhat( c );
end;

procedure TArea.ForAllCells(aWhatArea: TArea; aWhat: TCellMethod);
var c : TCoord2D;
begin
  for c in aWhatArea do aWhat( c );
end;

function TArea.ToString: AnsiString;
begin
  Exit( '(' + A.ToString + ',' + B.ToString + ')' );
end;


{ TByteRange }

procedure TByteRange.Create(const nMin, nMax: Byte);
begin
  Min := nMin;
  Max := nMax;
end;

function TByteRange.Diff: Byte;
begin
  Exit( Max - Min );
end;

function TByteRange.Contains(const value: Integer): Boolean;
begin
  Exit( ( value >= min ) and ( value <= max ) );
end;

function TByteRange.Random: Byte;
begin
  Exit( System.Random( max - min + 1 ) + min );
end;

{ TAreaEnumerator }

constructor TAreaEnumerator.Create(const Area: TArea);
begin
 FA := Area.A;
 FB := Area.B;
 FCurrent := Area.A;
 FCurrent.x -= 1;
end;

function TAreaEnumerator.MoveNext: Boolean;
begin
  FCurrent.x += 1;
  if FCurrent.x > FB.x then
  begin
    FCurrent.y += 1;
    FCurrent.x := FA.x;
  end;
  Exit( FCurrent.y <= FB.y );
end;

{ TCoord2DSet }

procedure TCoord2DSet.Add(Coord: TCoord2D);
begin
  inherited Add( Coord.X, Coord.Y );
end;

procedure TCoord2DSet.Remove(Coord: TCoord2D);
begin
  inherited Remove( Coord.X, Coord.Y );
end;

function TCoord2DSet.contains(Coord: TCoord2D): Boolean;
begin
  Exit( inherited contains( Coord.X, Coord.Y ) );
end;

end.


// Modified      : $Date: 2008-10-14 19:45:46 +0200 (Tue, 14 Oct 2008) $
// Last revision : $Revision: 227 $
// Last author   : $Author: chaos-dev $
// Last commit   : $Log$
// Head URL      : $HeadURL: https://libvalkyrie.svn.sourceforge.net/svnroot/libvalkyrie/fp/src/vrltools.pas $

