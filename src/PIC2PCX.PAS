program pic2pcx;

uses auxil;

const maxSize                   = 1024;
      PCXHeaderSize             = 128;

type  pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[0..maxSize-1] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[0..maxSize-1] of pixelLinePtr;
      bufferType                = array[0..maxSize-1] of byte;

var   image                     : pixelMatrixPtr;
      PCXFile                   : file;
      PCXBuffer                 : bufferType;
      xSize                     : word;
      ySize                     : word;
      imageSize                 : longInt;


procedure init;

var   fileName                  : string;
      PICFile                   : file;
      PICBuffer                 : bufferType;
      i,j                       : word;

begin
  if (paramCount=1) then
    begin
      fileName:=paramStr(1);
      if fileExists(picturePath(fileName)) then
        begin
          assign(PICFile,picturePath(fileName));
          reset(PICFile,1);
          assign(PCXFile,PCXPath(fileName));
          rewrite(PCXFile,1);
          blockRead(PICFile,PICBuffer,4);
          xSize:=(word(PICbuffer[0]) shl 8)+PICbuffer[1];
          ySize:=(word(PICbuffer[2]) shl 8)+PICbuffer[3];
          imageSize:=longInt(xSize)*longInt(ySize);
	  getMem(image,4*ySize);
	  for i:=0 to (ySize-1) do
	    begin
	      blockRead(PICFile,PICBuffer,xSize);
	      getMem(image^[i],xSize);
	      for j:=0 to (xSize-1) do
                image^[i]^[j]:=4*PICBuffer[j]
	    end;
	  close(PICFile);
        end
      else
        fatalError('Picture file not found: '+paramStr(1)+'.pic')
    end
  else
    fatalError('Usage: pic2pcx file (no extension)')
end;


procedure writePCXHeader;

var   i                         : byte;

begin
  PCXBuffer[ 0]:=10;
  PCXBuffer[ 1]:=5;
  PCXBuffer[ 2]:=1;
  PCXBuffer[ 3]:=8;
  PCXBuffer[ 4]:=0;
  PCXBuffer[ 5]:=0;
  PCXBuffer[ 6]:=0;
  PCXBuffer[ 7]:=0;
  PCXBuffer[ 8]:=hi(xSize-1);
  PCXBuffer[ 9]:=lo(xSize-1);
  PCXBuffer[10]:=hi(ySize-1);
  PCXBuffer[11]:=lo(ySize-1);
  PCXBuffer[12]:=lo(xSize);
  PCXBuffer[13]:=hi(xSize);
  PCXBuffer[14]:=lo(ySize);
  PCXBuffer[15]:=hi(ySize);
  for i:=0 to 15 do
    begin
      PCXBuffer[16+3*i  ]:=i;
      PCXBuffer[16+3*i+1]:=i;
      PCXBuffer[16+3*i+2]:=i
    end;
  PCXBuffer[64]:=0;
  PCXBuffer[65]:=1;
  PCXBuffer[66]:=lo(xSize);
  PCXBuffer[67]:=hi(xSize);
  PCXBuffer[68]:=lo(2);
  PCXBuffer[69]:=hi(2);
  for i:=0 to 57 do
    PCXBuffer[70+i]:=0;
  blockWrite(PCXFile,PCXBuffer,PCXHeaderSize)
end;


procedure mainLoop;

var   nPixelsWritten            : longInt;
      bufferCount               : word;
      currentX                  : word;
      currentY                  : word;
      nEqualPixels              : byte;
      currentPixelValue         : byte;


  function countEqualPixels(var pixelValue : byte) : byte;

  var   pixelCount                : byte;


    function nextX(var x,y : word) : word;

    begin
      if (x<xSize-1) then
        inc(x)
      else
        begin
          x:=0;
          inc(y)
        end;
      nextX:=x
    end;


  begin
    pixelCount:=1;
    pixelValue:=image^[currentY]^[currentX];
    while ((image^[currentY]^[nextX(currentX,currentY)]=pixelValue) and
           (pixelCount<=64) and (nPixelsWritten<imageSize)) do
      inc(pixelCount);
    countEqualPixels:=pixelCount
  end;


  function countPixel(aValue : byte) : boolean;

  begin
    countPixel:=(((aValue shr 6) and $03)=$03)
  end;


  procedure addToBuffer(aValue : byte);

  begin
    if (bufferCount=maxSize-1) then
      begin
        blockWrite(PCXFile,PCXBuffer,maxSize);
        bufferCount:=0
      end;
    PCXBuffer[bufferCount]:=aValue;
    inc(bufferCount)
  end;


begin
  nPixelsWritten:=0;
  bufferCount:=0;
  currentX:=0;
  currentY:=0;
  while (nPixelsWritten<imageSize) do
    begin
      nEqualPixels:=countEqualPixels(currentPixelValue);
      if (nEqualPixels=1) then
        begin
          if countPixel(currentPixelValue) then
            addToBuffer($C0 or $01);
          addToBuffer(currentPixelValue);
          inc(nPixelsWritten)
        end
      else
        begin
          addToBuffer($C0 or nEqualPixels);
          addToBuffer(currentPixelValue)
        end
    end;
  if (bufferCount>0) then
    blockWrite(PCXFile,PCXBuffer,bufferCount+1)
end;


procedure writePalette;

const paletteSize               = 768;

var   paletteFile               : file;
      palette                   : bufferType;
      i                         : word;

begin
  assign(paletteFile,palettePath('grey'));
  reset(paletteFile,1);
  blockRead(paletteFile,palette,paletteSize);
  close(paletteFile);
  for i:=0 to (paletteSize-1) do
    PCXBuffer[i]:=palette[i];
  blockWrite(PCXFile,PCXBuffer,paletteSize)
end;


procedure finishOff;

var   i                         : word;

begin
  close(PCXFile);
  for i:=0 to (ySize-1) do
    freeMem(image^[i],xSize);
  freeMem(image,4*ySize)
end;


begin
  init;
  write('Converting.... ');
  writePCXHeader;
  mainLoop;
  writePalette;
  writeLn('done');
  finishOff
end.