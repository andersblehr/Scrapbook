unit search;


INTERFACE

uses graph,auxil;

const maxSize                   = 512;
      nGrayLevels               = 64;

      nLeapsMax                 = 10;
      nEstimatesMax             = 55;

      null                      = 0;
      west                      = -1;
      east                      = 1;
      north                     = -1;
      south                     = 1;

      asPoint                   = 0;
      asStar                    = 1;
      asCircle                  = 2;

type  bufferType                = array[1..maxSize] of byte;

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

const lakeLevel                 : byte = 1;   { -l option }
      sobelThreshold            : byte = 5;   { -s option }

      minPupilRadiusFraction    : real = 10;  { Per cent  }
      maxPupilRadiusFraction    : real = 20;  { Per cent  }

      octopusRadiusFraction     : real = 8;   { -o option }
      wetFraction               : real = 0.8; { -w option }

      nAdjustments              : byte = 0;   { -a option }
      nIterations               : word = 1;   { -n option }

      startX                    : word = 0;
      startY                    : word = 0;

      showSearch                : boolean = false;  { -d option }

var   image                     : pixelMatrixPtr;

      xSize                     : word;
      ySize                     : word;

      map                       : mapType;
      wet                       : wetType;

      minPupilRadius            : word;
      octopusRadius             : word;
      nonSearchRadius           : word;
      diagonalNonSearchRadius   : word;
      inSeaThreshold            : word;

      startingPoints            : pointArrayPtr;
      priAreas                  : priAreasType;


function applySobelMask(x,y                     : word;
                        northOrSouth,eastOrWest : shortInt) : integer;

function findPupilPoint(var pupilPoint : pointType) : boolean;

function findPosition(pupilPoint : pointType;
                  var position   : pointType) : boolean;

procedure initGlobals;

procedure markPosition(x,y : word; asWhat : byte);

procedure closeSearch;


IMPLEMENTATION

uses crt,math;

