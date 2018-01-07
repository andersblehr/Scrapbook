program mail;

uses crt,auxil,keys;

const comNoCommand           = 0;
      comThisMsg             = -1;
      comQuit                = -2;
      comListHeaders         = -3;
      comScrollHeaders       = -4;

var   inputFile              : file;


function getMessages(fileName : string) : messageListOPtr;

var   theList                : messageListOPtr;
      theFile                : text;
      count                  : longInt;
      posInFile              : longInt;
      lineLength             : word;
      msgNum                 : word;
      thisLine               : string;
      lineHead               : string;
      from                   : string;
      date                   : string;
      subject                : string;

begin
  theList:=new(messageListOPtr,init);
  assign(theFile,fileName);
  reset(theFile);
  count:=0;
  msgNum:=1;
  while (not (EOF(theFile))) do
    begin
      readLn(theFile,thisLine);
      lineLength:=length(thisLine);
      lineHead:=nextWord(thisLine);
      if (lineHead='From') then
        begin
          posInFile:=count;
          from:=nextWord(thisLine);
          delete(thisLine,1,2);
          date:=thisLine;
          while (not (lineHead='Subject:')) do
            begin
              inc(count,lineLength+2);
              readLn(theFile,thisLine);
              lineLength:=length(thisLine);
              lineHead:=nextWord(thisLine)
            end;
          inc(count,lineLength+2);
          delete(thisLine,1,1);
          subject:=thisLine;
          theList^.addElement(new(messageNodeOPtr,
                                  init(msgNum,posInFile,from,date,subject)));
          gotoXY(18,whereY);
          write(msgNum,')....');
          inc(msgNum)
        end
      else
        inc(count,lineLength+2)
    end;
  writeLn('done');
  close(theFile);
  getMessages:=theList
end;


function number(aString : string) : boolean;

var   stringAsNum            : word;
      code                   : integer;

begin
  val(aString,stringAsNum,code);
  number:=(code=0)
end;


function interpretCommand(aString : string) : integer;

var   stringAsNum            : word;
      ignore                 : integer;

begin
  if (number(aString)) then
    begin
      val(aString,stringAsNum,ignore);
      interpretCommand:=stringAsNum
    end
  else if (length(aString)=1) then
    case aString[1] of
      ' '     : interpretCommand:=comThisMsg;
      'H','h' : interpretCommand:=comListHeaders;
      'Z','z' : interpretCommand:=comScrollHeaders;
      'Q','q' : interpretCommand:=comQuit
    else
      interpretCommand:=comNoCommand
    end
end;


function displayMessage(msgNum : word; startPos,endPos : longInt) : string;

var   numOfChars             : longInt;
      charBuffer             : array[1..1024] of char;
      i,j                    : word;
      numRead                : word;
      buffers                : word;
      rest                   : word;
      linesWritten           : byte;
      colsWritten            : byte;
      commandChar            : char;
      commandString          : string;
      doExit                 : boolean;

begin
  numOfChars:=endPos-startPos;
  linesWritten:=0;
  colsWritten:=0;
  buffers:=numOfChars div 1024;
  rest:=numOfChars mod 1024;
  doExit:=FALSE;
  seek(inputFile,startPos);
  for i:=1 to buffers do
    begin
      blockRead(inputFile,charBuffer,1024,numRead);
      for j:=1 to 1024 do
        begin
          write(charBuffer[j]);
          inc(colsWritten);
          if ((charBuffer[j]=LF) or (colsWritten>80)) then
            begin
              inc(linesWritten);
              colsWritten:=0
            end;
          if (linesWritten=23) then
            begin
              write(':');
              commandChar:=readKey;
              if (commandChar<>' ') then
                begin
                  writeLn(commandChar);
                  doExit:=TRUE;
                  i:=buffers;
                  j:=1024;
                  displayMessage:=commandChar
                end
              else
                begin
                  linesWritten:=0;
                  gotoXY(1,25)
                end
            end
        end
    end;
  if (not (doExit)) then
    begin
      blockRead(inputFile,charBuffer,rest,numRead);
      for i:=1 to rest do
        begin
          write(charBuffer[i]);
          inc(colsWritten);
          if ((charBuffer[i]=LF) or (colsWritten>80)) then
            begin
              inc(linesWritten);
              colsWritten:=0
            end;
          if (linesWritten=23) then
            begin
              write(':');
              commandChar:=readKey;
              if (commandChar<>' ') then
                begin
                  writeLn(commandChar);
                  doExit:=TRUE;
                  i:=rest;
                  displayMessage:=commandChar
                end
              else
                begin
                  linesWritten:=0;
                  gotoXY(1,25)
                end
            end
        end
    end;
  if (not (doExit)) then
    begin
      write(':');
      commandChar:=readKey;
      writeLn(commandChar);
      if (commandChar=' ') then
        begin
          str(succ(msgNum),commandString);
          displayMessage:=commandString
        end
      else
        displayMessage:=commandChar;
    end
