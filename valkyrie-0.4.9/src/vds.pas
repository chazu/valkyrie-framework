{$INCLUDE valkyrie.inc}
// @abstract(Generic data structures for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @cvs($Author: chaos-dev $)
// @cvs($Date: 2008-01-14 22:16:41 +0100 (Mon, 14 Jan 2008) $)
//
// Introduces generic data structures using Free Pascal generics.
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
//  @html </div>unit vds;

unit vds;
interface

uses
  vnode, vutil, Classes, SysUtils;

type EParameterException = class(EException);
     EEmptyException     = class(EException);
     EOverwriteException = class(EException);
     EBadIndexException  = class(EException);
     EStoreException     = class(EException);

const VNOT_FOUND : DWord = $FFFFFFFF;


// General Array implementation. The array is self resizing as
// needed. Also it is guaranteed to hold nil values when created. Added elements
// disposing is left to the user. Memory consumption is equal to the highest
// index. Indexing starts at 0.
type generic TArray<_T> = class(TVObject)
       // Standard constructor, reserves InitialSize slots for the array.
       // Increment size is the minimal size of expansion. If no IncrementSize is
       // specified then the array size is doubled each time it runs out of space.
       // @raises(EParameterException)
       constructor Create( InitialSize : DWord = 16; IncrementSize : DWord = 0 );
       // Pushes the element to the top of the stack. Returns index of added element;
       function Push( const Element : _T ) : DWord; inline;
       // Pops the element from the top of the stack, throws exception if empty.
       // @raises(EEmptyException)
       function Pop : _T; inline;
       // Returns the top element of the stack, throws exception if empty.
       // @raises(EEmptyException)
       function Peek : _T; inline;
       // Returns wether the stack is empty.
       function IsEmpty : boolean; inline;
       // Returns current maximum size of array.
       function MaxSize : DWord; inline;
       // Clears the stack (sets elements and pointer to zero)
       procedure Clear; virtual;
{       // Writes data to the given Output Stream. Needs to be overriden to work.
       procedure Write(OSt : TStream); virtual;
       // Reads data from the given Input Stream. Needs to be overriden to work.
       procedure Read(ISt : TStream); virtual;}
       protected
       // Returns pointer number Index. Pointer is nil if it's out of range or empty
       function getElement( Index : DWord ) : _T; inline;
       // Writes Pointer to Array. If a pointer exists at given point it is
       // overwritten.
       procedure setElement( Index : DWord; const Element : _T ); inline;
       // Expands the size of the stack to NewStackSize.
       procedure Expand( NewSize : DWord );
       // Calculates the expansion that will include TargetSize and calls
       // Expand.
       procedure ExpandTo( TargetSize : DWord );

       protected

       FData     : array of _T;
       FSize     : DWord;
       FIncrement: DWord;
       FCurrent  : DWord;
       FMax      : DWord;
       FEmpty    : boolean;
       public
       // Default property access
       property Elements[ Index : DWord ] : _T read GetElement write SetElement; default;
       // Returns the count of elements. If the array was used as a stack then it's
       // the true count of elements-1 (because the array is 0 based!), else it's the
       // highest set index
       property Count : DWord read FMax;
     end;

// Unmanaged object specialization for the use of TManagedArray
type TUnmanagedObjectArray = specialize TArray<TObject>;

// A TArray that stores objects -- contrary to TArray we don't have to set a
// default value, and objects are FREED at destruction, as long as they have
// overriden TObject.Destroy.
// This class will become a lot smaller and efficient with the introduction of
// generic inheritance (as seen in http://bugs.freepascal.org/view.php?id=9007 )
generic TManagedArray<_TMANAGED> = class(TUnmanagedObjectArray)
       // Standard constructor, reserves InitialSize slots for the array.
       // Increment size is the minimal size of expansion. If no IncrementSize is
       // specified then the array size is doubled each time it runs out of space.
       constructor Create(InitialSize : DWord = 16; IncrementSize : DWord = 0);
       // Frees all objects -- also those stored!
       destructor Destroy; override;
       // Pops the element from the top of the stack, throws exception if empty.
       function Pop : _TMANAGED; reintroduce; inline;
       // Returns the top element of the stack, throws exception if empty.
       function Peek : _TMANAGED; reintroduce; inline;
       protected
       // Returns pointer number Index. Pointer is nil if it's out of range or empty
       function getElement(Index : DWord) : _TMANAGED; reintroduce; inline;
       // Writes Pointer to Array. If a pointer exists at given point it is
       // overwritten.
       procedure setElement(Index : DWord; const Element : _TMANAGED); inline;
       public
       // Default property access
       property Elements[Index : DWord] : _TMANAGED read GetElement write SetElement; default;
end;

// Generic Associative Array.
type

{ TAssocArray }

generic TAssocArray<_T> = class(TVObject)
       // Helper structure used by TAbstractAssocArray
       public type
       PAssocArrayEntry = ^TAssocArrayEntry;
       TAssocArrayEntry = record
         Next  : PAssocArrayEntry;
         Key   : AnsiString;
         Value : _T;
       end;
       var public
       // Prepare the structure
       constructor Create( ACanRewrite : Boolean = False );
       // Remove it from memory
       destructor Destroy; override;
       // Returnes wether an entry with this key exists.
       function Exists(Str : Ansistring) : Boolean; virtual;
       // Returns the amount of stored entries
       function getCount : DWord;
       // Writes data to the given Output Stream. WriteValue needs to be overriden for it to work.
       procedure WriteToStream( OSt : TStream );
       // Reads data from the given Input Stream. ReadValue needs to be overriden for it to work.
       procedure ReadFromStream( ISt : TStream );
       // Writes value to the given Output Stream. For non-basic types needs to be overriden to work.
       procedure WriteValue(OSt : TStream; Value : _T ); virtual;
       // Reads value from the given Input Stream. For non-basic types needs to be overriden to work.
       function ReadValue(ISt : TStream) : _T; virtual;
       // Gets with a default value
       function Get( Key : Ansistring; defaultValue : _T ) : _T;
       // Gets without a default value (FZero) returned
       function Get( Key : Ansistring ) : _T;
       // Removes entry with given key
       procedure Remove(Str : Ansistring);
       protected
       FZero          : _T;
       FItems         : DWord;
       FLastHash      : Word;
       FEntries       : array[0..95] of PAssocArrayEntry;
       FLastEntry     : PAssocArrayEntry;
       FLastEntryName : Ansistring;
       FCanRewrite    : Boolean;
       procedure DisposeOf( Value : _T ); virtual;
       procedure Rewrite(const Entry : PAssocArrayEntry; Value : _T);
       function  Hash(Str : Ansistring) : Byte;
       procedure RemoveEntryRow(Entry : Word);
       procedure RemoveEntry(const Entry : PAssocArrayEntry); virtual;
       procedure addEntry(Str : Ansistring; Value : _T);
       function  getEntry(Str : Ansistring) : _T;
       public
       // Default property access
       // @raises(EOverwriteException)
       property Elements[Index : AnsiString] : _T read getEntry write addEntry; default;
       property CanRewrite : Boolean read FCanRewrite write FCanRewrite;
     end;

type TSparseSetBucket = record
       X, Y : Integer;
       Next : Integer;
     end;

type TSparseSet = class(TVObject)
       constructor Create;
       procedure Add(X, Y: LongInt);
       procedure Remove(X, Y : LongInt);
       function contains(X, Y : LongInt) : Boolean;
       procedure Clear;
     private
       function hash(X, Y : Cardinal) : Integer;
       procedure MakeTable(Order : Integer);
       procedure Grow;
     private
       Index : Array of Integer;
       BucketPool : Array of TSparseSetBucket;

       FreeBucket : Integer;
       BucketShift : Integer;
       BucketMask : Integer;
     end;

