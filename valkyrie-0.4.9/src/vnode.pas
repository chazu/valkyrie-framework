{$INCLUDE valkyrie.inc}
// @abstract(Node class for Valkyrie)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(May 7, 2004)
// @cvs($Author: chaos-dev $)
// @cvs($Date: 2008-01-14 22:16:41 +0100 (Mon, 14 Jan 2008) $)
//
// @link(TNode) is core class from which other classes inherit.
// It implements a tree-like structure. Also, each node
// has an unique identifier, represented by @link(TUID).
//
// This unit also implements the two Valkyrie base classes :
// TVObject and TVClass.
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
// @preformatted(
// TODO: Check wether a Node can dispose of itself via Self.Done.
// TODO: Implement generic Save/Load via streams.
// )

unit vnode;
interface
uses Classes, vmsg, vutil, vdebug;

// The most generic of Valkyrie objects. Implements only the error
// handling functions. It is recommended that all Valkyrie classes
// inherit at least this class.
type

{ TVObject }

TVObject = class( TObject )
     // TVObject Interface for @link(grdebug.CritError)
     procedure   CritError( const aCritErrorString : Ansistring ); virtual;
     // TVObject Interface for @link(grdebug.Warning).
     procedure   Warning  ( const aWarningString   : Ansistring ); virtual;
     // TVObject Interface for @link(grdebug.Log).
     procedure   Log      ( const aLogString       : Ansistring ); virtual;
     // TVObject Interface for @link(grdebug.Log).
     procedure   Log      ( Level : TLogLevel; const aLogString : Ansistring ); virtual;
     // TVObject Interface for @link(grdebug.CritError), VFormat version.
     procedure   CritError( const aCritErrorString : Ansistring; const aParam : array of Const );
     // TVObject Interface for @link(grdebug.Warning), VFormat version.
     procedure   Warning  ( const aWarningString   : Ansistring; const aParam : array of Const );
     // TVObject Interface for @link(grdebug.Log), VFormat version.
     procedure   Log      ( const aLogString       : Ansistring; const aParam : array of Const );
     // TVObject Interface for @link(grdebug.Log), VFormat version.
     procedure   Log      ( Level : TLogLevel; const aLogString       : Ansistring; const aParam : array of Const );
     // Returns wether the object has a parent -- in case of TVObject it's always false
     function hasParent : boolean; virtual;
     // Returns wether the object has a child -- in case of TVObject it's always false
     function hasChild : boolean; virtual;
     // Returns wether the object is a TVNode
     function isNode : boolean; virtual;
  end;

type TNode = class;

// Enumerator for nodes. Implemented as a generic so it may be reused
// For a node that implements TNode.
  generic TGNodeEnumerator<T> = object
  protected
    // We store the parent node for the case if during iteration the child node
    // changes it's parent.
    FParent   : TNode;
    // Current node, returned by the iterator.
    FCurrent  : TNode;
    // Next node, held separately so we can go on smoothly event if the current
    // node changes it's parent.
    FNext     : TNode;
    // Returns current node as T. No checking is done!
    function GetCurrent: T;
  public
    // Creates the iterator
    constructor Create( Parent : TNode );
    // Moves the iterator and returns whether current if valid
    function MoveNext : Boolean;
    // Returns current node
    property Current : T read GetCurrent;
  end;

  // Specialization of the enumerator for TNode
  TNodeEnumerator = specialize TGNodeEnumerator<TNode>;

// Reverse Enumerator for nodes. Implemented as a generic so it may be reused
// For a node that implements TNode.
  generic TGNodeReverseEnumerator<T> = object
  protected
    // We store the parent node for the case if during iteration the child node
    // changes it's parent.
    FParent   : TNode;
    // Current node, returned by the iterator.
    FCurrent  : TNode;
    // Next node, held separately so we can go on smoothly event if the current
    // node changes it's parent.
    FNext     : TNode;
    // Returns current node as T. No checking is done!
    function GetCurrent: T;
  public
    // Creates the iterator
    constructor Create( Parent : TNode );
    // Moves the iterator and returns whether current if valid
    function MoveNext : Boolean;
    // Allows to be used as enumerator
    function GetEnumerator : TGNodeReverseEnumerator;
  public
    // Returns current node
    property Current : T read GetCurrent;
  end;

  // Specialization of the reverse enumerator for TNode
  TNodeReverseEnumerator = specialize TGNodeReverseEnumerator<TNode>;

