(*MLVect:                                              MiniLib V.4, 2004
  ------
  Classes MLVector and MLVectorIterator.
========================================================================*)
UNIT MLVect;

INTERFACE

  USES
    MLObj, MLColl;

  TYPE

    MLObjectArray    = ARRAY [1..1] OF MLObject;
    MLObjectArrayPtr = ^MLObjectArray;

    MLVectorIterator = ^MLVectorIteratorObj;  (*full declaration below MLVector*)


(*=== class MLVector ===*)

    MLVector = ^MLVectorObj;
    MLVectorObj = OBJECT(MLCollectionObj)

      curCap:   INTEGER;          (*cur. capacity = space for elements*)
      curSize:  INTEGER;          (*cur. number of elements <= curCap*)
      elements: MLObjectArrayPtr; (*dyn. alloc. array of MLObject pointers*)

      CONSTRUCTOR Init;
      DESTRUCTOR Done; VIRTUAL;

(*--- overridden "abstract" methods ---*)

      FUNCTION Size: INTEGER; VIRTUAL;
      (*returns number of elements in collection*)

      PROCEDURE Add(o: MLObject); VIRTUAL;
      (*adds element at right end*)

      FUNCTION Remove(o: MLObject): MLObject; VIRTUAL;
      (*removes first element = o, shifts rest to the left
        and returns removed element*)

      FUNCTION Contains(o: MLObject): BOOLEAN; VIRTUAL;
      (*returns whether collection contains an element = o*)

      PROCEDURE Clear; VIRTUAL;
      (*removes all elements WITHOUT disposing them*)

      FUNCTION NewIterator: MLIterator; VIRTUAL;
      (*returns a vector iterator which has to be disposed after usage*)

(*--- new methods ---*)

      PROCEDURE SetAt(index: INTEGER; o: MLObject); VIRTUAL;
      (*sets element at index*)

      FUNCTION GetAt(index: INTEGER): MLObject; VIRTUAL;
      (*returns element at index*)

      FUNCTION IndexOf(o: MLObject): INTEGER; VIRTUAL;
      (*returns first index for element = o or 0*)

      PROCEDURE InsertAt(index: INTEGER; o: MLObject); VIRTUAL;
      (*inserts object at the given index, shifts rest to the right*)

      FUNCTION RemoveAt(index: INTEGER): MLObject; VIRTUAL;
      (*removes object at index and returns removed object*)

      PROCEDURE Sort; VIRTUAL;
      (*sorts elements*)

    PRIVATE

      PROCEDURE CheckIndex(index: INTEGER);
      PROCEDURE IncreaseCapacity;

    END; (*OBJECT*)


