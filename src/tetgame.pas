unit tetgame;

interface
uses 
{$IFDEF UNIX}
    sysutils,ptccrt,ptcgraph,
{$ELSE}
    crt,graph,
{$ENDIF}
    sprites,mouse,tetun,music;

const
  blocksize = 20;
  width = 12;
  height = 22;
  k = 17.8;
  bgcolor = darkgray;
  nevents = 30;
  left = 0;
  right = 1;
  novozd = 1;
  full = 2;
  dead = 3;
  maxn = 25;
  gentrn = 30;

type

  tplayer = record
    scores : longint;
    speed  : integer;
    diff   : byte;
    vozd   : integer;
    cx,cy  : integer;
  end;

  tgevent = record
    wevent : byte;
    i      : longint;
    time   : longint;
  end;

  tpole = array[1..width,1..height] of byte;

  tevents = array[1..nevents] of tgevent;

var
  pole   : tpole;
  figs   : array[1..3*7] of figmat;
  player : tplayer;
{$IFNDEF UNIX}
  timer  : longint absolute $0000:$046c;
{$ENDIF}
  fg,nfg : tfigure;
  events : tevents;
  fx,fy  : integer;
  gocode : byte;
  mus,rotmus,downmus,movmus,upmus,lifemus : tmusic;
  nnot   : integer;
  bars   : array[1..15] of tsprite;
  screen : tsprite;
  dels   : longint;
  spd    : real;
  demo   : boolean;

{$IFDEF UNIX}
function timer : longint;
{$ENDIF}
procedure game(dem : boolean);
procedure maindraw;
procedure initgame;
procedure drawscores;
procedure drawspeed;
procedure drawpole;
procedure drawvozd(dvozd : integer);
procedure mydelay(s100 : longint);
procedure drawnext;
procedure drawfig(x0,y0 : integer; fig : tfigure; del : byte);
procedure gamegetevent(gevents : boolean);
procedure putevent(tt : real; i : longint; t : byte);
procedure movefig(where : byte);
procedure movfig(where : byte);
procedure initfig(var f : tfigure);
procedure putnewfg(fg : tfigure);
procedure rotfig(orient : byte; var fig : tfigure);
procedure rotate(orient : byte);
function canmove(where : byte) : boolean;
function canrotate(orient : byte) : boolean;
procedure down;
procedure eraser;
procedure drawten(del : byte);
procedure delevent(ev : byte);
procedure gameover;
procedure drawcreature(del : byte);
procedure movecreat;
function canbreath : boolean;
procedure testvozd;
procedure pause;
procedure esc;
procedure playmusic(m : tmusic; paused : boolean);
procedure playnot;
procedure genturn(x,t : byte);
function rait(next : boolean) : longint;
function minnextrait : longint;
procedure rotatef(orient : byte);

implementation

{$IFDEF UNIX}
function timer : longint;
var
  ts : tdatetime;
begin
  ts := now;
  timer := round(ts * 86400.0 * 1000.0 / 55.0);
end;
{$ENDIF}
procedure rotatef(orient : byte);
var
  x,y : integer;
  a   : byte;
begin
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      a:=pole[fx+x-1,fy+y-1];
      pole[fx+x-1,fy+y-1]:=0;
    end;
  rotfig(orient,fg);
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
      pole[fx+x-1,fy+y-1]:=a;
end;

function minnextrait : longint;
var
  spole    : tpole;
  sfx,sfy  : integer;
  i,o,u    : longint;
  x,y      : integer;
  sf       : tfigure;
  m        : longint;
  d        : byte;
begin
  spole:=pole;
  sfx:=fx;
  sfy:=fy;
  sf:=fg;
  fg:=nfg;
  fy:=1;
  fx:=round(width/2)-2;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      if pole[fx+x-1,fy+y-1]<>0 then
      begin
        minnextrait:=10000000;
        pole:=spole;
        fx:=sfx;
        fy:=sfy;
        fg:=sf;
        exit;
      end;
      pole[fx+x-1,fy+y-1]:=fg.col;
    end;
  if canmove(2)=false then
  begin
    minnextrait:=10000000;
    pole:=spole;
    fx:=sfx;
    fy:=sfy;
    fg:=sf;
    exit;
  end;
  d:=0;
  for u:=1 to 4 do
  begin
    if canrotate(right)=false then
    begin
      if canmove(2)=true then
        movfig(2);
      inc(d);
    end;
    if (canrotate(right)=false) and (d>2) then
      break else
      rotatef(right);
  end;
  while canmove(1)=true do
    movfig(1);
  m:=rait(false);
  for u:=0 to 3 do
  begin
    o:=rait(false);
    if o<m then
      m:=o;
    while canmove(3)=true do
    begin
      movfig(3);
      o:=rait(false);
      if o<m then
        m:=o;
    end;
    i:=0;
    while canrotate(right)=false do
    begin
      if canmove(1)=true then
        movfig(1);
      inc(i);
      if i>5 then break;
    end;
    if canrotate(right)=true then
      rotatef(right) else break;
    while canmove(1)=true do
      movfig(1);
  end;
  pole:=spole;
  fx:=sfx;
  fy:=sfy;
  fg:=sf;
  minnextrait:=m;
end;

function rait(next : boolean) : longint;
const
  puz = 80;
  h   = 7;
  lr  = 2;
  nr  = 0.8;
  rd  = -100;

