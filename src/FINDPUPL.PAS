program findPupilInPicture;

uses crt,dos,graph,auxil,math,SVGA;

const maxSize                   = 512;
      nGrayLevels               = 64;

      nLeapsMax                 = 10;

      north                     = -1;
      south                     = 1;
      east                      = 1;
      west                      = -1;

      asPoint                   = 0;
      asStar                    = 1;
      asCircle                  = 2;

type  bufferType                = array[1..maxSize] of byte;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

      mapType                   = array[0..nGrayLevels-1] of byte;
      wetType                   = array[0..nGrayLevels-1] of boolean;

      point                     = record
	x                         : word;
	y                         : word;
	visited                   : boolean
      end;

      pointArrayPtr             = ^pointArray;
      pointArray                = array[0..maxSize-1] of point;

      priAreasType              = array[1..3] of word;

const wetFraction               : real    = 0.8;

      lakeLevel                 : byte    = 1;
      minPupilRadiusFraction    : real    = 8;   (* Per cent *)
      filterRadiusFraction      : real    = 8;   (* Per cent *)

      nIterations               : word    = 1;
      showPoints                : boolean = false;

var   image                     : pixelMatrixPtr;

      map                       : mapType;
      wet                       : wetType;

      inSeaThreshold            : word;
      minPupilRadius            : word;
      filterRadius              : word;

      xSize                     : word;
      ySize                     : word;
      startX                    : word;
      startY                    : word;

      pupilPoint                : pointType;

      startingPoints            : pointArrayPtr;
      priAreas                  : priAreasType;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure getParameters(nParameters : word);

  var   i                         : byte;
	thisParameter             : string;


    function getParameterValue(parameterString : string) : word;

    var   value                     : word;
	  result                    : integer;

    begin
      val(copy(parameterString,3,length(parameterString)-2),value,result);
      if (result=0) then
	getParameterValue:=value
      else
	fatalError('Illegal parameter value, must be a number!')
    end;


  begin
    for i:=1 to nParameters-1 do
      begin
	thisParameter:=paramStr(i);
	if (thisParameter[1]='-') then
	  case thisParameter[2] of
	    'r' : filterRadiusFraction:=getParameterValue(thisParameter);
	    'l' : lakeLevel:=getParameterValue(thisParameter);
	    'n' : nIterations:=getParameterValue(thisParameter);
	    's' : showPoints:=true
	  else
	    fatalError('Illegal option: -'+thisParameter[2])
	  end
	else
	  fatalError('Cannot specify more than one file: '+thisParameter)
      end;
    fileName:=picturePath(paramStr(nParameters))
  end;


  procedure initVariables;

  var   i                         : byte;


    procedure initPointMatrix;

    var   xCenter                   : word;
	  yCenter                   : word;
	  xRadius                   : word;
	  yRadius                   : word;
	  nHorizontal               : word;
	  nVertical                 : word;
	  xStart                    : word;
	  yStart                    : word;
	  leftOffset                : word;
	  priArea1xRadius            : word;
	  priArea1yRadius            : word;
	  priArea2xRadius            : word;
	  priArea2yRadius            : word;
	  priCount                  : priAreasType;
	  pri                       : byte;
	  priOffset                 : word;
	  currentX                  : word;
	  currentY                  : word;
	  i,j                       : word;


      procedure initVariables;

      var   i                         : byte;


	function nPointsInRectangle(x,y : word) : word;

	begin
	  if even(trunc(x/2)+trunc(y/2)) then
	    nPointsInRectangle:=high(0.5*x*y)
	  else
	    nPointsInRectangle:=trunc(0.5*x*y)
	end;


      begin
	xCenter:=xSize div 2;
	yCenter:=ySize div 2;
	xRadius:=trunc((xCenter-minPupilRadius)/minPupilRadius);
	yRadius:=trunc((yCenter-minPupilRadius)/minPupilRadius);
	nHorizontal:=2*xRadius+1;
	nVertical:=2*yRadius+1;
	xStart:=xCenter-xRadius*minPupilRadius;
	yStart:=yCenter-yRadius*minPupilRadius;
	currentX:=xStart;
	currentY:=yStart;
	if ((even(xRadius) and even(yRadius)) or
	    (odd(xRadius)  and odd(yRadius) )) then
	  leftOffset:=0
	else
	  leftOffset:=minPupilRadius;
	priArea1xRadius:=xRadius div 3;
	priArea1yRadius:=yRadius div 3;
	priArea2xRadius:=trunc((2/3)*xRadius);
	priArea2yRadius:=trunc((2/3)*yRadius);
	priAreas[1]:=nPointsInRectangle(2*priArea1xRadius+1,2*priArea1yRadius+1);
	priAreas[2]:=nPointsInRectangle(2*priArea2xRadius+1,2*priArea2yRadius+1);
	priAreas[3]:=nPointsInRectangle(nHorizontal,nVertical);
	for i:=1 to 3 do
	  priCount[i]:=0;
	getMem(startingPoints,priAreas[3]*sizeOf(point));
      end;


      function getPriority(x,y : word) : byte;


	function inRectangle(x,y,rX,rY : word) : boolean;

	begin
	  inRectangle:=((x>=xCenter-rX*minPupilRadius) and
			(x<=xCenter+rX*minPupilRadius) and
			(y>=yCenter-rY*minPupilRadius) and
			(y<=yCenter+rY*minPupilRadius))
	end;


      begin
	if inRectangle(x,y,priArea1xRadius,priArea1yRadius) then
	  getPriority:=1
	else if inRectangle(x,y,priArea2xRadius,priArea2yRadius) then
	  getPriority:=2
	else
	  getPriority:=3
      end;


      function getPriOffset(i : byte) : word;

      begin
	case (i=1) of
	  true  : getPriOffset:=0;
	  false : getPriOffset:=priAreas[i-1]
	end
      end;


      procedure toggleLeftOffset;

      begin
	case (leftOffset=minPupilRadius) of
	  true  : leftOffset:=0;
	  false : leftOffset:=minPupilRadius
	end
      end;


    begin
      initVariables;
      repeat
	pri:=getPriority(currentX+leftOffset,currentY);
	priOffset:=getPriOffset(pri);
	startingPoints^[priOffset+priCount[pri]].x:=currentX+leftOffset;
	startingPoints^[priOffset+priCount[pri]].y:=currentY;
	startingPoints^[priOffset+priCount[pri]].visited:=false;
	inc(priCount[pri]);
	inc(currentX,2*minPupilRadius);
	if (currentX+leftOffset>xCenter+xRadius*minPupilRadius) then
	  begin
	    inc(currentY,minPupilRadius);
	    currentX:=xStart;
	    toggleLeftOffset
	  end
      until (currentY>yStart+2*yRadius*minPupilRadius)
    end;


  begin
    assign(inputFile,fileName);
    reset(inputFile,1);
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    startX:=round(getMaxX/2-xSize/2);
    startY:=round(getMaxY/2-ySize/2);
    minPupilRadius:=round(xSize*minPupilRadiusFraction/100);
    filterRadius:=round(xSize*filterRadiusFraction/100);
    inSeaThreshold:=round(4*wetFraction*pred(filterRadius))+2;
    initPointMatrix;
    for i:=0 to lakeLevel do
      begin
	map[i]:=lakeLevel;
	wet[i]:=true
      end;
    for i:=(lakeLevel+1) to (nGrayLevels-1) do
      begin
	map[i]:=i;
	wet[i]:=false
      end
  end;


