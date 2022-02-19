unit setkeyb;

interface
uses 
{$IFDEF UNIX}
    ptccrt,ptcgraph,
{$ELSE}
    crt, graph,
{$ENDIF}
    tetun;

var
  el     : byte;
  a      : shortint;
  skeyb  : tkeyb;

function keyname(c : word) : string;
procedure setkeys;
procedure maindraw;
procedure draw;
procedure setvalue;
procedure setcur;
function getmel : byte;

implementation

function getmel : byte;
var
  i : integer;
begin
  getmel:=0;
  for i:=1 to 7 do
    if (event.mx>=330-length(keybs[i])*8-20) and
       (event.mx<=330+(length(keyname(keyb[i]))*8)+8+10) and
       (event.my>=80+(i-1)*ht*2) and
       (event.my<=80+(i-1)*ht*2+ht) then
    begin
      getmel:=i;
      break;
    end;
  if (event.mx>=200) and (event.mx<=280) and
     (event.my>=360) and (event.my<=375) then
       getmel:=8;
  if (event.mx>=365) and (event.mx<=435) and
     (event.my>=360) and (event.my<=375) then
       getmel:=9;
end;

procedure setcur;
var
  a : byte;
begin
  a:=getmel;
  if (a<>el) and (a<>0) then
  begin
    el:=a;
    draw;
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

procedure setvalue;
var
  x,y : integer;
  s   : string;
begin
  s:='<нажмите клавишу>';
  setcolor(txtcolor);
  x:=330;
  setfillstyle(1,lightblue);
  bar(105,80+(el-1)*ht*2,530,80+el*ht*2);
  y:=80+(el-1)*ht*2+4;
  myouttext(x-10,y,keybs[el],el=el,left);
  myouttext(x+10,y,s,el=el,right);
  putlabel(x-length(keybs[el])*8-20,y+4,x+length(s)*8+20,y+4);
  y:=el;
  repeat
    getevent;
    if event.what=mousemove then
      setcur;
  until (event.what=keypress) or (el<>y);
  if y=el then
  for x:=1 to 7 do
    if keyb[x]=event.key then
    keyb[x]:=0;
  if (event.key=27) or (el<>y) then
    keyb[y]:=0 else
    keyb[el]:=event.key;
  event.what:=nothing;
end;

procedure draw;
var
  i,x,y : integer;

begin
  setcolor(txtcolor);
  x:=330;
  for i:=1 to 7 do
  begin
    setfillstyle(1,lightblue);
    bar(105,80+(i-1)*ht*2,530,80+i*ht*2);
    y:=80+(i-1)*ht*2+4;
    myouttext(x-10,y,keybs[i],i=el,left);
    myouttext(x+10,y,keyname(keyb[i]),i=el,right);
    if i=el then
      putlabel(x-length(keybs[i])*8-20,y+4,x+length(keyname(keyb[i]))*8+20,y+4);
  end;
  i:=8;
  setfillstyle(1,lightblue);
  bar(160,60+(i-1)*ht*2,480,60+i*ht*2);
  x:=240;
  y:=80+(i-1)*ht*2+4;
  myouttext(x,y,'Принять',i=el,center);
  if i=el then
    putlabel(x-7*4-10,y+4,x+7*4+10,y+4);
  i:=9;
  x:=400;
  myouttext(x,y,'Отмена',i=el,center);
  if i=el then
    putlabel(x-6*4-10,y+4,x+6*4+10,y+4);
end;

function keyname(c : word) : string;
begin
  case c of
    0      : keyname:='---';
    8      : keyname:='BackSpace';
    9      : keyname:='TAB';
    13     : keyname:='Enter';
    32     : keyname:='SpaceBar';
    72*$FF : keyname:='UpArrow';
    77*$FF : keyname:='RightArrow';
    80*$FF : keyname:='DownArrow';
    75*$FF : keyname:='LeftArrow';
    82*$FF : keyname:='Insert';
    83*$FF : keyname:='Del';
    71*$FF : keyname:='Home';
    73*$FF : keyname:='PageUp';
    79*$FF : keyname:='End';
    81*$FF : keyname:='PageDown';
    else keyname:=chr(c mod $FF);
  end;
end;

procedure setkeys;
begin
  el:=8;
  maindraw;
  draw;
  skeyb:=keyb;
  repeat
    getevent;
    if (event.what=leftbutton) and (getmel<>0) then
    begin
      event.what:=keypress;
      event.key:=13;
    end;
    if event.what=keypress then
    case event.key of
      $FF*72 : begin
                 dec(el);
                 if el<1 then el:=9;
                 draw;
               end;
      $FF*80 : begin
                 inc(el);
                 if el>9 then el:=1;
                 draw;
               end;
      13 : begin
             case el of
               8 : begin
                     assign(fkeyb,nkeyb);
                     rewrite(fkeyb);
                     write(fkeyb,keyb);
                     close(fkeyb);
                     skeyb:=keyb;
                   end;
               1..7 : begin
                        setvalue;
                        draw;
                      end;
             end;
           end;
    end;
    if event.what=mousemove then
      setcur;
  until ((event.key=13) and (el in [8..9])) or (event.key=27);
  keyb:=skeyb;
  event.what:=nothing;
end;

procedure maindraw;
begin
  drawfont(lightgreen);
  setfillstyle(1,blue);
  setlinestyle(0,0,3);
  setcolor(red);
  bar(100+dx,60+dy,540+dx,420+dy);
  rectangle(100+dx,60+dy,540+dx,420+dy);
  setfillstyle(1,lightblue);
  bar(100,60,540,420);
  setcolor(lightred);
  rectangle(100,60,540,420);
end;

end.