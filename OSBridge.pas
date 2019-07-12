(* OSBridge:                                           MiniLib V.4, 2004
   --------
   Bridge to plattform GUI operating system (MS Windows 32-bit).
========================================================================*)
UNIT OSBridge;

INTERFACE

  USES
  {$IFDEF FPC}
    Windows;
  {$ELSE}
    WinTypes;
  {$ENDIF}

  TYPE

(*--- possible kinds of events ---*)

    EventKind = (idleEvent,
                 buttonDownEvent, buttonReleaseEvent, mouseMoveEvent,
                 keyEvent,
                 commandEvent,
                 redrawEvent, resizeEvent,
                 quitEvent);

(*--- point within a window in pixel coordinates ---*)

    Point = RECORD
      x, y: INTEGER;
    END; (*RECORD*)

(*--- plattform dependent window decritpion ---*)

    WindowPeer = ^WindowPeerRec; (*treat as opaque type*)
    WindowPeerRec = RECORD
      wnd: HWnd; (*handle to window*)
      dc:  HDC;  (*handle to display context*)
    END; (*RECORD*)

(*--- event data structure ---*)

    Event = RECORD
      kind:      EventKind;
      wp:        WindowPeer;
      pos:       Point;   (*for button(Dwon|Release)Event, and mouseMoveEvent*)
      commandNr: INTEGER; (*for commandEvent*)
      key:       CHAR;    (*for charEvent*)
      exitCode:  INTEGER; (*for quitEvent*)
    END; (*RECORD)


(*--- 1. application utility utilities ---*)

  PROCEDURE OSB_InitApplication(applName: STRING);
  (*initializes window system and creates GUI application*)

  PROCEDURE OSB_DestroyApplication;
  (*terminates application*)
  
  PROCEDURE OSB_GetNextEvent(VAR e: Event);
  (*returns the next event from event queue*)


  (*--- 2. menu management utilities ---*)

  FUNCTION OSB_NewMenuCommand(menu, cmd: STRING; shortCut: CHAR): INTEGER;
  (*creates a new menu command menu and returns its command number*)

  PROCEDURE OSB_InstallMenuBar;
  (*attatches menu bar to application window*)

  PROCEDURE OSB_RemoveMenuBar;
  (*removes menue bar from application window*)


(*--- 3. window management utilities ---*)

  PROCEDURE OSB_GetMouseState(wp: WindowPeer;
                              VAR buttonPressed: BOOLEAN; VAR pos: Point);
  (*returns if mouse button is pressed and mouse position*)

  PROCEDURE OSB_ShowMessageWindow(title, message: STRING);
  (*opens modal dialog window with message and OK button*)

  FUNCTION OSB_EqualWindowPeers(wp1, wp2: WindowPeer): BOOLEAN;
  (*compares two window peers and returns if they are equal*)

  PROCEDURE OSB_CreateNewWindow(title: STRING; VAR wp: WindowPeer);
  (*creates and opens new window*)

  PROCEDURE OSB_DestroyOldWindow(VAR wp: WindowPeer);
  (*closes and destroys old window*)

  FUNCTION OSB_ActiveWindowPeer: WindowPeer;
  (*returns active windows peer or NIL*)

  FUNCTION OSB_IsVisible(wp: WindowPeer): BOOLEAN;
  (*returns if window is visible, iconized windows are invisible*)

  PROCEDURE OSB_EraseContent(wp: WindowPeer);
  (*erases content of window*)

  PROCEDURE OSB_GetContentRect(wp: WindowPeer;
                               VAR topLeft: Point; VAR w, h: INTEGER);
  (*calculates content rectangle of window*)

  PROCEDURE OSB_InvalRect(wp: WindowPeer; topLeft: Point; w, h: INTEGER);
  (*invalidates content of rectangle*)


(*--- 4. drawing utilities ---*)

  PROCEDURE OSB_DrawDot(wp: WindowPeer;
                        pos: Point);
  (*draws dot at position*)

  PROCEDURE OSB_DrawLine(wp: WindowPeer;
                         startPos, endPos: Point; t: INTEGER);
  (*draws line from startPos to endPos with thickness*)

  PROCEDURE OSB_DrawRectangle(wp: WindowPeer;
                              topLeft: Point; w, h, t: INTEGER; fill: BOOLEAN);
  (*draws (filled) rectangle from topLeft with width, height, and thickness*)

  PROCEDURE OSB_DrawOval(wp: WindowPeer;
                         topLeft: Point; w, h, t: INTEGER; fill: BOOLEAN);
  (*draws (filled) oval from topLeft with width, heigth, and thickness*)

  PROCEDURE OSB_DrawString(wp: WindowPeer;
                           pos: Point; str: STRING; size: INTEGER);
  (*draws string with fontsize at position*)


