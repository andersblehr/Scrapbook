unit search;


INTERFACE

uses graph,auxil;

const maxSize                   = 512;
      nGrayLevels               = 64;

      nLeapsMax                 = 10;

      west                      = -1;
      east                      = 1;
      north                     = -1;
      south                     = 1;

      asPoint                   = 0;
      asStar                    = 1;
      asCircle                  = 2;

type  variableRPtr              = ^variableR;
      variableR                 = record
        name                      : string;
        value                     : integer
      end;

      initFileManagerOPtr       = ^initFileManagerO;
      initFileManagerO          = object
        initFileExists            : boolean;
        initFileEmpty             : boolean;
        initFile                  : text;
        currentLine               : string;
        constructor init(fileName : string);
        destructor  done;
        function    nextVariable : variableRPtr;
      end;

      bufferType                = array[1..maxSize] of byte;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

      mapType                   = array[0..nGrayLevels-1] of byte;
      wetType                   = array[0..nGrayLevels-1] of boolean;

      point                     = record
        x                         : word;
        y                         : word;
        visited                   : boolean
      end;

      pointArrayPtr             = ^pointArray;
      pointArray                = array[0..maxSize-1] of point;

      priAreasType              = array[1..3] of word;

const lakeLevel                 : byte = 0;
      sobelThreshold            : byte = 5;
      nonSearchRadius           : byte = 0;

      minPupilRadiusFraction    : real = 10;  (* Per cent *)
      maxPupilRadiusFraction    : real = 20;  (* Per cent *)

      filterRadiusFraction      : real = 8;   (* Per cent *)
      wetFraction               : real = 0.8; (* 0 < wetFraction <= 1 *)

      nIterations               : word = 1;

      startX                    : word = 0;
      startY                    : word = 0;

      showSearch                : boolean = false;

var   image                     : pixelMatrixPtr;

      xSize                     : word;
      ySize                     : word;

      map                       : mapType;
      wet                       : wetType;

      minPupilRadius            : word;
      filterRadius              : byte;
      inSeaThreshold            : word;

      startingPoints            : pointArrayPtr;
      priAreas                  : priAreasType;


function applySobelMask(x,y                     : word;
                        northOrSouth,eastOrWest : shortInt) : integer;

function findPupilPoint(var pupilPoint : pointType) : boolean;

procedure findPosition(var pupilPoint,position : pointType);

procedure initGlobals(xSize,ySize : word);

procedure markPosition(x,y : word; asWhat : byte);

procedure closeSearch;


IMPLEMENTATION

uses crt,math;

