unit tethelp;

interface
uses 
{$IFDEF UNIX}
    ptccrt,ptcgraph,
{$ELSE}
    crt, graph,
{$ENDIF}
    mouse,sprites,tetun;

const
  maxlinks = 20;

var
  npg,pages,height,width,nlink : integer;
  hfc     : file of char;
  hft     : text;
  pp      : tpoint;
  links   : array[1..maxlinks] of tlink;
  u       : boolean;

procedure callhelp;
procedure upstr(var ss : string);
procedure getsize(n : integer);
procedure getpgs;
procedure readtag(var tag : string);
procedure drawpage(n : integer);

implementation

procedure drawpage(n : integer);
var
  s,ss  : string;
  i,e,o : integer;
  ns    : byte;
  ch    : char;
  ssp   : tsprite;
begin
  ssp.data:=nil;
  for i:=1 to maxlinks do
  with links[i] do
  begin
    x1:=0;
    x2:=0;
    y1:=0;
    y2:=0;
    npage:=0;
  end;
  getsize(n);
  str(n,s);
  str(pages,ss);
  s:=' стр '+s+' из '+ss+' ';
  nlink:=1;
  if n>1 then
  begin
    inc(nlink);
    with links[nlink] do
    begin
      x1:=320-length(s)*4-2-arr1.width;
      x2:=320-length(s)*4;
      y1:=240+height-20;
      y2:=240+height-20+arr1.height;
      npage:=n-1;
    end;
  end;
  if n<pages then
  begin
    inc(nlink);
    with links[nlink] do
    begin
      x1:=320+length(s)*4+2;
      x2:=320+length(s)*4+2+arr2.width;
      y1:=240+height-20;
      y2:=240+height-20+arr2.height;
      npage:=n+1;
    end;
  end;
  drawfont(lightgreen);
  setfillstyle(1,blue);
  setlinestyle(0,0,3);
  setcolor(red);
  bar(320-width+dx,240-height+dy,320+width+dx,240+height+dy+20);
  rectangle(320-width+dx,240-height+dy,320+width+dx,240+height+dy+20);
  setfillstyle(1,lightblue);
  bar(320-width,240-height,320+width,240+height+20);
  setcolor(lightred);
  rectangle(320-width,240-height,320+width,240+height+20);
  setcolor(white);
  outtextxy(320-length(s)*4,240+height-20,s);
  if n>1 then
    drawsprite(arr1,320-length(s)*4-2-arr1.width,240+height-20,dontdrawblack);
  if n<pages then
    drawsprite(arr2,320+length(s)*4+2,240+height-20,dontdrawblack);
  s:='Назад (ESC)';
  with links[1] do
  begin
    x1:=320-length(s)*4-7;
    y1:=240+height-5;
    x2:=320+length(s)*4+7;
    y2:=240+height+10;
    npage:=-1;
  end;
  setfillstyle(1,lightgray);
  bar(320-length(s)*4-7,240+height-5,320+length(s)*4+7,240+height+10);
  setcolor(red);
  rectangle(320-length(s)*4-7,240+height-5,320+length(s)*4+7,240+height+10);
  setcolor(white);
  outtextxy(320-length(s)*4,240+height-1,s);
  assign(hfc,fhelp);
  reset(hfc);
  i:=0;
  while i<n do
  begin
    read(hfc,ch);
    if ch='<' then
    begin
      readtag(s);
      if s='NEWPAGE' then i:=i+1;
    end;
  end;
  ns:=1;
  pp.x:=320-width+10;
  pp.y:=240-height+10;
  u:=false;
  setlinestyle(0,0,1);
  repeat
    s:='';
    read(hfc,ch);
    if ch in [#10,#13] then continue;
    if ch='<' then
    begin
      readtag(s);
      if s='BR' then
      begin
        pp.y:=pp.y+10;
        pp.x:=320-width+10;
      end;
      if copy(s,1,3)='TC=' then
      begin
        val(copy(s,4,length(s)-3),e,o);
        setcolor(e);
      end;
      if copy(s,1,5)='LINK=' then
      begin
        val(copy(s,6,length(s)-5),e,o);
        inc(nlink);
        with links[nlink] do
        begin
          npage:=e;
          x1:=pp.x;
          y1:=pp.y-1;
        end;
        e:=getcolor;
        setcolor(blue);
        u:=true;
      end;
      if s='/LINK' then
      with links[nlink] do
      begin
        x2:=pp.x;
        y2:=pp.y+7;
        setcolor(e);
        u:=false;
      end;
      if s='U' then
        u:=true;
      if s='/U' then
        u:=false;
      if copy(s,1,6)='IMAGE=' then
      begin
        s:=copy(s,7,length(s)-6);
        loadspritefromfile(ssp,s);
        pp.y:=pp.y+10;
        pp.x:=320-round(ssp.width/2);
        drawsprite(ssp,pp.x,pp.y,drawblack);
        e:=getcolor;
        setcolor(red);
        rectangle(pp.x,pp.y,pp.x+ssp.width,pp.y+ssp.height);
        setcolor(e);
        pp.y:=pp.y+10+ssp.height;
        pp.x:=320-width+10;
        freesprite(ssp);
      end;
    end else
    begin
      outtextxy(pp.x,pp.y,ch);
      if u=true then
        line(pp.x,pp.y+8,pp.x+8,pp.y+8);
      pp.x:=pp.x+8;
      if pp.x>320+width-10 then
      begin
        pp.y:=pp.y+10;
        pp.x:=320-width+10;
      end;
    end;
  until s='END';
  close(hfc);
end;

procedure readtag(var tag : string);
var
  c : char;
  s : string;
begin
  s:='';
  read(hfc,c);
  repeat
    s:=s+c;
    read(hfc,c);
  until c='>';
  tag:=s;
  upstr(tag);
end;

procedure getpgs;
var
  hf : text;
  s  : string;
begin
  assign(hf,fhelp);
  reset(hf);
  pages:=0;
  while not eof(hf) do
  begin
    readln(hf,s);
    upstr(s);
    if s='<NEWPAGE>' then
      pages:=pages+1;
  end;
  close(hf);
end;

procedure getsize(n : integer);
var
  i,ns : integer;
  s,ss : string;
  ms   : integer;
  ssp  : tsprite;
  ddy  : integer;
begin
  assign(hft,fhelp);
  reset(hft);
  i:=0;
  ms:=0;
  ddy:=0;
  ssp.data:=nil;
  while i<>n do
  begin
    readln(hft,s);
    upstr(s);
    if s='<NEWPAGE>' then i:=i+1;
  end;
  ns:=0;
  repeat
    readln(hft,s);
    upstr(s);
    if length(s)>ms then ms:=length(s);
    while pos('<IMAGE=',s)<>0 do
    begin
      ss:=copy(s,pos('<IMAGE=',s)+7,pos('>',s)-pos('<IMAGE=',s)-7);
      s:=copy(s,pos('>',s)+1,length(s)-pos('>',s));
      loadspritefromfile(ssp,ss);
      ddy:=ddy+10+ssp.height+10+4;
      freesprite(ssp);
    end;
    ns:=ns+1;
  until s='<END>';
  close(hft);
  height:=ns*5+round(ddy/2);
  width:=round((ms*8+20)/2);
  if width>300 then width:=300;
  if width<80 then width:=80;
end;

procedure upstr(var ss : string);
var
  i : integer;
begin
  for i:=1 to length(ss) do
    ss[i]:=upcase(ss[i]);
end;

procedure callhelp;

function getmel : byte;
var
  i : integer;
begin
  getmel:=0;
  for i:=1 to nlink do
    if (event.mx>=links[i].x1) and
       (event.mx<=links[i].x2) and
       (event.my>=links[i].y1) and
       (event.my<=links[i].y2) then
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
  i : integer;
begin
  delcur;
  getpgs;
  npg:=1;
  drawpage(npg);
  setcur;
  repeat
    repeat
      getevent;
      if event.what=mousemove then
        setcur;
    until ((event.what=keypress) and ((event.key=$FF*75) or (event.key=$FF*77) or (event.key=27))) or (event.what=leftbutton);
    if (event.what=keypress) and ((event.key=$FF*75) or (event.key=$FF*77)) then
    begin
      if event.key=$FF*75 then npg:=npg-1;
      if event.key=$FF*77 then npg:=npg+1;
      if npg<1 then
        npg:=1 else
      begin
        if npg>pages then
          npg:=pages else
          drawpage(npg);
      end;
    end;
    if event.what=leftbutton then
    begin
      i:=getmel;
      if i<>0 then
      begin
        npg:=links[getmel].npage;
        if npg<>-1 then
          drawpage(npg);
      end;
    end;
  until (event.key=27) or (npg=-1);
  event.what:=nothing;
  event.key:=0;
end;









end.