// The base Valkyrie node class, implements data for object serialization and
// unique identification (see @link(TUIDStore)). One of the reasons for
// this serialization is to create a global Load/Save Mechanism.
// Implements a self-disposing tree-like structure. The base class of @link(TSystem),
// and considered a building block for the data structure of the program. At best,
// all the program nodes should be gathered in one tree -- that allows one-call
// disposal of all the allocated memory.
 TNode = class(TVObject)
       // Standard constructor, zeroes all fields.
       constructor Create; virtual;
       // Stream constructor, reads UID, and ID from stream, should be overriden.
       constructor CreateFromStream( Stream : TStream ); virtual;
       // Write Node to stream (UID and ID) should be overriden.
       procedure WriteToStream( Stream : TStream ); virtual;
       // zeroes all fields.
       procedure Clean; virtual;
       // Adds theChild as a child of current node.
       // The child is added to the END of the Child list.
       procedure   Add(theChild : TNode); virtual;
       // Executed when the node has changed it's parent (not in nil case). By
       // default does nothing.
       procedure ParentChanged; virtual;
       // Changes parent to Destination.
       // Error free.
       procedure   Move(Destination : TNode);
       // Basic recieveing method. Should be overriden.
       procedure   Receive(MSG : TMessage); virtual;
       // Removes self from Parent node, calls Parent.Remove(Self)
       // if parent present.
       procedure   Detach; virtual;
       // Removes child from this node, does nothing if child's parent
       // isn't self. Detach calls this, so this is always ran
       procedure   Remove( theChild : TNode ); virtual;
       // Destroys all children.
       procedure DestroyChildren;
       // Standard destructor, frees @link(UID), and destroys
       // children and siblings.
       destructor  Destroy; override;
       // Returns wether the node has a parent.
       function hasParent : boolean; override;
       // Returns wether the object has a child.
       function hasChild : boolean; override;
       // Returns wether the object is a TNode
       function isNode : boolean; override;
       // Returns wether the object is a first child
       function isFirstChild : boolean; 
       // Returns wether the object is the last child
       function isLastChild : boolean;
       // TNode Interface for @link(grdebug.CritError)
       // Calls vdebug.CritError, providing additional information on
       // the error-calling TNode.
       procedure   CritError(const aCritErrorString : Ansistring); override; overload; deprecated;
       // TNode Interface for @link(grdebug.Warning).
       // Calls vdebug.Warning, providing additional information on
       // the warning-calling TNode.
       procedure   Warning  (const aWarningString   : Ansistring); override; overload;
       // TNode Interface for @link(grdebug.Log).
       // Calls vdebug.Log, providing additional information on
       // the log-calling TNode.
       procedure   Log      (const aLogString       : Ansistring); override; overload;
       // TNode Interface for @link(grdebug.Log).
       // Calls vdebug.Log, providing additional information on
       // the log-calling TNode.
       procedure   Log      (Level : TLogLevel; const aLogString : Ansistring); override; overload;
       // Compare with other node (should be overriden). By default compares
       // by ID then by UID.
       function Compare( aOther : TNode ) : Boolean; virtual;
       // Find child by pointer
       function FindChild( Child : TNode; Recursive : Boolean = False ) : TNode; overload;
       // Find child by uid
       function FindChild( UID : TUID; Recursive : Boolean = False ) : TNode; overload;
       // Find child by id
       function FindChild( const ID : AnsiString; Recursive : Boolean = False ) : TNode; overload;
       // Enumerator support
       function GetEnumerator: TNodeEnumerator;
       // Reverse enumerator
       function Reverse : TNodeReverseEnumerator;
     protected
       // Unique IDentification number (@link(TUID))
       // Assigned by the @link(UIDs) singleton, unique.
       FUID        : TUID;
       // Identification Number of this Class - may be shared among similar
       // Classes.
       FID         : TIDN;
     private
       // Link to the parent node.
       FParent     : TNode;
       // Link to first child node.
       FChild      : TNode;
       // Link to next node.
       FNext       : TNode;
       // Link to previous node.
       FPrev       : TNode;
       // Count of children nodes.
       FChildCount : DWord;
     public
       property UID        : TUID read FUID;
       property ID         : TIDN read FID;
       property Parent     : TNode read FParent;
       property Child      : TNode read FChild;
       property Next       : TNode read FNext;
       property Prev       : TNode read FPrev;
       property ChildCount : DWord read FChildCount;
     end;

  TNodeList = class;

