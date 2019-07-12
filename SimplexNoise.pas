{
  SimplexNoise (2D only for now)
  @author(Jan Caspar <jan@subkonstrukt.at>)
  @abstract(simplex noise generator)
  @created(2017-07-10)
  Simplex Noise Generator, based on simplex demystified
  http://staffwww.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
  by Stefan Gustavson (stegu@itn.liu.se).
  @lastmod(2017-07-10)
}
UNIT SimplexNoise;

INTERFACE
USES
    MlObj, Math;
TYPE
    SimplexNoiseGenerator = ^TSimplexNoiseGenerator;
    TSimplexNoiseGenerator = OBJECT(MLObjectObj)
        PRIVATE
            TYPE
                ThreeDVec = RECORD
                    x : INTEGER;
                    y : INTEGER;
                    z : INTEGER;
                END;
                (* might wanna extend to 3d later so why not *)
                GRAARRAY = ARRAY[0..11] OF ThreeDVec;
                RANDOMIZEDARRAY = ARRAY[0..255] OF WORD;
                PERMARRAY = ARRAY[0..511] OF WORD;
            VAR
                _perm : PERMARRAY;
                _permMod : PERMARRAY;
                _grad : GRAARRAY;
                _frequency : REAL;
                _max : REAL;
                _min : REAL;
                _octaves : INTEGER;
                _persistence : REAL;
                _amplitude : REAL;
            FUNCTION Dot(d : ThreeDVec; x,y : REAL) : REAL;
            FUNCTION G2 : REAL;
            FUNCTION Raw(x,y : REAL) : REAL;
            PROCEDURE BuildGraArray;
            PROCEDURE BuildPermutations;
            FUNCTION Scale(val : REAL) : REAL;
        PUBLIC
            CONSTRUCTOR Init(freq, min, max, amp : REAL;  oct : INTEGER; pers : REAL);
            DESTRUCTOR Done; VIRTUAL;
            FUNCTION AsString: STRING; VIRTUAL;
            PROCEDURE WriteAsString; VIRTUAL;
            FUNCTION Scaled(x,y : INTEGER) : REAL; VIRTUAL;
    END;

    FUNCTION NewSimplexNoiseGenerator(freq, min, max, amp : REAL;  oct : INTEGER; pers : REAL) : SimplexNoiseGenerator;
    FUNCTION NewDefaultSimplexNoiseGenerator : SimplexNoiseGenerator;

IMPLEMENTATION

FUNCTION NewSimplexNoiseGenerator(freq, min, max, amp : REAL;  oct : INTEGER; pers : REAL) : SimplexNoiseGenerator;
VAR
    sn : SimplexNoiseGenerator;
BEGIN
    New(sn,Init(freq,min,max,amp,oct,pers));
    NewSimplexNoiseGenerator := sn;
END;

FUNCTION NewDefaultSimplexNoiseGenerator : SimplexNoiseGenerator;
VAR
    sn : SimplexNoiseGenerator;
BEGIN
    New(sn,Init(1,0,1,1,8,1));
    NewDefaultSimplexNoiseGenerator := sn;
END;

CONSTRUCTOR TSimplexNoiseGenerator.Init(freq, min, max, amp : REAL;  oct : INTEGER; pers : REAL);
BEGIN
    INHERITED Init;
    Register('SimplexNoiseGenerator', 'MLObject');
    _frequency := freq;
    _max := max;
    _amplitude := amp;
    _min := min;
    _octaves := oct;
    _persistence := pers;
    BuildGraArray;
    BuildPermutations;
END;

PROCEDURE TSimplexNoiseGenerator.BuildPermutations;
VAR
    i,q,n : INTEGER;
    p : RANDOMIZEDARRAY;
BEGIN
    FOR i := 0 TO High(RANDOMIZEDARRAY) DO
        p[i] := i;

    FOR i := 255 DOWNTO Low(RANDOMIZEDARRAY) DO BEGIN
        n := Floor((i+1) * Random);
        q := p[i];
        p[i] := p[n];
        p[n] := q;
    END;

    FOR i := 0 TO High(PERMARRAY) DO BEGIN
        _perm[i] := p[i AND 255];
        _permMod[i] := _perm[i] MOD 12;
    END;
END;

