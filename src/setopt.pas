unit setopt;
interface
uses 
{$IFDEF UNIX}
    ptccrt,ptcgraph,
{$ELSE}
    crt, graph,
{$ENDIF}
    sprites,mouse,tetun;

var
  galk   : tsprite;
  el     : byte;
  ss     : string;
  ncur,a : shortint;
  sopt   : toptions;

procedure setoptions;
procedure setcur;
procedure drawlabel;
procedure dellabel;
procedure maindraw;
procedure drawname;
procedure drawspeed;
procedure drawdiff;
procedure drawten;
procedure drawsound;
procedure drawlife;
function getmpos : byte;

implementation

function getmpos : byte;
begin
  getmpos:=0;
  if (event.mx>=350) and (event.mx<=350+arr1.width) and
     (event.my>=185-round(arr1.height/2)) and (event.my<=185+round(arr1.height/2)) then
     begin
       getmpos:=9;
       exit;
     end;
  if (event.mx>=350+5+16+5+arr1.width) and (event.mx<=350+5+16+5+arr1.width+arr2.width) and
     (event.my>=185-round(arr2.height/2)) and (event.my<=185+round(arr2.height/2)) then
     begin
       getmpos:=10;
       exit;
     end;
  if (event.mx>=350) and (event.mx<=350+arr1.width) and
     (event.my>=225-round(arr1.height/2)) and (event.my<=225+round(arr1.height/2)) then
     begin
       getmpos:=11;
       exit;
     end;
  if (event.mx>=350+5+length(diffs[options.diff])*8+5+arr1.width) and
     (event.mx<=350+5+length(diffs[options.diff])*8+5+arr1.width+arr2.width) and
     (event.my>=225-round(arr2.height/2)) and (event.my<=225+round(arr2.height/2)) then
     begin
       getmpos:=12;
       exit;
     end;
  if (event.mx>=140) and (event.mx<=475) and
     (event.my>=134) and (event.my<=150) then
     begin
       getmpos:=1;
       exit;
     end;
  if (event.mx>=140) and (event.mx<=475) and
     (event.my>=174) and (event.my<=190) then
     begin
       getmpos:=2;
       exit;
     end;
  if (event.mx>=140) and (event.mx<=475) and
     (event.my>=214) and (event.my<=230) then
     begin
       getmpos:=3;
       exit;
     end;
  if (event.mx>=140) and (event.mx<=475) and
     (event.my>=254) and (event.my<=270) then
     begin
       getmpos:=4;
       exit;
     end;
  if (event.mx>=140) and (event.mx<=475) and
     (event.my>=294) and (event.my<=310) then
     begin
       getmpos:=5;
       exit;
     end;
  if (event.mx>=140) and (event.mx<=475) and
     (event.my>=334) and (event.my<=350) then
     begin
       getmpos:=6;
       exit;
     end;
  if (event.mx>=180) and (event.mx<=260) and
     (event.my>=375) and (event.my<=391) then
     begin
       getmpos:=7;
       exit;
     end;
  if (event.mx>=384) and (event.mx<=457) and
     (event.my>=375) and (event.my<=391) then
     begin
       getmpos:=8;
       exit;
     end;
end;

procedure dellabel;
begin
  setfillstyle(1,lightblue);
  case el of
    1 : dlabel(140,142,475,142);
    2 : dlabel(140,182,475,182);
    3 : dlabel(140,222,475,222);
    4 : dlabel(140,262,475,262);
    5 : dlabel(140,302,475,302);
    6 : dlabel(140,342,475,342);
    7 : dlabel(180,383,260,383);
    8 : dlabel(384,383,457,383);
  end;
end;

procedure drawlabel;
begin
  case el of
    1 : putlabel(140,142,475,142);
    2 : putlabel(140,182,475,182);
    3 : putlabel(140,222,475,222);
    4 : putlabel(140,262,475,262);
    5 : putlabel(140,302,475,302);
    6 : putlabel(140,342,475,342);
    7 : putlabel(180,383,260,383);
    8 : putlabel(384,383,457,383);
  end;
end;

procedure maindraw;
begin
  drawfont(lightgreen);
  setfillstyle(1,blue);
  setlinestyle(0,0,3);
  setcolor(red);
  bar(50+dx,50+dy,590+dx,430+dy);
  rectangle(50+dx,50+dy,590+dx,430+dy);
  setfillstyle(1,lightblue);
  bar(50,50,590,430);
  setcolor(lightred);
  rectangle(50,50,590,430);
end;

procedure drawname;
begin
  if el=1 then
    setfillstyle(1,black) else
    setfillstyle(1,lightblue);
  bar(350-5,138-3,466+5,148+3);
  setlinestyle(0,0,1);
  if el=1 then
  begin
    setcolor(white);
    line(350+ncur*8-1,139,350+ncur*8-1,147);
    setcolor(green);
  end else
    setcolor(markedtxt);
  outtextxy(350,141,options.name);
  myouttext(150,140,'Имя игрока:',el=1,right);
