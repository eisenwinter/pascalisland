(*MLStr:                                               MiniLib V.4, 2004
  -----
  Class MLString, the MiniLib string class.
========================================================================*)
UNIT MLStr;

INTERFACE

  USES
    MLObj;

  TYPE

(*=== class MLString ===*)

    MLString = ^MLStringObj;
    MLStringObj = OBJECT(MLObjectObj)

      pasStr: STRING;

      CONSTRUCTOR Init(s: STRING);
      DESTRUCTOR Done; VIRTUAL;

(*--- overridden methods ---*)

      FUNCTION AsString: STRING; VIRTUAL;
      (*returns MLString value as STRING*)

      FUNCTION IsEqualTo(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns SELF.pasStr = o^.pasStr*)

      FUNCTION IsLessThan(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns SELF.pasStr < o^.pasStr*)

(*--- new methods ---*)

      FUNCTION Length: INTEGER; VIRTUAL;
      (*returns length of MLString*)

      PROCEDURE Append(s: STRING); VIRTUAL;
      (*append s to MLString*)

    END; (*OBJECT*)


  FUNCTION NewMLString(s: STRING): MLString;


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo;


  FUNCTION NewMLString(s: STRING): MLString;
    VAR
      mls: MLString;
  BEGIN
    New(mls, Init(s));
    NewMLString := mls;
  END; (*NewMLString*)


  CONSTRUCTOR MLStringObj.Init(s: STRING);
  BEGIN
    INHERITED Init;
    Register('MLString', 'MLObject');
    pasStr := s;
  END; (*MLStringObj.Init*)

  DESTRUCTOR MLStringObj.Done;
  BEGIN
    INHERITED Done;
  END; (*MLStringObj.Done*)


(*--- overridden methods ---*)

  FUNCTION MLStringObj.AsString: STRING;
  BEGIN
    AsString := pasStr;
  END; (*MLStringObj.AsString*)
    
  FUNCTION MLStringObj.IsEqualTo(o: MLObject): BOOLEAN;
  BEGIN
    IF o^.IsA('MLString') THEN
      IsEqualTo := SELF.pasStr = MLString(o)^.pasStr
    ELSE BEGIN
      Error('invalid IsEqualTo comparison of MLString to ' + o^.Class);
      IsEqualTo := FALSE;
    END; (*ELSE*)
  END; (*MLStringObj.IsEqualTo*)

  FUNCTION MLStringObj.IsLessThan(o: MLObject): BOOLEAN;
  BEGIN
    IF o^.IsA('MLString') THEN
      IsLessThan := SELF.pasStr < MLString(o)^.pasStr
    ELSE BEGIN
      Error('invalid IsLessThan comparison of MLString to ' + o^.Class);
      IsLessThan := FALSE;
    END; (*ELSE*)
  END; (*MLStringObj.IsLessThan*)


(*--- new methods ---*)

  FUNCTION MLStringObj.Length: INTEGER;
  BEGIN
    Length := Ord(pasStr[0]);
  END; (*MLStringObj.Length*)

  PROCEDURE MLStringObj.Append(s: STRING);
  BEGIN
    pasStr := pasStr + s;
  END; (*MLStringObj.Append*)


END. (*MLStr*)


 