type

{ THeapQueue }

generic THeapQueue<_T> = class(TVObject)
       public type
         TCompareFunc = function(const Item1, Item2: _T): Integer;
         TDebugFunc   = function(const Item : _T): AnsiString;
         TClearFunc   = procedure(Item : _T);
       var public
       // Prepare the structure
       constructor Create(InitialSize : DWord = 16);
       // Standard destructor, frees allocated memory. Does not free the pointed
       // objects.
       destructor Destroy; override;
       // Pop the top of the heap. Exception on empty.
       // @raises(EEmptyException)
       function Pop : _T;
       // Peek at the top of the heap. Exception on empty.
       // @raises(EEmptyException)
       function Peek : _T; inline;
       // Returns true if Heap is empty, false otherwise.
       function IsEmpty : Boolean; inline;
       // Adds a elementy to the HeapQueue
       procedure Add(const Element : _T);
       // Sets comparision function
       procedure SetCompareFunc(CompareFunc : TCompareFunc);
       // Clears the Queue
       procedure Clear; overload;
       // Clears the Queue with a destructor
       procedure Clear( Func : TClearFunc ); overload;
       // Removes element by index, and resorts the heap. O(n)!
       procedure RemoveIndex( Index : DWord );
       //procedure LogPic;
       protected
       function Greater(Index1,Index2 : DWord) : Boolean;
       function Smaller(Index1,Index2 : DWord) : Boolean;
       procedure HeapDown( Index : DWord ); inline;
       procedure HeapUp( Index : DWord ); inline;
       procedure Swap(Index1,Index2 : DWord);
       // Returns pointer number Index. Pointer is nil if it's out of range or empty
       function getElement( Index : DWord ) : _T; inline;
       protected
       FCompare   : TCompareFunc;
       //FDebug     : TDebugFunc;
       FData      : array of _T;
       FSize      : DWord;
       FEntries   : DWord;
       public
       property OnCompare : TCompareFunc write SetCompareFunc;
       //property OnDebug   : TDebugFunc write FDebug;
       property Elements[ Index : DWord ]  : _T read getElement; default;
       property Size : DWord read FEntries;
     end;

// A Weighted List intended for random value with weights retrieval
type

{ TWeightedList }

generic TWeightedList<_TValue> = class(TVObject)
     // Creates a new TWeighted list
     constructor Create(InitialSize : DWord = 16);
     // Adds a new value with the given weight. Remember that 0 weight is
     // non-existent!
     procedure Add(Value : _TValue; Weight : DWord);
     // Returns a random value based on the stored weights.
     // @raises(EEmptyException)
     function Return : _TValue;
     // Resets the list
     procedure Clear;
     // Frees all allocated memory
     destructor Destroy; override;
     protected
     FEntries : DWord;
     FSize    : DWord;
     FSum     : DWord;
     FWeights : array of DWord;
     FValues  : array of _TValue;
     public
     property Elements : DWord read FEntries;
   end;

// A list for the purpose of choosing only a single element
type generic TPriorityChoiceList<_TValue> = class(TVObject)
     // Creates a new list
     constructor Create(InitialSize : DWord = 16);
     // Adds a new value. If the value has lower priority then the best one yet
     // then all the ones added before are discarded.
     procedure Add(Value : _TValue; Priority : DWord);
     // Returns a random value from the ones with the lowest priority
     function Return : _TValue;
     // Resets the list
     procedure Clear;
     // Returns true if number of elements = 0, false otherwise
     function Empty : boolean; inline;
     // Frees all allocated memory
     destructor Destroy; override;
     protected
     FEntries : DWord;
     FSize    : DWord;
     FLowest  : DWord;
     FValues  : array of _TValue;
     public
     property Elements : DWord read FEntries;
   end;
   
// Predefined data structures
type TArraySpecializeAnsiString      = specialize TArray<AnsiString>;
     TAssocArraySpecializeAnsiString = specialize TAssocArray<AnsiString>;
     
     TByteArray = specialize TArray<Byte>;
     
type IStringList = interface
     function SLGet(Index : DWord) : AnsiString;
     function SLSize : DWord;
   end;

// A string array
type TStringArray = class(TArraySpecializeAnsiString)
     // Standard constructor, reserves InitialSize  for the array.
     // Increment size is the minimal size of expansion. If no IncrementSize is
     // specified then the array size is doubled each time it runs out of space.
     constructor Create(InitialSize : DWord = 16; IncrementSize : DWord = 0);
     // Reads the string array from a text file
     procedure Read(TextFile : AnsiString);
     // Writes the string array to a text file
     procedure Write(TextFile : AnsiString);
     // Reads the string array from a string stream. String streams start with
     // a DWord -- the number of strings and then constitute of the given number
     // of Ansistrings
     procedure ReadFromStream(Stream : TStream);
     // Writes the string array to a stream. See @link(Read) for the format.
     procedure WriteToStream(Stream : TStream);
     // For IStringList
     function Get(Index : DWord) : AnsiString;
     // For IStringList
     function Size : DWord;
   end;

// A string array
type TStringAssocArray = class(TAssocArraySpecializeAnsiString)
     // Standard constructor
     constructor Create;
   end;

// A string buffer
type TMessageBuffer = class(TArraySpecializeAnsiString)
     // Standard constructor
     constructor Create(newSize : DWord; maxWidth : Word);
     // Get's a added message. The messages are indexed from the last added to
     // the last one in the buffer. That is -- Get(0) returns the last added
     // message, Get(1) returns the previous and so on...
     function Get(Index : Word) : Ansistring;
     // Returns the amount of messages added, or max size of the buffer, whichever is less.
     function Size : DWord;
     // Adds a string to the Buffer. Returnes the number of bufferlines used.
     function Add(str : AnsiString) : Word;
     // Clears all messages
     procedure Clear; override;
     // Kills last message and retrackts back.
     procedure KillLast;
     protected
     FFilled     : Boolean;
     FWidth      : Word;
     FPosition   : DWord;
     FBufferSize : DWord;
   end;

// Generic key-value map class.
type

{ TMap }

generic TMap<_KEY,_VALUE> = class(TVObject)
    private
       // Stored size
       FSize : DWord;
    public type
       // Visitor function
       TVisitor = procedure( k : _KEY; var v : _VALUE ) of object;
    var public
       // Standard constructor
       constructor Create;
       // Returns element from map.
       // @raises EBadIndex if trying to read a non-existing index
       function GetElement( const Index : _KEY ) : _VALUE; inline;
       // Writes element to map.
       procedure SetElement( const Index : _KEY; const Element : _VALUE ); inline;
       // Checks whether element exists
       function Exists( const Index : _KEY ) : Boolean;
       // Remove element with given key
       procedure Remove( const Index : _KEY );
       // Execute procedure on all elements
       procedure ForAll( Visitor : TVisitor );
       // Clear map
       procedure Clear;
       // Free memory
       destructor Destroy; override;

    public
       // Default property for map accessing
       // @raises EBadIndex if trying to read a non-existing index
       property Elements[ const Index : _KEY ] : _VALUE read GetElement write SetElement; default;
       // Size
       property Size : DWord read FSize;
    private
    type
         // Forward declaration
         PTreeNode = ^TTreeNode;
         // Tree node
         TTreeNode = record
           // Left and right sub-tree
           Left, Right : PTreeNode;
           // Stored Key
           Key         : _KEY;
           // Stored Value
           Value       : _VALUE;
           // Data for AVL balancing
           Balance     : ShortInt;
         end;
    var
    private

       // Search the binary tree for the given key
       function FindNode( const Key : _KEY; Node : PTreeNode ) : PTreeNode;
       // Rotate once left
       function RotateLeft( var Node : PTreeNode ) : Boolean;
       // Rotate once right
       function RotateRight( var Node : PTreeNode ) : Boolean;
       // Rotate twice left
       function RotateTwiceLeft( var Node : PTreeNode ) : Boolean;
       // Rotate twice right
       function RotateTwiceRight( var Node : PTreeNode ) : Boolean;
       // ReBalance
       function ReBalance( var Node : PTreeNode ) : Boolean;
       // Insert element into tree, returns rebalancing value
       function Insert( const Key : _KEY; const Value : _VALUE; var Node : PTreeNode; var Found : Boolean ) : Boolean;
       // Delete tree node
       procedure Delete( var Node : PTreeNode );
       // Remove element with given key
       function Remove( const Key : _KEY; var Node : PTreeNode; var Found : Boolean ) : Boolean;
       // ForAll implementation
       procedure ForAll( Visitor : TVisitor; Node : PTreeNode );

      private
       // Stored tree root
       Root : PTreeNode;
     end;

