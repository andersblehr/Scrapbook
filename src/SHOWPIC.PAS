program showPicture;

uses  crt,graph,auxil,images,SVGA;

var   eyeImage                  : imageOPtr;

begin
  if (paramCount>0) then
    begin
      SVGA_initGraphics(mode800x600);
      SVGA_setBlackAndWhitePalette;
      new(eyeImage,initStoredImage(paramStr(1)));
      eyeImage^.setPixelSize(1);
      eyeImage^.drawImage(center,center,paramStr(1));
      readKey;
      dispose(eyeImage,done);
      closeGraph
    end
  else
    fatalError('Usage: showpic <file name (no extension)>')
end.