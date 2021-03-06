Program DictSort;
{$M 64000,0,400000}
{$I c:\bp\oedit\DEFINES.INC}
Uses Utilpack,Crt,DOS;
{$I c:\bp\oedit\SEDIT.INC}
Type
 Str35 = String[36];
Const
 MaxEntries = 4000;
 MaxExtra   = 1500;
Var
 Config: ConfigRec;
 ConfigFile: File Of ConfigRec;
 CfgPath: String;
 HoldSort: Array[1..MaxEntries] Of ^Str35;
 ExtraHold: Array[1..MaxExtra] Of ^Str35;
 FSDF: LongInt;
 HS: Word;
 EH: Word;
 StartTime: Real;
 WordCnt: LongInt;
 Work,Work2,
 Compare,
 S: String;
 ShouldBePos: LongInt;
 LenByte: Char;
 MiscWordStart: LongInt;
 MajorC,MinorC,MinorxC: Byte;

 Idx: LongInt;
 IdxFile: File Of LongInt;
 DatFile: File;

 NewIdx: LongInt;
 NewIdxFile: File Of LongInt;
 NewDatFile: File;

 NR,
 Tmp: Word;

 Count,
 Count2             : Word;
 Buf                : Array[1..256] Of Byte;

Procedure Switch(x1,x2: Word);
Var Hold: String;
Begin
 Hold:=HoldSort[x1]^;
 HoldSort[x1]^:=HoldSort[x2]^;
 HoldSort[x2]^:=Hold;
End;

