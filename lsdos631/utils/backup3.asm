;BACKUP3/ASM - Backup by Class;;	Find highest available memory page;	LD	HL,0		; Set up to get HIGH$	LD	B,L	@@HIGH$	INC	HL		; Find highest available	DEC	H		;   memory page	LD	A,H	LD	(DOFIL06+1),A	; Save for later testing	LD	(DOFIL08+1),A	LD	(LSTBUF1+1),A	LD	A,0C9H		; Return instruction	LD	(PMTDST1),A	; Ignore dest disk test	CALL	PMTDST		; Prompt dest drive;;	Calculate maximum free space per dest disk type;	LD	A,(IY+07H)	; Get heads & sec/track	LD	B,A		; Save heads	AND	1FH		; Keep sectors	LD	C,A		; Store in C	INC	C		; Adjust for 0 offset	XOR	B		; Get # heads	RLCA			;   into bits 0-2	RLCA	RLCA	INC	A		; Adjust for 0 offset	LD	B,A		; Init loop counter	XOR	A		; Init sector count to 0	ADD	A,C		; Multiply # sectors/track	DJNZ	$-1		;   by heads/cyl	LD	L,A	LD	H,00H		; Xfer value to HL	JR	NC,$+3		; Skip if we didn't carry	INC	H		; Bump high byte	BIT	5,(IY+04H)	; If 2-sided diskette	JR	Z,$+3	ADD	HL,HL		; Double the # of sectors	LD	C,(IY+06H)	; Get # cyls and adjust for	DEC	C		; Boot & dir	@@MUL16			; Calc total records	LD	H,L		; Results to HL	LD	L,A	LD	(SIZSAV+1),HL	; Save for later;;	Read the boot sector of dest disk;	LD	DE,1		; Track 0, sector 1	LD	HL,BUF2$	; Disk buffer area	CALL	RDSEC		; Read the sector	JP	NZ,EXIT3	; Quit on read error	LD	A,(BOOTST$)	; Loc'n of boot step rate	LD	L,A	LD	A,(HL)		; Get step rate in	AND	03H		;   bits 0 and 1	LD	(BSCLS+1),A	; Save for later	LD	A,(BUF2$+2)	; Get DIR cylinder	LD	(IY+09H),A	; Stuff into DCT;;	Check ID type byte;	CALL	CKSWDD;;	If a system backup, then check the GAT & HIT;	LD	A,(SYSRSPB)	OR	A		; Check SYS parm response	JP	Z,CLSBU5	;   and skip if not SYS;;	If already a system disk, don't check BOOT space;	IF	@MOD2	CALL	PMTDST		; Get dest data;	LD	A,(IY+3)	; Get DCT data	AND	28H		; Bit 5/3	CP	20H		; 8" floppy?	JR	NZ,SETSYS2	; Go if not	LD	A,(IY+4)	; Get data	AND	50H		; Bit 6/4	CP	40H		; DD not alien?SETSYS2 LD	D,0		; Cyl 0 if not	JR	NZ,$+3		; Go if system	INC	D		; Sysinfo on cyl 1	ENDIF;	LD	HL,HITBUF	; Set disk buffer	LD	E,02H		;   and sector 2;;	Mod II save sysinfo sector for later;	IF	@MOD2	LD	(CKPROT2),DE	; Save cyl/sec	ENDIF;	IF	@MOD4	CALL	RDSEC		; Read sysinfo sector	JP	NZ,EXIT3	; Quit on read error	LD	A,(HITBUF+0C0H) ; Get the SYSTEM disk byte	INC	A		; If already a system disk	LD	D,(IY+09H)	;	JP	Z,CLSBU01	;   bypass	ENDIF;	IF	@MOD2	LD	D,(IY+9)	; Get dir cyl	ENDIF;	LD	E,L		; Set sector 0 dir trk	CALL	RDSEC		; Read the GAT	CP	06H		; Expect error 6	LD	A,14H		; Init "GAT read error	JP	NZ,EXIT3	; Quit on error;	IF	@MOD4	LD	B,00H		; Need no more	BIT	3,(IY+03H)	;   if hard drive	JR	NZ,SETSYS	; Go if hard drive	ENDIF;;	Check GAT byte on Model 2/12;	IF	@MOD2	LD	L,0CDH	BIT	7,(HL)	LD	L,0	JP	Z,CLSBU01	; Go if system disk;;	If alien or not 8" space is okay;	LD	A,(CKPROT2+1)	OR	A	JR	Z,SETSYS	; Go if not;;	Model II must have track 0 fully available;	LD	A,(HITBUF+60H)	; Track 0 lockout data	OR	1		; BOOT/SYS allocation	CP	(HL)		; Anything there?	JP	NZ,NOTSYS	; Yes, cannot use!;;	Model II must have 16 sectors available on cyl 1;	INC	HL		; Point to cyl 1	LD	B,3		; 2 grans SD or DD	ENDIF;	IF	@MOD4	LD	B,02H		; If 8" SDEN or DDEN then 1 gran	ENDIF;	BIT	5,(IY+03H)	; Test for 5" drive	JR	NZ,$+4		; Go if not 5"	LD	B,06H		; 5" needs grans 1 and 2	LD	A,(HL)		; Get GAT byte for boot	AND	B		; Check for needed space	JR	NZ,NOTSYS	; Go if no free space	LD	A,(HL)		; Reserve the GAT space	OR	B	LD	(HL),A;;	Model II must make force locked/used cyl 0;	IF	@MOD2	LD	A,-1		; Init	LD	L,0		; Reset to beginning	LD	(HL),A		; Allocate cyl 0	LD	L,60H		; Lockout table	LD	(HL),A		; Lockout cyl 0	ENDIF;;;	Mask the config byte "data/system" disk bit;SETSYS	LD	L,0CDH		; Point to config byte	RES	7,(HL)		;   and show system disk	CALL	WRGAT		; Write out the GAT;;	Adjust the allocation info for BOOT/SYS;CLSBU0	LD	E,02H		; Read the directory	CALL	RDSEC		;   sector containing	CP	06H		;   boot/sys record	LD	A,11H		; Init DIR read error	JP	NZ,EXIT3	; Go if error	INC	B		; Code to 7 3 1	INC	B		; Code to 8 4 2	SRA	B		; Code to 4 2 1	SRA	B		; Code to 2 1 0;	IF	@MOD2	LD	A,(CKPROT2+1)	OR	A	JR	Z,CLSBU01	ENDIF;;	Model II must force BOOT/SYS to new cyl 1;	IF	@MOD2CLSBU00 LD	L,16H		; Cylinder start	LD	(HL),1		; Force cylinder 1	ENDIF;	LD	L,17H		; Point to gran alloc	LD	(HL),B		; Reset alloc	LD	L,14H		; Point to ERN	LD	(HL),10H	; Update # boot records	LD	L,00H		; Buffer back to beginning	CALL	WRSYS		; Write dir sector back	LD	A,12H		; Init "Dir write errro	JP	NZ,EXIT3	; Exit if so;;	If OLD entered, no SYS file check needed;CLSBU01 LD	A,(OLDPRM$)	; Check for OLD entered	OR	A	JR	NZ,CLSBU5	; Skip SYS setup if so;;	Now check the HIT positions for /SYS files;	CALL	HITRD		; Read in destination HIT	JP	NZ,EXIT3	LD	DE,SYSDEC	; Pt to SYS file hash codes	EX	DE,HL		; HIT do DE, hash tbl to HL	LD	B,10H		; Check 16 DECsCLSBU1	LD	A,(DE)		; If dest spare, stuff	OR	A		;   with source else	JR	NZ,CLSBU2	;   test for match	LD	A,(HL)	LD	(DE),ACLSBU2	CP	(HL)		; Dest match source?	JR	Z,CLSBU3	; Continue if they do;NOTSYS	LD	HL,NOTSYS$	; "Can't make sys disk...	JP	EXIT4		; Display and quit;CLSBU3	INC	E		; Bump to next DEC	INC	HL		;   and our table	LD	A,08H		; At midpoint?	CP	E	JR	NZ,CLSBU4	; Skip if not	LD	E,20H		; Adjust DEC row #CLSBU4	DJNZ	CLSBU1	LD	D,(IY+09H)	; Okay to backup SYSTEM	LD	E,01H		; Init to HIT sector	LD	HL,HITBUF	CALL	WRSYS		; Write back dest HIT	LD	A,17H		; Init HIT write error	CALL	Z,HITRD		; Verify if write okay	JP	NZ,EXIT3	; Quit on any error;;	Set up byte x'C0' in SYSINFO sector;	IF	@MOD2	LD	DE,(CKPROT2)	; Get sysinfo sector	LD	E,2		; Force sector 2	ENDIF;	IF	@MOD4	LD	DE,2	ENDIF;;	HL -> to HITBUF at this point;	CALL	RDSEC		; Read the sector	LD	L,0C0H		; Point to type flag	LD	(HL),0FFH	; Set it	LD	L,00H		; Reset buffer	CALL	WRSEC		; Write it back;CLSBU5	CALL	PMTSRC		; Set up for source disk	CALL	HITRD		; Read source HIT	JP	NZ,EXIT3;;	Start the backup of files;	LD	HL,HITBUF	; Point to start of HIT	JR	SCNH3		; Branch to startOPENIT	DB	'R'!80H		; R2SCNHIT	POP	HL		; Remove top stack entrySCNH1	POP	BC		; Recover DEC position	LD	H,HITBUF<-8	; Hit buf high order	LD	L,B		;   and low orderSCNH2	@@CKBRKC		; Check for break	JP	NZ,ABRTBU	; Quit if pressed	LD	A,L		; Get the current DEC position	ADD	A,20H		; Advance to next file on	LD	L,A		;   this dir sector until	JR	NC,SCNH3	;   end, then go to next	INC	L		;   dir sector in the HIT	BIT	5,L		; Did we go off the end?	JR	Z,SCNH3		;   (i.e. from 1F to 20?)	LD	A,00H		; Backup limited found?SETBIT	EQU	$-1	OR	A	JR	Z,TOEXIT1	; If not, all done	CALL	PMTDST		; Get dest DCT in IY	LD	HL,HITBUF	LD	D,(IY+09H)	; Get dir cyl	LD	E,L		; Point to GAT sector	CALL	RDSEC		;   and read it	CP	06H		; Expect error 6	LD	A,14H		; Init GAT read error	JP	NZ,EXIT3	; Quit if any other	LD	L,0CDH		; Point to config byte	SET	4,(HL)		; Set "Has protected files"	CALL	WRGAT		; Write back outTOEXIT1 JP	EXIT1;;	Continue to scan the major loop;SCNH3	LD	A,(HL)		; Is HIT entry spare?	OR	A	JR	Z,SCNH2		; Loop back if so	LD	A,L	AND	0FEH		; Bypass if BOOT or DIR	JR	Z,SCNH2	LD	B,L		; Save DEC	PUSH	BC	CALL	PMTSRC		; Set up for source disk	LD	D,(IY+09H)	; Get DIR cylinder	LD	A,B		; Pt to dir sector of	AND	1FH		;   this file	ADD	A,02H		; Adjust for GAT and HIT	LD	E,A	LD	HL,BUF2$	; Read DIR sector	CALL	RDSEC	CP	06H		; Proper error code?	JP	NZ,DIRERR	; Go if not	LD	A,B		; Pt to dir rec for	AND	0E0H		;   the source file	LD	L,A	LD	H,BUF2$<-8	; Pt to high order dir buf	LD	A,(HL)		; Ignore file if not	LD	(ATTRIB+1),A	;   assigned in directory	BIT	4,A		; Assigned?	JR	Z,NODOIT	; Go if not	BIT	7,A	JP	NZ,SCNH1	; Ignore file if FXDE	INC	L		; Point to DIR+1	LD	A,(MODPRM$)	; Get MOD parameter	OR	A	JR	Z,SCNH4		; Bypass if MOD not entered	BIT	6,(HL)		; If MOD and bit not set	JR	Z,NODOIT	;   skip the fileSCNH4	BIT	4,(HL)		; Check if backup limited file	JR	Z,SCNH4A	; Go if not set	LD	A,(SVCTR)	; Get backup limit counter	OR	A		; Is it 0?	JR	Z,NODOIT	; Skip the file if 0	INC	A		; Was it FF?	JR	Z,NODOIT	; Skip the file if FF;SCNH4A	DEC	L		; Back to DIR+0	LD	A,(CLSFLG$)	; Get CLASS parameters	BIT	6,(HL)		; Bypass if not SYS file	JR	Z,CKINV	BIT	6,A		; Want SYS files?	JR	Z,NODOIT	; Go if not	JR	CKNAM		;    else back it upCKINV	BIT	3,(HL)		; Test if file is INV	JR	Z,CKNAM		; Skip if not	BIT	3,A		; Want INV files?NODOIT	JP	Z,SCNH1		; Don't want invsiiblesCKNAM	LD	A,(SPCFLD$)	; Now test filespec match	CP	' '		; If blank, don't bother	JR	NZ,CKNAM0	;   to match, take it	LD	A,(SPCFLD$+8)	; How about the extension?	CP	' '	JR	Z,SCNH6		; Go if no ext either;;	Test for a filespec match;CKNAM0	PUSH	HL	LD	A,L	ADD	A,05H		; Pt to filename in dir	LD	L,A	LD	DE,SPCFLD$	; Pt to user filespec	LD	B,11		; 11 char maxCKNAM1	LD	A,(DE)		; Get user entry	CP	'$'		; Wild card char?	JR	Z,CKNAM2	; Always matches	CP	(HL)		; Same as filespec?	JR	Z,CKNAM2	; Loop if so	CP	' '		; Ignore any further?	JP	NZ,TSTMFLG	; If not blank, no matchCKNAM2	INC	HL		; Match so far	INC	DE	DJNZ	CKNAM1;;	Filespec class matches, check if NOT used;	LD	A,(MFLG$)	; Bypass if match but	OR	A		;   - exclude given	JP	NZ,SCNHIT	; - was used, skip file	JR	SCNH5;TSTMFLG LD	A,(MFLG$)	; Ignore if NG match &	OR	A		;   no exclude given	JP	Z,SCNHITSCNH5	POP	HLSCNH6	PUSH	HL;;	Now check if date matches;	INC	HL		; Pt to date field	CALL	UNPACK		; Alter date for cpr	LD	A,(FTFLG$)	RLCA			; Test FROM bit	JR	NC,SCNH7	LD	A,D		; Ignore if date was	OR	E		;   00/00/00 for file	JP	Z,SCNHIT	LD	HL,(FMPAKD$)	; Get user entry	EX	DE,HL	CALL	CPHLDE		; HL-DE	EX	DE,HL	JP	C,SCNHIT	; Bypass if date range badSCNH7	LD	A,(FTFLG$)	RRCA			; Test TO bit	JR	NC,MATCHES	; Go if no TOPARM else	LD	A,D		;   check if file dated	OR	E	JP	Z,SCNHIT	; Bypass if date was 00	LD	HL,(TOPAKD$)	; Get user's packed date	CALL	CPHLDE		; HL-DE	JP	C,SCNHIT	; Bypass if out of rangeMATCHES POP	HLDONAM	LD	A,L		; Pt to start of dir rec	AND	0E0H	LD	L,A		; Make sure it's on stack	PUSH	HL	ADD	A,05H		; Pt to start of filename	LD	L,A	LD	DE,FCB1$	; Move name to into FCB	LD	B,08H		; Init 8 chars for filenameDONAM1	LD	A,(HL)		; Get char from the dir	CP	' '		; Space=end of name	JR	Z,DONAM2	LD	(DE),A		; Move char to FCB	INC	HL		; Bump both pointers	INC	DE	DJNZ	DONAM1		; Loop for moreDONAM2	LD	A,L		; Pt to file extension	ADD	A,B		; By adding loop remainder	LD	L,A	LD	A,(HL)	CP	' '	JR	Z,DONAM5	; Bypass if none there	LD	A,'/'		;   else set separator	LD	(DE),A		;   into the FCB	INC	DE	LD	B,03H		; Now move in EXTDONAM4	LD	A,(HL)		; Get EXT char	CP	' '		; End if no more	JR	Z,DONAM5	LD	(DE),A		; Put it in the FCB	INC	HL		; bump pointers	INC	DE	DJNZ	DONAM4		; Loop for extDONAM5	LD	A,03H		; Terminate with ETX	LD	(DE),A	PUSH	DE		; Save ptr to filespec end;;	Check for NEW or OLD option;	LD	A,(OLDPRM$)	; Get param and merge	LD	HL,NEWPRM$	;   with new	OR	(HL)		; If neither, bypass	JR	Z,BYPASS	LD	HL,FCB1$	; Save current spec	LD	DE,FCB3$	LD	BC,32	LDIR	POP	DE		; Recover spec end	PUSH	DE		; Needed to add drivespec	CALL	MAKSPC		; Make it a filespec	CALL	GETDST		; Bring in the dest disk	LD	HL,(BUFFER$)	; Buffer is irrelevant	LD	DE,FCB2$	; Point to dest spec	PUSH	IY	@@FLAGS			; IY => flags table	SET	0,(IY+'S'-'A')	; Inhibit file open bit	POP	IY	@@OPEN			; Attempt to open	POP	DE		; Keep stack proper	JR	Z,CKOLD		; If exists, check OLD	CP	19H		; File access denied?	JR	Z,CKOLD		;   means it exists	CP	18H		; File not found?	JP	NZ,SCNHIT	; Ignore if not	LD	A,(NEWPRM$)	; Check if NEW requested	OR	A	JR	NZ,GODOIT	; Go if NEW & not found	JP	SCNHITCKOLD	LD	A,(OLDPRM$)	; Was found, backup old	OR	A		;   files this time?	JP	Z,SCNHIT	; Ignore if not OLDGODOIT	PUSH	DE	LD	HL,FCB3$	; Recover original filename	LD	DE,FCB1$	LD	BC,32	LDIR;;	Check if prompting or not (Q param);BYPASS	LD	A,(QPARM$+1)	; Query each file?	OR	A	JP	Z,NOPRMPT	; Not if not entered	LD	HL,QUERY	; "backup filespec?	@@DSPLY;;	Display file info for user decision;	POP	DE		; Recover ptr to file buf	POP	HL		; Recover ptr to 1st dir byte	PUSH	DE	INC	HL		; Point to mod bit	BIT	6,(HL)		; Test MOD flag	JR	Z,SCDAT1	; Go if not set	LD	A,' '		; Put a space	LD	(DE),A	INC	DE	LD	A,'+'		; Put a "+" if MOD	LD	(DE),A	INC	DESCDAT1	LD	A,' '		; Write a space	LD	(DE),A	INC	DE	INC	HL		; Advance to date field	EX	DE,HL	LD	(HL),'{'	; Stuff left brace	INC	HL	EX	DE,HL	LD	A,(HL)		; If no date, then skip	OR	A	JR	Z,SCDAT4	; Ignore if no date saved	RRCA			; Has date, get day	RRCA	RRCA	AND	1FH	LD	B,2FH		; Convert day to decimalSCDAT2	INC	B		;   by counting # of 10s	SUB	0AH		; Sub 10 from day	JR	NC,SCDAT2	ADD	A,3AH		; Cvt lo order to ASCII	PUSH	AF		; Save day low order	LD	A,B		; Stuff day hi-order	LD	(DE),A	INC	DE		; Bump	POP	AF		; Recover low order	LD	(DE),A		; Stuff low order	INC	DE		; Bump ptr to msg	LD	A,'-'		; Add date sep	LD	(DE),A	INC	DE		; Point to month field	PUSH	HL		; Save DIR ptr	PUSH	AF		; Save separator	DEC	HL		; Pt to DIR+1	LD	A,(HL)		; Get month and schtuff	AND	0FH		; Strip off flags	DEC	A		; (mon-1)*3 to index	LD	C,A		;   string conversion table	RLCA			; * 2	ADD	A,C		; * 3	LD	C,A		; Results to BC	LD	B,00H*LIST	OFF	IFLT	@DOSLVL,'L'	;---> Before changes for 6.3.1L*LIST	ON	LD	HL,MONTBL	; Point to month names*LIST	OFF	ELSE			;<--> 6.3.1L*LIST	ON	LD	HL,MONTBL$	; Point to month names (from LOWCORE)MONTBL$	EQU	04DCH		; in LOWCORE*LIST	OFF	ENDIF			;<--- 6.3.1L*LIST	ON	ADD	HL,BC		; Add offset to table	LD	C,03H		; 3 char in month name	LDIR	POP	AF	LD	(DE),A		; Stuff separator	INC	DE		; Bump to year field	POP	HL		; Get dir ptr back	LD	C,'8'		; Init to 1980	LD	A,(GATCD1)	; Get gat byte x'CD'	OR	A*LIST	OFF	IFLT	@DOSLVL,'L'	;---> Before changes for 6.3.1L*LIST	ON	JR	NZ,SCDAT5	; Go if not zero	LD	A,(HL)		; Get year field	AND	07H		; Remove day	JR	SCDAT7SCDAT5	LD	A,L		; Point to year in DIR	ADD	A,11H	LD	L,A	LD	A,(HL)		; Get new year value	AND	1FH		; Mask off timeSCDAT6	CP	0AH		; Greater than 10?	JR	C,SCDAT7	; Go if year in 80s	INC	C		; Increment to 1990s	SUB	0AH		; Drop another 10	CP	0AH		; Done yet?*LIST	OFF	ELSE			;<--> 6.3.1L*LIST	ON	CALL	GTDIRYR		; Get Y-1980 from dir entry in A	LD	C,'8'		; Year for old style dirY3126	CP	10		; Is it 1980s?	JR	C,SCDAT7	; Skip if yes	SUB	10		; Subtract 10	INC	C		; Make C hold a '9'	LD	B,A		; Save subtracted year in B	LD	A,C		; Get 10s digit in ASCDAT6	CP	'9'+1		; Is digit > '9'?	LD	A,B		; Restore subtracted year from B	JR	NZ,Y3126	; Loop if not	LD	C,'0'		; Else reset to '0'	JR	Y3126		; And loop;	Garbage ...*LIST	OFF	ENDIF			;<--- 6.3.1L*LIST	ON	JR	C,SCDAT7	; Go if year in the 90s	SUB	0AH		; Do another subtract	LD	C,'0'		; Force into 2000s	JR	SCDAT6		; Loop back to do those;;	Put year in string;SCDAT7	LD	B,A		; Get year byte	LD	A,C		; Get tens of years	LD	(DE),A		; Stuff into year field	INC	DE		; Bump pointer	LD	A,B		; Get ones of year	ADD	A,'0'		; Convert to ASCII	LD	(DE),A		; Stuff in field	INC	DE		; Bump pointer;SCDAT4	LD	A,03H		; Stuff ETX for display	LD	(DE),A	LD	HL,FCB1$	; Point to filename	@@DSPLY	LD	HL,QMARK$	; "} ? "	@@DSPLY	LD	HL,(BUFFER$)	; Get user response	LD	BC,3<8		; 3 char max	@@KEYIN	JP	C,ABRTBU	; Abort on break	LD	A,(HL)		; Get response	RES	5,A		; Force upper case	CP	'Y'		; Was it Yes?	JR	Z,CPYMSG;;	Accept "C" response to set Query = N;	SUB	'C'		; Was response "C"?	JP	NZ,SCNHIT	; Don't backup if not	LD	(QPARM$+1),A	; Set Query = NCPYMSG	EX	(SP),HL		; Place dummy HL below	PUSH	HL		; FCB1$ ETX pointer;;	Display copying file info;NOPRMPT @@CKBRKC		; Check for break	JP	NZ,ABRTBU	; Quit if so	LD	HL,CPYFIL$	; "Copying file...	@@LOGOT	POP	HL		; Get pointer to ETX	LD	(HL),0DH	;   and replace with CR	PUSH	HL	LD	HL,FCB1$	; Display filespec	@@LOGOT	POP	DE		; Recover ptr to CR	POP	HL;;	Put in the drive spec;DOBU	CALL	MAKSPC		; Make the filespec	POP	BC		; Get DEC of source	PUSH	BC	LD	A,B		; Test if a SYS dec	AND	0D8H	JP	NZ,DOFIL0	; Jump if not SYSATTRIB	LD	A,00H		; Get attrib byte	BIT	6,A		; Don't do if not SYS	JP	Z,DOFIL0;;	Routine to copy over SYS files;	CALL	PMTDST		; Prompt dest drive	LD	D,(IY+09H)	; Get DIR cyl of dest	LD	A,B		; Get DEC & calc sector	AND	1FH	ADD	A,02H		; Adj for GAT and HIT	LD	E,A	LD	HL,(BUFFER$)	; Get buffer address	CALL	RDSEC		; Read DIR sector	CP	06H		; Proper errcode?	JP	NZ,DIRERR	; Go if not	LD	A,B		; Point to 1st byte	AND	0E0H		;   of dir record	LD	L,A	BIT	4,(HL)		; Go if already assigned	JR	NZ,DOSYS1	LD	(HL),5FH	; Show assigned, SYS, INV	INC	HL		;   and no access	LD	BC,3		; Zero out DIR+1 to DIR+4	LD	(HL),B	LD	D,H	LD	E,L	INC	DE	LDIR	LD	A,L		; Point HL to DIR+16	ADD	A,12	LD	L,A	INC	A	LD	E,A		; Point DE to DIR+17	LD	(HL),0FFH	; Stuff x'FF' in extent	LD	C,0FH		;   and password fields	LDIRDOSYS1	LD	A,L		; Point to DIR+0 of dest	AND	0E0H	BIT	6,(HL)		; Guard against writing	JP	Z,NOTSYS	;   over a non-SYS file	ADD	A,05H		; Point to name field	LD	L,A	LD	E,A		; Point DE to name field	LD	H,BUF2$<-8	;   of destination	LD	A,(BUFFER$+1)	; Get buffer hi-order addr	LD	D,A	LD	BC,13		; Move name/ext into dest	LDIR	LD	D,(IY+09H)	; Get dir cyl of dest	POP	BC		; Recover DEC of source	PUSH	BC	LD	A,B		; Calc dir sector for	AND	1FH		;   source SYS module	ADD	A,02H	LD	E,A	LD	HL,(BUFFER$)	; Get buffer ptr for dest	CALL	WRSYS		; Write the dir to dest	LD	A,12H		; Init "dir write error	JP	NZ,EXIT3	;   and quit on bad write;;	The HIT entries were transferred prior;	POP	BC		; Recover DEC of source	PUSH	BC	LD	A,B		; Test for SYS0	CP	02H	JP	NZ,DOFIL0	; Bypass if not SYS0	CALL	PMTSRC		; Prompt for source;	IF	@MOD4	LD	B,10H		; Init to xfer BOOT track	LD	DE,0		; Track 0, sector 0	ENDIF;	IF	@MOD2	LD	DE,(PROTSEC)	; Get sysinfo sector	LD	A,D	OR	A	LD	B,5		; Default to 5 secs	JR	Z,NBTSEC2	LD	B,16		; Use 16NBTSEC2 LD	E,0	ENDIF;	LD	HL,(BUFFER$)	; Set disk bufferRDBOOT	CALL	RDSEC		; Read sector	JP	NZ,EXIT3	; Quit on error	INC	H		; Point to next block	INC	E		;   and next sector	DJNZ	RDBOOT		; Continue reading boot;;	Turn off CONFIG on destination disk;	LD	HL,(BUFFER$)	; Start cyl image	LD	DE,100H*2+1	; Offset to sector 2 +1	ADD	HL,DE		; HL -> config byte	LD	(HL),0C9H	; Config off;DOSYS2	CALL	PMTDST		; Prompt destination;	IF	@MOD4	LD	B,10H		; Sector count for BOOT	LD	DE,0		; Track 0, sector 0	ENDIF;	IF	@MOD2	LD	DE,(CKPROT2)	; Get dest cyl number	LD	A,(PROTSEC+1)	LD	B,5		; Default 5 sectors	OR	A	JR	Z,NBTSECS	LD	B,16		; Use 16 sectorsNBTSECS LD	E,0	ENDIF;	LD	HL,(BUFFER$)	; Get buffer startWRBOOT	LD	A,E		; If sector 0 or 1	CP	02H		;   correct DIR cyl	JR	NC,WRBOOT2	;   and step rate	OR	A	JR	Z,WRBOOT1	; If sec 0, only DIR cyl;	LD	A,(BOOTST$)	; Get step pointer	LD	L,A	LD	A,(HL)		; Get boot step rate	AND	0FCH		; Strip the rateBSCLS	OR	00H		; Merge dest rate	LD	(HL),A		; Put it backWRBOOT1 LD	A,(IY+09H)	; Get dir cylinder	LD	L,02H	LD	(HL),A	LD	L,00H		; Reset to buff startWRBOOT2 CALL	WRSEC		; Write dest boot sector	JP	NZ,EXIT3	; Quit on error	INC	H		; Bump buffer page	INC	E		;    and sector num	DJNZ	WRBOOT		; Loop for # of sectors;;	Verify this track;	IF	@MOD4	LD	B,10H		; 16 sectors just written	LD	DE,0		;   on track 0	ENDIF;	IF	@MOD2	LD	A,(PROTSEC+1)	LD	B,5		; Default 5 sectors	LD	DE,(CKPROT2)	; Get dest cyl number	OR	A	JR	Z,NBTSEC1	LD	B,16		; Use 16 sectorsNBTSEC1 LD	E,0	ENDIF;VRBOOT	CALL	VERSEC		; Verify a boot sector	JP	NZ,EXIT3	; Quit on error	INC	E		; Bump sector #	DJNZ	VRBOOT;	IF	@MOD2	LD	DE,(CKPROT2)	; Get sysinfo sector	LD	A,(PROTSEC+1)	AND	D	JR	Z,COPY0E	; Go if yesOKWRT0	CALL	PMTSRC		; Get source disk	CALL	READ0		; Read cyl 0	JP	NZ,EXIT3	; Quit on disk error	CALL	PMTDST		; Get dest disk	CALL	FORMAT0		; Format cylinder	JP	NZ,EXIT3	; Quit if disk error;;	Setup new track length into boot data;	LD	HL,(BUFFER$)	; Get I/O buffer	PUSH	HL		; Save start	INC	HL		; +1	INC	HL		; +2 (dir cyl)	LD	A,(IY+9)	; Get dir cyl	LD	(HL),A		; to buffer	INC	HL		; +3 (boot step rate)	LD	A,(BSCLS+1)	; Get step rate	AND	3		; Step rate only	LD	(HL),A		; Load into buffer	INC	HL	LD	A,(IY+7)	; Get data	AND	1FH		; Highest sector #	INC	A		; Sectors/track	LD	(HL),A		; To buffer	INC	HL		; Bump	LD	A,(IY+3)	; Get data	ADD	A,A		; Density -> bit 7	AND	80H		; Keep only	LD	(HL),A		; To buffer	POP	HL		; HL => buffer start	LD	D,H		; Xfer to DE	LD	E,L	LD	BC,80H		; Buffer length	ADD	HL,BC		; HL => dest	EX	DE,HL		; HL => src, DE => dest	LDIR			; Copy sector 0 -> sec 1	CALL	PMTDST		; Re-fetch DCT	CALL	WRITE0		; Write the cylinder	JP	NZ,EXIT3	; Go on disk errorCOPY0E	EQU	$	ENDIF;;	Routine to perform the file copy do destination;DOFIL0	LD	DE,OPENIT	; Check the name	@@RENAM	LD	B,00H		; LRL = 256	CALL	GETSRC		; Prompt source & set FCB	LD	HL,(BUFFER$)	; Get buffer address	@@FLAGS	SET	0,(IY+'S'-'A')	; Inhibit file open bit	@@OPEN			; Open the source file	JP	NZ,EXIT3	; Quit on open error;;	Check if source file can fit on destination disk;	LD	HL,(FCB1$+12)	; Get ERNSIZSAV	LD	DE,0		; Get disk capacity	EX	DE,HL	SBC	HL,DE		; If < size then okay	JR	NC,SIZOK	LD	HL,SIZBIG$	; Inform user too big	@@LOGOT	JP	SCNH1		; Loop back for another fileSIZOK	LD	DE,OPENIT	; Check the name	@@RENAM	LD	B,00H		; LRL = 256	CALL	GETDST		; Get dest and set FCB	LD	HL,(BUFFER$)	; Get buffer address	@@INIT			; Init the dest file	JR	Z,LRLOK		; If no error, cont	CP	42		; Was it LRL error?	JR	Z,LRLOK		; Ignore if it was	JP	EXIT3		;   else abort - real errorLRLOK	LD	A,(FCB2$+7)	; Get DEC of dest	LD	(DOFIL11+1),A	LD	BC,(FCB1$+12)	; Get ERN & chk for enough	CALL	WRERN		;   space on disk	POP	BC		; Recover DEC	LD	L,B		; Reset HL to dir	LD	H,BUF2$<-8	PUSH	BC		; Save DEC	JR	Z,DOFIL02	; Go if there was room	CALL	PMTSRC		;   else make source current, loop	JP	DONAM		;   back because dest was swappedDOFIL02 LD	A,L		; Check if backup limited file	AND	0E0H		; Index to proper DIREC	INC	A		; Point to DIR+1	LD	L,A	BIT	4,(HL)		; Check backup limited bit	JR	Z,$+5		; Skip if not protected	LD	(SETBIT),A	; Set "disk has prot files"	LD	HL,0	LD	(FCB2$+12),HL	; Set dest ERN to 0	@@REW			; Rewind the dest fileDOFIL03 LD	HL,(BUFFER$)	; Buffer addressDOFIL04 LD	(FCB1$+3),HL	; Set buffer in FCB	CALL	GETSRC		; Prompt source & set FCB	@@READ			; Read a source file sector	JR	Z,DOFIL05	; Go if no error	CP	1CH		; EOF?	JR	Z,DOFIL09	; Yes, finished loading	CP	1DH		; NRN > ERN?	JR	Z,DOFIL09	; Also means load done	JP	EXIT3		; Any other error, abortDOFIL05 INC	H		; Bump the buffer pointer	LD	A,HDOFIL06 CP	00H		; Test out of memory	JR	NZ,DOFIL04	; Loop if more room	LD	HL,(BUFFER$)	; Get buffer startDOFIL07 LD	(FCB2$+3),HL	; Set buf into dest FCB	CALL	GETDST		; Prompt dest & set FCB	@@VER			; Write dest with verify	JP	NZ,EXIT3	; Quit on error	INC	H		; Bump buffer page	LD	A,HDOFIL08 CP	00H		; Out of memory?	JR	NZ,DOFIL07	; Write another if not	JR	DOFIL03		;   else back to loading;;	Reached the end of the source file;DOFIL09 CALL	LSTBUF		; Write remaining buffer	LD	HL,(FCB1$+8)	; Get DEC and LRL	LD	(FCB2$+8),HL	;   & stuff into dest	CALL	GETDST		; Set for dest FCB	@@CLOSE			; Close 'er up	JP	NZ,EXIT3	; Abort on close error;;	Now remove the mod flag from destination and;	do CLONE function;	LD	D,(IY+09H)	; Get DIR cylinderDOFIL11 LD	B,00H		; Get DEC	LD	A,B		; Point to DIR sector	AND	1FH	ADD	A,02H		; Bypass GAT and HIT	LD	E,A	PUSH	DE		; Save cyl/sect	LD	HL,(BUFFER$)	; Get buffer address	CALL	RDSEC		; Read sector	CP	06H		; Expected error?	LD	A,11H		; Init "Dir read error	JP	NZ,EXIT3	; Go if any other	LD	A,B		; Point to dir record	AND	0E0H	LD	E,A	LD	A,(BUFFER$+1)	; Get hi order buffer pos	LD	D,A	POP	HL	POP	BC		; Get DEC and buffer of src	PUSH	BC	PUSH	HL	LD	A,B		; Get source DEC	AND	0E0H		;   and point to DIREC	LD	L,A		;   of current file	LD	H,BUF2$<-8	INC	L		; Point to MOD flag	PUSH	HL	RES	6,(HL)		; Turn off MOD flag	DEC	L		; Point to DIR+0	LD	BC,5		; Transfer up through	LDIR			;   DIR+4BYSPACE LD	A,E		; Point DE to the dest	ADD	A,11		;   password fields	LD	E,A	LD	A,L		; Point HL to the source	ADD	A,11		;   password fields	LD	L,A	LD	C,4		; Move 4 bytes	LDIR	POP	HL		; Recover DIR+1	INC	HL		; Point to DIR+2	DEC	DE		; Dec Dest to time fld	LD	A,(GATCD0)	; Get x'CD' of gat	CP	04H		; Is bit 2 set?	 (Src has 6.3 dates??)	JR	NZ,M3378	; Go if not set	LD	A,(HL)		; Get value	AND	07H		; Mask off stuff	LD	(DE),A		; Store at DE	DEC	DE		; Back up one	XOR	A		; Clear A	LD	(DE),A		; Store in dirM3378	LD	HL,(BUFFER$)	; Get buffer addr	POP	DE		; Recover cyl/sect	CALL	WRSYS		; Write it backJPEXIT3 LD	A,12H		; Init "Dir write error	JP	NZ,EXIT3	; Go if error;;	Attempt to clear mod flag of source;DOFIL12 LD	A,00H		; Test for write prot src	OR	A		;   which implies, can't	JP	NZ,SCNH1	;   clear mod flags	POP	BC		; Get DEC of source	PUSH	BC	LD	A,B		; Clear mod flag on source	AND	0E0H		; Dir sector is resident	INC	A		;   in a buffer at BUF2	LD	L,A	LD	H,BUF2$<-8	RES	6,(HL)		; Reset MOD bit	CALL	PMTSRC		; Set for source I/O	LD	D,(IY+09H)	; Get dir cyl	LD	A,B		; Point to dir sect of src	AND	1FH	ADD	A,02H		; Adjust for GAT and HIT	LD	E,A	LD	HL,BUF2$	CALL	WRSYS		; Write it back	JP	Z,SCNH1		; Back on good write	CP	0FH		; Accept only "write prot err	JR	NZ,JPEXIT3	; Any other is "dir write err"	LD	A,0FFH		; Turn off clear mod flag test	LD	(DOFIL12+1),A	LD	HL,CCMOD$	; "Can't clear mod flags	@@LOGOT	JP	SCNH1		; Loop to next file;;	Routine to compare HL to DE, ret Z if equal;CPHLDE	LD	A,H		; Test H=D	SUB	D	RET	NZ		; Back if not	LD	A,L		; Test L=E	SUB	E	RET			; Ret with condition;;	Routine to construct filename from name/ext;MAKSPC	LD	A,':'		; Prepare for drivespec	LD	(DE),A	INC	DE	PUSH	DE		; Save pointer	LD	A,(DSTDRV$+1)	; Get dest drive #	AND	07H		; Mask off "where" bits	ADD	A,'0'		; Convert to ASCII	LD	(DE),A		; Save in buffer	INC	DE		; Bump	LD	A,03H		; Terminate with ETX	LD	(DE),A	LD	HL,FCB1$	; Copy source FCB to	LD	DE,FCB2$	;   destination FCB	LD	BC,32		; 32 bytes to copy	LDIR	POP	DE		; Recover where source	LD	A,(SRCDRV$+1)	; Get source drive	AND	07H		; Mask off bits	ADD	A,'0'		; Convert to ASCII	LD	(DE),A		; Store it in source	RET;;	Routine to extract date from directory;UNPACK	LD	A,(HL)		; Get DIR+1	AND	0FH		; Remove flags*LIST	OFF	IFLT	@DOSLVL,'L'	;---> Before changes for 6.3.1L*LIST	ON	LD	E,00H		; clear E	LD	D,A		; Month to D	SRL	D		; Move to D bits 2-0	RR	E		;   and E bit 7	INC	HL		; Point to DIR+2	LD	A,(HL)		; Get day and year	AND	0F8H		; Strip year	RRCA			; Day to 2-6	OR	E		; Merge with month	LD	E,A		; Save back in E	LD	A,(GATCD2)	; Get gat x'CD' byte	OR	A		; New style dates?	JR	NZ,UNPACK2	; Skip if non-zero	LD	A,(HL)		; Get year back	AND	07H		; Strip the dayUNPACK1 RLCA			; Rotate to 5-7	RLCA	RLCA	OR	D		; Merge with month	LD	D,A	RET;;	New style dates;UNPACK2 LD	A,L		; Get buffer	ADD	A,17		; Point to year	LD	L,A	LD	A,(HL)		; Get year & time	AND	1FH		; Keep just year	JR	UNPACK1		; Continue as before*LIST	OFF	ELSE			;<--> 6.3.1L*LIST	ON	LD	B,A		; B contains month	INC	HL		; Point to DIR+1	LD	A,(HL)		; Get year and day	RRCA			; Bring day	RRCA	RRCA	AND	1FH		; Mask off year	LD	C,A		; C contains dat	PUSH	BC		; Save month and day	CALL	GTDIRYR		; Get year-1980 in a	POP	BC		; Restore month and day	CALL	PKDAT		; Pack YMD to BC	LD	D,B		; Move to DE	LD	E,C		;	RET			; Done;;	Get Y-1980 from directory entry;	IN:	HL = DIR+2;	OUT:	A = Year-1980;		Cy set if Lev.H+ date;GTDIRYR	LD	A,(HL)		; Get year and day from DIR+2	AND	07H		; Mask off day	LD	B,A		; To B	LD	A,(GATCD2)	; Get GAT x'CD' byte	OR	A		; Is it zero (old dates)?	JP	Z,RETOLDY	; Go for old style if yes	LD	A,L		; Point to DIR+19 (New style date)	ADD	A,11H		;	LD	L,A		;	JP	GTEXTYR		; Get Lev.H+ year*LIST	OFF	ENDIF			;<--- 6.3.1L*LIST	ON;;	Write the GAT back to disk;WRGAT	LD	L,00H		; HL to start of buffer	CALL	WRSYS		; Write DIR sector	LD	A,15H		; Init "Gat write error	JP	NZ,EXIT3	;   and quit on error	CALL	VERSEC		; Verify good write	CP	06H		; Expect error 6	LD	A,14H		; Init "GAT read error	JP	NZ,EXIT3	; Quit on any other error	RET;;	Write last buffer if needed;LSTBUF	LD	A,(BUFFER$+1)	; Get hi-order buffer start	CP	H		; Are we there now?	RET	Z		; Back if so, nothing loadedLSTBUF1 LD	A,00H		; Get last available page	CP	H		; There now?	RET	Z		; Already written if so	LD	B,H		; Need to write to this page	LD	HL,(BUFFER$)	; Get buffer startLSTBUF2 LD	(FCB2$+3),HL	;   and put in dest FCB	CALL	GETDST		; Prompt for dest	@@VER			; Write with verify	JP	NZ,EXIT3	; Quit on bad write	INC	H		; Bump buffer page	LD	A,H	CP	B		; At the end?	JR	NZ,LSTBUF2	; Loop if more	RET;;	Check if enough space on destination disk;WRERN	LD	A,B		; If ERN = 0 don't	OR	C		;   write an ERN	RET	Z	DEC	BC		; Adjust for 0 offset	CALL	GETDST		; Prompt dest	PUSH	DE		; Save FCB pointer	@@POSN			; Position to end	LD	HL,(BUFFER$)	; Get buffer address	LD	D,H		; Construct a format	LD	E,L		;   sector of all x'E5's	INC	DE	LD	BC,255	LD	(HL),0E5H	LDIR	POP	DE		; Recover FCB pointer	@@VER			; Write with verify	RET	Z		; Return if no error	CP	1BH		; Disk full?	JR	NZ,NOTDF	; No - quit on real error	@@REMOV			; Remove what can't fit	BIT	3,(IY+03H)	; Is this a hard disk?	JR	Z,NOTHARD	; Go if not	BIT	2,(IY+03H)	; Shown as removable?	JR	Z,NOTHARD	; Prompt swap if so	LD	HL,FULDRV$	; Prepare disk full error	JR	DOING1NOTHARD @@FLAGS	BIT	5,(IY+'S'-'A')	; Can't switch while in DO	JR	NZ,DOING	LD	HL,NEWDISK	; "Disk full..enter new	CALL	FLASH	OR	01H		; Show switched dest	RETNOTDF	JP	EXIT3		; Error exit;GETSRC	PUSH	BC	LD	DE,FCB1$	; Point to source FCB	CALL	PMTSRC		; Show source current	POP	BC		;   for disk I/O	RET;GETDST	PUSH	BC	LD	DE,FCB2$	; Point to dest FCB	CALL	PMTDST		; Show dest is current	POP	BC		;   for disk I/O	RET;;	Read HIT of disk;HITRD	LD	D,(IY+09H)	; Get dir cyl of source	LD	E,01H		; Read HIT	LD	HL,HITBUF	; Into HIT buffer	CALL	RDSEC	CP	06H		; Error code correct?	LD	A,16H		; Init HIT read err	RET			; return w/ condition;DOING	LD	HL,DOMSGDOING1	JP	EXIT4;;	Messages for backup by class;CPYFIL$ DB	1DH,'Copying file: ',03QUERY	DB	'Backup ',3FULDRV$ DB	'Disk is full ',0DHNEWDISK DB	'Disk is full - Insert new formatted '	DB	'destination disk, <ENTER>',1DH,3DOMSG	DB	'Disk is full! - Can',27H,'t switch '	DB	'while <DO> in effect',0DHSIZBIG$ DB	'  File is larger than destination capacity'	DB	' - backup is bypassed',0DHNOTSYS$ DB	'Can',27H,'t create SYSTEM disk - directory '	DB	'slots in use',0DHQMARK$	DB	'} ? ',3*LIST	OFF	IFLT	@DOSLVL,'L'	;---> Before changes for 6.3.1L*LIST	ONMONTBL	DB	'JanFebMarAprMayJunJulAugSepOctNovDec'*LIST	OFF	ELSE			;<--> 6.3.1L*LIST	ON;;	New routine to pack date;	IN:	A=Year, B=Month, C=Day;	OUT:	BC=(A*16+B)*32+C;PKDAT	PUSH	HL	LD	L,A		; Year	ADD	HL,HL	ADD	HL,HL	ADD	HL,HL	ADD	HL,HL		; *16	LD	A,B		; Month	OR	L	LD	L,A		; HL=A*16+B	ADD	HL,HL	ADD	HL,HL	ADD	HL,HL	ADD	HL,HL	ADD	HL,HL		; *32	LD	A,C		; Day	OR	L	LD	C,A		; BC=(A*16+B)*32+C	LD	B,H	POP	HL	RET			; Done	DB	'lAugSepOctNovDec' ; Garbage*LIST	OFF	ENDIF			;<--- 6.3.1L*LIST	ON;	DECs for system files;SYSDEC	DB	0A2H,0C4H,2EH,2FH,2CH,2DH,2AH,2BH	DB	28H,29H,26H,27H,27H,0A7H,26H,0A6H;*LIST	OFF	IFLT	@DOSLVL,'L'	;---> Before changes for 6.3.1L*LIST	ON	DC	64,0		; Patch space*LIST	OFF	ELSE			;<--> 6.3.1L*LIST	ON;;	New routine to get Lev.H+ year from dir entry;	IN:	HL = DIR+19, Lev.H Date;		B = old year (can contain (Y-1980)/32 XORed with;			(HL)'s bits 0-2);	OUT:	A = Y-1980;		Cy set to indicate Lev.H+ dates;GTEXTYR	LD	A,(HL)		; Get byte	AND	1FH		; Keep bits 0-4 (Lev.H Y-1980)	LD	C,A		; Save to C	LD	A,B		; XOR with B	XOR	C		;	AND	07H		; Check bits 0-2	JR	Z,Y361C		; Skip if 0 (Old year = Lev.H Year); Double-check that DIR+19 does not contain 4296H (def't user passwd); (not really necessary -- this is not done in LBDIR)	PUSH	AF		; Save (Y-1980)/32	LD	A,96H		; Check LSB	CP	(HL)	JR	NZ,Y3614	; OK if not 96H	INC	HL	LD	A,42H		; Check MSB	CP	(HL)	DEC	HL	JR	NZ,Y3614	; OK if not 42H	POP	AF		; Restore (Y-1980)/32RETOLDY	LD	A,B		; Otherwise ret old year	OR	A		; With Cy reset to indicate old style	RET; Unpack new yearY3614	POP	AF		; Restore (Y-1980)/32	RRCA			; Mult by 32	RRCA	RRCA	OR	C		; Combine with low bits (Y-1980)%32	CP	100		; Less than 100 (2079)?	RET	C		; Return Lev.L Year if yes (with Cy)Y361C	LD	A,C		; Else return Lev.H Year	SCF			; Cy set to indicate Lev.H+ year	RET			; Done	DC	26,0		; Patch space*LIST	OFF	ENDIF			;<--- 6.3.1L*LIST	ON;	ORG	$<-8+1<+8;HITBUF	DS	256;	SUBTTL	'<Backup Misc. routines>';CLSSIZ	EQU	$-BACKUP;;	Establish PC for rest of backup initialization;	ORG	CORE$+MIRSIZ+CLSSIZ	LORG	$		; No offset here;;	Shift in Mirror or by-file module;CLSTST	LD	A,00H		; Non-zero if any option	OR	A	JP	NZ,MVBYCLS	; Bypass if special	LD	HL,MIRBU	; Move in standard code	LD	DE,BACKUP	LD	BC,MIRSIZ	LDIR	JR	SETBFR;MVBYCLS LD	A,(SXORD+1)	; Restrict by class	OR	A		;   if a single drive	JR	NZ,MVBYC1	LD	HL,CLS1DB$	; Can't by class on 1 drvMOVNOT	@@DSPLY			; Display the error	JP	ABRTBU		;   and abort backup;MVBYC1	LD	A,(XPARM$+1)	; By class backup requires	OR	A		;   either non (X) or residency	JR	Z,MVBYC2	;   of SYS 2,3,10 and 12RESLOC	LD	DE,0		; Store location (RES$)	LD	A,E	OR	D		; Check if there	LD	HL,RESREQ$	; "Must be resident	JR	Z,MOVNOT	; Error if not in use	PUSH	DE		; Okay, it's in use	POP	IX		; Are all modules present	LD	A,(IX+2*2+5)	;   and accounted for?	OR	A		; Is SYS2 resident?	JR	Z,MOVNOT	LD	A,(IX+3*2+5)	; SYS3 resident?	OR	A	JR	Z,MOVNOT	LD	A,(IX+10*2+5)	; SYS10 resident?	OR	A	JR	Z,MOVNOT	LD	A,(IX+12*2+5)	; SYS12 resident?	OR	A	JP	Z,MOVNOTMVBYC2	LD	HL,CLSBU	; Move in special code	LD	DE,BACKUP	LD	BC,CLSSIZ	LDIRSETBFR	DEC	DE		; Set the buffer	INC	D		;   one page above the code	LD	E,00H	LD	(BUFFER$),DE	; Save starting position	JP	BACKUP;;	Routine to get password;GETMPW	CALL	GMPW1	LD	A,0E4H		; Get SYS2 for hash	RST	28H;GETSYS2 LD	A,84H		; Load SYS2, no function	RST	28H;GMPW1	LD	A,D		; Password entered as param?	OR	E	JR	Z,GMPW3		; Prompt if not	LD	HL,BUF3$	PUSH	HL	LD	B,08HGMPW2	LD	A,(DE)		; Get password char	CP	0DH		; At end of line?	JR	Z,GMPW4		; Space out if yes	CP	','		; Comma separator?	JR	Z,GMPW4	CP	'"'		; Closing quote?	JR	Z,GMPW4	INC	DE		; Bump pointer	LD	(HL),A		; Xfer the char	INC	HL	DJNZ	GMPW2	JR	GMPW5;;	Not entered as param, get from keyboard;GMPW3	@@DSPLY			; Display request	LD	BC,8<8		; Max 8 chars	LD	HL,BUF3$	; Point to buffer	PUSH	HL	@@KEYIN			; Get password	JP	C,ABRTBU	; Abort on break	EX	DE,HL		; Buf start to DE	LD	H,00H		; Buf length to HL	LD	L,B	ADD	HL,DE		; Pt to 1st unused pos	LD	A,08H		; Calc spaces needed	SUB	B	JR	Z,GMPW5		; None if 8 input	LD	B,A		; Set space counterGMPW4	LD	(HL),' '	; Stuff space	INC	HL		; Bump pointer	DJNZ	GMPW4		; Loop for # spacesGMPW5	POP	HL		; Recover ptr to buffer	PUSH	HL	LD	B,08H		; Loop through fieldGMPW6	LD	A,(HL)	CP	'a'	JR	C,GMPW7	CP	'z'+1	JR	NC,GMPW7	RES	5,(HL)		; Force upper caseGMPW7	INC	HL	DJNZ	GMPW6	POP	DE		; Pointer to start	RET;;	Check a drive for availability;CKDRV	LD	A,(CURDSK+1)	; Get drive spec	LD	C,A		; Put in C	LD	A,(IY+00H)	; Get drive vector	CP	0C3H		; Check for enabled	JP	NZ,CKDR5	; Bypass if disabled	PUSH	HL	PUSH	DE	LD	A,(IY+06H)	; Make sure current	CP	(IY+05H)	; cyl count is in range	JP	NC,CKDRV1	; Go if in range	CALL	RESTOR		; Restore drive	JP	NZ,CKDR7A	; Go if error;CKDRV1	LD	D,(IY+05H)	; Get current track	LD	E,00H		; Set for sector 0	@@SEEK			; Set track into FDC	JP	NZ,CKDR7A	; Go if error	CALL	RSLCT		; Wait until not busy	JR	NZ,CKDR7A	; Not there - return NZ	BIT	3,(IY+03H)	; If hard drive - bypass	JR	NZ,CKDR2B	;   index pulse test	BIT	4,(IY+04H)	; If alien bypass	JR	NZ,CKDR2B	;   test of index pulses;	IF	@MOD4	LD	A,09H		; Set MSB of count down	DI;	ENDIF	IF	@MOD2	LD	A,20	ENDIF;	LD	(CDCNT+1),A	; Store in 'LD H,' instruction	LD	HL,20H		; Set up count (short);;	Test for diskette in drive and rotating;CKDR1	CALL	INDEX		; Test index pulse	JR	NZ,CKDR1	; Jump on indexCDCNT	LD	H,00H		; CKDRV counter (long)				; Count set from aboveCKDR2	CALL	INDEX		; Test index pulse	JR	Z,CKDR2		; Jump on no index;	IF	@MOD4	EI			; Okay for ints now	ENDIF;	LD	HL,20H		; Index off wait (short)CKDR2A	CALL	INDEX	JR	NZ,CKDR2A	; Jump on indexCKDR2B	PUSH	AF		; Save FDC status	LD	D,(IY+09H)	LD	HL,CKDRBUF	; Use this buffer	LD	E,L		; Read the GAT	@@RDSSC			; from directory	JR	NZ,CKDR7	LD	DE,(CKDRBUF+0CCH)	; Get config in D				; and cyl excess in E	LD	A,C		; Get drive (0-7)	RLCA			; Rotate bits into position	RLCA	RLCA	OR	0C4H		; Make instruction - [S/B C6H?!]	BIT	3,D		; Use new year stuff?	JR	NZ,$+4		; Jump if not set	XOR	40H		; Turn into RESET	LD	(SETINST+1),A	; Save in instruction	LD	HL,0		; Get YFLAG$ addressSVYFLG$ EQU	$-2SETINST RLC	B		; becomes (SET/RES) drive#,H [S/B drive#,(HL)]	BIT	3,(IY+03H)	; Hard disk?	JR	NZ,CKDR3	; Skip if hard disk	LD	A,22H		; Set base offset	ADD	A,E		; Add to cyl excess	LD	(IY+06H),A	; Set in DCT	RES	5,(IY+04H)	BIT	5,D		; Is it double sided?	JR	Z,CKDR3	SET	5,(IY+04H)	; Set DS bit in DCTCKDR3	POP	AF	RLCA	OR	(IY+03H)	AND	80H	ADD	A,ACKDR4	EI	POP	DE	POP	HLCKDR5	RET;INDEX	LD	A,H		; Count down tries	OR	L	JR	Z,CKDR7		; Error if counted out	DEC	HL		; Dec the count	CALL	RSLCT		; Check for index pulse	BIT	1,A		; Test index	RET			; Back with conditionCKDR7	POP	AFCKDR7A	LD	A,08H		; Set device not available	OR	A		; Set NZ status	JR	CKDR4		; Leave;;	Parameter Table;PRMTBL$ DB	'S'!80H		; Ver 6.x table format;VAL	EQU	80HSW	EQU	40HSTR	EQU	20HSGL	EQU	10H;	DB	63H	DB	'MPW'	DB	00HMPWRSP	EQU	$-PRMTBL$-1	DW	MPWPRM;	DB	73H	DB	'SYS'SYSRSPB DB	00HSYSRSP	EQU	$-PRMTBL$-1	DW	SYSPRM+1;	DB	53H	DB	'INV'	DB	00HINVRSP	EQU	$-PRMTBL$-1	DW	INVPRM+1;	DB	53H	DB	'MOD'	DB	00HMODRSP	EQU	$-PRMTBL$-1	DW	MODPRM$;	DB	55H	DB	'QUERY'	DB	00HQRSP	EQU	$-PRMTBL$-1	DW	QPARM$;	DB	41H	DB	58H	DB	00HXRSP	EQU	$-PRMTBL$-1	DW	XPARM$+1;	DB	34H	DB	'DATE'	DB	00HDATRSP	EQU	$-PRMTBL$-1	DW	DATPRM+1;	DB	53H	DB	'NEW'	DB	00HNEWRSP	EQU	$-PRMTBL$-1	DW	NEWPRM$;	DB	53H	DB	'OLD'	NOPOLDRSP	EQU	$-PRMTBL$-1	DW	OLDPRM$;	DB	00H		; End of param table;;	Messages and prompts;NOINDO$ DB	'Single drive backup invalid during <DO> processing',0DHNOFMT$	DB	'Destination disk not formatted - Backup aborted',0DHHELLO$	DB	'BACKUP'*GET	CLIENTLDOS$	DB	'Command executes only from DOS Ready',0DHPRMERR$ DB	'Parameter error',0DHSRCNUM$ DB	'Source drive number ?        ',3DSTNUM$ DB	'Destination drive number ?   ',03HNODAT$	DB	'No date established',0DHCLASS$	DB	'Backup by class invoked',0DHCLS1DB$ DB	0AH,'Single drive BACKUP invalid by files',0DHRES$	DB	'SYSRES'RESREQ$ DB	0AH,'This backup requires residency of SYS',27H	DB	's: 2, 3, 10 & 12.',0DHRECON$	DB	'Backup-reconstruct invoked',0DHMIRROR$ DB	'Cylinder count differs - Attempt mirror-image backup ? ',3PMTMPW$ DB	'Master password ?      ',3MAXDAYS DB	1FH,1CH,1FH,1EH,1FH,1EH,1FH,1FH,1EH,1FH,1EH,1FHBADFMT$ DB	'Bad date format',0DH;;;CKDRBUF EQU	$<-8+1<8	DS	256	END