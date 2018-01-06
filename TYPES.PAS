unit types;


INTERFACE

uses dos,keys,strings,oScreen,ADT;


const base                      = $0120;

      bb1PortA                  = base+$0;
      bb1PortB                  = base+$2;
      bb1PortC                  = base+$4;
      bb1ControlRegister        = base+$6;

      bb2PortA                  = base+$8;
      bb2PortB                  = base+$A;
      bb2PortC                  = base+$C;
      bb2ControlRegister        = base+$E;

      bb3PortA                  = base+$10;
      bb3PortB                  = base+$12;
      bb3PortC                  = base+$14;
      bb3ControlRegister        = base+$16;

      modeSetFlag               = $80;   {1000 0000}
      portAOutput               =  $0;   {0000 0000}
      portBInput                =  $2;   {0000 0010}
      portCInput                =  $9;   {0000 1001}

      LFP01                     =  1;
      LFP02                     =  2;
      LFP03                     =  3;
      LFP04                     =  4;
      LFP05                     =  5;
      LFP06                     =  6;
      LFP07                     =  7;
      LFP08                     =  8;
      MUA01                     =  9;
      MUA02                     = 10;
      MUA03                     = 11;
      MUA04                     = 12;
      MUA05                     = 13;
      MUA06                     = 14;
      MUA07                     = 15;
      MUA08                     = 16;

      adressRegister            = bb1PortA;          {Change these constants }
      dataRegister1             = bb1PortB;          {to transfer operation  }
      dataRegister2             = bb1PortC;          {from BB1 to BB2 or BB3.}
      controlRegister           = bb1ControlRegister;

      readTime                  = 1; {The time needed to read a configuration}

      looping                   = true;
      doing                     = false;

      withMessage               = true;
      withoutMessage            = false;

      toNext                    = 0;
      toPrevious                = 1;
      toFirst                   = 2;
      toLast                    = 3;

      blackOnGray               = 112;
      whiteOnGray               = 127;
      yellowOnGray              = 126;
      redOnGray                 = 116;
      grayOnGray                = 120;
      whiteOnBlue               =  31;
      yellowOnBlue              =  30;
      greenOnBlue               =  26;
      blackOnCyan               =  48;
      whiteOnCyan               =  63;
      yellowOnCyan              =  62;
      whiteOnBlack              =  15;
      whiteOnRed                =  79;
      yellowOnRed               =  78;
      magentaOnRed              =  77;

      BIOSSegment               = $0040;
      kbdBufStartOffset         = $001A;
      kbdBufEndOffset           = $001C;

type  wordPtr                   = ^word;

      fileString                = string[12];
      remarkString              = string[67];

      timeRecord                = record
        hours                     : byte;
        minutes                   : byte;
        seconds                   : byte
      end;

      dateRecord                = record
        dayOfWeek                 : byte;
        day                       : byte;
        month                     : byte;
        year                      : word
      end;

      filterRecord              = record
        amplifier                 : longInt;
        polarity                  : char;
        lowpass                   : single;
        highpass                  : single
      end;

      rawConfigArray            = array[LFP01..MUA08] of word;
      analysedConfigArray       = array[LFP01..MUA08] of filterRecord;

      rawConfigRecordPtr        = ^rawConfigRecord;
      rawConfigRecord           = record
        time                      : timeRecord;
        date                      : dateRecord;
        remark                    : remarkString;
        configuration             : rawConfigArray
      end;

      analysedConfigRecord      = record
        time                      : timeRecord;
        date                      : dateRecord;
        remark                    : remarkString;
        configuration             : analysedConfigArray
      end;

      configurationNodeOPtr     = ^configurationNodeO;
      configurationNodeO        = object(doubleNodeO)
        configurationValue        : rawConfigRecord;
        savedInValue              : fileString;
        numberValue               : word;
        constructor init(recordValue : rawConfigRecord;
                         aNumber     : word);
        destructor  done; virtual;
        function    configuration : rawConfigRecordPtr;
        function    savedIn       : string;
        function    number        : word;
        procedure   setConfiguration(aConfiguration : rawConfigRecord);
        procedure   setSavedIn(aFile : string);
        procedure   setNumber(aNumber : word);
      end;

      configurationListOPtr     = ^configurationListO;
      configurationListO        = object(doubleListO)
        currentRemarkValue        : remarkString;
        constructor init;
        destructor  done; virtual;
        function    getPosition    : configurationNodeOPtr;
        function    getFirst       : configurationNodeOPtr;
        function    getLast        : configurationNodeOPtr;
        function    currentRemark  : string;
        function    previousRemark : string;
        function    configuration  : rawConfigRecordPtr;
        function    savedIn        : string;
        function    remark         : string;
        function    number         : word;
        function    numberOfLast   : word;
        function    allSaved       : boolean;
        function    someSaved      : boolean;
        function    someUnsaved    : boolean;
        function    someCommented  : boolean;
        procedure   setRemark(aRemark : string);
        procedure   setSavedIn(aFile : string);
        procedure   renumber;
        procedure   goToNearestUnsaved;
        procedure   removeSavedInFor(deletedFile : string);
      end;

