unit math;


INTERFACE


function exp2(x : real) : real;

function intExp2(x : byte) : word;

function log2(x : real) : real;

function intLog2(x : word) : byte;

function pot(x : real; potence : integer) : real;

function intPot(x,potence : word) : word;

function potenceOf2(x : word) : boolean;

function rad(angleAsDegrees : real) : real;

function min(x1,x2 : integer) : integer;

function max(x1,x2 : integer) : integer;

function invertBits(x : word; numberOfBits : byte) : word;


IMPLEMENTATION


function exp2(x : real) : real;

begin
  exp2:=exp(x*ln(2))
end;


function intExp2(x : byte) : word;

begin
  intExp2:=round(exp2(x))
end;


function log2(x : real) : real;

begin
  if (x>0) then
    log2:=ln(x)/ln(2)
  else
    log2:=0
end;


function intLog2(x : word) : byte;

begin
  intLog2:=round(log2(x))
end;


function pot(x : real; potence : integer) : real;

var   tmp                       : real;
      i                         : word;

begin
  if (potence>=0) then
    begin
      tmp:=1;
      for i:=1 to potence do
        tmp:=tmp*x;
      pot:=tmp
    end
  else
    pot:=1/pot(x,-potence)
end;


function intPot(x,potence : word) : word;

var   tmp                       : word;
      i                         : word;

begin
  tmp:=1;
  for i:=1 to potence do
    tmp:=tmp*x;
  intPot:=tmp
end;


function potenceOf2(x : word) : boolean;

begin
  potenceOf2:=(intLog2(x)=log2(x))
end;


function rad(angleAsDegrees : real) : real;

begin
  rad:=(pi*angleAsDegrees)/180
end;


function min(x1,x2 : integer) : integer;

begin
  if (x1<x2) then
    min:=x1
  else
    min:=x2
end;


function max(x1,x2 : integer) : integer;

begin
  if (x1>x2) then
    max:=x1
  else
    max:=x2
end;


function invertBits(x : word; numberOfBits : byte) : word;

var   tmp                       : word;
      i                         : byte;

begin
  tmp:=0;
  for i:=0 to numberOfBits-1 do
    inc(tmp,((x shr i) and $01) shl (pred(numberOfBits)-i));
  invertBits:=tmp
end;


end.