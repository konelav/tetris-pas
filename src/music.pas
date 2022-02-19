unit music;

interface

const
  dsize = 6;

type
  tnote = record
    hz : integer;
    dl : longint;
  end;

  tnotearray = array[0..10000] of tnote;

  pnotearray = ^tnotearray;

  tmusic = record
    size    : integer;
    data    : pnotearray;
  end;

procedure createmusic(var music : tmusic; size : integer);
procedure freemusic(var music : tmusic);
procedure savemusicinfile(music : tmusic; fn : string);
procedure loadmusicfromfile(var music : tmusic; fn : string);
procedure eqmusic(var mus1,mus2 : tmusic);

implementation

procedure eqmusic(var mus1,mus2 : tmusic);
var
  i : integer;
begin
  if (mus1.size=mus2.size) then
    for i:=0 to mus1.size do
      mus2.data^[i]:=mus1.data^[i];
end;

procedure createmusic(var music : tmusic; size : integer);
begin
  if music.data<>nil then
    freemusic(music);
  music.size:=size;
  getmem(music.data,size*dsize);
end;

procedure freemusic(var music : tmusic);
begin
  with music do
  begin
    freemem(data,size*dsize);
    size:=0;
    data:=nil;
  end;
end;

procedure savemusicinfile(music : tmusic; fn : string);
var
  f : file;
begin
  assign(f,fn);
  rewrite(f,1);
  blockwrite(f,music.size,2);
  blockwrite(f,music.data^,music.size*dsize);
  close(f);
end;

procedure loadmusicfromfile(var music : tmusic; fn : string);
var
  f : file;
  s : word;
  r : byte;
begin
  assign(f,fn);
{$I-}
  reset(f,1);
{$I+}
  r:=ioresult;
  if r<>0 then
  begin
    writeln('FILE ',fn,' OPEN ERROR N',r);
    readln;
    readln;
    halt;
  end;
  blockread(f,s,2);
  createmusic(music,s);
  blockread(f,music.data^,music.size*dsize);
  close(f);
end;

end.