const whiteSpace                = [#9,#32];

type  variableRPtr              = ^variableR;
      variableR                 = record
        name                      : string;
        value                     : real
      end;


(**************************************************************************
 *                                                                        *
 *     Internals                                                          *
 *                                                                        *
 **************************************************************************)


procedure readInitFile;

var   initFile                  : text;
      currentLine               : string;
      variable                  : variableRPtr;


  function nextVariable : variableRPtr;

  var   variableName              : string;
        variableValue             : real;


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


    function getValue : real;

    var   valueAsString             : string;
          value                     : real;
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


    function makeVariable(name : string; value : real) : variableRPtr;

    var   theVariable               : variableRPtr;

    begin
      new(theVariable);
      theVariable^.name:=name;
      theVariable^.value:=value;
      makeVariable:=theVariable
    end;


  begin
    variableName:=nextWord;
    variableValue:=maxInt;
    while ((variableName<>'') and (variableValue=maxInt)) do
      variableValue:=getValue;
    if (variableName='') then
      nextVariable:=nil
    else
      nextVariable:=makeVariable(variableName,variableValue)
  end;


begin
  if fileExists(homePath('_search.rc')) then
    begin
      assign(initFile,homePath('_search.rc'));
      reset(initFile);
      readLn(initFile,currentLine);
      variable:=nextVariable;
      while (variable<>nil) do
        begin
          if (variable^.name='lakeLevel') then
            lakeLevel:=trunc(variable^.value)
          else if (variable^.name='sobelThreshold') then
            sobelThreshold:=trunc(variable^.value)
          else if (variable^.name='minPupilRadiusFraction') then
            minPupilRadiusFraction:=variable^.value
          else if (variable^.name='maxPupilRadiusFraction') then
            maxPupilRadiusFraction:=variable^.value
          else if (variable^.name='octopusRadiusFraction') then
            octopusRadiusFraction:=variable^.value
          else if (variable^.name='wetFraction') then
            wetFraction:=trunc(variable^.value)
          else if (variable^.name='nAdjustments') then
            nAdjustments:=trunc(variable^.value)
          else if (variable^.name='nIterations') then
            nIterations:=trunc(variable^.value);
          variable:=nextVariable
        end;
      close(initFile)
    end
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
      seaPointer.x:=feelEArm(octopusRadius)-feelWArm(octopusRadius);
      seaPointer.y:=feelSArm(octopusRadius)-feelNArm(octopusRadius)
    end;


    function octopusInSea(pos : pointType) : boolean;

    var   pixelsInSea               : word;
          probablyInSea             : boolean;
          i                         : integer;

    begin
      probablyInSea:=(wet[image^[pos.y]^[pos.x-octopusRadius]] and
                      wet[image^[pos.y-octopusRadius]^[pos.x]]);
      if probablyInSea then
        begin
          pixelsInSea:=0;
          for i:=(1-octopusRadius) to (octopusRadius-1) do
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
          octopusSwims:=octopusSwims(pos,depth+1)
      end
  end;


begin
  priLevel:=1;
  nInvestigated:=0;
  lastPos.x:=maxInt;
  lastPos.y:=maxInt;
  repeat
    repeat
      repeat
        i:=random(priAreas[priLevel])
      until (not startingPoints^[i].visited);
      startingPoint.x:=startingPoints^[i].x;
      startingPoint.y:=startingPoints^[i].y;
      startingPoints^[i].visited:=true;
      pupilFound:=octopusSwims(startingPoint,0);
      nInvestigated:=nInvestigated+1
    until (pupilFound or (nInvestigated=priAreas[priLevel]));
    priLevel:=priLevel+1
  until (pupilFound or (priLevel=4));
  for i:=0 to (priAreas[priLevel-1]-1) do
    startingPoints^[i].visited:=false;
  findPupilPoint:=pupilFound
end;


function findPosition(pupilPoint : pointType;
                  var position   : pointType) : boolean;

var   nEstimates                : word;
      previousEstimate          : pointType;
      break                     : boolean;


  procedure iterateOnce(origin   : pointType;
                    var estimate : pointType);

  var   NSCentre                  : word;
        WECentre                  : word;


    procedure NS_getMiddlePoint(x,y : word);

    var   NPoint                    : word;
          SPoint                    : word;


      procedure N_searchEdge(x,y : word);

      begin
        y:=y-nonSearchRadius;
        while wet[image^[y-2]^[x]] do
          y:=y-1;
        repeat
          y:=y-1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,north,null)>=sobelThreshold);
        NPoint:=y
      end;


      procedure S_searchEdge(x,y : word);

      begin
        y:=y+nonSearchRadius;
        while wet[image^[y+2]^[x]] do
          y:=y+1;
        repeat
          y:=y+1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,south,null)>=sobelThreshold);
        SPoint:=y
      end;


    begin
      N_searchEdge(x,y);
      S_searchEdge(x,y);
      NSCentre:=NPoint+((SPoint-NPoint) div 2)
    end;


    procedure WE_getMiddlePoint(x,y : word);

    var   WPoint                    : word;
          EPoint                    : word;


      procedure W_searchEdge(x,y : word);

      begin
        x:=x-nonSearchRadius;
        while wet[image^[y]^[x-2]] do
          x:=x-1;
        repeat
          x:=x-1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,null,west)>=sobelThreshold);
        WPoint:=x
      end;


      procedure E_searchEdge(x,y : word);

      begin
        x:=x+nonSearchRadius;
        while wet[image^[y]^[x+2]] do
          x:=x+1;
        repeat
          x:=x+1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,null,east)>=sobelThreshold);
        EPoint:=x
      end;


    begin
      W_searchEdge(x,y);
      E_searchEdge(x,y);
      WECentre:=WPoint+((EPoint-WPoint) div 2);
    end;


  begin
    with origin do
      begin
        NS_getMiddlePoint(x,y);
        WE_getMiddlePoint(x,y);
        estimate.x:=(nEstimates*estimate.x+WECentre) div (nEstimates+1);
        estimate.y:=(nEstimates*estimate.y+NSCentre) div (nEstimates+1);
        nEstimates:=nEstimates+1
      end
  end;


  procedure iterateTwice(origin   : pointType;
                     var estimate : pointType);

  var   NWSECentre                : pointType;
        SWNECentre                : pointType;


    procedure NWSE_getMiddlePoint(x,y : word);

    var   NWPoint                   : pointType;
          SEPoint                   : pointType;


      procedure NW_searchEdge(x,y : word);

      begin
        x:=x-diagonalNonSearchRadius;
        y:=y-diagonalNonSearchRadius;
        while wet[image^[y-2]^[x-2]] do
          begin
            x:=x-1;
            y:=y-1
          end;
        repeat
          x:=x-1;
          y:=y-1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,north,west)>=sobelThreshold);
        NWPoint.x:=x;
        NWPoint.y:=y
      end;


      procedure SE_searchEdge(x,y : word);

      begin
        x:=x+diagonalNonSearchRadius;
        y:=y+diagonalNonSearchRadius;
        while wet[image^[y+2]^[x+2]] do
          begin
            x:=x+1;
            y:=y+1
          end;
        repeat
          x:=x+1;
          y:=y+1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,south,east)>=sobelThreshold);
        SEPoint.x:=x;
        SEPoint.y:=y
      end;


    begin
      NW_searchEdge(x,y);
      SE_searchEdge(x,y);
      NWSECentre.x:=NWPoint.x+((SEPoint.x-NWPoint.x) div 2);
      NWSECentre.y:=NWPoint.y+((SEPoint.y-NWPoint.y) div 2)
    end;


    procedure SWNE_getMiddlePoint(x,y : word);

    var   SWPoint                   : pointType;
          NEPoint                   : pointType;


      procedure SW_searchEdge(x,y : word);

      begin
        x:=x-diagonalNonSearchRadius;
        y:=y+diagonalNonSearchRadius;
        while wet[image^[y+2]^[x-2]] do
          begin
            x:=x-1;
            y:=y+1
          end;
        repeat
          x:=x-1;
          y:=y+1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,south,west)>=sobelThreshold);
        SWPoint.x:=x;
        SWPoint.y:=y
      end;


      procedure NE_searchEdge(x,y : word);

      begin
        x:=x+diagonalNonSearchRadius;
        y:=y-diagonalNonSearchRadius;
        while wet[image^[y-2]^[x+2]] do
          begin
            x:=x+1;
            y:=y-1
          end;
        repeat
          x:=x+1;
          y:=y-1;
          if showSearch then
            markPosition(x,y,asPoint)
        until (applySobelMask(x,y,north,east)>=sobelThreshold);
        NEPoint.x:=x;
        NEPoint.y:=y
      end;


    begin
      SW_searchEdge(x,y);
      NE_searchEdge(x,y);
      SWNECentre.x:=SWPoint.x+((NEPoint.x-SWPoint.x) div 2);
      SWNECentre.y:=SWPoint.y+((NEPoint.y-SWPoint.y) div 2)
    end;


  begin
    with origin do
      begin
        NWSE_getMiddlePoint(x,y);
        SWNE_getMiddlePoint(x,y);
        estimate.x:=(nEstimates*estimate.x+
                     (NWSECentre.x+SWNECentre.x-x)) div (nEstimates+1);
        estimate.y:=(nEstimates*estimate.y+
                     (NWSECentre.y+SWNECentre.y-y)) div (nEstimates+1);
        nEstimates:=nEstimates+1
      end
  end;


