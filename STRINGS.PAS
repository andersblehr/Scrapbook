unit strings;


INTERFACE

type  stringPtr                 = ^string;


function strPtr(aText : string) : stringPtr;

function bigLetters(aText : string) : string;

function smallLetters(aText : string) : string;

function upCase(aChar : char) : char;

function lowCase(aChar : char) : char;

function upperCase(aChar : char) : boolean;

function lowerCase(aChar : char) : boolean;

function capitalizeFirst(aString : string) : string;

procedure delStr(aStringPtr : stringPtr);

procedure errorMessage(message : string);


IMPLEMENTATION

uses crt;


function strPtr(aText : string) : stringPtr;

var   aStringPtr                : stringPtr;

begin
  getMem(aStringPtr,length(aText)+1);
  aStringPtr^:=aText;
  strPtr:=aStringPtr
end;


function bigLetters(aText : string) : string;

var   aString                   : string;
      i                         : byte;

begin
  aString:='';
  for i:=1 to length(aText) do
    aString:=aString+upCase(aText[i]);
  bigLetters:=aString
end;


function smallLetters(aText : string) : string;

var   aString                   : string;
      i                         : byte;

begin
  aString:='';
  for i:=1 to length(aText) do
    aString:=aString+lowCase(aText[i]);
  smallLetters:=aString
end;


function upCase(aChar : char) : char;

begin
  case aChar of
    'a'..'z' : upCase:=chr(ord(aChar)-32);
    'ë'      : upCase:='í';
    'õ'      : upCase:='ù';
    'Ü'      : upCase:='è';
    'Ñ'      : upCase:='é';
    'î'      : upCase:='ô';
    'Å'      : upCase:='ö';
    'Ç'      : upCase:='ê';
    '§'      : upCase:='•'
  else
    upCase:=aChar
  end
end;


function lowCase(aChar : char) : char;

begin
  case aChar of
    'A'..'Z' : lowCase:=chr(ord(aChar)+32);
    'í'      : lowCase:='ë';
    'ù'      : lowCase:='õ';
    'è'      : lowCase:='Ü';
    'é'      : lowCase:='Ñ';
    'ô'      : lowCase:='î';
    'ö'      : lowCase:='Å';
    'ê'      : lowCase:='Ç';
    '•'      : lowCase:='§';
    'Ä'      : lowCase:='á'
  else
    lowCase:=aChar
  end
end;


function upperCase(aChar : char) : boolean;

begin
  upperCase:=(aChar in ['A'..'Z','í','ù','è','é','ô','ö','ê','•','Ä'])
end;


function lowerCase(aChar : char) : boolean;

begin
  lowerCase:=(aChar in ['a'..'z','ë','õ','Å'..'ç','ì'..'ò','†'..'§'])
end;


function capitalizeFirst(aString : string) : string;

begin
  capitalizeFirst:=upCase(aString[1])+copy(aString,2,length(aString)-1)
end;


procedure delStr(aStringPtr : stringPtr);

begin
  if (aStringPtr<>nil) then
    freeMem(aStringPtr,length(aStringPtr^)+1)
end;


procedure errorMessage(message : string);

begin
  clrScr;
  write('Errormessage from ',message);
  sound(1000);
  delay(400);
  noSound;
  halt(1)
end;


end.