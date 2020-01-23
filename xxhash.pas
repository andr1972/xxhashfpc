{****************************************************
 This file is FreePascal port of xxHash

  Copyright (C) 2014 Vojtěch Čihák, Czech Republic

  http://sourceforge.net/projects/xxhashfpc/files/

  This library is free software. See the files
  COPYING.modifiedLGPL.txt and COPYING.LGPL.txt,
  included in this distribution,
  for details about the license.
****************************************************}

unit xxHash;
{$mode objfpc}{$H+}

interface

const
  cPrime32x1: LongWord = 2654435761;
	cPrime32x2: LongWord = 2246822519;
	cPrime32x3: LongWord = 3266489917;
	cPrime32x4: LongWord = 668265263;
	cPrime32x5: LongWord = 374761393;

  cPrime64x1: QWord = 11400714785074694791;
  cPrime64x2: QWord = 14029467366897019727;
  cPrime64x3: QWord = 1609587929392839161;
  cPrime64x4: QWord = 9650029242287828579;
  cPrime64x5: QWord = 2870177450012600261;

type
  { TxxHash32 }
  TxxHash32 = class
  private
    FBuffer: Pointer;
    FMemSize: LongInt;
    FSeed: LongWord;
    FTotalLength: QWord;
    FV1, FV2, FV3, FV4: LongWord;
  public
    constructor Create(ASeed: LongWord = 0);
    destructor Destroy; override;
    function Digest: LongWord;
    procedure Reset;
    function Update(ABuffer: Pointer; ALength: LongInt): Boolean;
    property Seed: LongWord read FSeed write FSeed;
  end;

  { TxxHash64 }
  TxxHash64 = class
  private
    FBuffer: Pointer;
    FMemSize: LongInt;
    FSeed: QWord;
    FTotalLength: QWord;
    FV1, FV2, FV3, FV4: QWord;
  public
    constructor Create(ASeed: QWord = 0);
    destructor Destroy; override;
    function Digest: QWord;
    procedure Reset;
    function Update(ABuffer: Pointer; ALength: LongWord): Boolean;
    property Seed: QWord read FSeed write FSeed;
  end;

  function xxHash32Calc(ABuffer: Pointer; ALength: LongInt; ASeed: LongWord = 0): LongWord; overload;
  function xxHash32Calc(const ABuffer: array of Byte; ASeed: LongWord = 0): LongWord; overload;
  function xxHash32Calc(const AString: string; ASeed: LongWord = 0): LongWord; overload;

  function xxHash64Calc(ABuffer: Pointer; ALength: LongInt; ASeed: QWord = 0): QWord; overload;
  function xxHash64Calc(const ABuffer: array of Byte; ASeed: QWord = 0): QWord; overload;
  function xxHash64Calc(const AString: string; ASeed: QWord = 0): QWord; overload;

implementation

function xxHash32Calc(ABuffer: Pointer; ALength: LongInt; ASeed: LongWord = 0): LongWord;
var v1, v2, v3, v4: LongWord;
    pLimit, pEnd: Pointer;
begin
  pEnd := ABuffer + ALength;
  if ALength >= 16 then
    begin
      pLimit := pEnd - 16;
      v1 := ASeed + cPrime32x1 + cPrime32x2;
      v2 := ASeed + cPrime32x2;
      v3 := ASeed;
      v4 := ASeed - cPrime32x1;

      repeat
        v1 := cPrime32x1 * RolDWord(v1 + cPrime32x2 * PLongWord(ABuffer)^, 13);
        v2 := cPrime32x1 * RolDWord(v2 + cPrime32x2 * PLongWord(ABuffer+4)^, 13);
        v3 := cPrime32x1 * RolDWord(v3 + cPrime32x2 * PLongWord(ABuffer+8)^, 13);
        v4 := cPrime32x1 * RolDWord(v4 + cPrime32x2 * PLongWord(ABuffer+12)^, 13);
        inc(ABuffer, 16);
      until not (ABuffer <= pLimit);

      Result := RolDWord(v1, 1) + RolDWord(v2, 7) + RolDWord(v3, 12) + RolDWord(v4, 18);
    end else
    Result := ASeed + cPrime32x5;

  inc(Result, ALength);

  while ABuffer <= (pEnd - 4) do
    begin
      Result := Result + PLongWord(ABuffer)^ * cPrime32x3;
      Result := RolDWord(Result, 17) * cPrime32x4;
      inc(ABuffer, 4);
    end;

  while ABuffer < pEnd do
    begin
      Result := Result + PByte(ABuffer)^ * cPrime32x5;
      Result := RolDWord(Result, 11) * cPrime32x1;
      inc(ABuffer);
    end;

  Result := Result xor (Result shr 15);
  Result := Result * cPrime32x2;
  Result := Result xor (Result shr 13);
  Result := Result * cPrime32x3;
  Result := Result xor (Result shr 16);