begin
  nEstimates:=0;
  position.x:=0;
  position.y:=0;
  repeat
    previousEstimate:=position;
    iterateOnce(pupilPoint,position);
    break:=((nEstimates>nEstimatesMax) or
            ((position.x=previousEstimate.x) and
             (position.y=previousEstimate.y)));
    if (not break) then
      begin
        iterateTwice(pupilPoint,position);
        break:=((nEstimates>nEstimatesMax) or
                ((position.x=previousEstimate.x) and
                 (position.y=previousEstimate.y)));
        pupilPoint:=position
      end
  until break;
  findPosition:=(nEstimates<=nEstimatesMax)
end;


function applySobelMask(x,y                     : word;
                        northOrSouth,eastOrWest : shortInt) : integer;

begin
  case northOrSouth of
    null :
      case eastOrWest of
        null : applySobelMask:=0;
        west : applySobelMask:=   map[image^[y-2]^[x-2]]-
                                  map[image^[y-2]^[x+2]]+
                                2*map[image^[y  ]^[x-2]]-
                                2*map[image^[y  ]^[x+2]]+
                                  map[image^[y+2]^[x-2]]-
                                  map[image^[y+2]^[x+2]];
        east : applySobelMask:=  -map[image^[y-2]^[x-2]]+
                                  map[image^[y-2]^[x+2]]-
                                2*map[image^[y  ]^[x-2]]+
                                2*map[image^[y  ]^[x+2]]-
                                  map[image^[y+2]^[x-2]]+
                                  map[image^[y+2]^[x+2]]
      end;
    north :
      case eastOrWest of
        null : applySobelMask:=   map[image^[y-2]^[x-2]]+
                                2*map[image^[y-2]^[x  ]]+
                                  map[image^[y-2]^[x+2]]-
                                  map[image^[y+2]^[x-2]]-
                                2*map[image^[y+2]^[x  ]]-
                                  map[image^[y+2]^[x+2]];
        west : applySobelMask:= 2*map[image^[y-2]^[x-2]]+
                                  map[image^[y-2]^[x  ]]+
                                  map[image^[y  ]^[x-2]]-
                                  map[image^[y  ]^[x+2]]-
                                  map[image^[y+2]^[x  ]]-
                                2*map[image^[y+2]^[x+2]];
        east : applySobelMask:=   map[image^[y-2]^[x  ]]+
                                2*map[image^[y-2]^[x+2]]-
                                  map[image^[y  ]^[x-2]]+
                                  map[image^[y  ]^[x+2]]-
                                2*map[image^[y+2]^[x-2]]-
                                  map[image^[y+2]^[x  ]]
      end;
    south :
      case eastOrWest of
        null : applySobelMask:=  -map[image^[y-2]^[x-2]]-
                                2*map[image^[y-2]^[x  ]]-
                                  map[image^[y-2]^[x+2]]+
                                  map[image^[y+2]^[x-2]]+
                                2*map[image^[y+2]^[x  ]]+
                                  map[image^[y+2]^[x+2]];
        west : applySobelMask:=  -map[image^[y-2]^[x  ]]-
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


