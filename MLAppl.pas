(*MLAppl:                                              MiniLib V.4, 2004
  ------
  Class MLApplication.
========================================================================*)
UNIT MLAppl;

INTERFACE
  
  USES
    OSBridge,
    MLObj, MLColl, MLVect,
    MLWin;
    
  TYPE

(*=== class MLApplication ===*)

    MLApplication   = ^MLApplicationObj;
    MLApplicationObj = OBJECT(MLObjectObj)

(*--- private data components ---*)

      applName:    STRING;   (*application name*)
      running:     BOOLEAN;  (*TRUE while running*)
      openWindows: MLVector; (*currently open windows*)

      CONSTRUCTOR Init(name: STRING);
      DESTRUCTOR Done; VIRTUAL;

(*--- new private methods, no overrides ---*)

      PROCEDURE AddWindow   (w: MLWindow); (*called from MLWindow.Open*)
      PROCEDURE RemoveWindow(w: MLWindow); (*called from MLwindow.Close*)
      PROCEDURE DispatchEvent(e: Event);

(*--- override to build application specific menus ---*)

      PROCEDURE BuildMenus; VIRTUAL; (*using calls to NewMenuCommand*)

(*--- rund and quit methods ---*)

      PROCEDURE Run; VIRTUAL;
      PROCEDURE Quit; VIRTUAL;

(*--- window handling methods ---*)

      PROCEDURE OpenNewWindow; VIRTUAL;
      FUNCTION  WindowOf(wp: WindowPeer): MLWindow; VIRTUAL;
      FUNCTION  TopWindow: MLWindow; VIRTUAL;
      FUNCTION  NewOpenWindowsIterator: MLIterator; VIRTUAL;
      PROCEDURE CloseAllOpenWindows; VIRTUAL;

(*--- event handling methods ---*)

      PROCEDURE OnIdle; VIRTUAL;
      PROCEDURE OnMousePressed (pos: Point); VIRTUAL;
      PROCEDURE OnMouseReleased(pos: Point); VIRTUAL;
      PROCEDURE OnMouseMove    (pos: Point); VIRTUAL;
      PROCEDURE OnKey(key: CHAR); VIRTUAL;
      PROCEDURE OnCommand(commandNr: INTEGER); VIRTUAL;

    END; (*OBJECT*)


  VAR

    MLApplicationInstance: MLApplication; (*the one and only appl. object*)

  (*file menu:*)
    newCommand, closeCommand, quitCommand,
  (*edit menu:*)
    undoCommand, cutCommand, copyCommand, pasteCommand, clearCommand,
  (*window menu:*)
    closeAllCommand,
  (*help menue:*)
    aboutCommand
    : INTEGER;


  FUNCTION NewMLApplication(name: STRING): MLApplication;

  PROCEDURE ShowMessageWindow(title, message: STRING);

  FUNCTION NewMenuCommand(menu, cmd: STRING; shortCut: CHAR): INTEGER;


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo;
    

  PROCEDURE BuildFileAndEditMenus;
    VAR
      dummy: INTEGER;
  BEGIN
  (*file menu:*)
    newCommand      := NewMenuCommand('File',   'New',       'N');
    closeCommand    := NewMenuCommand('File',   'Close',     'W');
    dummy           := NewMenuCommand('File',   '-',         ' ');
    quitCommand     := NewMenuCommand('File',   'Quit',      'Q');
  (*edit menu:*)
    undoCommand     := NewMenuCommand('Edit',   'Undo',      'Z');
    dummy           := NewMenuCommand('Edit',   '-',         ' ');
    cutCommand      := NewMenuCommand('Edit',   'Cut',       'X');
    copyCommand     := NewMenuCommand('Edit',   'Copy',      'C');
    pasteCommand    := NewMenuCommand('Edit',   'Paste',     'V');
    clearCommand    := NewMenuCommand('Edit',   'Clear',     ' ');
  END; (*BuildFileAndEditMenus*)
    
  PROCEDURE BuildWindowAndHelpMenus;
  BEGIN
  (*window menu: Cascade, Tile, and Arrang icons in OS_Bridge*)
    closeAllCommand := NewMenuCommand('Window', 'Close All', ' ');
  (*help menu:*)
    aboutCommand    := NewMenuCommand('Help',   'About ...', ' ');
  END; (*BuildWindowAndHelpMenus*)


  FUNCTION NewMLApplication(name: STRING): MLApplication;
    VAR
      a: MLApplication;
  BEGIN
    New(a, Init(name));
    NewMLApplication := a;
  END; (*NewApplication*)


  PROCEDURE ShowMessageWindow(title, message: STRING);
  BEGIN
    OSB_ShowMessageWindow(title, message);
  END; (*ShowMessageWindow*)

  FUNCTION NewMenuCommand(menu, cmd: STRING;
                          shortCut: CHAR): INTEGER;
  BEGIN
    NewMenuCommand := OSB_NewMenuCommand(menu, cmd, shortCut);
  END; (*NewMenuCommand*)


