Unit Graf3D;


INTERFACE

Uses Graph,Matte;


TYPE   Punkt3D    = Record
                       x         : Real;
                       y         : Real;
                       z         : Real;
                       Flagg     : Boolean
                    END;
       Punkt3     = Record
                       x         : Real;
                       y         : Real;
                       z         : Real
                    END;


CONST  KoordKlart   : Boolean = false;


VAR    Origo        : PointType;
       Enhet        : Real;
       v1           : Real;
       v2           : Real;
       r            : Real;



Procedure KoordSystem(Radius,Vinkel1,Vinkel2 : Real);

Procedure KoordInit(Radius,Vinkel1,Vinkel2 : Real);

Procedure Plot(x,y,z : Real; Farge : Byte);

Function X3D(x,y,z : Real) : Integer;

Function Y3D(x,y,z : Real) : Integer;

Procedure Line3D(x1,y1,z1,x2,y2,z2 : Real);

Procedure PLine3D(Punkt1,Punkt2 : Punkt3D);

Procedure Kube(x1,y1,z1,x2,y2,z2 : Real);

Procedure HelKube(x1,y1,z1,x2,y2,z2 : Real);

Procedure EgenPosXYZ(VAR Punkt : Punkt3D);



IMPLEMENTATION




Procedure KoordSystem;

VAR    XStartX      : Integer;
       XStartY      : Integer;
       XSluttX      : Integer;
       XSluttY      : Integer;
       YStartX      : Integer;
       YStartY      : Integer;
       YSluttX      : Integer;
       YSluttY      : Integer;
       ZStartX      : Integer;
       ZStartY      : Integer;
       ZSluttX      : Integer;
       ZSluttY      : Integer;

BEGIN
   KoordKlart:=true;
   r:=Radius;
   Enhet:=230/r;
   Origo.x:=320;
   Origo.y:=240;
   v1:=rad(Vinkel1);
   v2:=rad(Vinkel2);
   With Origo do
      BEGIN
         XStartX:=x-trunc(r*Enhet*sin(v1));
         XStartY:=y+trunc(r*Enhet*cos(v1)*cos(v2));
         XSluttX:=x+trunc(r*Enhet*sin(V1));
         XSluttY:=y-trunc(r*Enhet*cos(v1)*cos(v2));
         YStartX:=x-trunc(r*Enhet*cos(v1));
         YStartY:=y-trunc(r*Enhet*sin(v1)*cos(v2));
         YSluttX:=x+trunc(r*Enhet*cos(v1));
         YSluttY:=y+trunc(r*Enhet*sin(v1)*cos(v2));
         ZStartX:=x;
         ZStartY:=y+trunc(r*Enhet*sin(v2));
         ZSluttX:=x;
         ZSluttY:=y-trunc(r*Enhet*sin(v2))
      END;
   Line(YStartX,YStartY,YSluttX,YSluttY);
   Line(ZStartX,ZStartY,ZSluttX,ZSluttY);
   Line(XStartX,XStartY,XSluttX,XSluttY)
END;




Procedure KoordInit;

BEGIN
   KoordKlart:=true;
   r:=Radius;
   Enhet:=230/r;
   Origo.x:=320;
   Origo.y:=240;
   v1:=rad(Vinkel1);
   v2:=rad(Vinkel2)
END;




Procedure Plot;

VAR    x1           : Integer;
       y1           : Integer;

BEGIN
   If KoordKlart then
      BEGIN
         x1:=X3D(x,y,z);
         y1:=Y3D(x,y,z);
         PutPixel(x1,y1,Farge)
      END
END;




Function X3D;

BEGIN
   X3D:=Origo.x+trunc(Enhet*(y*cos(v1)-x*sin(v1)))
END;




Function Y3D;

BEGIN
   Y3D:=Origo.y+trunc(Enhet*((x*cos(v1)+y*sin(v1))*cos(v2)-z*sin(v2)))
END;




Procedure Line3D;

VAR    x_1          : Integer;
       y_1          : Integer;
       x_2          : Integer;
       y_2          : Integer;

