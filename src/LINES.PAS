program lines;

uses crt,graph,auxil,search,SVGA;

const displayCenterPoint        : boolean = false;  { -c option }

var   pupilPoint                : pointType;
      pointToDisplay            : pointType;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure getParameters(numberOfParameters : word);

  var   i                         : byte;
        thisParameter             : string;


    function getParameterValue(parameterString : string) : real;

    var   value                     : real;
          result                    : integer;

    begin
      val(copy(parameterString,3,length(parameterString)-2),value,result);
      if (result=0) then
        getParameterValue:=value
      else
        fatalError('Illegal parameter value, must be a number!')
    end;


  begin
    for i:=1 to numberOfParameters-1 do
      begin
        thisParameter:=paramStr(i);
        if (thisParameter[1]='-') then
          case thisParameter[2] of
            'c' : displayCenterPoint:=true;
            'l' : lakeLevel:=trunc(getParameterValue(thisParameter));
            'o' : octopusRadiusFraction:=getParameterValue(thisParameter);
            's' : sobelThreshold:=trunc(getParameterValue(thisParameter));
            'q' : nonSearchRadius:=trunc(getParameterValue(thisParameter));
            'w' : wetFraction:=getParameterValue(thisParameter);
            'a' : nAdjustments:=trunc(getParameterValue(thisParameter))
          else
            fatalError('Illegal option: -'+thisParameter[2])
          end
        else
          fatalError('Cannot specify more than one file: '+thisParameter)
      end;
    fileName:=picturePath(paramStr(numberOfParameters));
  end;


  procedure initVariables;

  begin
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    initGlobals
  end;


