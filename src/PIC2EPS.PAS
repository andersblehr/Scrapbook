program pic2eps;

uses crt,auxil;

const maxSize                   = 1024;
      LF                        = #10;
      CR                        = #13;

type  PICBufferType             = array[0..maxSize-1] of byte;
      EPSBufferType             = array[0..maxSize-1] of char;

var   fileName                  : string;
      PICFile                   : file;
      EPSFile                   : file;
      PICBuffer                 : PICBufferType;
      EPSBuffer                 : EPSBufferType;
      xSize                     : word;
      ySize                     : word;


procedure copyToBuffer(aString : string; var charCount : word);

var   i                         : byte;

begin
  for i:=1 to length(aString) do
    begin
      EPSBuffer[charCount]:=aString[i];
      inc(charCount)
    end;
  EPSBuffer[charCount]:=CR;
  EPSBuffer[charCount+1]:=LF;
  inc(charCount,2)
end;


procedure init;

var   xSizeAsString             : string;
      ySizeAsString             : string;


  procedure writeEPSHeader(xSize,ySize : string);

  var   nToWrite                  : word;

  begin
    nToWrite:=0;
    copyToBuffer('%!PS-Adobe-1.0',nToWrite);
    copyToBuffer('%%BoundingBox: 0 0 '+xSize+' '+ySize,nToWrite);
    copyToBuffer('/doimage {',nToWrite);
    copyToBuffer('   /b exch def /m exch def /n exch def',nToWrite);
    copyToBuffer('        /pix n string def',nToWrite);
    copyToBuffer('   n m b [n 0 0 m neg 0 m]',nToWrite);
    copyToBuffer('   { currentfile pix readhexstring pop }',nToWrite);
    copyToBuffer('   image',nToWrite);
    copyToBuffer('} def',nToWrite);
    copyToBuffer('/spotsize {',nToWrite);
    copyToBuffer('   /perinch exch def',nToWrite);
    copyToBuffer('   currentscreen 3 -1 roll',nToWrite);
    copyToBuffer('   pop perinch',nToWrite);
    copyToBuffer('   3 1 roll setscreen',nToWrite);
    copyToBuffer('} def',nToWrite);
    copyToBuffer(xSize+' '+ySize+' scale',nToWrite);
    copyToBuffer('60 spotsize',nToWrite);
    copyToBuffer(' '+xSize+' '+ySize+' 8 doimage',nToWrite);
    blockWrite(EPSFile,EPSBuffer,nToWrite)
  end;


begin
  if (paramCount=1) then
    begin
      fileName:=paramStr(1);
      if fileExists(picturePath(fileName)) then
        begin
          assign(PICFile,picturePath(fileName));
          reset(PICFile,1);
          assign(EPSFile,EPSPath(fileName));
          rewrite(EPSFile,1);
          blockRead(PICFile,PICBuffer,4);
          xSize:=(word(PICbuffer[0]) shl 8)+PICbuffer[1];
          ySize:=(word(PICbuffer[2]) shl 8)+PICbuffer[3];
          str(xSize,xSizeAsString);
          str(ySize,ySizeAsString);
          writeEPSHeader(xSizeAsString,ySizeAsString)
        end
      else
        fatalError('Picture file not found: '+paramStr(1)+'.pic')
    end
  else
    fatalError('Usage: pic2eps file (no extension)')
end;


procedure mainLoop;

var   i                         : word;
      charCount                 : word;


  procedure hexify(inBuffer : PICBufferType; var outBuffer : EPSBufferType);

  var   i                         : word;
        loFour                    : byte;
        hiFour                    : byte;


    function dec2hex(x : byte) : char;

    begin
      case x of
         0 : dec2hex:='0';
         1 : dec2hex:='1';
         2 : dec2hex:='2';
         3 : dec2hex:='3';
         4 : dec2hex:='4';
         5 : dec2hex:='5';
         6 : dec2hex:='6';
         7 : dec2hex:='7';
         8 : dec2hex:='8';
         9 : dec2hex:='9';
        10 : dec2hex:='A';
        11 : dec2hex:='B';
        12 : dec2hex:='C';
        13 : dec2hex:='D';
        14 : dec2hex:='E';
        15 : dec2hex:='F'
      end
    end;


  begin
    for i:=0 to xSize-1 do
      begin
        loFour:=4*(inBuffer[i]) and $0F;
        hiFour:=(4*(inBuffer[i]) shr 4) and $0F;
        outBuffer[2*i]:=dec2hex(hiFour);
        outBuffer[2*i+1]:=dec2hex(loFour)
      end
  end;


begin
  for i:=0 to ySize-1 do
    begin
      blockRead(PICFile,PICBuffer,xSize);
      hexify(PICBuffer,EPSBuffer);
      blockWrite(EPSFile,EPSBuffer,2*xSize)
    end;
  EPSBuffer[0]:=CR;
  EPSBuffer[1]:=LF;
  charCount:=2;
  copyToBuffer('showpage',charCount);
  blockWrite(EPSFile,EPSBuffer,charCount)
end;


procedure finishOff;

begin
  close(EPSFile);
  close(PICFile)
end;


begin
  init;
  mainLoop;
  finishOff
end.