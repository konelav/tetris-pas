unit tetun;

interface
uses 
{$IFDEF UNIX}
    ptccrt,ptcgraph,
{$ELSE}
    crt, graph,
{$ENDIF}
    sprites,mouse,music;

const
  fscores = 'data/scores.dat';
  farr    = 'sprites/arrow.spr';
  farm    = 'sprites/arm.spr';
  fdata   = 'data/options.dat';
  fgalk   = 'sprites/galka.spr';
  flb1    = 'sprites/label1.spr';
  flb2    = 'sprites/label1.spr';
  farr1   = 'sprites/arrow1.spr';
  farr2   = 'sprites/arrow2.spr';
  fcreat  = 'sprites/creature.spr';
  nfgs    = 'data//figures.dat';
  nkeyb   = 'sprites/keyboard.dat';
  frot    = 'sound/rotate.mus';
  fdown   = 'sound/down.mus';
  fmove   = 'sound/move.mus';
  fup     = 'sound/up.mus';
  flife   = 'sound/life.mus';
  fhelp   = 'help.hlp';

const
  nel = 7;
  els : array[1..nel] of string = ('Начать игру',
                                   'Демонстрация',
                                   'Опции игры',
                                   'Управление',
                                   'Лучшие результаты',
                                   'О программе',
                                   'Выход');
  keybs : array[1..7] of string = ('Сдвиг влево:',
                                   'Сдвиг вправо:',
                                   'Сдвиг вниз:',
                                   'Поворот по часовой:',
                                   'Поворот против часовой:',
                                   'Опустить до конца:',
                                   'Пауза:');
  diffs : array[1..3] of string = ('Лёгкая','Средняя','Тяжелая');
  ht = 20;
  dx = 12;
  dy = 9;

const
  txtcolor = white;
  bgcolor = lightblue;
  markedbg = blue;
  markedtxt = lightmagenta;

const
  nothing = 0;
  leftbutton = 1;
  rightbutton = 2;
  keypress = 3;
  mousemove = 4;
  figdown = 10;
  vozdup = 11;
  dosound = 12;
  loose = 13;
  movecreature = 14;
  getvozd = 15;
  playnote = 16;

const
  easy = 1;
  medium = 2;
  hard = 3;

const
  maxspeed = 20;
  minspeed = 1;

const
  on = true;
  off = false;

const
  right = 0;
  center = 1;
  left = 2;

type
  tlink = record
    x1,y1,x2,y2 : integer;
    npage       : integer;
  end;

  tpoint = record
    x,y : integer;
  end;

  tevent = record
    key   : word;
    mx,my : integer;
    what  : byte;
  end;

  toptions = record
    speed : byte;
    diff  : byte;
    sound : boolean;
    life  : boolean;
    name  : string[15];
    ten   : boolean;
  end;

  tkeyb = array[1..7] of word;

  trec = record
    name  : string[15];
    score : longint;
  end;

  trecs = array[0..1,1..3,1..20] of trec;

  figmat = array[1..4,1..4] of boolean;

  tfigure = record
    fig : figmat;
    col : byte;
  end;

var
  scr,cur,arm,arr,lb1,lb2,arr1,arr2,creature : tsprite;
  event           : tevent;
  options         : toptions;
  fopt            : file of toptions;
  curs            : byte;
  keyb            : tkeyb;
  fkeyb           : file of tkeyb;

procedure myouttext(x0,y : integer; txt : string; selected : boolean; align : byte);
procedure getevent;
procedure delcur;
procedure drawcur;
procedure init;
procedure dlabel(x1,y1,x2,y2 : integer);
procedure putlabel(x1,y1,x2,y2 : integer);
procedure drawfont(font : byte);

implementation

procedure drawfont(font : byte);
begin
  setfillstyle(1,font);
  bar(0,0,640,480);
  setcolor(font);
  setlinestyle(0,0,1);
  setfillstyle(1,black);
  bar(0,0,30,30);
  setfillstyle(1,font);
  fillellipse(30,30,30,30);
  setfillstyle(1,black);
  bar(0,450,30,480);
  setfillstyle(1,font);
  fillellipse(30,450,30,30);
  setfillstyle(1,black);
  bar(610,0,640,30);
  setfillstyle(1,font);
  fillellipse(610,30,30,30);
  setfillstyle(1,black);
  bar(610,450,640,480);
  setfillstyle(1,font);
  fillellipse(610,450,30,30);
