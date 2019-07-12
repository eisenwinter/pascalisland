{
  NameGenerator
  @author(Name <jan@subkonstrukt.at>)
  @abstract(a short description)
  @created(2017-07-07)
  this is supposed to give somehow usefull names for things that could spawn
  inspired by http://www.godpatterns.com/2005/09/name-generators-for-npcs-to-populate.html
  the plants are fixed and are based on the wikipedia article about fake plants(! lel)
  @lastmod(2017-07-10)
}
UNIT NameGen;

INTERFACE
USES
    MlObj;
TYPE
    NameGenerator = ^TNameGenerator;
    TNameGenerator = OBJECT(MLObjectObj)
        PRIVATE
            _plantNames : ARRAY[0..117] OF STRING;
            _animalEndings : ARRAY[0..13] OF STRING;
            _landEndings : ARRAY[0..24] OF STRING;
            _v : ARRAY[0..4] OF CHAR;
            _c : ARRAY[0..19] OF CHAR;
            FUNCTION Consonant : CHAR;
            FUNCTION Vocal : CHAR;
            FUNCTION LocationEnding : STRING;
            FUNCTION AnimalEnding : STRING;
            PROCEDURE SeedFakePlants;
            PROCEDURE SeedStringChains;
            FUNCTION BuildMarkovChain : STRING;
        PUBLIC
            CONSTRUCTOR Init;
            DESTRUCTOR Done; VIRTUAL;
            FUNCTION LocationName : STRING;
            FUNCTION AnimalName : STRING;
            FUNCTION PlantName : STRING;
    END;

    FUNCTION NewNameGenerator : NameGenerator;

IMPLEMENTATION
FUNCTION NewNameGenerator : NameGenerator;
VAR
  n : NameGenerator;
BEGIN
  New(n,Init);
  NewNameGenerator := n;
END;
CONSTRUCTOR TNameGenerator.Init;
BEGIN
    INHERITED Init;
    Register('NameGenerator', 'MLObject');
    SeedFakePlants;
    SeedStringChains;
END;

FUNCTION TNameGenerator.LocationName : STRING;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_landEndings));
  LocationName := BuildMarkovChain + _landEndings[i];
END;

FUNCTION TNameGenerator.AnimalName : STRING;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_animalEndings));
  AnimalName := BuildMarkovChain + _animalEndings[i];
END;

FUNCTION TNameGenerator.PlantName : STRING;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_plantNames));
  PlantName := _plantNames[i];
END;

DESTRUCTOR TNameGenerator.Done;
BEGIN
  INHERITED Done;
END;

FUNCTION TNameGenerator.BuildMarkovChain : STRING;
VAR
  len,i : INTEGER;
  chain : STRING;
BEGIN
  chain := '';
  len := Random(2) + 1;
  FOR i := 1 TO len DO BEGIN
    chain := chain + Consonant + Vocal + Consonant;
  END;
  chain[1] := upCase(chain[1]);
  BuildMarkovChain := chain;
END;

FUNCTION TNameGenerator.Consonant : CHAR;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_c));
  Consonant := _c[i];
END;
FUNCTION TNameGenerator.Vocal : CHAR;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_v));
  Vocal := _v[i];
END;
FUNCTION TNameGenerator.LocationEnding : STRING;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_landEndings));
  LocationEnding := _landEndings[i];
END;
FUNCTION TNameGenerator.AnimalEnding : STRING;
VAR
  i : INTEGER;
BEGIN
  i := Random(High(_animalEndings));
  AnimalEnding := _animalEndings[i];
END;

