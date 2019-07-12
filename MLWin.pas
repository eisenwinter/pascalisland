(*MLWin:                                               MiniLib V.4, 2004
  -----
  Class MLWindow.
========================================================================*)
UNIT MLWin;

INTERFACE

  USES
    OSBridge, MLObj;

  TYPE

(*=== class MLWindow ===*)

    MLWindow    = ^MLWindowObj;
    MLWindowObj = OBJECT(MLObjectObj)

(*--- private data components ---*)

      winTitle: STRING;
      wp:       WindowPeer;

      CONSTRUCTOR Init(title: STRING);
      DESTRUCTOR Done; VIRTUAL;

(*--- overridden method ---*)

      FUNCTION IsEqualTo(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns whether both MLWindow objects are identical*)

(*--- new methods ... ---*)

      FUNCTION GetWindowPeer: WindowPeer;

(*--- ... for window handling ---*)

      PROCEDURE Open; VIRTUAL;
      PROCEDURE Close; VIRTUAL;
      PROCEDURE Update; VIRTUAL;

      PROCEDURE GetContentRect(VAR topLeft: Point; VAR w, h: INTEGER); VIRTUAL;
      FUNCTION  Width:  INTEGER; VIRTUAL; (*returns same w as GetContent*)
      FUNCTION  Height: INTEGER; VIRTUAL; (*returns same h as GetContent*)
      FUNCTION  IsVisible: BOOLEAN; VIRTUAL;

      PROCEDURE Redraw; VIRTUAL;          (*override to do drawing*)

      PROCEDURE InvalRectangle(topLeft: Point; w, h: INTEGER); VIRTUAL;
      PROCEDURE InvalContent; VIRTUAL;    (*InvalRectangle for whole content*)
      PROCEDURE EraseContent; VIRTUAL;

(*--- ... for event handling ---*)

      PROCEDURE OnIdle; VIRTUAL;
      PROCEDURE OnMousePressed (pos: Point); VIRTUAL;
      PROCEDURE OnMouseReleased(pos: Point); VIRTUAL;
      PROCEDURE OnMouseMove    (pos: Point); VIRTUAL;
      PROCEDURE OnKey(key: CHAR); VIRTUAL;
      PROCEDURE OnCommand(commandNr: INTEGER); VIRTUAL;
      PROCEDURE OnRedraw; VIRTUAL;
      PROCEDURE OnResize; VIRTUAL;

      PROCEDURE GetMouseState(VAR buttonPressed: BOOLEAN; VAR pos: Point); VIRTUAL;

(*--- ... for drawing: w = width, h = height, t = thickness ---*)

      PROCEDURE DrawDot(pos: Point); VIRTUAL;
      PROCEDURE DrawLine(startPos, endPos: Point; t: INTEGER); VIRTUAL;
      PROCEDURE DrawRectangle(topLeft: Point; w, h, t: INTEGER); VIRTUAL;
      PROCEDURE DrawFilledRectangle(topLeft: Point; w, h: INTEGER); VIRTUAL;
      PROCEDURE DrawOval(topLeft: Point; w, h, t: INTEGER); VIRTUAL;
      PROCEDURE DrawFilledOval(topLeft: Point; w, h: INTEGER); VIRTUAL;
      PROCEDURE DrawString(pos: Point; str: STRING; size: INTEGER);

    END; (*MLWindow*)

  FUNCTION NewMLWindow(title: STRING): MLWindow;


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo,
    MLAppl;


  FUNCTION NewMLWindow(title: STRING): MLWindow;
    VAR
      w: MLWindow;
  BEGIN
    New(w, Init(title));
    NewMLWindow := w;
  END; (*NewMLWindow*)


(*=== MLWindow ===*)
 
 
  CONSTRUCTOR MLWindowObj.Init(title: STRING);
  BEGIN
    INHERITED Init;
    Register('MLWindow', 'MLObject');
    winTitle := title;
    wp       := NIL;
  END; (*MLWindowObj.Init*)

  DESTRUCTOR MLWindowObj.Done;
  BEGIN
   Close;
   INHERITED Done;
  END; (*MLWindowObj.Done*)


(*--- overridden method ---*)

  FUNCTION MLWindowObj.IsEqualTo(o: MLObject): BOOLEAN;
  BEGIN
    IsEqualTo := (@SELF = o);
  END; (*MLWindowObj.IsEqualTo*)


(*--- new methods ... ---*)

  FUNCTION MLWindowObj.GetWindowPeer: WindowPeer;
  BEGIN
    GetWindowPeer := wp;
  END; (*MLWindowObj.GetWindowPeer*)


