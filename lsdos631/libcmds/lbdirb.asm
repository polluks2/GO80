;LBDIRB/ASM - Display filespec and attributes	SUBTTL	'<LBDIRB - File attribute output>'	PAGE;;	Match - Display a file's name and extension;MATCH	PUSH	HL		; Save HIT position	LD	HL,COUNT+1	; Bump file count	INC	(HL);;	Was the drive header displayed?;	LD	HL,FILFLAG	; HL => file header flag	XOR	A		; If (HL) is non-zero	CP	(HL)		;   then header has not	LD	(HL),A		;   been shown	CALL	NZ,CKTITL	; Display title if NZ;;	Position HL to directory entry filename;ALRPRT	POP	HL		; Recover DEC	LD	A,L		; Get DEC	AND	0E0H		; Position to entry	ADD	A,05H		; Position to start of filename	LD	L,A		; HL => filename field;;	Init B=0 chars for filename, C=19 to col;	LD	C,19		; # chars to next column	LD	B,08H		; Filename;;	Loop to output the filename;DONAM1	LD	A,(HL)		; Get character	INC	HL		; Bump pointer	CP	' '		; Is it a space?	JR	Z,DONAM2	; Yes - done with filename	CALL	BYTOUT2		; No - output char	DJNZ	DONAM1		; Loop for field	JR	DONAM3;;	Filename has < 8 chars - pt to extension;DONAM2	LD	A,L		; Get low byte	ADD	A,B		; Add # of chars left	DEC	A		; Back one	LD	L,A		; HL => extension;;	Does this file have an extension?;DONAM3	LD	A,(HL)		; Get char	CP	' '		; Space?	JR	Z,DONAM5	; Yes - no extension;;	Output a slash and set up for extension loop;	LD	A,'/'		; Display slash	CALL	BYTOUT2	LD	B,3		; 3 chars max for EXT;;	Loop to output the extension;DONAM4	LD	A,(HL)		; Get char	INC	HL		; Bump ptr	CP	' '		; Done?	JR	Z,DONAM5	; Exit on 1st blank	CALL	BYTOUT2		;   else output the char	DJNZ	DONAM4		;   and loop for more;;	Was the (A) parameter specified?;DONAM5	LD	A,(APARM+1)	; Check A-param	OR	A	JR	Z,DONAM5A	; No - continue;;	A parameter specified - Tab to column 14;	LD	A,C		; Get chars left to col 20	SUB	6		; Adjust to col 14	LD	B,A		; Stuff into B for call	CALL	SPCTAB		; output (B) spaces;;	Output mod flag (if modified) and tab to 19;	LD	A,L		; Pt HL => DIR+0	AND	0E0H	LD	L,A	CALL	OUTMOD		; Output "+" if mod	LD	B,01H		; 1 space	CALL	SPCTAB;;	Output the file's attributes;DONAM5A	LD	B,1		; Space one	CALL	SPCTAB;;	Point HL to attributes;	LD	A,L		; Pt to 1st byte of	AND	0E0H		;   directory record	LD	L,A;;	Display "?" if file open bit is set;	LD	A,'?'		; Char to display	INC	HL		; Point to DIR+1	BIT	5,(HL)		; Test open bit	DEC	HL		; Back to DIR+0	CALL	NZ,BYTOUT2	; Yes - display it;;	Display an "*" if this is a PDS file;	LD	B,(HL)		; Get attributes	LD	A,'*'		; Char to display	BIT	5,B		; Is PDS bit set?	CALL	NZ,BYTOUT2	; Yes - display it;;	Display an "S" if file is a SYS file;	BIT	6,B		; Is it a SYS file?	LD	A,'S'	CALL	NZ,BYTOUT2	; Display if it is;;	Display an "I" if file is invisible;	BIT	3,B		; Check INV flag	LD	A,'I'	CALL	NZ,BYTOUT2	; Display if so;;	Point HL to the password field (DIR+16);	PUSH	HL	LD	A,L	ADD	A,10H	LD	L,A;;	Get password into DE;	LD	E,(HL)	INC	L	LD	D,(HL);;	Is this a password protected file?;	PUSH	HL		; Save ptr to user PW	LD	HL,BLKHASH	; Init to blank password	SBC	HL,DE		; Is password empty?	POP	HL	JR	Z,DONAM6	; Go if it is;;	Passworded - display "P" if access <> ALL;	LD	A,B		; Get attribs byte	AND	07H		; Get protection level	LD	A,'P'		; Init for protected	JR	NZ,DONAM7	; Stuff "P" if protected;;	Access = ALL - just show a blank;DONAM6	LD	A,' '		; Stuff a blank;;	Set password flag if protected & display "P";DONAM7	LD	(ALL02+1),A	; Stuff "P" or blank	CP	' '		; Space?	CALL	NZ,BYTOUT2	; Display char if needed	POP	HL		; Get HL => DIR+0 again;;	Display a "C" if the file was created with CREATE command;	INC	HL		; Point to DIR+1	LD	A,(HL)		; Get attributes	DEC	HL		; Point back to DIR+0	RLCA			; Created?	LD	A,'C'		; Init for it	CALL	C,BYTOUT2	; Yes - output the byte;;	Display Mod flag here if (A) not specified;	LD	A,(APARM+1)	; Get A param	OR	A		; Specified?	PUSH	AF		; Save it	CALL	Z,OUTMOD	; Output mod flag if -A	POP	AF		; Get A parm flag back;;	If (A) parameter given, then tab to col 26;	JR	Z,DONAM8	; Not A - goto 20	LD	A,04H		; Add 4 to column	ADD	A,C	LD	C,A		; C = # spaces;;	Position to next designated column;DONAM8	LD	A,' '		; Write a space	CALL	BYTOUT		; Output byte	DEC	C		; Dec column counter	JR	NZ,DONAM8	; Loop for #;;	Display other things if (A) parameter set;APARM	LD	DE,-1		; Get A parameter	LD	A,D		; Specified?	OR	E	CALL	NZ,ALL01	; Full info if A param;;	Check for end of line;DONAM9	LD	A,00H		; Count down 4 across	DEC	A	LD	(DONAM9+1),A	; Update count	RET	NZ		; Loop if more to go	LD	A,04H		; Else re-init to 4 per line	LD	(DONAM9+1),A;;	Finished with one line - end with C/R;ENDLINE	CALL	CR_OUT		; End line	JP	CKPAWS		; Scan pause or break;;	ALL01 - Display full allocation of a file;ALL01	PUSH	HL		; Save pointer to 1st byteALL02	LD	A,00H		; Bypass if not	SUB	' '		;   password protected	JR	Z,ALL03	LD	A,(HL)		; Get prot level	AND	07H		; Multiply by 4ALL03	RLCA	RLCA	LD	C,A	LD	B,00H	LD	HL,PROTS$	; Point to 4 ch abbrevs	ADD	HL,BC		; Point to proper one	LD	DE,PLEVEL	; Move into output line	LD	C,4	LDIR	POP	HL		; Recover pointer to	PUSH	HL		;   1st byte of dir rec	INC	L	INC	L	INC	L;;	Pick up EOF offset byte and save for later;	LD	A,(HL)		; Get EOF offset	LD	(EOFBYTE+1),A	; Save in LD DE,$-$;;	Calculate EOF record according to the formula;	EOFREC = ((ERN-1)+256)+EOF+LRL-1)/LRL if ERN<>0;	EOFREC = 0 if ERN=0;	LD	A,(HL)		; Get EOF offset	PUSH	AF		;   and save it	INC	L		; Point to LRL	LD	A,(HL)		; Get LRL	LD	(ALL04+1),A	; Save it;;	Get LRL into message;	PUSH	HL		; Save pointer	LD	L,A		; Transfer LRL to HL	LD	H,00H	OR	A		; Test for not 256	JR	NZ,NOT256	INC	H		; Show 256NOT256	LD	DE,LRL		; Point to dest	@@HEXDEC		; Put in msg field	POP	HL;;	Continue to calculate EOF;	LD	A,L		; Get ERN	ADD	A,10H	LD	L,A	LD	E,(HL)		; Get ERN into DE	INC	L	LD	D,(HL)	POP	BC		; Recover EOF offset	EX	DE,HL		; Put EOFREC in HLALL04	LD	A,00H		; Get LRL	OR	A	JR	Z,TSTSIZ	; Go use ERN of LRL=0	LD	E,A		; Transfer LRL to E	INC	B		; Test EOF	DEC	B	JR	Z,DONTDEC	; Don't dec ERN if EOF=0	DEC	HL		; Reduce ERN for 0 offsetDONTDEC	CALL	DIVIDE	LD	C,L	LD	D,H	LD	H,A	LD	L,B		; Pick up EOF	LD	A,E	CALL	DIVIDE	LD	H,C	OR	A	JR	Z,DONTINC	INC	HL		; Round up partial recordDONTINC	LD	A,D		; Check if overflow	OR	ATSTSIZ	JR	Z,EOFBYTE	; Use calc'd ERN if not;;	Overflow in # of records - use "*****";	LD	HL,RECORDS	; Point to destination	LD	B,0AH		; 10 asterisksM287B	LD	(HL),'*'	; Fill NumRecs and	INC	HL		;   EOF with "*"	DJNZ	M287B		; Loop	JR	DIR_0;;	if # Records = 0 then set EOF = 0;EOFBYTE	LD	DE,$-$		; Get EOF offset byte	LD	A,H		; # records = 0?	OR	L	JR	NZ,KEEPEOF	; No - keep EOF	LD	E,01H		; Set EOF = 1 (Gets DEC'd)KEEPEOF	PUSH	HL		; Save # of records	LD	HL,OFFSET	; HL => Destination	DEC	E		; DE = EOF byte	EX	DE,HL		; Swap for conversion	@@HEXDEC;;	Stuff # of records used into string;	POP	HL		; Recover # of records	LD	DE,RECORDS	; Destination	@@HEXDEC		;   Stuff into message;;	Get # extents & granules used;DIR_0	POP	HL		; Recover ptr to 1st byte	PUSH	HL	CALL	ALL09		; Get total grans in use	PUSH	DE		; Save total grans	LD	A,C	LD	DE,EXTENTS	CALL	CVA2ASC		; Convert to ASCII	POP	DE;;	DE = grans used - add to Grans counter;	LD	HL,(TOTGRNS+1)	; Get total grans	ADD	HL,DE		; Add this file's count	LD	(TOTGRNS+1),HL	; And put in counter;	LD	HL,KSIZE	; Point to string	CALL	CALCK		; Convert to K	LD	HL,DATEFLD-1	LD	DE,DATEFLD	LD	BC,17		; 17 bytes	LDIR;	POP	HL		; Recover ptr to DIR+0	LD	DE,DATEFLD	INC	HL	INC	HL		; Advance to date field	LD	A,(HL)	OR	A	JP	Z,ALL08		; Ignore if note date saved	RRCA			; Has date, get day	RRCA	RRCA	AND	1FH		; Make sure 0-31	CALL	CVA2ASC		; Convert to ASCII	INC	DE		; Bump ptr	PUSH	HL		; Save ptr to DIR	DEC	HL		; Pt to DIR+1 (month)	LD	A,(HL)		; Get month	AND	0FH		; Strip off flags	DEC	A		; (mon-1)*3 to index	LD	C,A		; String conv table	RLCA			; * 2	ADD	A,C		; * 3	LD	C,A		; Store it	LD	B,0		; BC = offset of month	LD	HL,MONTBL$	; Pt to month table	ADD	HL,BC		; Add offset to table	LD	C,03H		; BC now = 3	LDIR			; Move month field	INC	DE		; Bump dest pointer	LD	A,'-'		; Stuff dashes in date	LD	(DATEFLD+2),A	LD	(DATEFLD+6),A	POP	HL		; Recover DIR+2 ptr	PUSH	HL		; And save it again;;	Date handling stuff for directory;SVYFLG2	LD	A,($-$)		; Get YFLAG$ (stuffed earlier)TSTBIT2	BIT	0,A		; Does drive use new date?	PUSH	AF		; Save flag*LIST	OFF	IFLT	@DOSLVL,'L'	;---> Before changes for 6.3.1L*LIST	ON	JR	NZ,NEWDATE	; Go if uses new date	LD	A,(HL)		;   else get old year field	AND	07H		; Remove day	JR	OLDDATE		; And go convert to asciiNEWDATE	LD	A,L		; Get ptr to DIR+2	ADD	A,11H		; Point to extended date	LD	L,A		; Adjust pointer	LD	A,(HL)		; Get extended date info	AND	1FH		; Mask off other bits*LIST	OFF	ELSE			;<-->*LIST	ON	CALL	GTDIRYR		; Unpack date (CY set if Lev.H+ date)	EX	(SP),HL		; alter saved AF (containing new date style flag)	RES	6,L		; clear Z (Lev.H+ date)	JR	C,L2904		; but if NC,	SET	6,L		; set Z (old date)L2904	EX	(SP),HL		; save back AF	JR	OLDDATE	RRA			;garbage*LIST	OFF	ENDIF			;<--- 6.3.1L*LIST	ONOLDDATE	ADD	A,80		; Put it in proper range	CP	100		; Greater than 99?	JR	C,NOSB100		; Jump if it's not	SUB	100		; Convert to 00-11NOSB100	CALL	CVA2ASC		; Convert to ASCII in buffer	INC	DE	INC	DE		; Bump dest pointer	POP	AF		; Get date flag back	JR	Z,TIMEND	; Skip if old date style;;	Handle new style time stuff;	PUSH	IY		; Save IY	CALL	M2D76		; Get FLAGS, DEC HL, get byte (HL)	AND	0F8H		; Mask off other bits	RRCA			; Shift down three bits	RRCA	RRCA	PUSH	AF		; Save hours	BIT	4,(IY+08H)	; Test AM/PM in DIR thingie	JR	NZ,CVTHOUR	; Jump if it's been set	OR	A		; Is it 00:xx??	JR	NZ,NOTMID	; Go if it's not	LD	A,12		;   else set to 12NOTMID	CP	0DH		; Is it in 0-12 range?	JR	C,CVTHOUR		; Jump if so	SUB	0CH		; Else convert PM timeCVTHOUR	CALL	CVA2ASC		; Convert hours to ASCII	LD	A,':'		; Time separator	LD	(DE),A		; Put it in buffer	INC	DE		; Bump output pointer	LD	A,(HL)		; Get minutes value (part of it)	INC	HL		; Bump pointer	LD	L,(HL)		; Get other byte in L	AND	07H		; Keep bits 0-2 in A	LD	B,03H		; Get top 3 bits of LM2942	SLA	L		; Shifted into A	RLA	DJNZ	M2942		;	CALL	CVA2ASC		; Convert minutes to ASCII	POP	AF		; Get time back	JP	M2D7C		; Test AM/PM and pop IY	NOPM294F	JR	NZ,TIMEND	; Jump if 24 hour time display	CP	12		; Before noon?	LD	A,'a'		; Init for AM	JR	C,M2959		; Jump if before noon	LD	A,'p'		;   else set PMM2959	LD	(DE),A		; Stuff AM/PM indicatorTIMEND	POP	HL		; Clean up stack?;ALL08	LD	HL,PLEVEL	; Point to start of message	CALL	LINOUT		; Output the line	LD	A,01H		; Show only one entry	LD	(DONAM9+1),A	;   per line if (A) param	RET;;	Routine to convert A to ASCII at (DE);CVA2ASC	LD	BC,0030H	; B = 0; C = "0"M296A	SUB	10		; Sub 10 from A	JR	C,M2971		; Jump if done	INC	B		; Inc count	JR	M296A		; Loop;M2971	PUSH	AF		; Save value	LD	A,B		; Get count	ADD	A,C		; Make it "0"-9"	LD	(DE),A		; Stuff byte in buffer	CP	C		; It is "0"?	JR	NZ,M2980	; Go if it isn't "0"	DEC	DE		; Was last char a space?	LD	A,(DE)		; If so, don't write the "0"	INC	DE		; Re-adjust pointer	CP	' '		; Space?	JR	NZ,M2980	; Go if not space	LD	(DE),A		; Else put the charM2980	INC	DE		; Bump dest ptr	POP	AF		; Get val back	ADD	A,':'		; Make ascii	LD	(DE),A		; Put it in buffer	INC	DE		; Bump pointer	RET			;   and return;;;DIVIDE	PUSH	BC		; Save BC	LD	C,A		; Transfer divisor to C	@@DIV16			; Divide HL / C	POP	BC		; Restore BC	RET;;	OUTMOD - Output a "+" if file has been modified;OUTMOD	INC	HL		; HL >= DIR+1	LD	A,' '		; Default to no mod	BIT	6,(HL)		; Test mod flag	JR	Z,OUTCHR	; Go if not set	LD	A,'+'		;   else make it "+"OUTCHR	CALL	BYTOUT2		; Display character	DEC	HL		; Reposition to DIR+0	RET;;	Routine calculates total grans in use;ALL09	LD	A,(SORTPRM+1)	; If sorted, then data	OR	A		;   already calculated	JR	Z,ALL09A	; Go if not sorted	PUSH	HL	POP	IX		; Index this thing	LD	E,(IX+22)	; Get space used	LD	D,(IX+23)	LD	C,(IX+24)	; Get # of extents	LD	B,(IX+25)	RET;;	ALL09A - Calculate space allocated to a file;	HL => DIR+0 of an FPDE;	BC <= # of extents in the file;	DE <= # of grans allocated to the file;ALL09A	LD	DE,0		; Init gran counter to 0	LD	B,E		; Init extent counter to 0	LD	C,E;;	Point ot first extent of the directory entry;ALL10	LD	A,L		; Get low byteALL11	ADD	A,22		; HL => DIR+22	LD	L,A;;	Is the extent field in use?;ALL14	LD	A,(HL)		; Get cylinder	INC	L		; Bump to alloc info	CP	0FEH		; Another extent or done?	JR	NC,ALL15	; Either FE or FF;;	Extent field is in use - get allocation info;	INC	BC		; Bump extent counter	LD	A,(HL)		; Get alloc info	INC	L		; Point to next extent	AND	1FH		; Keep # of grans	INC	A		; Adjust for zero offset;;	A = # of contiguous grans - add to gran counter;	ADD	A,E		; Accumulate # of grans	LD	E,A	JR	NC,ALL14	; Forget hi if no carry	INC	D		; Bump hi	JR	ALL14		; Get next extent field;;	Get DEC if (x'FE') or return if done (x'FF');ALL15	RET	NZ		; Return if not extended	LD	A,(HL)		;   else get DEC of FXDE;;	Point HL to extended directory entry position;	AND	1FH		; Get dir sector of DEC	PUSH	AF		; Save it	XOR	(HL)		; Get dir record of FXDE	LD	L,A		; Save dir record position	POP	AF		; Recover DEC of FXDE;;	Is the dir sector with FXDE already in memory?;	PUSH	HL		; Save the 1st extent pointer	LD	HL,CKHIT6+1	; Do we have this dir sector	CP	(HL)		;   in memory already?	POP	HL		; Recover pointerSBUFFER	LD	H,0		; Restore high order	JR	Z,ALL10		; Jump if we have it;;	Dir sector not resident - is Ext buf resident?;ALL16	CP	0FFH		; Same as extended area?	LD	H,BUF2<-8	; Pt to ext buff area	JR	Z,ALL10		; Jump if we have it there	LD	(ALL16+1),A	;   else updt the test byte;;	Set B to the DEC of the FXDE;	PUSH	BC		; Save the gran counter	PUSH	DE		; Save extent counter	OR	L		; Combine sector & record	LD	B,A		; Pointers to retrieve DEC;;	Set C = logical drive #, D = directory cylinder;	LD	A,(DRIVE)	; Get ASCII drive number	SUB	'0'		; Convert to binary	LD	C,A		; Save it in C	LD	D,(IY+09H)	; Get directory cyl in D;;	Set E = FXDE's dir sector, HL => IO buffer;	LD	A,B		; Get DEC	AND	1FH		; Get sector num	ADD	A,02H		; Adjust for GAT and HIT	LD	E,A		; Put that in E	LD	HL,BUF2		; Point HL to I/O buffer;;	Read in the FXDE's directory sector;	@@RDSEC			; Read a sector	CP	06H		; Expecting error 6	LD	A,11H		; Read error?	JP	NZ,IOERR	; Jump if we got an error;;	Set A = offset into sector of entry;	LD	A,B		; Get FXDE DEC in A	AND	0E0H		; Point to dir record	POP	DE		; Restore counters	POP	BC	JR	ALL11		; Loop through extents;;	LINOUT - Output a line to *DO/*PR;	HL => buffer to ouput;LINOUT	@@DSPLY			; Output the line to *DO	JR	NZ,JPIOERR	; Go on an error	LD	A,(PPARM+1)	; Want printed output?	OR	A	RET	Z		; None specified - return	@@PRINT			; Output the line to *PRJPIOERR	JP	NZ,IOERR	; Go if an error	RET;;	BYTOUT - Output a byte to *DO/*PR;	A = character to output;BYTOUT2	DEC	C		; Decrement column numberBYTOUT	PUSH	BC		; Save BC	LD	C,A		; Display char goes in C	@@DSP			; Display it	JR	NZ,JPIOERR	; Go on errorPPARM	LD	DE,0		; Get P parameter	INC	E		; Specified?	JR	NZ,NOPRT	; No - don't print it	@@PRT			; Print it	JR	NZ,JPIOERR	; Go on error	LD	A,C		; Get char backNOPRT	POP	BC		; Restore BC	RET			;   and return;;	Output # spaces specified in B reg;SPCTAB	LD	A,' '		; Space char	CALL	BYTOUT2		; Output it	DJNZ	SPCTAB		; Loop	RET			;   and return;	END