// Enumerator for node lists. Implemented as a generic so it may be reused
// For a node list that stores TNode descendants.
// Note : Works only on packed lists!
  generic TGNodeListEnumerator<T> = object
  protected
    // Current node, returned by the iterator.
    FList     : TNodeList;
    // Next node, held separately so we can go on smoothly event if the current
    // node changes it's parent.
    FCurrent  : DWord;
    // Returns current node as T. No checking is done!
    function GetCurrent : T;
  public
    // Creates the iterator
    constructor Create( List : TNodeList );
    // Moves the iterator and returns whether current if valid
    function MoveNext : Boolean;
    // Returns current node
    property Current : T read GetCurrent;
  end;

  // Specialization of the enumerator for TNode
  TNodeListEnumerator = specialize TGNodeListEnumerator<TNode>;

// Reverse enumerator for node lists. Implemented as a generic so it may be reused
// For a node list that stores TNode descendants
// Note : Works only on packed lists!
  generic TGNodeListReverseEnumerator<T> = object
  protected
    // Current node, returned by the iterator.
    FList     : TNodeList;
    // Next node, held separately so we can go on smoothly event if the current
    // node changes it's parent.
    FCurrent  : DWord;
    // Returns current node as T. No checking is done!
    function GetCurrent : T;
  public
    // Creates the iterator
    constructor Create( List : TNodeList );
    // Moves the iterator and returns whether current if valid
    function MoveNext : Boolean;
    // Allows to be used as enumerator
    function GetEnumerator : TGNodeListReverseEnumerator;
  public
    // Returns current node
    property Current : T read GetCurrent;
  end;

  // Specialization of the enumerator for TNode
  TNodeListReverseEnumerator = specialize TGNodeListReverseEnumerator<TNode>;

 // A type to manage and pass ordered lists of Nodes, without
 // owning them. Out of conviniece, the Index is 1-based.
 type TNodeList = class( TVObject )
     // Constructs the list, MaxSize is the maximum amount of
     // items stored
     constructor Create( MaxSize : DWord );
     // Pushes an item into the first free slot of the list.
     // Returns false if there's no place to push, true otherwise.
     function Push( aItem : TNode ) : Boolean;
     // Finds an item on the list, if present returns it, if
     // not returns nil.
     function Find( aItem : TNode ) : TNode;
     // Finds by ID.
     function FindByID( const ID : AnsiString ) : TNode;
     // Finds by UID.
     function FindByUID( const UID : TUID ) : TNode;
     // Returns true if list has this item.
     function Has( aItem : TNode ) : Boolean;
     // Finds an item on the list, if present returns it, if
     // not returns nil.
     function Remove( aItem : TNode ) : Boolean;
     // Finds by ID.
     function Remove( const ID : AnsiString ) : Boolean;
     // Finds by UID.
     function Remove( const UID : TUID ) : Boolean;
     // Clears the list
     procedure Clear;
     // Sorts the list
     procedure Sort;
     // Moves items so, that there are no empty spaces inside.
     procedure Pack;
     // Returns last non-nil index (1-based), returns 0 if no
     // non-nil items present.
     // Note : Works properly only on Packed lists
     function LastIndex : DWord;
     // Destroys the list, but not the items stored on it
     destructor Destroy; override;
     // Enumerator support
     // Note : Works only on packed lists!
     function GetEnumerator : TNodeListEnumerator; inline;
     // Reverse enumerator support
     // Note : Works only on packed lists!
     function Reverse : TNodeListReverseEnumerator; inline;
   protected
     // Gets an item from the list. If index is out of range,
     // we return nil.
     function GetItem( aIndex : DWord ) : TNode;
     // Places an item on the list. If one is present in the
     // index, it is simply overwritten
     procedure SetItem( aIndex : DWord; aItem : TNode );
   private
     FItems   : array of TNode;
     FMaxSize : DWord;
     FSize    : DWord;
   public
     property Items[ aIndex : DWord ] : TNode read GetItem write SetItem; default;
     property Size : DWord     read FSize;
     property Capacity : DWord read FMaxSize;
   end;