(*======================================================================*)
IMPLEMENTATION (*for MS Windows 32-bit *)

  USES
  {$IFNDEF FPC}
    WinAPI, Win31, WinProcs,
  {$ENDIF}
    Strings,
    MetaInfo, MLWin, MLAppl;

  CONST
    firstMenuCmd   = 100;
    maxMenus       =  20;
    maxMenuNameLen =  31;
    firstChildId   = 300; (*id of first child window of appl. window*)

  TYPE
    DrawColor = (black, white);
    DrawMode  = (addMode, invertMode);
    MenuDescr = RECORD
      nr:         INTEGER;
      chars:      SET OF CHAR;
      titles:     ARRAY [0 .. maxMenus] OF STRING[maxMenuNameLen];
      shortCuts:  ARRAY [0 .. maxMenus] OF CHAR;
      cmdNrs:     ARRAY [0 .. maxMenus] OF INTEGER;
    END; (*RECORD*)


(*--- module globals ---*)

  VAR
    menuBar: HMenu;
    lastMenuCmd: INTEGER;
    menuBarItems: MenuDescr;
    menuItems: ARRAY [0 .. maxMenus] OF MenuDescr;
    cascadeCommand, tileCommand, arrangeIconCommand: INTEGER;
    gButtonPressed, windowMenuFirst: BOOLEAN;
    appFrameWnd, appClientWnd: HWnd;


(*--- assert correct operation result ---*)

  PROCEDURE AssertOperation(opSuccess: Bool; operation: STRING);
  BEGIN
    IF NOT opSuccess THEN
      Error('Operation ' + operation + ' failed');
  END; (*AssertOperation*)