var
  x,y,i,e : integer;
  a,b,c   : boolean;
  rr      : longint;
  spole   : tpole;
  sfx,sfy : integer;
  dd      : integer;
  ner     : array[0..width+1] of integer;

procedure delete(y0 : integer);
var
  x,y : integer;
begin
  for y:=y0 downto 2 do
  for x:=1 to width do
    pole[x,y]:=pole[x,y-1];
  for x:=1 to width do
    pole[x,1]:=0;
end;

begin
  spole:=pole;
  sfx:=fx;
  sfy:=fy;
  rr:=0;
  while canmove(2)=true do
    movfig(2);
  repeat
    for y:=height downto 1 do
    begin
      b:=true;
      for x:=1 to width do
        if pole[x,y]=0 then b:=false;
      if b=true then
      begin
        delete(y);
        rr:=rr+rd;
        break;
      end;
    end;
  until b=false;
  dd := 0;
  for y:=1 to 4 do
  begin
    for x:=1 to 4 do
      if fg.fig[x,y]=true then break;
    if fg.fig[x,y]=true then break else
      dd:=dd+1;
  end;
  rr:=rr+(height-fy-(y-2))*h;
  for x:=1 to width do
  begin
    ner[x]:=height;
    a:=true;
    for y:=1 to height do
      if (pole[x,y]=0) and (a=true) then ner[x]:=ner[x]-1 else
        a:=false;
  end;
  if ner[2]<ner[1] then
    ner[0]:=ner[1] else
    ner[0]:=ner[2];
  if ner[width]>ner[width-1] then
    ner[width+1]:=ner[width] else
    ner[width+1]:=ner[width-1];
  for x:=1 to width-1 do
  begin
    rr:=rr+lr*abs(ner[x]-ner[x+1]);
    if (ner[x-1]-ner[x]>=3) and (ner[x+1]-ner[x]>=3) then
      rr:=rr+lr*7*((ner[x-1]-ner[x]) div 4 + 1)*((ner[x+1]-ner[x]-2) div 4 + 1);
  end;
  for y:=height downto 2 do
  begin
    b:=true;
    a:=true;
    for x:=1 to width do
    begin
      c:=true;
      e:=0;
      for i:=y-1 downto 2 do
        if pole[x,i]<>0 then
        begin
          b:=false;
          c:=false;
          e:=e+1;
        end;
      if (pole[x,y]=0) and (c=false) and (a=true) then
      begin
        rr:=rr+puz;
        a:=false;
      end;
    end;
    if b=true then break;
  end;
  if next=true then
    rr:=rr+round(minnextrait*nr);
  rait:=rr;
  pole:=spole;
  fx:=sfx;
  fy:=sfy;
{  setfillstyle(1,lightgreen);
  bar(1,1,50,10);
  str(rr,s);
  outtextxy(5,3,s);
  if readkey=#27 then halt;}
end;

procedure genturn(x,t : byte);
var
  spole    : tpole;
  sfx,sfy  : integer;
  i,o,u    : longint;
  sf       : tfigure;
  tx,tt,m  : longint;
  r        : real;
  d        : byte;
begin
  spole:=pole;
  sfx:=fx;
  sfy:=fy;
  sf:=fg;
  d:=0;
  r:=0;
  if canmove(2)=false then
  begin
    putevent(r,keyb[6],keypress);
    exit;
  end;
  for u:=1 to 4 do
  begin
    if canrotate(right)=false then
    begin
      if canmove(2)=true then
        movfig(2);
      inc(d);
    end;
    if (canrotate(right)=false) and (d>2) then
      break else
      rotatef(right);
  end;
  while canmove(1)=true do
    movfig(1);
  tx:=fx;
  tt:=0;
  m:=rait(true);
  for u:=0 to 3 do
  begin
    o:=rait(true);
    if o<m then
    begin
      tx:=fx;
      tt:=u;
      m:=o;
    end;
    while canmove(3)=true do
    begin
      movfig(3);
      o:=rait(true);
      if o<m then
      begin
        tx:=fx;
        tt:=u;
        m:=o;
      end;
    end;
    i:=0;
    while canrotate(right)=false do
    begin
      if canmove(1)=true then
        movfig(1);
      inc(i);
      if i>5 then break;
    end;
    if canrotate(right)=true then
      rotatef(right);
    while canmove(1)=true do
      movfig(1);
  end;

  pole:=spole;
  fx:=sfx;
  fy:=sfy;
  fg:=sf;
{  drawpole;

  setfillstyle(1,lightgreen);
  bar(1,1,50,10);
  str(m,s);
  outtextxy(5,3,s);
  if readkey=#27 then halt;}

  delevent(keypress);
  x:=tx;
  t:=tt;
  r:=spd;
  for i:=1 to d do
  begin
    putevent(r,keyb[3],keypress);
    r:=r+spd;
  end;
  if tt<3 then
  for i:=1 to tt do
  begin
    putevent(r,keyb[4],keypress);
    r:=r+spd;
  end else
    putevent(r,keyb[5],keypress);
  if tx>fx then
  for i:=fx to (tx-1) do
  begin
    putevent(r,keyb[2],keypress);
    r:=r+spd;
  end else
  for i:=(tx+1) to fx do
  begin
    putevent(r,keyb[1],keypress);
    r:=r+spd;
  end;
  putevent(r,keyb[6],keypress);
end;

procedure playnot;
begin
  if nnot>mus.size then
    nosound else
  begin
    sound(mus.data^[nnot-1].hz);
    putevent(mus.data^[nnot-1].dl/100,0,playnote);
    inc(nnot);
  end;
end;

procedure playmusic(m : tmusic; paused : boolean);
var
  i : integer;
begin
  if options.sound=false then exit;
  if paused=true then
  begin
    for i:=1 to m.size do
    begin
      sound(m.data^[i-1].hz);
      mydelay(m.data^[i-1].dl);
    end;
    nosound;
  end else
  begin
    mus:=m;
    nnot:=1;
    delevent(playnote);
    playnot;
  end;
end;

procedure esc;
var
  x     : integer;
  tt    : longint;
  sevs  : tevents;
  s     : string;
  el    : boolean;
procedure drawbb;
begin
  setfillstyle(1,white);
  bar(95,250,305,280);
  myouttext(200-40,260,'Да',el,right);
  myouttext(200+40,260,'Нет',not el,left);
  if el=true then
    putlabel(200-40-8*2-2,250,200-40+18,277) else
    putlabel(200+40-10,250,200+40+8*3+10,277);
end;
begin
  el:=false;
  tt:=timer;
  sevs:=events;
  setfillstyle(1,bgcolor);
  bar(80,460-height*blocksize,80+width*blocksize,460);
  setfillstyle(1,white);
  bar(90,200,310,288);
  setcolor(blue);
  setlinestyle(0,0,3);
  rectangle(90,200,310,288);
  setcolor(red);
  s:='Вы действительно';
  outtextxy(200-length(s)*4,220,s);
  s:='хотите выйти?';
  outtextxy(200-length(s)*4,230,s);
  drawbb;
  repeat
    gamegetevent(false);
    if (event.what=keypress) and ((event.key=$FF*75) or (event.key=$FF*77)) then
    begin
      el:=not el;
      drawbb;
    end;
  until (event.what=keypress) and ((event.key=13) or (event.key=27));
  if event.key=27 then el:=true;
  if el=true then
    event.what:=loose else
  begin
    event.what:=nothing;
    drawpole;
    drawten(0);
  end;
  for x:=1 to nevents do
  if events[x].wevent<>nothing then
    events[x].time:=sevs[x].time+(timer-tt);
end;

procedure pause;
var
  x     : integer;
  tt    : longint;
  sevs  : tevents;
begin
  tt:=timer;
  sevs:=events;
  nosound;
  setfillstyle(1,bgcolor);
  bar(80,460-height*blocksize,80+width*blocksize,460);
  setfillstyle(1,white);
  bar(90,200,310,288);
  setcolor(blue);
  setlinestyle(0,0,3);
  rectangle(90,200,310,288);
  setcolor(red);
  outtextxy(200-36,220,'П А У З А');
  outtextxy(200-92,240,'Для продолжения нажмите');
  setcolor(lightred);
  outtextxy(200-20,260,'ENTER');
  repeat
    if ((timer-tt) mod 5) = 0 then
    begin
      if (((timer-tt) div 5) mod 2) = 1 then
        setcolor(white) else
        setcolor(red);
      outtextxy(200-36,220,'П А У З А');
    end;
    gamegetevent(false);
  until (event.what=keypress) and (event.key=13);
  event.what:=nothing;
  drawpole;
  drawten(0);
  for x:=1 to nevents do
  if events[x].wevent<>nothing then
    events[x].time:=sevs[x].time+(timer-tt);
end;

procedure testvozd;
begin
  if canbreath=false then
  begin
    drawvozd(1);
    if player.vozd>100 then
    begin
      event.what:=loose;
      gocode:=novozd;
    end;
    putevent(0.8,0,getvozd);
  end else
  begin
    drawvozd(-1);
    if player.vozd<0 then
      player.vozd:=0 else
      putevent(0.1,0,getvozd);
  end;
end;

function canbreath : boolean;
var
  pp  : tpole;
  x,y : integer;
  b   : boolean;
begin
  if (options.life=false) or (demo=true) then
  begin
    canbreath:=true;
    exit;
  end;
  pp:=pole;
  pp[player.cx,player.cy]:=99;
  repeat
    b:=true;
    for x:=1 to width do
    for y:=1 to height do
    begin
      if (pp[x,y]=99) and (pp[x-1,y]=0) and (x-1>0) then
      begin
        pp[x-1,y]:=99;
        b:=false;
      end;
      if (pp[x,y]=99) and (pp[x+1,y]=0) and (x+1<=width) then
      begin
        pp[x+1,y]:=99;
        b:=false;
      end;
      if (pp[x,y]=99) and (pp[x,y-1]=0) and (y-1>0) then
      begin
        pp[x,y-1]:=99;
        b:=false;
      end;
      if (pp[x,y]=99) and (pp[x,y+1]=0) and (y+1<=height) then
      begin
        pp[x,y+1]:=99;
        b:=false;
      end;
    end;
  until b=true;
  b:=false;
  for x:=1 to width do
    if pp[x,1]=99 then b:=true;
  canbreath:=b;
end;

procedure movecreat;
var
  dx,dy : integer;

function canmove : boolean;
begin
  dy:=1;
  if (pole[player.cx+dx,player.cy]=0) and
     (player.cx+dx>0) and
     (player.cx+dx<=width) then
       dy:=0;
  if (pole[player.cx+dx,player.cy-1]=0) and
     (pole[player.cx+dx,player.cy]<>0) and
     (pole[player.cx,player.cy-1]=0) and
     (player.cy-1>0) and
     (player.cx+dx>0) and
     (player.cx+dx<=width) then
       dy:=-1;
  canmove:=(dy<>1);
end;

procedure downcreat;
begin
  while (player.cy+dy<height) and (pole[player.cx+dx,player.cy+dy+1]=0) do
    dy:=dy+1;
end;

begin
  if random(2)=0 then
    dx:=1 else
    dx:=-1;
  if canmove=false then
    dx:=0-dx;
  if canmove=false then exit;
  playmusic(lifemus,false);
  downcreat;
  drawcreature(1);
  player.cx:=player.cx+dx;
  player.cy:=player.cy+dy;
  drawcreature(0);
end;

procedure drawcreature(del : byte);
begin
  if del=1 then
  begin
    setfillstyle(1,bgcolor);
    with player do
      bar(80+blocksize*(cx-1),460+blocksize*(cy-1-height),80+blocksize*cx,460+blocksize*(cy-height));
    drawten(0);
    exit;
  end;
  with player do
    drawsprite(creature,80+blocksize*(cx-1),460+blocksize*(cy-1-height),dontdrawblack);
end;

procedure gameover;
var
  tt    : longint;
  s     : string;
begin
  nosound;
  tt:=timer;
  setfillstyle(1,white);
  bar(90,180,310,288);
  setcolor(blue);
  setlinestyle(0,0,3);
  rectangle(90,180,310,288);
  setcolor(red);
  case gocode of
    nothing : s:='Спасибо за игру!';
    novozd  : s:='Задохнулся, бедолага...';
    dead    : s:='Придавили несчастного...';
    full    : s:='Стакан переполнен!';
  end;
  if demo=true then
    s:='Спасибо за внимание!';
  outtextxy(200-length(s)*4,200,s);
  setcolor(blue);
  s:='Игра окончена!';
  outtextxy(200-length(s)*4,220,s);
  str(player.scores,s);
  if demo=false then
    s:='Вы набрали '+s+' очк' else
    s:='Мой результат: '+s+' очк';
  case (player.scores mod 10) of
    1    : s:=s+'о';
    2..4 : s:=s+'а';
    else s:=s+'ов';
  end;
  outtextxy(200-length(s)*4,240,s);
  s:='Нажмите ENTER';
  outtextxy(200-length(s)*4,260,s);
  repeat
    if ((timer-tt) mod 5) = 0 then
    begin
      if (((timer-tt) div 5) mod 2) = 1 then
        setcolor(white) else
        setcolor(blue);
      outtextxy(200-length(s)*4,260,s);
    end;
    gamegetevent(false);
  until (event.what=keypress) and (event.key=13);
  event.what:=nothing;
end;

procedure delevent(ev : byte);
var
  i : integer;
begin
  for i:=1 to nevents do
    if events[i].wevent=ev then
      events[i].wevent:=nothing;
end;

procedure drawten(del : byte);
var
  x,y,a,fy1,fx1 : integer;
  pl      : tpole;
begin
  if options.ten=false then exit;
  pl:=pole;
  fx1:=fx;
  fy1:=fy;
  while canmove(2)=true do
  begin
    for x:=1 to 4 do
    for y:=1 to 4 do
      if fg.fig[x,y]=true then
      begin
        a:=pole[fx+x-1,fy+y-1];
        pole[fx+x-1,fy+y-1]:=0;
      end;
    fy:=fy+1;
    for x:=1 to 4 do
    for y:=1 to 4 do
      if fg.fig[x,y]=true then
        pole[fx+x-1,fy+y-1]:=a;
  end;
  if del=1 then
    drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,1) else
    drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,2);
  pole:=pl;
  fx:=fx1;
  fy:=fy1;
  if (options.life=true) and (del=1) and (demo=false) then
    drawcreature(0);
  drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,0);
