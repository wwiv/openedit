Unit SEdit_Reg;

Interface

Function Decode(KeyStr: String; DataUEC: LongInt; RegFName: String): String;
Function StrUnreg: String;
Procedure BumpDecode(MSeg,MOfs,Size: Word);
Function CW(C: Byte; Seed: ShortInt): Byte;

Implementation

Uses DOS,Utilpack,Crt;

{.DEFINE Debug}
Const RegNameConst: String[80] = '';

Type
  stArray = Array[0..255] of Byte;
  GRType = Record
    R: Char;
    G: Array[1..4] Of Char;
   End;
  RealGarb = Record
    G8: LongInt;
    GR: Array[1..6] Of GRType;
    GC: Char;
    G7: LongInt;
   End;
  KeyType = Array[1..255] Of RealGarb;
  RegKeyType = Record
    RegData: String[246];
    CRC: LongInt;
    Reg: KeyType;
    FinalData: Array[1..40] Of Char;
    EORegData: String[3];
   End;

Const
 CRC_32_Tab: Array[0..255] Of LongInt = (
  $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535, $9e6495a3,
  $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91,
  $1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7,
  $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9, $fa0f3d63, $8d080df5,
  $3b6e20c8, $4c69105e, $d56041e4, $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
  $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59,
  $26d930ac, $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
  $2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab, $b6662d3d,
  $76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433,
  $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
  $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457,
  $65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65,
  $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb,
  $4369e96a, $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
  $5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
  $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81, $b7bd5c3b, $c0ba6cad,
  $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615, $73dc1683,
  $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8, $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1,
  $f00f9344, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb, $196c3671, $6e6b06e7,
  $fed41b76, $89d32be0, $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
  $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
  $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef, $4669be79,
  $cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703, $220216b9, $5505262f,
  $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d,
  $9b64c2b0, $ec63f226, $756aa39c, $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
  $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21,
  $86d3d2d4, $f1d4e242, $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777,
  $88085ae6, $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3, $166ccf45,
  $a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d, $3e6e77db,
  $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
  $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $cdd70693, $54de5729, $23d967bf,
  $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
 );
Var
  S: String;
  UEC: LongInt;
  TmpR: Real;
  Letter: Byte;
  TimeDate: String;
  MajorTimeDate: String;
  RegKey: KeyType;
  RegKeyInfo: RegKeyType;
  RegFile: File Of RegKeyType;
  Match: Array[1..255] Of Real;

Function MakeCodeStr(key : LongInt; Var s): String;
Var
  x: Word;
  len: Byte Absolute s;
  st: Array[0..255] of Byte Absolute s;
Begin
  RandSeed := (key * len) div st[len];
  MakeCodeStr[0] := chr(len);
  For x := 1 to len do MakeCodeStr[x] := chr(32 + Random(95));
End;

Function Key(Var s): LongInt;
Var
  x: Byte;
  temp: LongInt;
  c: Array[1..64] of LongInt Absolute s;
  len: Byte Absolute s;
begin
  temp:= 0;
  For x := 1 to len div 4 do temp := temp xor c[x]; Key := Abs(temp);
end;

Function StrUnreg: String;
Const
  Unr: String[12] = ('������������'); Var S: String; Tmp: Byte;
Begin
  S:=Unr; For Tmp:=Length(S) DownTo 1 Do S[Tmp]:=Chr(Ord(Unr[Tmp]) Xor 666);
  StrUnreg:=S;
End;

Function DecryptStr(key : LongInt; s: String): String;
Var
  cnt,x: Byte;
  st: stArray Absolute s;
  len: Byte Absolute s;
  CodeStr: stArray;
  temp: String Absolute CodeStr;
  ch: Char;