const whiteSpace                = [#9,#32];


(**************************************************************************
 *                                                                        *
 *     Internals                                                          *
 *                                                                        *
 **************************************************************************)


procedure readInitFile;

var   initFileManager           : initFileManagerOPtr;
      variable                  : variableRPtr;

begin
  new(initFileManager,init('_search'));
  with initFileManager^ do
    if initFileExists then
      begin
        variable:=nextVariable;
        while (variable<>nil) do
          begin
            if (variable^.name='lakeLevel') then
              lakeLevel:=variable^.value
            else if (variable^.name='sobelThreshold') then
              sobelThreshold:=variable^.value
            else if (variable^.name='nonSearchRadius') then
              nonSearchRadius:=variable^.value
            else if (variable^.name='minPupilRadiusFraction') then
              minPupilRadiusFraction:=variable^.value
            else if (variable^.name='maxPupilRadiusFraction') then
              maxPupilRadiusFraction:=variable^.value
            else if (variable^.name='filterRadiusFraction') then
              filterRadiusFraction:=variable^.value
            else if (variable^.name='nIterations') then
              nIterations:=variable^.value;
            variable:=nextVariable
          end
      end;
  dispose(initFileManager,done)
end;


(**************************************************************************
 *                                                                        *
 *     initFileManagerO's methods                                         *
 *                                                                        *
 **************************************************************************)


constructor initFileManagerO.init(fileName : string);

begin
  assign(initFile,appendExtension('c:\user\blehr\'+filename,'.rc'));
  {$I-}
  reset(initFile);
  {$I+}
  initFileExists:=(IOResult=0);
  initFileEmpty:=EOF(initFile);
  if (initFileExists and (not initFileEmpty)) then
    readLn(initFile,currentLine)
end;


destructor initFileManagerO.done;

begin
  if initFileExists then
    close(initFile)
end;


function initFileManagerO.nextVariable : variableRPtr;

var   variableName              : string;
      variableValue             : integer;


  function nextWord : string;

  var   theWord                   : string;


    function nextLine : string;

    var   aLine                     : string;

    begin
      if (not EOF(initFile)) then
        readLn(initFile,aLine)
      else
        aLine:='EOF';
      nextLine:=aLine
    end;


    procedure removeWhiteSpace;

    begin
      while ((currentLine<>'') and (currentLine[1] in whiteSpace)) do
        delete(currentLine,1,1)
    end;


  begin
    theWord:='';
    removeWhiteSpace;
    while ((currentLine='') or (currentLine[1]='%')) do
      begin
        currentLine:=nextLine;
        removeWhiteSpace
      end;
    if (currentLine<>'EOF') then
      begin
        while ((currentLine<>'') and (not (currentLine[1] in whiteSpace))) do
          begin
            theWord:=theWord+currentLine[1];
            delete(currentLine,1,1)
          end
      end;
    nextWord:=theWord
  end;


  function getValue : word;

  var   valueAsString             : string;
        value                     : word;
        result                    : integer;

  begin
    valueAsString:=nextWord;
    val(valueAsString,value,result);
    if (result=0) then
      getValue:=value
    else
      begin
        variableName:=valueAsString;
        getValue:=maxInt
      end
  end;


  function makeVariable(name : string; value : integer) : variableRPtr;

  var   theVariable               : variableRPtr;

  begin
    new(theVariable);
    theVariable^.name:=name;
    theVariable^.value:=value;
    makeVariable:=theVariable
  end;


begin
  if initFileExists then
    if (not initFileEmpty) then
      begin
        variableName:=nextWord;
        variableValue:=maxInt;
        while ((variableName<>'') and (variableValue=maxInt)) do
          variableValue:=getValue;
        if (variableName='') then
          nextVariable:=nil
        else
          nextVariable:=makeVariable(variableName,variableValue)
      end
    else
      fatalError('initFileManagerO.nextVariable: Init file is empty!')
  else
    fatalError('initFileManagerO.nextVariable: Init file does not exist!')
end;


(**************************************************************************
 *                                                                        *
 *     Exported procedures and functions                                  *
 *                                                                        *
 **************************************************************************)


function findPupilPoint(var pupilPoint : pointType) : boolean;

var   pupilFound                : boolean;
      priLevel                  : byte;
      nInvestigated             : word;
      startingPoint             : pointType;
      seaPointer                : pointType;
      previousPos               : pointType;
      lastPos                   : pointType;
      i                         : word;


  procedure getStartingPoint(var aPoint : pointType);

  var   i                         : word;

  begin
    repeat
      i:=random(priAreas[priLevel])
    until (not startingPoints^[i].visited);
    aPoint.x:=startingPoints^[i].x;
    aPoint.y:=startingPoints^[i].y;
    startingPoints^[i].visited:=true
  end;


  function octopusSwims(pos : pointType; depth : byte) : boolean;


    procedure locateSea(pos : pointType; var seaPointer : pointType);


      function feelNArm(offset : word) : word;

      begin
        while ((not wet[image^[pos.y-offset]^[pos.x]]) and (offset>0)) do
          offset:=offset-1;
        feelNArm:=offset
      end;


      function feelSArm(offset : word) : word;

      begin
        while ((not wet[image^[pos.y+offset]^[pos.x]]) and (offset>0)) do
          offset:=offset-1;
        feelSArm:=offset
      end;


      function feelEArm(offset : word) : word;

      begin
        while ((not wet[image^[pos.y]^[pos.x+offset]]) and (offset>0)) do
          offset:=offset-1;
        feelEArm:=offset
      end;


      function feelWArm(offset : word) : word;

      begin
        while ((not wet[image^[pos.y]^[pos.x-offset]]) and (offset>0)) do
          offset:=offset-1;
        feelWArm:=offset
      end;


    begin
      seaPointer.x:=feelEArm(filterRadius)-feelWArm(filterRadius);
      seaPointer.y:=feelSArm(filterRadius)-feelNArm(filterRadius)
    end;


    function octopusInSea(pos : pointType) : boolean;

    var   pixelsInSea               : word;
          probablyInSea             : boolean;
          i                         : integer;

    begin
      probablyInSea:=(wet[image^[pos.y]^[pos.x-filterRadius]] and
                      wet[image^[pos.y-filterRadius]^[pos.x]]);
      if probablyInSea then
        begin
          pixelsInSea:=0;
          for i:=-pred(filterRadius) to pred(filterRadius) do
            begin
              if wet[image^[pos.y]^[pos.x+i]] then
                pixelsInSea:=pixelsInSea+1;
              if wet[image^[pos.y+i]^[pos.x]] then
                pixelsInSea:=pixelsInSea+1
            end;
          if (pixelsInSea>=inSeaThreshold) then
            begin
              pupilPoint:=pos;
              octopusInSea:=true
            end
          else
            octopusInSea:=false
        end
      else
        octopusInSea:=false
    end;


  begin
    previousPos:=lastPos;
    lastPos:=pos;
    locateSea(pos,seaPointer);
    if ((seaPointer.x=0) and (seaPointer.y=0)) then
      octopusSwims:=octopusInSea(pos)
    else
      begin
        pos.x:=pos.x+seaPointer.x;
        pos.y:=pos.y+seaPointer.y;
        if (((pos.x=previousPos.x) and (pos.y=previousPos.y)) or
            (depth>=nLeapsMax)) then
          octopusSwims:=false
        else
          octopusSwims:=octopusSwims(pos,succ(depth))
      end
  end;


begin
  pupilFound:=false;
  priLevel:=1;
  nInvestigated:=0;
  lastPos.x:=maxInt;
  lastPos.y:=maxInt;
  repeat
    repeat
      getStartingPoint(startingPoint);
      pupilFound:=octopusSwims(startingPoint,0);
      nInvestigated:=nInvestigated+1
    until (pupilFound or (nInvestigated=priAreas[priLevel]));
    priLevel:=priLevel+1
  until (pupilFound or (priLevel=4));
  for i:=0 to (priAreas[3]-1) do
    startingPoints^[i].visited:=false;
  findPupilPoint:=pupilFound
end;


procedure findPosition(var pupilPoint,position : pointType);

var   ascendingCenter           : pointType;
      descendingCenter          : pointType;


  procedure getMiddlePoint(x,y         : word;
                           direction   : shortInt;
                       var middlePoint : pointType);

  var   leftPoint                 : pointType;
        rightPoint                : pointType;


    procedure searchEdge(x,y       : word;
                         dX,dY     : shortInt;
                     var edgePoint : pointType);

    begin
      inc(x,dX*nonSearchRadius+1);
      inc(y,dY*nonSearchRadius+1);
      repeat
        inc(x,dX);
        inc(y,dY);
        if showSearch then
          markPosition(x,y,asPoint);
        if ((x<=1) or (x>=xSize) or (y<=1) or (y>=ySize)) then
          fatalError('searchEdge: No edge found!')
      until (applySobelMask(x,y,dY,dX)>=sobelThreshold);
      edgePoint.x:=x;
      edgePoint.y:=y
    end;


  begin
    searchEdge(x,y,west,-direction,leftPoint);
    searchEdge(x,y,east,direction,rightPoint);
    middlePoint.x:=leftPoint.x+round((rightPoint.x-leftPoint.x)/2);
    middlePoint.y:=leftPoint.y+round((rightPoint.y-leftPoint.y)/2)
  end;


begin
  with pupilPoint do
    begin
      getMiddlePoint(x,y,south,ascendingCenter);
      getMiddlePoint(x,y,north,descendingCenter);
      position.x:=ascendingCenter.x+descendingCenter.x-x;
      position.y:=ascendingCenter.y+descendingCenter.y-y
    end
end;


function applySobelMask(x,y                     : word;
                        northOrSouth,eastOrWest : shortInt) : integer;

begin
  case northOrSouth of
    north :
      case eastOrWest of
        west : applySobelMask:=2*map[image^[y-2]^[x-2]]+
                                 map[image^[y-2]^[x  ]]+
                                 map[image^[y  ]^[x-2]]-
                                 map[image^[y  ]^[x+2]]-
                                 map[image^[y+2]^[x  ]]-
                               2*map[image^[y+2]^[x+2]];
        east : applySobelMask:=  map[image^[y-2]^[x  ]]+
                               2*map[image^[y-2]^[x+2]]-
                                 map[image^[y  ]^[x-2]]+
                                 map[image^[y  ]^[x+2]]-
                               2*map[image^[y+2]^[x-2]]-
                                 map[image^[y+2]^[x  ]]
      end;
    south :
      case eastOrWest of
        west : applySobelMask:= -map[image^[y-2]^[x  ]]-
                               2*map[image^[y-2]^[x+2]]+
                                 map[image^[y  ]^[x-2]]-
                                 map[image^[y  ]^[x+2]]+
                               2*map[image^[y+2]^[x-2]]+
                                 map[image^[y+2]^[x  ]];
        east : applySobelMask:=-2*map[image^[y-2]^[x-2]]-
                                  map[image^[y-2]^[x  ]]-
                                  map[image^[y  ]^[x-2]]+
                                  map[image^[y  ]^[x+2]]+
                                  map[image^[y+2]^[x  ]]+
                                2*map[image^[y+2]^[x+2]]
      end
  end
end;


procedure initGlobals(xSize,ySize : word);

var   i                         : byte;


  procedure initPointMatrix;

  var   xCenter                   : word;
        yCenter                   : word;
        xRadius                   : word;
        yRadius                   : word;
        nHorizontal               : word;
        nVertical                 : word;
        xStart                    : word;
        yStart                    : word;
        leftOffset                : word;
        priArea1xRadius            : word;
        priArea1yRadius            : word;
        priArea2xRadius            : word;
        priArea2yRadius            : word;
        priCount                  : priAreasType;
        pri                       : byte;
        priOffset                 : word;
        currentX                  : word;
        currentY                  : word;
        i,j                       : word;


    procedure initVariables;

    var   i                         : byte;


      function nPointsInRectangle(x,y : word) : word;

      begin
        if even(trunc(x/2)+trunc(y/2)) then
          nPointsInRectangle:=high(0.5*x*y)
        else
          nPointsInRectangle:=trunc(0.5*x*y)
      end;


    begin
      xCenter:=xSize div 2;
      yCenter:=ySize div 2;
      xRadius:=trunc((xCenter-minPupilRadius)/minPupilRadius);
      yRadius:=trunc((yCenter-minPupilRadius)/minPupilRadius);
      nHorizontal:=2*xRadius+1;
      nVertical:=2*yRadius+1;
      xStart:=xCenter-xRadius*minPupilRadius;
      yStart:=yCenter-yRadius*minPupilRadius;
      currentX:=xStart;
      currentY:=yStart;
      if ((even(xRadius) and even(yRadius)) or
          (odd(xRadius)  and odd(yRadius) )) then
        leftOffset:=0
      else
        leftOffset:=minPupilRadius;
      priArea1xRadius:=xRadius div 3;
      priArea1yRadius:=yRadius div 3;
      priArea2xRadius:=trunc((2/3)*xRadius);
      priArea2yRadius:=trunc((2/3)*yRadius);
      priAreas[1]:=nPointsInRectangle(2*priArea1xRadius+1,2*priArea1yRadius+1);
      priAreas[2]:=nPointsInRectangle(2*priArea2xRadius+1,2*priArea2yRadius+1);
      priAreas[3]:=nPointsInRectangle(nHorizontal,nVertical);
      for i:=1 to 3 do
        priCount[i]:=0;
      getMem(startingPoints,priAreas[3]*sizeOf(point));
    end;


    function getPriority(x,y : word) : byte;


      function inRectangle(x,y,rX,rY : word) : boolean;

      begin
        inRectangle:=((x>=xCenter-rX*minPupilRadius) and
                      (x<=xCenter+rX*minPupilRadius) and
                      (y>=yCenter-rY*minPupilRadius) and
                      (y<=yCenter+rY*minPupilRadius))
      end;


    begin
      if inRectangle(x,y,priArea1xRadius,priArea1yRadius) then
        getPriority:=1
      else if inRectangle(x,y,priArea2xRadius,priArea2yRadius) then
        getPriority:=2
      else
        getPriority:=3
    end;


    function getPriOffset(i : byte) : word;

    begin
      case (i=1) of
        true  : getPriOffset:=0;
        false : getPriOffset:=priAreas[i-1]
      end
    end;


    procedure toggleLeftOffset;

    begin
      case (leftOffset=minPupilRadius) of
        true  : leftOffset:=0;
        false : leftOffset:=minPupilRadius
      end
    end;


  begin
    initVariables;
    repeat
      pri:=getPriority(currentX+leftOffset,currentY);
      priOffset:=getPriOffset(pri);
      startingPoints^[priOffset+priCount[pri]].x:=currentX+leftOffset;
      startingPoints^[priOffset+priCount[pri]].y:=currentY;
      startingPoints^[priOffset+priCount[pri]].visited:=false;
      inc(priCount[pri]);
      inc(currentX,2*minPupilRadius);
      if (currentX+leftOffset>xCenter+xRadius*minPupilRadius) then
        begin
          inc(currentY,minPupilRadius);
          currentX:=xStart;
          toggleLeftOffset
        end
    until (currentY>yStart+2*yRadius*minPupilRadius)
  end;


begin
  minPupilRadius:=round(xSize*minPupilRadiusFraction/100);
  filterRadius:=round(xSize*filterRadiusFraction/100);
  inSeaThreshold:=round(4*wetFraction*pred(filterRadius))+2;
  initPointMatrix;
  for i:=0 to lakeLevel do
    begin
      map[i]:=lakeLevel;
      wet[i]:=true
    end;
  for i:=(lakeLevel+1) to (nGrayLevels-1) do
    begin
      map[i]:=i;
      wet[i]:=false
    end
end;


procedure markPosition(x,y : word; asWhat : byte);

begin
  setColor(63);
  case asWhat of
    asPoint :
      putPixel(startX+x,startY+y,63);
    asStar :
      begin
        line(startX+x-3,startY+y,startX+x+3,startY+y);
        line(startX+x,startY+y-3,startX+x,startY+y+3)
      end;
    asCircle :
      circle(startX+x,startY+y,2)
  end
end;


procedure closeSearch;

var   i                         : word;

begin
  freeMem(startingPoints,priAreas[3]*sizeOf(point));
  for i:=1 to ySize do
    freeMem(image^[i],xSize);
  freeMem(image,4*ySize)
end;


begin
  readInitFile
end.