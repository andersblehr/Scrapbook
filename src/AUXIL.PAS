unit auxil;


INTERFACE


type  pointPtr                  = ^point;
      point                     = record
        x                         : word;
        y                         : word
      end;


function fileExists(pathToFile : string) : boolean;

function intString(aNumber : word) : string;

function realString(aNumber : real) : string;

function makePoint(anX,anY : word) : pointPtr;

procedure beep(frequency,time : word);

procedure fatalError(errorMessage : string);


IMPLEMENTATION

uses crt;


function fileExists(pathToFile : string) : boolean;

var   aFile			: file;

begin
  assign(aFile,pathToFile);
  {$I-}
  reset(aFile,1);
  {$I+}
  fileExists:=(IOResult=0);
  if (IOResult=0) then
    close(aFile)
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