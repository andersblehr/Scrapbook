program PCXView;

uses crt,graph,auxil,SVGA;

const bufferSize                = 4096;
      headerSize                = 128;

type  bufferType                = array[0..bufferSize-1] of byte;

var   fileName                  : string;
      inputFile                 : file;
      thisBuffer                : bufferType;
      previousBuffer            : bufferType;
      xSize                     : word;
      ySize                     : word;
      startX                    : word;
      startY                    : word;
      pictureSize               : longInt;


procedure init;

begin
  if (paramCount>0) then
    if (fileExists(PCXPath(paramStr(1)))) then
      begin
        fileName:=paramStr(1);
        assign(inputFile,PCXPath(fileName));
        reset(inputFile,1);
        blockRead(inputFile,thisBuffer,headerSize);
        SVGA_initGraphics(mode800x600);
        xSize:=thisBuffer[12]+256*thisBuffer[13];
        ySize:=thisBuffer[14]+256*thisBuffer[15];
        startX:=(getMaxX-xSize) div 2;
        startY:=(getMaxY-ySize) div 2;
        pictureSize:=longInt(xSize)*longInt(ySize)
      end
    else
      fatalError('PCX file not found: '+PCXPath(paramStr(1)))
  else
    fatalError('Usage: pcxview <file name (no extension)>')
end;


procedure getPCXPalette;

const paletteSize               = 768;

type  paletteBuffer             = array[1..768] of byte;

var   theFile                   : file;
      buffer                    : paletteBuffer;
      i                         : byte;
      thePalette                : VGAPaletteType;

begin
  assign(theFile,PCXPath(fileName));
  reset(theFile,1);
  seek(theFile,fileSize(theFile)-paletteSize);
  blockRead(theFile,buffer,paletteSize);
  close(theFile);
  for i:=0 to 255 do
    begin
      thePalette[i].R:=buffer[3*i+1];
      thePalette[i].G:=buffer[3*i+2];
      thePalette[i].B:=buffer[3*i+3]
    end;
  SVGA_setAllVGAPalette(thePalette)
end;


procedure mainLoop;

var   pixelCount                : longInt;
      i,j                       : integer;
      overhead                  : word;
      noRead                    : word;


  function runLengthByte(aByte : byte) : boolean;

  begin
    runLengthByte:=((aByte and $C0)=$C0)
  end;


  function runLength(aRunLengthByte : byte) : byte;

  begin
    runLength:=(aRunLengthByte and $3F)
  end;


  function getBuffer(index : integer) : byte;

  begin
    if (index>=0) then
      getBuffer:=thisBuffer[index]
    else
      getBuffer:=previousBuffer[bufferSize+index]
  end;


begin
  pixelCount:=0;
  overhead:=0;
  repeat
    i:=-overhead;
    overhead:=0;
    previousBuffer:=thisBuffer;
    blockRead(inputFile,thisBuffer,bufferSize,noRead);
    while ((i<noRead) and (pixelCount<=pictureSize)) do
      if runLengthByte(getBuffer(i)) then
        if (i+runLength(getBuffer(i))>=noRead) then
          begin
            overhead:=noRead-i;
            i:=noRead
          end
        else
          begin
            for j:=1 to runLength(getBuffer(i)) do
              begin
                putPixel(startX+(pixelCount mod xSize),
                         startY+(pixelCount div xSize),
                         trunc(getBuffer(i+1)/4));
                inc(pixelCount)
              end;
            inc(i,2)
          end
      else
        begin
          putPixel(startX+(pixelCount mod xSize),
                   startY+(pixelCount div xSize),trunc(getBuffer(i)/4));
          inc(i);
          inc(pixelCount)
        end
  until (noRead<bufferSize)
end;


procedure finishOff;

begin
  close(inputFile);
  readKey;
  closeGraph
end;


begin
  init;
  getPCXPalette;
  mainLoop;
  finishOff
end.