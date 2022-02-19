unit tetres;

interface
uses 
{$IFDEF UNIX}
    ptccrt,ptcgraph,
{$ELSE}
    crt, graph,
{$ENDIF}
    tetun;

var
  dif   : byte;
  cre   : byte;
  recs  : trecs;
  el,a  : integer;
  ff    : file of trecs;
  scor  : longint;
  mest  : integer;

procedure viewresults(scores : longint);
function getmel : byte;
procedure drawpole;
procedure drawbutt;
procedure setcur;
procedure delscores;
procedure maindraw;
procedure initres;
procedure drawdiff;
procedure drawcrea;
procedure drawtable;
procedure drawrect(x1,y1,x2,y2 : integer; s : string; marked : boolean);
function myord(b : boolean) : byte;

implementation

function myord(b : boolean) : byte;
begin
  if b=true then
    myord:=1 else
    myord:=0;
end;

procedure drawrect(x1,y1,x2,y2 : integer; s : string; marked : boolean);
var
  d : integer;
begin
  if marked=true then
    setfillstyle(1,white) else
    setfillstyle(1,lightgray);
  setcolor(red);
  d:=(1-myord(marked))*2;
  bar(x1+d,y1+d,x2-d,y2-d);
  if marked=true then
  begin
    rectangle(x1,y1,x2,y2);
    setcolor(white);
    line(x1,y2,x2,y2);
  end;
  setcolor(blue);
  outtextxy(round((x2+x1)/2)-length(s)*4,round((y2+y1)/2)-4,s);
end;

procedure drawdiff;
begin
  setfillstyle(1,white);
  bar(165,95,475,385);
  setcolor(red);
  setlinestyle(0,0,1);
  rectangle(165,95,475,385);
  drawrect(165,80,268,95,diffs[1],dif=1);
  drawrect(268,80,372,95,diffs[2],dif=2);
  drawrect(372,80,475,95,diffs[3],dif=3);
end;

procedure drawcrea;
const
  crs : array[0..1] of string = ('Без существа','С существом');

begin
  setfillstyle(1,white);
  bar(160,75,480,390);
  setcolor(red);
  setlinestyle(0,0,1);
  rectangle(160,75,480,390);
  drawrect(160,60,320,75,crs[0],cre=0);
  drawrect(320,60,480,75,crs[1],cre=1);
end;

procedure drawtable;
var
  i       : integer;
  s,ss    : string;
  b       : boolean;
begin
  setfillstyle(1,darkgray);
  bar(170,100,470,380);
  setcolor(blue);
  setlinestyle(0,0,3);
  rectangle(170,100,470,380);
  b:=false;
  for i:=1 to 20 do
  if not ((recs[cre,dif,i].name='nobody') and (recs[cre,dif,i].score=0)) then
  begin
    str(i,s);
    ss:=s+'. '+recs[cre,dif,i].name;
    str(recs[cre,dif,i].score,s);
    repeat
      ss:=ss+'.';
    until (length(ss)+length(s))>=35;
    ss:=ss+s;
    if (cre=myord(options.life)) and (dif=options.diff) and
       (i=mest) then
         setcolor(red) else
         setcolor(white);
    outtextxy(180,110+i*12,ss);
    b:=true;
  end;
  if b=false then
  begin
    setcolor(lightred);
    s:='Нет ни одного результата!';
    outtextxy(320-length(s)*4,220,s);
  end;
end;

procedure initres;
var
  i   : integer;
begin
  assign(ff,fscores);
  reset(ff);
  read(ff,recs);
  dif:=options.diff;
  cre:=myord(options.life);
  mest:=-1;
  for i:=1 to 20 do
  begin
    if recs[cre,dif,i].score<=scor then
    begin
      mest:=i;
      break;
    end;
  end;
  if mest<>-1 then
  begin
    for i:=20 downto mest+1 do
      recs[cre,dif,i]:=recs[cre,dif,i-1];
    recs[cre,dif,mest].score:=scor;
    recs[cre,dif,mest].name:=options.name;
    rewrite(ff);
    write(ff,recs);
  end;
  close(ff);
end;