// Generic override of TNodeList, to return typess that we want
generic TGNodeList<T> = class( TNodeList )
private
    public type TEnumeratorType        = specialize TGNodeListEnumerator<T>;
    public type TReverseEnumeratorType = specialize TGNodeListReverseEnumerator<T>;
    // Pushes an item into the first free slot of the list.
    // Returns false if there's no place to push, true otherwise.
    function Push( aItem : T ) : Boolean; reintroduce;
    // Finds an item on the list, if present returns it, if
    // not returns nil.
    function Find( aItem : T ) : T; reintroduce;
    // Finds by ID.
    function FindByID( const ID : AnsiString ) : T; reintroduce;
    // Finds by UID.
    function FindByUID( const UID : TUID ) : T; reintroduce;
    // Enumerator support
    // Note : Works only on packed lists!
    function GetEnumerator: TEnumeratorType; reintroduce;
    // Reverse enumerator support
    // Note : Works only on packed lists!
    function Reverse : TReverseEnumeratorType; reintroduce;
  protected
    // Gets an item from the list. If index is out of range,
    // we return nil.
    function GetItem( aIndex : DWord ) : T; inline;
    // Gets an item from the list. If index is out of range,
    // we return nil.
    procedure SetItem( aIndex : DWord; const aItem : T ); inline;
  public
    property Items[ aIndex : DWord ] : T read GetItem write SetItem; default;
end;

implementation
uses vuid, sysutils;

{ TGNodeEnumerator }

function TGNodeEnumerator.GetCurrent : T;
begin
  Exit( T(FCurrent) );
end;

constructor TGNodeEnumerator.Create ( Parent : TNode );
begin
  FParent  := Parent;
  FCurrent := nil;
  FNext    := Parent.Child;
end;

function TGNodeEnumerator.MoveNext : Boolean;
begin
  FCurrent := FNext;
  if FNext <> nil then FNext := FNext.Next;
  if FNext = FParent.Child then FNext := nil;
  Exit( FCurrent <> nil );
end;

{ TGNodeReverseEnumerator }

function TGNodeReverseEnumerator.GetCurrent : T;
begin
  Exit( T(FCurrent) );
end;

constructor TGNodeReverseEnumerator.Create ( Parent : TNode );
begin
  FParent  := Parent;
  FCurrent := nil;
  if Parent.Child = nil
    then FNext := nil
    else FNext := Parent.Child.Prev;
end;

function TGNodeReverseEnumerator.MoveNext : Boolean;
begin
  FCurrent := FNext;
  if FNext <> nil then
  begin
    FNext := FNext.Prev;
    if FNext = FParent.Child.Prev then FNext := nil;
  end;
  Exit( FCurrent <> nil );
end;