(*=== class MLApplication ===*)


  CONSTRUCTOR  MLApplicationObj.Init(name: STRING);
  BEGIN
    INHERITED Init;
    REGISTER('MLApplication', 'MLObject');
  (*check if singleton*)
    IF MLApplicationInstance = NIL THEN
      MLApplicationInstance := @SELF
    ELSE
      Error('invalid attempt to construct another MLApplication object');
  (*reset golbal variables defined and initialized in MetaInfo*)
    applKind      := guiApplication;
    showMsgWindow := OSB_ShowMessageWindow;
  (*finish object initialization*)
    applName      := name;
    running       := TRUE;
    openWindows   := NewMLVector;
  (*initialize MS Windows application*)
    OSB_InitApplication(applName);
  END; (*MLApplicationObj.Init*)


  DESTRUCTOR MLApplicationObj.Done;
  BEGIN
    MLApplicationInstance := NIL;
    Dispose(openWindows, Done);
    OSB_DestroyApplication;
    INHERITED Done
  END; (*MLApplicationObj.Done*)


  PROCEDURE MLApplicationObj.AddWindow(w: MLWindow);
  BEGIN
    openWindows^.Add(w)
  END; (*MLApplicationObj.AddWindow*)
    
  PROCEDURE MLApplicationObj.RemoveWindow(w: MLWindow);
  BEGIN
    openWindows^.Remove(w)
  END; (*MLApplication.RemoveWindow*)

  PROCEDURE MLApplicationObj.DispatchEvent(e: Event);
    VAR
      w: MLWindow;
  BEGIN
    CASE e.kind OF
      idleEvent: BEGIN
        OnIdle;
      END; (*idleEvent*)
      buttonDownEvent: BEGIN
        OnMousePressed(e.pos);
      END; (*buttonDownEvent*)
      buttonReleaseEvent: BEGIN
        OnMouseReleased(e.pos);
      END; (*buttonReleaseEvent*)
      mouseMoveEvent: BEGIN
        OnMouseMove(e.pos);
      END; (*mouseMoveEvent*)
      keyEvent: BEGIN
        OnKey(e.key)
      END; (*keyEvent*)
      commandEvent: BEGIN
        OnCommand(e.commandNr);
      END; (*commandEvent*)
      resizeEvent: BEGIN
        w := WindowOf(e.wp);
        IF w <> NIL THEN
          w^.OnResize;
      END; (*resizeEvent*)
      redrawEvent: BEGIN
        w := WindowOf(e.wp);
        IF w <>NIL THEN
          w^.OnRedraw;
      END; (*redrawEvent*)
      quitEvent: BEGIN
        Quit;
      END; (*quitEvent*)
      ELSE BEGIN
        (*nothing to do*)
      END; (*ELSE*)
    END; (*CASE*)
  END;(*MLApplicationObj.DispatchEvent*)


(*--- override to build application specific menus ---*)

  PROCEDURE MLApplicationObj.BuildMenus;
  BEGIN
    (*implementation in derived classes calls NewMenuCommand*)
  END; (*MLApplicationObj.BuildMenus*)


(*--- run and quit mehtods ---*)

  PROCEDURE MLApplicationObj.Run;
    VAR
      e: Event;
  BEGIN
    BuildFileAndEditMenus;
    BuildMenus;
    BuildWindowAndHelpMenus;
    OSB_InstallMenuBar;
    OpenNewWindow;
    OSB_GetNextEvent(e);
    WHILE running DO BEGIN
      DispatchEvent(e);
      OSB_GetNextEvent(e);
    END; (*WHILE*)
    CloseAllOpenWindows
  END; (*MLApplicationObj.Run*)
    
  PROCEDURE MLApplicationObj.Quit;
  BEGIN
    running := FALSE;
    OSB_RemoveMenuBar;
  END; (*MLApplicationObj.Quit*)


