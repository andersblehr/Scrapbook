Unit myGraph;



INTERFACE

Uses Graph,keys;


CONST  MouseX       : Integer = 314;
       MouseY       : Integer = 232;


VAR    BitMap       : Pointer;



Procedure InitGraf(GraphDriver,GraphMode : Integer; Sti : String;
                   BakGrunn,TegneFarge : Byte);

Procedure Clear(x1,y1,x2,y2 : Word);

Procedure ClearColor(x1,y1,x2,y2,Color : Word);

Procedure LesXY(x,y : Word; VAR Retur : String);



IMPLEMENTATION


CONST  GraphInit    : Boolean = false;
       MouseInit    : Boolean = false;
       MouseHidden  : Boolean = false;



Procedure InitGraf;

BEGIN
   InitGraph(GraphDriver,GraphMode,Sti);
   SetBkColor(BakGrunn);
   SetColor(TegneFarge);
   GraphInit:=true;
END;



Procedure Clear;

BEGIN
   SetFillStyle(SolidFill,GetBkColor);
   Bar(x1,y1,x2,y2)
END;



Procedure ClearColor(x1,y1,x2,y2,Color : Word);

BEGIN
   SetFillStyle(SolidFill,Color);
   Bar(x1,y1,x2,y2)
END;



Procedure LesXY;

CONST  Delta        = 8;

VAR    Tegn         : Char;
       Temp         : String;
       StartX       : Word;
       x1           : Word;

BEGIN
   Temp:='';
   StartX:=x;
   x1:=x;
   Repeat
      Tegn:=readKey;
      If (Tegn=BackSp) and (x1>StartX) then
         BEGIN
            x1:=x1-Delta;
            Clear(x1,y,x1+Delta,y+Delta);
            Delete(Temp,Length(Temp),1)
         END
      else if not (Tegn in [CR,Esc,BackSp]) then
         BEGIN
            Temp:=Temp+Tegn;
            OutTextXY(x1,y,Tegn);
            x1:=x1+Delta
         END
   Until Tegn=CR;
   Retur:=Temp
END;



END.