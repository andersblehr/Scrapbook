program lines;

uses crt,graph,paths,auxil,search,SVGA;

type  sobelLinePtr              = ^sobelLine;
      sobelLine                 = array[1..maxSize] of shortInt;

const displayCenterPoint        : boolean = false;

var   xSize                     : word;
      ySize                     : word;
      sobelXLine                : sobelLinePtr;
      sobelYLine                : sobelLinePtr;

      pointToDisplay            : pointPtr;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure getParameters(numberOfParameters : word);

  var   i                         : byte;
        thisParameter             : string;


    function getParameterValue(parameterString : string) : byte;

    var   value                     : byte;
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
            'r' : filterRadius:=getParameterValue(thisParameter);
            't' : filterThreshold:=getParameterValue(thisParameter);
            's' : sobelThreshold:=getParameterValue(thisParameter)
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
    assign(inputFile,fileName);
    reset(inputFile,1);
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    initGlobals(xSize,ySize)
  end;


begin
  if (paramCount<>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
        begin
          initSVGAGraphics;
          setBlackAndWhitePalette;
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
          close(inputFile);
          getMem(sobelXLine,xSize);
          getMem(sobelYLine,ySize)
        end
      else
        fatalError('Image file not found!')
    end
  else
    fatalError('Usage: lines [-c][-r<radius>][-t<threshold>][-s<threshold>] file[.pic]')
end;


procedure treatLines;

var   minSobel                  : word;
      maxSobel                  : word;
      sobelExtent               : word;


  procedure applySobelMasks;

  const horizontal                = 0;
        vertical                  = 1;

  var   pos                       : word;


    function applySobelMaskAt(x,y : word; direction : byte) : byte;

    const xSobelMask                = 0;
          ySobelMask                = 1;

    var   sobelValue                : shortInt;

    begin
      case direction of
        horizontal : sobelValue:=applySobelMask(x,y,ySobelMask);
        vertical   : sobelValue:=applySobelMask(x,y,xSobelMask)
      end;
      if (sobelValue>maxSobel) then
        maxSobel:=sobelValue;
      if (sobelValue<minSobel) then
        minSobel:=sobelValue;
      applySobelMaskAt:=sobelValue
    end;


  begin
    minSobel:=255;
    maxSobel:=0;
    sobelXLine^[1]:=1;
    sobelYLine^[1]:=1;
    sobelXLine^[xSize]:=1;
    sobelYLine^[ySize]:=1;
    with pointToDisplay^ do
      begin
        for pos:=2 to xSize-1 do
          sobelXLine^[pos]:=applySobelMaskAt(pos,y,horizontal);
        for pos:=2 to ySize-1 do
          sobelYLine^[pos]:=applySobelMaskAt(x,pos,vertical)
      end;
    sobelExtent:=maxSobel-minSobel
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
        xUnit                     : real;
        yUnit                     : real;
        xSpacing                  : real;
        ySpacing                  : real;


    procedure initVariables;

    begin
      pixelLinesY:=ySize+round((getMaxY-ySize)/2)-5;
      sobelLinesY:=getMaxY-10;
      lengthOf1stAxis:=round(getMaxX/2)-20;
      lengthOf2ndAxis:=round((getMaxY-ySize)/2)-20;
      leftStart:=5;
      rightStart:=round(getMaxX/2)+5;
      xUnit:=lengthOf1stAxis/xSize;
      yUnit:=lengthOf1stAxis/ySize;
      xSpacing:=10*xUnit;
      ySpacing:=10*yUnit;
      unitPixelAxis:=lengthOf2ndAxis/64;
      unitSobelAxis:=lengthOf2ndAxis/sobelExtent;
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
      drawSystem(leftStart,pixelLinesY,
                 xSize div 10,8,xSpacing,pixelSpacing);
      drawSystem(rightStart,pixelLinesY,
                 ySize div 10,8,ySpacing,pixelSpacing);
      drawSystem(leftStart,sobelLinesY,
                 xSize div 10,sobelExtent div 5,xSpacing,sobelSpacing);
      drawSystem(rightStart,sobelLinesY,
                 ySize div 10,sobelExtent div 5,ySpacing,sobelSpacing)
    end;


    procedure drawCharacteristics(x,y : word);

    var   xPos                      : word;
          yPos                      : word;

    begin
      for xPos:=2 to xSize do
        begin
          line(leftStart+round(xUnit*(xPos-2)),
               pixelLinesY-round(unitPixelAxis*image^[y]^[xPos-1]),
               leftStart+round(xUnit*(xPos-1)),
               pixelLinesY-round(unitPixelAxis*image^[y]^[xPos]));
          line(leftStart+round(xUnit*(xPos-2)),
               sobelLinesY+round(minSobel*unitSobelAxis)-
                   round(unitSobelAxis*sobelXLine^[xPos-1]),
               leftStart+round(xUnit*(xPos-1)),
               sobelLinesY+round(minSobel*unitSobelAxis)-
                   round(unitSobelAxis*sobelXLine^[xPos]))
        end;
      for yPos:=2 to ySize do
        begin
          line(rightStart+round(yUnit*(yPos-2)),
               pixelLinesY-round(unitPixelAxis*image^[yPos-1]^[x]),
               rightStart+round(yUnit*(yPos-1)),
               pixelLinesY-round(unitPixelAxis*image^[yPos]^[x]));
          line(rightStart+round(yUnit*(yPos-2)),
               sobelLinesY+round(minSobel*unitSobelAxis)-
                   round(unitPixelAxis*sobelYLine^[yPos-1]),
               rightStart+round(yUnit*(yPos-1)),
               sobelLinesY+round(minSobel*unitSobelAxis)-
                   round(unitPixelAxis*sobelYLine^[yPos]))
        end
    end;


    procedure markPositionInGraphs(x,y : word);


      procedure markPosition(start,xPos,yPos : word;
                             theUnit         : real;
                             threshold       : word);

      begin
        line(start+round(theUnit*(xPos-filterRadius)),yPos,
             start+round(theUnit*(xPos-filterRadius)),yPos-lengthOf2ndAxis);
        line(start+round(theUnit*xPos),yPos,
             start+round(theUnit*xPos),yPos-lengthOf2ndAxis);
        line(start+round(theUnit*(xPos+filterRadius)),yPos,
             start+round(theUnit*(xPos+filterRadius)),yPos-lengthOf2ndAxis);
        line(start,yPos-round(unitPixelAxis*threshold),
             start+lengthOf1stAxis,yPos-round(unitPixelAxis*threshold))
      end;


    begin
      setColor(30);
      markPosition(leftStart,x,pixelLinesY,xUnit,filterThreshold);
      markPosition(leftStart,x,sobelLinesY,xUnit,sobelThreshold);
      markPosition(rightStart,y,pixelLinesY,yUnit,filterThreshold);
      markPosition(rightStart,y,sobelLinesY,yUnit,sobelThreshold)
    end;


  begin
    initVariables;
    drawCoordinateSystems;
    drawCharacteristics(pointToDisplay^.x,pointToDisplay^.y);
    markPositionInGraphs(pointToDisplay^.x,pointToDisplay^.y)
  end;


begin
  aPupilPoint:=findPupilPoint;
  if (aPupilPoint<>nil) then
    begin
      if displayCenterPoint then
        pointToDisplay:=findPosition(aPupilPoint)
      else
        pointToDisplay:=aPupilPoint;
      applySobelMasks;
      presentLines
    end
  else
    begin
      closeGraph;
      writeLn('No pupil were found!');
      halt(1)
    end
end;


procedure writeData;

var   positionMessage           : string;


  procedure markPosition;

  begin
    setColor(63);
    with pointToDisplay^ do
      begin
        line(x,1,x,ySize);
        line(1,y,xSize,y);
        circle(x,y,filterRadius)
      end
  end;


begin
  markPosition;
  setTextStyle(defaultFont,horizDir,1);
  setTextJustify(leftText,topText);
  setColor(63);
  if (pointToDisplay=aPupilPoint) then
    positionMessage:='Position of pupil point'
  else
    positionMessage:='Center position found';
  with pointToDisplay^ do
    outTextXY(xSize+20,1,positionMessage+': ('+
        intString(x)+','+intString(y)+')')
end;


procedure finishOff;

var   i                         : word;

begin
  readKey;
  closeGraph;
  for i:=1 to ySize do
    freeMem(image^[i],xSize);
  freeMem(image,4*ySize)
end;


begin
  init;
  treatLines;
  writeData;
  finishOff
end.