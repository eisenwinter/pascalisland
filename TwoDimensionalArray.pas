{
  TwoDimensionalArray
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @abstract(two dimensional array packed in one d. array)
  @created(2017-07-10)
  @lastmod(2017-07-10)
}
UNIT TwoDimensionalArray;

INTERFACE
USES
  MlObj;
TYPE
  GENERIC T2DArray<T> = OBJECT(MLObjectObj)
    PRIVATE
      _totalCells : LONGWORD;
      _freeCells : LONGWORD;
      _rows : INTEGER;
      _cols : INTEGER;
      _arr : ARRAY OF T;

    PUBLIC
      CONSTRUCTOR Init(r,c : INTEGER);
      CONSTRUCTOR InitQuad(q : INTEGER);
      DESTRUCTOR Done; VIRTUAL;

      FUNCTION FreeCells : INTEGER; VIRTUAL;
      FUNCTION CellCount: INTEGER; VIRTUAL;
      FUNCTION Height : INTEGER; VIRTUAL;
      FUNCTION Width : INTEGER; VIRTUAL;

      FUNCTION GetCell(id : INTEGER) : T; VIRTUAL;
      FUNCTION GetXY(x,y : INTEGER) : T; VIRTUAL;
      PROCEDURE SetCell(id : INTEGER; obj : T); VIRTUAL;
      PROCEDURE SetXY(x,y : INTEGER; obj : T); VIRTUAL;

      FUNCTION AsString: STRING; VIRTUAL;
      PROCEDURE WriteAsString; VIRTUAL;
      FUNCTION RemoveLast : T; VIRTUAL;
  END;

IMPLEMENTATION

CONSTRUCTOR T2DArray.Init(r,c : INTEGER);
BEGIN
  INHERITED Init;
  Register('2DArray', 'MLObject');
  _rows := r;
  _cols := c;
  _freeCells := r * c;
  _totalCells := _freeCells;
  SetLength(_arr,r * c);
END;

FUNCTION T2DArray.FreeCells : INTEGER;
BEGIN
  FreeCells := _freeCells;
END;

FUNCTION T2DArray.CellCount: INTEGER;
BEGIN
  CellCount := _totalCells;
END;

FUNCTION T2DArray.Height : INTEGER;
BEGIN
  Height := _rows - 1;
END;

FUNCTION T2DArray.Width: INTEGER;
BEGIN
  Width := _cols - 1;
END;


FUNCTION T2DArray.GetCell(id : INTEGER) : T;
BEGIN
  GetCell := _arr[id];
END;

FUNCTION T2DArray.RemoveLast : T;
VAR
  o : T;
BEGIN
  IF _totalCells > 0 THEN BEGIN
    o := _arr[_totalCells];
    Dec(_totalCells);
    RemoveLast := o;
  END ELSE
    RemoveLast := NIL;
END;

FUNCTION T2DArray.GetXY(x,y : INTEGER) : T;
BEGIN
  GetXY := _arr[x * _rows + y];
END;

PROCEDURE T2DArray.SetCell(id : INTEGER; obj : T);
BEGIN
  _arr[id] := obj;
END;

PROCEDURE T2DArray.SetXY(x,y : INTEGER; obj : T);
BEGIN
  _arr[x * _rows + y] := obj;
END;

CONSTRUCTOR T2DArray.InitQuad(q : INTEGER);
BEGIN
  Init(q,q);
END;

DESTRUCTOR T2DArray.Done;
BEGIN
  INHERITED Done;
END;

FUNCTION T2DArray.AsString: STRING;
VAR
  r, c : STRING;
BEGIN
  Str(_rows,r);
  Str(_cols,c);
  AsString := '[2DArray('+r+','+c+')]';
END;
PROCEDURE T2DArray.WriteAsString;
BEGIN
  WriteLn(AsString);
END;
END.
