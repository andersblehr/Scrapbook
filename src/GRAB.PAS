program Pbas2pcx;

{   Programm zur Steuerung des c't-Mini-Framegrabbers }
{   Version 1.0-PAS, Hans Windgassen                  }

uses
  crt, dos;

const
  videomode = $2e; {Videomode 640x480 in 256 F. ET 3/4000 }
  max_horiz = 640; {gewaehlte Aufloesung horizontal}
  max_verti = 480; {gewaehlte Aufloesung vertical}
  flag1     = 1;   {wenn 1 wird jeder zweite Punkt ignoriert}
  flag2     = 0;   {wenn 1 wird jede Zeile zweimal geschrieben}
  max_x     = 888; {ergibt sich aus: Quarzfrequenz * 0.000064}
  max_y     = 284; {max. Anzahl Zeilen}
  delay2    = 124; {Verzoegerung bis Bildanfang in Zeile 1}
  delay3    = 248; {Verz. zum Ausblenden der Synchronbalken}

  inport    = $320;   {Adresse des c't-Mini-Frame-Grabbers}
  outport   = $320;

  text1 : string =
'ESC = Stop, S = Save, H/D = heller/dunkler, +/- = Synch-Justage.';

  r         = $04; {Steuerbits fÅr Field-Memory }
  rstr      = $02; { nicht Ñndern  }
  srck      = $01;
  w         = $08;
  rstw      = $10;

type pcxheader=record
   indent, version, compress, bpp         : byte;
   xmin, ymin, xmax, ymax, h_dpi, v_dpi   : word;
   colpal                                 : array[1..48] of byte;
   res, planes                            : byte;
   b_per_line, pal_type                   : word;
   paldummy                               : array[1..58] of byte;
 end;

var
  pcx_hdr                             : pcxheader;
  pal                                 : array[0..768] of byte;
  regs                                : registers;
  taste                               : char;
  fi                                  : file;
  filename                            : string;
  oldmode, outdat, hori, verti_pixels,
  horiz_pixels, hell_offset, x, y, c,
  h_adr, v_adr, wert                  : integer;

  picturesSaved                       : word;

procedure grafic_on;
var x : integer;
begin
 {alten Videomode merken}
  regs.ah:=$0f; intr($10,regs); oldmode:=regs.al;
 {neuen Videomode einschalten}
  regs.al:=videomode; regs.ah:=0; intr($10,regs);
 {Palette setzen}
  for x:=0 to 63 do
    begin
     regs.ah:=$10; regs.al:=$10; regs.bx:=x; regs.dh:=x;
     regs.ch := x;   regs.cl := x;   intr($10,regs);

 {Palette fuers PCX File generieren}
     pal[(x*3)+1]:=x*4; pal[(x*3)+2]:=x*4;
     pal[(x*3)+3]:=x*4;
    end;
 {Palettenanfang markieren}
  pal[0]:=$0c;
end;

procedure grafic_off;
begin regs.al:=oldmode; regs.ah:=0; intr($10,regs); end;

procedure r_high;
begin outdat:=outdat or r; port[outport]:=outdat; end;

procedure r_low;
begin outdat:=outdat and not r; port[outport]:=outdat; end;

procedure srck_high;
begin outdat:=outdat or srck; port[outport]:=outdat; end;

procedure srck_low;
begin outdat:=outdat and not srck; port[outport]:=outdat; end;

procedure rstw_high;
begin outdat:=outdat or rstw; port[outport]:=outdat; end;

procedure rstw_low;
begin outdat:=outdat and not rstw; port[outport]:=outdat; end;

procedure w_high;
begin outdat:=outdat or w; port[outport]:=outdat; end;

procedure w_low;
begin outdat:=outdat and not w; port[outport]:=outdat; end;

procedure rstr_high;
begin outdat:=outdat or rstr; port[outport]:=outdat; end;

procedure rstr_low;
begin outdat:=outdat and not rstr; port[outport]:=outdat; end;

procedure srck_impuls;
begin srck_high; srck_low; end;

procedure res_read;                     {Reset Read-Memory}
begin
  rstr_high; srck_impuls; srck_impuls; srck_impuls; rstr_low;
end;

procedure write_mem;
begin                                   {write reset}
  rstw_high; rstw_low; w_high; w_low; rstw_high; rstw_low;
end;

procedure draw_picture;
begin
  r_high;                               { read enable             }
  res_read;                             { und Reset               }

  for c:=0 to delay2-1 do srck_impuls;  { Sync. Balken ausblenden }

  h_adr:=0; v_adr:=0;
  while v_adr <= verti_pixels do        { jetzt die Daten holen   }
  begin
    srck_high; wert:=port[inport]; srck_low; { Byte ins F-Memory  }

    wert:=wert+hell_offset;             { Helligkeitskorrektur    }
    wert:= (wert shr 2);                { Bit 0 und 1 verwerfen   }

    if flag1=1 then srck_impuls; { nur jeden 2ten Punkt wenn flg1 }

    regs.bh:=0; regs.ah:=$0c;           { jetzt den Punkt auf den }
    regs.cx:=h_adr; regs.dx:=v_adr;     { Bildschirm bringen      }
    regs.al:=wert; intr($10,regs);

    if flag2=1 then                     { wenn Flag2 jede Zeile   }
    begin                               { doppelt                 }
      regs.bh:=0; regs.ah:=$0c;
      regs.cx:=h_adr; regs.dx:=v_adr+1;
      regs.al:=wert; intr($10,regs);
    end;

    inc(h_adr);                         { naechster Punkt         }
    if h_adr=hori then                  { Ende der Zeile ?        }
    begin
      for c:=0 to delay3-1 do srck_impuls;{Sync.Balken ausblenden }
      h_adr:=0;                         {Horiz. Zeiger auf 0      }
      if flag2=1 then inc(v_adr);       {doppelscan               }
      inc(v_adr);                       {einmal in jedem Fall     }
    end;
  end;
  r_low;                                {r-Bit in Grundstellung   }
  res_read;
end;

function getpix(var x,y : word): byte;
begin
  regs.cx:=x; regs.dx:=y; regs.ah:=$0d; regs.bh:=0;
  intr($10,regs); getpix:=regs.al and $3f;
end;


function imageNumber : string;

var   numberAsString            : string;
      i                         : byte;

begin
  str(picturesSaved,numberAsString);
  for i:=1 to 3-length(numberAsString) do
    numberAsString:='0'+numberAsString;
  inc(picturesSaved);
  imageNumber:=numberAsString
end;


procedure beep;

begin
  sound(4000);
  delay(20);
  noSound
end;


procedure save_pic;

type  bufferType                = array[1..512] of byte;

var   fileName                  : string;
      pictureFile               : file;
      buffer                    : bufferType;
      i,j                       : word;

begin
  fileName:='c:\user\blehr\fag\diplom\bilder\image'+imageNumber+'.pic';
  assign(pictureFile,fileName);
  rewrite(pictureFile,1);
  buffer[1]:=hi(hori);
  buffer[2]:=lo(hori);
  buffer[3]:=hi(verti_pixels);
  buffer[4]:=lo(verti_pixels);
  blockWrite(pictureFile,buffer,4);
  for i:=1 to verti_pixels do
    begin
      for j:=1 to hori do
        buffer[j]:=getPix(j,i);
      blockWrite(pictureFile,buffer,hori)
    end;
  close(pictureFile)
end;


procedure save_pcx;
var
  x, y, z     : word;
  anz, b1, b2 : byte;
  label pcx1, pcx2, pcx3, pcx4, pcx5, pcx8, pcx9, pcx10, savepal;
begin
  filename:='c:\user\blehr\fag\diplom\bilder\pcx\image'+imageNumber+'.pcx';
  assign (fi,filename);
  rewrite(fi,1);

  {PCX - Header generieren und speichern}
  pcx_hdr.indent:=$0a;
  pcx_hdr.version:=5;
  pcx_hdr.compress:=1;
  pcx_hdr.bpp:=8;
  pcx_hdr.xmin:=0;
  pcx_hdr.ymin:=0;
  pcx_hdr.xmax:=hori-1;
  pcx_hdr.ymax:=verti_pixels-1;
  pcx_hdr.h_dpi:=300;
  pcx_hdr.v_dpi:=300;
  pcx_hdr.res:=0;
  pcx_hdr.planes:=1;
  pcx_hdr.b_per_line:=hori;
  pcx_hdr.pal_type:=1;
  for c:=1 to 48 do pcx_hdr.colpal[c]:=0;
  for c:=1 to 58 do pcx_hdr.paldummy[c]:=0;
  blockwrite(fi,pcx_hdr,sizeof(pcx_hdr));

  {jetzt das Bild vom Schirm im PCX-Format speichern}
   y:=0;
  pcx1:
   x:=0;
  pcx2:
   anz:=1;
   b1:=getpix(x,y) and $3f;
   inc(x); if x=hori then goto pcx4;
  pcx3:
   inc(x); b2:=getpix(x,y) and $3f; dec(x);
   if b1=b2 then goto pcx5;
   if anz <> 1 then
     begin
       anz:=anz or $c0; blockwrite(fi,anz,1); anz:=1;
     end;
   blockwrite(fi,b1,1);
  pcx8:
   b1:=b2;
   inc(x);
   if x <> hori then goto pcx3;
   if anz <> 1 then
     begin
       anz:=anz or $c0; blockwrite(fi,anz,1); anz:=1;
     end;
  pcx9:
   blockwrite(fi,b1,1);
  pcx10:
   inc(y);
   if y=verti_pixels then goto savepal;
   goto pcx1;
  pcx5:
   inc(anz);
   if anz<>63 then goto pcx8;
   anz:=anz or $c0; blockwrite(fi,anz,1); blockwrite(fi,b1,1);
   anz:=1;
   inc(x); if x=hori then goto pcx10;
   goto pcx2;
  pcx4:
   if anz <> 1 then
     begin
       anz:=anz or $c0; blockwrite(fi,anz,1); anz:=1;
     end;
   goto pcx9;

  {Paletten Info anhaengen}
  savepal:
  blockwrite(fi,pal,sizeof(pal));
  close(fi);
end;

   { * * * Hauptprogramm * * * }
begin
{Initialisierungsteil}
 {Port in Grundstellung bringen}
  outdat:=0; port[outport]:=outdat;

 {150 "Dummy" Leseimpulse ausgeben}
  r_high; for c:=0 to 150 do srck_impuls; r_low; res_read;

{ Die ZÑhler fÅr das Bildformat vorbereiten.                 }
{ "hori" erhaelt die Anzahl Punkte die das Bild in der       }
{ Horizontalen aufweisen soll. Die H-Synchronbalken          }
{ muessen dazu abgezogen werden.                             }
  hori := max_x - delay3;
  if flag1=1 then hori:=hori div 2;

{ "verti" erhaelt die Anzahl Punkte (=Zeilen) die das Bild   }
{ in der Vertikalen aufweisen soll.                          }
  if flag2=1
    then verti_pixels:=max_y * 2
    else verti_pixels:=max_y;
  if verti_pixels > max_verti
    then verti_pixels:= max_verti;

  hell_offset:=0;           {keine Manipulation der Grauwerte}

  for c:=0 to sizeof(pal)-1 do pal[c]:=$c7;  {Palette fuellen}

  picturesSaved:=0;

  grafic_on;

 {Bedienungsanleitung einblenden}
  regs.bh:=0;  regs.ah:=$13; regs.cx:=length(text1);
  regs.dh:=24; regs.dl:=1;   regs.al:=0;
  regs.es:=seg(text1); regs.bp:=ofs(text1[1]);
  intr($10,regs);

 {Jetzt kommt die Hauptroutine}
  taste:=' ';
  beep;
  delay(4500);
  repeat
    if not keypressed then
    begin
      write_mem;                             {lese BAS Signal}
      draw_picture;              {Bild auf den Schirm bringen}
      beep
    end
    else
    begin
      taste:=upcase(readkey);
      beep;
      beep;
      if taste = '+' then inc(hori);
      if taste = '-' then dec(hori); if hori = 0 then hori:=0;
      if taste = 'S' then save_pic;
      if taste = 'H' then hell_offset:=hell_offset+4;
      if taste = 'D' then hell_offset:=hell_offset-4;
    end;
  until ord(taste)= 27;
  grafic_off;
end.
