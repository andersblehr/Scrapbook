(*
 * Theoretical basis for this program is Section 4.2.2, pages 146-151, of
 * Gonzales, R.C. & Wintz, P.; Digital Image Processing, Addison-Wesley 1987.
 *)


program histogramEqualization;

uses crt,graph,paths,auxil,SVGA;

const maxSize                   = 512;
      grayLevels                = 64;

type  bufferType                = array[1..maxSize] of byte;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

      distributionArrayType     = array[0..grayLevels-1] of word;

var   originalImage             : pixelMatrixPtr;
      distribution              : distributionArrayType;
      mapping                   : distributionArrayType;

      xSize                     : word;
      ySize                     : word;
      numberOfPixels            : longInt;

      mostFrequent              : word;
      yPositionOfGraph          : word;


procedure drawDistribution(xPositionOfGraph : word);

var   lengthOf1stAxis           : word;
      lengthOf2ndAxis           : word;
      unit1stAxis               : real;
      unit2ndAxis               : real;
      spacing1stAxis            : real;
      spacing2ndAxis            : real;


  procedure initVariables;

  begin
    lengthOf1stAxis:=(getMaxX div 2)-20;
    lengthOf2ndAxis:=150;
    unit1stAxis:=lengthOf1stAxis/64;
    unit2ndAxis:=lengthOf2ndAxis/(mostFrequent/numberOfPixels);
    spacing1stAxis:=5*unit1stAxis;
    spacing2ndAxis:=unit2ndAxis/(5*numberOfPixels/mostFrequent)
  end;


  procedure drawCoordinateSystem;

  var   oldLineSettings           : lineSettingsType;
	i                         : byte;

  begin
    line(xPositionOfGraph,yPositionOfGraph,
	 xPositionOfGraph+lengthOf1stAxis,yPositionOfGraph);
    for i:=0 to 12 do
      line(xPositionOfGraph+trunc(i*spacing1stAxis),yPositionOfGraph,
	   xPositionOfGraph+trunc(i*spacing1stAxis),yPositionOfGraph+3);
    getLineSettings(oldLineSettings);
    setLineStyle(dottedLn,oldLineSettings.pattern,oldLineSettings.thickness);
    for i:=1 to 5 do
      line(xPositionOfGraph,yPositionOfGraph-trunc(i*spacing2ndAxis),
	   xPositionOfGraph+lengthOf1stAxis,
	   yPositionOfGraph-trunc(i*spacing2ndAxis));
    setLineStyle(oldLineSettings.lineStyle,oldLineSettings.pattern,
		 oldLineSettings.thickness);
  end;


  procedure drawHistogram;

  var   i                         : byte;


    function normalize(aNumber : word) : real;

    begin
      normalize:=aNumber/numberOfPixels
    end;


  begin
    for i:=0 to 63 do
      line(xPositionOfGraph+trunc(i*unit1stAxis),yPositionOfGraph,
	   xPositionOfGraph+trunc(i*unit1stAxis),
	   yPositionOfGraph-trunc(normalize(distribution[i])*unit2ndAxis))
  end;


begin
  initVariables;
  drawCoordinateSystem;
  drawHistogram
end;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure initVariables;

  var   i                         : byte;

  begin
    setColor(60);
    setTextStyle(defaultFont,HorizDir,1);
    setTextJustify(leftText,bottomText);
    assign(inputFile,fileName);
    reset(inputFile,1);
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    numberOfPixels:=longInt(xSize-1)*longInt(ySize);
    yPositionOfGraph:=ySize+170;
    for i:=0 to grayLevels-1 do
      distribution[i]:=0;
  end;


