unit graph3D;


INTERFACE

uses graph,math;

type  point3D                   = record
	x                         : real;
	y                         : real;
	z                         : real
      end;


function gr3D_x(x,y,z : real) : word;

function gr3D_y(x,y,z : real) : word;

procedure gr3D_drawCoordSystem(theRadius,theFrontAngle,theTopAngle : real);

procedure gr3D_initCoordSystem(theRadius,theFrontAngle,theTopAngle : real);

procedure gr3D_plot(x,y,z : real; colour : Byte);

procedure gr3D_line(x1,y1,z1,x2,y2,z2 : real);

procedure gr3D_pointLine(point1,point2 : point3D);

procedure gr3D_getViewersPosition(var viewersPosition : point3D);


IMPLEMENTATION

uses auxil;


const coordSystemInitialized    : boolean = false;

var   origo                     : pointType;
      screenUnit                : real;
      frontAngle                : real;
      topAngle                  : real;
      radius                    : real;


function gr3D_x(x,y,z : real) : word;

begin
  gr3D_x:=origo.x+trunc(screenUnit*(y*cos(frontAngle)-x*sin(frontAngle)))
end;


function gr3D_y(x,y,z : real) : word;

begin
  gr3D_y:=origo.y+trunc(screenUnit*((x*cos(frontAngle)+y*sin(frontAngle))*cos(topAngle)-z*sin(topAngle)))
end;


procedure gr3D_drawCoordSystem(theRadius,theFrontAngle,theTopAngle : real);

var   xStartX                   : word;
      xStartY                   : word;
      xEndX                     : word;
      xEndY                     : word;
      yStartX                   : word;
      yStartY                   : word;
      yEndX                     : word;
      yEndY                     : word;
      zStartX                   : word;
      zStartY                   : word;
      zEndX                     : word;
      zEndY                     : word;

begin
  gr3D_initCoordSystem(theRadius,theFrontAngle,theTopAngle);
  with origo do
    begin
      xStartX:=x-trunc(radius*screenUnit*sin(frontAngle));
      xStartY:=y+trunc(radius*screenUnit*cos(frontAngle)*cos(topAngle));
      xEndX:=x+trunc(radius*screenUnit*sin(frontAngle));
      xEndY:=y-trunc(radius*screenUnit*cos(frontAngle)*cos(topAngle));
      yStartX:=x-trunc(radius*screenUnit*cos(frontAngle));
      yStartY:=y-trunc(radius*screenUnit*sin(frontAngle)*cos(topAngle));
      yEndX:=x+trunc(radius*screenUnit*cos(frontAngle));
      yEndY:=y+trunc(radius*screenUnit*sin(frontAngle)*cos(topAngle));
      zStartX:=x;
      zStartY:=y+trunc(radius*screenUnit*sin(topAngle));
      zEndX:=x;
      zEndY:=y-trunc(radius*screenUnit*sin(topAngle))
    end;
  line(yStartX,yStartY,yEndX,yEndY);
  line(zStartX,zStartY,zEndX,zEndY);
  line(xStartX,xStartY,xEndX,xEndY)
end;


procedure gr3D_initCoordSystem(theRadius,theFrontAngle,theTopAngle : real);

begin
  coordSystemInitialized:=true;
  radius:=theRadius;
  screenUnit:=((getMaxY div 2)-10)/radius;
  origo.x:=getMaxX div 2;
  origo.y:=getMaxY div 2;
  frontAngle:=rad(theFrontAngle);
  topAngle:=rad(theTopAngle)
end;


procedure gr3D_plot(x,y,z : real; colour : Byte);

begin
  if coordSystemInitialized then
    putPixel(gr3D_x(x,y,z),gr3D_y(x,y,z),colour)
  else
    fatalError('graph3D: Coordinate system not initialized!')
end;


procedure gr3D_line(x1,y1,z1,x2,y2,z2 : real);

begin
  if coordSystemInitialized then
    line(gr3D_x(x1,y1,z1),gr3D_y(x1,y1,z1),gr3D_x(x2,y2,z2),gr3D_y(x2,y2,z2))
  else
    fatalError('graph3D: Coordinate system not initialized!')
end;


procedure gr3D_pointLine(point1,point2 : point3D);

begin
  if coordSystemInitialized then
    line(gr3D_x(point1.x,point1.y,point1.z),
	 gr3D_y(point1.x,point1.y,point1.z),
	 gr3D_x(point2.x,point2.y,point2.z),
	 gr3D_y(point2.x,point2.y,point2.z))
  else
    fatalError('graph3D: Coordinate system not initialized!')
end;


procedure gr3D_getViewersPosition(var viewersPosition : point3D);

begin
  with viewersPosition do
    begin
      x:=2*radius*sin(topAngle)*cos(frontAngle);
      y:=2*radius*sin(topAngle)*sin(frontAngle);
      z:=2*radius*cos(topAngle)
    end
end;


end.