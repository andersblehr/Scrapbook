program edges;

uses crt,graph,auxil,search,SVGA;

var   pupilPoint                : pointType;
      outputFile                : file;
      buffer                    : bufferType;


procedure init;

var   fileName                  : string;
      inputFile                 : file;
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
            'o' : octopusRadiusFraction:=getParameterValue(thisParameter);
            'l' : lakeLevel:=trunc(getParameterValue(thisParameter))
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
    blockRead(inputFile,buffer,4);
    xSize:=(word(buffer[1]) shl 8)+buffer[2];
    ySize:=(word(buffer[3]) shl 8)+buffer[4];
    startX:=getMaxX div 2;
    initGlobals
  end;


begin
  if (paramCount<>0) then
    begin
      getParameters(paramCount);
      if fileExists(fileName) then
        begin
          SVGA_initGraphics(mode800x600);
          SVGA_setBlackAndWhitePalette;
          assign(inputFile,fileName);
          reset(inputFile,1);
          assign(outputFile,'c:\user\blehr\fag\diplom\bilder\edges.pic');
          rewrite(outputFile,1);
          initVariables;
          getMem(image,4*ySize);
          buffer[1]:=hi(xSize-4);
          buffer[2]:=lo(xSize-4);
          buffer[3]:=hi(ySize-4);
          buffer[4]:=lo(ySize-4);
          blockWrite(outputFile,buffer,4);
          for i:=1 to ySize do
            begin
              blockRead(inputFile,buffer,xSize);
              getMem(image^[i],xSize);
              for j:=1 to xSize do
                begin
                  image^[i]^[j]:=buffer[j];
                  putPixel(j,i,buffer[j])
                end
            end;
          close(inputFile)
        end
      else
        fatalError('Image file not found: '+picturePath(fileName))
    end
  else
    fatalError('Usage: edges [-r<radius>][-t<threshold>] file[.pic]')
end;


procedure main;

var   eastWestBorder            : word;
      northSouthBorder          : word;
      i,j                       : word;


  function getFilterValue(x,y : word) : byte;

  var   eastOrWest                : shortInt;
        northOrSouth              : shortInt;
        filterValue               : integer;


    function getHalfPlane(position,border : word) : shortInt;

    begin
      case (position>border) of
        true  : getHalfPlane:=1;
        false : getHalfPlane:=-1
      end;
    end;


  begin
    eastOrWest:=getHalfPlane(x,eastWestBorder);
    northOrSouth:=getHalfPlane(y,northSouthBorder);
    filterValue:=applySobelMask(x,y,northOrSouth,eastOrWest);
    case (filterValue>0) of
      true  : getFilterValue:=filterValue;
      false : getFilterValue:=0
    end
  end;


  function doLimit(aValue : byte) : byte;

  begin
    case (aValue>63) of
      true  : doLimit:=63;
      false : doLimit:=aValue
    end
  end;


  procedure writeText;

  begin
    setColor(60);
    setTextStyle(defaultFont,HorizDir,1);
    setTextJustify(leftText,centerText);
    outTextXY(1,ySize+30,'Original image');
    outTextXY(startX,ySize+30,'Filtered image');
    outTextXY(startX,ySize+40,'The circle designates filter origo')
  end;


begin
  if findPupilPoint(pupilPoint) then
    begin
      eastWestBorder:=pupilPoint.x;
      northSouthBorder:=pupilPoint.y;
      for i:=3 to ySize-2 do
        begin
          for j:=3 to xSize-2 do
            begin
              buffer[j-2]:=doLimit(2*getFilterValue(j,i));
              putPixel(startX+j,i,buffer[j-2])
            end;
          blockWrite(outputFile,buffer,xSize-4)
        end;
      markPosition(pupilPoint.x,pupilPoint.y,asCircle);
      writeText
    end
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
  main;
  finishOff
end.