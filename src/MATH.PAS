unit math;


INTERFACE


const positive                  = 1;
      negative                  = -1;


function exp2(x : real) : real;

function intExp2(x : byte) : word;

function log2(x : real) : real;

function intLog2(x : word) : byte;

function pot(x : real; potence : integer) : real;

function intPot(x,potence : word) : word;

function potenceOf2(x : word) : boolean;

function rad(angleAsDegrees : real) : real;

function intMin(x1,x2 : integer) : integer;

function intMax(x1,x2 : integer) : integer;

function realMin(x1,x2 : real) : real;

function realMax(x1,x2 : real) : real;

function odd(x : integer) : boolean;

function even(x : integer) : boolean;

function high(x : real) : integer;

function sign(x : real) : shortInt;

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


function intMin(x1,x2 : integer) : integer;

begin
  if (x1<x2) then
    intMin:=x1
  else
    intMin:=x2
end;


function intMax(x1,x2 : integer) : integer;

begin
  if (x1>x2) then
    intMax:=x1
  else
    intMax:=x2
end;


function realMin(x1,x2 : real) : real;

begin
  if (x1<x2) then
    realMin:=x1
  else
    realMin:=x2
end;


function realMax(x1,x2 : real) : real;

begin
  if (x1>x2) then
    realMax:=x1
  else
    realMax:=x2
end;


function odd(x : integer) : boolean;

begin
  odd:=(not even(x))
end;


function even(x : integer) : boolean;

begin
  even:=((x/2)=(x div 2))
end;


function high(x : real) : integer;

begin
  if (x>=0) then
    if (trunc(x)=0) then
      high:=1
    else if ((x/trunc(x))=1) then
      high:=trunc(x)
    else
      high:=succ(trunc(x))
  else
    high:=-high(-x)
end;


function sign(x : real) : shortInt;

begin
  if (x>=0) then
    sign:=1
  else
    sign:=-1
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