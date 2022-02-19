unit mouse;

interface

const
  textmode = 0;
  graphmode = 1;

type
  str6 = string[6];

procedure resetmouse(var ismouse : boolean; var nbuttons : byte);
procedure showmouse;
procedure hidemouse;
procedure getmouse(var buttons : byte; var x,y : integer);
procedure mousegotoxy(x,y : word);
procedure getmousebuttons(var button : byte; var count,x,y : integer);
procedure getmousebuttonrelease(var button : byte; var count,x,y : integer);
procedure setlimitx(minx,maxx : word);
procedure setlimity(miny,maxy : word);
procedure setgraphcur(hx,hy : integer; address : pointer);
procedure settextcur(scrmask,curmask : word);

procedure initmouse(mousemode : byte);

function mousex : integer;
function mousey : integer;

implementation

uses
{$IFDEF UNIX}
    ptccrt,ptcgraph,ptcmouse,
{$ELSE}
    crt, graph,
{$ENDIF}
    dos;

{$IFDEF UNIX}
const
  global_width = 640;
  global_height = 480;
var
  limit_minx, limit_maxx, limit_miny, limit_maxy : integer;
{$ELSE}
var
  regs : registers;
{$ENDIF}

procedure resetmouse(var ismouse : boolean; var nbuttons : byte);
begin
{$IFDEF UNIX}
  ismouse := ptcmouse.initmouse;
  nbuttons := 3;
  limit_minx := 1; limit_maxx := global_width;
  limit_miny := 1; limit_maxy := global_height;
{$ELSE}
  regs.ax:=$00;
  intr($33,regs);
  ismouse:=odd(regs.ax);
  nbuttons:=regs.bx;
{$ENDIF}
end;

procedure showmouse;
begin
{$IFDEF UNIX}
  ptcmouse.showmouse;
{$ELSE}
  regs.ax:=$01;
  intr($33,regs);
{$ENDIF}
end;

procedure hidemouse;
begin
{$IFDEF UNIX}
  ptcmouse.hidemouse;
{$ELSE}
  regs.ax:=$02;
  intr($33,regs);
{$ENDIF}
end;

procedure getmouse(var buttons : byte; var x,y : integer);
var
  ptcx, ptcy, ptcbtn: longint;
begin
{$IFDEF UNIX}
  ptcmouse.getmousestate(ptcx, ptcy, ptcbtn);
  x := round(ptcx / global_width * (limit_maxx - limit_minx) + limit_minx);
  y := round(ptcy / global_height * (limit_maxy - limit_miny) + limit_miny);
  buttons := ptcbtn;
{$ELSE}
  regs.ax:=$03;
  intr($33,regs);
  with regs do
  begin
    buttons:=bl;
    x:=cx;
    y:=dx;
  end;
{$ENDIF}
end;

procedure mousegotoxy(x,y : word);
begin
{$IFDEF UNIX}
  x := round((x - limit_minx) / (limit_maxx - limit_minx) * global_width);
  y := round((y - limit_miny) / (limit_maxy - limit_miny) * global_height);
  ptcmouse.setmousepos(x, y);
{$ELSE}
  with regs do
  begin
    ax:=$04;
    cx:=x;
    dx:=y;
  end;
  intr($33,regs);
{$ENDIF}
end;

procedure getmousebuttons(var button : byte; var count,x,y : integer);
begin
{$IFDEF UNIX}
  getmouse(button, x, y);
{$ELSE}
  regs.ax:=$05;
  regs.bl:=button;
  intr($33,regs);
  with regs do
  begin
    button:=al;
    count:=bx;
    x:=cx;
    y:=dx;
  end;
{$ENDIF}
end;

procedure getmousebuttonrelease(var button : byte; var count,x,y : integer);
begin
{$IFNDEF UNIX}
  regs.ax:=$06;
  regs.bl:=button;
  intr($33,regs);
  with regs do
  begin
    button:=al;
    count:=bx;
    x:=cx;
    y:=dx;
  end;
{$ENDIF}
end;

procedure setlimitx(minx,maxx : word);
begin
{$IFDEF UNIX}
  limit_minx := minx;
  limit_maxx := maxx;
{$ELSE}
  with regs do
  begin
    ax:=$07;
    cx:=minx;
    dx:=maxx;
  end;
  intr($33,regs);
{$ENDIF}
end;

procedure setlimity(miny,maxy : word);
begin
{$IFDEF UNIX}
  limit_miny := miny;
  limit_maxy := maxy;
{$ELSE}
  with regs do
  begin
    ax:=$08;
    cx:=miny;
    dx:=maxy;
  end;
  intr($33,regs);
{$ENDIF}
end;

procedure setgraphcur(hx,hy : integer; address : pointer);
begin
{$IFNDEF UNIX}
  with regs do
  begin
    ax:=$09;
    bx:=word(hx);
    cx:=word(hy);
    es:=seg(address^);
    dx:=ofs(address^);
  end;
  intr($33,regs);
{$ENDIF}
end;

procedure settextcur(scrmask,curmask : word);
begin
{$IFNDEF UNIX}
  with regs do
  begin
    ax:=$0a;
    bx:=$00;
    cx:=scrmask;
    dx:=curmask;
  end;
  intr($33,regs);
{$ENDIF}
end;

procedure initmouse(mousemode : byte);
var
  ismouse  : boolean;
  nbuttons : byte;
begin
  resetmouse(ismouse,nbuttons);
{$IFDEF UNIX}
  ptcmouse.initmouse;
{$ENDIF}
  case mousemode of
    textmode : begin
                 setlimitx(1,632);
                 setlimity(1,195);
               end;
    graphmode : begin
                  setlimitx(0,getmaxx);
                  setlimity(0,getmaxy);
                end;
  end;
  showmouse;
end;

function mousex : integer;
var
  buttons: byte;
  x, y : integer;
begin
{$IFDEF UNIX}
  getmouse(buttons, x, y);
  mousex := x;
{$ELSE}
  regs.ax:=$03;
  intr($33,regs);
  mousex:=regs.cx;
{$ENDIF}
end;

function mousey : integer;
var
  buttons: byte;
  x, y : integer;
begin
{$IFDEF UNIX}
  getmouse(buttons, x, y);
  mousey := y;
{$ELSE}
  regs.ax:=$03;
  intr($33,regs);
  mousey:=regs.dx;
{$ENDIF}
end;

end.