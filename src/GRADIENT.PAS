program gradient;

uses crt,graph,auxil,images,SVGA;

var   eyeImage                  : imageOPtr;
      xSobelImage               : imageOPtr;
      ySobelImage               : imageOPtr;
      laPlaceImage              : imageOPtr;

begin
  if (paramCount=1) then
    begin
      initSVGAGraphics;
      setBlackAndWhitePalette;
      new(eyeImage,initStoredImage(paramStr(1)));
      eyeImage^.drawImage(top,left,'Original image');
      laPlaceImage:=eyeImage^.applySpacialMask(laPlaceMask);
      laPlaceImage^.drawImage(top,right,'After applying the LaPlace mask');
      dispose(laPlaceImage,done);
      xSobelImage:=eyeImage^.applySpacialMask(xSobelMask);
      xSobelImage^.drawImage(bottom,left,'After applying the x-gradient mask');
      dispose(xSobelImage,done);
      ySobelImage:=eyeImage^.applySpacialMask(ySObelMask);
      ySobelImage^.drawImage(bottom,right,'After applying the y-gradient mask');
      dispose(ySobelImage,done);
      dispose(eyeImage,done);
      readKey;
      closeGraph
    end
  else
    fatalError('Usage: gradient <file name>')
end.