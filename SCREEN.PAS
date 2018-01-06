unit screen;


INTERFACE

uses keys,strings;


const screenMemory              = $B800;
      offset                    = 0;
      elements                  = 4000;
      columns                   = 80;
      lines                     = 50;

      off                       = 0;
      on                        = 1;
      medium                    = 2;
      big                       = 3;

      shadow                    = true;
      noShadow                  = false;

      ignore                    = 15;

type  screenFragment            = Record
        ch                        : char;
        attr                      : byte
      end;

      storedScreenType          = array[0..elements] of screenFragment;
      columnArrayType           = array[1..columns] of screenFragment;
      screenType                = array[1..lines] of columnArrayType;
      frameCharacters           = string[6];

const numberOfLines             : byte = 25;

      cursorStatus              : byte = On;

      simpleFrame               : frameCharacters = 'ÚÄ¿³ÀÙ';
      doubleFrame               : frameCharacters = 'ÉÍ»ºÈ¼';
      specialFrame1             : frameCharacters = 'ÖÄ·ºÓ½';
      specialFrame2             : frameCharacters = 'ÕÍ¸³Ô¾';
      noFrame                   : frameCharacters = '      ';

var   theScreen                 : screenType absolute screenMemory : offset;

      defaultMain               : byte; {31}
      defaultMarked             : byte; {30}
      defaultFrame              : byte; {31}
      defaultText               : byte; {48}
      defaultInverse            : byte; {15}
      defaultRead               : byte; {whiteOnCyan}
      defaultFrameType          : frameCharacters; {simpleFrame}
      defaultShadow             : boolean; {shadow}


procedure setDefaultAttributes(mainAttribute,markedAttribute,frameAttribute,
            textAttribute,inverseAttribute,readAttribute : byte;
            frameType : frameCharacters; shadow : boolean);

procedure restoreDefaultAttributes;

procedure setAttributes(mainAttribute,markedAttribute,frameAttribute,
            textAttribute,inverseAttribute,readAttribute : byte;
            frameType : frameCharacters; shadow : boolean);

procedure saveAttributes;

procedure restoreAttributes;

procedure setMainAttribute(value : byte);

procedure setMarkedAttribute(value : byte);

procedure setFrameAttribute(value : byte);

procedure setTextAttribute(value : byte);

procedure setInverseAttribute(value : byte);

procedure setReadAttribute(value : byte);

procedure setFrameType(value : frameCharacters);

procedure setShadow(value : boolean);

procedure writeXY(x,y : byte; aText : string);

procedure writeColourXY(x,y,attr : byte; aText : String);

procedure setNumberOfLines(aNumber : byte);

procedure cls(attr : byte);

procedure clsXY(x1,y1,x2,y2,attr : byte);

procedure clsAttr(attr : byte);

procedure clsAttrXY(x1,y1,x2,y2,attr : byte);

procedure storeScreen(x1,y1,x2,y2 : byte);

procedure restoreScreen;

procedure window(x1,y1,x2,y2 : byte; aText : string);

procedure windowOver(x1,y1,x2,y2 : byte; aText : string);

procedure textWindow(x1,y1,x2,y2 : byte; aText : string);

procedure textWindowOver(x1,y1,x2,y2 : byte; aText : string);

procedure frame(x1,y1,x2,y2 : byte; aText : string);

procedure normalScreen;

procedure makeMenu(x1,y1,x2,y2 : byte; alternatives,aText : string);

procedure setCursor(status : byte);

function mainAttribute : byte;

function markedAttribute : byte;

function frameAttribute : byte;

function textAttribute : byte;

function inverseAttribute : byte;

function readAttribute : byte;

function frameType : frameCharacters;

function shadowSet : boolean;

function menuChoose(addedCharacters : characterSet) : Char;

function getAttribute(backgroundColour,foregroundColour : byte) : byte;


IMPLEMENTATION

uses crt,dos;


const maxNumberOfScreens        = 255;