var   storedScreen              : screenOPtr;


IMPLEMENTATION


(*************************************************************************
 *                                                                       *
 *     configurationNodeO(doubleNodeO)'s methods                         *
 *                                                                       *
 *************************************************************************)


constructor configurationNodeO.init(recordValue : rawConfigRecord;
                                        aNumber : word);

begin
  setConfiguration(recordValue);
  savedInValue:='';
  numberValue:=aNumber
end;


destructor configurationNodeO.done;

begin
  dispose(configuration);
  doubleNodeO.done
end;


function configurationNodeO.configuration : rawConfigRecordPtr;

var   aConfigPtr                : rawConfigRecordPtr;

begin
  new(aConfigPtr);
  aConfigPtr^:=configurationValue;
  configuration:=aConfigPtr
end;


function configurationNodeO.savedIn : string;

begin
  savedIn:=savedInValue
end;


function configurationNodeO.number : word;

begin
  number:=numberValue
end;


procedure configurationNodeO.setConfiguration(aConfiguration : rawConfigRecord);

begin
  configurationValue:=aConfiguration
end;


procedure configurationNodeO.setSavedIn(aFile : string);

begin
  savedInValue:=aFile
end;


procedure configurationNodeO.setNumber(aNumber : word);

begin
  numberValue:=aNumber
end;


(*************************************************************************
 *                                                                       *
 *     configurationListO(doubleListO)'s methods                         *
 *                                                                       *
 *************************************************************************)


constructor configurationListO.init;

begin
  currentRemarkValue:='';
  doubleListO.init
end;


destructor configurationListO.done;

begin
  doubleListO.done
end;


function configurationListO.getPosition : configurationNodeOPtr;

begin
  getPosition:=configurationNodeOPtr(position)
end;


function configurationListO.getFirst : configurationNodeOPtr;

begin
  getFirst:=configurationNodeOPtr(first)
end;


function configurationListO.getLast : configurationNodeOPtr;

begin
  getLast:=configurationNodeOPtr(last)
end;


function configurationListO.currentRemark : string;

begin
  currentRemark:=currentRemarkValue
end;


function configurationListO.previousRemark : string;

begin
  if (not startOfList) then
    previousRemark:=configurationNodeOPtr(previous)^.configuration^.remark
  else
    previousRemark:=''
end;


function configurationListO.configuration : rawConfigRecordPtr;

begin
  if (not isEmpty) then
    configuration:=getPosition^.configuration
  else
    configuration:=nil
end;


function configurationListO.savedIn : string;

begin
  if (not isEmpty) then
    savedIn:=getPosition^.savedIn
  else
    savedIn:=''