// Generic vector implementation based on dynamic arrays. The vector is self
// resizing as needed if expanded by push. Memory consumption is equal to
// capacity * sizeof(element) + 8 bytes. Indexing starts at 0.
type

{ TVector }

generic TVector<_TYPE> = class(TObject)
       // Standard constructor, reserves InitialCapacity slots for the array.
       // The vector capacity is doubled each time it runs out of space. Initial
       // size is 0, use Resize or Push to increase size.
       constructor Create( InitialCapacity : DWord = 16 );

    type
       // Visitor function
       TVectorVisitor = procedure( e : _TYPE ) {of object};

       // Filter function
       TVectorFilter  = function( e : _TYPE ) : boolean {of object};
    var

       // Pushes the element to the back of the vector. Returns index of added
       // element.
       function Push( const Element : _TYPE ) : DWord; inline;

       // Pushes the element to the front of the vector.
       procedure PushFront( const Element : _TYPE ); inline;

       // Pops element from the front of the vector.
       function PopFront() : _TYPE; inline;

       // Pops element from the back of the vector.
       function Pop() : _TYPE; inline;

       // Pops element from the back of the vector.
       function Last() : _TYPE; inline;

       // Sets the vector size to zero. Does not deallocate memory.
       procedure Clear;

       // Free memory
       destructor Destroy; override;

       // Expands the capacity of the vector to NewCapacity.
       procedure Reserve( NewCapacity : DWord );

       // Expands the size of the vector to NewSize, and zeros the elements.
       procedure Resize( NewSize : DWord );

       // Erases ONE element and shifts back further elements
       // Nothing happens if element is not found
       procedure EraseAndShift( Index : DWord );

       // Runs passed visitor for all elements
       procedure ForAll( Visitor : TVectorVisitor );

       // Runs passed visitor for all elements, if returns false, then removes it and shifts the array
       procedure ForAllFilter( Visitor : TVectorFilter );

       // Searches the vector. Warning - O(n)! Returns index, or VNOT_FOUND if not found.
       function FindIndex( const Element : _TYPE ) : DWord;

    public type
       // Definition of sort function for sort. Should return true if a >= b.
       TSortFunction = function( const a : _TYPE; const b : _TYPE ) : Boolean of object;
    var public

       // Sorts the vector based on the given sort function.
       // Note: While the implementation is efficient (QuickSort at O(N*log N)),
       //   the algorithm does swaps and copies in the array, so it works well
       //   only if _TYPE isn't too big ( less or equal to 64 bytes probably ).
       // Warning: Sort sorts in  0..SIZE-1 range!
       procedure Sort( sorter : TSortFunction );

     protected
       // Returns element in vector of passed index.
       // @raises EBadIndex if index is not in 0..capacity-1 range
       function GetElement( Index : DWord ) : _TYPE; inline;

       // Writes element to vector.
       // @raises EBadIndex if index is not in 0..capacity-1 range
       procedure SetElement( Index : DWord; const Element : _TYPE ); inline;

     protected
       // class members (fields) cannot be declare after methods in compiler version 2.3.1 or higher.


       // Data storage
       FData     : array of _TYPE;

       // Capacity -- amount of allocated memory
       FCapacity : DWord;

       // Size -- amount of elements pushed, or the effect of resize
       FSize     : DWord;

     private
       // Recursive quicksort function
       // Note : not local to Sort because generics can't have nested procedures
       procedure QuickSort( ibegin, iend : DWord; Sorter : TSortFunction );

       // Swaps values under index ia and ib
       // Note : not local to Sort because generics can't have nested procedures
       procedure IndexSwap( ia, ib : DWord ); inline;

       // Performs a split for quicksort
       // Note : not local to Sort because generics can't have nested procedures
       function QSplit( ibegin, iend : DWord; Sorter : TSortFunction ) : DWord;

     public
       // Default property indexing access.
       // @raises EBadIndex if index is not in 0..capacity-1 range
       property Elements[ Index : DWord ] : _TYPE read GetElement write SetElement; default;

       // Returns the size of the vector.
       property Size : DWord     read FSize     write Resize;

       // Returns the allocated capacity of the vector
       property Capacity : DWord read FCapacity;

       // Returns wether the vector is empty -- i.e. wether it's size is zero
       function Empty : Boolean;
     end;


type TVariantAssocArray = specialize TAssocArray< Variant >;

type

{ TProperties }

TProperties = class( TVariantAssocArray )
  // Constructor
  constructor Create;
  // Writes value to the given Output Stream. For non-basic types needs to be overriden to work.
  procedure WriteValue(OSt : TStream; Value : Variant ); override;
  // Reads value from the given Input Stream. For non-basic types needs to be overriden to work.
  function ReadValue(ISt : TStream) : Variant; override;
end;


implementation

uses variants,vmath;

{ TArray }

constructor TArray.Create( InitialSize: DWord; IncrementSize: DWord );
var Counter : DWord;
begin
  if ( InitialSize = 0 ) then raise EParameterException.Create('Bad initial size!');
  SetLength(FData,InitialSize);
  for Counter := 0 to InitialSize-1 do
    FillChar( FData[Counter], SizeOf(_T) , 0 );
  FSize      := InitialSize;
  FIncrement := IncrementSize;
  FCurrent  := 0;
  FMax := 0;
  FEmpty := True;
end;

function TArray.MaxSize: DWord;
begin
  Exit(FSize);
end;

procedure TArray.Clear;
begin
  FCurrent := 0;
  FMax     := 0;
end;


function TArray.getElement(Index: DWord): _T;
begin
  if Index >= FSize then ExpandTo(Index);
  Exit(FData[Index]);
end;

procedure TArray.setElement(Index: DWord; const Element: _T);
begin
  if Index >= FSize then ExpandTo(Index);
  FData[Index] := Element;
  if Index > FMax then FMax := Index;
  FEmpty := False;
end;

function TArray.Push(const Element : _T) : DWord;
begin
  SetElement(FCurrent,Element);
  Push := FCurrent;
  Inc(FCurrent);
end;

function TArray.Pop : _T;
begin
  if FCurrent = 0 then raise EEmptyException.Create('Popped empty stack!');
  Dec(FCurrent);
  Pop := FData[FCurrent];
  FillByte(FData[FCurrent],SizeOf(_T),0);
end;