type  alternativeListPtr        = ^alternativeListRecord;
      alternativeListRecord     = Record
        alternative               : char;
        no                        : byte;
        previous                  : alternativeListPtr;
        next                      : alternativeListPtr
      end;

      storedScreenPtr           = ^storedScreenType;

      screenPtr                 = ^screenRecord;
      screenRecord              = record
        aScreen                   : storedScreenPtr;
        first                     : alternativeListPtr;
        position                  : alternativeListPtr;
        last                      : alternativeListPtr;
        startX                    : byte;
        startY                    : byte;
        endX                      : byte;
        endY                      : byte
      end;

      screenArray               = array[1..maxNumberOfScreens] of screenPtr;

      attributeRecord           = record
        mainAttribute             : byte;
        markedAttribute           : byte;
        frameAttribute            : byte;
        textAttribute             : byte;
        inverseAttribute          : byte;
        readAttribute             : byte;
        frameType                 : frameCharacters;
        shadow                    : boolean
      end;

const here                      : byte    = 1;
      storedScreensExist        : boolean = false;

var   root                      : screenArray;
      attributes                : attributeRecord;
      savedAttributes           : attributeRecord;


procedure setDefaultAttributes(mainAttribute,markedAttribute,frameAttribute,
            textAttribute,inverseAttribute,readAttribute : byte;
            frameType : frameCharacters; shadow : boolean);

begin
  defaultMain:=mainAttribute;
  defaultMarked:=markedAttribute;
  defaultFrame:=frameAttribute;
  defaultText:=textAttribute;
  defaultInverse:=inverseAttribute;
  defaultRead:=readAttribute;
  defaultFrameType:=frameType;
  defaultShadow:=shadow;
  restoreDefaultAttributes;
  saveAttributes
end;


procedure restoreDefaultAttributes;

begin
  setMainAttribute(defaultMain);
  setMarkedAttribute(defaultMarked);
  setFrameAttribute(defaultFrame);
  setTextAttribute(defaultText);
  setInverseAttribute(defaultInverse);
  setReadAttribute(defaultRead);
  setFrameType(defaultFrameType);
  setShadow(defaultShadow)
end;


procedure setAttributes(mainAttribute,markedAttribute,frameAttribute,
            textAttribute,inverseAttribute,readAttribute : byte;
            frameType : frameCharacters; shadow : boolean);

begin
  setMainAttribute(mainAttribute);
  setMarkedAttribute(markedAttribute);
  setFrameAttribute(frameAttribute);
  setTextAttribute(textAttribute);
  setInverseAttribute(inverseAttribute);
  setReadAttribute(readAttribute);
  setFrameType(frameType);
  setShadow(shadow)
end;


procedure saveAttributes;

begin
  savedAttributes:=attributes
end;


procedure restoreAttributes;

begin
  attributes:=savedAttributes
end;


procedure setMainAttribute(value : byte);

begin
  attributes.mainAttribute:=value
end;


procedure setMarkedAttribute(value : byte);

begin
  attributes.markedAttribute:=value
end;


procedure setFrameAttribute(value : byte);

begin
  attributes.frameAttribute:=value
end;


procedure setTextAttribute(value : byte);

begin
  attributes.textAttribute:=value
end;


procedure setInverseAttribute(value : byte);

begin
  attributes.inverseAttribute:=value
end;


procedure setReadAttribute(value : byte);

begin
  attributes.readAttribute:=value
end;


procedure setFrameType(value : frameCharacters);

begin
  attributes.frameType:=value
end;


procedure setShadow(value : boolean);

begin
  attributes.shadow:=value
end;


function mainAttribute : byte;

begin
  mainAttribute:=attributes.mainAttribute
end;


function markedAttribute : byte;

begin
  markedAttribute:=attributes.markedAttribute
end;


function frameAttribute : byte;

begin
  frameAttribute:=attributes.frameAttribute
end;


function textAttribute : byte;

begin
  textAttribute:=attributes.textAttribute
end;


function inverseAttribute : byte;

begin
  inverseAttribute:=attributes.inverseAttribute
end;


function readAttribute : byte;

begin
  readAttribute:=attributes.readAttribute
end;


function frameType : frameCharacters;

begin
  frameType:=attributes.frameType
end;


function shadowSet : boolean;

