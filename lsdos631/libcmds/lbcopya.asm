; LBCOPYA/ASM - Copy/Append commands	SUBTTL	'<LBCOPYA - APPEND Mainline>';PAGE;;	Jump to COPY Entry PointCOPY	JP	COPYST		; Go to COPY;;	APPEND entry point - Was <BREAK> hit?;APPEND	LD	(SAVESP+1),SP	; Save stack pointer!	@@CKBRKC		; 6AH - @CKBRKC	JR	NZ,ABORT	; Jump if BREAK set	CALL	APCODE;;	Done - Exit the module;EXIT	LD	HL,0	JR	SAVESP;;	I/O Error Display and Abort RoutineIOERR	PUSH	AF		; Save error code	CALL	PMTSYS		; Prompt SYSTEM DISK	POP	AF		; Recover error code	LD	L,A		; Move to HL	LD	H,0	OR	0C0H		; Set for ABBREV err msg	LD	C,A		; Save Error # in C	@@ERROR			; @ERRORSAVESP	LD	SP,$-$		; Get us out of here	@@CKBRKC		; Clear any break	RET			;  and return;;	Load HL with error message string to displaySAMERR	LD	HL,SAMERR$	; Source & dest same	DB	0DDHSPCREQ	LD	HL,SPCREQ$	; File spec required	DB	0DDHNOINDO	LD	HL,NOINDO$	; Invalid during DO	DB	0DDHDIFLRL	LD	HL,DIFLRL$	; Files have diff LRLs	DB	0DDHDSTREQ	LD	HL,DSTREQ$	; Dest spec required	@@LOGOT			; Log error message;;	Attempt to close any OPEN destination file;	LD	DE,FCB2		; Point to dest FCB	LD	A,(DE)		; Is the file open?	RLCA	JR	NC,ABORT	; No - abort	@@CLOSE			; Close the file;ABORT	LD	HL,-1		; Abort code in HL	JR	SAVESP		; Get us out of here;;	APCODE - Append spec to spec;APCODE	XOR	A		; Turn off CLONE param	LD	(CPARM+1),A	LD	(CPARM+2),A	LD	(APPFLAG+1),A	; We're in APPEND not COPY;	CALL	DOINIT		; Set high memory;;	Check if Filespec/Devspec #1 is legal;	LD	DE,FCB1		; DE => File #1 FCB	@@FSPEC			; Check out filespec	JP	NZ,SPCREQ	; NZ - Filespec required;;	Check if Filespec/Devspec #2 is legal;	LD	DE,FCB2		; DC => File #2 FCB	@@FSPEC			; Check if legal	CALL	NZ,CVRTUC	; Convert line to upper case;;	Is the second FCB a device?;	LD	A,(FCB2)	; p/u Byte 0 of FCB	CP	'*'		; Is this a devspec?	JP	Z,SPCREQ	; Z - Filespec required;;	Parse any parameters entered;	LD	DE,APPTBL	; DE => Param table	@@PARAM			; Check out parameters	JP	NZ,IOERR	; NZ - Parameter error;	CALL	PRSPC		; get FCB ptr in DE;;	Open Filespec #2 with LRL of 256;	CALL	OPENSR2		; Open filespec #2	CALL	PUTDEST		; Xfer dest filespec	CALL	GETLRL		; Get LRL from DIR entry;	LD	(LRL2+1),A	; Set dir LRL into parm	LD	(GEOF1+1),A	; Also stuff for later;;	Open filespec #1 with LRL of 256;	CALL	OPENSRC		; Open filename #1	CALL	PUTSOUR		; Xfer source filename;;	Is the source a device?;	EX	DE,HL	BIT	7,(HL)		; get FCB+0 of source	EX	DE,HL		; Device?	CALL	Z,CPYFILE	; Display "Appending..."	JR	Z,APND2		; Yes - don't check LRLs;;	File source - Check if LRLs are different;	CALL	GETLRL		; Get LRL of filespec 1LRL2	LD	B,00H		; Get LRL of filespec 2	XOR	B		; Same?	JP	NZ,DIFLRL	; No - Different LRLs	CALL	CPYFILE		; "Appending...";;	Files have same LRLs, check STRIP parameter;SPARM	LD	DE,$-$		; p/u strip parameter	LD	A,D		; if STRIP then must do	OR	E		;   byte I/O	JR	NZ,APND2	; Go if STRIP;;	Pick up End of File offset byte from FCB;	LD	A,(FCB2+8)	; Get EOF mark	OR	A		; if full sectors, use	JR	Z,APND3		; Sector I/O;;	EOF not on page boundary - use byte I/O;APND2	LD	DE,FCB2		; Get FCB	@@PEOF			; Position to end of file	LD	A,(SPARM+1)	; Get SPARM	OR	A		; Specified?	JR	Z,APND2A	; No - dont' backspace;;	SPARM specified - Backspace one byte;	LD	HL,FCB2+9	; HL => LRL of FCB 2	LD	B,(HL)		; Get current dest LRL	LD	(HL),01H	; Reset LRL=1	@@BKSP			; Backspace 1 byte	LD	(HL),B		; Reset LRL back;;	Replace the I/O buffer in FCB #2;APND2A	LD	HL,BUF2		; HL => new buffer addr	LD	(FCB2+3),HL	; Stuff in FCB	JP	BYTIO0;;	EOF on page boundary, use sector I/O;APND3	LD	BC,(FCB1+12)	; Get ERN of source	LD	A,B		; If source is null	OR	C		;  file, don't do any	JP	Z,GEOF3		;  appending, just close;;	Write ending record number;	LD	HL,(FCB2+12)	; Get ERN of dest	PUSH	HL		; Save it for later	ADD	HL,BC		; Add the two to find new	LD	B,H		;  ERN & xfer new ERN to BC	LD	C,L	CALL	WRERN		; Write a data sector	POP	HL		; Recover original ERN	LD	(FCB2+12),HL	;  & reset FCB to it	@@PEOF			; Position to end of file	JP	XFER5	SUBTTL	'<LBCOPYA - COPY Mainline>';	PAGE;;	COPY Entry Point - was <BREAK> hit?;COPYST	LD	(SAVESP+1),SP	; Save stack pointer	@@CKBRKC		; Check for break	JP	NZ,ABORT	; Go if break hit;;	BREAK not hit - execute module;	CALL	COPYCD		; Do it	JP	EXIT		; and then exit;;	COPYCD - Copy spec to spec;COPYCD	CALL	DOINIT		; Set high mem test byte;;	Check if Source filespec is legal;	LD	DE,FCB1		; DE => source fcb	@@FSPEC			; Check out filespec	JP	NZ,SPCREQ	; NZ - filespec required;;	Check destination filespec is legal;	LD	DE,FCB2		; DE -> dest fcb	@@FSPEC			; Check out filespec	CALL	NZ,CVRTUC	; Convert line to U/C;COPY1	LD	DE,COPYTBL	; DE => Parameter table	@@PARAM			; Check out parameters	JP	NZ,IOERR	; NZ - Parameter error;;	Test if X parameter entered;XPARM	LD	DE,$-$		; p/u (X) parm - We don't	LD	A,D		;  XFER devices	OR	E	JR	NZ,XFER;;	Is the Source or Destination a device?;	CALL	CKDEV		; Device?	JP	Z,BYTEIO	; Yes - use byte I/O;;	Pick up defaults for source and destination;	CALL	PRSPC		; Grab defaults	JR	OPNSRC;;	XFER Initialization code;XFER	@@FLAGS			; Position IY to flags	BIT	5,(IY+12H)	; DO active?	JP	NZ,NOINDO	; Yes - abort;;	If the source or dest is a device - abort;	CALL	CKDEV		; Device?	JP	Z,SPCREQ	; Yes - Filespecs required;;	P/u Drivespec of source filespec if entered;	LD	HL,FCB1	LD	C,00H		; Init to drive 0;;	Loop to pick up Drive # or terminator;XFER1	LD	A,(HL)		; Look for drive spec	INC	HL	CP	':'		; Colon indicator?	JR	Z,XFER2		; Jump if found	CP	' '		; Jump on end	JR	C,XFER3	JR	XFER1;;	Colon indicator present - p/u drive #;XFER2	LD	A,(HL)		; P/u user drive	SUB	'0'		; Convert to binary	LD	C,A		;  & stuff into C;;	Save source drive number;XFER3	LD	HL,XFRDRV+1	; HL => Drive #	LD	(HL),C		; Save drive # for later;;	Stuff drive # into prompt strings;	LD	A,'0'		; Cvt drive to ASCII	ADD	A,C	LD	(SRC_DR),A	; Source drive #	LD	(DEST_DR),A	; Destination drive #;;	Transfer source FCB to destination FCB;	LD	HL,FCB1		; HL => Source FCB	LD	DE,FCB2		; DE => Destination FCB	LD	BC,20H		; 32 bytes to xfer	LDIR			; do it;	CALL	GETSYS2		; Load SYS2 for OPEN;;	Flash "Insert source disk" message;	LD	HL,PMTSRC$	; Prompt for source	CALL	FLASH		;   and wait for ENTER;;	Read in the GAT of the source disk;	LD	A,(XFRDRV+1)	; Get source drive	LD	C,A		; Stuff in C	CALL	RDGAT		; Read in GAT	JP	NZ,IOERR	; Abort on GAT error;;	Xfer password, name & date to destination;	LD	HL,GAT+0CEH	; Disk PW, Name and Date	LD	DE,SRCSTR	; DE => Destination	LD	BC,0012H	; 18 bytes	LDIR;;	Open the source file with a LRL of 256;OPNSRC	CALL	OPENSRC		; Open source file	CALL	PUTSOUR		; Xfer source filespec	CALL	GETCLON		; Get clone data;;	Pick up source drive and muck with it;	LD	A,(FCB1+6)	; Get drive # of source	AND	07H		; Mask off other bits	CALL	M28FC		; 0=47,1=4F,2=57,3=5F,etc.	LD	(M25A7),A	; And store it in instrYFLAG1	LD	A,($-$)		; Get YFLAG$	RLC	B		; Rotate carry to CM25A7	EQU	$-1	JR	NZ,M25AF;	LD	A,0FFH	LD	(M26C4),A	; Store for OR (vs 0FEH);;	Pick up source LRL;M25AF	LD	A,L		; Pt back to LRL of source	SUB	10H	LD	L,A	LD	A,(HL)		; Get source LRL;;	Save LRL from source FCB or LRL parameter;LPARM	LD	BC,0FF00H	; Get LRL	INC	B	JR	NZ,USEREGC	; If parm entered, use it	LD	C,AUSEREGC	LD	HL,GEOF1+1	; HL => Stuff LRL here	LD	(HL),C		; Stuff LRL for close here;;	Ignore this if not COPY (X);	LD	A,(XPARM+1)	; Bypass if not (X)	OR	A	JR	Z,OPNDST;;	Flash "Insert destination disk" message;	LD	HL,PMTDST$	; Prompt destination	CALL	FLASH		; Flash until loaded;;	Read GAT of destination drive;	LD	A,(XFRDRV+1)	; p/u drive	LD	C,A		; Read GAT from dest	CALL	RDGAT	JP	NZ,IOERR	; Jump on GAT read error;;	Xfer name, password and date to destination;	LD	HL,GAT+0CEH	; HL => GAT + X'CE'	LD	DE,DSTSTR	; DE => Destination	LD	BC,0012H	; To match up when	PUSH	DE	LDIR			;   swapping disks	POP	DE		; Restore dest ptr;;	Check if source ID = dest ID;	LD	HL,SRCSTR	; Compare source & dest	LD	B,12H		; 18 bytes	CALL	CPRHLDE		; MPW, PackID & Date	JR	NZ,OPNDST	; Bypass if different;;	Display "Source & Dest disks identical";	CALL	PMTSYS		; Prompt for SYSTEM	JP	SAMERR		; Pack IDs identical;;	Open the destination file;OPNDST	LD	DE,FCB2		; DE => FCB2	LD	HL,BUF1		; HL => I/O Buffer 1	CALL	INITDES		; Init the file	CALL	PUTDEST		; Xfer dest filename;;	Do the weird thing with the drive;	LD	A,(FCB2+6)	; Get Drive from FCB2	AND	07H		; Mask off other stuff	CALL	M28FC		; Call the weird thing	LD	(M260D),A	; Store in codeYFLAG2	LD	A,($-$)		; Get YFLAG thing	RLC	BM260D	EQU	$-1	JR	Z,M2614		; Jump if Z	LD	HL,M26C4	; Point to thing	INC	(HL)		; And incremement it;;	Check if X parm entered;M2614	LD	A,(XPARM+1)	; If (X) then source &	OR	A		;   dest can be same file	JR	NZ,XF2		; Bypass if X;;	Do source and dest have same DEC and drive #?;	LD	HL,(FCB1+6)	; Get drive and DEC from FCB1	LD	DE,(FCB2+6)	; Get drive and DEC from FCB2	XOR	A		; Clear carry	SBC	HL,DE		; Subtract for comparison	JP	Z,DSTREQ	; Same - Dest spec required;;	Write revised ERN for space check;XF2	CALL	CPYFILE		; "Copying : ..."	LD	BC,(FCB1+12)	; Get ESN	CALL	WRERN		; Write a FORMAT sector;;	Reset Destination ESN to zero;	LD	HL,0		; Rewind file	LD	(FCB2+12),HL	@@REW			; Rewind it;XFER5	CALL	PMTSRC		; Display "Insert Source";;	Stuff correct buffer address in source FCB;	LD	HL,BUF1		; Stuff in FCBRDREC1	LD	(FCB1+3),HL	; Set buffer address;;	Read in a source sector;	LD	DE,FCB1		; Get source FCB	@@READ			; Read a record	JR	Z,RDREC2	; Bypass if no error;;	Some sort of I/O error - check it out;	CP	1CH		; EOF?	JR	Z,GOTEOF	CP	1DH		; NRN > ERN?	JR	Z,GOTEOF	JP	IOERR		; Abort!;;	Successful READ - is there enough memory?;RDREC2	INC	H		; Bump memory pointer	LD	A,H		; Go past top?RDREC3	CP	$-$	JR	NZ,RDREC1	; Loop if not;;	Read all we could - display "Insert Dest";	CALL	PMTDST		; Get destination;;	Stuff source FCB buffer into Destination FCB;	LD	HL,BUF1		; Set buffer startRDREC4	LD	(FCB2+3),HL;;	Loop to write destination file;	LD	DE,FCB2		; DE => Destination FCB	@@WRITE			; Write a sector	JP	NZ,IOERR	; Jump on write error;;	Bump memory ptr & check if finished;	INC	H		; Else bump memory pointer	LD	A,H		; At top?RDREC5	CP	00H		; test it	JR	NZ,RDREC4	; Loop if not	JR	XFER5		; Else go back to source;;	Got EOF error from source - Write out EOF;GOTEOF	CALL	GEOF5		; Write any memory left	LD	HL,(FCB1+8)	; Get EOF and LRL	LD	(FCB2+8),HL	; Xfer to FCB2;;	Get @CLOSE module if needed;	CALL	PMTSYS		; Prompt for SYSTEM if needed	CALL	GETSYS3		; Load SYS3 for CLOSE	LD	A,(XFRDRV+1)	; Get drive #	OR	A		; Is it 0?	CALL	Z,PMTDST	; Get dest if drive 0;;	Close the destination file;	LD	BC,(FCB2+6)	; Get DEC and drive from FCB2	LD	DE,FCB2		; Get Dest FCB in DE	@@CLOSE			; Close a file svc	JP	NZ,IOERR	; Jump on error;;	Get the destination file directory record;	@@DIRRD			; Get dest dir entry	JP	NZ,IOERR	; I/O error - abort;;	Stuff new LRL into directory entry;	PUSH	BC		; Save drive and DEC;	PUSH	HL		; HL => DIR+0 of dest	LD	A,04H		; Posn to LRL byte	ADD	A,L	LD	L,A		; HL => DIR+4 (LRL)GEOF1	LD	(HL),00H	; GEOF1+1 contains LRL	POP	HL		; Restore HL;;	Pick up the Clone parameter;CPARM	LD	DE,-1		; Default = ON	LD	A,D		; Was it changed?	OR	E	JR	Z,GEOF2		; CLONE = N;;	CLONE = Yes, Transfer attributes and data;	PUSH	HL		; Save HL	EX	DE,HL		; DE => DIR+0	LD	HL,CLONSAV	; HL => Attr	LD	BC,3		; 3 bytes	LDIR	LD	A,0DH		; Pt to DIR password flds	ADD	A,E	LD	E,A		; DE => DIR+16	LD	C,04H		; 4 bytes to xfer	LDIR;;	Probably mucking with dates and stuff;	DEC	DE		; DE => DIR+19	POP	HL		; HL => DIR+0	LD	A,0FEHM26C4	EQU	$-1	OR	A		; Changed it?	JR	NZ,GEOF2	; Jump if not	INC	HL		; DIR+1	INC	HL		; DIR+2	LD	A,(HL)		; Get byte	AND	07H		; Mask off lower part	LD	(DE),A		; Store in DIR+19	DEC	DE		; DE => DIR+18	XOR	A		; Clear A	LD	(DE),A		; Store in DIR+18;;	Write out directory entry;GEOF2	POP	BC		; Recover drive & DEC	@@DIRWR				; Write directory entry	JR	GEOF4;;	Close the destination file;GEOF3A	LD	HL,-1		; Abort JCL	LD	(RETCOD+1),HL	;  if BREAK hitGEOF3	LD	DE,FCB2		; DE => Destination FCB	@@CLOSE			; Close itGEOF4	JP	NZ,IOERR	; I/O Error - abort;;	Flash "Insert system disk" and exit;	CALL	PMTSYS		; Prompt for SYSTEM if neededRETCOD	LD	HL,$-$		; Return code (0=good)	JP	SAVESP		; Finished;;	Write a format sector on FILE #2;WRERN	LD	DE,FCB2		; DE => File 2 FCB	LD	A,B		; Don't bother to write	OR	C		;  a sector if source	RET	Z		; is empty;;	Position to ERN of file #2;	DEC	BC		; Adj for ERN	@@POSN			; Position to ERN	PUSH	DE		; Save FCB pointer;;	Fill a buffer with X'E5's;	LD	HL,BUF1		; HL => I/O Buffer	LD	DE,BUF1+1	; DE => I/O Buffer + 1	LD	BC,0FFH		; 255+1 bytes to fill	LD	(HL),0E5H	; Format byte = X'E5'	LDIR			; Do it;;	Write ERN of file #2;	POP	DE		; Get FCB2 back	@@WRITE			; Write sector	RET	Z		; Return if no error	JP	IOERR		; Error - abort;;	BYTEIO - Open source or dest using byte I/O;BYTEIO	CALL	OPENSRC		; Open source file	CALL	PUTSOUR		; Get source filespec;;	INIT the dest device with LRL from parm;	LD	A,(LPARM+1)	; Get LRL from parm	LD	B,A		; Open destination	LD	DE,FCB2		; DE => FCB #2	LD	HL,BUF2		; Different buffer	LD	A,@INIT		; @INIT SVC #	CALL	GETFILE		; Issue it	CALL	PUTDEST		; Get dest devspec	CALL	CPYFILE		; "Copying/Appending : ..."	XOR	A		; Reset LRL=0	LD	(FCB2+9),A	; For sector I/O;;	Turn on cursor;BYTIO0	LD	C,0EH		; Turn Cursor on	CALL	DISPB		; Display byte;;	BYTIO1 Loop - File - Dev, Dev - File, Dev - Dev;	Was the <BREAK> key hit?;BYTIO1	CALL	CKBRK		; Was BREAK hit?E_O_F	JP	NZ,GEOF3A;;	<BREAK> was not hit - get a character;	LD	DE,FCB1		; DE => Source FCB	@@GET			; Get a byte	JR	Z,BYTIO4	; Good - stuff it;;	If Error # = 0 then try @GET again;	OR	A		; Error # = 0?	JR	Z,BYTIO1	; Yes - @GET again;;	Is the error an "End of file" error?;	CP	1CH		; EOF?	JP	Z,GEOF3		; Yes - finished	JP	IOERR		; No - Abort;;	Was the source character a <BREAK>?BYTIO4	CP	BREAK	JR	NZ,BYTIO4A	; No - @PUT it;;	Source = <BREAK> --- is the BREAK bit set?;	CALL	CKBRK		; <BREAK> bit set?	JR	NZ,E_O_F	; Yes - stop	LD	A,BREAK		; No - restore it;;	Output byte to destination;BYTIO4A	LD	DE,FCB2		; DE => Dest device/file	LD	C,A		; Stuff byte in C for output	@@PUT			; Output byte SVC	JP	NZ,IOERR	; NZ - I/O Error;;	Echo byte if parameter set;EPARM	LD	DE,$-$		; Get ECHO parm	INC	D		; Specified?	CALL	Z,DISPB		; Echo byte	JR	BYTIO1		; Go til EOF or BREAK;