(*--- window handling methods ---*)

  PROCEDURE MLApplicationObj.OpenNewWindow;
  BEGIN
    NewMLWindow('MiniLib Window')^.Open;
  END; (*MLApplicationObj.OpenNewWindow*)

  FUNCTION MLApplicationObj.WindowOf(wp: WindowPeer): MLWindow;
    VAR
      it:    MLIterator;
      w:     MLWindow;
      found: BOOLEAN;
  BEGIN
    found := FALSE;
    it    := openWindows^.NewIterator;
    w     := MLWindow(it^.Next);
    WHILE (NOT found) AND (w <> NIL) DO BEGIN
      IF OSB_EqualWindowPeers(w^.wp, wp) THEN
        found := TRUE
      ELSE
        w := MLWindow(it^.Next);
    END; (*WHILE*)
    Dispose(it, Done);
    WindowOf := w;
  END; (*MLApplicationObj.WindowOf*)
    
  FUNCTION MLApplicationObj.TopWindow: MLWindow;
  BEGIN
    TopWindow := WindowOf(OSB_ActiveWindowPeer)
  END; (*MLApplicationObj.TopWindow*)

  FUNCTION MLApplicationObj.NewOpenWindowsIterator: MLIterator;
  BEGIN
    NewOpenWindowsIterator := openWindows^.NewIterator;
  END; (*MLApplicationObj.NewOpenWindowsIterator*)

  PROCEDURE MLApplicationObj.CloseAllOpenWindows;
    VAR
      w: MLWindow;
      i: INTEGER;
  BEGIN
    i := openWindows^.Size;
    WHILE i >= 1 DO BEGIN
      w := MLWindow(openWindows^.GetAt(i));
      Dispose(w, Done); (*removes w from openWindows, closes and deletes it*)
      i := i - 1;
    END; (*WHILE*)
  END; (*MLApplicationObj.CloseAllOpenWindows*)
    

(*--- event handling methods ---*)

  PROCEDURE MLApplicationObj.OnIdle;
    VAR
      it: MLIterator;
      w:  MLWindow;
  BEGIN
    it := openWindows^.NewIterator;
    w  := MLWindow(it^.Next);
    WHILE w <> NIL DO BEGIN
      w^.OnIdle;
      w := MLWindow(it^.Next);
    END; (*WHILE*)
    Dispose(it, Done);
  END; (*MLApplicationObj.OnIdle*)

  PROCEDURE MLApplicationObj.OnMousePressed(pos: Point);
    VAR
      w: MLWindow;
  BEGIN
    w := TopWindow;
    IF w <> NIL THEN
      w^.OnMousePressed(pos);
  END; (*MLApplicationObj.OnMousePressed*)

  PROCEDURE MLApplicationObj.OnMouseReleased(pos: Point);
    VAR
      w: MLWindow;
  BEGIN
    w := TopWindow;
    IF w <> NIL THEN
      w^.OnMouseReleased(pos);
  END; (*MLApplicationObj.OnMouseReleased*)

  PROCEDURE MLApplicationObj.OnMouseMove(pos: Point);
    VAR
      w: MLWindow;
  BEGIN
    w := TopWindow;
    IF w <> NIL THEN
      w^.OnMouseMove(pos);
  END; (*MLApplicationObj.OnMouseMove*)
    
  PROCEDURE MLApplicationObj.OnKey(key: CHAR);
    VAR
      w: MLWindow;
  BEGIN
    w := TopWindow;
    IF w <> NIL THEN
      w^.OnKey(key);
  END; (*MLApplicationObj.OnKey*)

  PROCEDURE MLApplicationObj.OnCommand(commandNr: INTEGER);
    VAR
      w: MLWindow;
  BEGIN
    IF commandNr = quitCommand THEN
      Quit
    ELSE IF commandNr = closeAllCommand THEN
      CloseAllOpenWindows
    ELSE IF commandNr = aboutCommand THEN
      OSB_ShowMessageWindow('About Window', applName +
        CHR(10) + CHR(13) + 'based on the famous application framework MiniLib' +
        CHR(10) + CHR(13) + '-- Version 4.0 (in Pascal), 2004')
    ELSE IF commandNr = newCommand THEN
      OpenNewWindow
    ELSE BEGIN (*delegate to top window*)
      w := TopWindow;
      IF w <> NIL THEN
        w^.OnCommand(commandNr)
    END; (*ELSE*)
  END; (*MLApplicationObj.OnCommand*)


BEGIN (*MLAppl*)
  MLApplicationInstance := NIL;
END. (*MLAppl*)






 