(*--- ... for window handling ---*)

  PROCEDURE MLWindowObj.Open;
  BEGIN
    OSB_CreateNewWindow(winTitle, wp);
    MLApplicationInstance^.AddWindow(@SELF);
  END; (*MLWindowObj.Open*)
    
  PROCEDURE MLWindowObj.Close;
  BEGIN
    MLApplicationInstance^.RemoveWindow(@SELF);
    OSB_DestroyOldWindow(wp);
  END; (*MLWindowObj.Close*)

  PROCEDURE MLWindowObj.Update;
  BEGIN
    IF IsVisible THEN BEGIN
      OSB_EraseContent(wp);
      Redraw;
    END; (*IF*)
  END; (*MLWindowObj.Update*)


  PROCEDURE MLWindowObj.GetContentRect(VAR topLeft: Point;
                                       VAR w, h : INTEGER);
  BEGIN
    OSB_GetContentRect(wp, topLeft, w, h);
  END; (*MLWindowObj.GetContentRect*)
    
  FUNCTION MLWindowObj.Width: INTEGER;
    VAR
      topLeft: Point;
      w, h:    INTEGER;
  BEGIN
    OSB_GetContentRect(wp, topLeft, w, h);
    Width := w;
  END; (*MLWindowObj.Width*)
    
  FUNCTION MLWindowObj.Height: INTEGER;
    VAR
      topLeft: Point;
      w, h:    INTEGER;
  BEGIN
    OSB_GetContentRect(wp, topLeft, w, h);
    Height := h;
  END; (*MLWindowObj.Height*)
    
  FUNCTION MLWindowObj.IsVisible: BOOLEAN;
  BEGIN
    IsVisible := OSB_IsVisible(wp);
  END; (*MLWindowObj.IsVisible*)


  PROCEDURE MLWindowObj.Redraw;
  BEGIN
    (*nothing to do here: override to do drawing*)
  END; (*MLWindowObj.Redraw*)


  PROCEDURE MLWindowObj.InvalRectangle(topLeft: Point; w, h: INTEGER);
  BEGIN
    OSB_InvalRect(wp, topLeft, w, h);
  END; (*MLWindowObj.InvalRectangle*)

  PROCEDURE MLWindowObj.InvalContent;
    VAR
      topLeft: Point;
      w, h:    INTEGER;
  BEGIN
    GetContentRect(topLeft, w, h);
    InvalRectangle(topLeft, w, h);
  END; (*MLWindowObj.InvalContent*)

  PROCEDURE MLWindowObj.EraseContent;
  BEGIN
    OSB_EraseContent(wp);
  END; (*MLWindowObj.EraseContent*)


(*--- ... for event handling ---*)

  PROCEDURE MLWindowObj.OnIdle;
  BEGIN
    (*nothing to do here*)
  END; (*MLWindowObj.OnIdle*)
    
  PROCEDURE MLWindowObj.OnMousePressed(pos: Point);
  BEGIN
    (*nothing to do here*)
  END; (*MLWindowObj.OnMousePressed*)
    
  PROCEDURE MLWindowObj.OnMouseReleased(pos: Point);
  BEGIN
    (*nothing to do here*)
  END; (*MLWindowObj.OnMOuseReleased*)
    
  PROCEDURE MLWindowObj.OnMouseMove(pos: Point);
  BEGIN
    (*nothing to do here*)
  END; (*MLWindowObj.OnMouseMove*)
    
  PROCEDURE MLWindowObj.OnKey(key: CHAR);
  BEGIN
    (*nothing to do here*)
  END; (*MLWindowObj.OnMouseMove*)
    
  PROCEDURE MLWindowObj.OnCommand(commandNr: INTEGER);
    VAR
      w: MLWindow;
  BEGIN
    IF commandNr = closeCommand THEN BEGIN
      Close;
      w := @SELF;
      Dispose(w, Done);
    END; (*IF*)
  END; (*MLWindowObj.OnCommand*)
    
  PROCEDURE MLWindowObj.OnRedraw;
  BEGIN
    IF IsVisible THEN
      Redraw;
  END; (*MLWindowObj.OnRedraw*)

  PROCEDURE MLWindowObj.OnResize;
  BEGIN
    IF IsVisible THEN
      Update;
  END; (*MLWindowObj.OnResize*)


  PROCEDURE MLWindowObj.GetMouseState(VAR buttonPressed: BOOLEAN;
                                      VAR pos: Point);
  BEGIN
    OSB_GetMouseState(wp, buttonPressed, pos);
  END; (*MLWindowObj.GetMouseState*)


(*--- ... for drawing ---*)

  PROCEDURE MLWindowObj.DrawDot(pos: Point);
  BEGIN
    IF IsVisible THEN
      OSB_DrawDot(wp, pos);
  END; (*MLWindowObj.DrawDot*)

  PROCEDURE MLWindowObj.DrawLine(startPos, endPos: Point; t: INTEGER);
  BEGIN
    IF IsVisible THEN
      OSB_DrawLine(wp, startPos, endPos, t);
  END; (*MLWindowObj.DrawLine*)

  PROCEDURE MLWindowObj.DrawRectangle(topLeft: Point; w, h, t: INTEGER);
  BEGIN
    IF IsVisible THEN
      OSB_DrawRectangle(wp, topLeft, w, h, t, FALSE);
  END; (*MLWindowObj.DrawRectangle*)

  PROCEDURE MLWindowObj.DrawFilledRectangle(topLeft: Point; w, h: INTEGER);
  BEGIN
    IF IsVisible THEN
      OSB_DrawRectangle(wp, topLeft, w, h, 1, TRUE);
  END; (*MLWindowObj.DrawFilledRectangle*)

  PROCEDURE MLWindowObj.DrawOval(topLeft: Point; w, h, t: INTEGER);
  BEGIN
    IF IsVisible THEN
      OSB_DrawOval(wp, topLeft, w, h, t, FALSE);
  END; (*MLWindowObj.DrawOval*)

  PROCEDURE MLWindowObj.DrawFilledOval(topLeft: Point; w, h: INTEGER);
  BEGIN
    IF IsVisible THEN
      OSB_DrawOval(wp, topLeft, w, h, 1, TRUE);
  END; (*MLWindowObj.DrawFilledOval*)

  PROCEDURE MLWindowObj.DrawString(pos: Point; str: STRING; size: INTEGER);
  BEGIN
    IF IsVisible THEN
      OSB_DrawString(wp, pos, str, size);
  END; (*MLWindowObj.DrawString*)


END. (*MLWin*)


 