end;

procedure drawpole;
var
  x,y : integer;
begin
  setfillstyle(1,bgcolor);
  bar(80,460-height*blocksize,80+width*blocksize,460);
  setcolor(white);
  setlinestyle(0,0,3);
  for x:=1 to width do
  for y:=1 to height do
  if pole[x,y]<>0 then
  begin
    setfillstyle(1,pole[x,y]);
    bar(80+(x-1)*blocksize+2,460-height*blocksize+(y-1)*blocksize+2,80+x*blocksize-2,460-height*blocksize+y*blocksize-2);
    rectangle(80+(x-1)*blocksize+2,460-height*blocksize+(y-1)*blocksize+2,80+x*blocksize-2,460-height*blocksize+y*blocksize-2);
    drawsprite(bars[pole[x,y]],80+(x-1)*blocksize,460-height*blocksize+(y-1)*blocksize,dontdrawblack);
  end;
  if (options.life=true) and (demo=false) then
    drawcreature(0);
end;

procedure eraser;

var
  k : byte;

procedure delete(y0 : integer);
var
  x,y,i,e,o : integer;
begin
  setfillstyle(1,bgcolor);
  x:=80+round(width*blocksize/2);
  y:=460-round((height-y0+0.5)*blocksize);
  e:=random(8);
  setcolor(bgcolor);
  setlinestyle(0,0,3);
  for i:=1 to round(blocksize/2)-1 do
  begin
    if options.sound=true then
      sound(1000-i*50);
    case e of
      0 : bar(x-i*width,y-i,x+i*width,y+i);
      1 : for o:=1 to width do
            bar(80+(o-1)*blocksize,460-(height-y0)*blocksize,80+(o-1)*blocksize+i*2,460-(height-y0+1)*blocksize);
      2 : bar(80,y-i,80+width*blocksize,y+i);
      3 : for o:=1 to width do
            bar(80+o*blocksize,460-(height-y0)*blocksize,80+o*blocksize-i*2,460-(height-y0+1)*blocksize);
      4 : for o:=1 to width do
            bar(80+(o-1)*blocksize,460-(height-y0)*blocksize,80+o*blocksize,460-(height-y0)*blocksize-i*2);
      5 : for o:=1 to width do
            if (o mod 2) = 1 then
              bar(80+(o-1)*blocksize,460-(height-y0+1)*blocksize,80+o*blocksize,460-(height-y0+1)*blocksize+i*2) else
              bar(80+(o-1)*blocksize,460-(height-y0)*blocksize,80+o*blocksize,460-(height-y0)*blocksize-i*2);
      6 : for o:=1 to width-1 do
            bar(80+o*blocksize-i,460-(height-y0)*blocksize,80+o*blocksize+i,460-(height-y0+1)*blocksize);
      7 : for o:=1 to width do
            bar(80+(o-1)*blocksize+round(blocksize/2)-i,460-(height-y0)*blocksize-round(blocksize/2)-i,
                80+(o-1)*blocksize+round(blocksize/2)+i,460-(height-y0)*blocksize-round(blocksize/2)+i);
    end;
    mydelay(3);
  end;
  nosound;

  for y:=y0 downto 2 do
  for x:=1 to width do
    pole[x,y]:=pole[x,y-1];
  for x:=1 to width do
    pole[x,1]:=0;
  if (options.life = true) and (demo = false) then
    while (player.cy<height) and (pole[player.cx,player.cy+1]=0) do
      inc(player.cy);
  drawpole;
  player.scores:=player.scores+10+k*5;
  drawscores;
  inc(dels);
  if (((dels div maxn)+1)>player.speed) and ((dels div maxn)+1<=maxspeed) then
  begin
    player.speed:=(dels div maxn)+1;
    spd:=(maxspeed+minspeed-player.speed)*0.02;
    drawspeed;
    playmusic(upmus,true);
  end;