begin
  if (paramCount<>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
        begin
          SVGA_initGraphics(mode1024x768);
          SVGA_setBlackAndWhitePalette;
          assign(inputFile,fileName);
          reset(inputFile,1);
          initVariables;
          getMem(image,4*ySize);
          for i:=1 to ySize do
            begin
              blockRead(inputFile,buffer,xSize);
              getMem(image^[i],xSize);
              for j:=1 to xSize do
                begin
                  image^[i]^[j]:=buffer[j];
                  putPixel(j,i,buffer[j])
                end
            end;
          close(inputFile)
        end
      else
        fatalError('Image file not found!')
    end
  else
    fatalError('Usage: lines [-acloqsw] file[.pic]')
end;


procedure treatLines;

type  sobelLine                 = array[1..maxSize] of word;

var   ascendingLine             : sobelLine;
      descendingLine            : sobelLine;

      ascendingLineLeftSize     : word;
      ascendingLineRightSize    : word;
      descendingLineLeftSize    : word;
      descendingLineRightSize   : word;
      ascendingLineSize         : word;
      descendingLineSize        : word;

      maxSobel                  : word;


  procedure initVariables;

  var   i                         : integer;


    function getLineSize(northOrSouth,eastOrWest : shortInt) : word;


      function min(x1,x2 : integer) : integer;

      begin
        if (x1<x2) then
          min:=x1
        else
          min:=x2
      end;


    begin
      with pointToDisplay do
        case northOrSouth of
          north :
            case eastOrWest of
              east : getLineSize:=min(xSize-x,y);
              west : getLineSize:=min(x,y)
            end;
          south :
            case eastOrWest of
              east : getLineSize:=min(xSize-x,ySize-y);
              west : getLineSize:=min(x,ySize-y)
            end
        end
    end;


  begin
    maxSobel:=0;
    ascendingLineLeftSize:=getLineSize(north,west);
    ascendingLineRightSize:=getLineSize(south,east);
    descendingLineLeftSize:=getLineSize(south,west);
    descendingLineRightSize:=getLineSize(north,east);
    ascendingLineSize:=ascendingLineLeftSize+ascendingLineRightSize-2;
    descendingLineSize:=descendingLineLeftSize+descendingLineRightSize-2;
    ascendingLine[1]:=0;
    ascendingLine[ascendingLineSize]:=0;
    descendingLine[1]:=0;
    descendingLine[descendingLineSize]:=0;
    for i:=-nonSearchRadius to nonSearchRadius do
      begin
        ascendingLine[ascendingLineLeftSize+i]:=0;
        descendingLine[descendingLineLeftSize+i]:=0
      end
  end;


  procedure applySobelMasks;

  var   i                         : word;


    function applySobelMaskAt(x,y                     : word;
                              northOrSouth,eastOrWest : shortInt) : word;

    var   sobelValue                : integer;

    begin
      sobelValue:=applySobelMask(x,y,northOrSouth,eastOrWest);
      if (sobelValue>maxSobel) then
        maxSobel:=sobelValue
      else if (sobelValue<0) then
        sobelValue:=0;
      applySobelMaskAt:=sobelValue
    end;


  begin
    with pointToDisplay do
      begin
        for i:=(ascendingLineLeftSize-2) downTo nonSearchRadius do
          ascendingLine[ascendingLineLeftSize-i]:=
              applySobelMaskAt(x-i,y-i,north,west);
        for i:=nonSearchRadius to (ascendingLineRightSize-3) do
          ascendingLine[ascendingLineLeftSize+i]:=
              applySobelMaskAt(x+i,y+i,south,east);
        for i:=(descendingLineLeftSize-2) downTo nonSearchRadius do
          descendingLine[descendingLineLeftSize-i]:=
              applySobelMaskAt(x-i,y+i,south,west);
        for i:=nonSearchRadius to (descendingLineRightSize-3) do
          descendingLine[descendingLineLeftSize+i]:=
              applySobelMaskAt(x+i,y-i,north,east)
      end
  end;


  procedure presentLines;

  var   pixelLinesY               : word;
        sobelLinesY               : word;
        lengthOf1stAxis           : word;
        lengthOf2ndAxis           : word;
        leftStart                 : word;
        rightStart                : word;
        unitPixelAxis             : real;
        unitSobelAxis             : real;
        pixelSpacing              : real;
        sobelSpacing              : real;
        ascendingUnit             : real;
        descendingUnit            : real;
        ascendingSpacing          : real;
        descendingSpacing         : real;


    procedure initVariables;

    begin
      pixelLinesY:=ySize+round((getMaxY-ySize)/2)-5;
      sobelLinesY:=getMaxY-10;
      lengthOf1stAxis:=round(getMaxX/2)-20;
      lengthOf2ndAxis:=round((getMaxY-ySize)/2)-20;
      leftStart:=5;
      rightStart:=round(getMaxX/2)+5;
      ascendingUnit:=lengthOf1stAxis/ascendingLineSize;
      descendingUnit:=lengthOf1stAxis/descendingLineSize;
      ascendingSpacing:=10*ascendingUnit;
      descendingSpacing:=10*descendingUnit;
      unitPixelAxis:=lengthOf2ndAxis/64;
      unitSobelAxis:=lengthOf2ndAxis/maxSobel;
      pixelSpacing:=lengthOf2ndAxis/8;
      sobelSpacing:=5*unitSobelAxis;
      setColor(63)
    end;


    procedure drawCoordinateSystems;


      procedure drawSystem(xPos,yPos                     : word;
                           ticks1stAxis,ticks2ndAxis     : byte;
                           spacing1stAxis,spacing2ndAxis : real);

      var   i                         : word;

      begin
        line(xPos,yPos,xPos+lengthOf1stAxis,yPos);
        line(xPos,yPos-lengthOf2ndAxis,xPos,yPos);
        for i:=0 to ticks2ndAxis do
          line(xPos-4,yPos-round(i*spacing2ndAxis),
               xPos,yPos-round(i*spacing2ndAxis));
        for i:=0 to ticks1stAxis do
          line(xPos+round(i*spacing1stAxis),yPos+1,
               xPos+round(i*spacing1stAxis),yPos+5)
      end;


    begin
      drawSystem(leftStart,pixelLinesY,ascendingLineSize div 10,8,
                 ascendingSpacing,pixelSpacing);
      drawSystem(rightStart,pixelLinesY,descendingLineSize div 10,8,
                 descendingSpacing,pixelSpacing);
      drawSystem(leftStart,sobelLinesY,ascendingLineSize div 10,
                 maxSobel div 5,ascendingSpacing,sobelSpacing);
      drawSystem(rightStart,sobelLinesY,descendingLineSize div 10,
                 maxSobel div 5,descendingSpacing,sobelSpacing)
    end;


    procedure drawCharacteristics(x,y : word);

    var   i                         : integer;

    begin
      for i:=-(ascendingLineLeftSize-2) to ascendingLineRightSize do
        begin
          line(leftStart+round(ascendingUnit*(ascendingLineLeftSize+i-2)),
               pixelLinesY-round(unitPixelAxis*map[image^[y+i-1]^[x+i-1]]),
               leftStart+round(ascendingUnit*(ascendingLineLeftSize+i-1)),
               pixelLinesY-round(unitPixelAxis*map[image^[y+i]^[x+i]]));
          line(x+i-1,y+i-1,x+i,y+i)
        end;
      for i:=-(descendingLineLeftSize-2) to descendingLineRightSize do
        begin
          line(rightStart+round(descendingUnit*(descendingLineLeftSize+i-2)),
               pixelLinesY-round(unitPixelAxis*map[image^[y-(i-1)]^[x+i-1]]),
               rightStart+round(descendingUnit*(descendingLineLeftSize+i-1)),
               pixelLinesY-round(unitPixelAxis*map[image^[y-i]^[x+i]]));
          line(x+i-1,y-(i-1),x+i,y-i)
        end;
      for i:=2 to ascendingLineSize do
        line(leftStart+round(ascendingUnit*(i-2)),
             sobelLinesY-round(unitSobelAxis*ascendingLine[i-1]),
             leftStart+round(ascendingUnit*(i-1)),
             sobelLinesY-round(unitSobelAxis*ascendingLine[i]));
      for i:=2 to descendingLineSize do
        line(rightStart+round(descendingUnit*(i-2)),
             sobelLinesY-round(unitSobelAxis*descendingLine[i-1]),
             rightStart+round(descendingUnit*(i-1)),
             sobelLinesY-round(unitSobelAxis*descendingLine[i]))
    end;


    procedure markPositionInGraphs(x,y : word);


      procedure markPosition(start,xPos,yPos         : word;
                             unit1stAxis,unit2ndAxis : real;
                             threshold               : word);

      begin
        line(start+round(unit1stAxis*(xPos-octopusRadius)),yPos,
             start+round(unit1stAxis*(xPos-octopusRadius)),
             yPos-lengthOf2ndAxis);
        line(start+round(unit1stAxis*xPos),yPos,
             start+round(unit1stAxis*xPos),yPos-lengthOf2ndAxis);
        line(start+round(unit1stAxis*(xPos+octopusRadius)),yPos,
             start+round(unit1stAxis*(xPos+octopusRadius)),
             yPos-lengthOf2ndAxis);
        line(start,yPos-round(unit2ndAxis*threshold),
             start+lengthOf1stAxis,yPos-round(unit2ndAxis*threshold))
      end;


    begin
      setColor(30);
      markPosition(leftStart,ascendingLineLeftSize,pixelLinesY,
                   ascendingUnit,unitPixelAxis,lakeLevel);
      markPosition(leftStart,ascendingLineLeftSize,sobelLinesY,
                   ascendingUnit,unitSobelAxis,sobelThreshold);
      markPosition(rightStart,descendingLineLeftSize,pixelLinesY,
                   descendingUnit,unitPixelAxis,lakeLevel);
      markPosition(rightStart,descendingLineLeftSize,sobelLinesY,
                   descendingUnit,unitSobelAxis,sobelThreshold)
    end;


  begin
    initVariables;
    drawCoordinateSystems;
    with pointToDisplay do
      begin
        drawCharacteristics(x,y);
        markPositionInGraphs(x,y);
        setColor(63);
        circle(x,y,octopusRadius)
      end
  end;


begin
  if findPupilPoint(pupilPoint) then
    begin
      if displayCenterPoint then
        findPosition(pupilPoint,pointToDisplay)
      else
        pointToDisplay:=pupilPoint;
      initVariables;
      applySobelMasks;
      presentLines
    end
  else
    begin
      closeGraph;
      fatalError('No pupil was found!')
    end
end;


procedure writeData;

var   positionMessage           : string;

begin
  setTextStyle(defaultFont,horizDir,1);
  setTextJustify(leftText,topText);
  setColor(63);
  if ((pointToDisplay.x=pupilPoint.x) and
      (pointToDisplay.y=pupilPoint.y)) then
    positionMessage:='Position of pupil point'
  else
    positionMessage:='Center position found';
  with pointToDisplay do
    outTextXY(xSize+20,1,positionMessage+': ('+
        intString(x)+','+intString(y)+')')
end;


procedure finishOff;

var   i                         : word;

begin
  closeSearch;
  readKey;
  closeGraph
end;


begin
  init;
  treatLines;
  writeData;
  finishOff
end.