Procedure Keyprocess;
Begin
 If ReadKey=#27 Then
  Begin
   WriteLn; WriteLn(' � Program Terminated.');
   WriteLn(MakeStr(78,#196));
   Close(NewDatfile);
   Close(NewIdxFile);
   Erase(NewDatFile);
   Erase(NewIdxFile);
   Halt;
  End;
End;

Procedure LoadConfig;
Begin
 CfgPath:=FExpand(GetEnv('OEDIT'));
 cfgpath:= (cfgpath+'\DICT');

 If CfgPath[Length(CfgPath)]<>'\' Then CfgPath:=CfgPath+'\';
 CfgPath:=FExpand(RemoveWildCard(ParamStr(0)));
 Assign(ConfigFile,CfgPath+'OEDIT.CFG');
 FileMode:=66; {$I-} Reset(ConfigFile); {$I+} FileMode:=2;

 { * Check in current directory                      }
 If IOResult<>0 Then
  Begin
   CfgPath:=FExpand(''); Assign(ConfigFile,CfgPath+'OEDIT.CFG');
   FileMode:=66; {$I-} Reset(ConfigFile); {$I+} FileMode:=2;
  End;

 { * Check in execution path                         }
 If IOResult<>0 Then
  Begin
   CfgPath:=FExpand(RemoveWildCard(ParamStr(0)));
   Assign(ConfigFile,CfgPath+'OEDIT.CFG');
   FileMode:=66; {$I-} Reset(ConfigFile); {$I+} FileMode:=2;
  End;

 { * Can't find the damned thing                     }
 If IOResult<>0 Then
  Begin
   Writeln('');
   WriteLn('� Cannot locate OEDIT.CFG.  Please run DICTSORT from the Open!EDIT directory.');
   Halt;
  End;
{ Read(ConfigFile,Config);}
 Close(ConfigFile);
{ If Config.DictionaryPath[Length(Config.DictionaryPath)]<>'\' Then Config.DictionaryPath:=Config.DictionaryPath+'\';}
 If Config.DictionaryPath[Length(Config.DictionaryPath)]<>'.\DICT' Then
    Config.DictionaryPath:=Config.DictionaryPath+'.\DICT\';
End;


{Label SmallOne;}
Begin                            {Do not check capitalized words}
 MajorC:=1; {A}
 MinorC:=1; {A}
 MinorxC:=1; {A}
 LoadConfig;

 Assign(IdxFile,Config.DictionaryPath+'OE_DIC.IDX');
 {$I-} Reset(IdxFile); {$I+}
 If IOresult<>0 Then
  Begin
   WriteLn('');
   WriteLn('� Could not locate ',Config.DictionaryPath+'OE_DIC.IDX!');
   Writeln('� Make sure OE_DIC.IDX is located in the .\DICT directory.');
   Halt;
  End;

 Assign(DatFile,Config.DictionaryPath+'OE_DIC.DAT');
 {$I-} Reset(DatFile,1); {$I+}
 If IOresult<>0 Then
  Begin
   WriteLn('');
   WriteLn('� Could not locate ',Config.DictionaryPath+'OE_DIC.DAT!');
   Writeln('� Make sure OE_DIC.DAT is located in the .\DICT directory.');
   Halt;
  End;

 FSDF:=FileSize(DatFile);
 Assign(NewIdxFile,Config.DictionaryPath+'$OE_DIC.IDX');
 ReWrite(NewIdxFile);
 Assign(NewDatFile,Config.DictionaryPath+'$OE_DIC.DAT');
 ReWrite(NewDatFile,1);

 WriteLn(' Open!EDIT DictSort v1.00');
 WriteLn(MakeStr(78,#196));
 WriteLn(' � Press <esc> at any time to abort');
 WriteLn(' � Working with OE_DIC.IDX and OE_DIC.DAT');
 WordCnt:=0;
 StartTime:=Timer;

 BlockRead(DatFile,Buf,256);
 BlockWrite(NewDatFile,Buf,256);

 If MemAvail<MaxEntries*SizeOf(Str35)+MaxExtra*SizeOf(Str35) Then
  Begin
   WriteLn(' � Insufficient memory:');
   WriteLn(' � ',MaxEntries*SizeOf(Str35)+MaxExtra*SizeOf(Str35),' required, ',MemAvail,' available.');
   WriteLn(MakeStr(78,#196));
   Halt;
  End;

 For Tmp:=1 To MaxEntries Do New(HoldSort[Tmp]);
 For Tmp:=1 To MaxExtra Do New(ExtraHold[Tmp]);

 EH:=0;

    Seek(DatFile,252); {Header Smaller Size}
    BlockRead(DatFile,MiscWordStart,SizeOf(MiscWordStart),NR);
    If (MiscWordStart=$1A0A0D73) Or (MiscWordStart=0) Or (MiscWordStart=16777216) Then MiscWordStart:=440061;
     { ^ Old Dict Style }
    Seek(DatFile,MiscWordStart+256);
    Repeat
     BlockRead(DatFile,S[0],1,NR);
     BlockRead(DatFile,Mem[Seg(S):Ofs(S)+1],Ord(S[0]),NR);
     Inc(EH); ExtraHold[EH]^:=S;
    Until (NR=0);

 Repeat
  Compare:=Chr(64+MajorC)+Chr(64+MinorC)+Chr(64+MinorxC);
  Write(#13,' � Processing: ',Compare);
  ShouldBePos:=((ord(Chr(64+MajorC))-Ord('A'))*26*26)+((ord(Chr(64+MinorC))-Ord('A'))*26)+(ord(Chr(64+MinorxC))-Ord('A'));
  if not Eof(IdxFile) then
  begin
   Seek(IdxFile,ShouldBePos);
   Read(IdxFile,Idx);
  end;

  HS:=0;
  If Idx<>-1 Then
   Begin
    Seek(DatFile,Idx+256);
    Repeat
     BlockRead(DatFile,S[0],1,NR);
     BlockRead(DatFile,Mem[Seg(S):Ofs(S)+1],Ord(S[0]),NR);
     Work:=S; While Length(Work)<3 Do Work:=Work+'A'; Work[0]:=#3;
     If (Work=Compare) And (NR<>0) Then
      Begin
       Inc(HS);
       If HS>MaxEntries Then
        Begin
         WriteLn;
         WriteLn(^G,' � ERROR: Overflow [HS>MaxEntries: ',HS,'>',MaxEntries,']');
         WriteLn(MakeStr(78,#196));
         Halt;
        End;
       HoldSort[HS]^:=S;
      End;
   Until (Work<>Compare) Or (NR=0);

   End;

 { Search extras that might be appended }
   For Count:=1 To EH Do
    Begin
     S:=ExtraHold[Count]^;
     Work:=S; While Length(Work)<3 Do Work:=Work+'A'; Work[0]:=#3;
     If Work=Compare Then
      Begin
       Inc(HS);
       If HS>MaxExtra Then
        Begin
         WriteLn;
         WriteLn(^G,' � ERROR: Overflow [HS>MaxExtra: ',HS,'>',MaxExtra,']');
         WriteLn(MakeStr(78,#196));
         Halt;
        End;
       HoldSort[HS]^:=S;
       ExtraHold[Count]^:=MakeStr(Length(ExtraHold[Count]^),#255);
      End;
    End;

    If HS>0 Then
     Begin
      Count:=0;
      Count2:=0;
      Repeat
       Inc(Count2);
       For Count:=1 To HS Do
        If HoldSort[Count]^>HoldSort[Count2]^ Then Switch(Count2,Count);
      Until Count2=HS;
     End;

    If HS<>0 Then
     Begin
      NewIdx:=FilePos(NewDatFile)-256;
      Write(NewIdxFile,NewIdx);
      For Tmp:=1 To HS Do
       Begin
        If HoldSort[Tmp]^<>MakeStr(Length(HoldSort[Tmp]^),#255) Then
         Begin
          BlockWrite(NewDatFile,HoldSort[Tmp]^[0],1);
          BlockWrite(NewDatFile,HoldSort[Tmp]^[1],Length(HoldSort[Tmp]^));
          Inc(WordCnt);
          If WordCnt Mod 1000 = 0 Then
           Write(#13,' � Processing: ',Compare,' (',FilePos(DatFile)*100/FSDF:0:1,'% Complete)');
         End;
       End;
     End
     Else
     Begin
      NewIdx:=-1;
      Write(NewIdxFile,NewIdx);
     End;

    If Mem[$0040:$001A]<>Mem[$0040:$001C] Then KeyProcess;

  Inc(MinorxC);
  If MinorxC=27 Then Begin Inc(MinorC); MinorxC:=1; End;
  If MinorC=27 Then Begin Inc(MajorC); MinorC:=1; End;
 Until (MajorC=27) And (MinorC=1) And (MinorxC=1);

 For Tmp:=1 To MaxEntries Do Dispose(HoldSort[Tmp]);
 For Tmp:=1 To MaxExtra Do Dispose(ExtraHold[Tmp]);

 MiscWordStart:=FileSize(NewDatFile)-256;
 Seek(NewDatFile,252);
 BlockWrite(NewDatFile,MiscWordStart,SizeOf(MiscWordStart));

 Close(IdxFile);
 Close(DatFile);
 If FileExists(Config.DictionaryPath+'OE_IDX.BAK') Then
  Begin Assign(IdxFile,Config.DictionaryPath+'CE_IDX.BAK'); Erase(IdxFile); End;
 If FileExists(Config.DictionaryPath+'OE_DAT.BAK') Then
  Begin Assign(IdxFile,Config.DictionaryPath+'OE_DAT.BAK'); Erase(IdxFile); End;
 Assign(IdxFile,Config.DictionaryPath+'OE_DIC.IDX');

 Rename(IdxFile,Config.DictionaryPath+'OE_IDX.BAK');
 Rename(DatFile,Config.DictionaryPath+'OE_DAT.BAK');
 Close(NewIdxFile);
 Close(NewDatFile);
 Rename(NewIdxFile,Config.DictionaryPath+'OE_DIC.IDX');
 Rename(NewDatFile,Config.DictionaryPath+'OE_DIC.DAT');
 Write(#13,' � ',WordCnt,' words processed in ',FormatTime(Timer-StartTime));
 WriteLn(' (',WordCnt/(Timer-StartTime):0:1,' words/sec)');
 WriteLn(' � OE_DIC.DAT backed up to OE_DAT.BAK');
 WriteLn(' � OE_DIC.IDX backed up to OE_IDX.BAK');
 WriteLn(' � New dictionary datafiles created');
 WriteLn(MakeStr(78,#196));

End.