end;

var
  x,y   : integer;
  b     : boolean;
begin
  k:=0;
  repeat
    for y:=height downto 1 do
    begin
      b:=true;
      for x:=1 to width do
        if pole[x,y]=0 then b:=false;
      if b=true then
      begin
        delete(y);
        break;
      end;
    end;
    k:=k+1;
  until b=false;
end;

procedure down;
begin
  while (canmove(2)=true) and (event.what<>loose) do
    movefig(2);
  if event.what<>loose then
    movefig(2);
  playmusic(downmus,false);
end;

procedure rotfig(orient : byte; var fig : tfigure);
var
  x,y : integer;
  ff  : tfigure;
begin
  if orient=right then
  begin
    for x:=1 to 4 do
    for y:=1 to 4 do
      ff.fig[5-y,x]:=fig.fig[x,y];
  end else
  begin
    for x:=1 to 4 do
    for y:=1 to 4 do
      ff.fig[x,y]:=fig.fig[5-y,x];
  end;
  fig.fig:=ff.fig;
end;

function canrotate(orient : byte) : boolean;
var
  x,y : integer;
  b   : boolean;
  a   : byte;
  ff  : tfigure;
begin
  b:=true;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      a:=pole[fx+x-1,fy+y-1];
      pole[fx+x-1,fy+y-1]:=0;
    end;
  ff:=fg;
  rotfig(orient,ff);
  for x:=1 to 4 do
  for y:=1 to 4 do
    if (ff.fig[x,y]=true) and ((pole[fx+x-1,fy+y-1]<>0) or
       ((fx+x-1)>width) or ((fx+x-1)<1) or
       ((fy+y-1)>height) or ((fy+y-1)<1)) then
    begin
      b:=false;
      break;
    end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
      pole[fx+x-1,fy+y-1]:=a;
  canrotate:=b;