end;


function configurationListO.remark : string;

begin
  if (not isEmpty) then
    remark:=getPosition^.configuration^.remark
  else
    remark:=''
end;


function configurationListO.number : word;

begin
  if (not isEmpty) then
    number:=getPosition^.number
  else
    number:=65535
end;


function configurationListO.numberOfLast : word;

begin
  if (not isEmpty) then
    numberOfLast:=getLast^.number
  else
    numberOfLast:=0
end;


function configurationListO.allSaved : boolean;

var   allSavedSoFar             : boolean;

begin
  if isEmpty then
    allSaved:=true
  else
    begin
      allSavedSoFar:=true;
      rememberPosition;
      goToStart;
      while ((not endOfList) and allSavedSoFar) do
        begin
          allSavedSoFar:=(allSavedSoFar and (savedIn<>''));
          goForwards
        end;
      allSaved:=(allSavedSoFar and (savedIn<>''));
      restorePosition
    end
end;


function configurationListO.someSaved : boolean;

var   savedFound                : boolean;

begin
  rememberPosition;
  goToStart;
  savedFound:=(savedIn<>'');
  repeat
    goForwards;
    savedFound:=(savedFound or (savedIn<>''))
  until (endOfList or savedFound);
  restorePosition;
  someSaved:=savedFound
end;


function configurationListO.someUnsaved : boolean;

var   unsavedFound              : boolean;

begin
  rememberPosition;
  goToStart;
  unsavedFound:=(savedIn='');
  repeat
    goForwards;
    unsavedFound:=(unsavedFound or (savedIn=''))
  until (endOfList or unsavedFound);
  restorePosition;
  someUnsaved:=unsavedFound
end;


function configurationListO.someCommented : boolean;

var   commentedFound            : boolean;

begin
  rememberPosition;
  goToStart;
  commentedFound:=(remark<>'');
  repeat
    goForwards;
    commentedFound:=(commentedFound or (remark<>''))
  until (endOfList or commentedFound);
  restorePosition;
  someCommented:=commentedFound
end;


procedure configurationListO.setRemark(aRemark : string);

begin
  currentRemarkValue:=aRemark
end;


procedure configurationListO.setSavedIn(aFile : string);

begin
  getPosition^.setSavedIn(aFile)
end;


procedure configurationListO.renumber;

begin
  rememberPosition;
  goToStart;
  getPosition^.setNumber(1);
  while (not endOfList) do
    begin
      goForwards;
      with getPosition^ do
        setNumber(configurationNodeOPtr(position^.previous)^.number+1)
    end;
  restorePosition
end;


procedure configurationListO.goToNearestUnsaved;

var   distance                  : word;
      shortestDistance          : word;
      bestPosition              : doubleNodeOPtr;

begin
  distance:=0;
  rememberPosition;
  if (savedIn<>'') then
    begin
      repeat
        goForwards;
        inc(distance)
      until (endOfList or (savedIn=''));
      if (not (endOfList and (savedIn<>''))) then
        begin
          shortestDistance:=distance;
          bestPosition:=position
        end
      else
        shortestDistance:=65535;
      distance:=0;
      restorePosition;
      repeat
        goBackwards;
        inc(distance)
      until (startOfList or (savedIn=''));
      if (startOfList and (savedIn<>'')) then
        distance:=65535;
      if ((shortestDistance<65535) and (distance>shortestDistance)) then
        goToPosition(bestPosition)
      else if (distance=65535) then
        goToPosition(nil)
    end
end;


procedure configurationListO.removeSavedInFor(deletedFile : string);

begin
  if (not isEmpty) then
    begin
      rememberPosition;
      goToStart;
      if (savedIn=deletedFile) then
        setSavedIn('');
      repeat
        goForwards;
        if (savedIn=deletedFile) then
          setSavedIn('')
      until endOfList;
      restorePosition
    end
end;


end.