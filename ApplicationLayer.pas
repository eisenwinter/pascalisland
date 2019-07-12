{
  ApplLayer
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @abstract(ui for pascal ist auch nur eine Insel)
  @created(2017-07-10)
  this houses the ui af the application
  @lastmod(2017-07-10)
}
UNIT ApplicationLayer;

INTERFACE
  USES
    MetaInfo, OSBridge,
    MLObj, MLWin, MLAppl, IslandWindow;
  TYPE
    IslandApplication = ^TIslandApplication;
    TIslandApplication = OBJECT(MLApplicationObj)
        CONSTRUCTOR Init;
        PROCEDURE BuildMenus; VIRTUAL;
        PROCEDURE Run; VIRTUAL;
        PROCEDURE OpenNewWindow; VIRTUAL;
        END;
  FUNCTION NewApplication : IslandApplication;
IMPLEMENTATION
VAR
  rebuildCommand : INTEGER;

FUNCTION NewApplication : IslandApplication;
VAR
  s : IslandApplication;
BEGIN
  New(s,Init);
  NewApplication := s;
END;

CONSTRUCTOR TIslandApplication.Init;
BEGIN
  INHERITED Init('Pascal ist auch nur eine Insel');
  Register('IslandApplication', 'MLApplication');
END;

PROCEDURE TIslandApplication.Run;
  VAR
    e: Event;
BEGIN
  Randomize;
  BuildMenus;
  OSB_InstallMenuBar;
  OpenNewWindow;
  OSB_GetNextEvent(e);
  WHILE running DO BEGIN
    DispatchEvent(e);
    OSB_GetNextEvent(e);
  END; (*WHILE*)
  CloseAllOpenWindows
END;

PROCEDURE TIslandApplication.BuildMenus;
BEGIN
  rebuildCommand := NewMenuCommand('Settings',  'Rebuild',  'R');
END;

PROCEDURE TIslandApplication.OpenNewWindow;
BEGIN
  NewIslandWindow^.Open;
END;

END.
