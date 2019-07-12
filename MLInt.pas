(*MLInt:                                               MiniLib V.4, 2004
  -----
  Class MLInteger, the MiniLib integer class.
========================================================================*)
UNIT MLInt;

INTERFACE

  USES
    MLObj;

  TYPE

(*=== class MLInteger ===*)

    MLInteger = ^MLIntegerObj;
    MLIntegerObj = OBJECT(MLObjectObj)

      val: INTEGER;

      CONSTRUCTOR Init(i: INTEGER);
      DESTRUCTOR Done; VIRTUAL;

(*--- overridden methods ---*)

      FUNCTION AsString: STRING; VIRTUAL;
      (*returns MLInteger value as STRING*)

      FUNCTION IsEqualTo(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns SELF.val = o^.val*)

      FUNCTION IsLessThan(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns SELF.val < o^.val*)

    END; (*OBJECT*)


  FUNCTION NewMLInteger(val: INTEGER): MLInteger;


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo;


  FUNCTION NewMLInteger(val: INTEGER): MLInteger;
    VAR
      i: MLInteger;
  BEGIN
    New(i, Init(val));
    NewMLInteger := i;
  END; (*NewMLInteger*)


(*=== clas MLInteger ===*)


CONSTRUCTOR MLIntegerObj.Init(i: INTEGER);
  BEGIN
    INHERITED Init;
    Register('MLInteger', 'MLObject');
    val := i;
  END; (*MLIntegerObj.Init*)

  DESTRUCTOR MLIntegerObj.Done;
  BEGIN
    INHERITED Done;
  END; (*MLIntegerObj.Done*)


(*--- overridden methods ---*)

  FUNCTION MLIntegerObj.AsString: STRING;
    VAR
      s: STRING;
  BEGIN
    Str(val, s);
    AsString := s;
  END; (*MLIntegerObj.AsString*)
    
  FUNCTION MLIntegerObj.IsEqualTo(o: MLObject): BOOLEAN;
  BEGIN
    IF o^.IsA('MLInteger') THEN
      IsEqualTo := SELF.val = MLInteger(o)^.val
    ELSE BEGIN
      Error('invalid IsEqualTo comparison of MLInteger to ' + o^.Class);
      IsEqualTo := FALSE;
    END; (*ELSE*)
  END; (*MLIntegerObj.IsEqualTo*)

  FUNCTION MLIntegerObj.IsLessThan(o: MLObject): BOOLEAN;
  BEGIN
    IF o^.IsA('MLInteger') THEN
      IsLessThan := SELF.val < MLInteger(o)^.val
    ELSE BEGIN
      Error('invalid IsLessThan comparison of MLInteger to ' + o^.Class);
      IsLessThan := FALSE;
    END; (*ELSE*)
  END; (*MLIntegerObj.IsLessThan*)


END. (*MLInt*)


 

