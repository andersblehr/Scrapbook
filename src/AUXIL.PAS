unit auxil;


INTERFACE

uses dos;


type  pointPtr                  = ^point;
      point                     = record
        x                         : word;
        y                         : word
      end;

      charSet                   = set of char;


function nextWord(var aLine : string; whiteSpace : charSet) : string;

function appendExtension(path : pathStr; wantedExtension : extStr) : pathStr;

function fileExists(pathToFile : string) : boolean;

function intString(aNumber : word) : string;

function realString(aNumber : real) : string;

function makePoint(anX,anY : word) : pointPtr;

procedure beep(frequency,time : word);

procedure fatalError(errorMessage : string);


IMPLEMENTATION

uses crt;


function nextWord(var aLine : string; whiteSpace : charSet) : string;

var   theWord                   : string;

begin
  theWord:='';
  if (aLine<>'') then
    begin
      while (aLine[1] in whiteSpace) do
        delete(aLine,1,1);
      while ((aLine<>'') and (not (aLine[1] in whiteSpace))) do
        begin
          theWord:=theWord+aLine[1];
          delete(aLine,1,1)
        end
    end;
  nextWord:=theWord
end;


function appendExtension(path : pathStr; wantedExtension : extStr) : pathStr;

var   directory                 : dirStr;
      fileName                  : nameStr;
      extension                 : extStr;

begin
  fSplit(path,directory,fileName,extension);
  if (extension=wantedExtension) then
    appendExtension:=path
  else
    appendExtension:=directory+fileName+wantedExtension
end;


function fileExists(pathToFile : string) : boolean;

var   aFile			: file;
      exists                    : boolean;

begin
  assign(aFile,pathToFile);
  {$I-}
  reset(aFile,1);
  {$I+}
  exists:=(IOResult=0);
  if exists then
    close(aFile);
  fileExists:=exists
end;


function intString(aNumber : word) : string;

var   aString                   : string;

begin
  str(aNumber,aString);
  intString:=aString
end;


function realString(aNumber : real) : string;

var   aString                   : string;

begin
  str(aNumber:4:2,aString);
  realString:=aString
end;


function makePoint(anX,anY : word) : pointPtr;

var   aPoint                    : pointPtr;

begin
  new(aPoint);
  aPoint^.x:=anX;
  aPoint^.y:=anY;
  makePoint:=aPoint
end;


procedure beep(frequency,time : word);

begin
  sound(frequency);
  delay(time);
  noSound
end;


procedure fatalError(errorMessage : string);

begin
  writeLn(errorMessage);
  beep(600,100);
  halt(1)
end;


end.