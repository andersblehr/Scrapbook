unit doRead;


INTERFACE


const screenMemory              = $B800;
      offset                    = 0;
      elements                  = 4000;
      columns                   = 80;
      lines                     = 50;

      BackSp                    =  #8;
      Del                       = #83;
      Home                      = #71;
      EndP                      = #79;
      Right                     = #77;
      Left                      = #75;
      CR                        = #13;
      Esc                       = #27;

const attributesSet             : boolean = false;

type  screenFragment            = Record
        ch                        : char;
        attr                      : byte
      end;

      storedScreenType          = array[0..elements] of screenFragment;
      columnArrayType           = array[1..columns] of screenFragment;
      screenType                = array[1..lines] of columnArrayType;
      frameCharacters           = string[6];

      charTuple                 = record
        header                    : char;
        primary                   : char
      end;

      characterSet              = set of char;

var   theScreen                 : screenType absolute screenMemory : offset;

      mainAttribute             : byte;
      inverseAttribute          : byte;
      readAttribute             : byte;


function readWithToggleXY(x,y,maxLength : byte; default : string;
                          toggleChars : characterSet;
                          var returnedCharacter : char) : string;

function readXY(x,y,maxLength : byte; default : string) : string;

function readKey : char;

function getAttribute(backgroundColour,foregroundColour : byte) : byte;

procedure setAttributes(anInverse,aRead : byte);

procedure writeColourXY(x,y,attr : byte; aText : string);

procedure clsXY(x1,y1,x2,y2,attr : byte);

procedure clsAttrXY(x1,y1,x2,y2,attr : byte);

procedure anyKey(var aKey : charTuple);

procedure readString(var aString : string);

procedure criticalError(message : string);


IMPLEMENTATION

uses crt,dos;


const noKey                     = 'þ';

var   specialKey                : boolean;


function readWithToggleXY(x,y,maxLength : byte; default : string;
                          toggleChars : characterSet;
                          var returnedCharacter : char) : string;

var   key                       : charTuple;
      currentWindowMin          : word;
      currentWindowMax          : word;


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
  if attributesSet then
    begin
      currentWindowMin:=windMin;
      currentWindowMax:=windMax;
      crt.window(1,1,80,25);
      gotoXY(x,y);
      clsXY(x,y,x+maxLength,y,readAttribute);
      if (default<>'') then
        readWithToggleXY:=treatDefault(default)
      else
        readWithToggleXY:=getString('');
      crt.window(lo(currentWindowMin),hi(currentWindowMin),
                 lo(currentWindowMax),hi(currentWindowMax))
    end
  else
    criticalError('Attributes not set')
end;


function readXY(x,y,maxLength : byte; default : string) : string;

var   ignore                    : char;

begin
  readXY:=readWithToggleXY(x,y,maxLength,default,[],ignore)
end;


function readKey : char;

var   regs                      : registers;
      currentVector             : pointer;
      aKey                      : char;

begin
  regs.ah:=$00;
  intr($16,regs);
  specialKey:=(regs.al=0);
  if specialKey then
    readKey:=chr(regs.ah)
  else
    readKey:=chr(regs.al)
end;


function getAttribute(backgroundColour,foregroundColour : byte) : byte;

begin
  getAttribute:=(16*backgroundColour)+foregroundColour
end;


procedure setAttributes(anInverse,aRead : byte);

begin
  inverseAttribute:=anInverse;
  readAttribute:=aRead;
  attributesSet:=true
end;


procedure writeColourXY(x,y,attr : byte; aText : string);

var   i                         : byte;

begin
  if (aText<>'') then
    for i:=0 to length(aText)-1 do
      begin
        theScreen[y][x+i].ch:=aText[i+1];
        theScreen[y][x+i].attr:=attr
      end
end;


procedure clsXY(x1,y1,x2,y2,attr : byte);

var   i,j                       : byte;

begin
  for i:=y1 to y2 do
    for j:=x1 to x2 do
      begin
        theScreen[i][j].ch:=' ';
        theScreen[i][j].attr:=attr
      end
end;


procedure clsAttrXY(x1,y1,x2,y2,attr : byte);

var   i,j                       : byte;

begin
  For i:=y1 to y2 do
    For j:=x1 to x2 do
      theScreen[i][j].attr:=attr
end;


procedure anyKey(var aKey : charTuple);

var   keyRead                   : char;

begin
  keyRead:=readKey;
  if specialKey then
    begin
      aKey.header:=#0;
      aKey.primary:=keyRead
    end
  else
    begin
      aKey.header:=noKey;
      aKey.primary:=keyRead
    end
end;


procedure readString(var aString : string);

var   startX                    : byte;
      key                       : charTuple;


  function treatKey(key : char; soFar : string) : string;

  var   count                     : byte;

  begin
    treatKey:=soFar+key;
    write(key)
  end;


  function deleteCharacter(soFar : string) : string;

  begin
    if (whereX>startX) then
      begin
        delete(soFar,length(soFar),1);
        gotoXY(pred(whereX),whereY);
        write(' ');
        gotoXY(pred(whereX),whereY)
      end;
    deleteCharacter:=soFar
  end;


begin
  startX:=whereX;
  aString:='';
  repeat
    anyKey(key);
    with key do
      if ((header=noKey) and (not (primary in [#8,#13]))) then
        aString:=treatKey(primary,aString)
      else if ((header=noKey) and (primary=#8)) then
        aString:=deleteCharacter(aString)
  until ((key.header=noKey) and (key.primary=#13))
end;


procedure criticalError(message : string);

begin
  clrScr;
  write(message,', aborting....');
  sound(1000);
  delay(400);
  noSound;
  halt(1)
end;


end.