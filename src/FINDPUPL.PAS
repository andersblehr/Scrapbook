program findPupilInPicture;

uses crt,dos,graph,auxil,search,SVGA;

const showPoints                : boolean = false;  { -p option }

var   pupilPoint                : pointType;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure getParameters(nParameters : word);

  var   i                         : byte;
	thisParameter             : string;


    function getParameterValue(parameterString : string) : real;

    var   value                     : real;
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
	    'o' : octopusRadiusFraction:=getParameterValue(thisParameter);
	    'l' : lakeLevel:=trunc(getParameterValue(thisParameter));
	    'n' : nIterations:=trunc(getParameterValue(thisParameter));
	    'p' : showPoints:=true;
            'w' : wetFraction:=getParameterValue(thisParameter);
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

  begin
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    startX:=round(getMaxX/2-xSize/2);
    startY:=round(getMaxY/2-ySize/2);
    initGlobals
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
          assign(inputFile,fileName);
          reset(inputFile,1);
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
    fatalError('Usage: findpupl [-lnosw] file[.pic]')
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
  if findPupilPoint(pupilPoint) then
    begin
      getTime(startHours,startMinutes,startSeconds,start100thSeconds);
      for i:=1 to nIterations do
	begin
	  findPupilPoint(pupilPoint);
	  if showPoints then
	    markPosition(pupilPoint.x,pupilPoint.y,asStar)
	end;
      getTime(endHours,endMinutes,endSeconds,end100thSeconds);
      markPosition(pupilPoint.x,pupilPoint.y,asStar);
      writeData
    end
  else
    fatalError('No pupil was found!')
end;


procedure finishOff;

var   i                         : word;

begin
  readKey;
  closeSearch;
  closeGraph
end;


begin
  init;
  doFindPupil;
  finishOff
end.