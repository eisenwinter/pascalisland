(*MLColl:                                              MiniLib V.4, 2004
  -----
  Abstract classes MLCollection and MLIterator,
  the root classes for all MiniLib collection and iterator classes.
========================================================================*)
UNIT MLColl;

INTERFACE

  USES
    MLObj;

  TYPE

    MLIterator = ^MLIteratorObj; (*full declaration below MLCollection*)

(*=== class MLCollection ===*)

    MLCollection = ^MLCollectionObj;
    MLCollectionObj = OBJECT(MLObjectObj) (*treat like an abstract class*)

      CONSTRUCTOR Init;
      DESTRUCTOR Done; VIRTUAL;

(*--- overridden methods ---*)

      FUNCTION AsString: STRING; VIRTUAL;
      (*returns string representation of collention with some elements*)

      PROCEDURE WriteAsString; VIRTUAL;
      (*writes collection to output with all elements*)

(*--- new "abstract" methods that have to be overridden ---*)

      FUNCTION Size: INTEGER; VIRTUAL;
      (*returns number of elements in collection*)

      PROCEDURE Add(o: MLObject); VIRTUAL;
      (*adds element o to collection*)

      FUNCTION Remove(o: MLObject): MLObject; VIRTUAL;
      (*removes first element = o and returns that element*)

      FUNCTION Contains(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns whether collection contains an element = o*)

      PROCEDURE Clear; VIRTUAL;
      (*removes all elements WITHOUT disposing them*)

      FUNCTION NewIterator: MLIterator; VIRTUAL;
      (*returns an iterator which has to be deleted after usage*)

(*--- new method ---*)

      PROCEDURE DisposeElements; VIRTUAL;
      (*removes all elements (like Clear) AND disposes them*)

    END; (*OBJECT*)


(*=== class MLIterator ===*)

  (*MLIterator = ^MLIteratorObj;        (*see declaration above*)
    MLIteratorObj = OBJECT(MLObjectObj) (*treat like an abstract class*)

      CONSTRUCTOR Init;
      DESTRUCTOR Done; VIRTUAL;

(*--- new abstract method ---*)

      FUNCTION Next: MLObject; VIRTUAL;
      (*returns next element or NIL if "end of" collection reached*)

    END; (*OBJECT*)


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo;


(*=== MLCollection ===*)


  CONSTRUCTOR MLCollectionObj.Init;
  BEGIN
    INHERITED Init;
    Register('MLCollection', 'MLObject');
  END; (*MLCollectionObj.Init*)

  DESTRUCTOR MLCollectionObj.Done;
  BEGIN
    INHERITED Done;
  END; (*MLCollectionObj.Done*)


(*--- overridden method ---*)

  FUNCTION MLCollectionObj.AsString: STRING;
    LABEL (*with GOTO ;-)*)
      999;
    VAR
      it:    MLIterator;
      o:     MLObject;
      s, os: STRING;
      first: BOOLEAN;
  BEGIN
    Str(Size, s);
    s := Class + ' with ' + s + ' Element(s): { ';
    it := NewIterator;
    o := it^.Next;
    first := TRUE;
    WHILE o <> NIL DO BEGIN
      os := o^.AsString;
      IF Length(s) + Length(os) > 230 THEN BEGIN
        s := s + ' ... TRUNCATED!';
        GOTO 999;
      END; (*IF*)
      IF NOT first THEN
        s := s + ', ';
      first := FALSE;
      s := s + os;
      o := it^.Next;
    END; (*WHILE*)
999:
    Dispose(it, Done);
    s := s + ' }';
    AsString := s;
  END; (*MLCollectionObj.AsString*)

  PROCEDURE MLCollectionObj.WriteAsString;
    VAR
      it:    MLIterator;
      o:     MLObject;
      first: BOOLEAN;
  BEGIN
    Write(Class, ' with ', Size, ' Element(s): { ');
    it := NewIterator;
    o := it^.Next;
    first := TRUE;
    WHILE o <> NIL DO BEGIN
      IF NOT first THEN
        Write(', ');
      first := FALSE;
      Write(o^.AsString);
      o := it^.Next;
    END; (*WHILE*)
    Dispose(it, Done);
    WriteLn(' }');
  END; (*MLCollectionObj.WriteAsString*)


(*--- default implementations of "abstract" methods ---*)

  FUNCTION MLCollectionObj.Size: INTEGER;
  BEGIN
    AbstractMethodError('MLCollectionObj.Size');
    Size := 0;
  END; (*MLCollectionObj.Size*)

  PROCEDURE MLCollectionObj.Add(o: MLObject);
  BEGIN
    AbstractMethodError('MLCollectionObj.Add');
  END; (*MLCollectionObj.Add*)

  FUNCTION MLCollectionObj.Remove(o: MLObject): MLObject;
  BEGIN
    AbstractMethodError('MLCollectionObj.Remove');
    Remove := NIL;
  END; (*MLCollectionObj.Remove*)

  FUNCTION MLCollectionObj.Contains(o: MLObject): BOOLEAN;
  BEGIN
    AbstractMethodError('MLCollectionObj.Contains');
    Contains := FALSE;
  END; (*MLCollectionObj.Contains*)

  PROCEDURE MLCollectionObj.Clear;
  BEGIN
    AbstractMethodError('MLCollectionObj.Clear');
  END; (*MLCollectionObj.Clear*)

  FUNCTION MLCollectionObj.NewIterator: MLIterator;
  BEGIN
    AbstractMethodError('MLCollectionObj.Iterator');
    NewIterator := NIL;
  END; (*MLCollectionObj.NewIterator*)


(*--- new method ---*)

  PROCEDURE MLCollectionObj.DisposeElements;
    VAR
      it: MLIterator;
      o:  MLObject;
  BEGIN
    it := NewIterator;
    o := it^.Next;
    WHILE o <> NIL DO BEGIN
      IF o^.IsA('MLCollection') THEN  (*dispose its elements rec.*)
        MLCollection(o)^.DisposeElements;
      Dispose(o, Done);
      o := it^.Next;
    END; (*WHILE*)
    Dispose(it, Done);
    Clear;
  END; (*MLCollectionObj.DisposeElements*)


(*=== MLIterator ===*)


  CONSTRUCTOR MLIteratorObj.Init;
  BEGIN
    INHERITED Init;
    Register('MLIterator', 'MLObject');
  END; (*MLIteratorObj.Init*)

  DESTRUCTOR MLIteratorObj.Done;
  BEGIN
    INHERITED Done;
  END; (*MLIteratorObj.Done*)


(*--- default implementation of "abstract" method ---*)

  FUNCTION MLIteratorObj.Next: MLObject;
  BEGIN
    AbstractMethodError('MLIteratorObj.Next');
    Next := NIL;
  END; (*MLIteratorObj.Next*)


END. (*MLColl*)


 