(*=== class MLVectorIterator ===*)

  (*MLVectorIterator = ^MLVectorIteratorObj;  (*see declaration above*)
    MLVectorIteratorObj = OBJECT(MLIteratorObj)

      v:      MLVector; (*vector to iterate over*)
      curIdx: INTEGER;  (*current index in v*)

      CONSTRUCTOR Init(vect: MLVector);
      DESTRUCTOR Done; VIRTUAL;

(*--- implementation of "abstract" method ---*)

      FUNCTION Next: MLObject; VIRTUAL;
      (*returns next element or NIL if "end of" collection reached*)

    END; (*OBJECT*)


  FUNCTION NewMLVector: MLVector;


(*======================================================================*)
IMPLEMENTATION

  USES
    MetaInfo;


  FUNCTION NewMLVector: MLVector;
    VAR
      v: MLVector;
  BEGIN
    New(v, Init);
    NewMLVector := v;
  END; (*NewMLVector*)


(*=== class MLVector ===*)


  PROCEDURE MLVectorObj.CheckIndex(index: INTEGER);
    VAR
      is, css: STRING;
  BEGIN
    IF (index < 1) OR (index > curSize) THEN BEGIN
      Str(index,   is);
      Str(curSize, css);
      Error('range error detected in MLVector.CheckIndex, index ' + is +
            ' is not in [1 .. ' + css + ']');
    END; (*IF*)
  END; (*MLVectorObj.CheckIndex*)

  PROCEDURE MLVectorObj.IncreaseCapacity;
    VAR
      oldCap, newCap: LONGINT;
      newElements:    MLObjectArrayPtr;
      i:              INTEGER;
  BEGIN
    Assert(curSize = curCap, 'no need to increase capacity of MLVector');
    oldCap := curCap;
    newCap := oldCap * 2;
    IF newCap > 16382 THEN BEGIN (*max. for GetMem= 16382*4 = 65528*)
      newCap := 16382;
      IF newCap = oldCap THEN
        Error('no further incr. of capacity possible' +
              ', max. 16382 reached');
    END; (*IF*)
    GetMem(newElements, newCap * SizeOf(MLObject));
    FOR i := 1 TO oldCap DO BEGIN
      (*$R-*)
      newElements^[i] := elements^[i];
      (*$R+*)
    END; (*FOR*)
    FreeMem(elements, oldCap * SizeOf(MLObject));
    elements := newElements;
    curCap := newCap;
  END; (*MLVectorObj.IncreaseCapacity*)


  CONSTRUCTOR MLVectorObj.Init;
  BEGIN
    INHERITED Init;
    Register('MLVector', 'MLCollection');
    curCap  := 10;
    curSize :=  0;
    GetMem(elements, LONGINT(curCap) * SizeOf(MLObject));
  END; (*MLVectorObj.Init*)

  DESTRUCTOR MLVectorObj.Done;
  BEGIN
    FreeMem(elements, LONGINT(curCap) * SizeOf(MLObject));
    INHERITED Done;
  END; (*MLVectorObj.Done*)


  (*--- implementations of "abstract" mehtods ---*)

  FUNCTION MLVectorObj.Size: INTEGER;
  BEGIN
    Size := curSize;
  END; (*MLVectorObj.Size*)

  PROCEDURE MLVectorObj.Add(o: MLObject);
  BEGIN
    IF curSize = curCap THEN
      IncreaseCapacity;
    curSize := curSize + 1;
    (*$R-*)
    elements^[curSize] := o;
    (*$R+*)
  END; (*MLVectorObj.Add*)

  FUNCTION MLVectorObj.Remove(o: MLObject): MLObject;
    VAR
      index: INTEGER;
  BEGIN
    index := IndexOf(o);
    IF index = 0 THEN
      Remove := NIL
    ELSE
      Remove := RemoveAt(index);
  END; (*MLVectorObj.Remove*)

  FUNCTION MLVectorObj.Contains(o: MLObject): BOOLEAN;
  BEGIN
    Contains := IndexOf(o) > 0;
  END; (*MLVectorObj.Contains*)

  PROCEDURE MLVectorObj.Clear;
  BEGIN
    curSize := 0;
  END; (*MLVectorObj.Clear*)

  FUNCTION MLVectorObj.NewIterator: MLIterator;
    VAR
      it: MLVectorIterator;
  BEGIN
    New(it, Init(@SELF));
    NewIterator := it;
  END; (*MLVectorObj.NewIterator*)


(*--- new mehtods ---*)

  PROCEDURE MLVectorObj.SetAt(index: INTEGER; o: MLObject);
  BEGIN
    CheckIndex(index);
    (*$R-*)
    elements^[index] := o;
    (*$R+*)
  END; (*MLVectorObj.SetAt*)

  FUNCTION MLVectorObj.GetAt(index: INTEGER): MLObject;
    VAR
      o: MLObject;
  BEGIN
    CheckIndex(index);
    (*$R-*)
    o := elements^[index];
    (*$R+*)
    GetAt := o;
  END; (*MLVectorObj.SetAt*)

  FUNCTION MLVectorObj.IndexOf(o: MLObject): INTEGER;
    VAR
      elem: MLObject;
      i:    INTEGER;
  BEGIN
    FOR i := 1 TO curSize DO BEGIN
      (*$R-*)
      elem := elements^[i];
      (*$R+*)
      IF elem^.IsEqualTo(o) THEN BEGIN
        IndexOf := i;
        Exit;
      END; (*IF*)
    END; (*FOR*)
    IndexOf := 0; (*not found*)
  END; (*MLVectorObj.IndexOf*)

  PROCEDURE MLVectorObj.InsertAt(index: INTEGER; o: MLObject);
    VAR
      i: INTEGER;
  BEGIN
    CheckIndex(index);
    IF curSize = curCap THEN
      IncreaseCapacity;
    FOR i := curSize + 1 DOWNTO index + 1 DO BEGIN (*shift elements right*)
      (*$R-*)
      elements^[i] := elements^[i - 1];
      (*$R+*)
    END; (*FOR*)
    (*$R-*)
    elements^[index] := o;
    (*$R+*)
    curSize := curSize + 1;
  END; (*MLVectorObj.InsertAt*)

  FUNCTION MLVectorObj.RemoveAt(index: INTEGER): MLObject;
    VAR
      i: INTEGER;
      o: MLObject;
  BEGIN
    CheckIndex(index);
    (*$R-*)
    o := elements^[index];
    (*$R+*)
    FOR i := index TO size - 1 DO BEGIN (*shift elements left*)
      (*$R-*)
      elements^[i] := elements^[i + 1];
      (*$R+*)
    END; (*FOR*)
    curSize := curSize - 1;
    RemoveAt := o;
  END; (*MLVectorObj.RemoveAt*)

  PROCEDURE MLVectorObj.Sort; (*standard quicksort*)

    PROCEDURE Partition(l, r: INTEGER);
      VAR
        mo, h: MLObject; (*mo is the middle object*)
        i, j:  INTEGER;
    BEGIN
      (*$R-*)
      i := l;
      j := r;
      mo := elements^[(l + r) DIV 2];
      REPEAT
        WHILE elements^[i]^.IsLessThan(mo) DO
          i := i + 1;
        WHILE mo^.IsLessThan(elements^[j]) DO
          j := j - 1;
        IF i <= j THEN BEGIN
          IF i <> j THEN BEGIN
            h := elements^[i];
            elements^[i] := elements^[j];
            elements^[j] := h;
          END; (*IF*)
          i := i + 1;
          j := j - 1;
        END; (*IF*)
      UNTIL i > j;
      IF l < j THEN
        Partition(l, j);
      IF i < r THEN
        Partition(i, r);
      (*$R+*)
    END; (*Partition*)

  BEGIN (*MLVectorObj.Sort*)
    Partition(1, curSize);
  END; (*MLVectorObj.Sort*)


 (*=== MLVectorIterator ===*)
 

  CONSTRUCTOR MLVectorIteratorObj.Init(vect: MLVector);
  BEGIN
    INHERITED Init;
    Register('MLVectorIterator', 'MLIterator');
    v      := vect;
    curIdx := 1;
  END; (*MLVectorIteratorObj.Init*)

  DESTRUCTOR MLVectorIteratorObj.Done;
  BEGIN
    INHERITED Done;
  END; (*MLVectorIteratorObj.Done*)


(*--- implementation of "abstract" method ---*)

  FUNCTION MLVectorIteratorObj.Next: MLObject;
    VAR
      o: MLObject;
  BEGIN
    o := NIL;
    WHILE (curIdx <= v^.Size) AND (o = NIL) DO BEGIN
      o := v^.GetAt(curIdx);
      curIdx := curIdx + 1;
    END; (*WHILE*)
    Next := o;
  END; (*MLVectorIteratorObj.Next*)


END. (*MLVect*)


 

