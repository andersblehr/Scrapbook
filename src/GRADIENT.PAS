program gradient;

uses crt,graph,auxil,images,SVGA;

var   image                     : imageOPtr;
      nextImage                 : imageOPtr;

begin
  if (paramCount=1) then
    begin
      initSVGAGraphics;
      setBlackAndWhitePalette;
      new(image,initStoredImage(paramStr(1)));
      nextImage:=image^.applySpacialMask(xSobelMask);
      nextImage^.drawImage(top,left,'After applying the x-Sobel mask');
      dispose(nextImage,done);
      nextImage:=image^.applySpacialMask(ySobelMask);
      nextImage^.drawImage(top,right,'After applying the y-Sobel mask');
      dispose(nextImage,done);
      nextImage:=image^.applySpacialMask(xySobelMask);
      nextImage^.drawImage(bottom,left,'After applying the xy-Sobel mask');
      dispose(nextImage,done);
      nextImage:=image^.applySpacialMask(yxSobelMask);
      nextImage^.drawImage(bottom,right,'After applying the rotated xy-Sobel mask');
      dispose(nextImage,done);
      dispose(image,done);
      readKey;
      closeGraph
    end
  else
    fatalError('Usage: gradient <file name>')
end.