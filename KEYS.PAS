unit keys;


INTERFACE


const F1                        = #59;
      F2                        = #60;
      F3                        = #61;
      F4                        = #62;
      F5                        = #63;
      F6                        = #64;
      F7                        = #65;
      F8                        = #66;
      F9                        = #67;
      F10                       = #68;
      NewPage                   = #12;
      CR                        = #13;
      Esc                       = #27;
      Up                        = #72;
      Left                      = #75;
      Right                     = #77;
      Down                      = #80;
      Ins                       = #82;
      Del                       = #83;
      Home                      = #71;
      EndP                      = #79;
      PgUp                      = #73;
      BackSp                    = #8;
      Tab                       = #9;
      PgDn                      = #81;
      CtrlF1                    = #94;
      CtrlF2                    = #95;
      CtrlF3                    = #96;
      CtrlF4                    = #97;
      CtrlF5                    = #98;
      CtrlF6                    = #99;
      CtrlF7                    = #100;
      CtrlF8                    = #101;
      CtrlF9                    = #102;
      CtrlF10                   = #103;
      CtrlHome                  = #119;
      CtrlPgUp                  = #132;
      CtrlLeft                  = #115;
      CtrlRight                 = #116;
      CtrlEnd                   = #117;
      CtrlPgDn                  = #118;
      CtrlA                     = #1;
      CtrlB                     = #2;
      CtrlC                     = #3;
      CtrlD                     = #4;
      CtrlE                     = #5;
      CtrlF                     = #6;
      CtrlG                     = #7;
      CtrlH                     = #8;
      CtrlI                     = #9;
      CtrlJ                     = #10;
      CtrlK                     = #11;
      CtrlL                     = #12;
      CtrlM                     = #13;
      CtrlN                     = #14;
      CtrlO                     = #15;
      CtrlP                     = #16;
      CtrlQ                     = #17;
      CtrlR                     = #18;
      CtrlS                     = #19;
      CtrlT                     = #20;
      CtrlU                     = #21;
      CtrlV                     = #22;
      CtrlW                     = #23;
      CtrlX                     = #24;
      CtrlY                     = #25;
      CtrlZ                     = #26;
      AltF1                     = #104;
      AltF2                     = #105;
      AltF3                     = #106;
      AltF4                     = #107;
      AltF5                     = #108;
      AltF6                     = #109;
      AltF7                     = #110;
      AltF8                     = #111;
      AltF9                     = #112;
      AltF10                    = #113;
      AltHome                   = #7;
      AltUp                     = #8;
      AltPgUp                   = #9;
      AltLeft                   = #4;
      Alt5                      = #5;
      AltRight                  = #6;
      AltEnd                    = #1;
      AltDown                   = #2;
      AltPgDn                   = #3;
      AltA                      = #30;
      AltB                      = #48;
      AltC                      = #46;
      AltD                      = #32;
      AltE                      = #18;
      AltF                      = #33;
      AltG                      = #34;
      AltH                      = #35;
      AltI                      = #23;
      AltJ                      = #36;
      AltK                      = #37;
      AltL                      = #38;
      AltM                      = #50;
      AltN                      = #49;
      AltO                      = #24;
      AltP                      = #25;
      AltQ                      = #16;
      AltR                      = #19;
      AltS                      = #31;
      AltT                      = #20;
      AltU                      = #22;
      AltV                      = #47;
      AltW                      = #17;
      AltX                      = #45;
      AltY                      = #21;
      AltZ                      = #44;

      noKey                     = 'þ';

type  characterSet              = set of char;

      charTuple                 = record
        header                    : char;
        primary                   : char
      end;

const specialKey                : boolean = false;
      ownReadKeyToBeUsed        : boolean = false;

var   keyboardVector            : pointer;


function readKey : char;

procedure anyKey(var aKey : charTuple);

function waitForKey(legalKeys : characterSet; var header : char) : char;

procedure wait;

procedure setKey(var aKey : charTuple; aChar,anotherChar : char);

procedure useOwnReadKey;

procedure doNotUseOwnReadKey;


IMPLEMENTATION

uses crt,dos,intrupt;


function readKey : char;

var   regs                      : registers;
      currentVector             : pointer;
      aKey                      : char;

begin
  if ownReadKeyToBeUsed then
    begin
      getIntVec(keyboardIntNo,currentVector);
      setIntVec(keyboardIntNo,keyboardVector);
      regs.ah:=$00;
      intr($16,regs);
      specialKey:=(regs.al=0);
      if specialKey then
        readKey:=chr(regs.ah)
      else
        readKey:=chr(regs.al);
      setIntVec(keyboardIntNo,currentVector)
    end
  else
    begin
      aKey:=crt.readKey;
      specialKey:=(aKey=#0);
      if specialKey then
        readKey:=crt.readKey
      else
        readKey:=aKey
    end
end;


procedure anyKey(var aKey : charTuple);

var   keyRead                   : char;

begin
  keyRead:=readKey;
  if specialKey then
    setKey(aKey,#0,keyRead)
  else
    setKey(aKey,noKey,keyRead)
end;


function waitForKey(legalKeys : characterSet; var header : char) : char;

var   aKey                      : charTuple;

begin
  if (legalKeys=[]) then
    anyKey(aKey)
  else
    repeat
      anyKey(aKey)
    until ((aKey.primary in legalKeys) or
           (upCase(aKey.primary) in legalKeys));
  header:=aKey.header;
  waitForKey:=aKey.primary
end;


procedure wait;

var   aKey                      : char;

begin
  aKey:=readKey
end;


procedure setKey(var aKey : charTuple; aChar,anotherChar : char);

begin
  with aKey do
    begin
      header:=aChar;
      primary:=anotherChar
    end
end;


procedure useOwnReadKey;

begin
  ownReadKeyToBeUsed:=true
end;


procedure doNotUseOwnReadKey;

begin
  ownReadKeyToBeUsed:=false
end;


begin
  getIntVec(keyboardIntNo,keyboardVector)
end.