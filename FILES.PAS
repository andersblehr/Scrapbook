unit files;


INTERFACE

uses dos,types,keys,strings,oScreen,ADT;


const opened                    = true;
      closed                    = false;

type  dataRecord                = rawConfigRecord;
      dataFileType              = file of dataRecord;

      dataFileOPtr              = ^dataFileO;
      dataFileO                 = object
        thisFile                  : dataFileType;
        pathValue                 : dirStr;
        fileNameValue             : fileString;
        statusValue               : boolean;
        constructor init(nameOfFile : string);
        destructor  done; virtual;
        function    path       : string;
        function    fileName   : string;
        function    status     : boolean;
        function    sizeOfFile : longInt;
        procedure   setPath(aPath : string);
        procedure   setFile(NameOfFile : string);
        procedure   openFile;
        procedure   closeFile;
        procedure   rewriteFile;
        procedure   writeFile(pos : longInt; aRecord : dataRecord);
        procedure   readFile(pos : longInt; var recordRead : dataRecord);
      end;

      fileTreeOPtr              = ^fileTreeO;
      fileTreeO                 = object(stringTreeO)
        constructor init;
        destructor  done; virtual;
        procedure   sortedList(var listOfFiles : doubleListOPtr);
      end;

      fileListNodeOPtr          = ^fileListNodeO;
      fileListNodeO             = object(doubleNodeO)
        fileName                  : fileString;
        constructor init(aFile : string);
        destructor  done; virtual;
        function    getString : string; virtual;
      end;

      chooseFileWindowOPtr      = ^chooseFileWindowO;
      chooseFileWindowO         = object
        pathValue                 : dirStr;
        defaultFileValue          : nameStr;
        fileTree                  : fileTreeOPtr;
        fileList                  : doubleListOPtr;
        fileScreen                : virtualScreenOPtr;
        constructor init(attr : byte);
        destructor  done;
        function    path        : string;
        function    defaultFile : string;
        function    chooseFile(extension : string) : string;
        procedure   setPath(aPath : string);
        procedure   setDefaultFile(aFile : string);
      end;


IMPLEMENTATION

uses screen,auxil;


(*************************************************************************
 *                                                                       *
 *     Auxiliary procedures and functions                                *
 *                                                                       *
 *************************************************************************)


function eightLetters(aFile : string) : string;

var    i                         : byte;

begin
  for i:=1 to 8-length(aFile) do
    aFile:=aFile+' ';
  eightLetters:=aFile
end;


(*************************************************************************
 *                                                                       *
 *     dataFileO's methods                                               *
 *                                                                       *
 *************************************************************************)


constructor dataFileO.init(nameOfFile : string);

begin
  statusValue:=closed;
  setFile(nameOfFile)
end;


destructor dataFileO.done;

begin
  if (status=opened) then
    closeFile
end;


function dataFileO.path : string;

begin
  path:=pathValue
end;


function dataFileO.fileName : string;

begin
  fileName:=fileNameValue
end;


function dataFileO.status : boolean;

begin
  status:=statusValue
end;


function dataFileO.sizeOfFile : longInt;

begin
  if (status=opened) then
    sizeOfFile:=fileSize(thisFile)
  else
    sizeOfFile:=-1
end;


procedure dataFileO.setPath(aPath : string);

begin
  pathValue:=bigLetters(aPath)
end;


procedure dataFileO.setFile(nameOfFile : string);

var   dir                       : dirStr;
      name                      : nameStr;
      ext                       : extStr;

begin
  if (status=opened) then
    closeFile;
  fSplit(nameOfFile,dir,name,ext);
  pathValue:=bigLetters(dir);
  fileNameValue:=bigLetters(name+ext)
end;


procedure dataFileO.openFile;

begin
  if (fileName<>'') then
    begin
      statusValue:=opened;
      assign(thisFile,path+fileName);
      {$I-}
      reset(thisFile);
      {$I+}
      if (IOResult<>0) then
        rewriteFile
    end
end;


procedure dataFileO.closeFile;

begin
  if (status=opened) then
    begin
      close(thisFile);
      statusValue:=closed
    end
end;


procedure dataFileO.rewriteFile;

var   currentStatus             : boolean;

begin
  currentStatus:=status;
  if (currentStatus=closed) then
    openFile;
  rewrite(thisFile);
  if (currentStatus=closed) then
    closeFile
end;


procedure dataFileO.writeFile(pos : longInt; aRecord : dataRecord);

begin
  if (status=opened) then
    begin
      seek(thisFile,pos);
      write(thisFile,aRecord)
    end
end;


procedure dataFileO.readFile(pos : longInt; var recordRead : dataRecord);

begin
  if (status=opened) then
    begin
      seek(thisFile,pos);
      read(thisFile,recordRead)
    end