function TArray.Peek : _T;
begin
  if FCurrent = 0 then raise EEmptyException.Create('Peeped empty stack!');
  Peek := FData[FCurrent-1];
end;

function TArray.IsEmpty : boolean;
begin
  IsEmpty := FEmpty or (FCurrent = 0);
end;


procedure TArray.Expand( NewSize: DWord );
var Counter,OldSize : DWord;
begin
  OldSize := High(FData);
  SetLength(FData,NewSize);
  for Counter := OldSize+1 to NewSize-1 do
      FillChar( FData[Counter], SizeOf(_T) , 0 );
  FSize  := NewSize;
end;

procedure TArray.ExpandTo(TargetSize: DWord);
var Temp : DWord;
begin
  Temp := FSize;
  if FIncrement <> 0 then
    while Temp <= TargetSize do Temp := Temp+FIncrement
  else
    while Temp <= TargetSize do Temp := 2*Temp;
  Expand(Temp);
end;

constructor TAssocArray.Create( ACanRewrite : Boolean = False);
var Count : Word;
begin
  for Count := 0 to 95 do FEntries[Count] := nil;
  FItems := 0;
  FillChar( FZero, SizeOf(_T), 0 );
  FCanRewrite := ACanRewrite;
end;

function TAssocArray.getCount : DWord;
begin
  Exit(FItems);
end;

procedure TAssocArray.WriteToStream(OSt: TStream);
var iPtr   : PAssocArrayEntry;
    iCount : DWord;
begin
  OSt.WriteDWord(FItems);
  for iCount := 0 to 95 do
    begin
      iPtr := FEntries[iCount];
      while iPtr <> nil do
      begin
        OSt.WriteAnsiString(iPtr^.Key);
        WriteValue(OSt,iPtr^.Value);
        iPtr := iPtr^.Next;
      end;
    end;
end;

procedure TAssocArray.ReadFromStream(ISt: TStream);
var iCount : DWord;
    iItems : DWord;
    iKey   : AnsiString;
begin
  iItems := ISt.ReadDWord;
  for iCount := 1 to iItems do
  begin
    iKey := ISt.ReadAnsiString;
    AddEntry( iKey, ReadValue( ISt ) );
  end;
end;

procedure TAssocArray.WriteValue(OSt: TStream; Value: _T);
begin
  OSt.Write(Value,SizeOf(_T));
end;

function TAssocArray.ReadValue(ISt: TStream): _T;
begin
  {$HINTS OFF}
  ISt.Read(ReadValue,SizeOf(_T));
  {$HINTS ON}
end;

function TAssocArray.Get(Key: Ansistring; defaultValue: _T): _T;
begin
  FLastEntryName := Key;
  FLastHash := Hash(Key);
  FLastEntry := FEntries[FLastHash];
  if FLastEntry = nil then Exit(defaultValue);
  while FLastEntry^.Key <> Key do
  begin
    FLastEntry := FLastEntry^.Next;
    if FLastEntry = nil then Exit(defaultValue);
  end;
  Exit(FLastEntry^.Value);
end;

function TAssocArray.Get(Key: Ansistring): _T;
begin
  FLastEntryName := Key;
  FLastHash := Hash(Key);
  FLastEntry := FEntries[FLastHash];
  if FLastEntry = nil then Exit(FZero);
  while FLastEntry^.Key <> Key do
  begin
    FLastEntry := FLastEntry^.Next;
    if FLastEntry = nil then Exit(FZero);
  end;
  Exit(FLastEntry^.Value);
end;

procedure TAssocArray.DisposeOf(Value: _T);
begin
end;


function TAssocArray.Hash(Str : Ansistring) : Byte;
var cnt : byte;
    Res : DWord;
begin
  Res := 0;
  if Str <> '' then
  for cnt := 1 to length(Str) do
    Res := Res+DWord(Max(Ord(Str[cnt])-32,0));
  FLastHash := Res mod 96;
  Hash := FLastHash;
end;

function TAssocArray.GetEntry(Str : Ansistring) : _T;
begin
  FLastEntryName := Str;
  FLastHash := Hash(Str);
  FLastEntry := FEntries[FLastHash];
  if FLastEntry = nil then Exit(FZero);
  while FLastEntry^.Key <> Str do
  begin
    FLastEntry := FLastEntry^.Next;
    if FLastEntry = nil then Exit(FZero);
  end;
  Exit(FLastEntry^.Value);
end;

procedure TAssocArray.Remove(Str : Ansistring);
var Prev : PAssocArrayEntry;
begin
  FLastEntryName := Str;
  FLastHash := Hash(Str);
  FLastEntry := FEntries[FLastHash];
  if FLastEntry = nil then Exit;
  Prev := nil;
  while FLastEntry^.Key <> Str do
  begin
    Prev := FLastEntry;
    FLastEntry := FLastEntry^.Next;
    if FLastEntry = nil then Exit;
  end;
  if Prev = nil then
    FEntries[FLastHash] := FLastEntry^.Next
  else
    Prev^.Next := FLastEntry^.Next;
  RemoveEntry( FLastEntry );
  FLastEntry := nil;
end;


function  TAssocArray.Exists(Str : Ansistring) : Boolean;
begin
  GetEntry(Str);
  Exit(FLastEntry <> nil);
end;

procedure TAssocArray.Rewrite(const Entry : PAssocArrayEntry; Value : _T);
begin
  if not FCanRewrite then raise EOverwriteException.Create('Trying to overwrite existing Entry ('+Entry^.Key+') with a new Value!');
  DisposeOf(Entry^.Value);
  Entry^.Value := Value;
end;


procedure TAssocArray.AddEntry(Str : Ansistring; Value : _T);
begin
  GetEntry(Str);
  if FLastEntry <> nil then
  begin
    Rewrite(FLastEntry,Value);
    Exit;
  end;
  Inc(FItems);
  New(FLastEntry);
  FLastEntry^.Key := Str;
  FLastEntry^.Value := value;
  FLastEntry^.Next := FEntries[FLastHash];
  FEntries[FLastHash] := FLastEntry;
end;

destructor TAssocArray.Destroy;
var Count : Word;
begin
  for Count := 0 to 95 do if FEntries[Count] <> nil then RemoveEntryRow(Count);
end;

procedure TAssocArray.RemoveEntryRow(Entry : Word);
var Ptr : PAssocArrayEntry;
begin
  while FEntries[Entry] <> nil do
  begin
    Ptr := FEntries[Entry];
    FEntries[Entry] := Ptr^.Next;
    RemoveEntry(Ptr);
  end;
end;

procedure TAssocArray.RemoveEntry(const Entry : PAssocArrayEntry);
begin
  DisposeOf(Entry^.Value);
  Dispose(Entry);
end;

// These constants are derived from the binary expansion of the fractional
// part of the golden ratio.  Because the golden ratio is an irrational
// number with only 2s in its continued fraction expansion, it is in a
// sense 'far' from any rational number; thus, given input numbers which
// fall into any regular comb pattern in any number of dimensions, this
// hash function will cause them to become equidistributed over S^1.
//
// You are not expected to understand this.
function TSparseSet.hash(X, Y : Cardinal) : LongInt;
begin
  hash := (($9E3779B9 * X + $7F4A7C15 * Y) shr BucketShift) and BucketMask;
end;

// This is only called from Grow, which needs the old table intact, and the
// constructor, where there is no old table, so we deliberately make new
// tables instead of resizing the old ones.
procedure TSparseSet.MakeTable(Order : Integer);
var
  Buckets, MaxLoad : Integer;

  NewPool  : Array of TSparseSetBucket;
  NewIndex : Array of Integer;
  I : Integer;
