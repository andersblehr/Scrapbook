unit auxil;


INTERFACE

uses dos,graph;

const BackSp                    = #8;
      CR                        = #13;
      Esc                       = #27;

type  charSet                   = set of char;

const specialKey                : boolean = false;


function readKey : char;

function homePath(fileName : string) : string;

function picturePath(fileName : string) : string;

function pcxPath(fileName : string) : string;

function palettePath(fileName : string) : string;

function nextWord(var aLine : string; whiteSpace : charSet) : string;

function appendExtension(path : pathStr; wantedExtension : extStr) : pathStr;

function legalFileName(fileName : string) : boolean;

function fileExists(pathToFile : string) : boolean;

function intString(aNumber : word) : string;

function realString(aNumber : real) : string;

function grConfirm(x,y : word; question : string) : boolean;

function grRead(x,y : word) : string;

function grGetReply(x,y : word; prompt : string) : string;

procedure grClear(x1,y1,x2,y2 : word);

procedure grWriteChar(x,y : word; aChar : char);

procedure makePoint(anX,anY : word; aPoint : pointType);

procedure beep(frequency,time : word);

procedure fatalError(errorMessage : string);


IMPLEMENTATION

uses crt;

const homeDirectory             = 'c:\user\blehr\';
      picDirectory              = 'c:\user\blehr\fag\diplom\bilder\';
      pcxDirectory              = 'c:\user\blehr\fag\diplom\bilder\pcx\';
      palDirectory              = 'c:\user\blehr\fag\diplom\bilder\pal\';


(**************************************************************************
 *                                                                        *
 *    Internals                                                           *
 *                                                                        *
 **************************************************************************)


function possibleLackingExtension(path             : pathStr;
                                  correctExtension : extStr) : extStr;

var   ignoreDirectory           : dirStr;
      ignoreFileName            : nameStr;
      extension                 : extStr;

begin
  fSplit(path,ignoreDirectory,ignoreFileName,extension);
  if ((extension='') or (extension<>correctExtension)) then
    possibleLackingExtension:=correctExtension
  else
    possibleLackingExtension:=''
end;


(**************************************************************************
 *                                                                        *
 *    Implementation                                                      *
 *                                                                        *
 **************************************************************************)


function readKey : char;

var   aKey                      : char;

begin
  aKey:=crt.readKey;
  specialKey:=(aKey=#0);
  if specialKey then
    readKey:=crt.readKey
  else
    readKey:=aKey
end;


function homePath(fileName : string) : string;

begin
  homePath:=homeDirectory+fileName
end;


function picturePath(fileName : string) : string;

begin
  picturePath:=picDirectory+fileName+possibleLackingExtension(fileName,'.pic')
end;


function pcxPath(fileName : string) : string;

begin
  pcxPath:=pcxDirectory+fileName+possibleLackingExtension(fileName,'.pcx')
end;


function palettePath(fileName : string) : string;

begin
  palettePath:=palDirectory+fileName+possibleLackingExtension(fileName,'.pal')
end;


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


function legalFileName(fileName : string) : boolean;

const legalChars                = ['a'..'z','A'..'Z','0'..'9','_'];

var   successSoFar              : boolean;
      i                         : byte;

begin
  successSoFar:=((fileName<>'') and (length(fileName)<9) and
                 (fileName[1] in (legalChars-['1'..'9'])));
  if successSoFar then
    for i:=2 to length(fileName) do
      successSoFar:=(successSoFar and (fileName[i] in legalChars));
  legalFileName:=successSoFar
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


function grConfirm(x,y : word; question : string) : boolean;

var   answer                    : char;

begin
  question:=question+' (Y/N)? ';
  outTextXY(x,y,question);
  repeat
    answer:=readKey
  until (answer in ['y','n','Y','N']);
  outTextXY(x+textWidth(question),y,upCase(answer));
  grConfirm:=(answer in ['y','Y'])
end;


function grRead(x,y : word) : string;

var   oldTextSettings           : textSettingsType;
      stringRead                : string;
      charWidth                 : word;
      charHeight                : word;
      xPos                      : word;
      aKey                      : char;


  procedure treatKey;

  begin
    if (not specialKey) then
      if (not (aKey in [BackSp,CR,Esc])) then
        begin
          stringRead:=stringRead+aKey;
          grWriteChar(xPos,y,aKey);
          inc(xPos,charWidth);
          outTextXY(xPos,y,'_')
        end
      else if ((aKey=BackSp) and (stringRead<>'')) then
        begin
          grWriteChar(xPos,y,' ');
          dec(xPos,charWidth);
          grWriteChar(xPos,y,'_');
          delete(stringRead,length(stringRead),1)
        end
  end;


begin
  getTextSettings(oldTextSettings);
  setTextStyle(oldTextSettings.font,horizDir,oldTextSettings.charSize);
  setTextJustify(leftText,bottomText);
  outTextXY(x,y,'_');
  stringRead:='';
  charWidth:=textWidth(' ');
  charHeight:=textHeight(' ');
  xPos:=x;
  repeat
    aKey:=readKey;
    treatKey
  until (aKey in [CR,Esc]);
  grWriteChar(xPos,y,' ');
  setTextJustify(oldTextSettings.horiz,oldTextSettings.vert);
  setTextStyle(oldTextSettings.font,oldTextSettings.direction,
               oldTextSettings.charSize);
  case aKey of
    CR  : grRead:=stringRead;
    Esc : grRead:=''
  end
end;


function grGetReply(x,y : word; prompt : string) : string;

begin
  prompt:=prompt+': ';
  outTextXY(x,y,prompt);
  grGetReply:=grRead(x+textWidth(prompt),y)
end;


procedure grClear(x1,y1,x2,y2 : word);

var   oldFillSettings           : fillSettingsType;

begin
  getFillSettings(oldFillSettings);
  setFillStyle(solidFill,getBkColor);
  bar(x1,y1,x2,y2);
  setFillStyle(oldFillSettings.pattern,oldFillSettings.color)
end;


procedure grWriteChar(x,y : word; aChar : char);

var   oldTextSettings           : textSettingsType;

begin
  getTextSettings(oldTextSettings);
  setTextJustify(leftText,bottomText);
  grClear(x,y,x+textWidth(' '),y-textHeight(' '));
  outTextXY(x,y,aChar);
  setTextJustify(oldTextSettings.horiz,oldTextSettings.vert)
end;


procedure makePoint(anX,anY : word; aPoint : pointType);

begin
  aPoint.x:=anX;
  aPoint.y:=anY
end;


procedure beep(frequency,time : word);

begin
  sound(frequency);
  delay(time);
  noSound
end;


procedure fatalError(errorMessage : string);

begin
  if (getGraphMode>=0) then
    closeGraph;
  writeLn(errorMessage);
  beep(600,100);
  halt(1)
end;


end.