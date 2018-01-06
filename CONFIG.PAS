unit config;


INTERFACE

uses dos,strings;


const numberOfConfigFields      = 2;

type  configRecord              = record
        path                      : dirStr;
        fileName                  : nameStr
      end;

      configFileType            = file of configRecord;

      configManagerOPtr         = ^configManagerO;
      configManagerO            = object
        pathValue                 : dirStr;
        fileNameValue             : nameStr;
        configFile                : configFileType;
        changed                   : boolean;
        constructor init;
        destructor  done;
        function    path     : dirStr;
        function    fileName : nameStr;
        procedure   setFullName(fullName : pathStr);
        procedure   setPath(aPath : dirStr);
        procedure   setFileName(aName : nameStr);
        procedure   getConfig(prompt : string);
        procedure   readConfig;
        procedure   saveConfig;
      end;


IMPLEMENTATION

uses crt,types,auxil,keys,screen;


(*************************************************************************
 *                                                                       *
 *     configManagerO's methods                                          *
 *                                                                       *
 *************************************************************************)


constructor configManagerO.init;

begin
  pathValue:='C:\FILTER\';
  fileNameValue:='FILTER';
  readConfig;
  changed:=false
end;


destructor configManagerO.done;

begin
  if (changed and confirm('Save config file?')) then
    saveConfig
end;


function configManagerO.path : dirStr;

begin
  path:=pathValue
end;


function configManagerO.fileName : nameStr;

begin
  fileName:=fileNameValue
end;


procedure configManagerO.setFullName(fullName : pathStr);

var   dir                       : dirStr;
      name                      : nameStr;
      ext                       : extStr;

begin
  fSplit(fullName,dir,name,ext);
  setPath(dir);
  setFileName(name)
end;


procedure configManagerO.setPath(aPath : dirStr);

begin
  if (aPath<>path) then
    begin
      pathValue:=bigLetters(aPath);
      changed:=true
    end
end;


procedure configManagerO.setFileName(aName : nameStr);

begin
  if (aName<>fileName) then
    begin
      fileNameValue:=bigLetters(aName);
      changed:=true
    end
end;


procedure configManagerO.getConfig(prompt : string);

var   theConfig                 : configRecord;
      field                     : byte;
      returnedChar              : char;


  procedure makeWindow;

  begin
    setMainAttribute(blackOnGray);
    setFrameAttribute(yellowOnGray);
    setTextAttribute(grayOnGray);
    window(10,8,70,11,prompt);
    writeXY(12,9,'Directory:');
    writeXY(12,10,'File name:');
    clsXY(23,9,67,9,whiteOnCyan);
    clsXY(23,10,31,10,whiteOnCyan);
    writeColourXY(23,10,whiteOnCyan,fileName);
    writeXY(32,10,'.CNF')
  end;


  procedure readPath(var field : byte; var aKey : char);

  begin
    with theConfig do
      path:=readWithToggleXY(23,9,45,bigLetters(path),[Tab],aKey);
    if (aKey=Tab) then
      inc(field)
  end;


  procedure readFileName(var field : byte; var aKey : char);

  begin
    with theConfig do
      fileName:=readWithToggleXY(23,10,8,bigLetters(fileName),[Tab],aKey);
    if (aKey=Tab) then
      inc(field)
  end;


begin
  field:=0;
  theConfig.path:=path;
  theConfig.fileName:=fileName;
  saveAttributes;
  makeWindow;
  repeat
    case (field mod numberOfConfigFields) of
      0 : readPath(field,returnedChar);
      1 : readFileName(field,returnedChar)
    end
  until ((returnedChar=CR) and pathExists(theConfig.path,withMessage));
  restoreScreen;
  restoreAttributes;
  setPath(theConfig.path);
  if (theConfig.fileName<>'') then
    setFileName(theConfig.fileName)
end;


procedure configManagerO.readConfig;

const defaultPath               : dirStr = 'c:\filter\';

var   configRead                : configRecord;


  procedure displayWarningAndAbort;

  begin
    setMainAttribute(whiteOnRed);
    setFrameAttribute(yellowOnRed);
    setTextAttribute(whiteOnRed);
    window(6,10,74,13,'Error');
    writeXY(8,11,'Please create the directory C:\FILTER\ '+
                  'before using this program.');
    writeColourXY(25,12,whiteOnRed+blink,
                  'Press any key to terminate....');
    wait;
    restoreScreen;
    dispose(storedScreen,done);
    halt
  end;


begin
  if fileExists('c:\filter\config.fil') then
    begin
      assign(configFile,'c:\filter\config.fil');
      reset(configFile);
      seek(configFile,0);
      read(configFile,configRead);
      close(configFile);
      setPath(configRead.path);
      setFileName(configRead.fileName)
    end
  else if pathExists(defaultPath,withoutMessage) then
    getConfig('No config file, please enter preferences....')
  else
    displayWarningAndAbort
end;


procedure configManagerO.saveConfig;

var   currentConfig             : configRecord;

begin
  changed:=false;
  currentConfig.path:=path;
  currentConfig.fileName:=fileName;
  showStatus('Saving config file....');
  assign(configFile,'c:\filter\config.fil');
  rewrite(configFile);
  seek(configFile,0);
  write(configFile,currentConfig);
  close(configFile);
  restoreScreen
end;


end.