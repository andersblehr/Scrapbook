unit help;


INTERFACE

uses adt,oScreen;

const null                      = 65535;
      rootPage                  = 0;

type  helpScreenString          = string[65];

      helpFileType              = file of helpScreenString;

      childNodeOPtr             = ^childNodeO;
      childNodeO                = object(doubleNodeO)
        nameOfPageV               : helpScreenString;
        filePositionV             : word;
        constructor init(positionOfChild : word);
        destructor  done; virtual;
        function    nameOfPage   : string;
        function    filePosition : word;
        procedure   setNameOfPage(aName : helpScreenString);
        procedure   setFilePosition(aPosition : word);
      end;

      pageManagerOPtr           = ^pageManagerO;
      pageManagerO              = object(doubleListO)
        helpFile                  : helpFileType;
        helpScreen                : virtualScreenOPtr;
        numberOfLinesV            : byte;
        numberOfChildrenV         : byte;
        siblingNumberV            : byte;
        noOfSiblingsOnThisLevelV  : byte;
        positionOfCurrentPageV    : word;
        positionOfParentV         : word;
        choosePositionV           : byte;
        constructor init(pathToHelpFile : string; anAttribute : byte);
        destructor  done; virtual;
        function    numberOfLines               : byte;
        function    numberOfChildren            : byte;
        function    siblingNumber               : byte;
        function    numberOfSiblingsOnThisLevel : byte;
        function    positionOfCurrentPage       : word;
        function    positionOfParent            : word;
        function    choosePosition              : byte;
        function    currentChild                : childNodeOPtr;
        function    goToParent                  : boolean;
        function    goToLeftSibling             : boolean;
        function    goToRightSibling            : boolean;
        procedure   setNumberOfLines(aNumber : byte);
        procedure   setNumberOfChildren(aNumber : byte);
        procedure   setNumberOfSiblingsOnThisLevel(aNumber : byte);
        procedure   setSiblingNumber(aNumber : byte);
        procedure   setPositionOfCurrentPage(aPosition : word);
        procedure   setPositionOfParent(aPosition : word);
        procedure   setChoosePosition(aPosition : byte);
        procedure   pageUp;
        procedure   pageDown;
        procedure   goToTopOfPage;
        procedure   goToBottomOfPage;
        procedure   goToRoot;
        procedure   goToChildNumber(aNumber : byte);
        procedure   goToPage(positionOfPage : word);
        procedure   showRoot;
        procedure   showParent;
        procedure   showLeftSibling;
        procedure   showRightSibling;
        procedure   showChildNumber(aNumber : byte);
        procedure   showPageAt(positionOfPage : word);
        procedure   showPage;
        procedure   initOperation;
        procedure   closeOperation;
      end;

      helpManagerOPtr           = ^helpManagerO;
      helpManagerO              = object
        pageManager               : pageManagerOPtr;
        constructor init(pathToHelpFile : string; anAttribute : byte);
        destructor  done;
        procedure   navigate;
        procedure   helpOnHelp(mode : boolean); virtual;
      end;


IMPLEMENTATION

uses auxil,screen,keys,strings;


const leftPoint                 =  2;
      centerPoint               = 24;
      rightPoint                = 79;
      topPoint                  =  2;
      middlePoint               = 15;
      bottomPoint               = 23;

      navigating                = false;
      choosing                  = true;


(**************************************************************************
 *                                                                        *
 *     childNodeO(doubleListO)'s methods                                  *
 *                                                                        *
 **************************************************************************)


constructor childNodeO.init(positionOfChild : word);

begin
  doubleNodeO.init;
  setNameOfPage('');
  setFilePosition(positionOfChild)
end;


destructor childNodeO.done;

begin
  doubleNodeO.done
end;


function childNodeO.nameOfPage : string;

begin
  nameOfPage:=nameOfPageV
end;


function childNodeO.filePosition : word;

begin
  filePosition:=filePositionV
end;


procedure childNodeO.setNameOfPage(aName : helpScreenString);

begin
  nameOfPageV:=copy(aName,1,18)
end;


procedure childNodeO.setFilePosition(aPosition : word);

begin
  filePositionV:=aPosition
end;


(**************************************************************************
 *                                                                        *
 *     pageManagerO(doubleListO)'s methods                                *
 *                                                                        *
 **************************************************************************)