function TGNodeReverseEnumerator.GetEnumerator : TGNodeReverseEnumerator;
begin
  Exit( Self );
end;

{ TNode }

constructor TNode.Create;
begin
  Log(LTRACE,'Created.');
  Clean;
end;

constructor TNode.CreateFromStream( Stream: TStream );
begin
  Log(LTRACE,'Created.');
  Clean;
  FID  := Stream.ReadAnsiString();
  FUID := Stream.ReadQWord();
end;

procedure TNode.WriteToStream( Stream: TStream );
begin
  Stream.WriteAnsiString( FID );
  Stream.WriteQWord( FUID );
end;

procedure TNode.Clean;
begin
  FChild      := nil;
  FParent     := nil;
  FNext       := Self;
  FPrev       := Self;
  FChildCount := 0;
  FUID        := 0;
  FID         := '';
end;

procedure TNode.Add(theChild : TNode);
begin
  if theChild.FParent <> nil then theChild.Detach;
  theChild.FParent := Self;
  if FChild = nil then
    FChild := theChild
  else
  begin
    theChild.FPrev := FChild.FPrev;
    theChild.FNext := FChild;
    FChild.FPrev.FNext := theChild;
    FChild.FPrev      := theChild;
  end;  
  Inc(FChildCount);
  theChild.ParentChanged;
end;

procedure TNode.ParentChanged;
begin
  // noop
end;

function TNode.hasParent : boolean;
begin
  Exit(FParent <> nil);
end;

function TNode.hasChild : boolean;
begin
  Exit(FChild <> nil);
end;

function TNode.isNode : boolean; 
begin
  Exit(True);
end;

function TNode.isFirstChild : boolean; 
begin
  if FParent <> nil then
    Exit(FParent.FChild = Self)
  else Exit(False);
end;

function TNode.isLastChild : boolean; 
begin
  if FParent <> nil then
    if FParent.FChild <> nil then
      Exit(FParent.FChild.FNext = Self)
    else Exit(False)
  else Exit(False);
end;


procedure TNode.Detach;
begin
  if FParent <> nil then
    FParent.Remove( Self ) // this will call Detach again!
  else
  begin
    FPrev.FNext := FNext;
    FNext.FPrev := FPrev;
    FPrev := Self;
    FNext := Self;
    FParent := nil;
  end;
end;

procedure TNode.Remove( theChild : TNode );
begin
  if theChild.FParent <> Self then Exit(); // signal error?
  if theChild = FChild then
  begin
    if theChild.FNext <> theChild then FChild := theChild.FNext
                                  else FChild := nil;
  end;
  theChild.FParent := nil;
  theChild.Detach;
  Dec(FChildCount);
end;

procedure TNode.DestroyChildren;
begin
  while FChild <> nil do
  begin
    FChild.Free;
  end;
end;


procedure TNode.Receive(MSG : TMessage);
begin
  case MSG.ID of
    0 :;
    //MSG_NODE_Destroy : begin FParent.Remove(Self); Self.Done; exit; end;
  else
    Self.Warning('Unknown message recieved (@1, ID: @2)',[Msg.ClassName,Msg.ID]);
  end;
  MSG.Free;
end;

procedure TNode.Move(Destination : TNode);
begin
  if FParent <> nil     then Detach;
  if Destination <> nil then Destination.Add(Self);
end;

destructor TNode.Destroy;
begin
  Detach;
  if (UIDs <> nil) and (FUID <> 0) then UIDs.Remove(FUID);
  while FChild <> nil do
  begin
    FChild.Free;
  end;
  Log(LTRACE,'Destroyed.');
end;

procedure TNode.Log      (const aLogString       : Ansistring);
begin
  vdebug.Log('<'+classname+'/'+FID+'/'+IntToStr(FUID)+'> '+aLogString);
end;

procedure TNode.Log(Level: TLogLevel; const aLogString: Ansistring);
begin
  if Level > LogLevel then Exit;
  vdebug.Log('<'+classname+'/'+FID+'/'+IntToStr(FUID)+'> '+aLogString);
