unit images;


INTERFACE


const maxRowPixels              = 512;

      left                      = 0;
      center                    = 1;
      right                     = 2;
      top                       = 0;
      bottom                    = 2;

type  bufferType                = array[1..512] of char;

      rowArrayPtr               = ^rowArray;
      rowArray                  = array[0..maxRowPixels-1] of byte;
      imagePtr                  = ^imageMatrix;
      imageMatrix               = array[0..maxRowPixels-1] of rowArrayPtr;

      bitInversionArrayPtr      = ^bitInversionArray;
      bitInversionArray         = array[0..maxRowPixels-1] of word;

      transformationLinePtr     = ^transformationLine;
      transformationLine        = array[0..maxRowPixels-1] of single;
      transformationMatrixPtr   = ^transformationMatrix;
      transformationMatrix      = array[0..maxRowpixels-1] of transformationLinePtr;
      transformationFloodPtr    = ^transformationFlood;
      transformationFlood       = array[1..16] of transformationMatrixPtr;

      maskArray                 = array[1..9] of real;

      FFTransformerOPtr         = ^FFTransformerO;
      FFTransformerO            = object
        extent                    : word;
        numberOfBits              : byte;
        bitInverter               : bitInversionArrayPtr;
        transformationFlood       : transformationFloodPtr;
        constructor init(theExtent : word);
        destructor  done;
        function    FFTLine(aLine : rowArrayPtr) : rowArrayPtr;
      end;

      imageOPtr                 = ^imageO;
      imageO                    = object
        image                     : imagePtr;
        xSize                     : word;
        ySize                     : word;
        pixelSize                 : byte;
        FFTInitiated              : boolean;
        FFTransformer             : FFTransformerOPtr;
        constructor initStoredImage(whatImage : string);
        constructor initEmptyImage(xExtent,yExtent : word);
        destructor  done;
        function    readPixel(x,y : word)               : byte;
        function    FFT                                 : imageOPtr;
        function    applySpacialMask(aMask : maskArray) : imageOPtr;
        function    threshold(limit : byte)             : imageOPtr;
        procedure   prepareFFT;
        procedure   addImage(anImage : imageOPtr);
        procedure   setPixelSize(aSize : byte);
        procedure   drawImage(whereVer,whereHor : byte; aText : string);
        procedure   saveImage(imageName : string);
        procedure   disposeImage;
      end;

const nullMask                  : maskArray = ( 0, 0, 0,
                                                0, 1, 0,
                                                0, 0, 0);

      xSobelMask                : maskArray = (-1,-2,-1,
                                                0, 0, 0,
                                                1, 2, 1);

      ySobelMask                : maskArray = (-1, 0, 1,
                                               -2, 0, 2,
                                               -1, 0, 1);

      laPlaceMask               : maskArray = ( 0, 1, 0,
                                                1,-4, 1,
                                                0, 1, 0);

      averageMask               : maskArray = (-0.11,-0.11,-0.11,
                                               -0.11, 1   ,-0.11,
                                               -0.11,-0.11,-0.11);


IMPLEMENTATION

uses crt,graph,defs,auxil,math,SVGA;


(**************************************************************************
 *                                                                        *
 *    Auxiliary procedures and functions                                  *
 *                                                                        *
 **************************************************************************)


procedure criticalError(errorMessage : string);

begin
  clrScr;
  writeLn('IMAGES ERROR: ',errorMessage);
  sound(440);
  delay(100);
  noSound;
  halt(0)
end;


(**************************************************************************
 *                                                                        *
 *    FFTransformerO's methods                                            *
 *                                                                        *
 **************************************************************************)


constructor FFTransformerO.init(theExtent : word);

var   i,j                       : word;
      xSize                     : word;
      ySize                     : word;

