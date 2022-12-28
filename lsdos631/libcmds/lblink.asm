;LBLINK/ASM - LINK command	TITLE	<LINK - LS-DOS 6.3>;*GET	SVCEQU			; SVC call equates;CR	EQU	13LF	EQU	10;	ORG	2400H;LINK	LD	DE,FCB1		; Fetch source spec	LD	A,@FSPEC	RST	28H	JR	NZ,SPCERR1	; Exit if bad name	LD	A,(DE)	CP	'*'		; Must be a device	JR	NZ,SPCERR;;	Fetch second device spec;	LD	DE,FCB2		; Fetch destination spec	LD	A,@FSPEC	RST	28H	JR	NZ,SPCERR	; Exit if bad name	LD	A,(DE)	CP	'*'		; Must also be a deviceSPCERR1	JR	NZ,SPCERR;;	Make sure source <> destination;	LD	HL,(FCB1+1)	; If devices are the same	LD	DE,(FCB2+1)	;   then quit	SBC	HL,DE	JR	Z,SPCERR;;	Locate a spare DCB for the link;	LD	DE,0	LD	A,@GTDCB	RST	28H	LD	A,33		; Init "No spare device"	JR	NZ,IOERR	LD	(LINKDCB+1),HL	; Save pointer;;	Locate destination DCB address;	LD	DE,(FCB2+1)	; Grab DCB name	LD	A,@GTDCB	; Locate its address	RST	28H	JR	NZ,IOERR	; Jump if not found	LD	(DSTDCB+1),HL	; Save destination;;	Locate source DCB address;	LD	DE,(FCB1+1)	; Get 1st DCB name	LD	A,@GTDCB	; Locate in device tables	RST	28H	JR	NZ,IOERR	; Jump if not found	PUSH	HL		; Save pointer we used	DI			; Can't interrupt right now;;	Save old device vector while stuffing new one;LINKDCB	LD	BC,$-$		; Get link DCB address	INC	L		; Bump to vector	LD	A,(HL)		; Save what's there	LD	(HL),C		; Stuff link address	LD	C,A		;   into DCB of source	INC	L		;   while saving old	LD	A,(HL)		;   vector for storage	LD	(HL),B		;   (could be a FCB)	LD	B,A;;	Now set LINK bit and rest of LINK DCB block;	POP	HL		; Get ptr to src DCB+0	LD	A,(HL)		; Get the LINK bit	PUSH	AF		; Save old TYPE byte	AND	07H		; Strip flags	OR	20H		; Set link bit	LD	(HL),A		; Show source is linked	LD	HL,(LINKDCB+1)	; Get link DCB address	POP	AF		; Get source TYPE back	LD	(HL),A		; Set new LINK TYPE	INC	L	LD	(HL),C		; Stuff the source vector	INC	L	LD	(HL),B	INC	L		; Bypass dest TYPE	INC	LDSTDCB	LD	BC,$-$		; Get destination DCB addr	LD	(HL),C		;   and stuff into link DCB	INC	L	LD	(HL),B	INC	L	PUSH	HL		; Save name field pointer	LD	DE,'/L'		; Let's find link nameNAMLP	INC	D		; Bump 2nd char	LD	A,@GTDCB	; If we find this name	RST	28H	JR	Z,NAMLP		;   look for another	POP	HL		; Get name pointer	LD	(HL),E		;   & stuff in the	INC	L		;   selected link name	LD	(HL),D	EI			; Start tasks again	LD	HL,0		; Show no error	RET;;	Error processing;IOERR	LD	L,A		; Move error # to HL	LD	H,0	OR	0C0H		; Abbrev and return	LD	C,A		; Code to C for @ERROR	LD	A,@ERROR	RST	28H	RET;SPCERR	LD	HL,SPCERR$	LD	A,@LOGOT	; Log error	RST	28H	LD	HL,-1		; Init error code	RET			; and return;;	The error message;SPCERR$	DB	'Device spec required',CR;;	Other data;FCB1	DS	3		; Only 3 bytes neededFCB2	DS	32;	END	LINK