end;

procedure rotate(orient : byte);
var
  x,y : integer;
  a   : byte;
begin
  if canrotate(orient)=false then
  begin
    if fy>0 then
      exit;
    a:=0;
    while canrotate(orient)=false do
    begin
      if canmove(2)=true then
        movefig(2);
      inc(a);
      if a>3 then break;
    end;
    if canrotate(orient)=false then
      exit;
  end;
  playmusic(rotmus,false);
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      a:=pole[fx+x-1,fy+y-1];
      pole[fx+x-1,fy+y-1]:=0;
    end;
  drawten(1);
  drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,1);
  rotfig(orient,fg);
  drawten(0);
  drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,0);
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
      pole[fx+x-1,fy+y-1]:=a;
end;

procedure putnewfg(fg : tfigure);
var
  x,y : integer;
  b   : boolean;
  dy  : integer;
begin
  for dy:=0 to 3 do
  begin
    b:=false;
    for x:=1 to 4 do
      if fg.fig[x,dy+1]=true then b:=true;
    if b=true then break;
  end;
  fy:=1-dy;
  fx:=round(width/2)-2;
  b:=true;
  for x:=1 to 4 do
  for y:=1+dy to 4 do
    if pole[fx+x-1,fy+y-1]<>0 then b:=false;
  if b=false then
  begin
    event.what:=loose;
    gocode:=full;
    exit;
  end;
  for x:=1 to 4 do
  for y:=1+dy to 4 do
    if fg.fig[x,y]=true then
      pole[fx+x-1,fy+y-1]:=fg.col;
  drawten(0);
  drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,0);
  if demo=true then
    putevent(spd,0,gentrn);
  delevent(keypress);