end;

function xxHash32Calc(const ABuffer: array of Byte; ASeed: LongWord): LongWord;
begin
  Result := xxHash32Calc(@ABuffer[0], length(ABuffer), ASeed);
end;

function xxHash32Calc(const AString: string; ASeed: LongWord): LongWord;
begin
  Result := xxHash32Calc(PChar(AString), length(AString), ASeed);
end;

function xxHash64Calc(ABuffer: Pointer; ALength: LongInt; ASeed: QWord): QWord;
var v1, v2, v3, v4: QWord;
    pLimit, pEnd: Pointer;
begin
  pEnd := ABuffer + ALength;

  if ALength >= 32 then
    begin
      v1 := ASeed + cPrime64x1 + cPrime64x2;
      v2 := ASeed + cPrime64x2;
      v3 := ASeed;
      v4 := ASeed - cPrime64x1;

      pLimit := pEnd - 32;
      repeat
        v1 := cPrime64x1 * RolQWord(v1 + cPrime64x2 * PQWord(ABuffer)^, 31);
        v2 := cPrime64x1 * RolQWord(v2 + cPrime64x2 * PQWord(ABuffer+8)^, 31);
        v3 := cPrime64x1 * RolQWord(v3 + cPrime64x2 * PQWord(ABuffer+16)^, 31);
        v4 := cPrime64x1 * RolQWord(v4 + cPrime64x2 * PQWord(ABuffer+24)^, 31);
        inc(ABuffer, 32);
      until not (ABuffer <= pLimit);

      Result := RolQWord(v1, 1) + RolQWord(v2, 7) + RolQWord(v3, 12) + RolQWord(v4, 18);

      v1 := RolQWord(v1 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v1) * cPrime64x1 + cPrime64x4;

      v2 := RolQWord(v2 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v2) * cPrime64x1 + cPrime64x4;

      v3 := RolQWord(v3 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v3) * cPrime64x1 + cPrime64x4;

      v4 := RolQWord(v4 * cPrime64x2, 31) * cPrime64x1;
      Result := (Result xor v4) * cPrime64x1 + cPrime64x4;
    end else
    Result := ASeed + cPrime64x5;

  inc(Result, ALength);

  while ABuffer <= (pEnd - 8) do
    begin
      Result := Result xor (cPrime64x1 * RolQWord(cPrime64x2 * PQWord(ABuffer)^, 31));
    	Result := RolQWord(Result, 27) * cPrime64x1 + cPrime64x4;
    	inc(ABuffer, 8);
    end;

  if ABuffer <= (pEnd - 4) then
    begin
    	Result := (Result xor PLongWord(ABuffer)^) * cPrime64x1;
      Result := RolQWord(Result, 23) * cPrime64x2 + cPrime64x3;
      inc(ABuffer, 4);
    end;

  while ABuffer < pEnd do
    begin
      Result := Result xor (PByte(ABuffer)^ * cPrime64x5);
      Result := RolQWord(Result, 11) * cPrime64x1;
      inc(ABuffer);
    end;

  Result := Result xor (Result shr 33);
  Result := Result * cPrime64x2;
  Result := Result xor (Result shr 29);
  Result := Result * cPrime64x3;
  Result := Result xor (Result shr 32);
end;

function xxHash64Calc(const ABuffer: array of Byte; ASeed: QWord): QWord;
begin
  Result := xxHash64Calc(@ABuffer[0], length(ABuffer), ASeed);
end;

function xxHash64Calc(const AString: string; ASeed: QWord): QWord;
begin
  Result := xxHash64Calc(PChar(AString), length(AString), ASeed);
end;

{ TxxHash32 }

constructor TxxHash32.Create(ASeed: LongWord);
begin
  FSeed := ASeed;
  Reset;
  FBuffer := GetMem(16);
end;

destructor TxxHash32.Destroy;
begin
  Freemem(FBuffer, 16);
  inherited Destroy;
end;

