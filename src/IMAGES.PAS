unit images;


INTERFACE


const maxRowPixels              = 512;

      left                      = 0;
      center                    = 1;
      right                     = 2;
      top                       = 0;
      bottom                    = 2;

type  bufferType                = array[1..512] of byte;

      rowArrayPtr               = ^rowArray;
      rowArray                  = array[0..maxRowPixels-1] of byte;
      imagePtr                  = ^imageMatrix;
      imageMatrix               = array[0..maxRowPixels-1] of rowArrayPtr;

      maskArray                 = array[1..9] of shortInt;

      imageOPtr                 = ^imageO;
      imageO                    = object
        image                     : imagePtr;
        xSize                     : word;
        ySize                     : word;
        pixelSize                 : byte;
        constructor initStoredImage(whatImage : string);
        constructor initEmptyImage(xExtent,yExtent : word);
        destructor  done;
        function    readPixel(x,y : word)               : byte;
        function    applySpacialMask(aMask : maskArray) : imageOPtr;
        function    threshold(limit : byte)             : imageOPtr;
        procedure   addImage(anImage : imageOPtr);
        procedure   setPixelSize(aSize : byte);
        procedure   drawImage(whereVer,whereHor : byte; aText : string);
        procedure   saveImage(imageName : string);
        procedure   disposeImage;
      end;

const xSobelMask                : maskArray = (-1,-2,-1,
                                                0, 0, 0,
                                                1, 2, 1);

      ySobelMask                : maskArray = (-1, 0, 1,
                                               -2, 0, 2,
                                               -1, 0, 1);

      laPlaceMask               : maskArray = ( 0, 1, 0,
                                                1,-4, 1,
                                                0, 1, 0);


IMPLEMENTATION

uses crt,graph,auxil,math,SVGA;


(**************************************************************************
 *                                                                        *
 *    imageO's methods                                                    *
 *                                                                        *
 **************************************************************************)


constructor imageO.initStoredImage(whatImage : string);

var   imageFile                 : file;
      buffer                    : bufferType;
      sizeOfSizeInfo            : byte;
      sizeInfo                  : string;
      imageLine                 : string;
      i,j                       : word;


  function getXSize(sizeInfo : bufferType) : word;

  begin
    getXSize:=(word(sizeInfo[1]) shl 8)+sizeInfo[2]
  end;


  function getYSize(sizeInfo : bufferType) : word;

  begin
    getYSize:=(word(sizeInfo[3]) shl 8)+sizeInfo[4]
  end;


begin
  setTextStyle(defaultFont,horizDir,1);
  setTextJustify(leftText,topText);
  if fileExists(appendExtension(whatImage,'.pic')) then
    assign(imageFile,appendExtension(whatImage,'.pic'))
  else if fileExists(picturePath(whatImage)) then
    assign(imageFile,picturePath(whatImage))
  else
    begin
      closeGraph;
      fatalError(whatImage+': Image not found!')
    end;
  reset(imageFile,1);
  if (IOResult<>0) then
    image:=nil
  else
    begin
      sizeInfo:='';
      blockRead(imageFile,buffer,4);
      xSize:=getXSize(buffer);
      ySize:=getYSize(buffer);
      setPixelSize(1);
      getMem(image,4*ySize);
      for i:=0 to ySize-1 do
        begin
          getMem(image^[i],xSize);
          blockRead(imageFile,buffer,xSize);
          for j:=0 to xSize-1 do
            image^[i]^[j]:=buffer[succ(j)]
        end;
      close(imageFile)
    end
end;


constructor imageO.initEmptyImage(xExtent,yExtent : word);

var   i                         : word;

begin
  setTextStyle(defaultFont,horizDir,1);
  setTextJustify(leftText,topText);
  xSize:=xExtent;
  ySize:=yExtent;
  setPixelSize(1);
  if (ySize>0) then
    begin
      getMem(image,4*ySize);
      if (xSize>0) then
        for i:=0 to ySize-1 do
          getMem(image^[i],xSize)
    end
end;


destructor imageO.done;

begin
  disposeImage
end;


function imageO.readPixel(x,y : word) : byte;

var   arrayPosition             : word;

begin
  if ((x>=0) and (x<xSize) and (y>=0) and (y<ySize)) then
    readPixel:=image^[y]^[x]
  else
    readPixel:=0
end;


function imageO.applySpacialMask(aMask : maskArray) : imageOPtr;

var   temporaryImage            : imageOPtr;
      i,j                       : word;