end;

procedure initfig(var f : tfigure);
var
  i,e : integer;
  ff  : tfigure;
begin
  ff.fig:=figs[random(7*options.diff)+1];
  ff.col:=random(14)+1;
  e:=random(4);
  for i:=1 to e do
    rotfig(right,ff);
  f:=ff;
end;

function canmove(where : byte) : boolean;
var
  x,y,dx,dy : integer;
  b         : boolean;
  a         : byte;
begin
  b:=true;
  dx:=0;
  dy:=0;
  case where of
    1 : dx:=-1;
    2 : dy:=1;
    3 : dx:=1;
  end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      a:=pole[fx+x-1,fy+y-1];
      pole[fx+x-1,fy+y-1]:=0;
    end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if (fg.fig[x,y]=true) and ((pole[fx+x-1+dx,fy+y-1+dy]<>0) or
       ((fx+x-1+dx)>width) or ((fx+x-1+dx)<1) or
       ((fy+y-1+dy)>height)) then
    begin
      b:=false;
      break;
    end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
      pole[fx+x-1,fy+y-1]:=a;
  canmove:=b;
end;

procedure movfig(where : byte);
var
  x,y,dx,dy : integer;
  a         : byte;
begin
  dx:=0;
  dy:=0;
  case where of
    1 : dx:=-1;
    2 : dy:=1;
    3 : dx:=1;
  end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      a:=pole[fx+x-1,fy+y-1];
      pole[fx+x-1,fy+y-1]:=0;
    end;
  fx:=fx+dx;
  fy:=fy+dy;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
      pole[fx+x-1,fy+y-1]:=a;
end;

procedure movefig(where : byte);
var
  x,y,dx,dy : integer;
  a         : byte;
begin
  if canmove(where)=false then
  begin
    if where=2 then
    begin
      eraser;
      fg:=nfg;
      initfig(nfg);
      drawnext;
      putnewfg(fg);
      delevent(figdown);
      putevent((maxspeed+minspeed-player.speed)*0.1,0,figdown);
      if (canbreath=false) and (player.vozd=0) then
      begin
        delevent(getvozd);
        putevent(0.5,0,getvozd);
      end;
    end;
    exit;
  end;
  playmusic(movmus,false);
  dx:=0;
  dy:=0;
  case where of
    1 : dx:=-1;
    2 : dy:=1;
    3 : dx:=1;
  end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      a:=pole[fx+x-1,fy+y-1];
      pole[fx+x-1,fy+y-1]:=0;
    end;
  if where<>2 then
    drawten(1);
  drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,1);
  fx:=fx+dx;
  fy:=fy+dy;
  if where<>2 then
    drawten(0);
  drawfig(80+blocksize*(fx-1),460+blocksize*(fy-1-height),fg,0);
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fg.fig[x,y]=true then
    begin
      pole[fx+x-1,fy+y-1]:=a;
      if (fx+x-1=player.cx) and (fy+y-1=player.cy) then
      begin
        event.what:=loose;
        gocode:=dead;
      end;
    end;
end;

procedure putevent(tt : real; i : longint; t : byte);
var
  e : integer;
begin
  for e:=1 to nevents do
    if events[e].wevent=nothing then break;
  events[e].wevent:=t;
  events[e].i:=i;
  events[e].time:=timer+round(tt*k);
end;

procedure gamegetevent(gevents : boolean);
var
  c       : char;
  cnt     : integer;
  x,y     : integer;
  button  : byte;
  t       : longint;
begin
  event.what:=nothing;
  event.mx:=mousex;
  event.my:=mousey;
  event.key:=0;
  getmousebuttons(button,cnt,x,y);
  if (event.mx<>mousex) or (event.my<>mousey) then
  begin
    event.mx:=mousex;
    event.my:=mousey;
    event.what:=mousemove;
    exit;
  end;
  if (button and $01)=$01 then
  begin
    event.what:=leftbutton;
    t:=timer;
    repeat
      getmousebuttons(button,cnt,x,y);
    until ((button and $01)=$00) or (((timer-t)/k)>0.5);
    exit;
  end;
  if (button and $02)=$02 then
  begin
    event.what:=rightbutton;
    t:=timer;
    repeat
      getmousebuttons(button,cnt,x,y);
    until ((button and $02)=$00) or (((timer-t)/k)>0.5);
    exit;
  end;
  if keypressed then
  begin
    c:=readkey;
    event.key:=ord(c);
    if c=#0 then
      event.key:=ord(readkey)*$FF;
    event.what:=keypress;
    exit;
  end;
  if gevents=true then
  for cnt:=1 to nevents do
    if events[cnt].wevent<>nothing then
    begin
      if events[cnt].time<=timer then
      begin
        event.what:=events[cnt].wevent;
        if events[cnt].wevent=keypress then
          event.key:=events[cnt].i;
        events[cnt].wevent:=nothing;
        events[cnt].time:=0;
        exit;
      end;
    end{ else break;}
