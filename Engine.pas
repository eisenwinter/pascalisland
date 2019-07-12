{
  Engine
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @created(2017-07-10)
  @lastmod(2017-07-10)
}
UNIT Engine;

INTERFACE
USES MlObj, Biome, Windows, MLVect, Math;

  TYPE
    RectArray = ARRAY[0..5] OF TPoint;
    Tile = ^TTile;
    TTile = OBJECT(MLObjectObj)
      PRIVATE
        _geo : BasicGeoData; (* ATTENTION! DO NOT DIPOSE AS IT USED IN THE SEEDING GRID! *)
        _dataPoint : TPoint;
        _auxPoint : TPoint;
        _tileSize : WORD;
      PUBLIC
        CONSTRUCTOR Init(x,y : INTEGER; biome : BasicGeoData);
        DESTRUCTOR Done; VIRTUAL;
        FUNCTION X : INTEGER;
        FUNCTION Y : INTEGER;
        FUNCTION AuxX : INTEGER;
        FUNCTION AuxY : INTEGER;
        PROCEDURE SetAuxX(x : INTEGER);
        PROCEDURE SetAuxY(y : INTEGER);
        PROCEDURE SetSize(s : WORD);
        FUNCTION BiomeType : TBiomeType;
        FUNCTION DrawableArray : RectArray;
        FUNCTION CurrentTileSize : INTEGER;
        FUNCTION GetGeoData : BasicGeoData;
        FUNCTION IsWithinProjection(x,y : INTEGER) : BOOLEAN;

    END;
    TileEngine = ^TTileEngine;
    TTileEngine = OBJECT(MLObjectObj)
      PRIVATE
        _polyVector : MLVector;
        _rows, _cols : INTEGER;
        _currentlySelected : Tile;
      PUBLIC
        CONSTRUCTOR Init;
        DESTRUCTOR Done; VIRTUAL;
        PROCEDURE AddField(x,y : INTEGER; biome : BasicGeoData); VIRTUAL;
        PROCEDURE DrawTo(dc : HDC; width, height : INTEGER); VIRTUAL;
        FUNCTION Translate(x,y : INTEGER) : BasicGeoData; VIRTUAL;
    END;

IMPLEMENTATION

CONSTRUCTOR TTile.Init(x,y : INTEGER; biome : BasicGeoData);
BEGIN
  INHERITED Init;
  Register('Tile', 'MLObject');
  _geo := biome;
  _tileSize := 32;
  _dataPoint.x := Round(x * Sqrt(3)/2 * (_tileSize * 2)) + 1;
  _dataPoint.y := Round(y * _tileSize * 2 * (3/4)) + 1;
  _auxPoint.x := x;
  _auxPoint.y := y;
END;



DESTRUCTOR TTile.Done;
BEGIN
  INHERITED Done;
END;

FUNCTION TTile.BiomeType : TBiomeType;
BEGIN
  BiomeType := _geo^.GetBiome;
END;

FUNCTION TTile.X : INTEGER;
BEGIN
  IF Odd(_auxPoint.y) THEN
    X := _dataPoint.x + _tileSize + Round(Sqrt(3)/2 * _tileSize * 2) DIV 2
  ELSE
    X := _dataPoint.x + _tileSize;
END;

FUNCTION TTile.GetGeoData : BasicGeoData;
BEGIN
  GetGeoData := _geo;
END;

FUNCTION TTile.CurrentTileSize : INTEGER;
BEGIN
  CurrentTileSize := _tileSize;
END;

PROCEDURE TTile.SetSize(s : WORD);
BEGIN
  _tileSize := s;
  _dataPoint.x := Round(_auxPoint.x * Sqrt(3)/2 * (_tileSize * 2)) + 1;
  _dataPoint.y := Round(_auxPoint.y * _tileSize * 2 * (3/4)) + 1;
END;

FUNCTION TTile.DrawableArray: RectArray;
VAR
  p : RectArray;
  i : INTEGER;
BEGIN
  FOR i := 0 TO 5 DO BEGIN
    p[i].x := _tileSize + Round(_dataPoint.x + _tileSize * Cos(Pi / 180 * (60*i+30)));
    p[i].y := _tileSize + Round(_dataPoint.y + _tileSize * Sin(Pi / 180 * (60*i+30)));
    IF (Odd(_auxPoint.y)) THEN BEGIN
      p[i].x := p[i].x + Round(Sqrt(3)/2 * _tileSize * 2) DIV 2;
    END;
  END;
  DrawableArray := p;
END;

FUNCTION TTile.IsWithinProjection(x,y : INTEGER) : BOOLEAN;
VAR
  q,p,r,h : INTEGER;
BEGIN
  r := _tileSize DIV 2;
  h := Round(_tileSize * 2 * (3/4));
  q := Round(Abs(x - self.X));
  p := Round(Abs(y - self.Y));
  IF (q > r) OR (p > h) THEN BEGIN
    IsWithinProjection := false;
  END
  ELSE
    IsWithinProjection := 2 * (h DIV 2) * r - (h DIV 2) * q - r * p >= 0;
END;

FUNCTION TTile.Y : INTEGER;
BEGIN
  Y := _dataPoint.y  + _tileSize;