begin
  if potenceOf2(theExtent) then
    begin
      extent:=theExtent;
      numberOfBits:=intLog2(extent);
      getMem(transformationFlood,4*numberOfBits);
      for i:=1 to numberOfBits do
        begin
          ySize:=intExp2(i);
          xSize:=extent div ySize;
          getMem(transformationFlood^[i],4*xSize);
          for j:=0 to xSize-1 do
            getMem(transformationFlood^[i]^[j],4*ySize)
        end;
      getMem(bitInverter,2*extent);
      for i:=1 to extent do
        bitInverter^[i]:=succ(invertBits(pred(i),numberOfBits))
    end
  else
    criticalError('Image cannot be FFT''ed!')
end;


destructor FFTransformerO.done;

var   i,j                       : word;
      xSize                     : word;
      ySize                     : word;

begin
  freeMem(bitInverter,2*extent);
  for i:=1 to numberOfBits do
    begin
      ySize:=intExp2(i);
      xSize:=extent div ySize;
      for j:=0 to xSize-1 do
        freeMem(transformationFlood^[i]^[j],4*ySize);
      freeMem(transformationFlood^[i],4*xSize)
    end
end;


function FFTransformerO.FFTLine(aLine : rowArrayPtr) : rowArrayPtr;

var   n                         : word;

begin
  n:=2;

end;


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
    getXSize:=(word(ord(sizeInfo[1])) shl 8)+ord(sizeInfo[2])
  end;


  function getYSize(sizeInfo : bufferType) : word;

  begin
    getYSize:=(word(ord(sizeInfo[3])) shl 8)+ord(sizeInfo[4])
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
      FFTInitiated:=false;
      FFTransformer:=nil;
      getMem(image,4*ySize);
      for i:=0 to ySize-1 do
        begin
          getMem(image^[i],xSize);
          blockRead(imageFile,buffer,xSize);
          for j:=0 to xSize-1 do
            image^[i]^[j]:=ord(buffer[succ(j)])
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
  FFTInitiated:=false;
  FFTransformer:=nil;
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
  disposeImage;
  if FFTInitiated then
    dispose(FFTransformer,done)
end;


function imageO.readPixel(x,y : word) : byte;

var   arrayPosition             : word;

begin
  if ((x>=0) and (x<xSize) and (y>=0) and (y<ySize)) then
    readPixel:=image^[y]^[x]
  else
    readPixel:=0
end;


function imageO.FFT : imageOPtr;

var   temporaryImage            : imageOPtr;
      i                         : word;

begin
  if FFTInitiated then
    begin
      new(temporaryImage,initEmptyImage(ySize,0));
      for i:=0 to ySize-1 do
        temporaryImage^.image^[i]:=FFTransformer^.FFTLine(image^[i]);
      FFT:=temporaryImage
    end
  else
    criticalError('FFT not initialized!')
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
        temporaryImage^.image^[i]^[j]:=
            abs(round(aMask[1]*image^[i-1]^[j-1]+
                      aMask[2]*image^[i-1]^[j]+
                      aMask[3]*image^[i-1]^[j+1]+
                      aMask[4]*image^[i]^[j-1]+
                      aMask[5]*image^[i]^[j]+
                      aMask[6]*image^[i]^[j+1]+
                      aMask[7]*image^[i+1]^[j-1]+
                      aMask[8]*image^[i+1]^[j]+
                      aMask[9]*image^[i+1]^[j+1]))
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


procedure imageO.prepareFFT;

begin
  new(FFTransformer,init(xSize));
  FFTInitiated:=true
end;


procedure imageO.addImage(anImage : imageOPtr);

var   i,j                       : word;


  function conform(aGrayLevel : word) : byte;

  begin
    aGrayLevel:=abs(aGrayLevel);
    if (aGrayLevel>31) then
      conform:=31
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
  assign(imageFile,'c:\user\blehr\diplom\bilder\'+imageName+'.pic');
  rewrite(imageFile,1);
  buffer[1]:=chr(hi(xSize));
  buffer[2]:=chr(lo(xSize));
  buffer[3]:=chr(hi(ySize));
  buffer[4]:=chr(lo(ySize));
  blockWrite(imageFile,buffer,4);
  for i:=0 to ySize-1 do
    begin
      for j:=0 to xSize-1 do
        buffer[succ(j)]:=chr(image^[i]^[j]);
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