begin
  Buckets := 1 shl Order;
  MaxLoad := 3 * Buckets;

  SetLength(NewIndex, Buckets);
  SetLength(NewPool, MaxLoad);

  BucketShift := 32 - Order;
  BucketMask := Buckets - 1;
  FreeBucket := 1;

  for I := 0 to Buckets-1 do
    NewIndex[I] := -1;

  for I := 0 to MaxLoad-2 do
    NewPool[I].Next := I+1;

  NewPool[MaxLoad - 1].Next := -1;

  Index := NewIndex;
  BucketPool := NewPool;
end;

constructor TSparseSet.Create;
begin
  MakeTable(5);
end;

procedure TSparseSet.Clear;
begin
  MakeTable(5);
end;

procedure TSparseSet.Grow;
var
  OldIndex : Array of Integer;
  OldPool  : Array of TSparseSetBucket;
  B, C : Integer;
begin
  OldIndex := Index;
  OldPool  := BucketPool;

  MakeTable((32 - BucketShift) + 1);

  for B := 0 to High(OldIndex) do
  begin
    C := OldIndex[B];

    while C <> -1 do
    begin
      Add(OldPool[C].X, OldPool[C].Y);
      C := OldPool[C].Next;
    end;
  end;
end;

procedure TSparseSet.Add(X, Y : Integer);
var
  B, C : Integer;
begin
  if FreeBucket = -1 then Grow;

  B := hash(X, Y);

  C := Index[B];
  while (C <> -1) and ((BucketPool[C].X <> X) or
                       (BucketPool[C].Y <> Y)) do
    C := BucketPool[C].Next;

  // Already there!
  if C <> -1 then Exit;

  C := FreeBucket;

  FreeBucket := BucketPool[C].Next;

  BucketPool[C].Next := Index[B];
  BucketPool[C].X    := X;
  BucketPool[C].Y    := Y;

  Index[B] := C;
end;

procedure TSparseSet.Remove(X, Y : Integer);
var
  B, T : Integer;
  Cp   : ^Integer;
begin
  B := hash(X, Y);
  Cp := @Index[B];

  while Cp^ <> -1 do
  begin
    if (BucketPool[Cp^].X = X) and (BucketPool[Cp^].Y = Y) then
    begin
      T := Cp^;
      Cp^ := BucketPool[T].Next;
      BucketPool[T].Next := FreeBucket;
      FreeBucket := T;
      Exit;
    end;

    Cp := @BucketPool[Cp^].Next;
  end;
end;

function TSparseSet.contains(X, Y : Integer) : Boolean;
var
  B, C : Integer;
begin
  B := hash(X, Y);
  C := Index[B];

  contains := false;

  while C <> -1 do
  begin
    if (BucketPool[C].X = X) and (BucketPool[C].Y = Y) then
    begin
      contains := true;
      Exit;
    end;

    C := BucketPool[C].Next;
  end;
end;

// Prepare the structure
constructor THeapQueue.Create(InitialSize : DWord = 16);
begin
  FSize := InitialSize;
  SetLength(FData,FSize);
  FEntries := 0;
end;

destructor THeapQueue.Destroy;
begin
//  if Managed then
//    for Count := 0 to Entries-1 do
//      FreeAndNil(TObject(Data[Count]));
  inherited Destroy;
end;


// Pop the top of the heap. Exception on empty.
function THeapQueue.Pop : _T;
begin
  if FEntries = 0 then raise EEmptyException.Create('Popped empty HeapQueue!');
  Pop := FData[0];
  Dec(FEntries);
  if FEntries = 0 then Exit;
  FData[0] := FData[FEntries];
  HeapDown(0);
end;

// Peek at the top of the heap. Exception on empty.
function THeapQueue.Peek : _T;
begin
  if FEntries = 0 then raise EEmptyException.Create('Peeked empty HeapQueue!');
  Peek := FData[0];
end;

// Adds a elementy to the HeapQueue
procedure THeapQueue.Add(const Element : _T);
var i : DWord;
begin
  if FEntries = FSize then
  begin
    FSize *= 2;
    SetLength(FData,FSize);
  end;
  i := FEntries;
  Inc(FEntries);
  FData[i] := Element;

  // go up with Data[Entries]
  HeapUp(i);
end;

function THeapQueue.IsEmpty : Boolean;
begin
  IsEmpty := FEntries = 0;
end;

procedure THeapQueue.SetCompareFunc(CompareFunc : TCompareFunc);
begin
  FCompare := CompareFunc;
end;

// Clears the Queue
procedure THeapQueue.Clear;
begin
  FEntries := 0;
end;

// Clears the Queue with a destructor
procedure THeapQueue.Clear( Func : TClearFunc );
var Count : DWord;
begin
  if FEntries = 0 then Exit;
  for Count := 0 to FEntries-1 do
    Func( FData[Count] );
  Clear;
end;

procedure THeapQueue.RemoveIndex(Index: DWord);
begin
  if Index = 0 then begin Pop; exit; end;
  if Index >= FEntries then raise EBadIndexException.Create('Bad index passed to THeapQueue.removeIndex!');
  Dec(FEntries);
  FData[Index] := FData[FEntries];
  if (FEntries = 1) or (Index = FEntries) then Exit;

  if Smaller((Index - 1) div 2,Index)
    then HeapUp( Index )
    else HeapDown( Index );
end;

{procedure THeapQueue.LogPic;
var Pow2,Idx,c : DWord;
    LS : AnsiString;
begin
  Log('---- HEAP(@1) ----', [FEntries]);
  Idx  := 0;
  Pow2 := 1;
  repeat
    LS := '';
    for c := 1 to Pow2 do
    begin
      LS := LS + FDebug( FData[ Idx ] )+ ' ';
      Inc( Idx );
      if Idx = FEntries then
        Break;
    end;
    Pow2 := Pow2 * 2;
    Log(LS);
  until Idx = FEntries;
  Log('------------------')
end;}

function THeapQueue.Greater(Index1,Index2 : DWord) : Boolean;
begin
  if (Index1 = Index2) or (Index2 >= FEntries) then Exit(False);
  Greater := FCompare(FData[Index1],FData[Index2]) > 0;
end;

function THeapQueue.Smaller(Index1,Index2 : DWord) : Boolean;
begin
  if Index1 = Index2 then Exit(False);
  Smaller := FCompare(FData[Index1],FData[Index2]) < 0;
end;

procedure THeapQueue.HeapDown( Index : DWord ); inline;
var l : DWord;
begin
  // go down with Data[0]
  repeat
    l := (Index+1)*2-1;
    if l >= FEntries then Break;
    if l+1 < FEntries then // not last
      if Greater(l+1,l) then Inc(l);
    if Greater(l,Index) then
    begin
      Swap(l,Index);
      Index := l;
    end else Break;
  until false;
end;

procedure THeapQueue.HeapUp( Index : DWord ); inline;
begin
  // go up with Data[Entries]
  while (Index <> 0) and Smaller((Index - 1) div 2,Index) do
  begin
    Swap((Index - 1) div 2,Index);
    Index := (Index - 1) div 2;
  end;
end;


procedure THeapQueue.Swap(Index1,Index2 : DWord);
var Temp : _T;
begin
  Temp := FData[Index2];
  FData[Index2] := FData[Index1];
  FData[Index1] := Temp;
end;

// Returns pointer number Index. Pointer is nil if it's out of range or empty
function THeapQueue.getElement( Index : DWord ) : _T;
begin
  if Index >= FEntries then raise EBadIndexException.Create('Bad index '+IntToStr(Index)+'/'+IntToStr(FEntries)+' passed to THeapQueue.getElement!');
  Exit( FData[ Index ] );
