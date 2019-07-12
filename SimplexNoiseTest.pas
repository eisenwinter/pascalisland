{
  SimplexNoiseTests
  @author(Jan <jan@subkonstrukt.at>)
}
PROGRAM SimplexNoiseTests;
USES SimplexNoise;

VAR
  sn : SimplexNoiseGenerator;
  x,y : INTEGER;
BEGIN
  Randomize;
  sn := NewSimplexNoiseGenerator(500/15,0,1,10,7,0.05);
  FOR x := 0 TO 15 DO BEGIN
    FOR y := 0 tO 15 DO BEGIN
      Write(sn^.Scaled(x,y) : 0 : 1, ' |');
    END;
    WriteLn;
  END;

END.
