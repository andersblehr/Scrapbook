unit mathcmpl;


INTERFACE


const asDegrees                 = 0;
      asRadians                 = 1;

type  cmplx                     = ^complexO;
      complexO                  = object
        re                        : real;
        im                        : real;
        constructor init(reValue,imValue : real);
        function    amplitude            : real;
        function    angle(asWhat : byte) : real;
        function    conjugate            : cmplx;
        function    add(x : cmplx)       : cmplx;
        function    subtract(x : cmplx)  : cmplx;
        function    multiply(x : cmplx)  : cmplx;
        function    divide(x : cmplx)    : cmplx;
        function    cos                  : cmplx;
        function    sin                  : cmplx;
        function    tan                  : cmplx;
        function    exp                  : cmplx;
        function    ln                   : cmplx;
        procedure   dump;
      end;


function complex(re,im : real) : cmplx;


IMPLEMENTATION


(**************************************************************************
 *                                                                        *
 *    complexO's methods                                                  *
 *                                                                        *
 **************************************************************************)


constructor complexO.init(reValue,imValue : real);

begin
  re:=reValue;
  im:=imValue
end;


function complexO.amplitude : real;

begin
  amplitude:=sqrt(sqr(re)+sqr(im))
end;


function complexO.angle(asWhat : byte) : real;

var   theAngle                  : real;

begin
  if ((re<>0) and (im<>0)) then
    theAngle:=arcTan(im/re)
  else if (((re>0) and (im=0)) or ((re=0) and (im=0))) then
    theAngle:=0
  else if ((re=0) and (im>0)) then
    theAngle:=pi/2
  else if ((re<0) and (im=0)) then
    theAngle:=pi
  else if ((re=0) and (im<0)) then
    theAngle:=3*pi/2;
  case asWhat of
    asDegrees : angle:=theAngle*180/pi;
    asRadians : angle:=theAngle
  end
end;


function complexO.conjugate : cmplx;

begin
  conjugate:=new(cmplx,init(re,-im))
end;


function complexO.add(x : cmplx) : cmplx;

begin
  add:=new(cmplx,init(re+x^.re,im+x^.im))
end;


function complexO.subtract(x : cmplx) : cmplx;

begin
  subtract:=new(cmplx,init(re-x^.re,im-x^.im))
end;


function complexO.multiply(x : cmplx) : cmplx;

begin
  multiply:=new(cmplx,init(re*x^.re-im*x^.im,re*x^.im+im*x^.re))
end;


function complexO.divide(x : cmplx) : cmplx;

var   dvs                       : real;

begin
  dvs:=sqr(x^.re)+sqr(x^.im);
  divide:=new(cmplx,init((re*x^.re+im*x^.im)/dvs,(-re*x^.im+im*x^.re)/dvs))
end;


function complexO.cos : cmplx;

begin
  cos:=multiply(complex(0,1))^.exp^.add(multiply(complex(0,-1))^.exp)^.divide(complex(2,0))
end;


function complexO.sin : cmplx;

begin
  sin:=multiply(complex(0,1))^.exp^.subtract(multiply(complex(0,-1))^.exp)^.divide(complex(0,2))
end;


function complexO.tan : cmplx;

begin
  tan:=sin^.divide(cos)
end;


function complexO.exp : cmplx;

begin
  exp:=new(cmplx,init(system.exp(re)*system.cos(im),system.exp(re)*system.sin(im)))
end;


function complexO.ln : cmplx;


  function translate(anAngle : real) : real;

  begin
    if (anAngle>pi) then
      translate:=anAngle-pi
    else
      translate:=anAngle
  end;


begin
  ln:=new(cmplx,init(system.ln(amplitude),translate(angle(asRadians))))
end;


procedure complexO.dump;

var   imSign                    : char;

begin
  if (im>=0) then
    imSign:='+'
  else
    imSign:='-';
  write(re:4:2,imSign,'j',abs(im):4:2)
end;


(**************************************************************************
 *                                                                        *
 *    General functions                                                   *
 *                                                                        *
 **************************************************************************)


function complex(re,im : real) : cmplx;

begin
  complex:=new(cmplx,init(re,im))
end;


end.