end;

function TNode.Compare ( aOther : TNode ) : Boolean;
begin
  if FID > aOther.FID then Exit( True );
  if UID > aOther.UID then Exit( False );
  Exit( False );
end;

function TNode.FindChild( Child: TNode; Recursive: Boolean ): TNode;
var Scan : TNode;
    Rec  : TNode;
begin
  Scan := FChild;
  if Scan <> nil then
  repeat
    if Scan = Child then Exit( Scan );
    Scan := Scan.Next;
  until Scan = FChild;
  if Recursive then
  begin
    Scan := FChild;
    if Scan <> nil then
    repeat
      Rec := Scan.FindChild( Child, Recursive );
      if Rec <> nil then Exit( Rec );
      Scan := Scan.Next;
    until Scan = FChild;
  end;
  Exit( nil );
end;

function TNode.FindChild( UID: TUID; Recursive: Boolean ): TNode;
var Scan : TNode;
    Rec  : TNode;
begin
  Scan := FChild;
  if Scan <> nil then
  repeat
    if Scan.UID = UID then Exit( Scan );
    Scan := Scan.Next;
  until Scan = FChild;
  if Recursive then
  begin
    Scan := FChild;
    if Scan <> nil then
    repeat
      Rec := Scan.FindChild( UID, Recursive );
      if Rec <> nil then Exit( Rec );
      Scan := Scan.Next;
    until Scan = FChild;
  end;
  Exit( nil );
end;

function TNode.FindChild( const ID: AnsiString; Recursive: Boolean ): TNode;
var Scan : TNode;
    Rec  : TNode;
begin
  Scan := FChild;
  if Scan <> nil then
  repeat
    if Scan.ID = ID then Exit( Scan );
    Scan := Scan.Next;
  until Scan = FChild;
  if Recursive then
  begin
    Scan := FChild;
    if Scan <> nil then
    repeat
      Rec := Scan.FindChild( ID, Recursive );
      if Rec <> nil then Exit( Rec );
      Scan := Scan.Next;
    until Scan = FChild;
  end;
  Exit( nil );
end;

function TNode.GetEnumerator : TNodeEnumerator;
begin
  GetEnumerator.Create(Self);
end;

function TNode.Reverse : TNodeReverseEnumerator;
begin
  Reverse.Create(Self);
end;

procedure TNode.CritError(const aCritErrorString : Ansistring);
begin
  vdebug.CritError('<'+classname+'/'+FID+'/'+IntToStr(FUID)+'> '+aCritErrorString);
end;

procedure TNode.Warning  (const aWarningString   : Ansistring);
begin
  vdebug.Warning('<'+classname+'/'+FID+'/'+IntToStr(FUID)+'> '+aWarningString);
end;

procedure TVObject.CritError( const aCritErrorString : Ansistring);
begin
  vdebug.CritError('<'+classname+'> ' + aCritErrorString);
end;

procedure TVObject.Warning  ( const aWarningString   : Ansistring);
begin
  vdebug.Warning('<'+classname+'> '+aWarningString);
end;

procedure TVObject.Log      (const aLogString       : Ansistring);
begin
  vdebug.Log('<'+classname+'> '+aLogString);
end;

procedure TVObject.Log(Level: TLogLevel; const aLogString: Ansistring);
begin
  if Level > LogLevel then Exit;
  vdebug.Log(Level,'<'+classname+'> '+aLogString);
end;

procedure TVObject.CritError(const aCritErrorString: Ansistring; const aParam: array of const);
begin
  CritError(VFormat(aCritErrorString,aParam));
end;

procedure TVObject.Warning(const aWarningString: Ansistring; const aParam: array of const);
begin
  Warning(VFormat(aWarningString,aParam));
end;

procedure TVObject.Log(const aLogString: Ansistring; const aParam: array of const);
begin
  Log(VFormat(aLogString,aParam));