begin
  new(temporaryImage,initEmptyImage(xSize,ySize));
  temporaryImage^.setPixelSize(pixelSize);
  for i:=0 to xSize-1 do
    begin
      temporaryImage^.image^[0]^[i]:=0;
      temporaryImage^.image^[ySize-1]^[i]:=0
    end;
  for i:=1 to ySize-2 do
    begin
      temporaryImage^.image^[i]^[0]:=0;
      temporaryImage^.image^[i]^[xSize-1]:=0;
      for j:=1 to xSize-2 do
        temporaryImage^.image^[i]^[j]:=abs(aMask[1]*image^[i-1]^[j-1]+
                                           aMask[2]*image^[i-1]^[j  ]+
                                           aMask[3]*image^[i-1]^[j+1]+
                                           aMask[4]*image^[i  ]^[j-1]+
                                           aMask[5]*image^[i  ]^[j  ]+
                                           aMask[6]*image^[i  ]^[j+1]+
                                           aMask[7]*image^[i+1]^[j-1]+
                                           aMask[8]*image^[i+1]^[j  ]+
                                           aMask[9]*image^[i+1]^[j+1])
    end;
  applySpacialMask:=temporaryImage
end;


function imageO.threshold(limit : byte) : imageOPtr;

var   temporaryImage            : imageOPtr;
      i,j                       : word;

begin
  new(temporaryImage,initEmptyImage(xsize,ySize));
  temporaryImage^.setPixelSize(pixelSize);
  for i:=0 to ySize-1 do
    for j:=0 to xSize-1 do
      if (image^[i]^[j]>=limit) then
        temporaryImage^.image^[i]^[j]:=62
      else
        temporaryImage^.image^[i]^[j]:=0;
  threshold:=temporaryImage
end;


procedure imageO.addImage(anImage : imageOPtr);

var   i,j                       : word;


  function conform(aGrayLevel : word) : byte;

  begin
    aGrayLevel:=abs(aGrayLevel);
    if (aGrayLevel>63) then
      conform:=63
    else
      conform:=aGrayLevel
  end;


begin
  for i:=0 to ySize-1 do
    for j:=0 to xSize-1 do
      image^[i]^[j]:=conform(image^[i]^[j]+anImage^.image^[i]^[j])
end;


procedure imageO.setPixelSize(aSize : byte);

begin
  pixelSize:=aSize
end;


procedure imageO.drawImage(whereVer,whereHor : byte; aText : string);

var   x,y                       : word;
      i,j                       : word;


  function xPosition(where : byte) : word;

  begin
    case where of
      left   : xPosition:=1;
      center : xPosition:=(getMaxX div 2)-(xSize div 2)*pixelSize;
      right  : xPosition:=getMaxX-xSize*pixelSize
    end
  end;


  function yPosition(where : byte) : word;

  begin
    case where of
      top    : yPosition:=1;
      center : yPosition:=(getMaxY div 2)-(ySize div 2)*pixelSize-10;
      bottom : yPosition:=getMaxY-ySize*pixelSize-20
    end
  end;


  procedure drawPixel(relX,relY : word; grayLevel : byte);

  var   offset                    : byte;

  begin
    setColor(grayLevel);
    for offset:=0 to pixelSize-1 do
      line(x+relX*pixelSize,y+relY*pixelSize+offset,
           x+relX*pixelSize+pixelSize,y+relY*pixelSize+offset)
  end;


begin
  x:=xPosition(whereHor);
  y:=yPosition(whereVer);
  for i:=0 to ySize-1 do
    for j:=0 to xSize-1 do
      if (pixelSize=1) then
        putPixel(x+j,y+i,image^[i]^[j])
      else
        drawPixel(j,i,image^[i]^[j]);
  outTextXY(x,y+ySize+10,aText)
end;


procedure imageO.saveImage(imageName : string);

var   imageFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


begin
  assign(imageFile,picturePath(imageName));
  rewrite(imageFile,1);
  buffer[1]:=hi(xSize);
  buffer[2]:=lo(xSize);
  buffer[3]:=hi(ySize);
  buffer[4]:=lo(ySize);
  blockWrite(imageFile,buffer,4);
  for i:=0 to ySize-1 do
    begin
      for j:=0 to xSize-1 do
        buffer[succ(j)]:=image^[i]^[j];
      blockWrite(imageFile,buffer,xSize)
    end;
  close(imageFile);
end;


procedure imageO.disposeImage;

var   i                         : word;

begin
  for i:=0 to ySize-1 do
    freeMem(image^[i],xSize);
  freeMem(image,4*ySize)
end;


end.