program threshold;

uses crt,graph,auxil;

const upper                     = 0;
      lower                     = 1;

      maxSize                   = 512;

type  bufferType                = array[1..maxSize] of byte;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

const thresholdLevel            : byte = 19;

var   image                     : pixelMatrixPtr;
      thresholdedImage          : pixelMatrixPtr;

      xSize                     : word;
      ySize                     : word;
      startX                    : word;
      startY                    : word;


function band(value : byte) : byte;

begin
  if (value>=thresholdLevel) then
    band:=upper
  else
    band:=lower
end;


procedure init;

var   fileName                  : string;
      graphDriver               : integer;
      graphMode                 : integer;
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
        fatalError('Illegal threshold value, must be a number!')
    end;


  begin
    for i:=1 to numberOfParameters-1 do
      begin
        thisParameter:=paramStr(i);
        if (thisParameter[1]='-') then
          if (thisParameter[2]='t') then
            thresholdLevel:=getParameterValue(thisParameter)
          else
            fatalError('Illegal option: -'+thisParameter[2])
        else
          fatalError('Cannot specify more than one file: '+thisParameter)
      end;
    fileName:=picturePath(paramStr(numberOfParameters))
  end;


  procedure initVariables;

  begin
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    startX:=getMaxX div 2;
    startY:=getMaxY div 2
  end;


begin
  if (paramCount>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
        begin
          graphDriver:=detect;
          initGraph(graphDriver,graphMode,'c:\language\tp6\bgi');
          assign(inputFile,fileName);
          reset(inputFile,1);
          initVariables;
          getMem(image,4*ySize);
          getMem(thresholdedImage,4*ySize);
          for i:=1 to ySize do
            begin
              blockRead(inputFile,buffer,xSize);
              getMem(image^[i],xSize);
              getMem(thresholdedImage^[i],xSize);
              image^[i]^[1]:=buffer[1];
              for j:=2 to xSize do
                begin
                  image^[i]^[j]:=buffer[j];
                  if (band(image^[i]^[j])<>band(image^[i]^[j-1])) then
                    thresholdedImage^[i]^[j-1]:=0
                  else
                    thresholdedImage^[i]^[j-1]:=15
                end
            end;
          close(inputFile)
        end
      else
        fatalError('Image file not found: '+picturePath(fileName))
    end
  else
    fatalError('Usage: threshld file[.pic]')
end;


procedure thresholdImage;

var   x,y                       : word;

begin
  for x:=1 to xSize do
    for y:=2 to ySize do
      begin
        if ((thresholdedImage^[y]^[x]=0) or
            (band(image^[y]^[x])<>band(image^[y-1]^[x]))) then
          thresholdedImage^[y-1]^[x]:=0
        else
          thresholdedImage^[y-1]^[x]:=15;
        putPixel(startX+x,startY+y,thresholdedImage^[y-1]^[x])
      end
end;


procedure finishOff;

var   i                         : word;

begin
  readKey;
  for i:=1 to ySize do
    begin
      freeMem(image^[i],xSize);
      freeMem(thresholdedImage^[i],xSize)
    end;
  freeMem(image,4*ySize);
  freeMem(thresholdedImage,4*ySize)
end;


begin
  init;
  thresholdImage;
  finishOff
end.