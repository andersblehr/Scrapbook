unit auxil;


INTERFACE

uses dos,types,keys,strings,oScreen;


procedure setRegister(register : word; value : byte);

function readRegister(register : word) : byte;

function invert(aBit : word) : word;

function getIntStr(number : word) : string;

function getRealStr(number : real) : string;

function upper(x : real) : word;

function readWithToggleXY(x,y,maxLength : byte; default : string;
                          toggleChars : characterSet;
                          var returnedCharacter : char) : string;

function readXY(x,y,maxLength : byte; default : string) : string;

function readWindowXY(x,y,maxLength : byte; prompt,default : string) : string;

procedure writeInWindow(aMessage : string);

function showMessageAndWait(body : string; legalKeys : characterSet) : char;

procedure showMessage(body : string);

procedure showStatus(statusMessage : string);

function confirm(aQuestion : string) : boolean;

function askWithMenu(aMenu : verticalMenuOPtr) : char;

function pathExists(var aPath : dirStr; messageWanted : boolean) : boolean;

function fileExists(aFile : string) : boolean;


IMPLEMENTATION

uses crt,ADT,screen,files;


procedure setRegister(register : word; value : byte);

begin
  port[register]:=value
end;


function readRegister(register : word) : byte;

begin
  readRegister:=port[register]
end;


function invert(aBit : word) : word;

begin
  case aBit of
    0 : invert:=1;
    1 : invert:=0
  end
end;


function getIntStr(number : word) : string;

var   tmp                       : string;

begin
  str(number,tmp);
  if (length(tmp)=1) then
    getIntStr:='0'+tmp
  else
    getIntStr:=tmp
end;


function getRealStr(number : real) : string;

var   tmp                       : string;

begin
  if (number=-1) then
    getRealStr:='Undefined'
  else
    begin
      str(number:8:2,tmp);
      getRealStr:=' '+tmp
    end
end;


procedure pushCharacters(x,y,count : byte);

var   i                         : byte;

begin
  for i:=x+count downTo x+1 do
    theScreen[y][i].ch:=theScreen[y][i-1].ch
end;


procedure pullCharacters(x,y,count : byte);

var   i                         : byte;

begin
  for i:=x to x+count-1 do
    theScreen[y][i].ch:=theScreen[y][i+1].ch
end;


function upper(x : real) : word;

var   tmp                       : word;

begin
  if (tmp>=0) then
    begin
      tmp:=trunc(x);
      if (tmp<x) then
        upper:=tmp+1
      else
        upper:=tmp
    end
  else
    upper:=0
end;


function readWithToggleXY(x,y,maxLength : byte; default : string;
                          toggleChars : characterSet;
                          var returnedCharacter : char) : string;

var   key                       : charTuple;
      currentWindowMin          : word;
      currentWindowMax          : word;


  function treatKey(key : char; soFar : string) : string;

  var   count                     : byte;

  begin
    if (length(soFar)<maxLength) then
      if (whereX=x+length(soFar)) then
        begin
          treatKey:=soFar+key;
          theScreen[y][whereX].ch:=key;
          gotoXY(whereX+1,y)
        end
      else
        begin
          count:=x+length(soFar)-whereX;
          treatKey:=copy(soFar,1,whereX-x)+key+copy(soFar,whereX-x+1,count);
          pushCharacters(whereX,y,count);
          theScreen[y][whereX].ch:=key;
          gotoXY(whereX+1,y)
        end
    else
      treatKey:=soFar
  end;


  function treatSpecialKey(key : char; soFar : string) : string;


    function treatBackSp(soFar : string) : string;

    var   count                     : byte;

    begin
      if (not (whereX=x)) then
        if (whereX=x+length(soFar)) then
          begin
            treatBackSp:=copy(soFar,1,length(soFar)-1);
            gotoXY(whereX-1,y);
            theScreen[y][whereX].ch:=' '
          end
        else
          begin
            count:=x+length(soFar)-whereX+1;
            treatBackSp:=copy(soFar,1,whereX-x-1)+
                         copy(soFar,whereX-x+1,count);
            gotoXY(whereX-1,y);
            pullCharacters(whereX,y,count)
          end
      else
        treatBackSp:=soFar
    end;


    function treatDel(soFar : string) : string;

    begin
      gotoXY(whereX+1,y);
      treatDel:=treatBackSp(soFar)
    end;


  begin
    case key of
      BackSp : treatSpecialKey:=treatBackSp(soFar);
      Del    : treatSpecialKey:=treatDel(soFar);
      Home   : begin
                 gotoXY(x,y);
                 treatSpecialKey:=soFar
               end;
      EndP   : begin
                 gotoXY(x+length(soFar),y);
                 treatSpecialKey:=soFar
               end;
      Right  : begin
                 if (whereX<x+length(soFar)) then
                   gotoXY(whereX+1,y);
                 treatSpecialKey:=soFar
               end;
      Left   : begin
                 if (whereX>x) then
                   gotoXY(whereX-1,y);
                 treatSpecialKey:=soFar
               end
    end
  end;


  function getString(aString : string) : string;

  begin
    repeat
      anyKey(key);
      with key do
        if ((header=noKey) and
            (not (primary in [CR,Esc,BackSp]+toggleChars))) then
          aString:=treatKey(primary,aString)
        else if (not (primary in [CR,Esc]+toggleChars)) then
          aString:=treatSpecialKey(primary,aString)
        else if (primary in [CR,Esc]+toggleChars) then
          returnedCharacter:=primary
    until ((key.header=noKey) and (key.primary in [CR,Esc]+toggleChars));
    if (key.primary=Esc) then
      getString:=''
    else
      getString:=aString
  end;


  function treatDefault(default : string) : string;

  var   aString                   : string;

  begin
    writeColourXY(x,y,inverseAttribute,default);
    repeat
      anyKey(key);
      with key do
        begin
          if ((header=noKey) and
              (not (primary in [CR,Esc,BackSp]+toggleChars))) then
            begin
              clsXY(x,y,x+maxLength,y,readAttribute);
              aString:=treatKey(primary,'');
              treatDefault:=getString(aString)
            end
          else if (((header<>noKey) and
                    (primary in [Left,Right,Del,Home,EndP])) or
                   ((header=noKey) and (primary=BackSp))) then
            begin
              clsAttrXY(x,y,x+maxLength,y,readAttribute);
              aString:=treatSpecialKey(primary,default);
              treatDefault:=getString(aString)
            end
          else if ((header=noKey) and (primary in [CR]+toggleChars)) then
            begin
              clsAttrXY(x,y,x+maxLength,y,readAttribute);
              returnedCharacter:=primary;
              treatDefault:=default
            end
          else if ((header=noKey) and (primary=Esc)) then
            begin
              returnedCharacter:=Esc;
              treatDefault:=''
            end
        end
    until ((key.header=noKey) or ((key.header<>noKey) and
           (key.primary in [Left,Right,Del,Home,EndP])))
  end;


