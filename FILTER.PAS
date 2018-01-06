program filter;

uses  crt,dos,printer,                { Standard libraries                  }
      types,auxil,files,config,help,  { Libraries made for this application }
      keys,screen,oScreen;            { Old, self-made libraries            }

const mode                      : boolean      = looping;

      loopActionSet             : characterSet = [F1,F2,F3,F4,F10,CtrlF1];
      doActionSet               : characterSet = [F1,F3,F4,F5,F6,F7,F8]+
                                                 [F9,F10,CtrlF1,PgUp,PgDn]+
                                                 [Home,EndP];

var   configurationList         : configurationListOPtr;
      configurationFile         : dataFileOPtr;
      chooseFileWindow          : chooseFileWindowOPtr;
      helpManager               : helpManagerOPtr;

      loopMenu                  : verticalMenuOPtr;
      doMenu                    : verticalMenuOPtr;
      saveConfigurationMenu     : verticalMenuOPtr;
      deleteConfigurationMenu   : verticalMenuOPtr;

      configManager             : configManagerOPtr;

      previousConfiguration     : rawConfigArray;
      thisConfiguration         : rawConfigArray;

      previousDate              : dateRecord;
      currentDate               : dateRecord;
      previousTime              : timeRecord;
      currentTime               : timeRecord;

      kbdBufferStart            : wordPtr;
      kbdBufferEnd              : wordPtr;

      keyPressed                : charTuple;
      actionSet                 : characterSet;


procedure queryKeyboard;

var   regs                      : registers;
      nextCharacter             : word;

