program convertTextFileToHelpFile;

uses crt,strings,help;

var   textFile                  : text;
      helpFile                  : helpFileType;
      fileName                  : string;


procedure init;

begin
  if ((paramStr(1)<>'') and (pos('.',paramStr(1))=0)) then
    fileName:=paramStr(1)
  else
    begin
      writeLn;
      write('File to be converted (no extension): ');
      readLn(fileName)
    end;
  assign(textFile,fileName+'.txt');
  reset(textFile);
  assign(helpFile,fileName+'.hlp');
  rewrite(helpFile);
  writeLn;
  write('Number of lines converted: ')
end;


procedure convertFile;

var   sizeOfHelpFile            : word;
      lineFromTextFile          : string;
      lineToHelpFile            : helpScreenString;


  function convertAndRemoveCharacter(var aTextLine : string) : char;

  var   ordAsString               : string;
        ordAsByte                 : byte;
        hashPosition              : byte;
        ignore                    : integer;

  begin
    delete(aTextLine,1,1);
    hashPosition:=pos('#',aTextLine);
    if (hashPosition<>0) then
      begin
        ordAsString:=copy(aTextLine,1,hashPosition-1);
        delete(aTextLine,1,hashPosition-1)
      end
    else
      begin
        ordAsString:=aTextLine;
        aTextLine:=''
      end;
    val(ordAsString,ordAsByte,ignore);
    convertAndRemoveCharacter:=chr(ordAsByte)
  end;


  function convertLine(aTextLine : string) : helpScreenString;

  var   convertedLine             : helpScreenString;

  begin
    if (aTextLine[1]<>'#') then
      convertLine:=aTextLine
    else
      begin
        convertedLine:='';
        while (aTextLine<>'') do
          convertedLine:=convertedLine+convertAndRemoveCharacter(aTextLine);
        convertLine:=convertedLine
      end
  end;


begin
  sizeOfHelpFile:=0;
  while (not EOF(textFile)) do
    begin
      readLn(textFile,lineFromTextFile);
      lineToHelpFile:=convertLine(lineFromTextFile);
      goToXY(28,whereY);
      write(succ(sizeOfHelpFile));
      seek(helpFile,sizeOfHelpFile);
      write(helpFile,lineToHelpFile);
      inc(sizeOfHelpFile)
    end;
  writeLn;
  writeLn('Done: File ',bigLetters(filename),
          '.TXT converted into ',bigLetters(fileName),'.HLP')
end;


procedure cleanUp;

begin
  close(textFile);
  close(helpFile)
end;


begin
  init;
  convertFile;
  cleanUp
end.