end;

{ TWeightedList }

constructor TWeightedList.Create(InitialSize: DWord);
begin
  FSize := InitialSize;
  SetLength(FValues,FSize);
  SetLength(FWeights,FSize);
  FEntries := 0;
  FSum := 0;
end;

procedure TWeightedList.Add(Value: _TValue; Weight: DWord);
begin
  if FEntries = FSize then
  begin
    FSize *= 2;
    SetLength(FValues,FSize);
    SetLength(FWeights,FSize);
  end;
  FValues [FEntries] := Value;
  FWeights[FEntries] := Weight;
  Inc(FEntries);
  FSum += Weight;
end;

function TWeightedList.Return : _TValue;
var Counter, Index, Roll : DWord;
begin
  if FSum = 0 then raise EEmptyException.Create('Return called on a empty TWeightedList!');

  Index := 0;
  Counter := 0;
  
  Roll := Random(FSum);
  
  while Index < FEntries-1 do
  begin
    Counter += FWeights[Index];
    if Roll < Counter then Break;
    Inc(Index);
  end;
  
  Exit(FValues[Index]);
end;

procedure TWeightedList.Clear;
begin
  FEntries := 0;
  FSum := 0;
end;

destructor TWeightedList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

{ TPriorityChoiceList }

constructor TPriorityChoiceList.Create(InitialSize: DWord);
begin
  FSize := InitialSize;
  SetLength(FValues,FSize);
  FEntries := 0;
  FLowest := High(DWord);
end;

procedure TPriorityChoiceList.Add(Value: _TValue; Priority: DWord);
begin
  if Priority > FLowest then Exit;
  if Priority < FLowest then
  begin
    FLowest  := Priority;
    FEntries := 0;
  end;

  if FEntries = FSize then
  begin
    FSize *= 2;
    SetLength(FValues,FSize);
  end;
  
  FValues [FEntries] := Value;
  Inc(FEntries);
end;

function TPriorityChoiceList.Return: _TValue;
begin
  if FEntries = 0 then raise EEmptyException.Create('Return called on a empty TPriorityChoiceList!');
  Exit(FValues[Random(FEntries)]);
end;

procedure TPriorityChoiceList.Clear;
begin
  FEntries := 0;
end;

function TPriorityChoiceList.Empty: boolean; inline;
begin
  Exit( FEntries = 0 );
end;

destructor TPriorityChoiceList.Destroy;
begin
  inherited Destroy;
end;

{ TManagedArray }

constructor TManagedArray.Create(InitialSize: DWord; IncrementSize: DWord);
begin
  inherited Create( InitialSize, IncrementSize );
end;

destructor TManagedArray.Destroy;
var Counter : DWord;
begin
  for Counter := 0 to FSize-1 do
    FreeAndNil( TObject( FData[Counter] ) );
  inherited Destroy;
end;

function TManagedArray.Pop: _TMANAGED;
begin
  Exit( _TMANAGED(inherited Pop) );
end;

function TManagedArray.Peek: _TMANAGED;
begin
  Exit( _TMANAGED(inherited Peek) );
end;

function TManagedArray.getElement(Index: DWord): _TMANAGED;
begin
  Exit( _TMANAGED(inherited getElement(Index)));
end;

procedure TManagedArray.setElement(Index: DWord; const Element: _TMANAGED);
begin
 inherited setElement(Index,Element);
end;

{ TStringArray }

constructor TStringArray.Create(InitialSize: DWord; IncrementSize: DWord);
begin
  inherited Create(InitialSize,IncrementSize);
end;

procedure TStringArray.Read(TextFile: AnsiString);
var TF : Text;
    TS : AnsiString;
begin
  Assign(TF,TextFile);
  Reset(TF);
  while not EOF(TF) do
  begin
    Readln(TF,TS);
    Push(TS);
  end;
  Close(TF);
end;

procedure TStringArray.Write(TextFile: AnsiString);
var TF : Text;
    Counter : DWord;
begin
  Assign(TF,TextFile);
  Rewrite(TF);
  for Counter := 0 to FMax do
    Writeln(TF,GetElement(Counter));
  Close(TF);
end;

procedure TStringArray.ReadFromStream(Stream: TStream);
var Lines   : DWord;
    Counter : DWord;
begin
  Lines := Stream.ReadDWord;
  for Counter := 1 to Lines do
    Push(Stream.ReadAnsiString);
end;

procedure TStringArray.WriteToStream(Stream: TStream);
var Counter : DWord;
begin
  if isEmpty then
  begin
    Stream.WriteDWord(0);
    Exit;
  end;
  Stream.WriteDWord(Count+1);
  for Counter := 0 to Count do
    Stream.WriteAnsiString(GetElement(Counter));
end;

function TStringArray.Get(Index: DWord): AnsiString;
begin
  Exit(getElement(Index));
end;

function TStringArray.Size: DWord;
begin
  Exit(Count);
end;

{ TStringAssocArray }

constructor TStringAssocArray.Create;
begin
  inherited Create( True );
end;


{ TMessageBuffer }

constructor TMessageBuffer.Create(newSize: DWord; maxWidth: Word);
begin
  inherited Create( newSize );
  FWidth      := maxWidth;
  FPosition   := 0;
  FBufferSize := newSize;
  FFilled     := False;
end;

function TMessageBuffer.Get(Index: Word): Ansistring;
var RelPos : LongInt;
begin
  RelPos := FPosition - Index - 1;
  while RelPos < 0 do RelPos := RelPos + LongInt(FBufferSize);
  Exit(FData[RelPos]);
end;

function TMessageBuffer.Size: DWord;
begin
  if FFilled then
     Exit(FBufferSize-1)
  else
     Exit(FPosition);
end;

function TMessageBuffer.Add(str: AnsiString) : Word;
var Line, Rest : AnsiString;
begin
  Add := 0;
  repeat
    Line := str;
    Rest := '';
    if Length(str) > FWidth then
      Split(str,Line,Rest,' ',FWidth-1);
    FData[FPosition] := Line;
    Inc(FPosition);
    if FPosition = FBufferSize then
    begin
      FPosition := 0;
      FFilled   := True;
    end;
    str := Rest;
    Inc(Add);
  until Rest = '';
end;

procedure TMessageBuffer.Clear;
var Counter : DWord;
begin
  inherited Clear;
  for Counter := 0 to FBufferSize-1 do
    FData[Counter] := '';
  FFilled   := False;
  FPosition := 0;
end;

procedure TMessageBuffer.KillLast;
begin
  if FPosition = 0 then FPosition := FBufferSize;
  Dec(FPosition);
  FData[FPosition] := '';
end;

function TMap.GetElement( const Index : _KEY ) : _VALUE;
var Query : PTreeNode;
begin
  Query := FindNode( Index, Root );
  if Query = nil then raise EBadIndexException.Create('Index not found!');
  Exit( Query^.Value );
end;

procedure TMap.SetElement( const Index : _KEY ; const Element : _VALUE);
var Found : Boolean;
begin
  Found := False;
  Insert( Index, Element, Root, Found );
end;

function TMap.Exists( const Index : _KEY ) : Boolean;
begin
  Exit( FindNode( Index, Root ) <> nil );
end;

procedure TMap.Remove( const Index : _KEY );
var Found : Boolean;
begin
  Found := False;
  Remove( Index, Root, Found );
  if found then dec(FSize);
end;

function TMap.Remove( const Key : _KEY; var Node : PTreeNode; var Found : Boolean ) : Boolean;
var Decreased : Boolean;
    Temp      : PTreeNode;
    BalChange : ShortInt;