BEGIN
   If KoordKlart then
      BEGIN
         x_1:=X3D(x1,y1,z1);
         y_1:=Y3D(x1,y1,z1);
         x_2:=X3D(x2,y2,z2);
         y_2:=Y3D(x2,y2,z2);
         Line(x_1,y_1,x_2,y_2)
      END
END;




Procedure PLine3D;

VAR    x_1          : Integer;
       y_1          : Integer;
       x_2          : Integer;
       y_2          : Integer;

BEGIN
   If KoordKlart then
      BEGIN
         x_1:=X3D(Punkt1.x,Punkt1.y,Punkt1.z);
         y_1:=Y3D(Punkt1.x,Punkt1.y,Punkt1.z);
         x_2:=X3D(Punkt2.x,Punkt2.y,Punkt2.z);
         y_2:=Y3D(Punkt2.x,Punkt2.y,Punkt2.z);
         Line(x_1,y_1,x_2,y_2)
      END
END;




Procedure Kube(x1,y1,z1,x2,y2,z2 : Real);

VAR    Punkt1       : Punkt3D;
       Punkt2       : Punkt3D;
       Punkt3       : Punkt3D;
       Punkt4       : Punkt3D;
       Punkt5       : Punkt3D;
       Punkt6       : Punkt3D;
       Punkt7       : Punkt3D;
       Punkt8       : Punkt3D;



   Procedure SettPunkt(VAR PunktX : Punkt3D; x1,y1,z1 : Real);

   BEGIN
      With PunktX do
         BEGIN
            x:=x1;
            y:=y1;
            z:=z1
         END
   END;



BEGIN
   SettPunkt(Punkt1,x1,y1,z1);
   SettPunkt(Punkt2,x2,y1,z1);
   SettPunkt(Punkt3,x2,y1,z2);
   SettPunkt(Punkt4,x1,y1,z2);
   SettPunkt(Punkt5,x1,y2,z1);
   SettPunkt(Punkt6,x2,y2,z1);
   SettPunkt(Punkt7,x2,y2,z2);
   SettPunkt(Punkt8,x1,y2,z2);
   PLine3D(Punkt1,Punkt2);
   PLine3D(Punkt2,Punkt3);
   PLine3D(Punkt3,Punkt4);
   PLine3D(Punkt4,Punkt1);
   PLine3D(Punkt1,Punkt5);
   PLine3D(Punkt2,Punkt6);
   PLine3D(Punkt3,Punkt7);
   PLine3D(Punkt4,Punkt8);
   PLine3D(Punkt5,Punkt6);
   PLine3D(Punkt6,Punkt7);
   PLine3D(Punkt7,Punkt8);
   PLine3D(Punkt8,Punkt5)
END;




Procedure HelKube(x1,y1,z1,x2,y2,z2 : Real);


TYPE   PunktTabell  = Array[1..8] of Punkt3D;


