program display;

uses crt,graph,auxil;

type  bufferType                = array[1..640] of byte;

var   xSize                     : word;
      ySize                     : word;


procedure doDisplay;

var   fileName                  : string;
      graphMode                 : integer;
      graphDriver               : integer;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure initVariables;

  begin
    assign(inputFile,fileName);
    reset(inputFile,1);
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4]
  end;


begin
  if (paramCount=1) then
    begin
      fileName:=picturePath(paramStr(1));
      if fileExists(fileName) then
        begin
          initVariables;
          graphDriver:=detect;
          initGraph(graphDriver,graphMode,'c:\language\tp6\bgi');
          for i:=1 to ySize do
            begin
              blockRead(inputFile,buffer,xSize);
              for j:=1 to xSize do
                if (buffer[j]=63) then
                  putPixel(j,i,15)
                else
                  putPixel(j,i,buffer[j])
            end;
          close(inputFile);
        end
      else
        fatalError('Image file not found!')
    end
  else
    fatalError('Usage: display file (no extension)')
end;


begin
  doDisplay;
  readKey;
  closeGraph
end.