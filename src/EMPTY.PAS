uses auxil;

const size                      = 128;
      grayLevel                 = 25;

type  bufferType                = array[1..size] of byte;

var   theFile                   : file;
      buffer                    : bufferType;
      i,j                       : word;

begin
  assign(theFile,picturePath('empty'));
  rewrite(theFile,1);
  buffer[1]:=hi(size);
  buffer[2]:=lo(size);
  buffer[3]:=hi(size);
  buffer[4]:=lo(size);
  blockWrite(theFile,buffer,4);
  for i:=1 to size do
    begin
      for j:=1 to size do
	buffer[j]:=grayLevel;
      blockWrite(theFile,buffer,size)
    end;
  close(theFile)
end.