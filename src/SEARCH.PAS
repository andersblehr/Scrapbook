unit search;


INTERFACE

uses auxil;

const maxSize                   = 512;
      numberOfGrayLevels        = 64;

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

      mapType                   = array[0..numberOfGrayLevels] of byte;

const filterRadius              : byte = 0;
      filterThreshold           : byte = 1;
      lakeLevel                 : byte = 0;
      sobelThreshold            : byte = 5;
      nonSearchRadius           : byte = 0;

      minPupilRadiusFraction    : byte = 5;   (* Per cent *)
      maxPupilRadiusFraction    : byte = 20;  (* Per cent *)

      searchAreaLeftFraction    : byte = 0;   (* Per cent *)
      searchAreaRightFraction   : byte = 100; (* Per cent *)
      searchAreaTopFraction     : byte = 0;   (* Per cent *)
      searchAreaBottomFraction  : byte = 100; (* Per cent *)

      numberOfIterations        : word = 1;

      startX                    : word = 0;
      startY                    : word = 0;

      showSearch                : boolean = false;

var   image                     : pixelMatrixPtr;
      map                       : mapType;

      searchAreaLeft            : word;
      searchAreaTop             : word;
      xSizeSearchArea           : word;
      ySizeSearchArea           : word;
      minSearchStep             : word;

      minPupilRadius            : word;


function applySobelMask(x,y                     : word;
                        northOrSouth,eastOrWest : shortInt) : integer;

function findPupilPoint(pupilPoint : pointPtr) : boolean;

procedure findPosition(pupilPoint,position : pointPtr);

procedure initGlobals(xSize,ySize : word);

procedure markPosition(x,y : word; asWhat : byte);


IMPLEMENTATION

uses crt,graph;

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
            if (variable^.name='filterRadius') then
              filterRadius:=variable^.value
            else if (variable^.name='filterThreshold') then
              filterThreshold:=variable^.value
            else if (variable^.name='lakeLevel') then
              lakeLevel:=variable^.value
            else if (variable^.name='sobelThreshold') then
              sobelThreshold:=variable^.value
            else if (variable^.name='nonSearchRadius') then
              nonSearchRadius:=variable^.value
            else if (variable^.name='minPupilRadiusFraction') then
              minPupilRadiusFraction:=variable^.value
            else if (variable^.name='maxPupilRadiusFraction') then
              maxPupilRadiusFraction:=variable^.value
            else if (variable^.name='searchAreaLeftFraction') then
              searchAreaLeftFraction:=variable^.value
            else if (variable^.name='searchAreaRightFraction') then
              searchAreaRightFraction:=variable^.value
            else if (variable^.name='searchAreaTopFraction') then
              searchAreaTopFraction:=variable^.value
            else if (variable^.name='searchAreaBottomFraction') then
              searchAreaBottomFraction:=variable^.value
            else if (variable^.name='numberOfIterations') then
              numberOfIterations:=variable^.value;
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


function findPupilPoint(pupilPoint : pointPtr) : boolean;


  function getFilterValue(x,y : word) : byte;

  var   filterSum                 : longInt;
        i                         : word;

  begin
    filterSum:=map[image^[searchAreaTop+y]^[searchAreaLeft+x]];
    for i:=1 to (filterRadius div 2) do
      filterSum:=filterSum+
          map[image^[searchAreaTop+y]^[searchAreaLeft+x-2*i]]+
          map[image^[searchAreaTop+y]^[searchAreaLeft+x+2*i]]+
          map[image^[searchAreaTop+y-2*i]^[searchAreaLeft+x]]+
          map[image^[searchAreaTop+y+2*i]^[searchAreaLeft+x]];
    getFilterValue:=round(filterSum/(2*filterRadius+1))
  end;


  function ySearch(y,currentYSize : word) : boolean;

  var   newYStep                  : word;


    function xSearch(x,currentXSize : word) : boolean;

    var   newXStep                  : word;


    begin
      if (getFilterValue(x,y)<=filterThreshold) then
        begin
          pupilPoint^.x:=searchAreaLeft+x;
          pupilPoint^.y:=searchAreaTop+y;
          xSearch:=true
        end
      else
        begin
          newXStep:=round(currentXSize/2);
          if (newXStep>minSearchStep) then
            xSearch:=(xSearch(x-newXStep,newXStep) or
                      xSearch(x+newXStep,newXStep))
          else
            xSearch:=false
        end
    end;


  begin
    if xSearch(xSizeSearchArea div 2,xSizeSearchArea div 2) then
      ySearch:=true
    else
      begin
        newYStep:=round(currentYSize/2);
        if (newYStep>minSearchStep) then
          ySearch:=(ySearch(y-newYStep,newYStep) or
                    ySearch(y+newYStep,newYStep))
        else
          ySearch:=false
      end
  end;


begin
  findPupilPoint:=ySearch(ySizeSearchArea div 2,ySizeSearchArea div 2)
end;


procedure findPosition(pupilPoint,position : pointPtr);

var   ascendingCenter           : pointPtr;
      descendingCenter          : pointPtr;


  procedure getMiddlePoint(x,y         : word;
                           direction   : shortInt;
                           middlePoint : pointPtr);

  var   leftPoint                 : pointPtr;
        rightPoint                : pointPtr;


    procedure searchEdge(x,y : word; dX,dY : shortInt; edgePoint : pointPtr);

    begin
      inc(x,dX*nonSearchRadius+1);
      inc(y,dY*nonSearchRadius+1);
      repeat
        inc(x,dX);
        inc(y,dY);
        if showSearch then
          markPosition(x,y,asPoint);
        if ((x<=searchAreaLeft) or (x>=searchAreaLeft+xSizeSearchArea) or
            (y<=searchAreaTop ) or (y>=searchAreaTop +ySizeSearchArea)) then
          fatalError('searchEdge: No edge found!')
      until (applySobelMask(x,y,dY,dX)>=sobelThreshold);
      makePoint(x,y,edgePoint)
    end;


  begin
    new(leftPoint);
    new(rightPoint);
    searchEdge(x,y,west,-direction,leftPoint);
    searchEdge(x,y,east,direction,rightPoint);
    makePoint(leftPoint^.x+round((rightPoint^.x-leftPoint^.x)/2),
              leftPoint^.y+round(integer(rightPoint^.y-leftPoint^.y)/2),
              middlePoint);
    dispose(rightPoint);
    dispose(leftPoint)
  end;


begin
  new(ascendingCenter);
  new(descendingCenter);
  with pupilPoint^ do
    begin
      getMiddlePoint(x,y,south,ascendingCenter);
      getMiddlePoint(x,y,north,descendingCenter);
      position^.x:=ascendingCenter^.x+descendingCenter^.x-x;
      position^.y:=ascendingCenter^.y+descendingCenter^.y-y
    end;
  dispose(descendingCenter);
  dispose(ascendingCenter)
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

begin
  searchAreaLeft:=round(xSize*searchAreaLeftFraction/100);
  searchAreaTop:=round(ySize*searchAreaTopFraction/100);
  xSizeSearchArea:=round(xSize*searchAreaRightFraction/100)-searchAreaLeft;
  ySizeSearchArea:=round(ySize*searchAreaBottomFraction/100)-searchAreaTop;
  minPupilRadius:=round(xSize*minPupilRadiusFraction/100);
  minSearchStep:=round(minPupilRadius/8);
  for i:=0 to lakeLevel do
    map[i]:=lakeLevel;
  for i:=(lakeLevel+1) to (numberOfGrayLevels-1) do
    map[i]:=i
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


begin
  readInitFile
end.