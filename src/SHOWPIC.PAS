program showPicture;

uses  crt,graph,auxil,defs,images,SVGA;

var   eyeImage                  : imageOPtr;

begin
  if (paramCount>0) then
    begin
      initSVGAGraphics;
      setBlackAndWhitePalette;
      new(eyeImage,initStoredImage(paramStr(1)));
      eyeImage^.setPixelSize(1);
      eyeImage^.drawImage(center,center);
      readKey;
      dispose(eyeImage,done);
      closeGraph
    end
  else
    fatalError('Usage: showpic <file name (no extension)>')
end.