(*=== local window management utilities ===*)

  FUNCTION FrameWndProc
  {$IFDEF FPC}
    (wnd: HWnd; msg: UINT; wParam: WPARAM; lParam: LPARAM):  LRESULT; StdCall; EXPORT;
  {$ELSE}
    (wnd: HWnd; msg: WORD; wParam: WORD;   lParam: LONGINT): LONGINT; EXPORT;
  {$ENDIF}
  BEGIN
    CASE msg OF
      wm_close: BEGIN
        PostQuitMessage(0);
        FrameWndProc := 0;
        Exit;
      END (*wm_close*)
      ELSE
       (*nothing to do*)
    END; (*CASE*)
    FrameWndProc := DefFrameProc(wnd, appClientWnd, msg, wParam, lParam);
  END; (*FrameWndProc*)
    
  FUNCTION ChildWndProc
  {$IFDEF FPC}
    (wnd: HWnd; msg: UINT; wParam: WPARAM; lParam: LPARAM):  LRESULT; StdCall; EXPORT;
  {$ELSE}
    (wnd: HWnd; msg: WORD; wParam: WORD;   lParam: LONGINT): LONGINT; EXPORT;
  {$ENDIF}
    VAR
      w:  MLWindow;
      wp: WindowPeerRec;
  BEGIN
    wp.wnd := wnd;
    CASE msg OF
      wm_paint: BEGIN
        IF MLApplicationInstance <> NIL THEN BEGIN
          w := MLApplicationInstance^.WindowOf(@wp);
          IF w <> NIL THEN BEGIN
            w^.Update;
            ValidateRect(wp.wnd, NIL);
            ChildWndProc := 0;
            Exit;
          END; (*IF*)
        END; (*IF*)
      END; (*wm_paint*)
      wm_size: BEGIN
        IF MLApplicationInstance <> NIL THEN BEGIN
          w := MLApplicationInstance^.WindowOf(@wp);
          IF w <> NIL THEN
            w^.OnResize;
        END; (*IF*)
      END; (*wm_size*)
      wm_close: BEGIN
        IF MLApplicationInstance <> NIL THEN BEGIN
          w := MLApplicationInstance^.WindowOf(@wp);
          IF w <> NIL THEN
            Dispose(w, Done);
        END; (*IF*)
      END; (*wm_close*)
      ELSE
        (*nothing to do*)
    END; (*CASE*)
    ChildWndProc := DefMDIChildProc(wnd, msg, wParam, lParam);
  END; (*ChildWndProc*)

  PROCEDURE RegisterFrameWindowKind;
    VAR
      wndClass: TWndClass;
  BEGIN
    IF hPrevInst <> 0 THEN
      Exit;
    wndClass.style         := cs_ownDC OR cs_hRedraw OR cs_vRedraw;
  {$IFDEF FPC}
    wndClass.lpfnWndProc   := WndProc(@FrameWndProc);
  {$ELSE}
    wndClass.lpfnWndProc   := @FrameWndProc;
  {$ENDIF}
    wndClass.cbClsExtra    := 0;
    wndClass.cbWndExtra    := 0;
    wndClass.hInstance     := hInstance;
    wndClass.hIcon         := LoadIcon(0, idi_application);
    wndClass.hCursor       := LoadCursor(0, idc_arrow);
    wndClass.hbrBackground := color_appWorkSpace;
    wndClass.lpszMenuName  := NIL;
    wndClass.lpszClassName := 'FrameWndKind';
    AssertOperation(Ord(RegisterClass(wndClass)) <> 0, 'RegisterClass');
  END; (*RegisterFrameWindowKind*)
    
  PROCEDURE RegisterChildWindowKind;
    VAR
      wndClass: TWndClass;
  BEGIN
    IF hPrevInst <> 0 THEN
      Exit;
    wndClass.style         := cs_ownDC OR cs_hRedraw OR cs_vRedraw;
  {$IFDEF FPC}
    wndClass.lpfnWndProc   := WndProc(@ChildWndProc);
  {$ELSE}
    wndClass.lpfnWndProc   := @ChildWndProc;
  {$ENDIF}
    wndClass.cbClsExtra    := 0;
    wndClass.cbWndExtra    := 0;
    wndClass.hInstance     := hInstance;
    wndClass.hIcon         := LoadIcon(0, idi_application);
    wndClass.hCursor       := LoadCursor(0, idc_arrow);
    wndClass.hbrBackground := GetStockObject(white_brush);
    wndClass.lpszMenuName  := NIL;
    wndClass.lpszClassName := 'ChildWndKind';
    AssertOperation(Ord(RegisterClass(wndClass)) <> 0, 'RegisterClass');
  END; (*RegisterChildWindowKind*)
    
  FUNCTION CreateFrameWindow(title: PChar): HWnd;
    VAR
      wnd: HWnd;
  BEGIN
    wnd := CreateWindow('FrameWndKind', title,
                   ws_overLappedWindow OR ws_clipChildren,
                   cw_useDefault, cw_useDefault, cw_useDefault, cw_useDefault,
                   0, 0, hInstance, NIL);
    CreateFrameWindow := wnd;
  END; (*CreateFrameWindow*)
    
  FUNCTION CreateClientWindow(frameWnd: HWnd): Hwnd;
    VAR
      wnd: HWnd;
      clientCreate: TClientCreateStruct;
  BEGIN
    clientCreate.hWindowMenu  := 0;
    clientCreate.idFirstChild := firstChildId;
    wnd := CreateWindow('MDICLIENT', NIL,
                        ws_child OR ws_clipChildren OR ws_visible,
                        0, 0, 0, 0,
                        frameWnd, 1, hInstance, @clientCreate);
    ShowWindow(frameWnd, sw_showNormal);
    UpdateWindow(frameWnd);
    CreateClientWindow := wnd;
   END; (*CreateClientWindow*)

  FUNCTION CreateChildWindow(title: PChar; clientWnd: HWnd): HWnd;
    VAR
      wnd: HWnd;
      mdiCreate: TMdiCreateStruct;
  BEGIN
    mdiCreate.szClass := 'ChildWndKind';
    mdiCreate.szTitle := title;
    mdiCreate.hOwner  := hInstance;
    mdiCreate.x       := cw_useDefault;
    mdiCreate.y       := cw_useDefault;
    mdiCreate.cx      := cw_useDefault;
    mdiCreate.cy      := cw_useDefault;
    mdiCreate.style   := 0;
    mdiCreate.lParam  := 0;
    wnd := HWnd(SendMessage(clientWnd, wm_mdiCreate, 0, LONGINT(@mdiCreate)));
    CreateChildWindow := wnd;
  END; (*CreateChildWindow*)


