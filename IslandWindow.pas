{
  IslandWindow
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @abstract(the window that displays the island as it is)
  @created(2017-07-10)
  this is the ui element that will auto-display
  @lastmod(2017-07-10)
}
UNIT IslandWindow;
INTERFACE
USES
  MLWin, NameGen, MLAppl, Environment, OSBridge;
  TYPE
  IslandWindowPtr = ^TIslandWindow;
  TIslandWindow = OBJECT(MLWindowObj)
    PRIVATE
      _env : IslandEnvironment;

    PUBLIC
      CONSTRUCTOR Init(env : IslandEnvironment);
      DESTRUCTOR Done; VIRTUAL;
      PROCEDURE Open; VIRTUAL;
      PROCEDURE Redraw; VIRTUAL;
      PROCEDURE OnIdle; VIRTUAL;
      PROCEDURE OnCommand(commandNr: INTEGER); VIRTUAL;
      PROCEDURE OnMousePressed (pos: Point); VIRTUAL;
      PROCEDURE OnMouseMove(pos : Point); VIRTUAL;
  END;
  FUNCTION NewIslandWindow : IslandWindowPtr;

IMPLEMENTATION

FUNCTION NewIslandWindow : IslandWindowPtr;
VAR
  s : IslandWindowPtr;
  e : IslandEnvironment;
  n : NameGenerator;
BEGIN
  n := NewNameGenerator;
  New(e,Init('Pascal Insel: '+ n^.LocationName));
  New(s,Init(e));
  NewIslandWindow := s;
  Dispose(n,Done);
END;
CONSTRUCTOR TIslandWindow.Init(env: IslandEnvironment);
BEGIN
  INHERITED Init(env^.GetName);
  Register('IslandWindow', 'MLWindow');
  _env := env;
END;

DESTRUCTOR TIslandWindow.Done;
BEGIN
  Dispose(_env,Done);
  INHERITED Done;
END;

PROCEDURE TIslandWindow.Open;
BEGIN
  INHERITED Open;
  _env^.RendnerMap(self.GetWindowPeer, self.Width, self.Height);
END;

PROCEDURE TIslandWindow.Redraw;
BEGIN
  _env^.RendnerMap(self.GetWindowPeer, self.Width, self.Height);
END;

PROCEDURE TIslandWindow.OnIdle;
BEGIN
END;

PROCEDURE TIslandWindow.OnCommand(commandNr: INTEGER);
BEGIN
  INHERITED OnCommand(commandNr);
END;

PROCEDURE TIslandWindow.OnMousePressed (pos: Point);
BEGIN
  _env^.ClickedOn(pos.x,pos.y);
  Update;
END;

PROCEDURE TIslandWindow.OnMouseMove(pos : Point);
BEGIN
  _env^.Hovering(pos.x,pos.y);
END;

END.