end;

procedure drawspeed;
begin
  str(options.speed,ss);
  if options.speed<10 then
    ss:='0'+ss;
  setfillstyle(1,lightblue);
  bar(350-5,178-5,466+5,188+3);
  if el=2 then
    setcolor(green) else
    setcolor(markedtxt);
  if el=2 then
  begin
    drawsprite(arr1,350,185-round(arr1.height/2),dontdrawblack);
    drawsprite(arr2,350+arr1.width+5+16+5,185-round(arr2.height/2),dontdrawblack);
  end;
  outtextxy(350+arr1.width+5,181,ss);
  myouttext(150,180,'Скорость игры:',el=2,right);
end;

procedure drawdiff;
begin
  ss:=diffs[options.diff];
  setfillstyle(1,lightblue);
  bar(350-5,218-3,466+5,228+3);
  if el=3 then
    setcolor(green) else
    setcolor(markedtxt);
  if el=3 then
  begin
    drawsprite(arr1,350,225-round(arr1.height/2),dontdrawblack);
    drawsprite(arr2,350+arr1.width+length(ss)*8+10,225-round(arr2.height/2),dontdrawblack);
  end;
  outtextxy(350+arr1.width+5,221,ss);
  myouttext(150,220,'Сложность игры:',el=3,right);
end;

procedure drawsound;
begin
  if options.sound=on then
    ss:='(Включен)' else
    ss:='(Выключен)';
  setfillstyle(1,lightblue);
  bar(350-5,258-9,466+5,268+3);
  if el=4 then
    setcolor(green) else
    setcolor(markedtxt);
  outtextxy(375,260,ss);
  setfillstyle(1,red);
  bar(349,254,366,271);
  setcolor(white);
  setlinestyle(0,0,3);
  rectangle(349,254,366,271);
  if options.sound=on then
    drawsprite(galk,349,250,dontdrawblack);
  myouttext(150,260,'Звук:',el=4,right);
end;

procedure drawlife;
begin
  if options.life=on then
    ss:='(Включено)' else
    ss:='(Выключено)';
  setfillstyle(1,lightblue);
  bar(350-5,298-9,466+5,308+3);
  if el=5 then
    setcolor(green) else
    setcolor(markedtxt);
  outtextxy(375,300,ss);
  setfillstyle(1,red);
  bar(349,294,366,311);
  setcolor(white);
  setlinestyle(0,0,3);
  rectangle(349,294,366,311);
  if options.life=on then
    drawsprite(galk,349,290,dontdrawblack);
  myouttext(150,300,'Существо:',el=5,right);
end;

procedure drawten;
begin
  if options.ten=on then
    ss:='(Включено)' else
    ss:='(Выключено)';
  setfillstyle(1,lightblue);
  bar(350-5,338-9,466+5,348+3);
  if el=6 then
    setcolor(green) else
    setcolor(markedtxt);
  outtextxy(375,340,ss);
  setfillstyle(1,red);
  bar(349,334,366,351);
  setcolor(white);
  setlinestyle(0,0,3);
  rectangle(349,334,366,351);
  if options.ten=on then
    drawsprite(galk,349,330,dontdrawblack);
  myouttext(150,340,'Тень фигуры:',el=6,right);
end;

procedure drawbb;
begin
  setfillstyle(1,lightblue);
  bar(150,375,550,395);
  myouttext(220,380,'Принять',el=7,center);
  myouttext(420,380,'Отмена',el=8,center);
end;

procedure draw(elm : byte);

begin
  case elm of
    0 : begin
          setfillstyle(1,lightblue);
          bar(60,60,580,420);
          myouttext(150,140,'Имя игрока:',el=1,right);
          myouttext(150,180,'Скорость игры:',el=2,right);
          myouttext(150,220,'Сложность игры:',el=3,right);
          myouttext(150,260,'Звук:',el=4,right);
          myouttext(150,300,'Существо:',el=5,right);
          myouttext(150,340,'Тень фигуры:',el=6,right);
          myouttext(220,380,'Принять',el=7,center);
          myouttext(420,380,'Отмена',el=8,center);
          drawname;
          drawspeed;
          drawdiff;
          drawsound;
          drawlife;
          drawten;
        end;
    1 : drawname;
    2 : drawspeed;
    3 : drawdiff;
    4 : drawsound;
    5 : drawlife;
    6 : drawten;
    7..8 : drawbb;
  end;
end;

procedure setcur;
var
  a : byte;
