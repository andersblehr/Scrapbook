program convert;

uses crt;

type  bufferType                = array[1..512] of char;

var   fileName                  : string;
      oldFile                   : text;
      newFile                   : file;
      xSize                     : word;
      ySize                     : word;
      sizeInfo                  : string;
      buffer                    : bufferType;
      i,j                       : byte;
      pictureLine               : string;


function getXSize(anInfoLine : string) : word;

var   theXSize                  : word;
      ignore                    : integer;

begin
  val(copy(anInfoLine,1,pos('x',anInfoLine)-1),theXSize,ignore);
  getXSize:=theXSize
end;


function getYSize(anInfoLine : string) : word;

var   theYSize                  : word;
      ignore                    : integer;

begin
  val(copy(anInfoLine,pos('x',anInfoLine)+1,
           length(anInfoLine)-pos('x',anInfoLine)),theYSize,ignore);
  getYSize:=theYSize
end;


function getGrayLevel(aChar : char) : byte;

begin
  if (aChar in ['0'..'9']) then
    getGrayLevel:=2*(ord(aChar)-48)
  else if (aChar in ['A'..'Z']) then
    getGrayLevel:=2*(ord(aChar)-55)
  else
    getGrayLevel:=0
end;


begin
  clrScr;
  write('Name of file to be converted (no extension): ');
  readLn(fileName);
  assign(oldFile,'c:\user\blehr\diplom\bilder\'+fileName+'.pic');
  rename(oldFile,'c:\user\blehr\diplom\bilder\'+fileName+'.old');
  assign(oldFile,'c:\user\blehr\diplom\bilder\'+fileName+'.old');
  reset(oldFile);
  assign(newFile,'c:\user\blehr\diplom\bilder\'+fileName+'.pic');
  rewrite(newFile,1);
  readLn(oldFile,sizeInfo);
  xSize:=getXSize(sizeInfo);
  ySize:=getYSize(sizeInfo);
  buffer[1]:=chr(hi(xSize));
  buffer[2]:=chr(lo(xSize));
  buffer[3]:=chr(hi(ySize));
  buffer[4]:=chr(lo(ySize));
  blockWrite(newFile,buffer,4);
  for i:=1 to ySize do
    begin
      readLn(oldFile,pictureLine);
      for j:=1 to xSize do
        buffer[j]:=chr(getGrayLevel(pictureLine[j]));
      blockWrite(newFile,buffer,xSize)
    end;
  close(oldFile);
  close(newFile)
end.