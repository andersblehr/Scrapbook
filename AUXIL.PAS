unit auxil;


INTERFACE

uses adt,strings,keys;

const LF                        = #10;

      whiteSpace                = [' ',Tab,LF,CR];

type  charSet                   = set of char;

      messageNodeOPtr           = ^messageNodeO;
      messageNodeO              = object(doubleNodeO)
        msgNum                    : word;
        posInFile                 : longInt;
        from                      : stringPtr;
        date                      : stringPtr;
        subject                   : stringPtr;
        constructor init(vMsgNum : word; vFilePos : longInt;
                         vFrom,vDate,vSubject : string);
        destructor  done; virtual;
        function    messageLine : string;
      end;

      messageListOPtr           = ^messageListO;
      messageListO              = object(doubleListO)
        constructor init;
        destructor  done; virtual;
        function     first       : messageNodeOPtr;
        function     last        : messageNodeOPtr;
        function     position    : messageNodeOPtr;
        function     previous    : messageNodeOPtr;
        function     next        : messageNodeOPtr;
        function     messageLine : string;
        function     posInFile   : longInt;
        procedure    goToElement(elementPos : word);
      end;


const specialKey                : boolean = false;


function nextWord(var aLine : string) : string;

function makeString(aString : string; aLength : byte) : string;

function fileExists(pathToFile : string) : boolean;

function intString(aNumber : word) : string;

function realString(aNumber : real) : string;

procedure beep(frequency,time : word);

procedure fatalError(errorMessage : string);


IMPLEMENTATION

uses crt;


(*****************************************************************************
 *  messageNodeO                                                             *
 *****************************************************************************)


constructor messageNodeO.init(vMsgNum : word; vFilePos : longInt;
                              vFrom,vDate,vSubject : string);

begin
  doubleNodeO.init;
  msgNum:=vMsgNum;
  posInFile:=vFilePos;
  from:=strPtr(vFrom);
  date:=strPtr(vDate);
  subject:=strPtr(vSubject)
end;


destructor messageNodeO.done;

begin
  delStr(from);
  delStr(date);
  delStr(subject);
  doubleNodeO.done
end;


function messageNodeO.messageLine : string;

var   theLine                : string;

begin
  messageLine:=intString(msgNum)+' From: '+makeString(from^,13)+' '+date^+
               ' Subject: '+makeString(subject^,21)
end;


(*****************************************************************************
 *  messageListO                                                             *
 *****************************************************************************)


constructor messageListO.init;

begin
  doubleListO.init
end;


destructor messageListO.done;

begin
  doubleListO.done
end;


function messageListO.first : messageNodeOPtr;

begin
  first:=messageNodeOPtr(doubleListO.first)
end;


function messageListO.last : messageNodeOPtr;

begin
  last:=messageNodeOPtr(doubleListO.last)
end;


function messageListO.position : messageNodeOPtr;

begin
  position:=messageNodeOPtr(doubleListO.position)
end;


function messageListO.previous : messageNodeOPtr;

begin
  previous:=messageNodeOPtr(doubleListO.previous)
end;


function messageListO.next : messageNodeOPtr;

begin
  next:=messageNodeOPtr(doubleListO.next)
end;


function messageListO.messageLine : string;

begin
  messageLine:=position^.messageLine
end;


function messageListO.posInFile : longInt;

begin
  posInFile:=position^.posInFile
end;


procedure messageListO.goToElement(elementPos : word);

var   i                      : word;

begin
  goToStart;
  for i:=1 to (elementPos-1) do
    goForwards
end;


(*****************************************************************************
 *  Exported functions and procedures                                        *
 *****************************************************************************)


function nextWord(var aLine : string) : string;

var   theWord                   : string;

begin
  theWord:='';
  if (aLine<>'') then
    begin
      while ((aLine<>'') and (aLine[1] in whiteSpace)) do
        delete(aLine,1,1);
      while ((aLine<>'') and (not (aLine[1] in whiteSpace))) do
        begin
          theWord:=theWord+aLine[1];
          delete(aLine,1,1)
        end
    end;
  nextWord:=theWord
end;


function makeString(aString : string; aLength : byte) : string;

var   i                      : byte;

begin
  if (length(aString)>=aLength) then
    makeString:=copy(aString,1,aLength)
  else
    begin
      for i:=1 to (aLength-length(aString)) do
        aString:=aString+' ';
      makeString:=aString
    end
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


end.