begin
  cnt:= st[len] and 127;
  st[len]:= cnt xor len;
  temp:= MakeCodeStr(key,st);
  DecryptStr[0]:= chr(len);
  DecryptStr[len]:= chr(st[len]);
  For x := 1 to len-1 do
  begin
    cnt:=st[x];
    dec(cnt,128 * ord(st[x] > 127));
    DecryptStr[x] := chr(cnt xor CodeStr[x]);
  end;  { For }
end;

Procedure MemSeedDecode(_Seg,_Ofs,_Size: Word; _Seed: LongInt);
Var
  Tmp: Word;
  Work: Byte;
Begin
  _Seed:=Trunc(_Seed * 2 / Pi);
  For Tmp:=0 To _Size Do
  If Tmp Mod 4 = 0 Then
  Begin
    Mem[_Seg:_Ofs+Tmp-3]:=Byte(Mem[_Seg:_Ofs+Tmp-3]-Mem[Seg(_Seed):Ofs(_Seed)+0]);
    Mem[_Seg:_Ofs+Tmp-2]:=Byte(Mem[_Seg:_Ofs+Tmp-2]-Mem[Seg(_Seed):Ofs(_Seed)+1]);
    Mem[_Seg:_Ofs+Tmp-1]:=Byte(Mem[_Seg:_Ofs+Tmp-1]-Mem[Seg(_Seed):Ofs(_Seed)+2]);
    Mem[_Seg:_Ofs+Tmp-0]:=Byte(Mem[_Seg:_Ofs+Tmp-0]-Mem[Seg(_Seed):Ofs(_Seed)+3]);
  End;
End;

Function SBKey(Var C: Char): LongInt;
Begin
  SBKey:=Ord(C)+Trunc(Ord(MajorTimeDate[Ord(C)])*Pi);
End;

Function CW(C: Byte; Seed: ShortInt): Byte;
Var
  I: LongInt;
Begin
  I:=C+Seed;
  If (Seed>0) Then Begin If I<=255 Then C:=I Else
  Begin
    While I>255 Do Dec(I,256);
    C:=I;
  End;
  End
  Else
  Begin
    If I>=0 Then C:=I Else
    Begin
      While I<0 Do Inc(I,256); C:=I;
    End;
  End; CW:=C;
End;

Procedure BumpDecode(MSeg,MOfs,Size: Word);
Var
  TmpW: Word;
  Adjust: Byte;
Begin
  Mem[MSeg:MOfs+Size-1]:=Mem[MSeg:MOfs+Size-1]-192;
  For TmpW:=Size DownTo 1 Do
  Begin
    If TmpW<>Size Then
    Mem[MSeg:MOfs+TmpW-1]:=CW(Mem[MSeg:MOfs+TmpW-1],-Mem[MSeg:MOfs+TmpW]);
  End;
End;

Procedure MemDecode(MSeg,MOfs,Size: Word);
Var
  TmpW: Word;
  Adjust: Byte;
Begin
  For TmpW:=Size DownTo 1 Do
  Begin
   Adjust:=(Ord(MajorTimeDate[TmpW Mod 111])*3+(Ord(MajorTimeDate[TmpW Mod 163]) Xor Ord(MajorTimeDate[TmpW Mod 142+1])))
            Xor (TmpW*(Ord(MajorTimeDate[TmpW Mod 122])));
   If TmpW<>Size Then
   Mem[MSeg:MOfs+TmpW-1]:=CW(Mem[MSeg:MOfs+TmpW-1],-SHORTINT(Mem[MSeg:MOfs+TmpW-1+1])-Adjust);
  End;
End;


Function Char2Real(C: Char): Real;
Begin
  Char2Real:=Match[Ord(C)];
End;

Function Real2Char(R: Real): Char;
Var
  Tmp: Byte;
Begin
  For Tmp:=1 To 255 Do If R=Match[Tmp] Then
  Begin
    Real2Char:=Chr(Tmp);
    Exit;
  End;
End;

Function UpdC32(octet: BYTE; crc: LONGINT) : LONGINT;
Begin
  UpdC32:=crc_32_tab[BYTE(crc XOR LONGINT(octet))] XOR ((crc SHR 8) AND $00FFF8FF)