end;


procedure runMail(fileName : string);

var   messageList            : messageListOPtr;
      lineCount              : byte;
      command                : integer;
      commandChar            : char;
      commandString          : string;

begin
  assign(inputFile,fileName);
  reset(inputFile,1);
  write('Parsing headers (');
  messageList:=getMessages(fileName);
  messageList^.goToStart;
  lineCount:=1;
  repeat
    writeLn(messageList^.messageLine);
    messageList^.goForwards;
    inc(lineCount)
  until ((messageList^.endofList) or (lineCount>24));
  if (messageList^.endOfList) then
    writeLn(messageList^.messageLine);
  messageList^.goToStart;
  write(':');
  commandChar:=readKey;
  if (commandChar=' ') then
    commandString:=commandChar
  else
    begin
      write(commandChar);
      readLn(commandString);
      commandString:=commandChar+commandString
    end;
  repeat
    command:=interpretCommand(commandString);
    case command of
      comThisMsg :
        str(messageList^.position^.msgNum,commandString);
      comListHeaders :
        begin
          messageList^.goToStart;
          lineCount:=1;
          repeat
            writeLn(messageList^.messageLine);
            messageList^.goForwards;
            inc(lineCount)
          until ((messageList^.endofList) or (lineCount>24));
          if (messageList^.endOfList) then
            writeLn(messageList^.messageLine);
          write(':');
          commandChar:=readKey;
          if (commandChar=' ') then
            commandString:=commandChar
          else
            begin
              write(commandChar);
              readLn(commandString);
              commandString:=commandChar+commandString
            end
        end;
      comScrollHeaders :
        begin
          lineCount:=1;
          repeat
            writeLn(messageList^.messageLine);
            messageList^.goForwards;
            inc(lineCount)
          until ((messageList^.endofList) or (lineCount>24));
          if (messageList^.endOfList) then
            writeLn(messageList^.messageLine);
          write(':');
          commandChar:=readKey;
          if (commandChar=' ') then
            commandString:=commandChar
          else
            begin
              write(commandChar);
              readLn(commandString);
              commandString:=commandChar+commandString
            end
        end
    else if ((command>0) and (command<messageList^.numberOfElements)) then
      begin
        messageList^.goToElement(command);
        commandString:=displayMessage(command,messageList^.posInFile,
                                      messageList^.next^.posInFile)
      end
    else if (command=messageList^.numberOfElements) then
      begin
        messageList^.goToEnd;
        commandString:=displayMessage(command,messageList^.posInFile,
                                      fileSize(inputFile))
      end
    else if (command<>comQuit) then
      begin
        write(':');
        readLn(commandString)
      end
    end;
  until (command=comQuit);
  dispose(messageList,done);
  close(inputFile)
end;


begin
  if (paramCount = 1) then
    if (fileExists(paramStr(1))) then
      runMail(paramStr(1))
    else
      fatalError('File doesn''t exist: '+paramStr(1))
  else
    fatalError('Usage: mail <file>')
end.