END;

PROCEDURE TTile.SetAuxX(x : INTEGER);
BEGIN
  _auxPoint.x := x;
END;

PROCEDURE TTile.SetAuxY(y : INTEGER);
BEGIN
  _auxPoint.y := y;
END;

FUNCTION TTile.AuxX : INTEGER;
BEGIN
  AuxX := _auxPoint.x;
END;

FUNCTION TTile.AuxY : INTEGER;
BEGIN
  AuxY := _auxPoint.y;
END;

CONSTRUCTOR TTileEngine.Init;
BEGIN
  INHERITED Init;
  Register('TileEngine', 'MLObject');
  _polyVector := NewMLVector;
  _rows := 0;
  _cols := 0;
  _currentlySelected := NIL;
END;

DESTRUCTOR TTileEngine.Done;
VAR
  i : INTEGER;
BEGIN
  FOR i := 1 TO _polyVector^.Size DO BEGIN
    Dispose(_polyVector^.GetAt(i),Done);
  END;
  Dispose(_polyVector,Done);
  INHERITED Done;
END;

PROCEDURE TTileEngine.AddField(x,y : INTEGER; biome : BasicGeoData);
VAR
  p : Tile;
BEGIN
  New(p,Init(x,y,biome));
  _polyVector^.Add(p);
  IF x > _cols THEN BEGIN
    _cols := x;
  END;
  IF y > _rows THEN BEGIN
    _rows := y;
  END;
END;

FUNCTION BiomeColor(t : TBiomeType) : LONGWORD;
VAR
  c : LONGWORD;
BEGIN
  CASE t OF
    Ocean: c :=  RGB(6, 64, 158);
    Marsh: c := RGB(149, 178, 21);
    Ice: c := RGB(247, 254, 255);
    Lake: c := RGB(0, 109, 198);
    Beach: c := RGB(252, 224, 123);
    Shrubland: c := RGB(198, 226, 142);
    Snow: c := RGB(198, 226, 142);
    Tundra: c := RGB(221, 198, 150);
    Bare: c := RGB(214, 221, 197);
    Scorched: c := RGB(201, 179, 161);
    Taiga: c := RGB(110, 204, 93);
    TemperateDesert: c := RGB(110, 204, 93);
    TemperateRainForest: c := RGB(14, 102, 5);
    TemperateDecidousForest: c := RGB(47, 163, 35);
    Grassland: c := RGB(73, 237, 23);
    TropicalRainForest: c:= RGB(6, 201, 77);
    TropicalSeasonalForest: c := RGB(76, 122, 36);
    SubtropicalDessert: c := RGB(172, 201, 66);
  END;
  BiomeColor := c;
END;

PROCEDURE TTileEngine.DrawTo(dc : HDC; width, height : INTEGER);
VAR
  j : INTEGER;
  ts : WORD;
  polyPen, oldPen: HPen;
  polyBrush, oldBrush: HBrush;
  c : Tile;
BEGIN
  width := width DIV _cols;
  height := height DIV _rows;
  IF width < height THEN
    ts := width
  ELSE
    ts := height;
  ts := ts DIV 2;
  FOR j := 1 TO _polyVector^.Size DO BEGIN
    c := Tile(_polyVector^.GetAt(j));
    c^.SetSize(ts);
    IF (_currentlySelected <> NIL) AND (_currentlySelected = c) THEN BEGIN
      polyPen := CreatePen(PS_SOLID, 2, RGB(219, 0, 0));
      oldPen := SelectObject(dc, polyPen);
    END ELSE BEGIN
      polyPen := CreatePen(PS_SOLID, 1, RGB(33, 22, 44));
      oldPen := SelectObject(dc, polyPen);
    END;
    polyBrush := CreateSolidBrush(BiomeColor(c^.BiomeType));
    oldBrush := SelectObject(dc, polyBrush);
    Windows.Polygon(dc, c^.DrawableArray, 6);

    { debug info only, display center points
    polyPen := CreatePen(PS_SOLID, 2, RGB(219, 0, 0));
    oldPen := SelectObject(dc, polyPen);
    Windows.Ellipse(dc,c^.X-2,c^.Y-2,c^.X+2,c^.Y+2);
    }
    SelectObject(dc, oldPen);
    SelectObject(dc, oldBrush);
    DeleteObject(polyPen);
    DeleteObject(polyBrush);
  END;

END;

FUNCTION TTileEngine.Translate(x,y : INTEGER) : BasicGeoData;
VAR
  i : INTEGER;
  d : BasicGeoData;
BEGIN
  d := NIL;
  i := 1;
  _currentlySelected := NIL;
  (* this is a cheap workarround for now - needs to be fixed!*)
  WHILE (d = NIL) AND (i <= _polyVector^.Size) DO BEGIN
    IF Tile(_polyVector^.GetAt(i))^.IsWithinProjection(x,y) THEN BEGIN
      d := Tile(_polyVector^.GetAt(i))^.GetGeoData;
      _currentlySelected := Tile(_polyVector^.GetAt(i));
    END;
    Inc(i);
  END;
  Translate := d;
END;

END.
