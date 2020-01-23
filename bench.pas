program Bench;
{$mode objfpc}

uses SysUtils, xxHash;

const cCycles = 100;

var aAlign: Byte;
    aBuff, aBuffAl: Pointer;
    aFile: file;
    i, aHash32, aLength: LongWord;
    aHash64: QWord;
    aTime: TDateTime;
begin
  writeln(ParamStr(1));
  if FileExists(ParamStr(1)) then
    begin
      AssignFile(aFile, ParamStr(1));
      Reset(aFile, 1);
      aLength:=FileSize(aFile);
      writeln(aLength, ' bytes');
      aBuff:=GetMem(aLength);
      BlockRead(aFile, aBuff^, aLength);

      writeln('Unaligned, 32-bit:');
      aTime:=Now;
      for i:=1 to cCycles do
        aHash32:=xxHash32Calc(aBuff, aLength, 0);
      aTime:=Now-aTime;
      aTime:=aTime*24*60*60/cCycles;
      writeln('Average speed: ', round(aLength/(aTime*(1 shl 20))), ' MB/s');
      writeln('Average time: '+floattostrF(1000*aTime, ffFixed, 0, 1)+' ms');
      writeln('xxHash32: $', hexStr(aHash32, 8));
      writeln('==========');

      writeln('Unaligned, 64-bit:');
      aTime:=Now;
      for i:=1 to cCycles do
        aHash64:=xxHash64Calc(aBuff, aLength, 0);
      aTime:=Now-aTime;
      aTime:=aTime*24*60*60/cCycles;
      writeln('Average speed: ', round(aLength/(aTime*(1 shl 20))), ' MB/s');
      writeln('Average time: '+floattostrF(1000*aTime, ffFixed, 0, 1)+' ms');
      writeln('xxHash32: $', hexStr(aHash64, 16));
      writeln('==========');
      FreeMem(aBuff, aLength);

      aAlign:=128;
      aBuff:=GetMem(aLength+(aAlign-1));
      aBuffAl:=aBuff+(aAlign-1) - (PtrUInt(aBuff+(aAlign-1)) and (aAlign-1));
      Reset(aFile, 1);
      BlockRead(aFile, aBuffAl^, aLength);
      writeln('Aligned to ', aAlign, 'B, 32-bit: (', PtrUInt(aBuffAl) and 255, ')');
      aTime:=Now;
      for i:=1 to cCycles do
        aHash32:=xxHash32Calc(aBuffAl, aLength, 0);
      aTime:=Now-aTime;
      aTime:=aTime*24*60*60/cCycles;
      writeln('Average speed: ', round(aLength/(aTime*(1 shl 20))), ' MB/s');
      writeln('Average time: '+floattostrF(1000*aTime, ffFixed, 0, 1)+' ms');
      writeln('xxHash32: $', hexStr(aHash32, 8));
      writeln('==========');
      FreeMem(aBuff, aLength+(aAlign-1));

      CloseFile(aFile);
    end else
    writeln('File not exists.');
end.