(*=== 1. application utilities ===*)

  PROCEDURE OSB_InitApplication(applName: STRING);
    VAR
      an: ARRAY [0..255] OF CHAR;
  BEGIN
    StrPCopy(an, applName);
    RegisterFrameWindowKind;
    RegisterChildWindowKind;
    appFrameWnd     := CreateFrameWindow(an);
    appClientWnd    := CreateClientWindow(appFrameWnd);
    lastMenuCmd     := firstMenuCmd;
    windowMenuFirst := TRUE;
    gButtonPressed  := FALSE;
    SetTimer(0, 0, 1, NIL); (*to trigger idle events*)
  END; (*OSB_InitApplication*)
    
  PROCEDURE OSB_DestroyApplication;
  BEGIN
    CloseWindow(appFrameWnd);
    AssertOperation(DestroyWindow(appFrameWnd), 'DestroyWindow');
  END; (*OSB_DestroyApplication*)

  FUNCTION ShortCutCmdNr(vKeyCode: WORD): INTEGER;
    VAR
      i, j: INTEGER;
      ch: CHAR;
  BEGIN
    ShortCutCmdNr := 0;
    IF (vKeyCode < 1) OR (vKeyCode > 26) THEN
      Exit;
    ch := Chr(vKeyCode + Ord('A') - 1);
    FOR i := 0 TO menuBarItems.nr - 1 DO BEGIN
      FOR j := 0 TO menuItems[i].nr - 1 DO BEGIN
        IF menuItems[i].shortCuts[j] = ch THEN BEGIN
          ShortCutCmdNr := menuItems[i].cmdNrs[j];
          Exit;
        END; (*IF*)
      END; (*FOR*)
    END; (*FOR*)
  END; (*ShortCutCmdNr*)

  PROCEDURE OSB_GetNextEvent(VAR e: Event);
    VAR
      msg:    TMsg;
      w:      MLWindow;
      wp:     WindowPeerRec;
      cmdNr:  INTEGER;
      found:  BOOLEAN;
  BEGIN
    found := FALSE;
    msg.hwnd := 0;
    WHILE NOT found DO BEGIN
      GetMessage(msg, 0, 0, 0);
      IF msg.message = wm_timer THEN BEGIN
        IF NOT InSendMessage AND
           NOT PeekMessage(msg, 0, 0, 0, pm_noRemove) THEN BEGIN
          (*no other messages pending*)
          e.kind := idleEvent;
          found  := TRUE;
        END (*IF*)
      END (*THEN*)
      ELSE BEGIN
        TranslateMessage(msg);
        CASE msg.message OF
          wm_lButtonDown: BEGIN
            e.kind         := buttonDownEvent;
            e.pos.x        := LoWord(msg.lParam);
            e.pos.y        := HiWord(msg.lParam);
            gButtonPressed := TRUE;
            found          := TRUE;
          END; (*wm_lButtonDown*)
          wm_lButtonUp: BEGIN
            e.kind         := buttonReleaseEvent;
            e.pos.x        := LoWord(msg.lParam);
            e.pos.y        := HiWord(msg.lParam);
            gButtonPressed := FALSE;
            found          := TRUE;
          END; (*wm_lButtonUp*)
          wm_mouseMove: BEGIN
            e.kind         := mouseMoveEvent;
            e.pos.x        := LoWord(msg.lParam);
            e.pos.y        := HiWord(msg.lParam);
            found          := TRUE;
          END; (*wm_lButtonUp*)
          wm_char: BEGIN
            cmdNr := ShortCutCmdNr(msg.wParam);
            IF cmdNr = 0 THEN BEGIN
              e.kind       := keyEvent;
              e.key        := CHAR(msg.wParam);
            END (*THEN*)
            ELSE BEGIN
              e.kind       := commandEvent;
              e.commandNr  := cmdNr;
            END; (*ELSE*)
            found := TRUE;
          END; (*wm_char*)
          wm_quit: BEGIN
            e.kind         := quitEvent;
            e.exitCode     := msg.wParam;
            found          := TRUE;
          END; (*wm_quit*)
          wm_command: BEGIN
            IF msg.wParam >= firstChildId THEN (*activate child command*)
              DispatchMessage(msg)
            ELSE IF msg.wParam = cascadeCommand THEN
              SendMessage(appClientWnd, wm_mdiCascade, 0, 0)
            ELSE IF (msg.wParam = tileCommand) THEN
              SendMessage(appClientWnd, wm_mdiTile, 0, 0)
            ELSE IF (msg.wParam = arrangeIconCommand) THEN
              SendMessage(appClientWnd, wm_mdiIconArrange, 0, 0)
            ELSE BEGIN
              e.kind       := commandEvent;
              e.commandNr  := msg.wParam;
              found        := TRUE;
            END; (*ELSE*)
          END; (*wm_command*)
          ELSE
            DispatchMessage(msg);
          END; (*CASE*)
        END; (*ELSE*)
    END; (*WHILE*)
    wp.wnd := msg.hwnd;
    w := MLApplicationInstance^.WindowOf(@wp);
    IF (w <> NIL) THEN
      e.wp := w^.GetWindowPeer
    ELSE
      e.wp := NIL;
  END; (*OSB_GetNextEvent*)