begin
  shadowSet:=attributes.shadow
end;


procedure writeXY(x,y : byte; aText : string);

var   i                         : byte;

begin
  If (aText<>'') then
    for i:=0 to length(aText)-1 do
      begin
        theScreen[y][x+i].ch:=aText[i+1];
        theScreen[y][x+i].attr:=mainAttribute
      end
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


procedure setNumberOfLines(aNumber : byte);

begin
  if (aNumber=25) then
    begin
      numberOfLines:=aNumber;
      textMode(3)
    end
  else if (aNumber=50) then
    begin
      numberOfLines:=aNumber;
      textMode(-1)
    end
end;


procedure cls(attr : byte);

var   i                         : byte;

begin
  for i:=1 to 80 do
    begin
      theScreen[1][i].ch:=' ';
      theScreen[1][i].attr:=attr
    end;
  for i:=2 to numberOfLines do
    theScreen[i]:=theScreen[1]
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


procedure clsAttr(attr : byte);

var   i,j                       : byte;

begin
  for i:=1 to numberOfLines do
    for j:=1 to 80 do
      theScreen[i][j].attr:=attr
end;


procedure clsAttrXY(x1,y1,x2,y2,attr : byte);

var   i,j                       : byte;

begin
  For i:=y1 to y2 do
    For j:=x1 to x2 do
      theScreen[i][j].attr:=attr
end;


procedure storeScreen(x1,y1,x2,y2 : Byte);

var   i,j                       : byte;

begin
  getMem(root[here],sizeOf(screenRecord));
  with root[here]^ do
    begin
      getMem(aScreen,(x2-x1+1)*(y2-y1+1)*sizeOf(screenFragment));
      for i:=y1 to y2 do
        for j:=x1 to x2 do
          aScreen^[(i-y1)*(x2-x1+1)+(j-x1)]:=theScreen[i][j];
      first:=nil;
      last:=nil;
      startX:=x1;
      startY:=y1;
      endX:=x2;
      endY:=y2
    end;
  inc(here)
end;


procedure restoreScreen;

var   i,j                       : byte;


  procedure deleteList;

  begin
    if (root[here-1]^.first<>nil) then
      begin
        root[here-1]^.position:=root[here-1]^.last;
        if (root[here-1]^.first<>root[here-1]^.last) then
          repeat
            root[here-1]^.position:=root[here-1]^.position^.previous;
            freeMem(root[here-1]^.position^.next,sizeOf(alternativeListRecord))
          until (root[here-1]^.position=root[here-1]^.first);
        freeMem(root[here-1]^.first,sizeOf(alternativeListRecord));
        root[here-1]^.first:=nil;
        root[here-1]^.last:=nil;
        root[here-1]^.position:=nil
      end
  end;


begin
  with root[here-1]^ do
    begin
      for i:=startY to endY do
        for j:=startX to endX do
          theScreen[i][j]:=aScreen^[(i-startY)*(endX-startX+1)+(j-startX)];
      freeMem(aScreen,(endX-startX+1)*(endY-startY+1)*
                       sizeOf(screenFragment));
      deleteList
    end;
  freeMem(root[here-1],sizeOf(screenRecord));
  root[here-1]:=nil;
  dec(here);
  storedScreensExist:=(here>1)
end;


procedure makeShadow(x1,y1,x2,y2 : byte);

var   i,j                       : byte;


  function xCode(x : byte) : byte;

  begin
    case x of
      1..78 : xCode:=2;
      79    : xCode:=1;
      80    : xCode:=0
    end;
  end;


  function yCode(y : byte) : byte;

  begin
    case numberOfLines of
      25 : case y of
             1..24 : yCode:=1;
             25    : yCode:=0
           end;
      50 : case y of
             1..49 : yCode:=1;
             50    : yCode:=0
           end
    end;
  end;


begin
  for i:=y1+1 to y2+yCode(y2) do
    for j:=x2+1 to x2+xCode(x2) do
      theScreen[i][j].attr:=8;
  for i:=x1+2 to x2 do
    theScreen[y2+1][i].attr:=8
end;


procedure frame(x1,y1,x2,y2 : byte; aText : string);

