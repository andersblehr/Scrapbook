program showEye;

uses  crt,graph,images,SVGA;

var   eyeImage                  : imageOPtr;

begin
  initSVGAGraphics;
  setBlackAndWhitePalette;
  new(eyeImage,initStoredImage('eye'));
  eyeImage^.setPixelSize(2);
  eyeImage^.drawImage(center,center);
  readKey;
  dispose(eyeImage,done);
  closeGraph
end.