(*=== 2. menue management utilities ===*)

  FUNCTION OSB_NewMenuCommand(menu, cmd: STRING; shortCut: CHAR): INTEGER;
    VAR
      menuBarPos, subMenuPos: INTEGER;
      subMenu: HMenu;
      str:     ARRAY [0 .. 255] OF CHAR;
        
    FUNCTION InsertMenuTitle(menu: HMenu; VAR menuDescr: MenuDescr;
                             title: STRING; shortCut: CHAR): INTEGER;
    (*inserts title in menu if it's not yet there and
      returns position of title in menu*)
      VAR
        i, j: INTEGER;
        t: ARRAY [0 .. 255] OF CHAR;
    BEGIN
      IF title <> '-' THEN BEGIN
        i := 0;
        WHILE (i < menuDescr.nr) AND (menuDescr.titles[i] <> title) DO BEGIN
          i := i + 1;
        END; (*WHILE*)
      END (*THEN*)
      ELSE
        i := menuDescr.nr; (*new menu*)
      IF i >= menuDescr.nr THEN BEGIN
        menuDescr.titles[menuDescr.nr] := title;
        IF title = '-' THEN (*insert separator*)
          AssertOperation(AppendMenu(menu, mf_separator, 0, NIL),
                          'AppendMenu')
        ELSE BEGIN (*insert menu entry*)
        (*find alt character*)
          j := 1;
          WHILE (j <= Length(title)) AND
                (UpCase(title[j]) IN menuDescr.chars) DO BEGIN
            j := j + 1;
          END; (*WHILE*)
          IF j <= Length(title) THEN BEGIN
            Include(menuDescr.chars, UpCase(title[j]));
            Insert('&', title, j);
          END; (*IF*)
          lastMenuCmd := lastMenuCmd + 1;
        (*insert shortcut description in menu title*)
          menuDescr.cmdNrs[i] := lastMenuCmd;
          shortCut := UpCase(shortCut);
          IF (shortCut >= 'A') AND (shortCut <= 'Z') THEN BEGIN
            title:= Concat(title, Chr(9), 'Ctrl-', shortCut);
            menuDescr.shortCuts[i] := shortCut;
          END (*THEN*)
          ELSE
            menuDescr.shortCuts[i] := ' ';
          StrPCopy(t, title);
          AssertOperation(AppendMenu(menu, mf_enabled, lastMenuCmd, t),
                          'AppendMenu');
        END; (*ELSE*)
        menuDescr.nr := menuDescr.nr + 1;
        IF menuDescr.nr > maxMenus THEN
          Error('too many menus');
      END; (*IF*)
      InsertMenuTitle := i;
    END; (*InsertMenuTitle*)
      
  BEGIN (*OSB_NewMenuCommand*)
    IF appFrameWnd = 0 THEN
      Error('menus allowed in an application only');
    IF windowMenuFirst AND (menu = 'Window') THEN BEGIN
      windowMenuFirst    := FALSE;
      cascadeCommand     := OSB_NewMenuCommand('Window', 'Cascade',       ' ');
      tileCommand        := OSB_NewMenuCommand('Window', 'Tile',          ' ');
      arrangeIconCommand := OSB_NewMenuCommand('Window', 'Arrange Icons', ' ');
    END; (*IF*)
    IF lastMenuCmd = firstMenuCmd THEN BEGIN (*create menu bar*)
      menuBar            := CreateMenu;
      menuBarItems.nr    := 0;
      menuBarItems.chars := [];
    END; (*IF*)
    menuBarPos := InsertMenuTitle(menuBar, menuBarItems, menu, ' ');
    subMenu    := GetSubMenu(menuBar, menuBarPos);
    IF subMenu  = 0 THEN BEGIN
      subMenu  := CreatePopUpMenu;
      GetMenuString(menuBar, menuBarPos, str, 256, mf_byPosition);
      ModifyMenu(menuBar, menuBarPos, mf_byPosition OR mf_popUp, subMenu, str);
      menuItems[menuBarPos].nr    :=  0;
      menuItems[menuBarPos].chars := [];
    END; (*IF*)
    subMenuPos := InsertMenuTitle(subMenu, menuItems[menuBarPos], cmd, shortCut);
    OSB_NewMenuCommand := GetMenuItemId(subMenu, subMenuPos);
  END; (*OSB_NewMenuCommand*)
    
  PROCEDURE OSB_InstallMenuBar;
  BEGIN
    AssertOperation(SetMenu(appFrameWnd, menuBar), 'SetMenu');
    SendMessage(appClientWnd, wm_mdiSetMenu, 0,
                MakeLong(menuBar, GetSubMenu(menuBar, menuBarItems.nr - 2)));
    DrawMenuBar(appFrameWnd);
  END; (*OSB_InstallMenuBar*)

  PROCEDURE OSB_RemoveMenuBar;
  BEGIN
    (*nothing to do*)
  END; (*OSB_RemoveMenuBar*)