procedure initGlobals;

var   i                         : byte;


  procedure initPointMatrix;

  var   xCentre                   : word;
        yCentre                   : word;
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
      xCentre:=xSize div 2;
      yCentre:=ySize div 2;
      xRadius:=trunc((xCentre-minPupilRadius)/minPupilRadius);
      yRadius:=trunc((yCentre-minPupilRadius)/minPupilRadius);
      nHorizontal:=2*xRadius+1;
      nVertical:=2*yRadius+1;
      xStart:=xCentre-xRadius*minPupilRadius;
      yStart:=yCentre-yRadius*minPupilRadius;
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
        inRectangle:=((x>=xCentre-rX*minPupilRadius) and
                      (x<=xCentre+rX*minPupilRadius) and
                      (y>=yCentre-rY*minPupilRadius) and
                      (y<=yCentre+rY*minPupilRadius))
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
      if (currentX+leftOffset>xCentre+xRadius*minPupilRadius) then
        begin
          inc(currentY,minPupilRadius);
          currentX:=xStart;
          toggleLeftOffset
        end
    until (currentY>yStart+2*yRadius*minPupilRadius)
  end;


begin
  randomize;
  minPupilRadius:=round(xSize*minPupilRadiusFraction/100);
  octopusRadius:=round(xSize*octopusRadiusFraction/100);
{
  nonSearchRadius:=trunc(octopusRadius/sqrt(2));
  diagonalNonSearchRadius:=trunc(nonSearchRadius/sqrt(2));
}
  nonSearchRadius:=1;
  diagonalNonSearchRadius:=1;
  inSeaThreshold:=round(4*wetFraction*pred(octopusRadius))+2;
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