end;


(*************************************************************************
 *                                                                       *
 *     fileTreeO(stringTreeO)'s methods                                  *
 *                                                                       *
 *************************************************************************)


constructor fileTreeO.init;

begin
  stringTreeO.init;
end;


destructor fileTreeO.done;

begin
  stringTreeO.done
end;


procedure fileTreeO.sortedList(var listOfFiles : doubleListOPtr);


  procedure traverse(where : stringNodeOPtr);

  begin
    if where<>nil then
      begin
        traverse(where^.left);
        listOfFiles^.addElement(new(fileListNodeOPtr,init(where^.key)));
        traverse(where^.right)
      end
  end;


begin
  traverse(head)
end;


(*************************************************************************
 *                                                                       *
 *     fileListNodeO(doubleNodeO)'s methods                              *
 *                                                                       *
 *************************************************************************)


constructor fileListNodeO.init(aFile : string);

begin
  doubleNodeO.init;
  fileName:=aFile
end;


destructor fileListNodeO.done;

begin
  doubleNodeO.done
end;


function fileListNodeO.getString : string;

begin
  getString:=fileName
end;


(*************************************************************************
 *                                                                       *
 *     chooseFileWindowO's methods                                       *
 *                                                                       *
 *************************************************************************)


constructor chooseFileWindowO.init(attr : byte);

begin
  pathValue:='';
  defaultFileValue:='';
  new(fileTree,init);
  new(fileList,init);
  new(fileScreen,init(attr))
end;


destructor chooseFileWindowO.done;

begin
  dispose(fileTree,done);
  dispose(fileList,done);
  dispose(fileScreen,done)
end;


function chooseFileWindowO.path : string;

begin
  path:=pathValue
end;


function chooseFileWindowO.defaultFile : string;

begin
  defaultFile:=defaultFileValue
end;


function chooseFileWindowO.chooseFile(extension : string) : string;