(*=== 3. window management utilities ===*)

  PROCEDURE OSB_GetMouseState(wp: WindowPeer;
                              VAR buttonPressed: BOOLEAN; VAR pos: Point);
    VAR
      msg: TMsg;
      p:   TPoint;
   BEGIN
    buttonPressed := gButtonPressed;
    IF appFrameWnd = GetActiveWindow THEN BEGIN
      SetCapture(wp^.wnd);
      IF PeekMessage(msg, 0, wm_lButtonUp, wm_lButtonUp, pm_noRemove) THEN
        buttonPressed := FALSE;
      GetCursorPos(p);  (*in screen coordinates*)
      ScreenToClient(wp^.wnd, p);
      ReleaseCapture;
      pos.x := p.x;
      pos.y := p.y;
    END; (*IF*)
  END; (*OSB_GetMouseState*)

  PROCEDURE OSB_ShowMessageWindow(title, message: STRING);
    VAR
      t, m: ARRAY [0 .. 255] OF CHAR;
  BEGIN
    StrPCopy(t, title);
    StrPCopy(m, message);
    MessageBox(GetFocus, m, t, mb_ok);
  END; (*OSB_ShowMessageWindow*)

  FUNCTION OSB_EqualWindowPeers(wp1, wp2: WindowPeer): BOOLEAN;
  BEGIN
    OSB_EqualWindowPeers := (wp1 = wp2) OR
                            ( (wp1 <> NIL) AND (wp2 <> NIL) AND
                              (wp1^.wnd = wp2^.wnd) );
  END; (*OSB_EqualWindowPeers*)

  PROCEDURE OSB_CreateNewWindow(title: STRING; VAR wp: WindowPeer);
    VAR
      t: ARRAY [0 .. 255] OF CHAR;
  BEGIN
    IF wp = NIL THEN BEGIN
      New(wp);
      StrPCopy(t, title);
      wp^.wnd := CreateChildWindow(t, appClientWnd);
    END; (*IF*)
    wp^.dc := GetDC(wp^.wnd);
    ShowWindow(wp^.wnd, sw_showNormal);
    UpdateWindow(wp^.wnd);
  END; (*OSB_CreateNewWindow*)

  PROCEDURE OSB_DestroyOldWindow(VAR wp: WindowPeer);
    VAR
      oldWnd: HWnd;
  BEGIN
    IF wp <> NIL THEN BEGIN
      oldWnd  := wp^.wnd;
      wp^.wnd := 0;
      CloseWindow(oldWnd);
      SendMessage(appClientWnd, wm_mdiDestroy, oldWnd, 0);
      (*Dispose(wp); not necessary*)
    END; (*IF*)
  END; (*OSB_DestroyOldWindow*)