begin
  if (paramCount=1) then
    begin
      fileName:=picturePath(paramStr(1));
      if fileExists(fileName) then
	begin
	  SVGA_initGraphics(mode800x600);
	  AVGA_setBlackAndWhitePalette;
	  initVariables;
	  getMem(originalImage,4*ySize);
	  for i:=1 to ySize do
	    begin
	      blockRead(inputFile,buffer,xSize);
	      getMem(originalImage^[i],xSize-1); (* Last pixel always 0 *)
	      for j:=1 to xSize-1 do
		begin
		  originalImage^[i]^[j]:=buffer[j];
		  putPixel(j,i,buffer[j]);
		  inc(distribution[buffer[j]])
		end
	    end;
	  close(inputFile);
	  mostFrequent:=0;
	  for i:=0 to 63 do
	    if (distribution[i]>mostFrequent) then
	      mostFrequent:=distribution[i];
	  drawDistribution(1);
	  outTextXY(1,ySize+210,'Original image');
	  outTextXY(1,ySize+220,'File: '+fileName)
	end
      else
	fatalError('Image file not found: '+picturePath(fileName))
    end
  else
    fatalError('Usage: histeq file[.pic]')
end;


procedure main;

var   startX                    : word;


  procedure equalizeDistribution;

  var   probabilitySum            : real;
	i                         : byte;

  begin
    probabilitySum:=0;
    for i:=0 to grayLevels-1 do
      begin
	probabilitySum:=probabilitySum+distribution[i]/numberOfPixels;
	distribution[i]:=0;
	mapping[i]:=trunc(probabilitySum*grayLevels)
      end
  end;


  procedure drawEqualizedImage;

  var   x,y                       : word;
	i                         : byte;

  begin
    for y:=1 to ySize do
      for x:=1 to xSize do
	begin
	  putPixel(startX+x,y,mapping[originalImage^[y]^[x]]);
	  inc(distribution[mapping[originalImage^[y]^[x]]])
	end;
    mostFrequent:=0;
    for i:=0 to 63 do
      if (distribution[i]>mostFrequent) then
	mostFrequent:=distribution[i];
    drawDistribution(startX);
    outTextXY(startX,ySize+210,'Histogram equalized image');
  end;


  procedure saveEqualizedImage;

  var   fileName                  : string;
	break                     : boolean;


    procedure saveImageInFile(fileName : string);

    var   infoText                  : string;
	  imageFile                 : file;
	  buffer                    : bufferType;
	  i,j                       : word;

    begin
      infoText:='Saving transformed image in file '+
		picturePath(fileName)+'.... ';
      outTextXY(1,ySize+270,infoText);
      assign(imageFile,picturePath(fileName));
      rewrite(imageFile,1);
      buffer[1]:=hi(xSize);
      buffer[2]:=lo(xSize);
      buffer[3]:=hi(ySize);
      buffer[4]:=lo(ySize);
      blockWrite(imageFile,buffer,4);
      for i:=1 to ySize do
	begin
	  for j:=1 to xSize do
	    buffer[j]:=mapping[originalImage^[i]^[j]];
	  blockWrite(imageFile,buffer,xSize)
	end;
      close(imageFile);
      outTextXY(textWidth(infoText),ySize+270,'done.')
    end;


  begin
    if grConfirm(1,ySize+240,'Do you want to save the transformed image') then
      begin
	repeat
	  grClear(1,ySize+250,getMaxX,ySize+250-textHeight(' '));
	  fileName:=grGetReply(1,ySize+250,'File name');
	  break:=(((legalFileName(fileName) and
		   (not fileExists(picturePath(fileName)))) or
		  (fileName='')));
	  if (not break) then
	    beep(1000,300)
	until break;
	if (fileName<>'') then
	  saveImageInFile(fileName)
      end
  end;


begin
  startX:=getMaxX div 2;
  equalizeDistribution;
  drawEqualizedImage;
  saveEqualizedImage;
  outTextXY(1,ySize+290,'Press any key to exit....')
end;


procedure finishOff;

var   i                         : word;

begin
  readKey;
  closeGraph;
  for i:=1 to ySize do
    freeMem(originalImage^[i],xSize);
  freeMem(originalImage,4*ySize)
end;


begin
  init;
  main;
  finishOff
end.