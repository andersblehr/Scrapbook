{$F+}
unit oScreen;


INTERFACE

uses screen,keys,strings;


const maxCharacters             = 4000;
      maxAlternatives           = 23;
      maxColumns                = 256;
      maxRows                   = 1024;

type  proc                      = procedure;

      rowArrayPtr               = ^rowArray;
      rowArray                  = array[1..maxColumns] of screenFragment;

      virtualScreenArrayPtr     = ^virtualScreenArray;
      virtualScreenArray        = array[1..maxRows] of rowArrayPtr;

      screenArrayPtr            = ^screenArray;
      screenArray               = array[0..maxCharacters] of screenFragment;

      menuOPtr                  = ^menuO;

      alternativeRecordPtr      = ^alternativeRecord;
      alternativeRecord         = record
        alternativeAsString       : stringPtr;
        alternativeAsChar         : char;
        case submenues            : boolean of
          true  : (submenu        : menuOPtr);
          false : (theProcedure   : proc)
      end;

      alternativeArrayPtr       = ^alternativeArray;
      alternativeArray          = array[1..maxAlternatives]
                                    of alternativeRecordPtr;

      menuO                     = object
        mainAttribute             : byte;
        markedAttribute           : byte;
        inverseAttribute          : byte;
        numberOfAlternatives      : byte;
        chosenAlternative         : byte;
        alternatives              : characterSet;
        addedCharacters           : characterSet;
        parent                    : menuOPtr;
        storedScreen              : screenArrayPtr;
        markerBuffer              : screenArrayPtr;
        alternativeList           : alternativeArrayPtr;
        constructor  init(initMainAttribute,initMarkedAttribute,
                          initInverseAttribute : byte;
                          initAlternatives : string;
                          initAddedCharacters : characterSet);
        destructor   done; virtual;
        function     markerX1                           : byte; virtual;
        function     markerX2                           : byte; virtual;
        function     markerY                            : byte; virtual;
        function     backCode                           : char; virtual;
        function     findPosition(code : char)          : byte;
        function     alternative(pos : byte)            : char;
        function     alternativeAsString(pos : byte)    : stringPtr;
        function     submenues(pos : byte)              : boolean;
        function     submenu(pos : byte)                : menuOPtr;
        function     legalAlternative(candidate : char) : boolean;
        function     addedCharacter(candidate : char)   : boolean;
        procedure    addAlternatives(alternativeString : string); virtual;
        procedure    setSubmenu(pos : byte; aMenu : menuOPtr);
        procedure    setProcedure(pos : byte; aProcedure : proc);
        procedure    choose(var code : char);
        procedure    goBack;
        procedure    goForwards;
        procedure    showMarker;
        procedure    removeMarker;
        procedure    goToPosistion(code : char);
        procedure    showMenu; virtual;
        procedure    removeMenu; virtual;
      end;

      verticalMenuOPtr          = ^verticalMenuO;
      verticalMenuO             = object(menuO)
        startX                    : byte;
        startY                    : byte;
        endX                      : byte;
        endY                      : byte;
        frameAttribute            : byte;
        frameTextAttribute        : byte;
        frameType                 : frameCharacters;
        frameText                 : stringPtr;
        shadow                    : boolean;
        constructor  init(initStartX,initStartY,
                          initMainAttribute,initMarkedAttribute,
                          initInverseAttribute,initFrameAttribute : byte;
                          initFrameType : frameCharacters;
                          initShadow : boolean;
                          initAlternatives,initFrameText : string;
                          initAddedCharacters : characterSet);
        destructor   done; virtual;
        function     markerX1           : byte; virtual;
        function     markerX2           : byte; virtual;
        function     markerY            : byte; virtual;
        function     backCode           : char; virtual;
        function     longestAlternative : string;
        procedure    addAlternatives(alternativeString : string); virtual;
        procedure    setFrameTextAttribute(value : byte);
        procedure    showMenu; virtual;
        procedure    removeMenu; virtual;
      end;

      screenOPtr                = ^screenO;
      screenO                   = object
        storedScreen              : screenType;
        x                         : byte;
        y                         : byte;
        constructor  init;
        destructor   done;
      end;

      virtualScreenOPtr         = ^virtualScreenO;
      virtualScreenO            = object
        monitor                   : virtualScreenArrayPtr;
        attribute                 : byte;
        xMax                      : word;
        yMax                      : word;
        xPosition                 : word;
        yPosition                 : word;
        windowMinX                : byte;
        windowMinY                : byte;
        windowMaxX                : byte;
        windowMaxY                : byte;
        windowMade                : boolean;
        scrollInit                : boolean;
        constructor  init(attr : byte);
        destructor   done;
        function     isDefined     : boolean;
        function     numberOfLines : word;
        procedure    makeScreen(xSize,ySize : word);
        procedure    forgetScreen;
        procedure    clearScreen(attr : byte);
        procedure    vWriteXY(x,y : word; aText : string);
        procedure    vWriteColourXY(x,y : word; attr : byte; aText : string);
        procedure    makeWindow(x1,y1,x2,y2 : byte);
        procedure    showScreen(x,y : word);
        procedure    forgetWindow;
        procedure    initScrolling;
        procedure    scroll(direction : char);
        procedure    closeScrolling;
      end;