PROCEDURE TNameGenerator.SeedStringChains;
BEGIN
  _animalEndings[0] := 'avis'; _animalEndings[1] := 'cetus';
  _animalEndings[2] := 'derm'; _animalEndings[3] := 'erpeton';
  _animalEndings[4] := 'felis'; _animalEndings[5] := 'ia';
  _animalEndings[6] := 'maia'; _animalEndings[7] := 'mimus';
  _animalEndings[8] := 'morph'; _animalEndings[9] := 'zoa';
  _animalEndings[10] := 'nyx'; _animalEndings[11] := 'pus';
  _animalEndings[12] := 'odon'; _animalEndings[13] := 'lophus';

  _landEndings[0] := 'bank'; _landEndings[1] := 'barrow';
  _landEndings[2] := 'cliff'; _landEndings[3] := 'crook';
  _landEndings[4] := 'down'; _landEndings[5] := 'hurst';
  _landEndings[6] := 'tor'; _landEndings[7] := 'burn';
  _landEndings[8] := 'mere'; _landEndings[9] := 'latch';
  _landEndings[10] := 'marsh'; _landEndings[11] := 'ness';
  _landEndings[12] := 'wick'; _landEndings[13] := 'thorpe';
  _landEndings[14] := 'cote'; _landEndings[15] := 'sett';
  _landEndings[16] := 'combe'; _landEndings[17] := 'croft';
  _landEndings[18] := 'thwaite'; _landEndings[19] := 'minster';
  _landEndings[20] := 'kirk'; _landEndings[21] := 'heath';
  _landEndings[22] := 'lea'; _landEndings[23] := 'ford';
  _landEndings[24] := 'stoke'; _landEndings[24] := 'ton';

  _v[0] := 'a'; _v[1] := 'e'; _v[2] := 'i'; _v[3] := 'o'; _v[4] := 'u';
  _c[0] := 'b'; _c[1] := 'c'; _c[2] := 'd'; _c[3] := 'f'; _c[4] := 'g';
  _c[5] := 'h'; _c[6] := 'j'; _c[7] := 'k'; _c[8] := 'l'; _c[9] := 'n';
  _c[10] := 'm'; _c[11] := 'p'; _c[12] := 'r'; _c[13] := 't'; _c[14] := 's';
  _c[15] := 'v'; _c[16] := 'y'; _c[17] := 'z'; _c[18] := 'x'; _c[19] := 'w';
END;

