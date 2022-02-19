unit sprites;

interface

const
  drawblack = true;
  dontdrawblack = false;

type

  tbytearray = array[0..65534] of byte;

  pbytearray = ^tbytearray;

  tsprite = record
    width,height : integer;
    data         : pbytearray;
  end;

procedure createsprite(var sprite : tsprite; width,height : integer);
procedure freesprite(var sprite : tsprite);
procedure getsprite(var sprite : tsprite; x1,y1,x2,y2 : integer);
procedure drawsprite(var sprite : tsprite; x,y : integer; db : boolean);
procedure savespriteinfile(sprite : tsprite; fn : string);
procedure loadspritefromfile(var sprite : tsprite; fn : string);
procedure rotatesprite(alpha : real; var sprite : tsprite);
procedure eqsprites(var spr1,spr2 : tsprite);

implementation

uses 
{$IFDEF UNIX}
    ptcgraph
{$ELSE}
    graph
{$ENDIF}
    ;

procedure eqsprites(var spr1,spr2 : tsprite);
var
  i : integer;
begin
  if (spr1.height=spr2.height) and (spr1.width=spr2.width) then
    for i:=0 to spr1.height*spr1.width do
      spr2.data^[i]:=spr1.data^[i];
end;

procedure createsprite(var sprite : tsprite; width,height : integer);
begin
  if sprite.data<>nil then
    freesprite(sprite);
  sprite.width:=width;
  sprite.height:=height;
  getmem(sprite.data,width*height);
end;

procedure freesprite(var sprite : tsprite);
begin
  with sprite do
  begin
    freemem(data,width*height);
    width:=0;
    height:=0;
    data:=nil;
  end;
end;

procedure getsprite(var sprite : tsprite; x1,y1,x2,y2 : integer);
var
  index,x,y : integer;
begin
  createsprite(sprite,x2-x1+1,y2-y1+1);
  index:=0;
  for y:=y1 to y2 do
    for x:=x1 to x2 do
    begin
      sprite.data^[index]:=getpixel(x,y);
      inc(index);
    end;
end;

procedure drawsprite(var sprite : tsprite; x,y : integer; db : boolean);
var
  index,xi,yi : integer;
begin
  index:=0;
  for yi:=0 to sprite.height-1 do
    for xi:=0 to sprite.width-1 do
    begin
      if not ((db=false) and (sprite.data^[index]=black)) then
        putpixel(xi+x,yi+y,sprite.data^[index]);
      inc(index);
    end;
end;

procedure savespriteinfile(sprite : tsprite; fn : string);
var
  f : file;
begin
  assign(f,fn);
  rewrite(f,1);
  blockwrite(f,sprite.height,2);
  blockwrite(f,sprite.width,2);
  blockwrite(f,sprite.data^,sprite.height*sprite.width);
  close(f);
end;

procedure loadspritefromfile(var sprite : tsprite; fn : string);
var
  f : file;
  h,w : word;
  r : byte;
begin
{$IFDEF UNIX}
  for h := 1 to length(fn) do
    fn[h] := lowercase(fn[h]);
{$ENDIF}
  assign(f,fn);
{$I-}
  reset(f,1);
{$I+}
  r:=ioresult;
  if r<>0 then
  begin
    closegraph;
    writeln('FILE ',fn,' OPEN ERROR N',r);
    readln;
    readln;
    halt;
  end;
  blockread(f,h,2);
  blockread(f,w,2);
  createsprite(sprite,w,h);
  blockread(f,sprite.data^,sprite.height*sprite.width);
  close(f);
end;

procedure rotatesprite(alpha : real; var sprite : tsprite);
var
  spr     : tsprite;
  x,y,xx,yy : longint;
  x1,y1,x2,y2,x10,x20,y10,y20,r,p,mx,my : real;
begin
  spr.data:=nil;
  createsprite(spr,sprite.width,sprite.height);
  for x:=0 to spr.width-1 do
  for y:=0 to spr.height-1 do
    spr.data^[y*spr.width+x]:=black;
  mx:=spr.width;
  my:=spr.height;
  for x:=0 to spr.width-1 do
    for y:=0 to spr.height-1 do
    begin
      x1:=x;
      y1:=y;
      x10:=x1-(mx/2);
      y10:=-y1+(my/2);
      if (abs(x10)>0.1) then
        p:=arctan(y10/x10) else
        p:=pi/2;
      if (x10<0) then
        p:=p+pi;
      r:=sqrt(sqr(x10)+sqr(y10));
      x20:=r*cos(alpha-p);
      y20:=r*sin(alpha-p);
      x2:=x20+(mx/2);
      y2:=-y20+(my/2);
      xx:=round(x2);
      yy:=round(y2);
      if (xx in [0..sprite.width-1]) and (yy in [0..sprite.height-1]) then
        spr.data^[yy*spr.width+xx]:=sprite.data^[y*spr.width+x];
    end;
  eqsprites(spr,sprite);
  freesprite(spr);
end;

end.