(*FUNCTION TempWindowPeer: WindowPeer; see bleow*)

    CONST
      wpArrMax =  10;
    VAR
      wpArr: ARRAY [0 .. wpArrMax] OF WindowPeerRec;
      wpArrNextFree: INTEGER;

  FUNCTION TempWindowPeer: WindowPeer;
  BEGIN
    wpArrNextFree  := (wpArrNextFree + 1) MOD wpArrMax;
    TempWindowPeer := @(wpArr[wpArrNextFree]);
  END; (*TempWindowPeer*)


  FUNCTION OSB_ActiveWindowPeer: WindowPeer;
    VAR
      wp: WindowPeer;
  BEGIN
    wp      := TempWindowPeer;
  {$IFDEF FPC}
    wp^.wnd :=        SendMessage(appClientWnd, wm_mdiGetActive, 0, 0);
  {$ELSE}
    wp^.wnd := LoWord(SendMessage(appClientWnd, wm_mdiGetActive, 0, 0));
  {$ENDIF}
  OSB_ActiveWindowPeer := wp;
  END; (*OSB_TopWindow*)

  FUNCTION OSB_IsVisible(wp: WindowPeer): BOOLEAN;
  BEGIN
    OSB_IsVisible := IsWindowVisible(wp^.wnd);
  END; (*OSB_IsVisible*)

  PROCEDURE OSB_EraseContent(wp: WindowPeer);
    VAR
      r:     TRect;
      brush: HBrush;
  BEGIN
    GetClientRect(wp^.wnd, r);
    brush := GetStockObject(white_brush);
    FillRect(wp^.dc, r, brush);
  END; (*OSB_EraseContent*)

  PROCEDURE OSB_GetContentRect(wp: WindowPeer;
                               VAR topLeft: Point; VAR w, h: INTEGER);
    VAR
      r: TRect;
  BEGIN
    GetClientRect(wp^.wnd, r);
    topLeft.x := r.left;
    topLeft.y := r.top;
    w         := r.right  - r.left;
    h         := r.bottom - r.top;
  END; (*OSB_GetContentRect*)

  PROCEDURE OSB_InvalRect(wp: WindowPeer; 
                          topLeft: Point; w, h: INTEGER);
    VAR
      r: TRect;
  BEGIN
    SetRect(r, topLeft.x, topLeft.y, topLeft.x + w, topLeft.y + h);
    InvalidateRect(wp^.wnd, @r, FALSE);
    UpdateWindow(wp^.wnd);
  END; (*OSB_InvalRect*)