PROCEDURE TSimplexNoiseGenerator.BuildGraArray;
BEGIN
    _grad[0].x := 1;
    _grad[0].y := 1;
    _grad[0].z := 0;

    _grad[1].x := -1;
    _grad[1].y := 1;
    _grad[1].z := 0;

    _grad[2].x := 1;
    _grad[2].y := -1;
    _grad[2].z := 0;

    _grad[3].x := -1;
    _grad[3].y := -1;
    _grad[3].z := 0;

    _grad[4].x := 1;
    _grad[4].y := 0;
    _grad[4].z := 1;

    _grad[5].x := -1;
    _grad[5].y := 0;
    _grad[5].z := 1;

    _grad[6].x := 1;
    _grad[6].y := 0;
    _grad[6].z := -1;

    _grad[7].x := -1;
    _grad[7].y := 0;
    _grad[7].z := -1;

    _grad[8].x := 0;
    _grad[8].y := 1;
    _grad[8].z := 1;

    _grad[9].x := 0;
    _grad[9].y := -1;
    _grad[9].z := -1;

    _grad[10].x := 0;
    _grad[10].y := 1;
    _grad[10].z := -1;

    _grad[11].x := 0;
    _grad[11].y := -1;
    _grad[11].z := -1;
END;

DESTRUCTOR TSimplexNoiseGenerator.Done;
BEGIN
    INHERITED Done;
END;

FUNCTION TSimplexNoiseGenerator.G2 : REAL;
BEGIN
    G2 := (3-Sqrt(3))/6;
END;

FUNCTION TSimplexNoiseGenerator.Dot(d : ThreeDVec; x,y : REAL) : REAL;
VAR
    total : REAL;
BEGIN
    total := x * d.x;
    total := total + y * d.y;
    Dot := total;
END;

FUNCTION TSimplexNoiseGenerator.Raw(x,y : REAL) : REAL;
VAR
    xD,yD,xZ,yZ,s,t, tZ, nZ, tON, nON, tT, nT,
    offsetX1, offsetX2, offsetY1, offsetY2 : REAL;
    i,j,oI,oJ,ii,jj,giZ,giO,giT : INTEGER;
BEGIN
    s := (x+y) * 0.5 * (Sqrt(3)-1);
    i := Floor(x + s);
    j := Floor(y + s);
    t := (i + j) * G2;
    xD := i - t;
    yD := j - t;
    xZ := x - xD;
    yZ := y - yD;

    IF xZ > yZ THEN BEGIN
        oI := 1;
        oJ := 0;
    END ELSE BEGIN
        oI := 0;
        oJ := 1;
    END;

    offsetX1 := xZ - oI + G2;
    offsetY1 := yZ - oJ + G2;
    offsetX2 := xZ - 1 + 2 * G2;
    offsetY2 := yZ - 1 + 2 * G2;

    ii := i AND 255;
    jj := j AND 255;
    giZ := _permMod[ii + _perm[jj]];
    giO := _permMod[ii + oI + _perm[jj + oJ]];
    gIT := _permMod[ii + 1 + _perm[jj + 1]];

    tZ := 0.5 - xZ * xZ - yZ * yZ;
    IF tZ < 0 THEN BEGIN
        nZ := 0;
    END ELSE BEGIN
        nZ := tZ * tZ * tZ * tZ * Dot(_grad[giZ], xZ, yZ);
    END;
    tON := 0.5 - offsetX1 * offsetX1 - offsetY1 * offsetY1;
    IF tON < 0 THEN BEGIN
        nON := 0;
    END ELSE BEGIN
        nOn := tON * tON * tON * tON * Dot(_grad[giO], offsetX1, offsetY1);
    END;
    tT := 0.5 - offsetX2 * offsetX2 - offsetY2 * offsetY2;
    IF tT < 0 THEN BEGIN
        nT := 0
    END ELSE BEGIN
        nT := tT * tT * tT * tT * Dot(_grad[gIT], offsetX2, offsetY2);
    END;
    Raw := 70.14805770653952 * (nZ + nON + nT);
END;

FUNCTION TSimplexNoiseGenerator.Scale(val : REAL) : REAL;
BEGIN
    Scale := _min + ((val + 1) / 2) * (_max-_min);
END;

FUNCTION TSimplexNoiseGenerator.Scaled(x,y : INTEGER) : REAL;
VAR
    a,f,m,n : REAL;
    i : INTEGER;
BEGIN
    n := 0;
    m := 0;
    f := _frequency;
    a := _amplitude;
    FOR i := 0 TO (_octaves-1) DO BEGIN
        n := n + Raw(x * f, y * f) * a;
        m := m + a;
        a := a * _persistence;
        f := f * 2;
    END;
    Scaled := Scale(n / m);
END;

FUNCTION TSimplexNoiseGenerator.AsString: STRING;
BEGIN
    AsString := '[SimplexNoiseGenerator]';
END;

PROCEDURE TSimplexNoiseGenerator.WriteAsString;
BEGIN
    WriteLn(AsString);
END;
END.
