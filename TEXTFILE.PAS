unit textFile;


INTERFACE

uses strings;


const opened                    = true;
      closed                    = false;

type  textFileOPtr              = ^textFileO;
      textFileO                 = object
        thisFile                  : text;
        fileNameValue             : stringPtr;
        statusValue               : boolean;
        constructor init(nameOfFile : string);
        destructor  done; virtual;
        function    fileName : string;
        function    status   : boolean;
        procedure   setFile(nameOfFile : string);
        procedure   writeFile(aString : string);
      end;


IMPLEMENTATION


(*************************************************************************
 *                                                                       *
 *     textFileO's methods                                               *
 *                                                                       *
 *************************************************************************)


constructor textFileO.init(nameOfFile : string);

begin
  statusValue:=closed;
  fileNameValue:=nil;
  setFile(nameOfFile)
end;


destructor textFileO.done;

begin
  delStr(fileNameValue);
  close(thisFile);
end;


function textFileO.fileName : string;

begin
  fileName:=fileNameValue^
end;


function textFileO.status : boolean;

begin
  status:=statusValue
end;


procedure textFileO.setFile(nameOfFile : string);

begin
  if (status=opened) then
    close(thisFile);
  delStr(fileNameValue);
  fileNameValue:=strPtr(bigLetters(nameOfFile));
  assign(thisFile,nameOfFile);
  rewrite(thisFile);
  statusValue:=opened
end;


procedure textFileO.writeFile(aString : string);

begin
  if (status=opened) then
    writeLn(thisFile,aString)
end;


end.