(*=== 4. drawing utilities ===*)

  FUNCTION MsWindowsColorOf(c: DrawColor): LONGINT;
  BEGIN
    CASE c OF
      black:
        MsWindowsColorOf := RGB(  0,   0,   0);
      white:
        MsWindowsColorOf := RGB(255, 255, 255);
      ELSE
        MsWindowsColorOf := RGB(127, 127, 127);
    END; (*CASE*)
  END; (*MsWindowsColorOf*)

  PROCEDURE OSB_DrawDot(wp: WindowPeer;
                        pos: Point);
    VAR
      linePen:        HPen;
      width, 
      normalPenStyle: INTEGER;
      mode:           DrawMode;
      color:          LONGINT;
  BEGIN
    width := 1;
    mode  := invertMode;
    color := MsWindowsColorOf(black);
    normalPenStyle := GetROP2(wp^.dc);
    (*move cursor to pos*)
    MoveToEx(wp^.dc, pos.x, pos.y, NIL);
    (*set drawing mode*)
    IF mode = invertMode THEN
      SetROP2(wp^.dc, r2_not)
    ELSE
      SetROP2(wp^.dc, r2_copyPen);
    linePen := CreatePen(ps_solid, width, color);
    SelectObject(wp^.dc, linePen);
    (*draw*)
    LineTo(wp^.dc, pos.x, pos.y);  (*a dot is a line with length 1*)
    (*restore previous settings*)
    SetROP2(wp^.dc, normalPenStyle);
    SelectObject(wp^.dc, GetStockObject(black_pen));
    DeleteObject(linePen);
  END; (*OSB_DrawDot*)

  PROCEDURE OSB_DrawLine(wp: WindowPeer;
                         startPos, endPos: Point; t: INTEGER);
    VAR
      linePen:        HPen;
      width, 
      normalPenStyle: INTEGER;
      mode:           DrawMode;
      color:          LONGINT;
  BEGIN
    width := t;
    mode  := invertMode;
    color := MsWindowsColorOf(black);
    normalPenStyle := GetROP2(wp^.dc);
    (*move cursor to startPos*)
    MoveToEx(wp^.dc, startPos.x, startPos.y, NIL);
    (*set drawing mode*)
    IF mode = invertMode THEN
      SetROP2(wp^.dc, r2_not)
    ELSE
      SetROP2(wp^.dc, r2_copyPen);
    (*SOLID because startPos and endPos are inside the line*)
    linePen := CreatePen(ps_solid, width, color);
    SelectObject(wp^.dc, linePen);
    (*draw*)
    LineTo(wp^.dc,endPos.x, endPos.y);
    (*restore previous settings*)
    SetROP2(wp^.dc, normalPenStyle);
    SelectObject(wp^.dc, GetStockObject(black_pen));
  END; (*OSB_DrawLine*)

  PROCEDURE OSB_DrawRectangle(wp: WindowPeer;
                              topLeft: Point; w, h, t: INTEGER; fill: BOOLEAN);
    VAR
      linePen:        HPen;
      lineBrush:      HBrush;
      lb:             TLogBrush;
      width, 
      normalPenStyle: INTEGER;
      mode:           DrawMode;
      color:          LONGINT;
  BEGIN
    lb.lbStyle := bs_hollow;
    width      := t;
    mode       := invertMode;
    color      := MsWindowsColorOf(black);
    normalPenStyle  := GetROP2(wp^.dc);
    (*set drawing mode*)
    IF mode = invertMode THEN
      SetROP2(wp^.dc, r2_not)
    ELSE
      SetROP2(wp^.dc, r2_copyPen);
    linePen := CreatePen(ps_insideFrame, width, color);
    SelectObject(wp^.dc, linePen);
    IF fill THEN
      lineBrush := CreateSolidBrush(color) (*fill color same as outline color*)
    ELSE
      lineBrush := CreateBrushIndirect(lb);
    SelectObject(wp^.dc, lineBrush);
    (*draw*)
    Rectangle(wp^.dc, topLeft.x , topLeft.y , topLeft.x + w , topLeft.y + h);
    (*restore pervious settings*)
    SetROP2(wp^.dc, normalPenStyle);
    SelectObject(wp^.dc, GetStockObject(black_pen));
    DeleteObject(linePen);
    DeleteObject(lineBrush);
  END; (*OSB_DrawRectangle*)

  PROCEDURE OSB_DrawOval(wp: WindowPeer;
                         topLeft: Point; w, h, t: INTEGER; fill: BOOLEAN);
    VAR
      linePen:        HPen;
      lineBrush:      HBrush;
      lb:             TLogBrush;
      width, 
      normalPenStyle: INTEGER;
      mode:           DrawMode;
      color:          LONGINT;
  BEGIN
    lb.lbStyle := bs_hollow;
    width      := t;
    mode       := invertMode;
    color      := MsWindowsColorOf(black);
    normalPenStyle := GetROP2(wp^.dc);
    (*set drawing mode*)
    IF mode = invertMode THEN
      SetROP2(wp^.dc, r2_not)
    ELSE
      SetROP2(wp^.dc, r2_copyPen);
    linePen := CreatePen(ps_insideFrame, width, color);
    SelectObject(wp^.dc, linePen);
    IF fill THEN
      lineBrush := CreateSolidBrush(color) (*fill color same as outline color*)
    ELSE
      lineBrush := CreateBrushIndirect(lb);
    SelectObject(wp^.dc, lineBrush);
    (*draw*)
    Ellipse(wp^.dc, topLeft.x , topLeft.y , topLeft.x + w, topLeft.y + h);
    (*restore previous settings*)
    SetROP2(wp^.dc, normalPenStyle);
    SelectObject(wp^.dc, GetStockObject(black_pen));
    DeleteObject(linePen);
    DeleteObject(lineBrush);
  END; (*OSB_DrawOval*)

  PROCEDURE OSB_DrawString(wp: WindowPeer;
                           pos: Point; str: STRING; size: INTEGER);
    TYPE
      BytePtr = ^BYTE;
    VAR
      font: HFont;
      lf:   TLogFont;
      pt:   Point;
      lfp:  BytePtr;
      i:    INTEGER;
      s:    ARRAY [0 .. 255] OF CHAR;
  BEGIN
    (*clear font structure*)
    lfp := BytePtr(@lf);
    FOR i := 1 TO SizeOf(TLogFont) DO BEGIN
      lfp^ := 0;
      lfp  := BytePtr(LONGINT(lfp) + 1);
    END; (*FOR*)
    (*convert coordinates*)
    pt.y := GetDeviceCaps(wp^.dc, logPixelSy);
    pt.x := 0;
    DPtoLP(wp^.dc, pt, 1);
    (*construct font*)
    lf.lfHeight     := -MulDiv(size, pt.y, 72); (*set height*)
    lf.lfEscapement := 0;
    lf.lfWeight     := fw_normal;     (*fw_normal, fw_bold, ...*)
    lf.lfItalic     := 0;             (*1 for italic*)
    StrPCopy(lf.lfFaceName, 'Arial'); (*Arial is standard font*)
    font := CreateFontIndirect(lf);
    (*draw*)
    SelectObject(wp^.dc, font);
    SetTextColor(wp^.dc, RGB(0, 0, 0));
    SetBkMode(wp^.dc, transparent);   (*background should remain*)
    StrPCopy(s, str);
    TextOut(wp^.dc, pos.x, pos.y, s, Length(str));
    DeleteObject(font);
  END; (*OSB_DrawString*)


BEGIN (*OSBridge*)
  lastMenuCmd    := firstMenuCmd;
  gButtonPressed := FALSE;
  wpArrNextFree  := 0;
END. (*OSBridge*)