End;

Function MemCRC32(MSeg,MOfs,Size: Word): LongInt;
Var
  CRC: LongInt;
  TmpW: Word;
Begin
  CRC:=$FEBAABEF; For TmpW:=1 To Size Do CRC:=UpdC32(Mem[MSeg:MOfs+TmpW-1],CRC); MemCRC32:=CRC;
End;

Function Relocate(B: Byte): Byte;
Begin
  Case B Of
    1 : B:=8;  2 : B:=5; 3 : B:=4;  4 : B:=11; 5 : B:=10;
    6 : B:=12; 7 : B:=9; 8 : B:=6;  9 : B:=13; 10: B:=15;
    11: B:=16; 12: B:=2; 13: B:=14; 14: B:=3;  15: B:=7;
    16: B:=1;
  End;
  Relocate:=B;
End;

Function DoCheck(R: RealGarb; Chek: Byte): LongInt;
Var
  Out: LongInt;
  Tmp: Byte;
Begin
  Out:=$993FABCD;
  Case Chek Of
    1: Begin
         For Tmp:=1 To 6 Do
           Out:=Out Xor (Ord(R.GR[Tmp].R)*$BACED) Xor ($A1B*(
           Ord(R.GR[Tmp].G[1])+Ord(R.GR[Tmp].G[2])+Ord(R.GR[Tmp].G[3])+Ord(R.GR[Tmp].G[4])));
       End;
   2: Begin
        For Tmp:=1 To 6 Do
        Out:=Out Xor (Ord(R.GR[Tmp].R)*$22CD1) Xor ((Out SHR 6) AND $E0E0FABA);
       Out:=Out Xor R.G7;
      End;
  End;
 DoCheck:=Out;
End;


{$F+}
Procedure KillHackerSS; Interrupt;             { Cold boot for single-steps }
Begin
 Inline($FB/$B8/01/00/$8E/$D8/$B8/$34/$12/$A3/$72/$04/$EA/$00/$00/$FF/$FF);
End;

Procedure KillHackerBP; Interrupt;              { Cold boot for breakpoints }
Begin
 Inline($FB/$B8/01/00/$8E/$D8/$B8/$34/$12/$A3/$72/$04/$EA/$00/$00/$FF/$FF);
End;
{$F-}


Function Decode(KeyStr: String; DataUEC: LongInt; RegFName: String): String;
Var
 TmpCount,
 Find: Byte;
 TmpL,
 Tmp,LI,CmpCRC: LongInt;
 DT: DateTime;
 FinishedOrig,Decrypted,FinishedKey,OldKey,KeyTmp: String;
 OldInt1Vec,
 OldInt3Vec: Pointer;
 Quitit: Boolean;
 TmpCnt: Byte;
 TotalG7,TotalG8: LongInt;
