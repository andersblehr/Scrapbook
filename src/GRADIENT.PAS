program gradient;

uses crt,graph,auxil,images,SVGA;

var   image                     : imageOPtr;
      xSobelImage               : imageOPtr;
      ySobelImage               : imageOPtr;

begin
  if (paramCount=1) then
    begin
      SVGA_initGraphics(mode800x600);
      SVGA_setBlackAndWhitePalette;
      new(image,initStoredImage(paramStr(1)));
      image^.drawImage(top,left,'Original image');
      xSobelImage:=image^.applySpacialMask(xSobelMask);
      xSobelImage^.drawImage(top,center,'After applying the x-Sobel mask');
      ySobelImage:=image^.applySpacialMask(ySobelMask);
      ySobelImage^.drawImage(center,left,'After applying the y-Sobel mask');
      dispose(image,done);
      xSobelImage^.addImage(ySobelImage);
      xSobelImage^.drawImage(center,center,'Combinated gradient image');
      xSobelimage^.saveImage('gradient');
      dispose(xSobelImage);
      dispose(ySobelImage);
      readKey;
      closeGraph
    end
  else
    fatalError('Usage: gradient <file name>')
end.