program pic2pcx;

uses auxil;

const maxSize                   = 1024;
      PCXHeaderSize             = 128;

type  bufferType                = array[0..maxSize-1] of byte;

var   fileName                  : string;
      PICFile                   : file;
      PCXFile                   : file;
      PICBuffer                 : bufferType;
      PCXBuffer                 : bufferType;
      xSize                     : word;
      ySize                     : word;


procedure init;


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
          ySize:=(word(PICbuffer[2]) shl 8)+PICbuffer[3]
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
  PCXBuffer[ 2]:=0;
  PCXBuffer[ 3]:=8;
  PCXBuffer[ 4]:=0;
  PCXBuffer[ 5]:=0;
  PCXBuffer[ 6]:=0;
  PCXBuffer[ 7]:=0;
  PCXBuffer[ 8]:=hi(xSize-1);
  PCXBuffer[ 9]:=lo(xSize-1);
  PCXBuffer[10]:=hi(ySize-1);
  PCXBuffer[11]:=lo(ySize-1);
  PCXBuffer[12]:=hi(300);
  PCXBuffer[13]:=lo(300);
  PCXBuffer[14]:=hi(300);
  PCXBuffer[15]:=lo(300);
  for i:=0 to 15 do
    begin
      PCXBuffer[16+3*i  ]:=i;
      PCXBuffer[16+3*i+1]:=i;
      PCXBuffer[16+3*i+2]:=i
    end;
  PCXBuffer[64]:=0;
  PCXBuffer[65]:=1;
  PCXBuffer[66]:=hi(xSize);
  PCXBuffer[67]:=lo(xSize);
  PCXBuffer[68]:=hi(2);
  PCXBuffer[69]:=lo(2);
  for i:=0 to 57 do
    PCXBuffer[70+i]:=0;
  blockWrite(PCXFile,PCXBuffer,PCXHeaderSize)
end;


procedure mainLoop;

var   i,j                       : word;

begin
  for i:=0 to (ySize-1) do
    begin
      blockRead(PICFile,PICBuffer,xSize);
      for j:=0 to (xSize-1) do
        PCXBuffer[i]:=PICBuffer[i];
      blockWrite(PCXFile,PCXBuffer,xSize)
    end
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

begin
  close(PCXFile);
  close(PICFile)
end;


begin
  init;
  writePCXHeader;
  mainLoop;
  writePalette;
  finishOff
end.