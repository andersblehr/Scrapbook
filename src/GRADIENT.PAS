program gradient;

uses crt,graph,images,SVGA;

var   eyeImage                  : imageOPtr;
      xSobelImage               : imageOPtr;
      ySobelImage               : imageOPtr;
      laPlaceImage              : imageOPtr;

begin
  initSVGAGraphics;
  setBlackAndWhitePalette;
  new(eyeImage,initStoredImage('eye'));
  eyeImage^.drawImage(top,left);
  laPlaceImage:=eyeImage^.applySpacialMask(laPlaceMask);
  laPlaceImage^.drawImage(top,right);
  dispose(laPlaceImage,done);
  xSobelImage:=eyeImage^.applySpacialMask(xSobelMask);
  xSobelImage^.drawImage(bottom,left);
  dispose(xSobelImage,done);
  ySobelImage:=eyeImage^.applySpacialMask(ySObelMask);
  ySobelImage^.drawImage(bottom,right);
  dispose(ySobelImage,done);
  dispose(eyeImage,done);
  readKey;
  closeGraph
end.