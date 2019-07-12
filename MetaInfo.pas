(*MetaInfo:                                            MiniLib V.4, 2004
  ---------
  Meta information (abstract data structure).
========================================================================*)
UNIT MetaInfo;

INTERFACE
  
  TYPE
    ApplicationKind  = (consoleApplication, guiApplication);
    ShowMsgWindowPtr = PROCEDURE(title, message: STRING);


(*=== global variables  ===*)

  VAR
    applKind:      ApplicationKind;
    showMsgWindow: ShowMsgWindowPtr;


(*=== public procedures ===*)

  PROCEDURE WriteMetaInfo;
  (*writes meta info: class hierarchy and object counters*)

  PROCEDURE Error(message: STRING);
  (*writes error message to console or opens message window
    and terminates program execution*)

  PROCEDURE AbstractMethodError(methodName: STRING);
  (*calls Error to report call of abstract method*)

  PROCEDURE Assert(condition: BOOLEAN; message: STRING);
  (*checks condition, when false calls Error(message)*)


(*=== private procedures (used within MLObject only) ===*)

  PROCEDURE MI_Register(className, baseClassName: STRING;
                        objAddr: POINTER);
  (*registers class and increases object creation counter*)

  PROCEDURE MI_IncCreationCounter(index: INTEGER);
  (*increases object creation counter of class with index*)

  PROCEDURE MI_IncDeletionCounter(index: INTEGER);
  (*increases object deletion counter of class with index*)

  FUNCTION MI_ClassNameOf(index: INTEGER): STRING;
  (*returns calss mane for class with index*)

  FUNCTION MI_BaseClassNameOf(index: INTEGER): STRING;
  (*returns class name for base class of class with index*)

  FUNCTION MI_IsEqualToOrDerivedFrom(className,
                                     baseClassName: STRING): BOOLEAN;
  (*returns TRUE if there is an inheritance relationship between ...*)


(*======================================================================*)
IMPLEMENTATION
  
  USES
    WinCrt,
    MLObj;
    
  CONST
    errorIndex      =   0;    (*for non-existing classes or none*)
    maxClasses      = 100;    (*max. number of classes*)
    maxClassNameLen =  50;
    none            = 'NONE'; (*non-existing base class of Object*)


(*--- type for representation of information for classes ---*)

  TYPE
    Class = RECORD
      className:      STRING[maxClassNameLen]; (*name of class*)
      baseClassIndex: INTEGER;        (*index of base class in classes*)
      objsCreated:    LONGINT;        (*number of dynamic objects created*)
      objsDeleted:    LONGINT;        (*number of dynamic objects freed*)
    END; (*RECORD*)


(*--- data for collection meta information on classes their objects ---*)

VAR
    nrOfClasses: INTEGER;             (*number of classes registered*)
    classes:     ARRAY [1 .. maxClasses] OF Class; (*in [1..nrOfClasses]*)
    globalVar:   INTEGER;             (*to guess whether object isDynamic*)


(*--- utility functions and procedures uesd within this module only ---*)

  FUNCTION IndexOf(className: STRING): INTEGER;
    VAR
      i: INTEGER;
  BEGIN
    IF className = none THEN BEGIN
      IndexOf := errorIndex;
      Exit;
    END; (*IF*)
    i := nrOfClasses;
    WHILE (i >= 1) AND (classes[i].className <> className) DO BEGIN
      i := i - 1;
    END; (*WHILE*)
    IndexOf := i; (*if not found, returns errorIndex = 0*)
  END; (*IndexOf*)

  PROCEDURE WriteMetaInfoRec(baseClassIndex: INTEGER; indent: INTEGER;
                             VAR objectsStillAlive: LONGINT);
    VAR
      aliveSum, alive: LONGINT;
      space, i: INTEGER;
  BEGIN
    aliveSum := 0;
    FOR i := 1 TO nrOfClasses DO BEGIN
      IF classes[i].baseClassIndex = baseClassIndex THEN BEGIN
        space := 23 - indent;
        IF Length(classes[i].className) > space THEN
          (*name to long, trancate*)
          Write(' ': indent, Copy(classes[i].className, 1, space - 2),
                '.. ')
        ELSE
          Write(' ': indent, classes[i].className,
                ' ': space - Length(classes[i].className) + 1);
        Write('| ',  classes[i].objsCreated: 7);
        Write(' | ', classes[i].objsDeleted: 7);
        alive := classes[i].objsCreated - classes[i].objsDeleted;
        Write(' | ');
        IF alive < 0 THEN
          Write(alive, ' ERROR')
        ELSE BEGIN (*alive >= 0*)
          Write(alive: 11);
          aliveSum := aliveSum + alive;
        END; (*ELSE*)
        WriteLn;
        WriteMetaInfoRec(i, indent + 2, alive);
        aliveSum := aliveSum + alive;
      END; (*IF*)
    END; (*FOR*)
    objectsStillAlive := aliveSum;
  END; (*WriteMetaInfoRec*)