begin
  currentWindowMin:=windMin;
  currentWindowMax:=windMax;
  normalScreen;
  gotoXY(x,y);
  clsXY(x,y,x+maxLength,y,readAttribute);
  setCursor(on);
  if (default<>'') then
    readWithToggleXY:=treatDefault(default)
  else
    readWithToggleXY:=getString('');
  setCursor(off);
  crt.window(lo(currentWindowMin),hi(currentWindowMin),
             lo(currentWindowMax),hi(currentWindowMax))
end;


function readXY(x,y,maxLength : byte; default : string) : string;

var   ignore                    : char;

begin
  readXY:=readWithToggleXY(x,y,maxLength,default,[],ignore)
end;


function readWindowXY(x,y,maxLength : byte; prompt,default : string) : string;

begin
  window(x-2,y-1,x+maxLength+2,y+1,prompt);
  readWindowXY:=readXY(x,y,maxLength,default);
  restoreScreen
end;


procedure writeInWindow(aMessage : string);

var   lengthOfMessage           : byte;

begin
  saveAttributes;
  setMainAttribute(whiteOnRed);
  setFrameAttribute(yellowOnRed);
  lengthOfMessage:=length(aMessage);
  window(38-(lengthOfMessage div 2),10,42+(lengthOfMessage div 2),12,'');
  writeXY(40-(lengthOfMessage div 2),11,aMessage);
  restoreAttributes
end;


function showMessageAndWait(body : string; legalKeys : characterSet) : char;

var lengthOfBody                : byte;
    ch                          : char;

begin
  writeInWindow(body);
  showMessageAndWait:=waitForKey(legalKeys,ch);
  restoreScreen
end;


procedure showMessage(body : string);

var   ignore                    : char;

begin
  ignore:=showMessageAndWait(body,[])
end;


procedure showStatus(statusMessage : string);

begin
  writeInWindow(statusMessage)
end;


function confirm(aQuestion : string) : boolean;

var   reply                     : char;

begin
  reply:=showMessageAndWait(aQuestion+' (Y/N)',['Y','y','N','n',Esc]);
  confirm:=(reply in ['Y','y'])
end;


function askWithMenu(aMenu : verticalMenuOPtr) : char;

var   choice                    : char;

begin
  with aMenu^ do
    begin
      showMenu;
      choose(choice);
      if (choice=CR) then
        choice:=alternative(chosenAlternative);
      removeMenu;
      askWithMenu:=choice
    end
end;


function pathExists(var aPath : dirStr; messageWanted : boolean) : boolean;

var   ignore                    : searchRec;
      thePathExists             : boolean;

begin
  if (aPath<>'') then
    begin
      if (aPath[length(aPath)]<>'\') then
        aPath:=aPath+'\';
      findFirst(aPath+'ignore',archive,ignore);
      thePathExists:=(dosError<>3);
      if ((not thePathExists) and messageWanted) then
        showMessage('Path not found!');
      pathExists:=thePathExists
    end
  else
    pathExists:=false
end;


function fileExists(aFile : string) : boolean;

var   ignore                    : searchRec;

begin
  findFirst(aFile,archive,ignore);
  fileExists:=(dosError=0)
end;


end.