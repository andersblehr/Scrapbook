program readHelp;

uses help,types,screen,oScreen,keys;

var   helpManager               : helpManagerOPtr;
      storedScreen              : screenOPtr;

begin
  setDefaultAttributes(whiteOnBlue, yellowOnBlue,whiteOnBlue,blackOnCyan,
                       whiteOnBlack,whiteOnCyan, simpleFrame,shadow);
  setAttributes(blackOnGray,yellowOnGray,grayOnGray,whiteOnGray,
                blackOnCyan,redOnGray,simpleFrame,shadow);
  setCursor(off);
  new(storedScreen,init);
  new(helpManager,init('filter.hlp',mainAttribute));
  helpManager^.navigate;
  dispose(helpManager,done);
  dispose(storedScreen,done);
  setCursor(on)
end.