program eyePos;

uses crt,dos,graph,auxil,search,SVGA;

var   xSize                     : word;
      ySize                     : word;
      startX                    : word;
      startY                    : word;

      startHours                : word;
      startMinutes              : word;
      startSeconds              : word;
      start100thSeconds         : word;
      endHours                  : word;
      endMinutes                : word;
      endSeconds                : word;
      end100thSeconds           : word;


procedure markPosition(x,y : word);

begin
  setColor(63);
  line(startX+x-3,startY+y,startX+x+3,startY+y);
  line(startX+x,startY+y-3,startX+x,startY+y+3)
end;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure getParameters(numberOfParameters : word);

  var   i                         : byte;
	thisParameter             : string;


    function getParameterValue(parameterString : string) : byte;

    var   value                     : byte;
	  result                    : integer;

    begin
      val(copy(parameterString,3,length(parameterString)-2),value,result);
      if (result=0) then
	getParameterValue:=value
      else
	fatalError('Illegal parameter value, must be a number!')
    end;


  begin
    for i:=1 to numberOfParameters-1 do
      begin
	thisParameter:=paramStr(i);
	if (thisParameter[1]='-') then
	  case thisParameter[2] of
	    'r' : filterRadius:=getParameterValue(thisParameter);
	    't' : filterThreshold:=getParameterValue(thisParameter);
	    's' : sobelThreshold:=getParameterValue(thisParameter)
	  else
	    fatalError('Illegal option: -'+thisParameter[2])
	  end
	else
	  fatalError('Cannot specify more than one file: '+thisParameter)
      end;
    fileName:=picturePath(paramStr(numberOfParameters))
  end;


  procedure initVariables;

  begin
    assign(inputFile,fileName);
    reset(inputFile,1);
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    startX:=round(getMaxX/2-xSize/2);
    startY:=round(getMaxY/2-ySize/2);
    initGlobals(xSize,ySize)
  end;


begin
  if (paramCount<>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
	begin
	  initSVGAGraphics;
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
	  close(inputFile)
	end
      else
	fatalError('Image file not found: '+picturePath(fileName))
    end
  else
    fatalError('Usage: eyepos [-r<radius>][-t<threshold>][-s<threshold>] file[.pic]')
end;


procedure findPupilPosition;

var   i                         : byte;

begin
  getTime(startHours,startMinutes,startSeconds,start100thSeconds);
  for i:=1 to numberOfIterations do
    begin
      aPupilPoint:=findPupilPoint;
      if (aPupilPoint<>nil) then
	pupilPosition:=findPosition(aPupilPoint)
      else
	begin
	  closeGraph;
	  writeLn('No pupil was found!');
	  halt(1)
	end
    end;
  getTime(endHours,endMinutes,endSeconds,end100thSeconds);
  markPosition(pupilPosition^.x,pupilPosition^.y)
end;


procedure writeData;


  function sec100ths : real;

  begin
    sec100ths:=(6000*(endMinutes     -startMinutes)+
		 100*(endSeconds     -startSeconds)+
		     (end100thSeconds-start100thSeconds))/
	       (numberOfIterations/10)
  end;


begin
  setTextStyle(defaultFont,horizDir,1);
  setTextJustify(leftText,centerText);
  setColor(60);
  outTextXY(startX,startY+ySize+30,'Position  : ('+
	    intString(pupilPosition^.x)+','+intString(pupilPosition^.y)+')');
  outTextXY(startX,startY+ySize+40,'Time (ms) : '+realString(sec100ths))
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
  findPupilPosition;
  writeData;
  finishOff
end.