begin
  if Node = nil then Exit( False );
  Decreased := False;

  if Node^.Key = Key then BalChange := 0
  else
    if Node^.Key < Key
      then BalChange := -1
      else BalChange := 1;

  if BalChange <> 0 then
  begin
    // Do recursive delete
    if Node^.Key < Key then Decreased := Remove( Key, Node^.Right, Found )
                       else Decreased := Remove( Key, Node^.Left, Found );
    if not Decreased then BalChange := 0;
    // If node was found exit to prevent rebalancing
    if not Found then Exit( False );
  end
  else
  begin
    // Node found!
    Found := True;

    if (Node^.Left = nil) and (Node^.Right = nil) then
    begin
      // We have a leaf -- life is simple
      Dispose( Node );
      Node := nil;
      Exit( True );
    end;

    if (Node^.Left = nil) or (Node^.Right = nil) then
    begin
      // One child is present -- less simple but ok
      Temp := Node;
      if Node^.Left = nil
        then Node := Node^.Right
        else Node := Node^.Left;

      Dispose( Temp );
      Exit( True );
    end;

    // The ugly case, both children present

    // find successor
    Temp := Node^.Right;
    while Temp^.Left <> nil do Temp := Temp^.Left;

    // Copy
    Node^.Value := Temp^.Value;
    Node^.Key   := Temp^.Key;

    // And delete
    Decreased := Remove( Node^.Key, Node^.Right, found );

    // Key less
    if Decreased then BalChange := -1;
  end;

  Node^.Balance += BalChange;

  // If recursive call imbalanced, rebalance
  if BalChange <> 0 then
  begin
    if Node^.Balance <> 0 then
      Exit( ReBalance( Node ) );

    Exit( True );
  end
  else Exit( False );
end;

procedure TMap.Clear;
begin
  Delete( Root );
  FSize := 0;
end;


function TMap.RotateLeft(var Node : PTreeNode) : Boolean;
var Old : PTreeNode;
begin
  // Save node
  Old  := Node;

  // Balance check
  RotateLeft := (Node^.Right^.Balance <> 0);

  // Assign new node
  Node := Old^.Right;

  // Node exchanges it's Left subtree for it's parent
  Old^.Right := Node^.Left;
  Node^.Left := Old;

  // update balances
  Dec( Node^.Balance );
  Old^.Balance := -Node^.Balance;
end;

function TMap.RotateRight(var Node : PTreeNode) : Boolean;
var Old : PTreeNode;
begin
  // Save node
  Old  := Node;

  // Balance check
  RotateRight := (Node^.Left^.Balance <> 0);

  // Assign new node
  Node := Old^.Left;

  // Node exchanges it's Left subtree for it's parent
  Old^.Left   := Node^.Right;
  Node^.Right := Old;

  // update balances
  Inc( Node^.Balance );
  Old^.Balance := -Node^.Balance;
end;

function TMap.RotateTwiceLeft(var Node : PTreeNode) : Boolean;
var Old : PTreeNode;
    Sub : PTreeNode;
begin
  Old := Node;
  Sub := Node^.Right;

  // New node
  Node := Old^.Right^.Left;

  // New node exchanges it's subtree for it's grandparent
  Old^.Right := Node^.Left;
  Node^.Left := Old;

  // New node exchanges it's subtree for it's parent
  Sub^.Left := Node^.Right;
  Node^.Right := Sub;

  // update balances
  Node^.Left^.Balance  := -max(Node^.Balance, 0);
  Node^.Right^.Balance := -min(Node^.Balance, 0);
  Node^.Balance := 0;

  // Double rotation always shortens the height
  Exit( true );
end;

function TMap.RotateTwiceRight(var Node : PTreeNode) : Boolean;
var Old : PTreeNode;
    Sub : PTreeNode;
begin
  Old := Node;
  Sub := Node^.Left;

  // New node
  Node := Old^.Left^.Right;

  // New node exchanges it's subtree for it's grandparent
  Old^.Left := Node^.Right;
  Node^.Right := Old;

  // New node exchanges it's subtree for it's parent
  Sub^.Right := Node^.Left;
  Node^.Left := Sub;

  // update balances
  Node^.Left^.Balance  := -max(Node^.Balance, 0);
  Node^.Right^.Balance := -min(Node^.Balance, 0);
  Node^.Balance := 0;

  // Double rotation always shortens the height
  Exit( true );
end;

function TMap.ReBalance(var Node : PTreeNode) : Boolean;
begin
  ReBalance := False;
  if Node^.Balance < -1 then
  begin
    // Right rotation needed
    if Node^.Left^.Balance = 1 then
       // double rotation needed
       ReBalance := RotateTwiceRight(Node)
    else
       // single rotation needed
       ReBalance := RotateRight(Node);
  end
  else if Node^.Balance > 1 then
  begin
    // Need a left rotation
    if Node^.Right^.Balance = -1 then
       // double rotation needed
       ReBalance := RotateTwiceLeft(Node)
    else
       // single rotation needed
       ReBalance := RotateLeft(Node);
  end;
end;


function TMap.Insert( const Key : _KEY; const Value : _VALUE; var Node : PTreeNode; var Found : Boolean ) : Boolean;
var RecursiveRes : Boolean;
begin
  // if Node is empty, insert new one
  if Node = nil then
  begin
    New(Node);
    Node^.Left    := nil;
    Node^.Right   := nil;
    Node^.Key     := Key;
    Node^.Value   := Value;
    Node^.Balance := 0;
    Inc( FSize );
    Found := False;
    Exit( True );
  end;

  // Overwrite if found
  if Node^.Key = Key then
  begin
    Node^.Value := Value;
    Found := True;
    Exit( False )
  end;

  // Do recursive insert
  if Node^.Key < Key then RecursiveRes := Insert( Key, Value, Node^.Right, Found )
                     else RecursiveRes := Insert( Key, Value, Node^.Left, Found );

  // If node was found exit to prevent rebalancing
  if Found then Exit( False );

  // If recursive call imbalanced, rebalance
  if RecursiveRes then
  begin
    if Node^.Key < Key then Inc( Node^.Balance )
                       else Dec( Node^.Balance );

    if Node^.Balance <> 0 then Exit( not ReBalance( Node ) );

    Exit( False );
  end
  else Exit( False );
end;

procedure TMap.Delete( var Node : PTreeNode );
begin
  if Node = nil then Exit;
  Delete( Node^.Left );
  Delete( Node^.Right );
  Dispose( Node );
  Node := nil;
end;

{$HINTS OFF}
function TMap.FindNode( const Key : _KEY; Node : PTreeNode ) : PTreeNode;
begin
  while Node <> nil do
  begin
    if Node^.Key = Key then Exit( Node );
    if Node^.Key < Key then Node := Node^.Right
                       else Node := Node^.Left;
  end;
  Exit( nil );
end;
{$HINTS ON}

procedure TMap.ForAll( Visitor : TVisitor; Node : PTreeNode );
begin
  if FSize = 0 then exit;
  if Assigned( Node^.Left ) then ForAll(Visitor,Node^.Left);
  Visitor( Node^.Key, Node^.Value );
  if Assigned( Node^.Right ) then ForAll(Visitor,Node^.Right);
end;

procedure TMap.ForAll( Visitor : TVisitor );
begin
  ForAll( Visitor, Root );
end;

constructor TMap.Create;
begin
  Root := nil;
  FSize := 0;
end;

destructor TMap.Destroy;
begin
  Delete( Root );
  inherited Destroy;
end;

constructor TVector.Create( InitialCapacity: DWord );
begin
  Reserve( InitialCapacity );
  FSize      := 0;
