program runFilter;

uses crt,graph,defs,auxil,ADT,SVGA;

const maxSize                   = 512;
      defaultFilterRadius       = 0;
      defaultThreshold          = 1;

type  bufferArray               = array[1..maxSize] of char;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

      pointOPtr                 = ^pointO;
      pointO                    = object(doubleNodeO)
        x                         : word;
        y                         : word;
        constructor init(xValue,yValue : word);
        destructor  done; virtual;
      end;

var   xSize                     : word;
      ySize                     : word;
      startX                    : word;
      startY                    : word;
      fileName                  : string;
      pictureMatrix             : pixelMatrixPtr;
      pointList                 : doubleListOPtr;
      filterRadius              : byte;
      threshold                 : byte;
      lowestFilterValue         : byte;
      highestFilterValue        : byte;
      throughputCount           : word;
      middleValue               : real;


(***************************************************************************
 *                                                                         *
 *    pointO(doubleNodeO)'s methods                                        *
 *                                                                         *
 ***************************************************************************)


constructor pointO.init(xValue,yValue : word);

begin
  x:=xValue;
  y:=yValue;
  doubleNodeO.init
end;


destructor pointO.done;

begin
  doubleNodeO.done
end;


(***************************************************************************
 *                                                                         *
 *    Auxiliary procedures and functions                                   *
 *                                                                         *
 ***************************************************************************)


function currentPoint : pointOPtr;

begin
  currentPoint:=pointOPtr(pointList^.position)
end;


(***************************************************************************
 *                                                                         *
 *    The program                                                          *
 *                                                                         *
 ***************************************************************************)


procedure init;

var   parameter                 : string;
      radiusSet                 : boolean;
      thresholdSet              : boolean;
      pictureFile               : file;
      buffer                    : bufferArray;
      i,j                       : word;


  function getParameterValue(parameterString : string;
                         var flag            : boolean) : byte;

  var   value                     : byte;
        result                    : integer;

  begin
    val(copy(parameterString,3,length(parameterString)-2),value,result);
    if (result=0) then
      begin
        flag:=true;
        getParameterValue:=value
      end
    else
      fatalError('Illegal parameter value!')
  end;


begin
  radiusSet:=false;
  thresholdSet:=false;
  if (paramCount<>0) then
    begin
      for i:=1 to paramCount do
        begin
          parameter:=paramStr(i);
          if (parameter[1]='-') then
            case parameter[2] of
              'r' : filterRadius:=getParameterValue(parameter,radiusSet);
              't' : threshold:=getParameterValue(parameter,thresholdSet)
            else
              fatalError('Illegal option: -'+parameter[2])
            end
          else
            begin
              fileName:=picturePath(paramStr(i));
              i:=paramCount
            end
        end;
      if (not radiusSet) then
        filterRadius:=defaultFilterRadius;
      if (not thresholdSet) then
        threshold:=defaultThreshold;
      if (fileExists(fileName)) then
        begin
          initSVGAGraphics;
          setBlackAndWhitePalette;
          new(pointList,init);
          assign(pictureFile,fileName);
          reset(pictureFile,1);
          blockRead(pictureFile,buffer,4);
          xSize:=(word(ord(buffer[1])) shl 8)+ord(buffer[2]);
          ySize:=(word(ord(buffer[3])) shl 8)+ord(buffer[4]);
          startX:=(getMaxX div 2)-(xSize div 2);
          startY:=(getMaxY div 2)-(ySize div 2);
          getMem(pictureMatrix,4*ySize);
          for i:=1 to ySize do
            begin
              blockRead(pictureFile,buffer,xSize);
              getMem(pictureMatrix^[i],xSize);
              for j:=1 to xSize do
                pictureMatrix^[i]^[j]:=ord(buffer[j])
            end
        end
      else
        fatalError('Picture file not found!')
    end
  else
    fatalError('Usage: filter [-r<filter radius>][-t<threshold>] file (no extension)')
end;


procedure drawPicture;

var   x                         : word;
      y                         : word;