var   i                         : byte;

begin
  with attributes do
    begin
      for i:=x1+1 to x2-1 do
        begin
          theScreen[y1][i].attr:=frameAttribute;
          theScreen[y1][i].ch:=frameType[2];
          theScreen[y2][i].attr:=frameAttribute;
          theScreen[y2][i].ch:=frameType[2]
        end;
      For i:=y1+1 to y2-1 do
        begin
          theScreen[i][x1].attr:=frameAttribute;
          theScreen[i][x1].ch:=frameType[4];
          theScreen[i][x2].attr:=frameAttribute;
          theScreen[i][x2].ch:=frameType[4]
        end;
      theScreen[y1][x1].attr:=frameAttribute;
      theScreen[y1][x1].ch:=frameType[1];
      theScreen[y2][x1].attr:=frameAttribute;
      theScreen[y2][x1].ch:=frameType[5];
      theScreen[y1][x2].attr:=frameAttribute;
      theScreen[y1][x2].ch:=frameType[3];
      theScreen[y2][x2].attr:=frameAttribute;
      theScreen[y2][x2].ch:=frameType[6];
      If (aText<>'') then
        writeColourXY(x1+(x2-x1-length(aText)) div 2,y1,textAttribute,
                      ' '+aText+' ');
   end
end;


procedure windowOver(x1,y1,x2,y2 : byte; aText : string);

begin
  clsXY(x1,y1,x2,y2,mainAttribute);
  frame(x1,y1,x2,y2,aText);
  if shadowSet then
    makeShadow(x1,y1,x2,y2)
end;


procedure window(x1,y1,x2,y2 : byte; aText : string);

begin
  storeScreen(x1,y1,x2+2,y2+1);
  windowOver(x1,y1,x2,y2,aText)
end;


procedure textWindowOver(x1,y1,x2,y2 : byte; aText : string);

begin
  textColor(mainAttribute mod 16);
  textBackGround(mainAttribute div 16);
  crt.window(x1,y1,x2,y2);
  clrScr;
  crt.window(x1+1,y1+1,x2-1,y2-1);
  frame(x1,y1,x2,y2,aText);
  If shadowSet then
    makeShadow(x1,y1,x2,y2)
end;


procedure textWindow(x1,y1,x2,y2 : byte; aText : string);

begin
  storeScreen(x1,y1,x2+2,y2+1);
  textWindowOver(x1,y1,x2,y2,aText)
end;


procedure normalScreen;

begin
  crt.window(1,1,80,numberOfLines)
end;


function getComponent(var aString : string) : string;

var   position                  : byte;