PROCEDURE TNameGenerator.SeedFakePlants;
BEGIN
  (* well yeah those are static whatever *)
 _plantNames[0] := 'Adele'; _plantNames[1] := 'Aechmea asenionii '; _plantNames[2] := 'Akarso'; _plantNames[3] := 'Alraune'; _plantNames[4] := 'Arctus Mandibus'; _plantNames[5] := 'Audrey Jr.'; _plantNames[6] := 'Aum plant'; _plantNames[7] := 'Avern'; _plantNames[8] := 'Axis '; _plantNames[9] := 'Bat-thorn'; _plantNames[10] := 'Biollante'; _plantNames[11] := 'Black Mercy'; _plantNames[12] := 'Blister plants'; _plantNames[13] := 'Blood Grass '; _plantNames[14] := 'Blood Orchid '; _plantNames[15] := 'Bloodflower'; _plantNames[16] := 'Bob'; _plantNames[17] := 'Broxlorthian Squidflower'; _plantNames[18] := 'Cactacae'; _plantNames[19] := 'Candypop Bud'; _plantNames[20] := 'Carnifern'; _plantNames[21] := 'Chamalla'; _plantNames[22] := 'Chuck the Plant'; _plantNames[23] := 'Cleopatra'; _plantNames[24] := 'Crazee Dayzees'; _plantNames[25] := 'Cow plant (Laganaphyllis simnovorii) '; _plantNames[26] := 'Deathbottle'; _plantNames[27] := 'Dyson tree'; _plantNames[28] := 'Echo Flower Elowan'; _plantNames[29] := 'Eon Rose '; _plantNames[30] := 'Flaahgra'; _plantNames[31] := 'Flossberry'; _plantNames[32] := 'Flower of Life '; _plantNames[33] := 'Flowey Genesis Trees'; _plantNames[34] := 'Gijera'; _plantNames[35] := 'Gingold'; _plantNames[36] := 'Giraluna'; _plantNames[37] := 'Gloria Margagora GQuan Eth'; _plantNames[38] := 'Carter Green, the Vegetable Man'; _plantNames[39] := 'Grippers'; _plantNames[40] := 'Happy plant'; _plantNames[41] := 'Hearts Desire'; _plantNames[42] := 'Hybernia tree'; _plantNames[43] := 'Inkvine'; _plantNames[44] := 'Integral Trees'; _plantNames[45] := 'Juran'; _plantNames[46] := 'Jurai Royal Trees'; _plantNames[47] := 'Jacks Beanstalk'; _plantNames[48] := 'Katterpod Trappersnappers'; _plantNames[49] := 'Kite-Eating Tree'; _plantNames[50] := 'Krynoid'; _plantNames[51] := 'Kyrt'; _plantNames[52] := 'Lashers'; _plantNames[53] := 'Lovelies'; _plantNames[54] := 'Mangaboos'; _plantNames[55] := 'Mariphasa lupina lumina (Wolf Flower) '; _plantNames[56] := 'Metarex'; _plantNames[57] := 'Moon Disc'; _plantNames[58] := 'Mors ontologica'; _plantNames[59] := 'Mushroom trees'; _plantNames[60] := 'Night-blooming Mock Orchid'; _plantNames[61] := 'Night Howler Crocus'; _plantNames[62] := 'Obernut'; _plantNames[63] := 'Omega Flowey Paopu Fruit Deku Baba Papadalupapadipu Deku Scrubs Peahat'; _plantNames[64] := 'Peruvian Puff Pepper'; _plantNames[65] := 'Peya'; _plantNames[66] := 'Pikmin'; _plantNames[67] := 'Piranha Plant '; _plantNames[68] := 'PP-34'; _plantNames[69] := 'Principal Malaysian Palmgrass'; _plantNames[70] := 'Priphea Flowers'; _plantNames[71] := 'Protoanthus'; _plantNames[72] := 'Pseudobushiahugiflora'; _plantNames[73] := 'Quadrotriticale'; _plantNames[74] := 'Rangdo'; _plantNames[75] := 'Re-annual plants'; _plantNames[76] := 'Red weed'; _plantNames[77] := 'Rroamal'; _plantNames[78] := 'Rytt'; _plantNames[79] := 'Sapient Pearwood'; _plantNames[80] := 'SapSac'; _plantNames[81] := 'Seedrians'; _plantNames[82] := 'Senzu Bean'; _plantNames[83] := 'Shimmerweed'; _plantNames[84] := 'Snake vine'; _plantNames[85] := 'Solar Complexus Americanus'; _plantNames[86] := 'Spitfire Tree'; _plantNames[87] := 'Sser'; _plantNames[88] := 'Stage trees'; _plantNames[89] := 'Sorichra'; _plantNames[90] := 'Stinky'; _plantNames[91] := 'Strangleweed'; _plantNames[92] := 'Sukebind Moonflower Sunflower Supox utricularia'; _plantNames[93] := 'Tangle grass'; _plantNames[94] := 'Tanna leaves'; _plantNames[95] := 'Tava beans'; _plantNames[96] := 'Tellurian'; _plantNames[97] := 'Tesla trees'; _plantNames[98] := 'Thunder Spud'; _plantNames[99] := 'Tirils'; _plantNames[100] := 'Trama root '; _plantNames[101] := 'Traversers'; _plantNames[102] := 'Treant'; _plantNames[103] := 'Tree-of-Life'; _plantNames[104] := 'Treeships'; _plantNames[105] := 'Triffids'; _plantNames[106] := 'Truffula tree'; _plantNames[107] := 'Tumtum tree'; _plantNames[108] := 'Une'; _plantNames[109] := 'Vines'; _plantNames[110] := 'Vul nut vine'; _plantNames[111] := 'Wakeflower'; _plantNames[112] := 'Whistling leaves'; _plantNames[113] := 'White Claudia'; _plantNames[114] := 'Wildvine'; _plantNames[115] := 'Witchblood'; _plantNames[116] := 'Wroshyr trees'; _plantNames[117] := 'Yangala-Cola ';
END;

END.
