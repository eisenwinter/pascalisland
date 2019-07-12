(*MLObj:                                               MiniLib V.4, 2004
  -----
  Class MLObject, the root class for all MiniLib classes.
========================================================================*)
UNIT MLObj;

INTERFACE

  TYPE

(*=== class MLObject ===*)

    MLObject = ^MLObjectObj;
    MLObjectObj = OBJECT   (*treat like an abstract class*)

(*--- private data components (set in MetaInfo.MI_Register) ---*)

      isDynamic:  BOOLEAN; (*true if object allocated on the heap*)
      classIndex: INTEGER; (*index for object's class in MetaInfo*)

      CONSTRUCTOR Init;
      DESTRUCTOR Done; VIRTUAL;

(*--- meta information, no overrides ---*)

      PROCEDURE Register(className, baseClassName: STRING);
      (*registers class and its base class, increases class' creation counter,
        has to be called in every constructor in every class*)

      FUNCTION Class: STRING;
      (*returns name of class for object*)

      FUNCTION BaseClass: STRING;
      (*returns name of base class for object*)

      FUNCTION IsA(className: STRING): BOOLEAN;
      (*returns whether object is at least of specified class*)

(*--- generation of textual object representations ---*)

      FUNCTION AsString: STRING; VIRTUAL;
      (*returns string representation for object*)

      PROCEDURE WriteAsString; VIRTUAL;
      (*writes object to output per default using method AsString*)

(*--- comparison method that may be overridden ---*)

      FUNCTION IsEqualTo(o: MLObject): BOOLEAN; VIRTUAL;
      (*checks for identity: @SELF = o ?*)

(*--- comparison method that has to be overridden ---*)

      FUNCTION IsLessThan(o: MLObject): BOOLEAN; VIRTUAL;
      (*writes error message if not overridden*)


    END; (*OBJECT*)


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo;


(*=== MLObject ===*)


  CONSTRUCTOR MLObjectObj.Init;
  BEGIN
    isDynamic  := FALSE; (*assume a static     *)
    classIndex := 0;     (*         NONE object*)
    Register('MLObject', 'NONE');
  END; (*MLObjectObj.Init*)

  DESTRUCTOR MLObjectObj.Done;
  BEGIN
    IF isDynamic THEN
      MI_IncDeletionCounter(classIndex);
  END; (*MLObjectObj.Done*)


(*--- meta information, no overrides ---*)

  PROCEDURE MLObjectObj.Register(className, baseClassName: STRING);
  BEGIN
    MI_Register(className, baseClassName, @SELF);
  END; (*MLObjectObj.Register*)

  FUNCTION MLObjectObj.Class: STRING;
  BEGIN
    Class := MI_ClassNameOf(classIndex);
  END; (*MLObjectObj.Class*)

  FUNCTION MLObjectObj.BaseClass: STRING;
  BEGIN
    BaseClass := MI_BaseClassNameOf(classIndex);
  END; (*MLObjectObj.BaseClass*)
    
  FUNCTION MLObjectObj.IsA(className: STRING): BOOLEAN;
  BEGIN
    IsA := MI_IsEqualToOrDerivedFrom(Class, className);
  END; (*MLObjectObj.IsA*)


(*--- generation of textual representations ---*)

  FUNCTION MLObjectObj.AsString: STRING;
  BEGIN
    AsString := Class
  END; (*MLObjectObj.AsString*)
    
  PROCEDURE MLObjectObj.WriteAsString;
  BEGIN
    Write(AsString)
  END; (*MLObjectObj.WriteAsString*)


(*--- comparison method that may be overridden ---*)

  FUNCTION MLObjectObj.IsEqualTo(o: MLObject): BOOLEAN;
  BEGIN
    IsEqualTo := @SELF = o; (*identical*)
  END; (*MLObjectObj.IsEqualTo*)


(*--- comparison method that has to be overridden ---*)

  FUNCTION MLObjectObj.IsLessThan(o: MLObject): BOOLEAN;
  BEGIN
    (*simple comparison of addresses would be possible: @THIS < o ?
      but the result would be useless*)
    Error('invalid IsLessThan comparison of ' + Class + ' with ' + o^.Class);
    IsLessThan := FALSE;
  END; (*MLObjectObj.IsLessThan*)


END. (*MLObj*)


 