begin
  position:=pos('\',aString);
  getComponent:=Copy(aString,1,position-1);
  delete(aString,1,position)
end;


function getAlternative(aString : string) : char;

begin
  getAlternative:=aString[pos('_',aString)+1]
end;


function makeList(aString : string) : alternativeListPtr;

var   counter                   : byte;


  function legalAlternativeString(aString : String) : Boolean;

  begin
    legalAlternativeString:=((aString<>'')     and (aString<>'\\') and
                             (aString[1]<>'\') and
                             (aString[Length(aString)]='\'))
  end;


begin
  if legalAlternativeString(aString) then
    with root[here-1]^ do
      begin
        counter:=1;
        getMem(first,sizeOf(alternativeListRecord));
        first^.previous:=nil;
        first^.next:=nil;
        position:=first;
        position^.alternative:=getAlternative(getComponent(aString));
        position^.no:=counter;
        while (aString<>'') do
          begin
            inc(counter);
            getMem(position^.next,sizeOf(alternativeListRecord));
            position^.next^.previous:=position;
            position:=position^.next;
            position^.next:=nil;
            position^.alternative:=getAlternative(getComponent(aString));
            position^.no:=counter;
          end;
        last:=position;
        position:=first;
        makeList:=first
      end
  else
    makeList:=nil
end;


procedure makeMenu(x1,y1,x2,y2 : byte; alternatives,aText : string);


  procedure writeText(x,y : byte; aString : string);

  var   tmpString                 : string;
        no                        : byte;


    procedure doWrite(aString : String);

    VAR   aCharacter               : char;
          i,j                      : byte;

    begin
      j:=0;
      for i:=1 to length(aString) do
        begin
          aCharacter:=aString[i];
          if (aCharacter<>'_') then
            theScreen[y+no][x+(i-j)].ch:=aCharacter
          else
            begin
              inc(j);
              inc(i);
              aCharacter:=aString[i];
              theScreen[y+no][x+(i-j)].ch:=aCharacter;
              theScreen[y+no][x+(i-j)].attr:=markedAttribute
            end
        end;
      inc(no)
    end;


  begin
     no:=1;
     storedScreensExist:=true;
     while (aString<>'') do
       doWrite(getComponent(aString))
  end;


begin
  window(x1,y1,x2,y2,aText);
  root[here-1]^.first:=makeList(alternatives);
  if (root[here-1]^.first<>nil) then
    writeText(x1+2,y1,alternatives)
end;


function menuChoose(addedCharacters : characterSet) : char;

var   alternatives              : characterSet;
      x1,x2,y                   : byte;
      aCharacter                : char;


  procedure initAlternatives(var setOfAlternatives : characterSet);

  var   this                      : alternativeListPtr;

  begin
    with root[here-1]^ do
      begin
        this:=position;
        position:=first;
        setOfAlternatives:=setOfAlternatives+[upCase(position^.alternative)];
        while (position^.next<>nil) do
          begin
            position:=position^.next;
            setOfAlternatives:=setOfAlternatives+
                               [upCase(position^.alternative)]
          end;
        position:=this
      end
  end;


  procedure moveUp;

  begin
    with root[here-2]^ do
      if (position<>first) then
        position:=position^.previous
      else
        position:=last
  end;


  procedure moveDown;

  begin
    with root[here-2]^ do
      if (position<>last) then
        position:=position^.next
      else
        position:=first
  end;


  function goToPosition(aCharacter : Char) : Char;

  begin
    goToPosition:=aCharacter;
    if (not (aCharacter in addedCharacters+[Esc])) then
      with root[here-1]^ do
        begin
          position:=first;
          while (position^.alternative<>aCharacter) do
            position:=position^.next
        end
  end;


begin
  if storedScreensExist then
    with root[here-1]^ do
      begin
        x1:=startX+2;
        x2:=endX-4;
        y:=startY;
        alternatives:=[];
        initAlternatives(alternatives);
        repeat
          storeScreen(x1,y+position^.no,x2,y+position^.no);
          clsAttrXY(x1,y+position^.no,x2,y+position^.no,inverseAttribute);
          aCharacter:=readKey;
          case aCharacter of
            Up   : moveUp;
            Down : moveDown
          end;
          restoreScreen
        until (upCase(aCharacter) in alternatives+addedCharacters+[CR,Esc]);
        if (aCharacter=CR) then
          menuChoose:=upCase(position^.alternative)
        else
          menuChoose:=goToPosition(upCase(aCharacter))
      end
end;


procedure setCursor(status : byte);


  procedure doSetCursor(ch25,cl25,ch50,cl50 : byte);

  var   regs                      : registers;


    procedure setRegisters(ch,cl : byte);

    begin
      regs.ah:=$1;
      regs.ch:=ch;
      regs.cl:=cl
    end;


  begin
    case numberOfLines of
      25 : setRegisters(ch25,cl25);
      50 : setRegisters(ch50,cl50)
    end;
    intr($10,regs)
  end;


begin
  case status of
    off    : doSetCursor($E,$0,$E,$0);
    on     : doSetCursor($C,$D,$6,$7);
    medium : doSetCursor($FF,$8,$4,$3);
    big    : doSetCursor($0,$D,$0,$D)
  end;
  cursorStatus:=status
end;


function getAttribute(backgroundColour,foregroundColour : byte) : byte;

begin
  getAttribute:=(16*backgroundColour)+foregroundColour
end;


procedure makeNull(var aScreen : screenArray);

var   i                         : Byte;

begin
  for i:=1 to maxNumberOfScreens do
    aScreen[i]:=nil
end;


begin
  makeNull(root)
end.