begin
  for y:=0 to ySize-1 do
    for x:=0 to xSize-1 do
      putPixel(startX+x,startY+y,pictureMatrix^[y+1]^[x+1]);
  setColor(63);
  line(startX-5,startY,startX+xSize,startY);
  line(startX+xSize,startY,startX+xSize,startY+ySize);
  line(startX+xSize,startY+ySize,startX,startY+ySize);
  line(startX,startY+ySize,startX,startY-5);
  for x:=1 to xSize do
    if ((x div 50)=(x/50)) then
      line(startX+x-1,startY-5,startX+x-1,startY);
  for y:=1 to ySize do
    if ((y div 50)=(y/50)) then
      line(startX-5,startY+y-1,startX,startY+y-1)
end;


procedure doAnalyze;

var   sum                       : longInt;
      xPos                      : word;
      yPos                      : word;
      filterValue               : byte;


  function getFilterValue : byte;

  var   filterSum                 : longInt;
        i                         : integer;

  begin
    filterSum:=pictureMatrix^[yPos]^[xPos];
    for i:=1 to (filterRadius div 2) do
      filterSum:=filterSum+pictureMatrix^[yPos]^[xPos-2*i]+
                           pictureMatrix^[yPos]^[xPos+2*i]+
                           pictureMatrix^[yPos-2*i]^[xPos]+
                           pictureMatrix^[yPos+2*i]^[xPos];
    getFilterValue:=round(filterSum/(2*filterRadius+1))
  end;


begin
  setColor(60);
  outTextXY(startX,startY+ySize+30,
            'Analyzing the picture '+fileName+'....');
  outTextXY(startX,startY+ySize+50,
            'Filter radius: '+intString(filterRadius));
  lowestFilterValue:=64;
  highestFilterValue:=0;
  throughputCount:=0;
  sum:=0;
  for yPos:=filterRadius+1 to ySize-filterRadius-1 do
    begin
      for xPos:=filterRadius+1 to xSize-filterRadius-1 do
        begin
          filterValue:=getFilterValue;
          putPixel(startX+xPos-1,startY+yPos-1,63);
          if (filterValue<lowestFilterValue) then
            lowestFilterValue:=filterValue
          else if (filterValue>highestFilterValue) then
            highestFilterValue:=filterValue;
          if (filterValue<=threshold) then
            begin
              inc(throughputCount);
              pointList^.addElement(new(pointOPtr,init(xPos,yPos)))
            end;
          inc(sum,pictureMatrix^[yPos]^[xPos]);
        end;
      for xPos:=filterRadius to xSize-filterRadius do
        putPixel(startX+xPos-1,startY+yPos-1,pictureMatrix^[yPos]^[xPos])
    end;
  middleValue:=sum/(longInt(xSize)*longInt(ySize))
end;


procedure markPoints;


  procedure markPoint(aPoint : pointOPtr);

  begin
    with aPoint^ do
      putPixel(startX+x,startY+y,63)
{      begin
        line(startX+x,startY+y-3,startX+x,startY+y+3);
        line(startX+x-3,startY+y,startX+x+3,startY+y);
      end}
  end;


begin
  setColor(63);
  pointList^.goToStart;
  markPoint(currentPoint);
  while (not pointList^.endOfList) do
    begin
      pointList^.goForwards;
      markPoint(currentPoint)
    end
end;


procedure presentResult;

begin
  setColor(60);
  pointList^.goToStart;
  setTextStyle(defaultFont,horizDir,1);
  setTextJustify(leftText,centerText);
  outTextXY(startX,startY+ySize+64,
            'Lowest filter value: '+intString(lowestFilterValue));
  outTextXY(startX,startY+ySize+74,
            'Highest filter value: '+intString(highestFilterValue));
  outTextXY(startX,startY+ySize+84,
            'Position of first point let through: ('+
            intString(currentPoint^.x)+','+
            intString(currentPoint^.y)+')');
  outTextXY(startX,startY+ySize+94,
            'Number of points let through: '+intString(throughputCount));
  outTextXY(startX,startY+ySize+104,
            'Middle filter value: '+realString(middleValue));
  outTextXY(startX,startY+ySize+124,'Press any key to exit....');
  readKey
end;


procedure finishOff;

var   i                         : word;

begin
  dispose(pointList,done);
  closeGraph;
  for i:=1 to ySize do
    freeMem(pictureMatrix^[i],xSize);
  freeMem(pictureMatrix,4*ySize)
end;


begin
  init;
  drawPicture;
  doAnalyze;
  markPoints;
  presentResult;
  finishOff
end.