var   numberOfFiles             : byte;
      chosenFile                : string;


  function getFiles(extension : string) : byte;

  var   dirInfo                   : searchRec;


    function name(aFile : string) : string;

    begin
      name:=copy(aFile,1,pos('.',aFile)-1)
    end;


  begin
    findFirst(path+'*.'+extension,archive,dirInfo);
    if (dosError=0) then
      begin
        while (dosError=0) do
          begin
            fileTree^.addNode(new(stringNodeOPtr,init(name(dirInfo.name))));
            findNext(dirInfo)
          end;
        fileTree^.sortedList(fileList);
        getFiles:=fileList^.numberOfElements
      end
    else
      getFiles:=0
  end;


  procedure displayFiles(numberOfFiles : byte);

  var   numberOfRows              : byte;


    procedure makeWindow;

    begin
      window(18,6,63,18,'Choose file');
      writeColourXY(19,8,frameAttribute,
                    '컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
      writeColourXY(18,8,frameAttribute,'�');
      writeColourXY(63,8,frameAttribute,'�');
      writeXY(29,7,'.'+extension)
    end;


    procedure defineScreen(numberOfFiles : byte);

    begin
      if (numberOfFiles<25) then
        numberOfRows:=8
      else
        numberOfRows:=upper(numberOfFiles/3);
      fileScreen^.makeScreen(42,numberOfRows)
    end;


    procedure writeFilesToScreen(numberOfFiles : byte);

    var   i                         : byte;

    begin
      if (numberOfFiles>0) then
        with fileList^ do
          begin
            for i:=0 to numberOfFiles-1 do
              begin
                with fileScreen^ do
                  vWriteXY(1+15*(i mod 3),1+(i div 3),
                           eightLetters(getString)+' '+extension);
                goForwards
              end;
            goToStart
          end
    end;


    procedure showScreen;

    begin
      with fileScreen^ do
        begin
          makeWindow(20,9,61,17);
          showScreen(1,1)
        end
    end;


  begin
    makeWindow;
    defineScreen(numberOfFiles);
    writeFilesToScreen(numberOfFiles);
    showScreen
  end;


  function getChoice(extension : string) : string;

  const edit                      = 0;
        navigate                  = 1;

  var   currentDefault            : string;
        currentPosistion          : byte;
        aKey                      : char;
        mode                      : byte;
        scrollDepth               : byte;


    procedure doEdit(var default : string; var aKey : char; var mode : byte);

    begin
      default:=readWithToggleXY(20,7,8,default,[Tab],aKey);
      if (aKey=Tab) then
        mode:=navigate
    end;


    procedure doNavigate(var default   : string; var position : byte;
                         var direction : char;   var mode     : byte);

    var   aString                   : string;
          header                    : char;


      procedure markField(where,attribute : byte);

      var    yPos                      : byte;


        function yPosition(where : byte) : byte;

        var    yPos                      : byte;

        begin
          yPos:=(9-scrollDepth)+(where div 3);
          if (yPos>17) then
            begin
              fileScreen^.scroll(up);
              inc(scrollDepth);
              yPosition:=17
            end
          else if (yPos<9) then
            begin
              fileScreen^.scroll(down);
              dec(scrollDepth);
              yPosition:=9
            end
          else
            yPosition:=yPos
        end;


      begin
        yPos:=yPosition(where);
        clsAttrXY(19+15*(where mod 3),yPos,
                  32+15*(where mod 3),yPos,attribute)
      end;


      function goToPosition(direction : char; position : byte;
                            var aString : string) : byte;


        function goUp(position : byte; var aString : string) : byte;

        var currentPosition              : byte;
            i                            : byte;

        begin
          currentPosition:=position;
          with fileList^ do
            begin
              for i:=1 to 3 do
                if (currentPosition>0) then
                  begin
                    goBackwards;
                    dec(currentPosition)
                  end;
              aString:=getString
            end;
          goUp:=currentPosition
        end;


        function goDown(position : byte; var aString : string) : byte;

        var currentPosition              : byte;
            i                            : byte;

        begin
          currentPosition:=position;
          with fileList^ do
            begin
              for i:=1 to 3 do
                if (currentPosition<numberOfFiles-1) then
                  begin
                    goForwards;
                    inc(currentPosition)
                  end;
              aString:=getString
            end;
          goDown:=currentPosition
        end;


        function goRight(position : byte; var aString : string) : byte;

        begin
          if (position<numberOfFiles-1) then
            begin
              fileList^.goForwards;
              goRight:=succ(position)
            end
          else
            goRight:=position;
          aString:=fileList^.getString
        end;


        function goLeft(position : byte; var aString : string) : byte;

        begin
          if (position>0) then
            begin
              fileList^.goBackwards;
              goLeft:=pred(position)
            end
          else
            goLeft:=position;
          aString:=fileList^.getString
        end;


      begin
        case direction of
          Up    : goToPosition:=goUp(position,aString);
          Down  : goToPosition:=goDown(position,aString);
          Right : goToPosition:=goRight(position,aString);
          Left  : goToPosition:=goLeft(position,aString)
        end
      end;


    begin
      fileScreen^.initScrolling;
      markField(position,inverseAttribute);
      repeat
        direction:=waitForKey([Up,Down,Left,Right,CR,Esc,Tab],header);
        markField(position,mainAttribute);
        if ((header<>noKey) and (direction in [Up,Down,Left,Right])) then
          begin
            position:=goToPosition(direction,position,default);
            writeColourXY(20,7,readAttribute,eightLetters(default));
            markField(position,inverseAttribute)
          end
        else if ((header=noKey) and (direction=CR)) then
          default:=fileList^.getString;
      until ((header=noKey) and (direction in [CR,Esc,Tab]));
      if (direction=Esc) then
        default:=''
      else if (direction=Tab) then
        mode:=edit;
      fileScreen^.closeScrolling
    end;


  begin
    mode:=edit;
    currentDefault:=defaultFile;
    currentPosistion:=0;
    scrollDepth:=0;
    repeat
      case mode of
        edit     : doEdit(currentDefault,aKey,mode);
        navigate : doNavigate(currentDefault,currentPosistion,aKey,mode)
      end
    until (aKey in [CR,Esc]);
    getChoice:=currentDefault
  end;


  function formatName(name : string) : string;

  var   aString                   : string;

  begin
    if ((name<>'') and (pos('.',name)=0)) then
      if (length(name)>8) then
        formatName:=copy(name,1,8)+'.'+extension
      else
        formatName:=name+'.'+extension
    else
      formatName:=''
  end;


  procedure cleanUp;

  begin
    restoreScreen;
    fileTree^.disposeTree;
    fileList^.emptyList;
    fileScreen^.forgetWindow;
    fileScreen^.forgetScreen
  end;


begin
  extension:=bigLetters(extension);
  numberOfFiles:=getFiles(extension);
  displayFiles(numberOfFiles);
  chosenFile:=bigLetters(formatName(getChoice(extension)));
  if (chosenFile<>'') then
    begin
      setDefaultFile(path+chosenFile);
      chooseFile:=path+chosenFile
    end
  else
    chooseFile:='';
  cleanUp
end;


procedure chooseFileWindowO.setPath(aPath : string);

begin
  pathValue:=bigLetters(aPath)
end;


procedure chooseFileWindowO.setDefaultFile(aFile : string);

var   dir                       : dirStr;
      name                      : nameStr;
      ext                       : extStr;

begin
  fSplit(aFile,dir,name,ext);
  pathValue:=bigLetters(dir);
  defaultFileValue:=bigLetters(name)
end;


end.