end;

procedure TVObject.Log(Level: TLogLevel; const aLogString: Ansistring; const aParam: array of const);
begin
  if Level > LogLevel then Exit;
  Log(Level, VFormat(aLogString,aParam));
end;

function TVObject.hasParent : boolean;
begin
  Exit(False);
end;

function TVObject.hasChild : boolean;
begin
  Exit(False);
end;

function TVObject.isNode : boolean; 
begin
  Exit(False);
end;

{ TGNodeListEnumerator }

function TGNodeListEnumerator.GetCurrent : T;
begin
  Exit( T(FList[ FCurrent ]) );
end;

constructor TGNodeListEnumerator.Create ( List : TNodeList ) ;
begin
  FList    := List;
  FCurrent := 0;
end;

function TGNodeListEnumerator.MoveNext : Boolean;
begin
  repeat
    Inc( FCurrent );
    if FCurrent > FList.Size then Exit( False );
  until FList[ FCurrent ] <> nil;
end;

{ TGNodeListEnumerator }

function TGNodeListReverseEnumerator.GetCurrent : T;
begin
  Exit( T(FList[ FCurrent ]) );
end;

constructor TGNodeListReverseEnumerator.Create ( List : TNodeList ) ;
begin
  FList    := List;
  FCurrent := List.LastIndex+1;
end;

function TGNodeListReverseEnumerator.MoveNext : Boolean;
begin
  repeat
    Dec( FCurrent );
    if FCurrent = 0 then Exit( False );
  until FList[ FCurrent ] <> nil;
end;

function TGNodeListReverseEnumerator.GetEnumerator : TGNodeListReverseEnumerator;
begin
  Exit( Self );
end;

{ TNodeList }

constructor TNodeList.Create ( MaxSize : DWord ) ;
begin
  inherited Create;
  FSize    := 0;
  FMaxSize := MaxSize;
  SetLength( FItems, MaxSize );
  FillChar( FItems[0], MaxSize*SizeOf( TNode ), 0 );
end;

function TNodeList.Push ( aItem : TNode ) : Boolean;
var aIndex : DWord;
begin
  aIndex := 0;
  while FItems[ aIndex ] <> nil do
    if aIndex = FMaxSize-1
      then Exit( False )
      else Inc( aIndex );
  FItems[ aIndex ] := aItem;
  Inc( FSize );
  Exit( True );
end;

function TNodeList.GetItem ( aIndex : DWord ) : TNode;
begin
  if (aIndex = 0) or (aIndex > FMaxSize) then Exit( nil );
  Exit( FItems[ aIndex - 1 ] );
end;

procedure TNodeList.SetItem ( aIndex : DWord; aItem : TNode ) ;
begin
  if (aIndex = 0) or (aIndex > FMaxSize) then raise EException.Create('Bad index passed to SetItem!');
  Dec( aIndex );
  if FItems[ aIndex ] <> nil then Dec( FSize );
  if aItem <> nil            then Inc( FSize );
  FItems[ aIndex ] := aItem;
end;

function TNodeList.Find ( aItem : TNode ) : TNode;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize - 1 do
    if FItems[ iCount ] = aItem then
      Exit( aItem );
  Exit( nil );
end;

function TNodeList.FindByID ( const ID : AnsiString ) : TNode;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize - 1 do
    if ( FItems[ iCount ] <> nil ) and ( FItems[ iCount ].ID = ID ) then
      Exit( FItems[ iCount ] );
  Exit( nil );
end;

function TNodeList.FindByUID ( const UID : TUID ) : TNode;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize - 1 do
    if ( FItems[ iCount ] <> nil ) and ( FItems[ iCount ].UID = UID ) then
      Exit( FItems[ iCount ] );
  Exit( nil );
end;

function TNodeList.Has ( aItem : TNode ) : Boolean;
begin
  Exit( Find( aItem ) <> nil );
end;