constructor pageManagerO.init(pathToHelpFile : string; anAttribute : byte);

begin
  doubleListO.init;
  assign(helpFile,pathToHelpFile);
  reset(helpFile);
  new(helpScreen,init(anAttribute));
  setPositionOfCurrentPage(rootPage)
end;


destructor pageManagerO.done;

begin
  dispose(helpScreen,done);
  close(helpFile);
  doubleListO.done
end;


function pageManagerO.numberOfLines : byte;

begin
  numberOfLines:=numberOfLinesV
end;


function pageManagerO.numberOfChildren : byte;

begin
  numberOfChildren:=numberOfChildrenV
end;


function pageManagerO.siblingNumber : byte;

begin
  siblingNumber:=siblingNumberV
end;


function pageManagerO.numberOfSiblingsOnThisLevel : byte;

begin
  numberOfSiblingsOnThisLevel:=noOfSiblingsOnThisLevelV
end;


function pageManagerO.positionOfCurrentPage : word;

begin
  positionOfCurrentPage:=positionOfCurrentPageV
end;


function pageManagerO.positionOfParent : word;

begin
  positionOfParent:=positionOfParentV
end;


function pageManagerO.choosePosition : byte;

begin
  choosePosition:=choosePositionV
end;


function pageManagerO.currentChild : childNodeOPtr;

begin
  currentChild:=childNodeOPtr(position)
end;


function pageManagerO.goToParent : boolean;

var   parentExists              : boolean;

begin
  parentExists:=(positionOfParent<>null);
  if parentExists then
    goToPage(positionOfParent)
  else
    showMessage('No higher level!');
  goToParent:=parentExists
end;


function pageManagerO.goToLeftSibling : boolean;

var   siblingNumberOfThisPage   : byte;
      leftSiblingExists         : boolean;

begin
  leftSiblingExists:=(siblingNumber>1);
  if leftSiblingExists then
    begin
      siblingNumberOfThisPage:=siblingNumber;
      if goToParent then
        goToChildNumber(pred(siblingNumberOfThisPage))
    end
  else
    showMessage('First node on this level!');
  goToLeftSibling:=leftSiblingExists
end;


function pageManagerO.goToRightSibling : boolean;

var   siblingNumberOfThisPage   : byte;
      rightSiblingExists        : boolean;

begin
  rightSiblingExists:=(siblingNumber<numberOfSiblingsOnThisLevel);
  if rightSiblingExists then
    begin
      siblingNumberOfThisPage:=siblingNumber;
      if goToParent then
        goToChildNumber(succ(siblingNumberOfThisPage))
    end
  else
    showMessage('Last node on this level!');
  goToRightSibling:=rightSiblingExists
end;


procedure pageManagerO.setNumberOfLines(aNumber : byte);

begin
  numberOfLinesV:=aNumber
end;


procedure pageManagerO.setNumberOfChildren(aNumber : byte);

begin
  numberOfChildrenV:=aNumber
end;


procedure pageManagerO.setNumberOfSiblingsOnThisLevel(aNumber : byte);

begin
  noOfSiblingsOnThisLevelV:=aNumber
end;


procedure pageManagerO.setSiblingNumber(aNumber : byte);

begin
  siblingNumberV:=aNumber
end;


procedure pageManagerO.setPositionOfCurrentPage(aPosition : word);

begin
  positionOfCurrentPageV:=aPosition
end;


procedure pageManagerO.setPositionOfParent(aPosition : word);

begin
  positionOfParentV:=aPosition
end;


procedure pageManagerO.setChoosePosition(aPosition : byte);

begin
  choosePositionV:=aPosition
end;


procedure pageManagerO.pageUp;


  function adjust(aNumber : integer) : word;

  begin
    if (aNumber>=1) then
      adjust:=aNumber
    else
      adjust:=1
  end;


begin
  with helpScreen^ do
    showScreen(1,adjust(yPosition-(bottomPoint-topPoint-2)))
end;


procedure pageManagerO.pageDown;


  function adjust(aNumber : integer) : word;

  begin
    if (aNumber<=numberOfLines-(bottomPoint-topPoint-2)) then
      adjust:=aNumber
    else
      if (numberOfLines>(bottomPoint-topPoint-2)) then
        adjust:=numberOfLines-(bottomPoint-topPoint-2)
      else
        adjust:=1
  end;


