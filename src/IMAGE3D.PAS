program image3D;

uses crt,graph,auxil,math,graph3D,SVGA;

const maxSize                   = 512;
      numberOfGrayLevels        = 63;

      east                      = 2;
      west                      = -2;
      north                     = 1;
      south                     = -1;

type  bufferType                = array[1..maxSize] of byte;

      pixelLinePtr              = ^pixelLine;
      pixelLine                 = array[1..maxSize] of byte;
      pixelMatrixPtr            = ^pixelMatrix;
      pixelMatrix               = array[1..maxSize] of pixelLinePtr;

      mapType                   = array[0..numberOfGrayLevels] of byte;

const lakeLevel                 : byte     = 1;
      horizontalAngle           : integer  = 25;
      verticalAngle             : integer  = 25;
      zScaling                  : real     = 1;
      viewPoint                 : shortInt = south;
      showAxis                  : boolean  = false;

var   xSize                     : word;
      ySize                     : word;

      image                     : pixelMatrixPtr;
      map                       : mapType;

      viewPointHalfPlane        : shortInt;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
      buffer                    : bufferType;
      i,j                       : word;


  procedure getParameters(numberOfParameters : word);

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
    for i:=1 to numberOfParameters-1 do
      begin
	thisParameter:=paramStr(i);
	if (thisParameter[1]='-') then
	  case thisParameter[2] of
	    'l' : lakeLevel:=trunc(getParameterValue(thisParameter));
	    'h' : horizontalAngle:=trunc(getParameterValue(thisParameter));
	    'v' : verticalAngle:=trunc(getParameterValue(thisParameter));
	    'z' : zScaling:=getParameterValue(thisParameter);
	    'n' : viewPoint:=north;
	    'e' : viewPoint:=east;
	    's' : viewPoint:=south;
	    'w' : viewPoint:=west;
	    'a' : showAxis:=true
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
    case viewPoint of
      south :
	begin
	  viewPointHalfPlane:=south;
	  inc(horizontalAngle,90)
	end;
      east :
	begin
	  case sign(horizontalAngle) of
	    positive : viewPointHalfPlane:=north;
	    negative : viewPointHalfPlane:=south
	  end;
	  inc(horizontalAngle,180)
	end;
      north :
	begin
	  viewPointHalfPlane:=north;
	  inc(horizontalAngle,270)
	end;
      west :
	case sign(horizontalAngle) of
	  positive : viewPointHalfPlane:=south;
	  negative : viewPointHalfPlane:=north
	end
    end
  end;


begin
  if (paramCount<>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
	begin
	  SVGA_initGraphics(mode1024x768);
	  setBkColor(lightGray);
	  setColor(darkGray);
	  grClear(1,1,getMaxX,getMaxY);
	  initVariables;
	  if showAxis then
	    gr3D_drawCoordSystem(0,xSize,0,ySize,0,numberOfGrayLevels,
				 zScaling,horizontalAngle,verticalAngle)
	  else
	    gr3D_initCoordSystem(0,xSize,0,ySize,
				 zScaling,horizontalAngle,verticalAngle);
	  getMem(image,4*ySize);
	  for i:=1 to ySize do
	    begin
	      blockRead(inputFile,buffer,xSize);
	      getMem(image^[i],xSize);
	      for j:=1 to xSize do
		image^[i]^[j]:=buffer[j]
	    end;
	  close(inputFile);
	  for i:=0 to lakeLevel do
	    map[i]:=lakeLevel;
	  for i:=(lakeLevel+1) to numberOfGrayLevels do
	    map[i]:=i
	end
      else
	fatalError('Image file not found: '+fileName)
    end
  else
    fatalError('Usage: image3D [-l<lake level>] file[.pic]')
end;


procedure presentImage;

type  rectangleType             = array[1..4] of pointType;

var   x,y                       : word;
      thisRectangle             : rectangleType;


  procedure makePoint(v1,v2 : integer; var aPoint : pointType);

  begin
    aPoint.x:=v1;
    aPoint.y:=v2
  end;


  procedure drawRectangle(x,y : word);

  begin
    makePoint(gr3D_x(x  ,y  ,map[image^[y  ]^[x  ]]),
	      gr3D_y(x  ,y  ,map[image^[y  ]^[x  ]]),thisRectangle[1]);
    makePoint(gr3D_x(x  ,y+1,map[image^[y+1]^[x  ]]),
	      gr3D_y(x  ,y+1,map[image^[y+1]^[x  ]]),thisRectangle[2]);
    makePoint(gr3D_x(x+1,y+1,map[image^[y+1]^[x+1]]),
	      gr3D_y(x+1,y+1,map[image^[y+1]^[x+1]]),thisRectangle[3]);
    makePoint(gr3D_x(x+1,y  ,map[image^[y  ]^[x+1]]),
	      gr3D_y(x+1,y  ,map[image^[y  ]^[x+1]]),thisRectangle[4]);
    fillPoly(4,thisRectangle)
  end;


begin
  case viewPointHalfPlane of
    north :
      for y:=ySize-1 downTo 1 do
	for x:=1 to xSize-1 do
	  drawRectangle(x,y);
    south :
      for y:=1 to ySize-1 do
	for x:=1 to xSize-1 do
	  drawRectangle(x,y)
  end
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
  presentImage;
  finishOff
end.