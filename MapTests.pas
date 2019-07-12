PROGRAM MapTests;


USES Map;

VAR
  m : MapPtr;
BEGIN
  Randomize;
  m := NewMap(32,32);
  m^.Seed;
  m^.WriteAsString;
END.
