unit SVGA;


INTERFACE


type  RGBRecord                 = record
        R                         : byte;
        G                         : byte;
        B                         : byte
      end;
      VGAPaletteType            = array[0..255] of RGBRecord;

var   VGA256DriverMode          : integer;
      VGA16DriverMode           : integer;
      graphDriver               : integer;
      graphMode                 : integer;


function getVideoMode : byte;

procedure initSVGAGraphics;

procedure setAllVGAPalette(var palette : VGAPaletteType);

procedure setOverScanColour(colour : integer);

procedure setBlackAndWhitePalette;

procedure setPaletteFromFile(fullPath : string);


IMPLEMENTATION

uses graph,dos;


function getVideoMode : byte;

var regs                        : registers;

begin
  regs.ah:=$0F;            (* Video BIOS Funktion $0F *)
  intr($10,regs);          (* Video BIOS aufrufen *)
  getVideoMode:=regs.al    (* AL enth„lt jetzt den aktuellen Videomodus *)
end;


{$F+} function autoDetectVGA16: integer {$F-};

begin
  autoDetectVGA16:=VGA16DriverMode
end;


{$F+} function autoDetectVGA256: integer {$F-};

begin
  autoDetectVGA256:=VGA256DriverMode
end;


procedure initSVGAGraphics;

var   driverNumber              : integer;
      errorCode                 : integer;

begin
  driverNumber:=installUserDriver('VGA16',@autoDetectVGA16);
  if (graphResult<>grOK) then
    begin
      writeLn('Fehler beim Installieren des BGI-Treibers VGA16.');
      halt(1)
    end;
  driverNumber:=installUserDriver('VGA256',@autoDetectVGA256);
  if (graphResult<>grOK) then
    begin
      writeLn('Fehler beim Installieren des BGI-Treibers VGA256.');
      halt(1)
    end;
  graphDriver:=detect;
  VGA256DriverMode:=28;
  VGA16DriverMode:=grError;
  initGraph(graphDriver,graphMode,'c:\language\tp6\bgi');
  errorCode:=graphResult;
  if (errorCode<>grOK) then
    begin
      writeLn('Fehler im Graphiksystem: ',graphErrorMsg(errorCode));
      halt(1)
    end
end;


procedure setAllVGAPalette(var palette : VGAPaletteType);

var   regs                      : registers;

begin
  regs.ax:=$1012;         (* VGA BIOS Funktion $10, Unterfunktion $12 *)
  regs.bx:=0;             (* erster Paletteneintrag *)
  regs.cx:=256;           (* Anzahl der Paletteneintr„ge *)
  regs.es:=seg(palette);  (* Segment-Addresse der Palettendaten *)
  regs.dx:=ofs(palette);  (* Offset-Addresse der Palettendaten *)
  intr($10,regs)          (* VGA BIOS aufrufen *)
end;


procedure setOverScanColour(colour : integer);

var   regs                      : registers;

begin
  regs.ax:=$1012;          (* VGA BIOS Funktion $10, Unterfunktion $01 *)
  regs.bh:=colour;         (* Bildschirmrandfarbe *)
  intr($10,regs)           (* VGA BIOS aufrufen *)
end;


procedure setBlackAndWhitePalette;

var   i                         : byte;
      aPalette                  : VGAPaletteType;

begin
  for i:=0 to 255 do
    begin
      aPalette[i].R:=i;
      aPalette[i].G:=i;
      aPalette[i].B:=i
    end;
  setAllVGAPalette(aPalette)
end;


procedure setPaletteFromFile(fullPath : string);

type  paletteArray              = array[1..768] of char;

var   paletteFile               : file;
      paletteBuffer             : paletteArray;
      aPalette                  : VGAPaletteType;
      i                         : byte;

begin
  assign(paletteFile,fullPath);
  {$I-}
  reset(paletteFile,1);
  {$I+}
  if (IOResult<>0) then
    begin
      closeGraph;
      writeLn('Palette file not found!');
      halt(1)
    end
  else
    begin
      blockRead(paletteFile,paletteBuffer,768);
      close(paletteFile);
      for i:=0 to 255 do
        begin
          aPalette[i].R:=ord(paletteBuffer[3*i+1]);
          aPalette[i].G:=ord(paletteBuffer[3*i+2]);
          aPalette[i].B:=ord(paletteBuffer[3*i+3])
        end;
      setAllVGAPalette(aPalette)
    end
end;


end.