function TxxHash32.Digest: LongWord;
var pBuffer, pEnd: Pointer;
begin
  if FTotalLength >= 16
    then Result := RolDWord(FV1, 1) + RolDWord(FV2, 7) + RolDWord(FV3, 12) + RolDWord(FV4, 18)
    else Result := Seed + cPrime32x5;
  inc(Result, FTotalLength);

  pBuffer := FBuffer;
  pEnd := pBuffer + FMemSize;
  while pBuffer <= (pEnd - 4) do
    begin
      Result := Result + PLongWord(pBuffer)^ * cPrime32x3;
      Result := RolDWord(Result, 17) * cPrime32x4;
      inc(pBuffer, 4);
    end;

  while pBuffer < pEnd do
    begin
      Result := Result + PByte(pBuffer)^ * cPrime32x5;
      Result := RolDWord(Result, 11) * cPrime32x1;
      inc(pBuffer);
    end;

  Result := Result xor (Result shr 15);
  Result := Result * cPrime32x2;
  Result := Result xor (Result shr 13);
  Result := Result * cPrime32x3;
  Result := Result xor (Result shr 16);
end;

procedure TxxHash32.Reset;
begin
  FV1 := Seed + cPrime32x1 + cPrime32x2;
  FV2 := Seed + cPrime32x2;
  FV3 := Seed + 0;
  FV4 := Seed - cPrime32x1;
  FTotalLength := 0;
  FMemSize := 0;
end;

function TxxHash32.Update(ABuffer: Pointer; ALength: LongInt): Boolean;
var v1, v2, v3, v4: LongWord;
    pHelp, pEnd, pLimit: Pointer;
begin
  FTotalLength := FTotalLength + ALength;

  if (FMemSize + ALength) < 16 then  { not enough data, store them to the next Update }
    begin
      pHelp := FBuffer + FMemSize;
      Move(ABuffer^, pHelp^, ALength);
      FMemSize := FMemSize + ALength;
      Result := True;
      Exit;  { Exit! }
    end;

  pEnd := ABuffer + ALength;

  if FMemSize > 0 then  { some data left from the previous Update }
    begin
      pHelp := FBuffer + FMemSize;
      Move(ABuffer^, pHelp^, 16 - FMemSize);

      FV1 := cPrime32x1 * RolDWord(FV1 + cPrime32x2 * PLongWord(FBuffer)^, 13);
      FV2 := cPrime32x1 * RolDWord(FV2 + cPrime32x2 * PLongWord(FBuffer + 4)^, 13);
      FV3 := cPrime32x1 * RolDWord(FV3 + cPrime32x2 * PLongWord(FBuffer + 8)^, 13);
      FV4 := cPrime32x1 * RolDWord(FV4 + cPrime32x2 * PLongWord(FBuffer + 12)^, 13);

      ABuffer := ABuffer + (16 - FMemSize);
      FMemSize := 0;
    end;

  if ABuffer <= (pEnd - 16) then
    begin
      v1 := FV1;
      v2 := FV2;
      v3 := FV3;
      v4 := FV4;

      pLimit := pEnd - 16;
      repeat
        v1 := cPrime32x1 * RolDWord(v1 + cPrime32x2 * PLongWord(ABuffer)^, 13);
        v2 := cPrime32x1 * RolDWord(v2 + cPrime32x2 * PLongWord(ABuffer+4)^, 13);
        v3 := cPrime32x1 * RolDWord(v3 + cPrime32x2 * PLongWord(ABuffer+8)^, 13);
        v4 := cPrime32x1 * RolDWord(v4 + cPrime32x2 * PLongWord(ABuffer+12)^, 13);
        inc(ABuffer, 16);
      until not (ABuffer <= pLimit);

      FV1 := v1;
      FV2 := v2;
      FV3 := v3;
      FV4 := v4;
    end;

  if ABuffer < pEnd then  { store remaining data to the next Update or to Digest }
    begin
      pHelp := FBuffer;
      Move(ABuffer^, pHelp^, pEnd - ABuffer);
      FMemSize := pEnd - ABuffer;
    end;

  Result := True;
end;

{ TxxHash64 }

constructor TxxHash64.Create(ASeed: QWord);
begin
  FSeed := ASeed;
  Reset;
  FBuffer := GetMem(32);
end;

destructor TxxHash64.Destroy;
begin
  Freemem(FBuffer, 32);
  inherited Destroy;
end;

function TxxHash64.Digest: QWord;
var v1, v2, v3, v4: QWord;
    pBuffer, pEnd: Pointer;
