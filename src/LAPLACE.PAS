program gradient;

uses crt,graph,auxil,images,SVGA;

var   image                     : imageOPtr;
      laPlaceImage              : imageOPtr;

begin
  if (paramCount=1) then
    begin
      SVGA_initGraphics(mode800x600);
      SVGA_setBlackAndWhitePalette;
      new(image,initStoredImage(paramStr(1)));
      image^.drawImage(top,left,'Original image');
      laPlaceImage:=image^.applySpacialMask(laPlaceMask);
      laPlaceImage^.drawImage(top,center,'After applying the Laplacian');
      laPlaceImage^.saveImage('laplace');
      dispose(image,done);
      dispose(laPlaceImage);
      readKey;
      closeGraph
    end
  else
    fatalError('Usage: laplace <file name>')
end.