begin
  with helpScreen^ do
    showScreen(1,adjust(yPosition+(bottomPoint-topPoint-2)))
end;


procedure pageManagerO.goToTopOfPage;

begin
  helpScreen^.showScreen(1,1)
end;


procedure pageManagerO.goToBottomOfPage;


  function adjust(aNumber : integer) : word;

  begin
    if (aNumber>=1) then
      adjust:=aNumber
    else
      adjust:=1
  end;


begin
  helpScreen^.showScreen(1,adjust(numberOfLines-(bottomPoint-topPoint-2)))
end;


procedure pageManagerO.goToRoot;

begin
  goToPage(rootPage)
end;


procedure pageManagerO.goToChildNumber(aNumber : byte);

var   i                         : byte;

begin
  if (aNumber<=numberOfChildren) then
    begin
      goToStart;
      for i:=1 to aNumber-1 do
        goForwards;
      goToPage(currentChild^.filePosition)
    end
end;


procedure pageManagerO.goToPage(positionOfPage : word);

var   infoString                : helpScreenString;
      i                         : byte;

begin
  helpScreen^.forgetScreen;
  emptyList;
  setPositionOfCurrentPage(positionOfPage);
  seek(helpFile,positionOfCurrentPage);
  read(helpFile,infoString);
  setNumberOfLines(ord(infoString[1]));
  setNumberOfChildren(ord(infoString[2]));
  setNumberOfSiblingsOnThisLevel(ord(infoString[3]));
  setSiblingNumber(ord(infoString[4]));
  setPositionOfParent((word(ord(infoString[5])) shl 8)+ord(infoString[6]));
  setChoosePosition(0);
  for i:=1 to numberOfChildren do
    addElement(new(childNodeOPtr,
        init((word(ord(infoString[2*i+5])) shl 8)+ord(infoString[2*i+6]))));
  goToStart
end;


procedure pageManagerO.showRoot;

begin
  if (positionOfCurrentPage<>rootPage) then
    begin
      goToRoot;
      showPage
    end
  else
    showMessage('Root level!')
end;


procedure pageManagerO.showParent;

begin
  if goToParent then
    showPage
end;


procedure pageManagerO.showLeftSibling;

begin
  if goToLeftSibling then
    showPage
end;


procedure pageManagerO.showRightSibling;

begin
  if goToRightSibling then
    showPage
end;


procedure pageManagerO.showChildNumber(aNumber : byte);

begin
  goToChildNumber(aNumber);
  showPage
end;


procedure pageManagerO.showPageAt(positionOfPage : word);

begin
  goToPage(positionOfPage);
  showPage
end;


procedure pageManagerO.showPage;