end;

procedure drawfig(x0,y0 : integer; fig : tfigure; del : byte);
var
  x,y : integer;
begin
  case del of
    0 : begin
          setfillstyle(1,fig.col);
          setcolor(white);
          setlinestyle(0,0,3);
        end;
    1 : begin
          setfillstyle(1,bgcolor);
        end;
    2 : begin
          setfillstyle(11,fig.col);
{          setbkcolor(bgcolor);}
          setcolor(lightgray);
          setlinestyle(0,0,1);
        end;
  end;
  for x:=1 to 4 do
  for y:=1 to 4 do
    if fig.fig[x,y]=true then
    begin
      if del<>1 then
        begin
          if del=0 then
          begin
            bar(x0+(x-1)*blocksize+2,y0+(y-1)*blocksize+2,x0+x*blocksize-2,y0+y*blocksize-2);
            drawsprite(bars[fig.col],x0+(x-1)*blocksize,y0+(y-1)*blocksize,dontdrawblack);
          end;
        end else
          bar(x0+(x-1)*blocksize,y0+(y-1)*blocksize,x0+x*blocksize,y0+y*blocksize);
      if del in [0,2] then
        rectangle(x0+(x-1)*blocksize+2,y0+(y-1)*blocksize+2,x0+x*blocksize-2,y0+y*blocksize-2);
    end;
end;

procedure drawnext;
var
  sx,sy : integer;
  dx,dy : integer;
  x,y   : integer;
  a     : integer;
begin
  sx:=0;
  sy:=0;
  dx:=0;
  dy:=0;
  for x:=1 to 4 do
  begin
    a:=0;
    for y:=1 to 4 do
      if nfg.fig[x,y]=true then
        a:=1;
    if (a=0) and (sx=0) then
      dx:=dx+1;
    sx:=sx+a;
  end;
  for y:=1 to 4 do
  begin
    a:=0;
    for x:=1 to 4 do
      if nfg.fig[x,y]=true then
        a:=1;
    if (a=0) and (sy=0) then
      dy:=dy+1;
    sy:=sy+a;
  end;
  sx:=sx*blocksize;
  sy:=sy*blocksize;
  dx:=dx*blocksize;
  dy:=dy*blocksize;
  setfillstyle(1,bgcolor);
  bar(495,105,575,185);
  drawfig(round((575+495-sx)/2)-dx,round((105+185-sy)/2)-dy,nfg,0);
end;

procedure mydelay(s100 : longint);
var
  t0 : longint;
begin
  t0:=timer;
  repeat
  until (timer-t0)/k*100>s100;
end;

procedure drawscores;
var
  s : string;
begin
  setfillstyle(1,lightblue);
  bar(345,45,455,75);
  str(player.scores,s);
  while length(s)<10 do
    s:='0'+s;
  setcolor(white);
  outtextxy(360,58,s);
end;

procedure drawspeed;
var
  s : string;
begin
  setfillstyle(1,lightblue);
  bar(345,125,455,145);
  str(player.speed,s);
  setcolor(white);
  outtextxy(400-length(s)*4,138,s);
end;

procedure drawvozd(dvozd : integer);
begin
  if dvozd>0 then
  begin
    setfillstyle(1,red);
    bar(25,450-round(player.vozd*3.9),55,450-round((player.vozd+dvozd)*3.9));
  end else
  begin
    setfillstyle(1,lightblue);
    bar(25,450-round(player.vozd*3.9),55,450-round((player.vozd+dvozd)*3.9));
  end;
  player.vozd:=player.vozd+dvozd;
end;

procedure initgame;
var
  x,y : integer;
  f   : file of figmat;
  a   : string;
begin
  gocode:=nothing;
  for x:=1 to width do
  for y:=1 to height do
    pole[x,y]:=0;
  with player do
  begin
    scores:=0;
    speed:=options.speed;
    diff:=options.diff;
    vozd:=0;
  end;
  for x:=1 to nevents do
  with events[x] do
  begin
    wevent:=nothing;
    time:=0;
    i:=0;
  end;

  assign(f,nfgs);
  reset(f);
  for x:=1 to 3*7 do
    read(f,figs[x]);
  close(f);

  randomize;
  initfig(fg);
  initfig(nfg);
  fx:=4;
  fy:=1;
  putevent((maxspeed+minspeed-player.speed)*0.1,0,figdown);

  setlimitx(0,(width*blocksize*5)-1);
  setlimity(1,22);

  if (options.life=true) and (demo=false) then
  begin
    player.cy:=height;
    player.cx:=random(width)+1;
    putevent(random+0.4,0,movecreature);
  end else
  begin
    player.cy:=-1;
    player.cx:=-1;
  end;

  for x:=1 to 15 do
  begin
    str(x,a);
    a:='sprites/bar'+a+'.spr';
    loadspritefromfile(bars[x],a);
  end;

  loadmusicfromfile(rotmus,frot);
  loadmusicfromfile(downmus,fdown);
  loadmusicfromfile(movmus,fmove);
  loadmusicfromfile(upmus,fup);
  loadmusicfromfile(lifemus,flife);

  dels:=0;

  spd:=(maxspeed+minspeed-player.speed)*0.02;