end;

procedure dlabel(x1,y1,x2,y2 : integer);
begin
  bar(x1-lb1.width,round((y1+y2-lb1.height)/2),x1,round((y1+y2-lb1.height)/2)+lb1.height);
  bar(x2,round((y1+y2-lb2.height)/2),x2+lb2.width,round((y1+y2-lb2.height)/2)+lb2.height);
end;

procedure putlabel(x1,y1,x2,y2 : integer);
begin
  drawsprite(lb1,x1-lb1.width,round((y1+y2-lb1.height)/2),dontdrawblack);
  drawsprite(lb2,x2,round((y1+y2-lb2.height)/2),dontdrawblack);
end;

procedure init;
begin
  loadspritefromfile(arr,farr);
  loadspritefromfile(arm,farm);
  loadspritefromfile(lb1,flb1);
  loadspritefromfile(lb2,flb2);
  loadspritefromfile(arr1,farr1);
  loadspritefromfile(arr2,farr2);
  loadspritefromfile(creature,fcreat);
  cur:=arr;
  curs:=0;
  initmouse(graphmode);
  hidemouse;
  event.what:=nothing;
  mousegotoxy(1,1);
  assign(fopt,fdata);
{$I-}
  reset(fopt);
{$I+}
  if ioresult<>0 then
  begin
    rewrite(fopt);
    with options do
    begin
      speed:=1;
      diff:=medium;
      sound:=on;
      life:=on;
      name:='NoName';
      ten:=off;
    end;
    write(fopt,options);
  end else
    read(fopt,options);
  close(fopt);
  assign(fkeyb,nkeyb);
{$I-}
  reset(fkeyb);
{$I+}
  if ioresult<>0 then
  begin
    rewrite(fkeyb);
    keyb[1]:=$FF*75;
    keyb[2]:=$FF*77;
    keyb[3]:=$FF*80;
    keyb[4]:=$FF*73;
    keyb[5]:=$FF*71;
    keyb[6]:=32;
    keyb[7]:=112;
    write(fkeyb,keyb);
  end else
    read(fkeyb,keyb);
  close(fkeyb);
end;

procedure delcur;
begin
  drawsprite(scr,event.mx,event.my,drawblack);
end;

procedure drawcur;
begin
  getsprite(scr,event.mx,event.my,event.mx+cur.width,event.my+cur.height);
  drawsprite(cur,event.mx,event.my,dontdrawblack);
end;

procedure myouttext(x0,y : integer; txt : string; selected : boolean; align : byte);
var
  x : integer;
begin
  case align of
    left   : x:=x0-length(txt)*8;
    center : x:=x0-length(txt)*4;
    right  : x:=x0-length(txt)*0;
  end;
  if selected=true then
  begin
    setcolor(markedtxt);
    setfillstyle(1,markedbg);
    bar(x-8,y-4,x+length(txt)*8+8,y+11);
  end else
  begin
    setcolor(txtcolor);
    setfillstyle(1,bgcolor);
    bar(x-8,y-4,x+length(txt)*8+8,y+11);
  end;
  outtextxy(x,y,txt);
end;

procedure getevent;
var
  c       : char;
  cnt     : integer;
  x,y     : integer;
  button  : byte;
begin
  event.what:=nothing;
  event.mx:=mousex;
  event.my:=mousey;
  event.key:=0;
  drawcur;
  repeat
    getmousebuttons(button,cnt,x,y);
    if (event.mx<>mousex) or (event.my<>mousey) then
    begin
      delcur;
      event.mx:=mousex;
      event.my:=mousey;
      event.what:=mousemove;
      drawcur;
    end;
    if (button and $01)=$01 then
    begin
      event.what:=leftbutton;
      repeat
        getmousebuttons(button,cnt,x,y);
      until (button and $01)=$00;
    end;
    if (button and $02)=$02 then
    begin
      event.what:=rightbutton;
      repeat
        getmousebuttons(button,cnt,x,y);
      until (button and $02)=$00;
    end;
    if keypressed then
    begin
      c:=readkey;
      event.key:=ord(c);
      if c=#0 then
        event.key:=ord(readkey)*$FF;
      event.what:=keypress;
    end;
  until event.what<>nothing;
  delcur;
end;

end.