begin
  if (kbdBufferStart^<>kbdBufferEnd^) then
    begin
      nextCharacter:=wordPtr(ptr(BIOSSegment,lo(kbdBufferStart^)))^;
      if (lo(nextCharacter)=0) then
        setKey(keyPressed,#0,chr(hi(nextCharacter)))
      else
        setKey(keyPressed,noKey,chr(lo(nextCharacter)));
      regs.ah:=$00;
      intr($16,regs)
    end
end;


procedure resetKeyPressed;

begin
  setKey(keyPressed,noKey,noKey)
end;


procedure clearFields;

begin
  clsXY(15, 4,79,20,defaultMain);
  clsXY(10,21,18,21,defaultMain);
  clsXY(24,21,51,21,defaultMain);
  clsXY(12,23,78,23,defaultMain)
end;


procedure writeTime(time : timeRecord);

begin
  with time do
    writeXY(10,21,getIntStr(hours)+':'+getIntStr(minutes)+':'+getIntStr(seconds))
end;


procedure writeDate(date : dateRecord);


  function getDayOfWeek(day : byte) : string;

  begin
    case day of
      1 : getDayOfWeek:='Monday ';
      2 : getDayOfWeek:='Tuesday ';
      3 : getDayOfWeek:='Wednesday ';
      4 : getDayOfWeek:='Thursday ';
      5 : getDayOfWeek:='Friday ';
      6 : getDayOfWeek:='Saturday ';
      7 : getDayOfWeek:='Sunday '
    end
  end;


  function getMonth(month : byte) : string;

  begin
    case month of
       1 : getMonth:='January ';
       2 : getMonth:='February ';
       3 : getMonth:='March ';
       4 : getMonth:='April ';
       5 : getMonth:='May ';
       6 : getMonth:='June ';
       7 : getMonth:='July ';
       8 : getMonth:='August ';
       9 : getMonth:='September ';
      10 : getMonth:='October ';
      11 : getMonth:='November ';
      12 : getMonth:='December '
    end
  end;


begin
  with date do
    writeXY(24,21,copy(getDayOfWeek(dayOfWeek)+getMonth(month)+getIntStr(day)+' '+getIntStr(year)+'     ',1,27))
end;


procedure writeTimeAndDate(time : timeRecord; date : dateRecord);

begin
  writeTime(time);
  writeDate(date)
end;


procedure extractTime(var time : timeRecord);

var   h,m,s,s100                : word;

begin
  getTime(h,m,s,s100);
  with time do
    begin
      hours:=lo(h);
      minutes:=lo(m);
      seconds:=lo(s)
    end
end;


procedure extractDate(var date : dateRecord);

var   y,m,d,dow                 : word;

begin
  getDate(y,m,d,dow);
  with date do
    begin
      dayOfWeek:=lo(dow);
      day:=lo(d);
      month:=lo(m);
      year:=y
    end
end;


function getFile(extension : string) : string;

begin
  setMainAttribute(blackOnGray);
  setFrameAttribute(yellowOnGray);
  setTextAttribute(whiteOnGray);
  setInverseAttribute(whiteOnBlack);
  getFile:=chooseFileWindow^.chooseFile(extension);
  restoreDefaultAttributes
end;


procedure writeSavedIn(aFile : string);

begin
  clsXY(67,21,78,21,blackOnCyan);
  writeColourXY(67,21,blackOnCyan,aFile)
end;


procedure writeRemark(aRemark : string);

begin
  clsXY(12,23,78,23,defaultMain);
  writeXY(12,23,aRemark)
end;


function currentConfiguration : rawConfigRecordPtr;

begin
  currentConfiguration:=configurationList^.configuration
end;


procedure resetTimeAndDate;

begin
  with previousDate do
    begin
      dayOfWeek:=0;
      day:=0;
      month:=0;
      year:=0
    end;
  with previousTime do
    begin
      hours:=0;
      minutes:=0;
      seconds:=0
    end;
end;


procedure showInfo;


  function beforeApril1993 : boolean;

  var   year,month,d,dow                 : word;

  begin
    getDate(year,month,d,dow);
    beforeApril1993:=((year<1993) or ((year=1993) and (month<4)))
  end;


begin
  setMainAttribute(whiteOnCyan);
  setFrameAttribute(blackOnCyan);
  setTextAttribute(yellowOnCyan);
  if beforeApril1993 then
    window(18,5,62,18,'About this program')
  else
    window(18,5,62,12,'About this program');
  writeXY(22, 7,'(C) 1992 Phillips-Universit꼝 Marburg');
  writeXY(22, 8,'     Marburg an der Lahn, Germany');
  writeXY(22,10,'      Programmed by Anders Blehr');
  if beforeApril1993 then
    begin
      writeXY(22,12,' Until March 1993 I can be reached at');
      writeXY(22,13,'     the following email-adresses:');
      setMainAttribute(yellowOnCyan);
      writeXY(22,15,'           blehr@idt.unit.no');
      writeXY(22,16,'        blehr@cs.kuleuven.ac.be')
    end;
  wait;
  restoreDefaultAttributes;
  restoreScreen
end;


procedure initialize;


  procedure initializeCard(cardConfiguration : byte);

  begin
    setRegister(controlRegister,cardConfiguration)
  end;


  procedure initializeScreen;

  var   filter                    : byte;


    function nameOf(filter : byte) : string;

    begin
      case filter of
         1 : nameOf:='LFP 1';
         2 : nameOf:='LFP 2';
         3 : nameOf:='LFP 3';
         4 : nameOf:='LFP 4';
         5 : nameOf:='LFP 5';
         6 : nameOf:='LFP 6';
         7 : nameOf:='LFP 7';
         8 : nameOf:='LFP 8';
         9 : nameOf:='MUA 1';
        10 : nameOf:='MUA 2';
        11 : nameOf:='MUA 3';
        12 : nameOf:='MUA 4';
        13 : nameOf:='MUA 5';
        14 : nameOf:='MUA 6';
        15 : nameOf:='MUA 7';
        16 : nameOf:='MUA 8'
      end
    end;


  begin
    new(storedScreen,init);
    setCursor(off);
    setDefaultAttributes(whiteOnBlue, yellowOnBlue,whiteOnBlue,blackOnCyan,
                         whiteOnBlack,whiteOnCyan, simpleFrame,shadow);
    windowOver(1,1,80,25,'Current switch configuration');
    setMainAttribute(yellowOnBlue);
    writeXY( 4, 2,'Filter');
    writeXY(21, 2,'Amplifier');
    writeXY(36, 2,'Polarity');
    writeXY(51, 2,'Low pass');
    writeXY(66, 2,'High pass');
    writeXY( 4,21,'Time: ');
    writeXY(19,21,'Day: ');
    writeXY( 3,25,' F1 - Menu ');
    for filter:=LFP01 to MUA08 do
      writeColourXY(4,filter+3,greenOnBlue,nameOf(filter));
    setMainAttribute(defaultMain);
  end;


  procedure initializeConfigManager;

  begin
    new(configManager,init)
  end;


  procedure initializeHelpManager;

  begin
    new(helpManager,init('c:\filter\filter.hlp',blackOnGray))
  end;


  procedure initializeFiles;

  begin
    new(chooseFileWindow,init(blackOnGray));
    with configManager^ do
      begin
        new(configurationFile,init(path+fileName+'.CNF'));
        chooseFileWindow^.setDefaultFile(path+fileName)
      end
  end;


  procedure initializeMenues;

  begin
    new(loopMenu,init(27,7,blackOnGray,redOnGray,whiteOnBlack,yellowOnGray,
          defaultFrameType,defaultShadow,
          '_Get configuration      F2\'+
          '_Save configuration     F3\'+
          '_Print configuration    F4\'+
          '_Toggle mode           F10\'+
          '_Help              Ctrl-F1\'+
          '_About...\','',[]));
    new(doMenu,init(26,7,blackOnGray,redOnGray,whiteOnBlack,yellowOnGray,
          defaultFrameType,defaultShadow,
          '_Save configuration(s)    F3\'+
          '_Print configuration      F4\'+
          '_Forget configuration(s)  F5\'+
          '_Read file                F6\'+
          '_Delete file              F7\'+
          '_Change/view config file  F8\'+
          '_Edit remark              F9\'+
          '_Toggle mode             F10\','',[]));
    doMenu^.addAlternatives(
          '_Help                Ctrl-F1\'+
          '_About...\');
    new(saveConfigurationMenu,init(23,9,blackOnGray,redOnGray,whiteOnBlack,
          yellowOnGray,defaultFrameType,defaultShadow,
          '...only _this configuration      \'+
          '...only _commented configurations\'+
          '...only _unsaved configurations  \'+
          '..._all configurations\','Save...',[]));
    new(deleteConfigurationMenu,init(25,9,blackOnGray,redOnGray,whiteOnBlack,
          yellowOnGray,defaultFrameType,defaultShadow,
          '...only _this configuration  \'+
          '...only _saved configurations\'+
          '..._all configurations\','Forget...',[]));
    deleteConfigurationMenu^.setFrameTextAttribute(blackOnGray);
    saveConfigurationMenu^.setFrameTextAttribute(blackOnGray);
  end;


  procedure initializeList;

  begin
    new(configurationList,init)
  end;


  procedure initializePreviousConfiguration;

  var   filter                    : byte;

  begin
    for filter:=LFP01 to MUA08 do
      previousConfiguration[filter]:=255
  end;


  procedure initializeKeyboardRoutine;

  begin
    kbdBufferStart:=wordPtr(ptr(BIOSSegment,kbdBufStartOffset));
    kbdBufferEnd:=wordPtr(ptr(BIOSSegment,kbdBufEndOffset))
  end;


begin
  actionSet:=loopActionSet;
  resetTimeAndDate;
  initializeCard(modeSetFlag or portAOutput or portBInput or portCInput);
  initializeScreen;
  showInfo;
  initializeHelpManager;
  initializeConfigManager;
  initializeFiles;
  initializeMenues;
  initializeList;
  initializePreviousConfiguration;
  initializeKeyboardRoutine
end;


function readConfigurationFor(filter : byte) : word;

var   lowByte                   : byte;
      highByte                  : byte;

begin
  setRegister(adressRegister,filter);
  delay(readTime);
  lowByte:=readRegister(dataRegister1);
  highByte:=readRegister(dataRegister2);
  readConfigurationFor:=(highByte shl 8)+lowByte
end;


function extractAmplifierValue(filterValue : word; filter : byte) : longInt;

begin
  case filter of
    LFP01..LFP08 :
      case ((filterValue shr 5) and $07) of
        0     : extractAmplifierValue:= 100*(invert((filterValue shr 3) and $01)*9+1);
        1     : extractAmplifierValue:= 200*(invert((filterValue shr 3) and $01)*9+1);
        2     : extractAmplifierValue:= 500*(invert((filterValue shr 3) and $01)*9+1);
        3,4,5 : extractAmplifierValue:=1000*(invert((filterValue shr 3) and $01)*9+1)
      else
        extractAmplifierValue:=-1
      end;
    MUA01..MUA08 :
      case (filterValue and $07) of
        0     : extractAmplifierValue:= 100*(((filterValue shr 3) and $01)*9+1);
        1     : extractAmplifierValue:= 200*(((filterValue shr 3) and $01)*9+1);
        2     : extractAmplifierValue:= 500*(((filterValue shr 3) and $01)*9+1);
        3,4,5 : extractAmplifierValue:=1000*(((filterValue shr 3) and $01)*9+1)
      else
        extractAmplifierValue:=-1
      end
  end
end;


function extractPolarity(filterValue : word; filter : byte) : char;

begin
  case filter of
    LFP01..LFP08 :
      case ((filterValue and $10)<>0) of
        false : extractPolarity:='-';
        true  : extractPolarity:='+'
      end;
    MUA01..MUA08 :
      case ((filterValue and $10)<>0) of
        false : extractPolarity:='+';
        true  : extractPolarity:='-'
      end
  end
end;


function extractLowpassValue(filterValue : word; filter : byte) : single;

begin
  case filter of
    LFP01..LFP08 : extractLowpassValue:=100;
    MUA01..MUA08 : case ((filterValue shr 8) and $07) of
                     0 : extractLowpassValue:= 2000;
                     1 : extractLowpassValue:= 5000;
                     2 : extractLowpassValue:=10000;
                     3 : extractLowpassValue:=20000
                   else
                     extractLowpassvalue:=-1
                   end
  end
end;


function extractHighpassValue(filterValue : word; filter : byte) : single;

begin
  case filter of
    LFP01..LFP08 : case (filterValue and $07) of
                     0 : extractHighpassValue:= 0.1;
                     1 : extractHighpassValue:= 1.0;
                     2 : extractHighpassValue:=10.0;
                     3 : extractHighpassValue:=20.0
                   else
                     extractHighpassValue:=-1
                   end;
    MUA01..MUA08 : case ((filterValue shr 5) and $07) of
                     0   : extractHighpassValue:= 500;
                     1   : extractHighpassValue:=1000;
                     2,3 : extractHighpassValue:=2000
                   else
                     extractHighpassValue:=-1
                   end
  end
end;


procedure analyseWordAt(filter : byte; var aFilterRecord : filterRecord);

begin
  with aFilterRecord do
    begin
      amplifier:=extractAmplifierValue(thisConfiguration[filter],filter);
      polarity:=extractPolarity(thisConfiguration[filter],filter);
      lowpass:=extractLowpassValue(thisConfiguration[filter],filter);
      highpass:=extractHighpassValue(thisConfiguration[filter],filter)
    end
end;


procedure presentConfigurationFor(filter : byte);

var   returnedValues            : filterRecord;

begin
  if (thisConfiguration[filter]<>previousConfiguration[filter]) then
    begin
      analyseWordAt(filter,returnedValues);
      with returnedValues do
        begin
          writeXY(21,filter+3,getRealStr(amplifier));
          writeXY(40,filter+3,polarity);
          writeXY(50,filter+3,getRealStr(lowpass));
          writeXY(66,filter+3,getRealStr(highpass))
        end
    end;
  if (currentTime.seconds<>previousTime.seconds) then
    begin
      writeTime(currentTime);
      previousTime:=currentTime
    end;
  if (currentDate.dayOfWeek<>previousDate.dayOfWeek) then
    begin
      writeDate(currentDate);
      previousDate:=currentDate
    end
end;


procedure getConfiguration;

var   filter                    : byte;
      aConfiguration            : rawConfigRecord;

begin
  showStatus('Adding current configuration to edit list....');
  with aConfiguration do
    begin
      time:=currentTime;
      date:=currentDate;
      remark:='';
      for filter:=LFP01 to MUA08 do
        configuration[filter]:=readConfigurationFor(filter)
    end;
  configurationList^.addElement(new(configurationNodeOPtr,
      init(aConfiguration,succ(configurationList^.numberOfLast))));
  configurationList^.goToEnd;
  restoreScreen
end;


procedure saveLoopConfiguration;

var   aConfigRecord             : rawConfigRecord;
      chosenFile                : string;
      filter                    : byte;

begin
  chosenFile:=getFile('cnf');
  if (chosenFile<>'') then
    begin
      configurationFile^.setFile(chosenFile);
      configurationFile^.openFile;
      showStatus('Saving configuration in file '+configurationFile^.fileName);
      with aConfigRecord do
        begin
          time:=currentTime;
          date:=currentDate;
          remark:='';
          for filter:=LFP01 to MUA08 do
            configuration[filter]:=readConfigurationFor(filter)
        end;
      configurationFile^.writeFile(configurationFile^.sizeOfFile,aConfigRecord);
      configurationFile^.closeFile;
      restoreScreen
    end
end;


procedure saveConfigurations;


  procedure saveThisConfiguration;

  var   chosenFile                : string;

  begin
    if ((configurationList^.savedIn='') or
        confirm('Configuration already saved in file '+configurationList^.savedIn+'. Continue?')) then
      begin
        chosenFile:=getFile('cnf');
        if (chosenFile<>'') then
          begin
            configurationFile^.setFile(chosenFile);
            configurationList^.setSavedIn(configurationFile^.fileName);
            configurationFile^.openFile;
            showStatus('Saving configuration in file '+configurationFile^.fileName);
            configurationFile^.writeFile(configurationFile^.sizeOfFile,currentConfiguration^);
            restoreScreen;
            configurationFile^.closeFile;
            writeSavedIn(configurationList^.savedIn)
          end
      end
  end;


  procedure saveCommentedConfigurations;

  var   chosenFile                : string;
        fileSize                  : longInt;

  begin
    if configurationList^.someCommented then
      begin
        chosenFile:=getFile('cnf');
        if (chosenFile<>'') then
          begin
            configurationFile^.setFile(chosenFile);
            configurationFile^.openFile;
            fileSize:=configurationFile^.sizeOfFile;
            configurationList^.rememberPosition;
            configurationList^.goToStart;
            showStatus('Saving commented configurations in file '+configurationFile^.fileName);
            while (not configurationList^.endOfList) do
              begin
                if (configurationList^.remark<>'') then
                  begin
                    configurationFile^.writeFile(fileSize,currentConfiguration^);
                    configurationList^.setSavedIn(configurationFile^.fileName);
                    inc(fileSize)
                  end;
                configurationList^.goForwards
              end;
            if (configurationList^.remark<>'') then
              begin
                configurationFile^.writeFile(fileSize,currentConfiguration^);
                configurationList^.setSavedIn(configurationFile^.fileName)
              end;
            configurationFile^.closeFile;
            restoreScreen;
            configurationList^.restorePosition
          end;
        writeSavedIn(configurationList^.savedIn)
      end
    else
      showMessage('No commented configurations!')
  end;


  procedure saveUnsavedConfigurations;

  var   chosenFile                : string;
        fileSize                  : longInt;

  begin
    if configurationList^.someUnsaved then
      begin
        chosenFile:=getFile('cnf');
        if (chosenFile<>'') then
          begin
            configurationFile^.setFile(chosenFile);
            configurationFile^.openFile;
            fileSize:=configurationFile^.sizeOfFile;
            configurationList^.rememberPosition;
            configurationList^.goToStart;
            showStatus('Saving unsaved configurations in file '+configurationFile^.fileName);
            while (not configurationList^.endOfList) do
              begin
                if (configurationList^.savedIn='') then
                  begin
                    configurationFile^.writeFile(fileSize,currentConfiguration^);
                    configurationList^.setSavedIn(configurationFile^.fileName);
                    inc(fileSize)
                  end;
                configurationList^.goForwards
              end;
            if (configurationList^.savedIn='') then
              begin
                configurationFile^.writeFile(fileSize,currentConfiguration^);
                configurationList^.setSavedIn(configurationFile^.fileName)
              end;
            configurationFile^.closeFile;
            restoreScreen;
            configurationList^.restorePosition
          end;
        writeSavedIn(configurationList^.savedIn)
      end
    else
      showMessage('All configurations have been saved!')
  end;


  procedure saveAllConfigurations;

  var   chosenFile                : string;
        fileSize                  : longInt;
        someAlreadySaved          : boolean;

  begin
    someAlreadySaved:=configurationList^.someSaved;
    if ((someAlreadySaved and confirm('Some configurations have already been saved. Continue?')) or
        (not someAlreadySaved)) then
      begin
        chosenFile:=getFile('cnf');
        if (chosenFile<>'') then
          begin
            configurationFile^.setFile(chosenFile);
            configurationFile^.openFile;
            fileSize:=configurationFile^.sizeOfFile;
            configurationList^.rememberPosition;
            configurationList^.goToStart;
            showStatus('Saving configurations in file '+configurationFile^.fileName);
            while (not configurationList^.endOfList) do
              begin
                configurationFile^.writeFile(fileSize,currentConfiguration^);
                configurationList^.setSavedIn(configurationFile^.fileName);
                configurationList^.goForwards;
                inc(fileSize)
              end;
            configurationFile^.writeFile(fileSize,currentConfiguration^);
            configurationFile^.closeFile;
            restoreScreen;
            configurationList^.setSavedIn(configurationFile^.fileName);
            configurationList^.restorePosition
          end;
        writeSavedIn(configurationList^.savedIn)
      end
  end;


begin
  if (not configurationList^.isEmpty) then
    case askWithMenu(saveConfigurationMenu) of
      'T' : saveThisConfiguration;
      'C' : saveCommentedConfigurations;
      'U' : saveUnsavedConfigurations;
      'A' : saveAllConfigurations
    end
  else
    showMessage('No current configuration!')
end;


procedure printConfiguration;

var   i,j                       : byte;
      aString                   : string;
      screenToBePrinted         : screenOPtr;


  function printerReady : boolean;

  var   regs                      : registers;
        statusByte                : byte;
        timeoutError              : boolean;
        linkError                 : boolean;
        onLine                    : boolean;
        outOfPaper                : boolean;
        printerBusy               : boolean;
        ack                       : boolean;

  begin
    regs.ah:=$02;
    regs.dx:=$00;
    intr($17,regs);
    statusByte:=regs.ah;
    timeoutError:= ((statusByte and $01)       =1);
    linkError   :=(((statusByte and $08) shr 3)=1);
    onLine      :=(((statusByte and $10) shr 4)=1);
    outOfPaper  :=(((statusByte and $20) shr 5)=1);
    ack         :=(((statusByte and $40) shr 6)=0);
    printerBusy :=(((statusByte and $80) shr 7)=0);
    printerReady:=((not timeoutError) and (not linkError ) and
                        onLine        and (not outOfPaper) and
                   (not printerBusy ) and      ack)
  end;


  procedure initializePrinter;

  var   regs                      : registers;

  begin
    regs.ah:=$01;
    regs.dx:=$00;
    intr($17,regs)
  end;


begin
  if ((not configurationList^.isEmpty) or (mode=looping)) then
    if printerReady then
      begin
        initializePrinter;
        new(screenToBePrinted,init);
        showStatus('Printing configuration....');
        for i:=2 to 23 do
          begin
            aString:='';
            for j:=2 to 78 do
              aString:=aString+screenToBePrinted^.storedScreen[i][j].ch;
            writeLn(lst,aString)
          end;
        writeLn(lst,NewPage);
        restoreScreen;
        dispose(screenToBePrinted,done)
      end
    else
      showMessage('Printer not responding correctly!')
  else
    showMessage('No current configuration!')
end;


procedure presentConfiguration(aConfiguration : rawConfigRecord;
                               aFile          : string;
                               number         : word);

var   analysedConfiguration     : analysedConfigRecord;
      filter                    : byte;


  procedure writeConfiguration(analysedConfiguration : analysedConfigRecord;
                               aFile                 : string;
                               number                : word);

  var   filter                    : byte;
        numberAsString            : string;
        numberOfLastAsString      : string;
        toBeOutPut                : string;


    function stringify(aNumber : word) : string;

    var   aString                   : string;

    begin
      str(aNumber,aString);
      stringify:=aString
    end;


  begin
    with analysedConfiguration do
      begin
        if (remark<>'') then
          configurationList^.setRemark(remark)
        else
          configurationList^.setRemark(configurationList^.previousRemark);
        writeTimeAndDate(time,date);
        writeSavedIn(aFile);
        writeRemark(remark);
        for filter:=LFP01 to MUA08 do
          with configuration[filter] do
            begin
              numberAsString:=stringify(number);
              numberOfLastAsString:=
                stringify(configurationList^.numberOfLast);
              toBeOutput:=' '+numberAsString+':'+numberOfLastAsString+' ';
              writeXY(76-length(toBeOutput),1,'컴�');
              setMainAttribute(yellowOnBlue);
              writeXY(79-length(toBeOutput),1,toBeOutput);
              setMainAttribute(defaultMain);
              writeXY(21,filter+3,getRealStr(amplifier));
              writeXY(40,filter+3,polarity);
              writeXY(50,filter+3,getRealStr(lowpass));
              writeXY(66,filter+3,getRealStr(highpass))
            end
      end
  end;


  procedure analyseConfiguration(    filter        : byte;
                                 var aFilterRecord : filterRecord;
                                     aWord         : word);

  begin
    with aFilterRecord do
      begin
        amplifier:=extractAmplifierValue(aWord,filter);
        polarity:=extractPolarity(aWord,filter);
        lowpass:=extractLowpassValue(aWord,filter);
        highpass:=extractHighpassValue(aWord,filter)
      end
  end;


begin
  with analysedConfiguration do
    begin
      time:=aConfiguration.time;
      date:=aConfiguration.date;
      remark:=aConfiguration.remark;
      for filter:=LFP01 to MUA08 do
        analyseConfiguration(filter,configuration[filter],
                             aConfiguration.configuration[filter])
    end;
  writeConfiguration(analysedConfiguration,aFile,number)
end;


procedure deleteConfigurations;


  procedure deleteThisConfiguration;

  begin
    if ((configurationList^.savedIn<>'') or
        confirm('Configuration has not been saved. Continue?')) then
      begin
        configurationList^.removeElement(configurationList^.position);
        if (not configurationList^.isEmpty) then
          begin
            configurationList^.renumber;
            with configurationList^ do
              presentConfiguration(currentConfiguration^,savedIn,number)
          end
        else
          begin
            writeXY(71,1,'컴컴컴컴');
            clearFields;
            clsXY(67,21,78,21,blackOnCyan)
          end
      end
  end;


  procedure deleteSavedConfigurations;

  begin
    configurationList^.goToNearestUnsaved;
    configurationList^.rememberPosition;
    configurationList^.goToStart;
    while (not configurationList^.endOfList) do
      if (configurationList^.savedIn<>'') then
        begin
          configurationList^.goForwards;
          configurationList^.removeElement(configurationList^.position^.previous)
        end
      else
        configurationList^.goForwards;
    if (configurationList^.savedIn<>'') then
      configurationList^.removeElement(configurationList^.position);
    configurationList^.restorePosition;
    if (not configurationList^.isEmpty) then
      begin
        configurationList^.renumber;
        with configurationList^ do
          presentConfiguration(currentConfiguration^,savedIn,number)
      end
    else
      begin
        writeXY(71,1,'컴컴컴컴');
        clearFields;
        clsXY(67,21,78,21,blackOnCyan)
      end
  end;


  procedure deleteAllConfigurations;

  var   question                  : string;

  begin
    if configurationList^.allSaved then
      question:='Do you really want to throw away all configurations?'
    else
      question:='Some configurations have not been saved. Continue?';
    if confirm(question) then
      begin
        configurationList^.emptyList;
        writeXY(71,1,'컴컴컴컴');
        clearFields;
        clsXY(67,21,78,21,blackOnCyan)
      end
  end;


begin
  if configurationList^.isEmpty then
    showMessage('No current configuration!')
  else
    case askWithMenu(deleteConfigurationMenu) of
      'T' : deleteThisConfiguration;
      'S' : deleteSavedConfigurations;
      'A' : deleteAllConfigurations
    end
end;


procedure readConfigurationFromFile;

var   i                         : byte;
      chosenFile                : string;
      configuration             : rawConfigRecord;

begin
  if (configurationList^.isEmpty or
      confirm('Current configurations will be deleted. Continue?')) then
    begin
      chosenFile:=getFile('cnf');
      if (chosenFile<>'') then
        if fileExists(chosenFile) then
          begin
            configurationFile^.setFile(chosenFile);
            configurationFile^.openFile;
            if (configurationFile^.sizeOfFile>0) then
              begin
                configurationList^.emptyList;
                showStatus('Reading file '+configurationFile^.fileName+'....');
                for i:=0 to configurationFile^.sizeOfFile-1 do
                  begin
                    configurationFile^.readFile(i,configuration);
                    configurationList^.addElement(new(configurationNodeOPtr,
                        init(configuration,configurationList^.numberOfLast+1)));
                    configurationList^.goForwards;
                    configurationList^.setSavedIn(configurationFile^.fileName)
                  end;
                restoreScreen;
                with configurationList^ do
                  presentConfiguration(currentConfiguration^,savedIn,number)
              end
            else
              showMessage('File is empty!');
            configurationFile^.closeFile
          end
        else
          showMessage('File not found!')
    end
end;


procedure deleteFile;

var   chosenFile                : string;
      rememberFile              : string;

begin
  chosenFile:=getFile('cnf');
  if (chosenFile<>'') then
    if fileExists(chosenFile) then
      begin
        rememberFile:=configurationFile^.path+configurationFile^.fileName;
        configurationFile^.setFile(chosenFile);
        if confirm('File '+configurationFile^.fileName+' is about to be rewritten. Continue?') then
          begin
            configurationFile^.rewriteFile;
            configurationList^.removeSavedInFor(configurationFile^.fileName);
            writeSavedIn(configurationList^.savedIn)
          end;
        configurationFile^.setFile(rememberFile);
      end
    else
      showMessage('File not found!')
end;


procedure changeViewConfig;

begin
  with configManager^ do
    begin
      getConfig('Edit to make changes, or press Return to exit');
      configurationFile^.setFile(path+fileName+'.CNF');
      chooseFileWindow^.setDefaultFile(path+fileName)
    end
end;


procedure getRemark;

var   aRemark                   : string;


  function readRemark : string;

  var   aRemark                    : string;

  begin
    setMainAttribute(blackOnGray);
    setFrameAttribute(yellowOnGray);
    setTextAttribute(grayOnGray);
    with configurationList^ do
      begin
        aRemark:=readWindowXY(7,9,67,'Edit remark',currentRemark);
        setRemark(aRemark)
      end;
    restoreDefaultAttributes;
    writeRemark(aRemark);
    readRemark:=aRemark
  end;


begin
  if (configurationList^.isEmpty) then
    showMessage('No current configuration!')
  else
    with currentConfiguration^ do
      begin
        if ((remark='') or confirm('Remark exists. Continue?')) then
          aRemark:=readRemark;
        if (aRemark<>remark) then
          begin
            remark:=aRemark;
            configurationList^.setSavedIn('');
            writeSavedIn('')
          end
      end
end;


procedure toggleMode;

begin
  setFrameAttribute(yellowOnBlue);
  frame(1,1,80,25,'');
  delay(100);
  setFrameAttribute(defaultFrame);
  case mode of
    looping :
      begin
        mode:=doing;
        actionSet:=doActionSet;
        frame(1,1,80,25,'Edit configurations');
        clearFields;
        writeColourXY( 3,25,yellowOnBlue,' F1 - Menu ');
        writeColourXY(52,21,yellowOnBlue,'Saved in file: ');
        clsXY(67,21,78,21,blackOnCyan);
        writeColourXY( 4,23,yellowOnBlue,'Remark: ');
        writeColourXY(38,25,yellowOnBlue,
                      ' PgUp/PgDn - Next/previous configuration ');
        if (currentConfiguration<>nil) then
          with configurationList^ do
            presentConfiguration(currentConfiguration^,savedIn,number)
        else
          showMessage('No current configuration!')
      end;
    doing :
      begin
        mode:=looping;
        actionSet:=loopActionSet;
        frame(1,1,80,25,'Current switch configuration');
        clearFields;
        clsXY(52,21,78,21,defaultMain);
        clsXY( 4,23,18,23,defaultMain);
        writeColourXY( 3,25,yellowOnBlue,' F1 - Menu ');
        resetTimeAndDate
      end
  end
end;


procedure doHelp;

begin
  setMainAttribute(blackOnGray);
  setMarkedAttribute(yellowOnGray);
  setFrameAttribute(grayOnGray);
  setTextAttribute(whiteOnGray);
  setInverseAttribute(blackOnCyan);
  setReadAttribute(redOnGray);
  helpManager^.navigate;
  restoreDefaultAttributes
end;


procedure goToConfiguration(which : byte);

begin
  with configurationList^ do
    case which of
      toNext :
        if endOfList then
          showMessage('Last configuration')
        else
          begin
            goForwards;
            presentConfiguration(currentConfiguration^,savedIn,number)
        end;
      toPrevious :
        if startOfList then
          showMessage('First configuration')
        else
          begin
            goBackwards;
            presentConfiguration(currentConfiguration^,savedIn,number)
          end;
      toFirst :
        begin
          goToStart;
          presentConfiguration(currentConfiguration^,savedIn,number)
        end;
      toLast :
        begin
          goToEnd;
          presentConfiguration(currentConfiguration^,savedIn,number)
        end
    end
end;


procedure doLoopActionOn(aKey : char);


  procedure useMenu;

  begin
    case askWithMenu(loopMenu) of
      'G' : getConfiguration;
      'S' : saveLoopConfiguration;
      'P' : printConfiguration;
      'T' : toggleMode;
      'H' : doHelp;
      'A' : showInfo
    end
  end;


begin
  case aKey of
    F1     : useMenu;
    F2     : getConfiguration;
    F3     : saveLoopConfiguration;
    F4     : printConfiguration;
    F10    : toggleMode;
    CtrlF1 : doHelp
  end
end;


procedure doDoingActionOn(aKey : char);


  procedure useMenu;

  begin
    case askWithMenu(doMenu) of
      'S' : saveConfigurations;
      'P' : printConfiguration;
      'F' : deleteConfigurations;
      'R' : readConfigurationFromFile;
      'D' : deleteFile;
      'C' : changeViewConfig;
      'E' : getRemark;
      'T' : toggleMode;
      'H' : doHelp;
      'A' : showInfo
    end
  end;


begin
  case aKey of
    F1     : useMenu;
    F3     : saveConfigurations;
    F4     : printConfiguration;
    F5     : deleteConfigurations;
    F6     : readConfigurationFromFile;
    F7     : deleteFile;
    F8     : changeViewConfig;
    F9     : getRemark;
    F10    : toggleMode;
    CtrlF1 : doHelp;
    PgUp   : goToConfiguration(toNext);
    PgDn   : goToConfiguration(toPrevious);
    Home   : goToConfiguration(toFirst);
    EndP   : goToConfiguration(toLast)
  end
end;


procedure loop;


  procedure doLoopingLoop;

  var   filter                    : byte;

  begin
    for filter:=LFP01 to MUA08 do
      begin
        thisConfiguration[filter]:=readConfigurationFor(filter);
        with previousTime do
          if ((hours=0) and (minutes=0) and (seconds=0)) then
            extractDate(currentDate);
        extractTime(currentTime);
        presentConfigurationFor(filter)
      end;
    if ((keyPressed.header=#0) and (keyPressed.primary in actionSet)) then
      begin
        doLoopActionOn(keyPressed.primary);
        resetKeyPressed
      end
  end;


  procedure doDoingLoop;

  begin
    if ((keyPressed.header=#0) and (keyPressed.primary in actionSet)) then
      begin
        doDoingActionOn(keyPressed.primary);
        resetKeyPressed
      end
  end;


begin
  repeat
    resetKeyPressed;
    queryKeyboard;
    case mode of
      looping : doLoopingLoop;
      doing   : doDoingLoop
    end;
    if ((keyPressed.header=noKey) and (keyPressed.primary=Esc)) then
      if (not confirm('Are you sure you want to quit?')) then
        setKey(keyPressed,noKey,noKey)
  until ((keyPressed.header=noKey) and (keyPressed.primary=Esc) and
         (configurationList^.allSaved or
          confirm('Configurations will be lost. Continue?')))
end;


procedure cleanUp;

begin
  dispose(configurationList,done);
  dispose(deleteConfigurationMenu,done);
  dispose(saveConfigurationMenu,done);
  dispose(doMenu,done);
  dispose(loopMenu,done);
  dispose(configurationFile,done);
  dispose(chooseFileWindow,done);
  dispose(configManager,done);
  dispose(helpManager,done);
  dispose(storedScreen,done);
  setCursor(on)
end;


begin
  initialize;
  loop;
  cleanUp
end.