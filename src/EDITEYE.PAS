program editEye;

uses crt,graph,auxil,mice,SVGA;

const maxSize                   = 512;

type  bufferType                = array[1..maxSize] of byte;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

var   xSize                     : word;
      ySize                     : word;
      image                     : pixelMatrixPtr;
      mouse                     : mouseType;


procedure init;

var   imageFile                 : file;
      buffer                    : bufferType;


  procedure initializePicture;

  var   i,j                       : word;

  begin
    SVGA_initGraphics(mode1024x768);
    SVGA_setBlackAndWhitePalette;
    assign(imageFile,picturePath(paramStr(1)));
    reset(imageFile,1);
    blockRead(imageFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    getMem(image,4*ySize);
    for i:=1 to ySize do
      begin
        blockRead(imageFile,buffer,xSize);
        getMem(image^[i],xSize);
        for j:=1 to xSize do
          begin
            image^[i]^[j]:=buffer[j];
            putPixel(j,i,buffer[j])
          end
      end
  end;


  procedure initializeMouse;

  begin
    if initMouse then
      begin
        graphMouse(1,1,xSize,ySize);
        showMouse
      end
    else
      begin
        closeGraph;
        writeLn('Mouse not responding.');
        halt(1)
      end
  end;


begin
  if (paramCount<>0) then
    if fileExists(picturePath(paramStr(1))) then
      begin
        initializePicture;
        setTextStyle(defaultFont,horizDir,1);
        setTextJustify(leftText,bottomText);
        outTextXY(1,ySize+20,'File: '+picturePath(paramStr(1)));
        initializeMouse
      end
    else
      fatalError('Picture file not found: '+paramStr(1)+'.pic')
  else
    fatalError('Usage: editeye <picture file (no extension)>')
end;


procedure mouseLoop;

var   oldMouse                  : mouseType;
      firstCorner               : pointPtr;
      secondCorner              : pointPtr;
      upperLeftCorner           : pointPtr;
      lowerRightCorner          : pointPtr;
      mouseCorner               : pointPtr;
      editing                   : boolean;
      break                     : boolean;


  procedure makeCorners;

  begin
    new(firstCorner);
    new(secondCorner);
    new(upperLeftCorner);
    new(lowerRightCorner);
    new(mouseCorner)
  end;


  procedure getMouse(var aMouse : mouseType);

  begin
    while (not ((not aMouse.leftButton) and (not aMouse.rightButton))) do
      pollMouse(aMouse);
    pollMouse(aMouse)
  end;


  function mousePositionChanged(mouse1,mouse2 : mouseType) : boolean;

  begin
    mousePositionChanged:=((mouse1.x<>mouse2.x) or (mouse1.y<>mouse2.y))
  end;


  procedure getCorners(corner1,corner2 : pointPtr);

  begin
    if ((corner1^.x<=corner2^.x) and (corner1^.y<=corner2^.y)) then
      begin
        makePoint(corner1^.x,corner1^.y,upperLeftCorner);
        makePoint(corner2^.x,corner2^.y,lowerRightCorner)
      end
    else if ((corner2^.x<=corner1^.x) and (corner2^.y<=corner1^.y)) then
      begin
        makePoint(corner2^.x,corner2^.y,upperLeftCorner);
        makePoint(corner1^.x,corner1^.y,lowerRightCorner)
      end
    else if ((corner1^.x<=corner2^.x) and (corner2^.y<=corner1^.y)) then
      begin
        makePoint(corner1^.x,corner2^.y,upperLeftCorner);
        makePoint(corner2^.x,corner1^.y,lowerRightCorner)
      end
    else
      begin
        makePoint(corner2^.x,corner1^.y,upperLeftCorner);
        makePoint(corner1^.x,corner2^.y,lowerRightCorner)
      end
  end;


  procedure drawRectangle;

  begin
    makePoint(mouse.x,mouse.y,mouseCorner);
    getCorners(firstCorner,mouseCorner);
    rectangle(upperLeftCorner^.x,upperLeftCorner^.y,
              lowerRightCorner^.x,lowerRightCorner^.y)
  end;


  procedure eraseRectangle;

  var   i                         : word;

  begin
    for i:=upperLeftCorner^.x to lowerRightCorner^.x do
      begin
        putPixel(i,upperLeftCorner^.y,
                 image^[upperLeftCorner^.y]^[i]);
        putPixel(i,lowerRightCorner^.y,
                 image^[lowerRightCorner^.y]^[i]);
      end;
    for i:=upperLeftCorner^.y to lowerRightCorner^.y do
      begin
        putPixel(upperLeftCorner^.x,i,
                 image^[i]^[upperLeftCorner^.x]);
        putPixel(lowerRightCorner^.x,i,
                 image^[i]^[lowerRightCorner^.x])
      end
  end;


  procedure saveExtractedImage;

  var   fileName                  : string;
        break                     : boolean;
        newXSize                  : word;
        newYSize                  : word;


    procedure saveImageInFile(fileName : string);

    var   infoText                  : string;
          imageFile                 : file;
          buffer                    : bufferType;
          i,j                       : word;

    begin
      infoText:='Saving transformed image in file '+
                picturePath(fileName)+'.... ';
      outTextXY(1,ySize+70,infoText);
      assign(imageFile,picturePath(fileName));
      rewrite(imageFile,1);
      buffer[1]:=hi(newXSize);
      buffer[2]:=lo(newXSize);
      buffer[3]:=hi(newYSize);
      buffer[4]:=lo(newYSize);
      blockWrite(imageFile,buffer,4);
      for i:=upperLeftCorner^.y to lowerRightCorner^.y do
        begin
          for j:=upperLeftCorner^.x to lowerRightCorner^.x do
            buffer[j-upperLeftCorner^.x+1]:=image^[i]^[j];
          blockWrite(imageFile,buffer,newXSize)
        end;
      close(imageFile);
      outTextXY(textWidth(infoText),ySize+70,'done.')
    end;


  begin
    if grConfirm(1,ySize+40,'Do you want to save the extracted image') then
      begin
        getCorners(firstCorner,secondCorner);
        newXSize:=lowerRightCorner^.x-upperLeftCorner^.x+1;
        newYSize:=lowerRightCorner^.y-upperLeftCorner^.y+1;
        repeat
          grClear(1,ySize+50,getMaxX,ySize+50-textHeight(' '));
          fileName:=grGetReply(1,ySize+50,'File name');
          break:=(((legalFileName(fileName) and
                   (not fileExists(picturePath(fileName)))) or
                  (fileName='')));
          if (not break) then
            beep(1000,300)
        until break;
        if (fileName<>'') then
          saveImageInFile(fileName)
      end
  end;


  procedure disposeCorners;

  begin
    dispose(mouseCorner);
    dispose(lowerRightCorner);
    dispose(upperLeftCorner);
    dispose(secondCorner);
    dispose(firstCorner)
  end;


begin
  editing:=false;
  makeCorners;
  pollMouse(mouse);
  repeat
    getMouse(mouse);
    break:=(mouse.rightButton and (not editing));
    if mouse.leftButton then
      begin
        editing:=true;
        makePoint(mouse.x,mouse.y,firstCorner);
        drawRectangle;
        repeat
          oldMouse:=mouse;
          getMouse(mouse);
          if mousePositionChanged(oldMouse,mouse) then
            begin
              eraseRectangle;
              drawRectangle
            end
        until (mouse.leftButton or mouse.rightButton);
        editing:=false;
        if mouse.leftButton then
          begin
            makePoint(mouse.x,mouse.y,secondCorner);
            saveExtractedImage;
            break:=true
          end
        else if mouse.rightButton then
          eraseRectangle
      end
  until break;
  disposeCorners;
  outTextXY(1,ySize+100,'Press any key to exit....')
end;


procedure finishOff;

var   i                         : word;

begin
  readKey;
  closeGraph;
  for i:=1 to ySize do
    freeMem(image^[i],xSize);
  freeMem(image,4*ySize)
end;


begin
  init;
  mouseLoop;
  finishOff
end.