end;

procedure maindraw;
var
  s : string;
begin
  drawfont(lightblue);
  setfillstyle(1,bgcolor);
  bar(80,460-height*blocksize,80+width*blocksize,460);

  setlinestyle(0,0,3);
  setfillstyle(1,lightblue);

  setcolor(green);
  rectangle(340,40,460,80);
  bar(400-25,38,400+25,42);
  setcolor(black);
  outtextxy(400-20,36,'Очки:');
  drawscores;

  setcolor(green);
  rectangle(340,120,460,160);
  bar(400-37,118,400+40,122);
  setcolor(black);
  outtextxy(400-32,116,'Скорость:');
  drawspeed;

  setcolor(green);
  rectangle(340,200,460,240);
  bar(400-40,198,400+45,202);
  setcolor(black);
  outtextxy(400-35,196,'Сложность:');
  setcolor(white);
  outtextxy(400-length(diffs[options.diff])*4,216,diffs[options.diff]);

  setcolor(green);
  rectangle(490,100,580,190);
  bar(535-40,98,535+40,102);
  setcolor(black);
  outtextxy(535-38,96,'Подсказка:');
  drawnext;

  setfillstyle(1,white);
  bar(340,300,580,400);
  setcolor(red);
  setlinestyle(0,0,3);
  rectangle(340,300,580,400);
  setcolor(blue);
  s:='Copyright (C) Openov S.L.';
  outtextxy(460-length(s)*4,320,s);
  s:='2004';
  outtextxy(460-length(s)*4,340,s);
  s:='K01-223';
  outtextxy(460-length(s)*4,360,s);
  s:='MEPhI';
  outtextxy(460-length(s)*4,380,s);

  if (options.life=true) and (demo=false) then
  begin
    setlinestyle(0,0,3);
    setfillstyle(1,lightblue);
    setcolor(green);
    rectangle(10,50,70,460);
    bar(40-27,48,40+27,62);
    setcolor(black);
    outtextxy(40-25,46,'Воздух:');
  end;
  if (options.life=true) and (demo=false) then
    drawcreature(0);
end;

var
  s : string;
  a,x : integer;
  n : integer;
  tx,tt : byte;

procedure game(dem : boolean);
begin
  demo:=dem;
  initgame;
  maindraw;
  s:='a';
  a:=1;
  putnewfg(fg);
  n:=1;
  tx := 0;
  tt := 0;
  repeat
    gamegetevent(true);
    case event.what of
      figdown : begin
                  putevent((maxspeed+minspeed-player.speed)*0.1,0,figdown);
                  movefig(2);
                end;
      keypress : begin
                     if event.key=keyb[1] then movefig(1);
                     if event.key=keyb[3] then movefig(2);
                     if event.key=keyb[2] then movefig(3);
                     if event.key=keyb[5] then rotate(left);
                     if event.key=keyb[4] then rotate(right);
                     if event.key=keyb[6] then down;
                     if event.key=keyb[7] then pause;
                     if event.key=27 then esc;
{                     if chr(event.key)='s' then
                     begin
                       x0:=mousex;
                       y0:=mousey;
                       setlimitx(1,640);
                       setlimity(1,480);
                       repeat
                         getevent;
                       until event.what=leftbutton;
                       x1:=mousex;
                       y1:=mousey;
                       repeat
                         getevent;
                       until event.what=leftbutton;
                       x2:=mousex;
                       y2:=mousey;
                       if x2<x1 then
                       begin
                         x2:=x1+x2;
                         x1:=x2-x1;
                         x2:=x2-x1;
                       end;
                       if y2<y1 then
                       begin
                         y2:=y1+y2;
                         y1:=y2-y1;
                         y2:=y2-y1;
                       end;
                       getsprite(screen,x1,y1,x2,y2);
                       str(n,s);
                       if n<10 then s:='0'+s;
                       n:=n+1;
                       s:='screen'+s+'.spr';
                       savespriteinfile(screen,s);
                       setlimitx(0,(width*blocksize*5)-1);
                       setlimity(1,22);
                       mousegotoxy(x0,y0);
                     end;}
                 end;
      mousemove : begin
                    if event.my>20 then
                      movefig(2) else
                    begin
                      x:=trunc(event.mx/blocksize/5);
                      a:=0;
                      if x>fx then a:=3;
                      if x<fx then a:=1;
                      if a<>0 then
                      while x<>fx do
                      begin
                        if (canmove(a)=false) or (event.what=loose) then break;
                        movefig(a);
                      end;
                    end;
                    mousegotoxy(mousex,1);
                    event.my:=1;
                  end;
      leftbutton : down;
      rightbutton : rotate(right);
      movecreature : begin
                       movecreat;
                       delevent(movecreature);
                       putevent(random+0.2,0,movecreature);
                     end;
      getvozd : testvozd;
      playnote : playnot;
      gentrn : genturn(tx,tt);
    end;
  until event.what=loose;
  if event.what=loose then
    gameover;
  event.what:=nothing;
  setlimitx(0,getmaxx);
  setlimity(0,getmaxy);
  nosound;
end;

end.