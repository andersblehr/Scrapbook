Unit Matte;
{$N+}



INTERFACE


Function tan(x : Real) : Real;

Function cosh(x : Real) : Real;

Function sinh(x : Real) : Real;

Function tanh(x : Real) : Real;

Function eksp(x,y : Real) : Real;

Function lg(x : Real) : Real;

Function log(GrTall,x : Real) : Real;

Function fak(x : Integer) : Extended;

Function rad(x : Real) : Real;

Function grad(x : Real) : Real;

Function Max(x,y : Real) : Real;

Function Min(x,y : Real) : Real;



IMPLEMENTATION



Function tan(x : Real) : Real;

BEGIN
   tan:=sin(x)/cos(x)
END;



Function cosh(x : Real) : Real;

BEGIN
   cosh:=0.5*(exp(x)+exp(-x))
END;



Function sinh(x : Real) : Real;

BEGIN
   sinh:=0.5*(exp(x)-exp(-x))
END;



Function tanh(x : Real) : Real;

BEGIN
   tanh:=(exp(x)-exp(-x))/(exp(x)+exp(-x))
END;



Function eksp(x,y : Real) : Real;

VAR    i            : Integer;
       Temp         : Real;

BEGIN
   If x>0 then
      eksp:=exp(y*ln(x))
   else if (x<0) and (Int(y)=y) then
      BEGIN
         Temp:=1;
         For i:=1 to abs(Round(y)) do
            Temp:=Temp*x;
         If y<0 then
            eksp:=1/Temp
         else if y>0 then
            eksp:=Temp
      END
   else
      eksp:=0
END;



Function lg(x : Real) : Real;

BEGIN
   If x<=0 then
      lg:=-MaxInt
   else
      lg:=ln(x)/ln(10)
END;



Function log(GrTall,x : Real) : Real;

BEGIN
   If (GrTall<=0) or (x<=0) then
      log:=-MaxInt
   else
      log:=ln(x)/ln(GrTall)
END;



Function fak(x : Integer) : Extended;

VAR    Temp         : Extended;
       i            : Integer;

BEGIN
   If (x>0) and (x<1755) then
      BEGIN
         Temp:=1;
         For i:=1 to x do
            Temp:=Temp*i;
         fak:=Temp
      END
   else if x=0 then
      fak:=1
   else
      fak:=0
END;



Function rad(x : Real) : Real;

BEGIN
   rad:=(pi*x)/180
END;



Function grad(x : Real) : Real;

BEGIN
   grad:=(180*x)/pi
END;



Function Max(x,y : Real) : Real;

BEGIN
   If x>=y then
      Max:=x
   else
      Max:=y
END;



Function Min(x,y : Real) : Real;

BEGIN
   If x<=y then
      Min:=x
   else
      Min:=y
END;



END.