begin
  if (paramCount<>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
	begin
	  randomize;
	  SVGA_initGraphics(mode640x480);
	  SVGA_setBlackAndWhitePalette;
	  initVariables;
	  getMem(image,4*ySize);
	  for i:=1 to ySize do
	    begin
	      blockRead(inputFile,buffer,xSize);
	      getMem(image^[i],xSize);
	      for j:=1 to xSize do
		begin
		  image^[i]^[j]:=buffer[j];
		  putPixel(startX+j-1,startY+i-1,buffer[j])
		end
	    end;
	  close(inputFile);
	  rectangle(startX,startY,startX+xSize,startY+ySize)
	end
      else
	fatalError('Image file not found: '+fileName)
    end
  else
    fatalError('Usage: findpupl [options] file[.pic]')
end;


procedure markPosition(x,y : word; asWhat : byte);

begin
  setColor(63);
  case asWhat of
    asPoint :
      putPixel(startX+x,startY+y,63);
    asStar :
      begin
	line(startX+x-filterRadius,startY+y,startX+x+filterRadius,startY+y);
	line(startX+x,startY+y-filterRadius,startX+x,startY+y+filterRadius)
      end;
    asCircle :
      circle(startX+x,startY+y,2)
  end
end;


procedure doFindPupil;

var   i                         : word;
      startHours                : word;
      startMinutes              : word;
      startSeconds              : word;
      start100thSeconds         : word;
      endHours                  : word;
      endMinutes                : word;
      endSeconds                : word;
      end100thSeconds           : word;


  function findPupil(var pupilPoint : pointType) : boolean;

  var   pupilFound                : boolean;
	priLevel                  : byte;
	nInvestigated             : word;
	startingPoint             : pointType;
	previousPos               : pointType;
	lastPos                   : pointType;
	seaPointer                : pointType;
	i                         : word;


    procedure getStartingPoint(var aPoint : pointType);

    var   i                         : word;

    begin
      repeat
	i:=random(priAreas[priLevel])
      until (not startingPoints^[i].visited);
      aPoint.x:=startingPoints^[i].x;
      aPoint.y:=startingPoints^[i].y;
      startingPoints^[i].visited:=true
    end;


    function octopusSwims(pos : pointType; depth : byte) : boolean;


      procedure locateSea(pos : pointType; var seaPointer : pointType);


	function feelNArm(offset : word) : word;

	begin
	  while ((not wet[image^[pos.y-offset]^[pos.x]]) and (offset>0)) do
	    offset:=offset-1;
	  feelNArm:=offset
	end;


	function feelSArm(offset : word) : word;

	begin
	  while ((not wet[image^[pos.y+offset]^[pos.x]]) and (offset>0)) do
	    offset:=offset-1;
	  feelSArm:=offset
	end;


	function feelEArm(offset : word) : word;

	begin
	  while ((not wet[image^[pos.y]^[pos.x+offset]]) and (offset>0)) do
	    offset:=offset-1;
	  feelEArm:=offset
	end;


	function feelWArm(offset : word) : word;

	begin
	  while ((not wet[image^[pos.y]^[pos.x-offset]]) and (offset>0)) do
	    offset:=offset-1;
	  feelWArm:=offset
	end;


      begin
	seaPointer.x:=feelEArm(filterRadius)-feelWArm(filterRadius);
	seaPointer.y:=feelSArm(filterRadius)-feelNArm(filterRadius)
      end;


      function octopusInSea(pos : pointType) : boolean;

      var   pixelsInSea               : word;
	    probablyInSea             : boolean;
	    i                         : integer;

      begin
	probablyInSea:=(wet[image^[pos.y]^[pos.x-filterRadius]] and
			wet[image^[pos.y-filterRadius]^[pos.x]]);
	if probablyInSea then
	  begin
	    pixelsInSea:=0;
	    for i:=-pred(filterRadius) to pred(filterRadius) do
	      begin
		if wet[image^[pos.y]^[pos.x+i]] then
		  pixelsInSea:=pixelsInSea+1;
		if wet[image^[pos.y+i]^[pos.x]] then
		  pixelsInSea:=pixelsInSea+1
	      end;
	    if (pixelsInSea>=inSeaThreshold) then
	      begin
		pupilPoint:=pos;
		octopusInSea:=true
	      end
	    else
	      octopusInSea:=false
	  end
	else
	  octopusInSea:=false
      end;


    begin
      previousPos:=lastPos;
      lastPos:=pos;
      locateSea(pos,seaPointer);
      if ((seaPointer.x=0) and (seaPointer.y=0)) then
	octopusSwims:=octopusInSea(pos)
      else
	begin
	  pos.x:=pos.x+seaPointer.x;
	  pos.y:=pos.y+seaPointer.y;
	  if (((pos.x=previousPos.x) and (pos.y=previousPos.y)) or
	      (depth>=nLeapsMax)) then
	    octopusSwims:=false
	  else
	    octopusSwims:=octopusSwims(pos,succ(depth))
	end
    end;


  begin
    pupilFound:=false;
    priLevel:=1;
    nInvestigated:=0;
    lastPos.x:=maxInt;
    lastPos.y:=maxInt;
    repeat
      repeat
	getStartingPoint(startingPoint);
	pupilFound:=octopusSwims(startingPoint,0);
	nInvestigated:=nInvestigated+1
      until (pupilFound or (nInvestigated=priAreas[priLevel]));
      priLevel:=priLevel+1
    until (pupilFound or (priLevel=4));
    for i:=0 to (priAreas[3]-1) do
      startingPoints^[i].visited:=false;
    findPupil:=pupilFound
  end;


  procedure writeData;


    function sec100ths : real;

    begin
      sec100ths:=(6000*(endMinutes     -startMinutes)+
		   100*(endSeconds     -startSeconds)+
		       (end100thSeconds-start100thSeconds))/
		 (nIterations/10)
    end;


  begin
    setTextStyle(defaultFont,horizDir,1);
    setTextJustify(leftText,centerText);
    setColor(60);
    outTextXY(startX,startY+ySize+30,'Position         : ('+
	      intString(pupilPoint.x)+','+intString(pupilPoint.y)+')');
    outTextXY(startX,startY+ySize+40,'Search time (ms) : '+
	      realString(sec100ths))
  end;


begin
  if findPupil(pupilPoint) then
    begin
      getTime(startHours,startMinutes,startSeconds,start100thSeconds);
      for i:=1 to nIterations do
	begin
	  findPupil(pupilPoint);
	  if showPoints then
	    markPosition(pupilPoint.x,pupilPoint.y,asStar)
	end;
      getTime(endHours,endMinutes,endSeconds,end100thSeconds);
      markPosition(pupilPoint.x,pupilPoint.y,asStar);
      writeData;
      freeMem(startingPoints,priAreas[3]*sizeOf(point))
    end
  else
    fatalError('No pupil was found!')
end;


procedure finishOff;

var   i                         : word;

begin
  readKey;
  closeGraph;
  for i:=1 to ySize do
    freeMem(image^[i],xSize);
  freeMem(image,4*ySize)
end;


begin
  init;
  doFindPupil;
  finishOff
end.