unit intrupt;


INTERFACE

uses dos;


const clockIntNo                = $08;
      keyboardIntNo             = $09;
      ctrlBreakIntNo            = $1B;
      userClockIntNo            = $1C;


function changeIntVector(interruptNo : byte; aVector : pointer) : pointer;

procedure disableInterrupt; inline($FA);

procedure enableInterrupt; inline($FB);

procedure pushFlags; inline($9C);

procedure runVector(interruptNo : byte; aVector : pointer);


IMPLEMENTATION


function changeIntVector(interruptNo : byte; aVector : pointer) : pointer;

var   oldVector                 : pointer;

begin
  getIntVec(interruptNo,oldVector);
  setIntVec(interruptNo,aVector);
  changeIntVector:=oldVector
end;


procedure runVector(interruptNo : byte; aVector : pointer);

var   regs                      : registers;
      currentVector             : pointer;

begin
  getIntVec(interruptNo,currentVector);
  setIntVec(interruptNo,aVector);
  intr(interruptNo,regs);
  setIntVec(interruptNo,currentVector)
end;


end.