var   initMem                   : longInt;


IMPLEMENTATION

uses crt;


(**************************************************************************
 *                                                                        *
 *     Internal procedures and functions                                  *
 *                                                                        *
 **************************************************************************)


procedure dummy;

begin
end;


procedure storeScreen(var aScreen : screenArrayPtr; x1,y1,x2,y2 : byte);

var   i,j                       : byte;

begin
  getMem(aScreen,(x2-x1+1)*(y2-y1+1)*sizeOf(screenFragment));
  for i:=y1 to y2 do
    for j:=x1 to x2 do
      aScreen^[(i-y1)*(x2-x1+1)+(j-x1)]:=theScreen[i][j]
end;


function decideLast(max,x : word; x1,x2 : byte) : byte;

begin
  if (max-x<x2-x1) then
    decideLast:=max-x
  else
    decideLast:=x2-x1
end;


(**************************************************************************
 *                                                                        *
 *     menuO's methods                                                    *
 *                                                                        *
 **************************************************************************)


constructor menuO.init(initMainAttribute,initMarkedAttribute,
                       initInverseAttribute : byte;
                       initAlternatives : string;
                       initAddedCharacters : characterSet);

begin
  alternatives:=[];
  numberOfAlternatives:=0;
  mainAttribute:=initMainAttribute;
  markedAttribute:=initMarkedAttribute;
  inverseAttribute:=initInverseAttribute;
  storedScreen:=nil;
  markerBuffer:=nil;
  addAlternatives(initAlternatives);
  addedCharacters:=initAddedCharacters;
  parent:=nil;
  chosenAlternative:=1
end;


destructor menuO.done;


  procedure deleteAlternativeList;

  var   i                         : byte;

  begin
    for i:=1 to numberOfAlternatives do
      begin
        if submenues(i) then
          dispose(submenu(i),done);
        delStr(alternativeAsString(i));
        dispose(alternativeList^[i])
      end;
    freeMem(alternativeList,(numberOfAlternatives+1)*sizeOf(pointer))
  end;


begin
   if (alternativeList<>nil) then
      deleteAlternativeList;
   if (markerBuffer<>nil) then
      removeMarker;
   if (storedScreen<>nil) then
      removeMenu
end;


function menuO.markerX1 : byte;

begin
end;


function menuO.markerX2 : byte;

begin
end;


function menuO.markerY : byte;

begin
end;


function menuO.backCode : char;

begin
end;


function menuO.findPosition(code : char) : byte;

var   position                  : byte;

begin
  if legalAlternative(code) then
    begin
      position:=1;
      while (alternative(position)<>code) do
        inc(position);
      findPosition:=position
    end
  else
    errorMessage('menuO.findposition: Illegal alternative!')
end;


function menuO.alternative(pos : byte) : char;

begin
  alternative:=alternativeList^[pos]^.alternativeAsChar
end;


function menuO.alternativeAsString(pos : byte) : stringPtr;

begin
  alternativeAsString:=alternativeList^[pos]^.alternativeAsString
end;


function menuO.submenues(pos : byte) : boolean;

begin
  submenues:=alternativeList^[pos]^.submenues
end;


function menuO.submenu(pos : byte) : menuOPtr;

begin
  submenu:=alternativeList^[pos]^.submenu
end;


function menuO.legalAlternative(candidate : char) : boolean;

begin
  legalAlternative:=(candidate in alternatives)
end;



function menuO.addedCharacter(candidate : char) : boolean;

begin
  addedCharacter:=(candidate in addedCharacters)
end;