end;

procedure TVector.Clear;
begin
  FSize      := 0;
end;

function TVector.GetElement( Index: DWord ): _TYPE;
begin
  if Index >= FCapacity then raise EBadIndexException.Create('Bad index passed to vector get!');
  Exit(FData[Index]);
end;

procedure TVector.SetElement( Index: DWord; const Element: _TYPE );
begin
  if Index >= FCapacity then raise EBadIndexException.Create('Bad index passed to vector set!');
  FData[Index] := Element;
end;

procedure TVector.IndexSwap( ia, ib : DWord );
var temp : _TYPE;
begin
  temp      := FData[ia];
  FData[ia] := FData[ib];
  FData[ib] := temp;
end;

function TVector.QSplit( ibegin, iend : DWord; Sorter : TSortFunction ) : DWord;
var left, right : DWord;
    pivot       : _TYPE;
begin
  // First element will be the pivot
  pivot := FData[ibegin];
  left  := ibegin + 1;
  right := iend;

  // Swap wrong pairs
  while left <= right do
  begin
    while ( left <= iend   ) and ( not Sorter(FData[left], pivot)  )  do left += 1;
    while ( right > ibegin ) and (     Sorter(FData[right], pivot) ) do right -= 1;
    if left < right then IndexSwap( left, right );
  end;

  // Swap in the pivot into the proper indexPut the pivot between the halves. }
  IndexSwap( ibegin, right );

  Exit( right );
end;

procedure TVector.QuickSort(ibegin, iend : DWord; Sorter : TSortFunction);
var isplit : DWord; // split index
begin
  if ibegin < iend then
  begin
    isplit := QSplit( ibegin, iend, Sorter );
    Quicksort( ibegin, isplit, Sorter );
    Quicksort( isplit+1, iend, Sorter );
  end;
end;

function TVector.Push( const Element : _TYPE ) : DWord;
begin
  Inc( FSize );
  if FSize > FCapacity then Reserve( FCapacity * 2 );
  FData[FSize-1] := Element;
  Push := FSize-1;
end;

function TVector.Pop() : _TYPE; inline;
begin
  if FSize = 0 then raise EInvalidOperation.Create('vector is empty!');
  Dec( FSize );
  Exit( FData[FSize] );
end;

function TVector.Last(): _TYPE; inline;
begin
  if FSize = 0 then raise EInvalidOperation.Create('vector is empty!');
  Exit( FData[FSize-1] );
end;


procedure TVector.PushFront( const Element : _TYPE );
var
  count: dword;
begin
  Inc( FSize );
  if FSize > FCapacity then Reserve( FCapacity * 2 );
  if (FSize > 1) then
    for count := FSize-1 downto 1 do
      FData[Count] := FData[Count-1];
  FData[0] := Element;
end;

function TVector.PopFront() : _TYPE;
begin
  if FSize = 0 then raise EInvalidOperation.Create('vector is empty!');
  result:=FData[0];
  EraseAndShift(0);
end;

procedure TVector.Reserve( NewCapacity: DWord );
begin
  SetLength( FData, NewCapacity );
  FCapacity  := NewCapacity;
end;

procedure TVector.Resize( NewSize: DWord );
var Counter, OldCapacity : DWord;
begin
  OldCapacity := High(FData);
  Reserve( NewSize );
  for Counter := OldCapacity+1 to FCapacity-1 do
      FillChar( FData[Counter], SizeOf(_TYPE) , 0 );
  FSize  := FCapacity;
end;

procedure TVector.EraseAndShift( Index : DWord );
var Count : DWord;
begin
  if Index >= FSize then raise EBadIndexException.Create('Bad index passed to vector set!');
  if ( Index < FSize-1 ) and ( FSize > 1 ) then
    for Count := Index to FSize-2 do
      FData[Count] := FData[Count+1];

  // Shorten the array
  Pop;
end;

procedure TVector.ForAll(Visitor: TVectorVisitor);
var Count : DWord;
begin
  if FSize <> 0 then
  for Count := 0 to FSize-1 do
    Visitor( FData[Count] );
end;

procedure TVector.ForAllFilter(Visitor: TVectorFilter);
var Count : DWord;
begin
  Count := 0;
  while Count < FSize do
    if Visitor( FData[Count] )
      then Inc(Count)
      else EraseAndShift(Count);
end;

function TVector.FindIndex( const Element : _TYPE ) : DWord;
var Index : DWord;
begin
  for Index := 0 to FSize-1 do
    if CompareMem( @FData[Index], @Element, SizeOf(_TYPE) ) then
      Exit( Index );
  Exit( VNOT_FOUND );
end;

procedure TVector.Sort( Sorter : TSortFunction );
begin
  if (FSize = 0) then exit;
  Quicksort(0, FSize-1, Sorter);
end;

function TVector.Empty: Boolean;
begin
  Exit( FSize = 0 );
end;

destructor TVector.Destroy;
begin
  SetLength( FData, 0 );
  inherited destroy;
end;


{ TProperties }

constructor TProperties.Create;
begin
  inherited Create(True);
  FZero := VarNull;
end;

procedure TProperties.WriteValue(OSt: TStream; Value: Variant);
begin
  with TVarData(Value) do
  begin
    OSt.WriteWord( vType );
    case vType of
      varnull     : ;
      varsmallint : OSt.Write(vSmallInt,SizeOf(vSmallInt));
      varshortint : OSt.Write(vShortInt,SizeOf(vShortInt));
      varinteger  : OSt.Write(vInteger,SizeOf(vInteger));
      varint64    : OSt.Write(vInt64,SizeOf(vInt64));
      varsingle   : OSt.Write(vSingle,SizeOf(vSingle));
      vardouble   : OSt.Write(vDouble,SizeOf(vDouble));
      varboolean  : OSt.Write(vBoolean,SizeOf(vBoolean));
      varbyte     : OSt.Write(vByte,SizeOf(vByte));
      varword     : OSt.Write(vWord,SizeOf(vWord));
      varlongword : OSt.Write(vLongWord,SizeOf(vLongWord));
      varqword    : OSt.Write(vQWord,SizeOf(vQWord));
      varstring   : OSt.WriteAnsiString(Value);
    else
      raise EStoreException.Create('TProperties.Write : unsupported variant type ('+IntToStr(vType)+')!');
    end;
  end;
end;

{$HINTS OFF}
function TProperties.ReadValue(ISt: TStream): Variant;
var VType : Word;
    S     : Single;
    D     : Double;
    B     : Boolean;
begin
  VType := ISt.ReadWord;
  case vType of
    varnull     : Exit( varNull );
    varshortint : Exit( ShortInt(ISt.ReadByte) );
    varsmallint : Exit( SmallInt(ISt.ReadWord) );
    varinteger  : Exit( Integer(ISt.ReadDWord) );
    varint64    : Exit( Int64(ISt.ReadQWord) );
    varsingle   : begin ISt.Read(S,SizeOf(Single)); Exit(S); end;
    vardouble   : begin ISt.Read(D,SizeOf(Double)); Exit(D); end;
    varboolean  : begin ISt.Read(B,SizeOf(Boolean)); Exit(B); end;
    varbyte     : Exit( ISt.ReadByte );
    varword     : Exit( ISt.ReadWord );
    varlongword : Exit( ISt.ReadDWord );
    varqword    : Exit( ISt.ReadQWord );
    varstring   : Exit( ISt.ReadAnsiString() );
  else
    raise EStoreException.Create('TProperties.Read : unsupported variant type ('+IntToStr(vType)+')!');
  end;

end;
{$HINTS ON}

end.

