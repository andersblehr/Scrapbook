unit graph3D;


INTERFACE

type  point3D                   = record
	x                         : real;
	y                         : real;
	z                         : real
      end;


function gr3D_x(x,y,z : real) : word;

function gr3D_y(x,y,z : real) : word;

procedure gr3D_initCoordSystem(xMin,xMax,yMin,yMax,zScaling,a_H,a_V : real);

procedure gr3D_drawCoordSystem(xMin,xMax,yMin,yMax,zMin,zMax,zScaling,a_H,a_V : real);

procedure gr3D_plot(x,y,z : real; colour : Byte);

procedure gr3D_line(x1,y1,z1,x2,y2,z2 : real);

procedure gr3D_pointLine(point1,point2 : point3D);


IMPLEMENTATION

uses graph,auxil,math;


const gr3D_initialized          : boolean = false;

var   origo                     : pointType;
      horizontalAngle           : real;
      verticalAngle             : real;
      xOffset                   : real;
      yOffset                   : real;
      xyUnit                    : real;
      zUnit                     : real;


function gr3D_x(x,y,z : real) : word;

begin
  gr3D_x:=origo.x+trunc(xyUnit*((y-yOffset)*cos(horizontalAngle)+
				(x-yOffset)*sin(horizontalAngle)))
end;


function gr3D_y(x,y,z : real) : word;

begin
  gr3D_y:=origo.y+trunc(xyUnit*(((x-xOffset)*cos(horizontalAngle)-
	  (y-yOffset)*sin(horizontalAngle))*sin(-verticalAngle))-
	  (zUnit*z*cos(verticalAngle)))
end;


procedure gr3D_initCoordSystem(xMin,xMax,yMin,yMax,zScaling,a_H,a_V : real);

begin
  gr3D_initialized:=true;
  origo.x:=getMaxX div 2;
  origo.y:=2*(getMaxY div 3);
  xOffset:=xMin+(xMax-xMin)/2;
  yOffset:=yMin+(yMax-yMin)/2;
  xyUnit:=(0.8*getMaxY)/realMax(xMax-xMin,yMax-yMin);
  zUnit:=zScaling*xyUnit;
  horizontalAngle:=rad(a_H);
  verticalAngle:=rad(a_V)
end;


procedure gr3D_drawCoordSystem(xMin,xMax,yMin,yMax,zMin,zMax,zScaling,a_H,a_V : real);

begin
  gr3D_initCoordSystem(xMin,xMax,yMin,yMax,zScaling,a_H,a_V);
  gr3D_line(xMin,0,0,xMax,0,0);
  gr3D_line(0,yMin,0,0,yMax,0);
  gr3D_line(0,0,zMin,0,0,zMax)
end;


procedure gr3D_plot(x,y,z : real; colour : Byte);

begin
  if gr3D_initialized then
    putPixel(gr3D_x(x,y,z),gr3D_y(x,y,z),colour)
  else
    fatalError('graph3D: Coordinate system not initialized!')
end;


procedure gr3D_line(x1,y1,z1,x2,y2,z2 : real);

begin
  if gr3D_initialized then
    line(gr3D_x(x1,y1,z1),gr3D_y(x1,y1,z1),gr3D_x(x2,y2,z2),gr3D_y(x2,y2,z2))
  else
    fatalError('graph3D: Coordinate system not initialized!')
end;


procedure gr3D_pointLine(point1,point2 : point3D);

begin
  if gr3D_initialized then
    line(gr3D_x(point1.x,point1.y,point1.z),
	 gr3D_y(point1.x,point1.y,point1.z),
	 gr3D_x(point2.x,point2.y,point2.z),
	 gr3D_y(point2.x,point2.y,point2.z))
  else
    fatalError('graph3D: Coordinate system not initialized!')
end;


end.