(*=== "public" procedures and functions ===*)

  PROCEDURE WriteMetaInfo;
    VAR
      objectsStillAlive: LONGINT;
  BEGIN
    WriteLn;
    WriteLn;
    WriteLn('==========================================================');
    WriteLn(' Meta information for MiniLib application                 ');
    WriteLn('------------------------+---------------------------------');
    WriteLn(' Class hierarchy        | Number of dynamic objects       ');
    WriteLn('                        +---------+---------+-------------');
    WriteLn('                        | created | deleted | still alive ');
    WriteLn('------------------------+---------+---------+-------------');
    WriteMetaInfoRec(errorIndex, 1, objectsStillAlive); (*start with none*)
    WriteLn('------------------------+---------+---------+-------------');
    Write(' Number of classes: ', nrOfClasses: 2, '  | Summary: ');
    IF objectsStillAlive = 0 THEN
      WriteLn('all objects deleted')
    ELSE
      WriteLn(objectsStillAlive, ' object(s) still alive');
    WriteLn('==========================================================');
    WriteLn;
  END; (*WriteMetaInfo*)


  PROCEDURE Error(message: STRING);
  BEGIN
    IF applKind = consoleApplication THEN BEGIN
      WriteLn;
      WriteLn;
      WriteLn('*** ERROR: ' + message);
      WriteLn;
    END (*THEN*)
    ELSE BEGIN (*applKind = guiApplication*)
      ShowMsgWindow('*** ERROR ***', message);
    END; (*ELSE*)
    Halt;
  END; (*Error*)

  PROCEDURE AbstractMethodError(methodName: STRING);
  BEGIN
    Error('invalid call of abstract method ' + methodName);
  END; (*AbstractMethodError*)

  PROCEDURE Assert(condition: BOOLEAN; message: STRING);
  BEGIN
    IF NOT condition THEN
      Error('assertion failed, ' + message);
  END; (*Assert*)