function getmel : byte;
begin
  getmel:=0;
  if (event.mx>=210) and (event.mx<=270) and
     (event.my>=400) and (event.my<=420) then
       getmel:=1;
  if (event.mx>=420-64) and (event.mx<=440) and
     (event.my>=400) and (event.my<=420) then
       getmel:=2;
  if (event.mx>=163) and (event.mx<=317) and
     (event.my>=60) and (event.my<=75) then
       getmel:=3;
  if (event.mx>=323) and (event.mx<=477) and
     (event.my>=60) and (event.my<=75) then
       getmel:=4;
  if (event.mx>=168) and (event.mx<=265) and
     (event.my>=80) and (event.my<=95) then
       getmel:=5;
  if (event.mx>=271) and (event.mx<=369) and
     (event.my>=80) and (event.my<=95) then
       getmel:=6;
  if (event.mx>=374) and (event.mx<=473) and
     (event.my>=80) and (event.my<=95) then
       getmel:=7;
end;

procedure drawbutt;
begin
  setfillstyle(1,lightblue);
  bar(180,400,480,420);
  myouttext(220,405,' ОК ',el=1,right);
  myouttext(430,405,'Обнулить',el=2,left);
  case el of
    1 : putlabel(210,405,220+10+32,413);
    2 : putlabel(420-64,405,430+10,413);
  end;
end;

procedure drawpole;
begin
  setfillstyle(1,lightblue);
  bar(160,60,480,400);
  drawcrea;
  drawdiff;
  drawtable;
end;

procedure setcur;
var
  a : byte;
begin
  a:=getmel;
  if (a<>el) and (a in [1..2]) then
  begin
    el:=a;
    drawbutt;
  end;
  if (a=0) and (curs=1) then
  begin
    cur:=arr;
    curs:=0;
  end;
  if (a<>0) and (curs=0) then
  begin
    cur:=arm;
    curs:=1;
  end;
end;

procedure delscores;
var
  i : integer;
begin
  assign(ff,fscores);
  reset(ff);
  for i:=1 to 20 do
  with recs[cre,dif,i] do
  begin
    name:='nobody';
    score:=0;
  end;
  rewrite(ff);
  write(ff,recs);
  close(ff);
end;

procedure maindraw;
begin
  drawfont(lightgreen);
  setfillstyle(1,blue);
  setlinestyle(0,0,3);
  setcolor(red);
  bar(150+dx,50+dy,490+dx,430+dy);
  rectangle(150+dx,50+dy,490+dx,430+dy);
  setfillstyle(1,lightblue);
  bar(150,50,490,430);
  setcolor(lightred);
  rectangle(150,50,490,430);
end;

procedure viewresults(scores : longint);
begin
  scor:=scores;
  if scor=0 then scor:=-1;
  initres;
  maindraw;
  el:=1;
  drawbutt;
  drawpole;
  setcur;
  repeat
    getevent;
    if event.what=leftbutton then
    begin
      a:=getmel;
      if (a in [1..2]) then
      begin
        event.what:=keypress;
        event.key:=13;
      end;
      if (a in [3..4]) and (cre<>(a-3)) then
      begin
        cre:=a-3;
        drawpole;
      end;
      if (a in [5..7]) and (dif<>(a-4)) then
      begin
        dif:=a-4;
        drawpole;
      end;
    end;
    if event.what=keypress then
    begin
      case event.key of
        75*$FF : begin
                   dec(el);
                   if el<1 then el:=2;
                   drawbutt;
                 end;
        77*$FF : begin
                   inc(el);
                   if el>2 then el:=1;
                   drawbutt;
                 end;
        13 : begin
               case el of
                 2 : begin
                       delscores;
                       maindraw;
                       drawbutt;
                       drawpole;
                     end;
               end;
             end;
        9 : begin
              if dif=3 then
              begin
                dif:=1;
                cre:=myord(cre=0);
              end else
                dif:=dif+1;
              drawpole;
            end;
      end;
    end;
    if event.what=mousemove then
      setcur;
  until ((event.what=keypress) and ((event.key=27) or ((event.key=13) and (el in [1]))));
  event.what:=nothing;
end;

end.