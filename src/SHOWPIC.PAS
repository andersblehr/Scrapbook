program showEye;

uses  crt,graph,auxil,defs,images,SVGA;

var   eyeImage                  : imageOPtr;

begin
  if (paramCount>0) then
    if fileExists(picturePath(paramStr(1))) then
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
      fatalError('picture file not found: '+picturePath(paramStr(1)))
  else
    fatalError('Usage: showeye <file name (no extension)>')
end.