(*=== "private" procedures and functions (used within class Object only) ===*)

  PROCEDURE MI_Register(className, baseClassName: STRING;
                        objAddr: POINTER);
    VAR
      classIndex, baseClassIndex: INTEGER;
      obj: MLObject;
      localVar: INTEGER; (*to guess whether object isDynamic*)
      offsetToLocVar, offsetToGlobVar: LONGINT;
  BEGIN
    IF Length(className) > maxClassNameLen THEN
      Error('class name ' + className + ' too long');
    baseClassIndex := IndexOf(baseClassName);
    IF (baseClassIndex = errorIndex) AND (baseClassName <> none) THEN
      Error('base class ' + baseClassName +
             ' of class ' + className + ' not registered in MetaInfo');
    classIndex := IndexOf(className);
    IF classIndex = errorIndex THEN BEGIN (*new class*)
      IF nrOfClasses = maxClasses THEN
        Error('too many classes registerd in MetaInfo');
      nrOfClasses := nrOfClasses + 1;
      classIndex  := nrOfClasses;
      classes[classIndex].className      := className;
      classes[classIndex].baseClassIndex := baseClassIndex;
      classes[classIndex].objsCreated    := 0;
      classes[classIndex].objsDeleted    := 0;
    END; (*IF*)
    obj := MLObject(objAddr);
    obj^.classIndex := classIndex;
    (*try to guess whether objAddr lies within heap range*)
    offsetToLocVar  := Abs(LONGINT(objAddr) - LONGINT(@localVar));
    offsetToGlobVar := Abs(LONGINT(objAddr) - LONGINT(@globalVar));
    obj^.isDynamic := (offsetToLocVar  > 65535) AND
                      (offsetToGlobVar > 65535);
    IF obj^.isDynamic THEN BEGIN
      IF baseClassIndex <> errorIndex THEN
        Dec(classes[baseClassIndex].objsCreated);
      Inc(classes[classIndex].objsCreated);
    END; (*IF*)
  END; (*MI_Register*)

  PROCEDURE MI_IncCreationCounter(index: INTEGER);
  BEGIN
    IF (index >= 1) AND (index <= nrOfClasses) THEN
      Inc(classes[index].objsCreated)
    ELSE
      Error('invalid class index in MetaInfo.MI_IncCreationCounter');
  END; (*MI_IncCreationCounter*)

  PROCEDURE MI_IncDeletionCounter(index: INTEGER);
  BEGIN
    IF (index >= 1) AND (index <= nrOfClasses) THEN
      Inc(classes[index].objsDeleted)
    ELSE
      Error('invalid class index in MetaInfo.MI_IncDeletionCounter');
  END; (*MI_IncDeletionCounter*)

  FUNCTION MI_ClassNameOf(index: INTEGER): STRING;
  BEGIN
    IF index = errorIndex THEN BEGIN
      MI_ClassNameOf := none;
      Exit;
    END (*THEN*)
    ELSE IF (index >= 1) AND (index <= nrOfClasses) THEN BEGIN
      MI_ClassNameOf := classes[index].className;
      Exit;
    END (*ELSE*)
    ELSE
      Error('invalid class index in MetaInfo.MI_ClassNameOf');
  END; (*ClassNameOf*)

  FUNCTION MI_BaseClassNameOf(index: INTEGER): STRING;
  BEGIN
    IF (index >= 1) AND (index <= nrOfClasses) THEN BEGIN
      MI_BaseClassNameOf := MI_ClassNameOf(classes[index].baseClassIndex);
      Exit;
    END (*THEN*)
    ELSE
      Error('invalid class index in MetaInfo.MI_BaseClassNameOf');
  END; (*MI_BaseClassNameOf*)

  FUNCTION MI_IsEqualToOrDerivedFrom(className,
                                     baseClassName: STRING): BOOLEAN;
    VAR
      classIndex, baseClassIndex: INTEGER;
  BEGIN

    classIndex := IndexOf(className);
    IF classIndex = errorIndex THEN
      Error('class '+ className + ' not registered in MetaInfo');

    baseClassIndex := IndexOf(baseClassName);
    (* Attention: when baseClassIndex == errorIndex there are two possibilites
         1. this class exists, but no objects have been created up to now
         2. there is no class with this name
      let's be pessimistic, we assume the second possibility*)
    IF baseClassIndex = errorIndex THEN
      Error('class ' + baseClassName + ' not registered in MetaInfo');

    IF classIndex = baseClassIndex THEN BEGIN
      MI_IsEqualToOrDerivedFrom := TRUE;
      Exit;
    END; (*THEN*)
    WHILE (classIndex <> errorIndex) AND
          (classes[classIndex].className <> baseClassName) DO BEGIN
      classIndex := classes[classIndex].baseClassIndex;
    END; (*WHILE*)
    MI_IsEqualToOrDerivedFrom := classIndex <> errorIndex;
  END; (*MI_IsEqualToOrDerivedFrom*)


BEGIN (*MetaInfo*)
  (*init. both globals, possibly reset in MLApplication.Init*)
  applKind      := consoleApplication;
  showMsgWindow := NIL;
  (*init. abstract data structure for meta info*)
  nrOfClasses   :=   0;
{$IFNDEF FPC}
  (*init. screen*)
  screenSize.x  :=  80;
  screenSize.y  := 800;  (* ATTENTION: x*y must be less than 64KB *)
  InitWinCrt;
{$ENDIF}
END. (*MetaInfo*)




 