Begin
{$IFNDEF Debug}
 GetIntVec($01,OldInt1Vec);
 GetIntVec($03,OldInt3Vec);

 SetIntVec($01,@KillHackerSS);
 SetIntVec($03,@KillHackerBP);
{$ENDIF}
 RegNameConst:=RegFName;
 FillChar(RegKey,SizeOf(RegKey),#0); FillChar(RegKeyInfo,SizeOf(RegKeyInfo),#0);
 For Tmp:=1 To 255 Do
  Match[Tmp]:=Trunc(Tmp*(Cos(Tmp)*986)*(Sin(Tmp)*986)/(ArcTan(Tmp)/Pi));

 Assign(RegFile,RegNameConst);
 Reset(RegFile); Read(RegFile,RegKeyInfo); GetFTime(RegFile,LI); Close(RegFile);
 UnpackTime(LI,DT);
 TimeDate:=LeadingZero(DT.Month)+'-'+LeadingZero(DT.Day)+'-'+StrVal(DT.Year)+
           FPad(StrVal(DT.Hour),2)+':'+LeadingZero(DT.Min);
 MajorTimeDate:=TimeDate; For Tmp:=1 To 15 Do MajorTimeDate:=MajorTimeDate+TimeDate+' ';
 RegKey:=RegKeyInfo.Reg;

 BumpDecode(Seg(RegKey),Ofs(RegKey),SizeOf(RegKey));

 MemSeedDecode(Seg(RegKey),Ofs(RegKey),SizeOf(RegKey),DataUEC);

 MemDecode(Seg(RegKey),Ofs(RegKey),SizeOf(RegKey));

 If RegKeyInfo.CRC<>MemCRC32(Seg(RegKey),Ofs(RegKey),SizeOf(RegKey)) Then
  Begin
   Decode:=StrUnreg;
   {$IFNDEF Debug} SetIntVec($01,OldInt1Vec); SetIntVec($03,OldInt3Vec); {$ENDIF}
   Exit;
  End;

 MemDecode(Seg(RegKey),Ofs(RegKey),SizeOf(RegKey));

 BumpDecode(Seg(RegKey),Ofs(RegKey),SizeOf(RegKey));

 FinishedOrig:=''; FinishedKey:=''; Letter:=1;
 QuitIt:=False;
 While Not QuitIt Do
  Begin
   For TmpCnt:=1 To 6 Do
    Move(RegKey[Letter].GR[TmpCnt].R,Mem[Seg(TmpR):Ofs(TmpR)+TmpCnt-1],1);
   If TmpR=0 Then
    QuitIt:=True
   Else
    FinishedKey:=FinishedKey+Real2Char(TmpR); Inc(Letter);
  End;
 FinishedKey:=DecryptStr(Length(FinishedKey),FinishedKey);
 For Letter:=1 To Length(FinishedKey) Do
  Begin
   TmpL:=DoCheck(RegKey[Letter],1);
   If RegKey[Letter].G7<>TmpL Then
    Begin
     Decode:=StrUnreg;
     {$IFNDEF Debug} SetIntVec($01,OldInt1Vec); SetIntVec($03,OldInt3Vec); {$ENDIF}
     Exit;
    End;
   TotalG7:=TotalG7+TmpL;

   TmpL:=DoCheck(RegKey[Letter],2);
   If RegKey[Letter].G8<>TmpL Then
    Begin
     Decode:=StrUnreg;
     {$IFNDEF Debug} SetIntVec($01,OldInt1Vec); SetIntVec($03,OldInt3Vec); {$ENDIF}
     Exit;
    End;
   TotalG8:=TotalG8+TmpL;
  End;
 Repeat
  KeyTmp:=Copy(FinishedKey,Length(FinishedKey)-3,4); Delete(FinishedKey,Length(FinishedKey)-3,4);
  Decrypted:=KeyTmp;
  For Tmp:=1 To 3 Do Decrypted:=DecryptStr(SBKey(KeyStr[Tmp]),Decrypted);
  KeyTmp:=Decrypted;
  For Tmp:=1 To 4 Do
   If IntVal('$'+KeyTmp[Tmp])=-1 Then
    Begin
     Decode:=StrUnreg;
     {$IFNDEF Debug} SetIntVec($01,OldInt1Vec); SetIntVec($03,OldInt3Vec); {$ENDIF}
     Exit;
    End;
  Letter:=Length(FinishedOrig)+1;
  If Ord(KeyStr[Length(KeyStr)-Letter+1])<>0 Then
   FinishedOrig:=FinishedOrig+Chr(IntVal('$'+KeyTmp) Div Ord(KeyStr[Length(KeyStr)-Letter+1]));
 Until FinishedKey='';
 If FinishedOrig<>KeyStr Then
  Decode:=StrUnreg
 Else
   Decode:=FinishedOrig;
 {$IFNDEF Debug} SetIntVec($01,OldInt1Vec); SetIntVec($03,OldInt3Vec); {$ENDIF}
End;

End.