function TNodeList.Remove ( aItem : TNode ) : Boolean;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize - 1 do
    if FItems[ iCount ] = aItem then
    begin
      FreeAndNil( FItems[ iCount ] );
      Dec( FSize );
      Exit( True );
    end;
  Exit( False );
end;

function TNodeList.Remove ( const ID : AnsiString ) : Boolean;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize - 1 do
    if ( FItems[ iCount ] <> nil ) and ( FItems[ iCount ].ID = ID ) then
    begin
      FreeAndNil( FItems[ iCount ] );
      Dec( FSize );
      Exit( True );
    end;
  Exit( False );
end;

function TNodeList.Remove ( const UID : TUID ) : Boolean;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize - 1 do
    if ( FItems[ iCount ] <> nil ) and ( FItems[ iCount ].UID = UID ) then
    begin
      FreeAndNil( FItems[ iCount ] );
      Dec( FSize );
      Exit( True );
    end;
  Exit( False );
end;

procedure TNodeList.Clear;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize-1 do
    FItems[ iCount ] := nil;
end;

procedure TNodeList.Sort;
var cn   : DWord;
    ci   : DWord;
  procedure Swap( var Item1, Item2 : TNode );
  var Temp : TNode;
  begin
    Temp  := Item1;
    Item1 := Item2;
    Item2 := Temp;
  end;
begin
  Pack;
  if FSize > 1 then
  for cn := 0 to FSize-2 do
    for ci := 0 to FSize-2-cn do
      if FItems[ci].Compare( FItems[ci+1] ) then
        Swap(FItems[ci],FItems[ci+1]);
end;

procedure TNodeList.Pack;
var iCount : DWord;
begin
  for iCount := 0 to FMaxSize-2 do
    if FItems[iCount] = nil then
    begin
      FItems[iCount]     := FItems[iCount + 1];
      FItems[iCount + 1] := nil;
    end;
end;

function TNodeList.LastIndex : DWord;
var iCount : DWord;
begin
  for iCount := FMaxSize-1 downto 0 do
    if FItems[iCount] <> nil then
      Exit( iCount + 1 );
  Exit( 0 );
end;

destructor TNodeList.Destroy;
begin
  SetLength( FItems, 0 );
  inherited Destroy;
end;

function TNodeList.GetEnumerator : TNodeListEnumerator;
begin
  GetEnumerator.Create( Self );
end;

function TNodeList.Reverse : TNodeListReverseEnumerator;
begin
  Reverse.Create( Self );
end;

{ TGNodeList }

procedure TGNodeList.SetItem ( aIndex : DWord ; const aItem : TNode ) ;
begin
  inherited SetItem( aIndex, aItem );
end;

function TGNodeList.Push ( aItem : T ) : Boolean;
begin
  Exit( inherited Push( aItem ) );
end;

function TGNodeList.GetItem ( aIndex : DWord ) : T;
begin
  Exit( T(inherited GetItem( aIndex )) );
end;

function TGNodeList.Find ( aItem : T ) : T;
begin
  Exit( T(inherited Find( aItem )) );
end;

function TGNodeList.FindByID ( const ID : AnsiString ) : T;
begin
  Exit( T(inherited FindByID( ID )) );
end;

function TGNodeList.FindByUID ( const UID : TUID ) : T;
begin
  Exit( T(inherited FindByUID( UID )) );
end;

function TGNodeList.GetEnumerator : TEnumeratorType;
begin
  GetEnumerator.Create( Self );
end;

function TGNodeList.Reverse : TReverseEnumeratorType;
begin
  Reverse.Create( Self );
end;


end.

// Modified      : $Date: 2008-01-14 22:16:41 +0100 (Mon, 14 Jan 2008) $
// Last revision : $Revision: 110 $
// Last author   : $Author: chaos-dev $
// Last commit   : $Log$
// Head URL      : $HeadURL: https://libvalkyrie.svn.sourceforge.net/svnroot/libvalkyrie/fp/src/vnode.pas $

