unit mice;


{****************************************************************************

    Name             mice
    Type             Unit
    Author           H†kan Yngvesson
    Date             21/7-92

    Description      Routines for handling the mouse in Pascalprograms.

    Function         Function initMouse inits the mouse and returns true if
                     successful.
                     PROCEDURE pollMouse polls the mouse. Returns the actual
                     position in x,y. The buttons is returned in buttonStatus where
                     bit 0 = left button, bit 1 = right button and bit =
                     middle button, 1 means button pressed and 0 button not
                     pressed. staus of mousebuttons is also returned in
                     boolean variables leftButton,middleButton and rightButton where true means
                     button pressed.
                     Procedure TextMouse shows the cursor in textmode.
                     Procedure GraphMouse shows the mousecursor as an arrow
                     in graphic mode.
                     Procedure SandUhrMouse shows the mousecursor as a
                     sandclock in graphic mode.
                     Procedure RundPfeilMouse shows the mouse as a arrow that
                     bites itself in the back.
                     PROCEDURE ShowMouse shows the mouse.
                     PROCEDURE HideMouse makes the mousecursor invisible.
                     PROCEDURE WaitNoMouseButton wait until no mousebutton
                     is pressed.
                     PROCEDURE WaitMouseGone waits until the mouse is not in
                     the area xmin,ymin (upper left corner) and xmax,ymax
                     (lower right corner) with pressed buttons.

****************************************************************************}


INTERFACE


const arrow                     = 0;
      circleArrow               = 1;
      copyright                 = 2;
      sandClock                 = 3;

type  mouseType                 = record
        x                         : integer;
        y                         : integer;
        leftButton                : boolean;
        middleButton              : boolean;
        rightButton               : boolean;
        buttonStatus              : byte
      end;

var   q,k                       : byte;


function initMouse : boolean;

procedure showMouse;

procedure hideMouse;

procedure squareHide(x1,y1,x2,y2 : integer);

procedure pollMouse(var mouseVar : mouseType);

procedure waitNoMouseButton;

procedure waitMouseGone(xMin,yMin,xMax,yMax : integer);

procedure textMouse;

procedure graphMouse;

procedure setMouseCursor(cursorType : byte);


IMPLEMENTATION


var      MI  : boolean;
    Visible  : boolean;

{$L O_Pfeil }
{$L SandUhr }
{$L Copyrite }
{$L Pfeil }
{$F+}
procedure o_pfeil;External;
procedure SandUhr;External;
procedure Pfeil;External;
procedure copyrite;external;
{$F-}

{ *****     Anfang Mausroutinen     ***** }


procedure MouseBorders(x1,y1,x2,y2:integer);
begin
  ASM
    mov ax,$0007
    mov cx,x1
    mov dx,x2
    int $33
    mov ax,$0008
    mov cx,y1
    mov dx,y2
    int $33
  end;
end;


procedure TextMouse;
begin
  q:=8;
  k:=1;
  asm
    mov ax,$000A
    mov bx,0
    mov cx,$3FFF    { and  }
    mov dx,$7000    {xor   }
    int $33
  end;
end;


procedure GraphMouse;
begin
  pfeil;
  q:=1;
  k:=0;
  MouseBorders(0,0,630,466);
end;


function MouseReset:boolean;
var Slask1,Slask2,s1,s2:WORD;          { INIT THE MOUSE                     }
begin                                  { KOMP IS COMPENSATION OF X AND Y    }
  ASM                                  { UPPER LEFT FOR MOUSE IS 0,0        }
    MOV AX,$0000                       { KVOT IS QUOTE FOR X AND Y          }
    INT $33                            { GIVE KVOT=8 AND KOMP=1 TO MAKE THE }
    MOV Slask1,AX                      { MOUSE-COORDINATES THE SAME AS E.G. }
    MOV Slask2,BX                      { GOTOXY                             }
    mov ax,$001c
    mov bx,1
    int $33
  end;
  S1:=Slask1;
  S2:=Slask2;
  MI:=(S1=$FFFF);
  TextMouse;
  MouseReset:=MI;
end;




procedure SHOWMOUSE;                   { MAKES THE MOUSE VISIBLE            }
begin
  IF MI AND NOT Visible THEN
  begin
    ASM
      MOV AX,$0001
      INT $33
    end;
    Visible:=TRUE;
  end;
end;


procedure HIDEMOUSE;                   { MAKES THE MOUSE INVISIBLE          }
begin
  IF MI AND Visible THEN
  begin
    ASM
      MOV AX,$0002
      INT $33
    end;
    Visible:=FALSE;
  end;
end;

procedure SquareHide(x1,y1,x2,y2:integer);
var m:mousetype;
begin
     if (x1=0) and (x2=0) and (y1=0) and (y2=-1) and
     not visible then showmouse else
  IF MI THEN
  begin
    visible:=false;
    ASM
      push di
      push si
      mov ax,$0010
      mov cx,x1
      mov dx,y1
      mov si,x2
      mov di,y2
      INT $33
      pop si
      pop di
    end;
  end;
end;

procedure pollMouse(var MouseVar:mouseType);{ TELLS THE POSITION AND STATUS OF  }
var Slask1,SlaskX,SlaskY:WORD;         { THE MOUSE                          }
begin
  IF MI THEN
  begin
    ASM
      MOV AX,$0003
      INT $33
      MOV Slask1,BX   { BX enth„lt aufgaben ber die Maustasten  }
      MOV SlaskX,CX   { CX enth„lt aufgaben ber die horisontelle position }
      MOV SlaskY,DX   { DX enth„lt aufgaben ber die vertikale position }
    end;
    MouseVar.X:=(SlaskX DIV Q)+K;
    MouseVar.Y:=(SlaskY DIV Q)+K;
    MouseVar.buttonStatus:=lo(Slask1);
    MouseVar.leftButton:=(Slask1 AND $01>0);
    MouseVar.rightButton:=(Slask1 AND $02>0);
    MouseVar.middleButton:=(Slask1 AND $04>0);
    { Bit 1 = Linke Maustaste
      Bit 2 = Rechte Maustaste
      Bit 3 = Mittlere Maustaste }
  end
  ELSE
  begin
    MouseVar.X:=0;
    MouseVar.Y:=0;
    MouseVar.leftButton:=FALSE;
    MouseVar.rightButton:=FALSE;
    MouseVar.middleButton:=FALSE;
  end;
end;



procedure WaitMouseGone(Xmin,Ymin,Xmax,Ymax:integer);
var M:mouseType;
begin
  IF mi THEN
  REPEAT
    pollMouse(m);
  UNTIL (M.x<Xmin) OR (M.x>Xmax) OR (M.y<Ymin) OR (M.y>Ymax) OR ( M.buttonStatus=0 );
end;


procedure WaitNoMouseButton;
var M:mouseType;
begin
  REPEAT
    pollMouse(m);
  UNTIL M.buttonStatus=0;
end;



function initMouse:boolean;
begin
  initMouse:=MouseReset;
  Visible:=false;
end;


procedure setMouseCursor(cursorType : byte);

begin
  case cursorType of
    arrow       : pfeil;
    circleArrow : o_pfeil;
    copyright   : copyrite;
    sandClock   : sanduhr
  end
end;


begin
  mi:=FALSE;
end.
