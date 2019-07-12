{
  Environment
  @author(Name <jan@subkonstrukt.at>)
  @abstract(handles the environment of the island)
  @created(2017-07-11)
  while having a island consisting of biomes is nice,
  a island is so much more then just biomes. there are some
  inevitable things that need to happend on a island, day-night circles
  weather (tough its not used  for the biome creation which could be adapted)
  and of couse a island would need a name
  @lastmod(2017-07-11)
}
UNIT Environment;

INTERFACE
USES
  MlObj, OSBridge,Windows, Map, Engine, Biome;

TYPE
  IslandEnvironment = ^TEnvironment;
  TTimeCircle = (Day, Dusk, Dawn, Night);
  TWeatherEvents = (Sunny, Windy, Rain, Thunderstorm, Hail);
  TEnvironment = OBJECT(MLObjectObj)
    PRIVATE
      _islandName : STRING;
      _currentMap : MapPtr;
    PUBLIC
      CONSTRUCTOR Init(name : STRING);
      DESTRUCTOR Done; VIRTUAL;
      PROCEDURE RendnerMap(wp : WindowPeer; width, height : INTEGER); VIRTUAL;
      PROCEDURE RendnerInfo(wp : WindowPeer); VIRTUAL;
      PROCEDURE ClickedOn(x,y : INTEGER); VIRTUAL;
      FUNCTION GetName : STRING; VIRTUAL;
      PROCEDURE Hovering(x,y : INTEGER); VIRTUAL;
  END;

IMPLEMENTATION

CONSTRUCTOR TEnvironment.Init(name : STRING);
BEGIN
  INHERITED Init;
  Register('Environment', 'MLObject');
  _islandName := name;
  _currentMap := NewMap(16,16);
  _currentMap^.Seed;
END;

DESTRUCTOR TEnvironment.Done;
BEGIN
  Dispose(_currentMap,Done);
  INHERITED Done;
END;

PROCEDURE TEnvironment.RendnerMap(wp : WindowPeer; width, height : INTEGER);
VAR
  v : TileEngine;
  dc : HDC;
BEGIN
  dc := wp^.dc;
  v := _currentMap^.Gfx;
  IF v <> NIL THEN BEGIN
    v^.DrawTo(dc, width,height);
  END;
END;

PROCEDURE TEnvironment.ClickedOn(x,y : INTEGER);
VAR
  v : TileEngine;
  d : BasicGeoData;
BEGIN
  v := _currentMap^.Gfx;
  IF  v <> NIL THEN BEGIN
    WriteLn('Clicked yey!');
    d := v^.Translate(x,y);
    IF d <> NIL THEN
      WriteLn('found! ', d^.GetBiome);
  END;
END;

PROCEDURE TEnvironment.Hovering(x,y : INTEGER);
VAR
  v : TileEngine;
BEGIN

END;

PROCEDURE TEnvironment.RendnerInfo(wp : WindowPeer);
VAR
  p : Point;
BEGIN
  p.x := 5;
  p.y := 5;

END;

FUNCTION TEnvironment.GetName : STRING;
BEGIN
  GetName := _islandName;
END;

END.