begin
  if FTotalLength >= 32 then
    begin
      v1 := FV1;
      v2 := FV2;
      v3 := FV3;
      v4 := FV4;

      Result := RolQWord(v1, 1) + RolQWord(v2, 7) + RolQWord(v3, 12) + RolQWord(v4, 18);

      v1 := RolQWord(v1 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v1) * cPrime64x1 + cPrime64x4;

      v2 := RolQWord(v2 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v2) * cPrime64x1 + cPrime64x4;

      v3 := RolQWord(v3 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v3) * cPrime64x1 + cPrime64x4;

      v4 := RolQWord(v4 * cPrime64x2, 31) * cPrime64x1;
      Result := (Result xor v4) * cPrime64x1 + cPrime64x4;
    end else
    Result := Seed + cPrime64x5;

  Result := Result + FTotalLength;

  pBuffer := FBuffer;
  pEnd := pBuffer + FMemSize;
  while pBuffer <= (pEnd - 8) do
    begin
      Result := Result xor (cPrime64x1 * RolQWord(cPrime64x2 * PQWord(pBuffer)^, 31));
    	Result := RolQWord(Result, 27) * cPrime64x1 + cPrime64x4;
    	inc(pBuffer, 8);
    end;

  if pBuffer <= (pEnd - 4) then
    begin
      Result := (Result xor PLongWord(pBuffer)^) * cPrime64x1;
      Result := RolQWord(Result, 23) * cPrime64x2 + cPrime64x3;
      inc(pBuffer, 4);
    end;

  while pBuffer < pEnd do
    begin
      Result := (Result xor PByte(pBuffer)^) * cPrime64x5;
      Result := RolQWord(Result, 11) * cPrime64x1;
      inc(pBuffer);
    end;

  Result := Result xor (Result shr 33);
  Result := Result * cPrime64x2;
  Result := Result xor (Result shr 29);
  Result := Result * cPrime64x3;
  Result := Result xor (Result shr 32);
end;

procedure TxxHash64.Reset;
begin
  FV1 := Seed + cPrime64x1 + cPrime64x2;
  FV2 := Seed + cPrime64x2;
  FV3 := Seed + 0;
  FV4 := Seed - cPrime64x1;
  FTotalLength := 0;
  FMemSize := 0;
end;

function TxxHash64.Update(ABuffer: Pointer; ALength: LongWord): Boolean;
var v1, v2, v3, v4: QWord;
    pHelp, pEnd, pLimit: Pointer;
begin
  FTotalLength := FTotalLength + ALength;
  if (FMemSize + ALength) < 32 then  { not enough data, store them to the next Update }
    begin
      pHelp := FBuffer + FMemSize;
      Move(ABuffer^, pHelp^, ALength);
      FMemSize := FMemSize + ALength;
      Result := True;
      Exit;  { Exit! }
    end;

  pEnd := ABuffer + ALength;

  if FMemSize > 0 then  { some data left from the previous Update }
    begin
      pHelp := FBuffer + FMemSize;
      Move(FBuffer^, pHelp^, 32 - FMemSize);

      FV1 := cPrime64x1 * RolQWord(FV1 + cPrime64x2 * PQWord(FBuffer)^, 31);
      FV2 := cPrime64x1 * RolQWord(FV2 + cPrime64x2 * PQWord(FBuffer+8)^, 31);
      FV3 := cPrime64x1 * RolQWord(FV3 + cPrime64x2 * PQWord(FBuffer+16)^, 31);
      FV4 := cPrime64x1 * RolQWord(FV4 + cPrime64x2 * PQWord(FBuffer+24)^, 31);

      ABuffer := ABuffer + (32 - FMemSize);
      FMemSize := 0;
    end;

  if ABuffer <= (pEnd - 32) then
    begin
      v1 := FV1;
      v2 := FV2;
      v3 := FV3;
      v4 := FV4;

      pLimit := pEnd - 32;
      repeat
        v1 := cPrime64x1 * RolQWord(v1 + cPrime64x2 * PQWord(ABuffer)^, 31);
        v2 := cPrime64x1 * RolQWord(v2 + cPrime64x2 * PQWord(ABuffer+8)^, 31);
        v3 := cPrime64x1 * RolQWord(v3 + cPrime64x2 * PQWord(ABuffer+16)^, 31);
        v4 := cPrime64x1 * RolQWord(v4 + cPrime64x2 * PQWord(ABuffer+24)^, 31);
        inc(ABuffer, 32);
      until not (ABuffer <= pLimit);

      FV1 := v1;
      FV2 := v2;
      FV3 := v3;
      FV4 := v4;
    end;

  if ABuffer < pEnd then  { store remaining data to the next Update or to Digest }
    begin
      pHelp := FBuffer;
      Move(ABuffer^, pHelp^, pEnd - ABuffer);
      FMemSize := pEnd - ABuffer;
    end;

  Result := True;
end;

end.

