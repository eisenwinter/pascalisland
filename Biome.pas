{
  Biome
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @abstract(basic biomes)
  @created(2017-07-10)
  contains the basic type definition of a landpatch as well as
  mapping the patch to the correct biome
  @created(2017-07-10)
}
UNIT Biome;

INTERFACE
  USES
    MLObj;
  TYPE
    (* biome types according to http://plantphys.info/plant_biology/climate.shtml
     and https://www2.estrellamountain.edu/faculty/farabee/biobk/BioBookcommecosys.html *)
    TBiomeType = (NotSet, Ocean, Marsh, Ice, Lake, Beach, Shrubland,
                  Snow, Tundra, Bare, Scorched, Taiga, TemperateDesert,
                  TemperateRainForest, TemperateDecidousForest, Grassland,
                  TropicalRainForest, TropicalSeasonalForest, SubtropicalDessert);

    BasicGeoData = ^TBasicGeoData;
    TBasicGeoData = OBJECT(MLObjectObj)
      PRIVATE
        _elevation, _moisture : REAL;
        _ocean, _coast, _water : BOOLEAN;
        _biome : TBiomeType;

      (* once height is known, this decides the biome type by moisture *)
      PROCEDURE HighRegions;
      PROCEDURE MidRegions;
      PROCEDURE LowerRegions;
      PROCEDURE FlatRegions;

      PUBLIC
        FUNCTION GetElevation : REAL;
        FUNCTION GetMoisture : REAL;
        PROCEDURE SetElevation(e : REAL);
        PROCEDURE SetMoisture(m : REAL);

        FUNCTION GetIsOcean : BOOLEAN;
        FUNCTION GetIsCoast : BOOLEAN;
        FUNCTION GetIsWater : BOOLEAN;
        FUNCTION GetBiome : TBiomeType;

        PROCEDURE SetIsOcean(o : BOOLEAN);
        PROCEDURE SetIsCoast(c : BOOLEAN);
        PROCEDURE SetIsWater(w : BOOLEAN);

        PROCEDURE CreateBiomeType;

        CONSTRUCTOR Init;
        CONSTRUCTOR InitValue(moisture, elevation : REAL);
        DESTRUCTOR Done; VIRTUAL;
    END;

    FUNCTION NewBasicGeoData : BasicGeoData;

IMPLEMENTATION
FUNCTION NewBasicGeoData : BasicGeoData;
VAR
  bgd : BasicGeoData;
BEGIN
  New(bgd, Init);
  NewBasicGeoData := bgd;
END;
FUNCTION TBasicGeoData.GetElevation : REAL;
BEGIN
  GetElevation := _elevation;
END;

FUNCTION TBasicGeoData.GetMoisture : REAL;
BEGIN
  GetMoisture := _moisture;
END;

PROCEDURE TBasicGeoData.SetElevation(e : REAL);
BEGIN
  _elevation := e;
END;

PROCEDURE TBasicGeoData.SetMoisture(m : REAL);
BEGIN
  _moisture := m;
END;

FUNCTION TBasicGeoData.GetBiome : TBiomeType;
BEGIN
  GetBiome := _biome;
END;

FUNCTION TBasicGeoData.GetIsOcean : BOOLEAN;
BEGIN
  GetIsOcean := _ocean;
END;

FUNCTION TBasicGeoData.GetIsCoast : BOOLEAN;
BEGIN
  GetIsCoast := _coast;
END;

FUNCTION TBasicGeoData.GetIsWater : BOOLEAN;
BEGIN
  GetIsWater := _water;
END;

PROCEDURE TBasicGeoData.SetIsOcean(o : BOOLEAN);
BEGIN
  _ocean := o;
END;

PROCEDURE TBasicGeoData.SetIsCoast(c : BOOLEAN);
BEGIN
  _coast := c;
END;

PROCEDURE TBasicGeoData.SetIsWater(w : BOOLEAN);
BEGIN
  _water := w;
END;

PROCEDURE TBasicGeoData.HighRegions;
BEGIN
  IF _moisture > 0.5 THEN
    _biome := Snow
  ELSE IF _moisture > 0.33 THEN
    _biome := Tundra
  ELSE IF _moisture > 0.16 THEN
    _biome := Bare
  ELSE
    _biome := Scorched;
END;

PROCEDURE TBasicGeoData.MidRegions;
BEGIN
  IF _moisture > 0.66 THEN
    _biome := Taiga
  ELSE IF _moisture > 0.33 THEN
    _biome := Shrubland
  ELSE
    _biome := TemperateDesert;
END;

PROCEDURE TBasicGeoData.LowerRegions;
BEGIN
  IF _moisture > 0.83 THEN
    _biome := TemperateRainForest
  ELSE IF _moisture > 0.50 THEN
    _biome := TemperateDecidousForest
  ELSE IF _moisture > 0.16 THEN
    _biome := Grassland
  ELSE
    _biome := TemperateDesert;
END;

PROCEDURE TBasicGeoData.FlatRegions;
BEGIN
  IF _moisture > 0.66 THEN
    _biome := TemperateRainForest
  ELSE IF _moisture > 0.33 THEN
    _biome := TropicalSeasonalForest
  ELSE IF _moisture > 0.16 THEN
    _biome := Grassland
  ELSE
    _biome := SubtropicalDessert;
END;

PROCEDURE TBasicGeoData.CreateBiomeType;
BEGIN
  IF _biome = NotSet THEN BEGIN
    IF _ocean THEN
      _biome := Ocean
    ELSE IF _water THEN BEGIN
      IF _elevation < 0.1 THEN
        _biome := Marsh
      ELSE IF _elevation > 0.8 THEN
        _biome := Ice
      ELSE
        _biome := Lake;
    END (* water *)
    ELSE IF _coast THEN
      _biome := Beach
    ELSE IF _elevation > 0.8 THEN BEGIN
      HighRegions;
    END (* high regions > 0.8 *)
    ELSE IF _elevation > 0.6 THEN BEGIN
      MidRegions;
    END (* mid-regions > 0.6) *)
    ELSE IF _elevation > 0.3 THEN BEGIN
      LowerRegions;
    END (* lower lands  > 0.3 *)
    ELSE (* lowest regions *) BEGIN
      FlatRegions;
    END; (* lowest regions *)
  END;
END;

CONSTRUCTOR TBasicGeoData.Init;
BEGIN
  INHERITED Init;
  Register('BasicGeoData', 'MLObject');
  _biome := NotSet;
END;

CONSTRUCTOR TBasicGeoData.InitValue(moisture, elevation : REAL);
BEGIN
  Init;
  _moisture := moisture;
  _elevation := elevation;
  _biome := NotSet;
END;

DESTRUCTOR TBasicGeoData.Done;
BEGIN
  INHERITED Done;
END;

END.
