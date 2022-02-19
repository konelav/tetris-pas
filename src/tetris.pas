uses 
{$IFDEF UNIX}
    cthreads,ptccrt,ptcgraph,
{$ELSE}
    crt, graph,
{$ENDIF}
    dos,sprites,mouse,tetun,setopt,tetgame,tetres,setkeyb,tethelp;

procedure mainmenu(var sel : integer);
var
  el     : byte;
  height : integer;

procedure maindraw;
begin
  drawfont(lightgreen);
  height:=round((nel+2)*ht/2);
  setfillstyle(1,blue);
  setlinestyle(0,0,3);
  setcolor(red);
  bar(200+dx,240-height+dy,440+dx,240+height+dy);
  rectangle(200+dx,240-height+dy,440+dx,240+height+dy);
  setfillstyle(1,lightblue);
  bar(200,240-height,440,240+height);
  setcolor(lightred);
  rectangle(200,240-height,440,240+height);
end;

procedure draw;
var
  i,x,y  : integer;
begin
  setfillstyle(1,lightblue);
  bar(210,250-height,430,230+height);
  setcolor(txtcolor);
  for i:=1 to nel do
  begin
    x:=320;
    y:=240-height+(i*ht)+4;
    myouttext(x,y,els[i],i=el,center);
    if i=el then
      putlabel(x-length(els[i])*4-10,y+4,x+length(els[i])*4+10,y+4);
  end;
end;

function getmel : byte;
var
  i : integer;
begin
  getmel:=0;
  for i:=1 to nel do
    if (event.mx>=320-(length(els[i])*4)-8) and
       (event.mx<=320+(length(els[i])*4)+8) and
       (event.my>=240-height+(i*ht)) and
       (event.my<=240-height+(i*ht)+15) then
    begin
      getmel:=i;
      break;
    end;
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

var
  c : char;

begin
  el:=1;
  maindraw;
  draw;
  c:=#0;
  repeat
    getevent;
    if event.what=keypress then
    case event.key of
      72*$FF : begin
                 dec(el);
                 if el<1 then el:=nel;
                 draw;
               end;
      80*$FF : begin
                 inc(el);
                 if el>nel then el:=1;
                 draw;
               end;
    end;
    if (event.what=leftbutton) and (getmel<>0) then
    begin
      event.what:=keypress;
      event.key:=13;
    end;
    if event.what=mousemove then
      setcur;
  until (event.what=keypress) and ((event.key mod $FF) in [13,27]);
  sel:=el;
end;

procedure vga;
var
  error,d,m : integer;
  n         : string;
  ifont     : integer;
begin
  d:=9;
  m:=2;
  n:='./';
  initgraph(d,m,n);
  error:=graphresult;
  if error<>grok then
  writeln('Cant init graph: ', grapherrormsg(error));

{$IFDEF UNIX}
  ifont := installuserfont('MONO');
  error:=graphresult;
  if error<>grok then
  writeln(grapherrormsg(error))
  else
  writeln('User font installed: ', ifont);

  settextstyle(ifont, horizdir, 1);
  error:=graphresult;
  if error<>grok then
  writeln('Cant set text style: ', grapherrormsg(error));
{$ENDIF}
end;

var
  i : integer;

begin
  vga;
  init;
  repeat
    mainmenu(i);
    if not ((event.what=keypress) and (event.key=27)) then
    case i of
      1 : begin
            game(false);
            viewresults(player.scores);
          end;
      2 : begin
            game(true);
          end;
      3 : begin
            setoptions;
          end;
      4 : begin
            setkeys;
          end;
      5 : begin
            viewresults(-1);
          end;
      6 : begin
            callhelp;
          end;
    end;
  until (i=7) or ((event.what=keypress) and (event.key=27));
  closegraph;
end.