VAR    Punkt        : PunktTabell;
       EgenPos      : Punkt3D;
       Minste       : Punkt3D;
       i            : Byte;



   Procedure SettPunkt(VAR PunktX : Punkt3D; x1,y1,z1 : Real);

   BEGIN
      With PunktX do
         BEGIN
            x:=x1;
            y:=y1;
            z:=z1
         END
   END;



   Procedure MinsteAvstand(Ref : Punkt3D; VAR MiPunkt,Punkt : Punkt3D);

   VAR    Avst1        : Real;
          Avst2        : Real;
          Temp         : Punkt3D;

   BEGIN
      Avst1:=sqrt(sqr(ref.x-MiPunkt.x)+sqr(ref.y-MiPunkt.y)
                                      +sqr(ref.z-MiPunkt.z));
      Avst2:=sqrt(sqr(ref.x-Punkt.x)+sqr(ref.y-Punkt.y)+sqr(ref.z-Punkt.z));
      If Avst2<=Avst1 then
         MiPunkt:=Punkt
   END;



   Procedure FinnXPunkter(VAR Tabell : PunktTabell; Punkt : Punkt3D);

   VAR    i            : Byte;

   BEGIN
      For i:=1 to 8 do
         Tabell[i].Flagg:=Tabell[i].x=Punkt.x
   END;



   Procedure FinnYPunkter(VAR Tabell : PunktTabell; Punkt : Punkt3D);

   VAR    i            : Byte;

   BEGIN
      For i:=1 to 8 do
         Tabell[i].Flagg:=Tabell[i].y=Punkt.y
   END;



   Procedure FinnZPunkter(VAR Tabell : PunktTabell; Punkt : Punkt3D);

   VAR    i            : Byte;

   BEGIN
      For i:=1 to 8 do
         Tabell[i].Flagg:=Tabell[i].z=Punkt.z
   END;



   Procedure MarkerPlan(Tabell : PunktTabell);

   TYPE   PTabell      = Array[1..4] of Punkt3D;

   VAR    Punkter      : PTabell;
          i,j          : Byte;



      Procedure Sorter(VAR Tabell : PTabell);

      VAR    i            : Byte;



         Procedure ByttOm(VAR Element1,Element2 : Punkt3D);

         VAR    Temp         : Punkt3D;

         BEGIN
            Temp:=Element1;
            Element1:=Element2;
            Element2:=Temp
         END;



      BEGIN
         If (Tabell[1].x=Tabell[2].x) and (Tabell[2].x=Tabell[3].x) then
            For i:=1 to 3 do
               If (Tabell[i].y<>Tabell[i+1].y) and
                  (Tabell[i].z<>Tabell[i+1].z) then
                  ByttOm(Tabell[i+1],Tabell[i+2])
               else
         else if (Tabell[1].y=Tabell[2].y) and (Tabell[2].y=Tabell[3].y) then
            For i:=1 to 3 do
               If (Tabell[i].x<>Tabell[i+1].x) and
                  (Tabell[i].z<>Tabell[i+1].z) then
                  ByttOm(Tabell[i+1],Tabell[i+2])
               else
         else if (Tabell[1].z=Tabell[2].z) and (Tabell[2].z=Tabell[3].z) then
            For i:=1 to 3 do
               If (Tabell[i].x<>Tabell[i+1].x) and
                  (Tabell[i].y<>Tabell[i+1].y) then
                  ByttOm(Tabell[i+1],Tabell[i+2])
               else
      END;



   BEGIN
      j:=1;
      For i:=1 to 8 do
         If Tabell[i].Flagg then
            With Tabell[i] do
               BEGIN
                  Punkter[j].x:=Tabell[i].x;
                  Punkter[j].y:=Tabell[i].y;
                  Punkter[j].z:=Tabell[i].z;
                  Inc(j)
               END;
      Sorter(Punkter);
      For i:=1 to 3 do
         PLine3D(Punkter[i],Punkter[i+1]);
      PLine3D(Punkter[4],Punkter[1])
   END;



BEGIN
   SettPunkt(Punkt[1],x1,y1,z1);
   SettPunkt(Punkt[2],x2,y1,z1);
   SettPunkt(Punkt[3],x2,y1,z2);
   SettPunkt(Punkt[4],x1,y1,z2);
   SettPunkt(Punkt[5],x1,y2,z1);
   SettPunkt(Punkt[6],x2,y2,z1);
   SettPunkt(Punkt[7],x2,y2,z2);
   SettPunkt(Punkt[8],x1,y2,z2);
   SettPunkt(Minste,0,0,0);
   EgenPosXYZ(EgenPos);
   For i:=1 to 8 do
      MinsteAvstand(EgenPos,Minste,Punkt[i]);
   i:=0;
   Repeat
      Inc(i);
      Punkt[i].Flagg:=(Punkt[i].x=Minste.x) and
                      (Punkt[i].y=Minste.y) and
                      (Punkt[i].z=Minste.z)
   Until Punkt[i].Flagg;
   FinnXPunkter(Punkt,Punkt[i]);
   MarkerPlan(Punkt);
   FinnYPunkter(Punkt,Punkt[i]);
   MarkerPlan(Punkt);
   FinnZPunkter(Punkt,Punkt[i]);
   MarkerPlan(Punkt)
END;




Procedure EgenPosXYZ;

BEGIN
   With Punkt do
      BEGIN
         x:=2*r*sin(v2)*cos(v1);
         y:=2*r*sin(v2)*sin(v1);
         z:=2*r*cos(v2)
      END
END;




END.