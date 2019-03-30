// @abstract(Event handling unit for GenRogue Core)
// @author(Kornel Kisielewicz <epyon@chaosforge.org>)
// @created(May 7, 2004)
//
// Implements all event handling classes, that is @link(TEvent)
// and @link(TEventController). Implements global variables
// @link(Events) and @link(EventTimer).
{$INCLUDE valkyrie.inc}
{$H-}
unit vevents;
interface
uses vnode, vmsg,vutil,vds, vsystem;

// Global variable holding the current time. Queried to
// get knowledge wether an event should be executed.
var   EventTimer : QWord;

// Main event class, stored by @link(TEventController).
type TEvent    = class(TVObject)
  // The time the event will be executed.
  Sequence : QWord;
  // @link(TUID) of the target.
  Target   : TUID;
  // Carried @link(TMessage).
  MSG      : TMessage;
  // Constructor that takes all necessary data.
  constructor Create(Seq : QWord; nTarget : TUID; nMSG : TMessage);
  // Sends the message to Target. After this call MSG is no more valid.
  procedure Resolve;
  // Frees all neccessary data.
  destructor Destroy; override;
end;
                
                
type TEventHeapQueue = specialize THeapQueue<TEvent>;

// A specialization to for THeapQueue tailored to handling events.
type TEventQueue = class(TEventHeapQueue)
   // Creates a HeapQueue and registers comparision.
   constructor Create;
   // Marks all events pointing to nUID as invalid.
   procedure RemoveUID(nUID : TUID);
end;

// @link(TEvent) holder and manager. Holds all events in a priority queue.
// Used as a singleton @link(Events).
type TEventController = class(TSystem)
  // Standard constructor.
  constructor Create; override;
  // Standard destructor, frees all unexecuted events.
  destructor Destroy; override;
  // Adding an event to the queue. Timeleft calculates
  // execution time based on @link(EventTimer). MSG is
  // referenced, not copied.
  procedure AddEvent(TimeLeft : QWord; nTarget : TUID;
                     MSG : TMessage);
  // Drops next event from the queue if it's time has
  // come. If not, returns @nil.
  function DropTimeEvent : TEvent;
  // Removes all events with the given @link(TUID)
  // from the priority queue.
  procedure RemoveUID(nUID : TUID);
  private
  // First event in queue.
  Queue : TEventQueue;
  // Drops next event from the queue. No time checking.
  function DropNextEvent : TEvent;
end;

// Singleton @link(TEventController) class. Needs to be initialized.
const Events   : TEventController = nil;

implementation

uses SysUtils, vuid;

function EventCompare( const Item1, Item2: TEvent ): Integer;
begin
       if Item1.Sequence < Item2.Sequence then Exit(1)
  else if Item1.Sequence > Item2.Sequence then Exit(-1)
  else Exit(0);
end;

constructor TEvent.Create(Seq : QWord; nTarget : TUID; nMSG : TMessage);
begin
  MSG := nMSG;
  Sequence := Seq;
  Target := nTarget;
end;

procedure TEvent.Resolve;
begin
   UIDs.Get(Target).Receive(MSG); // Tu jest niszczone MSG !!!!
end;

destructor TEvent.Destroy;
begin
  Msg.Destroy;
end;

constructor TEventQueue.Create;
begin
  inherited Create(128);
  SetCompareFunc(@EventCompare);
end;

// Marks all events pointing to nUID as invalid.
procedure TEventQueue.RemoveUID(nUID : TUID);
var Count : DWord;
begin
  for Count := 0 to FEntries-1 do
    if (FData[Count] <> nil) and (TEvent(FData[Count]).Target = nUID) then
      TEvent(FData[Count]).Target := 0;
end;


constructor TEventController.Create;
begin
  inherited Create;
  Queue := TEventQueue.Create;
end;

procedure TEventController.RemoveUID(nUID : TUID);
begin
  Queue.RemoveUID(nUID);
end;

function TEventController.DropNextEvent : TEvent;
begin
  if not Queue.isEmpty then Exit(Queue.Pop) else Exit(nil);
end;


function TEventController.DropTimeEvent : TEvent;
begin
  Result := nil;
  if not Queue.isEmpty then
    if Queue.Peek.Sequence <= EventTimer then
      Result := Queue.Pop;
end;


procedure TEventController.AddEvent(TimeLeft : QWord; nTarget : TUID; Msg : TMessage);
begin
  Queue.Add(TEvent.Create(EventTimer + TimeLeft,nTarget,Msg));
end;

destructor TEventController.Destroy;
var Scan : TEvent;
begin
  FreeAndNil(Queue);
  inherited Destroy;
end;

end.

//* Created 22.08.2003