begin
  a:=getmpos;
  if (a<>el) and (a<>0) and (a<9) then
  begin
    dellabel;
    el:=el+2;
    draw(el-2);
    el:=a;
    draw(el);
    drawlabel;
  end;
  if ((a=0) or (a=2) or (a=3)) and (curs=1) then
  begin
    cur:=arr;
    curs:=0;
  end;
  if (a<>0) and (curs=0) and (a<>2) and (a<>3) then
  begin
    cur:=arm;
    curs:=1;
  end;
end;

procedure setoptions;
begin
  loadspritefromfile(galk,fgalk);
  maindraw;
  ncur:=length(options.name);
  el:=1;
  draw(0);
  drawlabel;
  setcur;
  sopt:=options;
  repeat
    getevent;
    if event.what=leftbutton then
    begin
      a:=getmpos;
      if a=el then
      begin
        case el of
          4..8 : begin
                   event.what:=keypress;
                   event.key:=13;
                 end;
          1 : begin
                a:=round((event.mx-350)/8);
                if a in [0..length(options.name)] then
                begin
                  ncur:=a;
                  drawname;
                end;
              end;
        end;
      end;
      if (a in [9,11]) then
      begin
        event.what:=keypress;
        event.key:=75*$FF;
      end;
      if (a in [10,12]) then
      begin
        event.what:=keypress;
        event.key:=77*$FF;
      end;
    end;
    if event.what=keypress then
    begin
      case event.key of
        72*$FF : begin
                   dellabel;
                   el:=el-1;
                   if el<1 then
                   begin
                     draw(1);
                     el:=8;
                   end else
                     draw(el+1);
                   draw(el);
                   drawlabel;
                 end;
        80*$FF : begin
                   dellabel;
                   el:=el+1;
                   if el>8 then
                   begin
                     draw(8);
                     el:=1;
                   end else
                     draw(el-1);
                   draw(el);
                   drawlabel;
                 end;
        13 : begin
               case el of
                 4 : begin
                       options.sound:=not options.sound;
                       drawsound;
                     end;
                 5 : begin
                       options.life:=not options.life;
                       drawlife;
                     end;
                 6 : begin
                       options.ten:=not options.ten;
                       drawten;
                     end;
                 7 : begin
                       assign(fopt,fdata);
                       rewrite(fopt);
                       write(fopt,options);
                       close(fopt);
                       sopt:=options;
                     end;
               end;
             end;
        75*$FF : begin
                   case el of
                     1 : begin
                           ncur:=ncur-1;
                           if ncur<0 then ncur:=0;
                           drawname;
                         end;
                     2 : begin
                           dec(options.speed);
                           if options.speed<minspeed then
                             options.speed:=minspeed;
                           drawspeed;
                         end;
                     3 : begin
                           dec(options.diff);
                           if options.diff<easy then
                             options.diff:=easy;
                           drawdiff;
                         end;
                   end;
                 end;
        77*$FF : begin
                   case el of
                     1 : begin
                           ncur:=ncur+1;
                           if ncur>length(options.name) then ncur:=length(options.name);
                           drawname;
                         end;
                     2 : begin
                           inc(options.speed);
                           if options.speed>maxspeed then
                             options.speed:=maxspeed;
                           drawspeed;
                         end;
                     3 : begin
                           inc(options.diff);
                           if options.diff>hard then
                             options.diff:=hard;
                           drawdiff;
                         end;
                   end;
                 end;
        71*$FF : begin
                   case el of
                     1 : begin
                           ncur:=0;
                           drawname;
                         end;
                   end;
                 end;
        79*$FF : begin
                   case el of
                     1 : begin
                           ncur:=length(options.name);
                           drawname;
                         end;
                   end;
                 end;
        83*$FF : begin
                   case el of
                     1 : begin
                           if ncur<length(options.name) then
                           begin
                             options.name:=copy(options.name,0,ncur)+
                                           copy(options.name,ncur+2,length(options.name)-ncur);
                             drawname;
                           end;
                         end;
                   end;
                 end;
      end;
      if (event.key<=$FF) and (el=1) and
         (chr(event.key) in ['a'..'z','A'..'Z','0'..'9',
                             'а'..'п','р'..'я','А'..'Я',
                             '_',' ',#8]) and
         ((length(options.name)<15) or (event.key=8)) then
      begin
        if event.key<>8 then
          begin
            options.name:=copy(options.name,0,ncur)+chr(event.key)+
                          copy(options.name,ncur+1,length(options.name)-ncur+1);
            ncur:=ncur+1;
            if ncur>length(options.name) then ncur:=length(options.name);
          end else
          begin
            if length(options.name)>0 then
            begin
              options.name:=copy(options.name,0,ncur-1)+
                            copy(options.name,ncur+1,length(options.name)-ncur);
              ncur:=ncur-1;
            end;
          end;
        drawname;
      end;
    end;
    if event.what=mousemove then
      setcur;
  until ((event.key=13) and (el in [7..8])) or (event.key=27);
  options:=sopt;
  event.what:=nothing;
end;
end.