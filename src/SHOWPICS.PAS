program showPictures;

uses crt,graph,auxil,images,SVGA;

var   i                         : byte;
      eyeImage                  : imageOPtr;

begin
  if (paramCount>0) then
    begin
      initSVGAGraphics;
      setBlackAndWhitePalette;
      for i:=0 to paramCount-1 do
        begin
          new(eyeImage,initStoredImage(paramStr(i+1)));
          eyeImage^.setPixelSize(1);
          eyeImage^.drawImage(i mod 3,i div 3);
          dispose(eyeImage,done)
        end;
      readKey;
      closeGraph
    end
  else
    fatalError('Usage: showpics <file list (max 9 files)>')
end.