var   i                         : byte;
      lineRead                  : helpScreenString;


  function revPos(var aString : string) : byte;

  var   backslashPos              : byte;

  begin
    backslashPos:=pos('\',aString);
    if (backslashPos<>0) then
      if (aString[succ(backslashPos)]<>'\') then
        revPos:=backslashPos
      else
        begin
          aString:=copy(aString,1,backslashPos-1)+
                   copy(aString,backslashPos+1,length(aString)-backslashPos);
          revPos:=0
        end
    else
      revPos:=0
  end;


  function getSubstring(var aString : string; var attribute : byte) : string;

  var   denotesChild              : boolean;
        possibleNameOfChild       : helpScreenString;


    function decideAttribute(aCommand : char;
                     var denotesChild : boolean) : byte;

    begin
      case aCommand of
        '@' :
          begin
            decideAttribute:=markedAttribute;
            denotesChild:=false
          end;
        '\' :
          begin
            decideAttribute:=inverseAttribute;
            denotesChild:=true
          end
      end
    end;


    function copyToAlphaOrBackslash(var aString : string) : string;

    var   endOfInterestingPart      : byte;


      function posOfAlphaOrBackslash(aString : string) : byte;

      var   posOfAlpha                : byte;
            posOfBackslash            : byte;

      begin
        posOfAlpha:=pos('@',aString);
        posOfBackslash:=revPos(aString);
        if ((posOfAlpha<>0) and (posOfBackslash<>0)) then
          if (posOfAlpha<posOfBackslash) then
            posOfAlphaOrBackslash:=posOfAlpha
          else
            posOfAlphaOrBackslash:=posOfBackslash
        else if (posOfAlpha=0) then
          posOfAlphaOrBackslash:=posOfBackslash
        else
          posOfAlphaOrBackslash:=posOfAlpha
      end;


    begin
      endOfInterestingPart:=posOfAlphaOrBackslash(aString)-1;
      copyToAlphaOrBackslash:=copy(aString,1,endOfInterestingPart);
      delete(aString,1,endOfInterestingPart)
    end;


  begin
    if (aString[1] in ['@','\']) then
      begin
        possibleNameOfChild:=copy(aString,3,pos('}',aString)-3);
        attribute:=decideAttribute(aString[1],denotesChild);
        if denotesChild then
          begin
            currentChild^.setNameOfPage(capitalizeFirst(possibleNameOfChild));
            goForwards
          end;
        delete(aString,1,pos('}',aString));
        getSubstring:=possibleNameOfChild
      end
    else
      begin
        attribute:=mainAttribute;
        getSubstring:=copyToAlphaOrBackslash(aString)
      end
  end;


  procedure writeLineToHelpScreen(aLine : string; y : byte);

  var   x                         : byte;
        anAttribute               : byte;
        substring                 : string;

  begin
    x:=1;
    if (length(aLine)>0) then
      if ((pos('@',aLine)=0) and (revPos(aLine)=0)) then
        if (aLine[1]<>'_') then
          helpScreen^.vWriteXY(x,y,aLine)
        else
          helpScreen^.vWriteColourXY(x,y,textAttribute,copy(aLine,2,length(aLine)-1))
      else
        while (aLine<>'') do
          begin
            substring:=getSubstring(aLine,anAttribute);
            helpScreen^.vWriteColourXY(x,y,anAttribute,substring);
            inc(x,length(substring))
          end
  end;


begin
  goToStart;
  clsXY(centerPoint+1,topPoint+1,rightPoint-1,bottomPoint-1,mainAttribute);
  clsXY(leftPoint+1,topPoint+1,centerPoint-2,middlePoint-1,mainAttribute);
  helpScreen^.makeScreen(rightPoint-centerPoint-2,numberOfLines);
  for i:=1 to numberOfLines do
    begin
      seek(helpFile,positionOfCurrentPage+i);
      read(helpFile,lineRead);
      writeLineToHelpScreen(lineRead,i)
    end;
  goToStart;
  for i:=1 to numberOfChildren do
    begin
      writeXY(leftPoint+2,topPoint+i,currentChild^.nameOfPage);
      goForwards
    end
end;


procedure pageManagerO.initOperation;


  procedure makeWindow;

  var   i                         : byte;

  begin
    window(leftPoint,topPoint,rightPoint,bottomPoint,'');
    saveAttributes;
    setFrameAttribute(markedAttribute);
    frame(leftPoint,middlePoint+1,centerPoint-1,bottomPoint,'Go to');
    frame(centerPoint,topPoint,rightPoint,bottomPoint,'');
    restoreAttributes;
    frame(leftPoint,topPoint,centerPoint-1,middlePoint,'');
    writeColourXY(leftPoint+ 2,middlePoint+2,readAttribute,'Ctrl- '#27);
    writeColourXY(leftPoint+ 9,middlePoint+2,mainAttribute,' : Previous');
    writeColourXY(leftPoint+ 2,middlePoint+3,readAttribute,'Ctrl- '#26);
    writeColourXY(leftPoint+ 9,middlePoint+3,mainAttribute,' : Next');
    writeColourXY(leftPoint+ 2,middlePoint+4,readAttribute,'Tab');
    writeColourXY(leftPoint+ 5,middlePoint+4,mainAttribute,' : Below');
    writeColourXY(leftPoint+ 2,middlePoint+5,readAttribute,'Ctrl-PgUp');
    writeColourXY(leftPoint+11,middlePoint+5,mainAttribute,' : Above');
    writeColourXY(leftPoint+ 2,middlePoint+6,readAttribute,'Ctrl-Home');
    writeColourXY(leftPoint+11,middlePoint+6,mainAttribute,' : Root');
    writeColourXY(leftPoint+ 2,middlePoint+7,readAttribute,'Ctrl-F1');
    writeColourXY(leftPoint+ 9,middlePoint+7,mainAttribute,' : Help')
  end;


begin
  makeWindow;
  helpScreen^.makeWindow(centerPoint+2,topPoint+1,rightPoint-1,bottomPoint-1);
  helpScreen^.initScrolling;
  goToPage(positionOfCurrentPage)
end;


procedure pageManagerO.closeOperation;

begin
  helpScreen^.closeScrolling;
  helpScreen^.forgetScreen;
  helpScreen^.forgetWindow;
  restoreScreen
end;


(**************************************************************************
 *                                                                        *
 *     helpManagerO's methods                                             *
 *                                                                        *
 **************************************************************************)


constructor helpManagerO.init(pathToHelpFile : string; anAttribute : byte);

begin
  new(pageManager,init(pathToHelpFile,anAttribute))
end;


destructor helpManagerO.done;

begin
  dispose(pageManager,done)
end;


procedure helpManagerO.navigate;

var   returnedKey               : charTuple;
      mode                      : boolean;


  procedure markField(position,attribute : byte);

  begin
    clsAttrXY(leftPoint+1,topPoint+position+1,centerPoint-2,
              topPoint+position+1,attribute)
  end;


  procedure toggleMode;

  begin
    case mode of
      navigating :
        if (pageManager^.numberOfChildren>0) then
          begin
            saveAttributes;
            setTextAttribute(frameAttribute);
            frame(centerPoint,topPoint,rightPoint,bottomPoint,'Help');
            frame(leftPoint,middlePoint+1,centerPoint-1,bottomPoint,'Go to');
            restoreAttributes;
            setFrameAttribute(markedAttribute);
            frame(leftPoint,topPoint,centerPoint-1,middlePoint,'Next level');
            markField(pageManager^.choosePosition,inverseAttribute);
            restoreAttributes;
            mode:=choosing
          end
        else
          showMessage('No level below this!');
      choosing :
        begin
          saveAttributes;
          setTextAttribute(frameAttribute);
          frame(leftPoint,topPoint,centerPoint-1,middlePoint,'Next level');
          restoreAttributes;
          setFrameAttribute(markedAttribute);
          frame(centerPoint,topPoint,rightPoint,bottomPoint,'Help');
          frame(leftPoint,middlePoint+1,centerPoint-1,bottomPoint,'Go to');
          restoreAttributes;
          writeColourXY(rightPoint-44,bottomPoint,frameAttribute,' Use ');
          writeColourXY(rightPoint-39,bottomPoint,readAttribute,#24#25);
          writeColourXY(rightPoint-37,bottomPoint,frameAttribute,' and ');
          writeColourXY(rightPoint-32,bottomPoint,readAttribute,'PgUp');
          writeColourXY(rightPoint-28,bottomPoint,frameAttribute,'/');
          writeColourXY(rightPoint-27,bottomPoint,readAttribute,'PgDn');
          writeColourXY(rightPoint-23,bottomPoint,frameAttribute,'/');
          writeColourXY(rightPoint-22,bottomPoint,readAttribute,'Home');
          writeColourXY(rightPoint-18,bottomPoint,frameAttribute,'/');
          writeColourXY(rightPoint-17,bottomPoint,readAttribute,'End');
          writeColourXY(rightPoint-14,bottomPoint,frameAttribute,' to navigate ');
          markField(pageManager^.choosePosition,mainAttribute);
          mode:=navigating
        end
    end
  end;


  procedure goUp;

  begin
    with pageManager^ do
      begin
        markField(choosePosition,mainAttribute);
        if (choosePosition>0) then
          setChoosePosition(pred(choosePosition))
        else
          setChoosePosition(numberOfChildren-1)
      end
  end;


  procedure goDown;

  begin
    with pageManager^ do
      begin
        markField(choosePosition,mainAttribute);
        setChoosePosition(succ(choosePosition) mod numberOfChildren)
      end
  end;


  procedure goToChosenPage;

  begin
    toggleMode;
    with pageManager^ do
      showChildNumber(succ(choosePosition))
  end;


begin
  mode:=choosing;
  setKey(returnedKey,noKey,noKey);
  pageManager^.initOperation;
  pageManager^.showPage;
  toggleMode;
  with pageManager^ do
    repeat
      anyKey(returnedKey);
      case mode of
        navigating :
          if (returnedKey.header=#0) then
            case returnedKey.primary of
              Up        : helpScreen^.scroll(down);
              Down      : helpScreen^.scroll(up);
              PgUp      : pageUp;
              PgDn      : pageDown;
              Home      : goToTopOfPage;
              EndP      : goToBottomOfPage;
              CtrlPgUp  : showParent;
              CtrlLeft  : showLeftSibling;
              CtrlRight : showRightSibling;
              CtrlHome  : showRoot;
              CtrlF1    : helpOnHelp(navigating)
            end
          else if (returnedKey.primary=Tab) then
            toggleMode;
        choosing :
          begin
            if (returnedKey.header=#0) then
              begin
                case returnedKey.primary of
                  Up     : goUp;
                  Down   : goDown;
                  CtrlF1 : helpOnHelp(choosing)
                end;
                markField(choosePosition,inverseAttribute)
              end
            else
              case returnedKey.primary of
                CR  : goToChosenPage;
                Tab : toggleMode
              end
          end
      end
    until ((returnedKey.header=noKey) and (returnedKey.primary=Esc));
  pageManager^.closeOperation
end;


procedure helpManagerO.helpOnHelp(mode : boolean);

var   frameAttrBuffer             : byte;

begin
  frameAttrBuffer:=frameAttribute;
  setFrameAttribute(markedAttribute);
  window(centerPoint,topPoint,rightPoint,bottomPoint,'Help on help');
  case mode of
    navigating :
      begin
        writeXY(26, 3,'The help system is based on a general tree structure');
        writeColourXY(64,3,markedAttribute,'tree structure');
        writeXY(26, 4,'of single pages.  Each page has zero or more pages');
        writeXY(26, 5,'underneath it, its children, and every page, except');
        writeColourXY(45,5,markedAttribute,'children');
        writeXY(26, 6,'the root page, has one page above it, the parent.');
        writeColourXY(30,6,markedAttribute,'root');
        writeColourXY(68,6,markedAttribute,'parent');
        writeXY(26, 7,'Pages that have the same parent, are said to be on');
        writeXY(26, 8,'the same level.');
        writeColourXY(35,8,markedAttribute,'level');
        writeXY(26,10,'In the lower left corner is described how to get');
        writeXY(26,11,'around between the pages.  To get to the previous or');
        writeXY(26,12,'next page on the same level, if it exists, press');
        writeXY(26,13,'Ctrl- '#27' and Ctrl- '#26', respectively.  To get to the');
        writeColourXY(26,13,markedAttribute,'Ctrl- '#27);
        writeColourXY(38,13,markedAttribute,'Ctrl- '#26);
        writeXY(26,14,'parent page, press Ctrl-PgUp, and to get to the root');
        writeColourXY(45,14,markedAttribute,'Ctrl-PgUp');
        writeXY(26,15,'page, press Ctrl-Home.  If the current page has any');
        writeColourXY(38,15,markedAttribute,'Ctrl-Home');
        writeXY(26,16,'children, these are written with these colours in');
        writeColourXY(59,16,inverseAttribute,'these colours');
        writeXY(26,17,'the text, and are present in the next level menu in');
        writeColourXY(59,17,markedAttribute,'next level menu');
        writeXY(26,18,'the upper left corner of the screen.  To be able to');
        writeXY(26,19,'choose among these, press Tab.');
        writeColourXY(52,19,markedAttribute,'Tab');
        writeXY(26,21,'To navigate within one page, follow the instructions');
        writeXY(26,22,'in the lower right corner of the screen.')
      end;
    choosing :
      begin
        writeXY(26, 4,'You have now pressed Tab to be able to choose which');
        writeColourXY(47,4,markedAttribute,'Tab');
        writeXY(26, 5,'of the child pages of the current page to go to');
        writeXY(26, 6,'next.');
        writeXY(26, 8,'The existing child pages are listed in the next');
        writeColourXY(69,8,markedAttribute,'next');
        writeXY(26, 9,'level menu in the upper left corner of the screen.');
        writeColourXY(26,9,markedAttribute,'level menu');
        writeXY(26,10,'Press '#25' and '#24' to navigate between the alternatives,');
        writeColourXY(32,10,markedAttribute,#25);
        writeColourXY(38,10,markedAttribute,#24);
        writeXY(26,11,'and Return to choose.');
        writeColourXY(30,11,markedAttribute,'Return');
        writeXY(26,13,'To get back to reading and navigating within the');
        writeXY(26,14,'current page, press Tab once more.');
        writeColourXY(46,14,markedAttribute,'Tab')
      end
  end;
  wait;
  restoreScreen;
  setFrameAttribute(frameAttrBuffer)
end;


end.