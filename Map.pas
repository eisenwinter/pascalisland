{
  Map
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @abstract(this holds the basic map)
  @created(2017-07-11)
  this holds and manages the basic tile map
  the map itself is composed of height and elevation
  to determine the biome type the current patch has
  while this is somewhat close to the real thing a further
  improvement would be to actually seed the water sources first
  and caculate winds to determine the moisture, but for now
  lets assume the moisture map generated somewhat symbolizes the wind

  as the island has no rivers for now it would be half trivial if watersources
  are spawned first to just follow the elevation downwards till it hits a
  sweetspot where the water cant escape and builds lakes or escapes into the ocean

  if water sources are not spawned first one could simply assume that all
  rivers go to the ocean, so the river just would have to go upwards from the beach
  till it hits maximum elevation, this might not seem so natural but might be
  really easy to implement, this could be used to generate a moisture map
  that matches the visuals
  @lastmod(2017-07-11)
}
UNIT Map;

INTERFACE
USES
  MlObj, TwoDimensionalArray, Biome, Engine,
  SimplexNoise, Math;

TYPE
  MapPtr = ^TMap;
  TMap = OBJECT(MLObjectObj)
    PRIVATE
      TYPE
        Tiles = ^TileArray;
        TileArray = SPECIALIZE T2DArray<BasicGeoData>;
      VAR
        _tiles : Tiles;
        _seeded : BOOLEAN;
        _gfx : TileEngine;

        PROCEDURE SeedElevation;
        PROCEDURE SeedMoisture;
      PUBLIC
        CONSTRUCTOR Init(width, height : INTEGER);
        DESTRUCTOR Done; VIRTUAL;
        PROCEDURE Seed; VIRTUAL;
        FUNCTION Gfx : TileEngine;
        FUNCTION AsString: STRING; VIRTUAL;
        PROCEDURE WriteAsString; VIRTUAL;
  END;
  FUNCTION NewMap(width,height : INTEGER) : MapPtr;
IMPLEMENTATION

FUNCTION NewMap(width,height : INTEGER) : MapPtr;
VAR
  ptr : MapPtr;
BEGIN
  New(ptr,Init(width,height));
  NewMap := ptr;
END;

CONSTRUCTOR TMap.Init(width, height : INTEGER);
BEGIN
  INHERITED Init;
  Register('Map', 'MLObject');
  New(_tiles,Init(width,height));
  _seeded := false;
  _gfx := NIL;
END;

DESTRUCTOR TMap.Done;
VAR

  x,y : INTEGER;
BEGIN
  FOR x := 0 TO _tiles^.Width DO BEGIN
    FOR y := 0 TO _tiles^.Height DO BEGIN
      Dispose(_tiles^.GetXY(x,y),Done);
    END;
  END;


  Dispose(_tiles,Done);
  IF _gfx <> NIL THEN
    Dispose(_gfx,Done);
  INHERITED Done;
END;

PROCEDURE TMap.SeedMoisture;
VAR
  sn : SimplexNoiseGenerator;
  x,y : INTEGER;
BEGIN
  sn := NewSimplexNoiseGenerator(50 DIV _tiles^.Height,0,1,1,3,3);
  FOR x := 0 TO _tiles^.Width DO BEGIN
    FOR y := 0 TO _tiles^.Height DO BEGIN
      _tiles^.GetXY(x,y)^.SetMoisture(sn^.Scaled(x,y));
      IF _tiles^.GetXY(x,y)^.GetMoisture > 0.86 THEN
        _tiles^.GetXY(x,y)^.SetIsWater(true);
    END;
  END;
  Dispose(sn,Done);
END;

FUNCTION TMap.Gfx : TileEngine;
VAR
  x,y : INTEGER;
BEGIN
  IF _seeded AND (_gfx = NIL) THEN BEGIN
    New(_gfx,Init);
    FOR x := 0 TO _tiles^.Width DO BEGIN
      FOR y := 0 TO _tiles^.Height DO BEGIN
        _gfx^.AddField(x,y,_tiles^.GetXY(x,y));
      END;
    END;
  END;
  Gfx := _gfx;
END;

PROCEDURE TMap.SeedElevation;
VAR
  sn : SimplexNoiseGenerator;
  midpointGardient : REAL;
  curField : BasicGeoData;
  centerX, centerY, x, y, dx, dy, center : INTEGER;
BEGIN
  sn := NewSimplexNoiseGenerator(200 DIV _tiles^.Height,0,1,10,7,0.05);
  centerX := Ceil(_tiles^.Width);
  centerY := Ceil(_tiles^.Height);
  FOR x := 0 TO _tiles^.Width DO BEGIN
    FOR y := 0 TO _tiles^.Height DO BEGIN
      curField := _tiles^.GetXY(x,y);
      (* its an island so its surrounded by an ocean ?! =P *)
      IF (x = 0) OR (y = 0) OR (x = _tiles^.Width) OR (y = _tiles^.Height) THEN BEGIN
        curField^.SetElevation(0);
        curField^.SetIsOcean(true);
        curField^.SetIsWater(true);
      END ELSE BEGIN
        dx := (centerX - x) * (centerX - x);
        dy := (centerY - y) * (centerY - y);
        center := Floor(Sqrt(dX+dY) / 64);
        midpointGardient := sn^.Scaled(x,y)-center;
        curField^.SetElevation(midpointGardient);
      END;
    END;
  END;
  Dispose(sn,Done);
END;

PROCEDURE TMap.Seed;
VAR
   x,y : INTEGER;
BEGIN
  FOR x := 0 TO _tiles^.Width DO BEGIN
    FOR y := 0 TO _tiles^.Height DO BEGIN
      _tiles^.SetXY(x,y,NewBasicGeoData);
    END;
  END;
  SeedMoisture;
  SeedElevation;
  (* creates biomes *)
  FOR x := 0 TO _tiles^.Width DO BEGIN
    FOR y := 0 TO _tiles^.Height DO BEGIN
      _tiles^.GetXY(x,y)^.CreateBiomeType;
    END;
  END;

  _seeded := true;
END;

FUNCTION TMap.AsString: STRING;
BEGIN
  IF _seeded THEN
    AsString := '[seeded Map]'
  ELSE
    AsString := '[unseeded Map]';
END;

PROCEDURE TMap.WriteAsString;
VAR
  x,y : INTEGER;
BEGIN
  IF _seeded THEN BEGIN
    Write('| ');
    FOR x := 0 TO _tiles^.Width DO BEGIN
      FOR y := 0 TO _tiles^.Height DO BEGIN
        Write(_tiles^.GetXY(x,y)^.GetBiome, '(');
        Write(_tiles^.GetXY(x,y)^.GetMoisture :0 : 2, '%,');
        Write(_tiles^.GetXY(x,y)^.GetElevation :0 : 2, 'm%)');
      END;
      WriteLn;
    END;
  END ELSE BEGIN
    WriteLn('Unseeded Map');
  END;
END;
END.