procedure menuO.addAlternatives(alternativeString : string);


  function setAlternatives(aString : string) : alternativeArrayPtr;

  var   aList                     : alternativeArray;
        i                         : byte;


    function legalAlternativeString(aString : string) : boolean;

    begin
      legalAlternativeString:=((aString<>'') and (aString<>'\\') and
        (aString[1]<>'\') and (aString[length(aString)]='\'))
    end;


    function allocateList(aList : alternativeArray;
                          size  : byte) : alternativeArrayPtr;

    var   allocatedList             : alternativeArrayPtr;
          i                         : byte;

    begin
      getMem(allocatedList,(size+1)*sizeOf(pointer));
      for i:=1 to size do
        allocatedList^[i]:=aList[i];
      allocatedList^[size+1]:=nil;
      allocateList:=allocatedList
    end;


    function getComponent(var aString : string) : string;

    var   position                  : byte;

    begin
      position:=pos('\',aString);
      getComponent:=copy(aString,1,position-1);
      delete(aString,1,position)
    end;


  begin
    if legalAlternativeString(aString) then
      begin
        for i:=1 to numberOfAlternatives do
          begin
            new(aList[i]);
            aList[i]:=alternativeList^[i]
          end;
        while (aString<>'') do
          begin
            inc(numberOfAlternatives);
            new(aList[numberOfAlternatives]);
            with aList[numberOfAlternatives]^ do
              begin
                alternativeAsString:=strPtr(getComponent(aString));
                alternativeAsChar:=upCase(alternativeAsString^[pos('_',
                  alternativeAsString^)+1]);
                submenues:=false;
                theProcedure:=dummy;
                alternatives:=alternatives+[alternativeAsChar]
              end
          end;
        setAlternatives:=allocateList(aList,numberOfAlternatives)
      end
    else
      errorMessage('Illegal alternative string!')
  end;


begin
  alternativeList:=setAlternatives(alternativeString);
end;


procedure menuO.setSubmenu(pos : byte; aMenu : menuOPtr);

begin
  if (not submenues(pos)) then
    begin
      alternativeList^[pos]^.submenu:=aMenu;
      alternativeList^[pos]^.submenues:=true
    end
  else
    errorMessage('menuO.setSubmenu: Submenues already in existence!')
end;


procedure menuO.setProcedure(pos : byte; aProcedure : proc);

begin
  if (not submenues(pos)) then
    alternativeList^[pos]^.theProcedure:=aProcedure
  else
    errorMessage('menuO.setProcedure: '+
                 'You are trying to overload a submenu with a procedure!')
end;


procedure menuO.choose(var code : char);

var   back                      : char;
      forward                   : char;
      ignore                    : char;


  function forwardCode(backCode : char) : char;

  begin
    if (backCode=Up) then
      forwardCode:=Down
    else
      forwardCode:=Right
  end;


  function codeShallBeReturned(code : char) : boolean;

  begin
    codeShallBeReturned:=((not (code in alternatives+[CR,Esc])) and
       (addedCharacter(code))) or
      ((code in alternatives+[Cr,Esc]) and (addedCharacter(code)) and
       (not specialKey) and (not (code in [back,forward]))) or
      (addedCharacter(code) and specialKey) or
      ((code in alternatives+[CR,Esc]) and
       (not (addedCharacter(code))) and (not specialKey))
  end;


begin
  back:=backCode;
  forward:=forwardCode(back);
  showMarker;
  repeat
    code:=upCase(waitForKey(alternatives+addedCharacters+
                            [CR,Esc,back,forward],ignore));
    if (specialKey and (code in [back,forward])) then
      begin
        if (code=back) then
          goBack
        else
          goForwards;
        showMarker
      end
  until codeShallBeReturned(code);
  if (legalAlternative(code) and (not specialKey)) then
    goToPosistion(code)
end;


procedure menuO.goBack;

begin
  removeMarker;
  if (chosenAlternative<>1) then
    dec(chosenAlternative)
  else
    chosenAlternative:=numberOfAlternatives
end;


procedure menuO.goForwards;

begin
  removeMarker;
  if (chosenAlternative<>numberOfAlternatives) then
    inc(chosenAlternative)
  else
    chosenAlternative:=1
end;


procedure menuO.showMarker;

var   x1,x2,y                   : byte;

begin
  if (markerBuffer=nil) then
    begin
      x1:=markerX1;
      x2:=markerX2;
      y:=markerY;
      storeScreen(markerBuffer,x1,y,x2,y);
      clsAttrXY(x1,y,x2,y,inverseAttribute)
    end
end;


procedure menuO.removeMarker;

var   x1,x2,y,i                 : byte;

begin
  if (markerBuffer<>nil) then
    begin
      x1:=markerX1;
      x2:=markerX2;
      y:=markerY;
      for i:=x1 to x2 do
        theScreen[y][i]:=markerBuffer^[i-x1];
      freeMem(markerBuffer,(x2-x1+1)*sizeOf(screenFragment));
      markerBuffer:=nil
    end
end;


procedure menuO.goToPosistion(code : char);

begin
  removeMarker;
  chosenAlternative:=findPosition(code);
  showMarker
end;


procedure menuO.showMenu;

begin
end;


procedure menuO.removeMenu;

begin
end;


(**************************************************************************
 *                                                                        *
 *     verticalMenuO(menuO)'s methods                                     *
 *                                                                        *
 **************************************************************************)


constructor verticalMenuO.init(initStartX,initStartY,
                               initMainAttribute,initMarkedAttribute,
                               initInverseAttribute,initFrameAttribute : byte;
                               initFrameType : frameCharacters;
                               initShadow : boolean;
                               initAlternatives,
                               initFrameText : string;
                               initAddedCharacters : characterSet);


begin
  menuO.init(initMainAttribute,initMarkedAttribute,initInverseAttribute,
             initAlternatives,initAddedCharacters);
  startX:=initStartX;
  startY:=initStartY;
  endX:=startX+length(longestAlternative)+2;
  endY:=startY+numberOfAlternatives+1;
  frameAttribute:=initFrameAttribute;
  frameTextAttribute:=defaultText;
  frameType:=initFrameType;
  frameText:=strPtr(initFrameText);
  shadow:=initShadow
end;


destructor verticalMenuO.done;

begin
  menuO.done;
  delStr(frameText)
end;


function verticalMenuO.markerX1 : byte;

begin
  markerX1:=startX+1
end;


function verticalMenuO.markerX2 : byte;

begin
  markerX2:=endX-1
end;


function verticalMenuO.markerY : byte;

begin
  markerY:=startY+chosenAlternative
end;


function verticalMenuO.backCode : char;

begin
  backCode:=Up
end;


function verticalMenuO.longestAlternative : string;

var   aString                   : string;
      i                         : byte;

begin
  aString:='';
  for i:=1 to numberOfAlternatives do
    if (length(alternativeAsString(i)^)>length(aString)) then
      aString:=alternativeAsString(i)^;
  longestAlternative:=aString
end;


procedure verticalMenuO.addAlternatives(alternativeString : string);

begin
  menuO.addAlternatives(alternativeString);
  endX:=startX+length(longestAlternative)+2;
  endY:=startY+numberOfAlternatives+1
end;


procedure verticalMenuO.setFrameTextAttribute(value : byte);

begin
  frameTextAttribute:=value
end;


procedure verticalMenuO.showMenu;


  procedure writeAlternatives(alternativeList : alternativeArrayPtr);

  var   i                      : byte;


    procedure doWrite(aString : string; no : byte);

    var   i                         : byte;
          positionOfMarkedCharacter : byte;

    begin
      positionOfMarkedCharacter:=pos('_',aString);
      delete(aString,positionOfMarkedCharacter,1);
      for i:=1 to length(aString) do
        begin
          theScreen[startY+no][startX+i+1].ch:=aString[i];
          if (i=positionOfMarkedCharacter) then
            theScreen[startY+no][startX+i+1].attr:=markedAttribute
          else
            theScreen[startY+no][startX+i+1].attr:=mainAttribute
        end
    end;


  begin
    for i:=1 to numberOfAlternatives do
      doWrite(alternativeAsString(i)^,i);
  end;


begin
  if (storedScreen=nil) then
    begin
      if shadow then
        storeScreen(storedScreen,startX,startY,endX+2,endY+1)
      else
        storeScreen(storedScreen,startX,startY,endX,endY);
      setMainAttribute(mainAttribute);
      setMarkedAttribute(markedAttribute);
      setFrameAttribute(frameAttribute);
      setTextAttribute(frameTextAttribute);
      setInverseAttribute(inverseAttribute);
      setFrameType(frameType);
      setShadow(shadow);
      windowOver(startX,startY,endX,endY,frameText^);
      restoreDefaultAttributes;
      writeAlternatives(alternativeList)
    end
end;


procedure verticalMenuO.removeMenu;

var   i,j                       : byte;
      xEnd                      : byte;
      yEnd                      : byte;


  procedure decideXYEnd;

  begin
    case shadow of
      true  : begin
                xEnd:=endX+2;
                yEnd:=endY+1
              end;
      false : begin
                xEnd:=endX;
                yEnd:=endY
              end
    end
  end;


begin
  decideXYEnd;
  if (markerBuffer<>nil) then
    removeMarker;
  for i:=startY to yEnd do
    for j:=startX to xEnd do
      theScreen[i][j]:=storedScreen^[(i-startY)*(xEnd-startX+1)+(j-startX)];
  freeMem(storedScreen,(xEnd-startX+1)*(yEnd-startY+1)*
          sizeOf(screenFragment));
  storedScreen:=nil
end;


(**************************************************************************
 *                                                                        *
 *     screenO's methods                                                  *
 *                                                                        *
 **************************************************************************)


constructor screenO.init;

begin
  storedScreen:=theScreen;
  x:=whereX;
  y:=whereY
end;


destructor screenO.done;

begin
  theScreen:=storedScreen;
  gotoXY(x,y)
end;


(**************************************************************************
 *                                                                        *
 *      virtualScreenO's methods                                          *
 *                                                                        *
 **************************************************************************)


constructor virtualScreenO.init(attr : byte);

begin
  monitor:=nil;
  attribute:=attr;
  xPosition:=1;
  yPosition:=1;
  windowMinX:=0;
  windowMinY:=0;
  windowMaxX:=0;
  windowMaxY:=0;
  windowMade:=false;
  scrollInit:=false
end;


destructor virtualScreenO.done;

begin
  if (monitor<>nil) then
    forgetScreen
end;


function virtualScreenO.isDefined : boolean;

begin
  isDefined:=(monitor<>nil)
end;


function virtualScreenO.numberOfLines : word;

begin
  numberOfLines:=yMax
end;


procedure virtualScreenO.makeScreen(xSize,ySize : word);

const pointerSize               = 4;
      fragmentSize              = 2;

var   i                         : byte;

begin
  xMax:=xSize;
  yMax:=ySize;
  getMem(monitor,(yMax+1)*pointerSize);
  for i:=1 to yMax do
    if (maxAvail>xMax*fragmentSize) then
      getMem(monitor^[i],xMax*fragmentSize)
    else
      writeLn('Not enough memory!');
  monitor^[i+1]:=nil;
  clearScreen(attribute)
end;


procedure virtualScreenO.forgetScreen;

const pointerSize               = 4;
      fragmentSize              = 2;

var   i                         : word;

begin
  if (monitor<>nil) then
    begin
      for i:=1 to yMax do
        freeMem(monitor^[i],xMax*fragmentSize);
      freeMem(monitor,(yMax+1)*pointerSize);
      yMax:=0;
      xMax:=0;
      yPosition:=1;
      xPosition:=1;
      monitor:=nil
    end
end;


procedure virtualScreenO.clearScreen(attr : byte);

var   i                      : word;

begin
  for i:=1 to xMax do
    begin
      monitor^[1]^[i].ch:=' ';
      monitor^[1]^[i].attr:=attr
    end;
  for i:=2 to yMax do
    monitor^[i]^:=monitor^[1]^
end;


procedure virtualScreenO.vWriteXY(x,y : word; aText : string);

var   visualPart                : string;
      start                     : byte;


  procedure writeToVirtualScreen(aText : string);

  var   i                         : byte;

  begin
    for i:=0 to length(aText)-1 do
      begin
        monitor^[y]^[x+i].ch:=aText[i+1];
        monitor^[y]^[x+i].attr:=attribute
      end
  end;


  function findVisualPart(aText : string) : string;

  var   lengthOfText              : byte;
        rightX                    : word;


    function textInWindow : boolean;

    begin
      textInWindow:=((y>=yPosition) and
                     (y<=yPosition+(windowMaxY-windowMinY))) and
                     (not ((x+lengthOfText<xPosition) or (x>rightX)))
    end;


  begin
    if textInWindow then
      begin
        lengthOfText:=length(aText);
        rightX:=xPosition+(windowMaxX-windowMinX);
        if ((x>=xPosition) and (x+lengthOfText<=rightX)) then
          findVisualPart:=aText
        else if ((x<xPosition) and (x+lengthOfText<=rightX)) then
          findVisualPart:=copy(aText,xPosition-x+1,x+lengthOfText-xPosition)
        else if ((x>=xPosition) and (x+lengthOfText>rightX)) then
          findVisualPart:=copy(aText,1,rightX-x+1)
        else
          findVisualPart:=copy(aText,xPosition-x+1,rightX-xPosition+1);
        if (x>=xPosition) then
          start:=windowMinX+(x-xPosition)
        else
          start:=windowMinX
      end
    else
      findVisualPart:=''
  end;


begin
  if (aText<>'') then
    begin
      writeToVirtualScreen(aText);
      if windowMade then
        begin
          visualPart:=findVisualPart(aText);
          if (visualPart<>'') then
            writeColourXY(start,windowMinY+(y-yPosition),
                          attribute,visualPart)
        end
    end
end;


procedure virtualScreenO.vWriteColourXY(x,y : word; attr : byte;
                                        aText : string);

var   rememberedAttribute       : byte;

begin
  rememberedAttribute:=attribute;
  attribute:=attr;
  vWriteXY(x,y,aText);
  attribute:=rememberedAttribute
end;


procedure virtualScreenO.makeWindow(x1,y1,x2,y2 : byte);

begin
  if (not windowMade) then
    begin
      windowMinX:=x1;
      windowMinY:=y1;
      windowMaxX:=x2;
      windowMaxY:=y2;
      windowMade:=true
    end
  else
    errorMessage('virtualScreenO.makeWindow: Window already made!')
end;


procedure virtualScreenO.showScreen(x,y : word);

var   i,j                       : byte;

begin
  if windowMade then
    begin
      xPosition:=x;
      yPosition:=y;
      for i:=0 to decideLast(yMax,y,windowMinY,windowMaxY) do
        for j:=0 to decideLast(xMax,x,windowMinX,windowMaxX) do
          theScreen[windowMinY+i][windowMinX+j]:=monitor^[y+i]^[x+j]
    end
  else
    errorMessage('virtualScreenO.showScreen: Window not made!')
end;


procedure virtualScreenO.forgetWindow;

begin
  if windowMade then
    begin
      windowMinX:=0;
      windowMinY:=0;
      windowMaxX:=0;
      windowMaxY:=0;
      windowMade:=false
    end
  else
    errorMessage('virtualScreenO.forgetWindow: Window not made!')
end;


procedure virtualScreenO.initScrolling;

begin
  if ((windowMinX<>windowMaxX) or (windowMinY<>windowMaxY)) then
    begin
      crt.window(windowMinX,windowMinY,
                 windowMinX+decideLast(xMax,xPosition,windowMinX,windowMaxX),
                 windowMinY+decideLast(yMax,yPosition,windowMinY,windowMaxY));
      scrollInit:=true
    end
  else
    errorMessage('virtualScreenO.initScrolling: '+
                 'Can only scroll in physical windows!')
end;


procedure virtualScreenO.scroll(direction : char);


  procedure scrollUp;

  var   i                         : byte;

  begin
    if (yPosition+(windowMaxY-windowMinY)<yMax) then
      begin
        gotoXY(1,1);
        delLine;
        inc(yPosition);
        for i:=0 to decideLast(xMax,xPosition,windowMinX,windowMaxX) do
          theScreen[windowMaxY][windowMinX+i]:=
            monitor^[yPosition+(windowMaxY-windowMinY)]^[xPosition+i]
      end
  end;


  procedure scrollDown;

  var   i                         : byte;

  begin
    if (yPosition>1) then
      begin
        gotoXY(1,1);
        insLine;
        dec(yPosition);
        for i:=0 to decideLast(xMax,xPosition,windowMinX,windowMaxX) do
          theScreen[windowMinY][windowMinX+i]:=
            monitor^[yPosition]^[xPosition+i]
      end
  end;


  procedure scrollLeft;

  begin
    if (xPosition+(windowMaxX-windowMinX+1)<xMax) then
      showScreen(xPosition+1,yPosition)
  end;


  procedure scrollRight;

  begin
    if (xPosition>1) then
      showScreen(xPosition-1,yPosition)
  end;


begin
  if scrollInit then
    begin
      case direction of
        Up    : scrollUp;
        Down  : scrollDown;
        Left  : scrollLeft;
        Right : scrollRight
      else
        errorMessage('virtualScreenO.scroll: Illegal direction!')
      end
    end
  else
    errorMessage('virtualScreenO.scroll: Scrolling not initialized!')
end;


procedure virtualScreenO.closeScrolling;

begin
  normalScreen;
  scrollInit:=false
end;


(**************************************************************************
 *                                                                        *
 *     Initialization                                                     *
 *                                                                        *
 **************************************************************************)


begin
  initMem:=memAvail
end.