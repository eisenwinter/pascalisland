{
  UbrMain
  @author(Jan <jan@subkonstrukt.at>)
  @abstract(Pascal ist auch nur eine Insel)
  @created(2017-07-10)

  a minilib application that creates an island
  @lastmod(2017-07-10)
}
PROGRAM Main;

USES
   ApplicationLayer, MetaInfo;
VAR
   s : IslandApplication;
BEGIN
   s := NewApplication;
   s^.Run;
   Dispose(s, Done);
   MetaInfo.WriteMetaInfo;
END.
