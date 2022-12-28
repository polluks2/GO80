;****************************************************************;* Filename: TASKER/ASM						*;* Rev Date: 30 Nov 97						*;* Revision: 6.3.1						*;****************************************************************;* System front end and task processor				*;*								*;****************************************************************;;	Interrupt task table, IM 1;CORE$	DEFL	$		;save where we are;	ORG	TCB$	DW	NOTASK,NOTASK,NOTASK,NOTASK	DW	NOTASK,NOTASK,NOTASK,NOTASK	DW	NOTASK,NOTASK,TYPTSK$,NOTASK	ORG	CORE$;;	Model IV Task Processor;RST38@	EX	(SP),HL	LD	(PCSAVE$),HL	;Save for trace	EX	(SP),HL	PUSH	HL		;Save HL for now	PUSH	AF		;  and AF	LD	HL,NFLAG$	;Show the system we	SET	6,(HL)		; are in the tasker	LD	HL,LBANK$	;Get & save current	LD	A,(HL)		;  logical bank	LD	(HL),0	PUSH	AF	LD	HL,OPREG$	;Get current memory	LD	A,(HL)	PUSH	AF		;  configuration & save	AND	8CH		;Strip bits 0,1,4-6	OR	3		;Bring up regular 64k	LD	(HL),A	OUT	(084H),AINTLAT	EQU	0E0H		;Interrupt latch	IN	A,(INTLAT)	;Get it	CPL			;Mod 4 is reverse	LD	HL,INTIM$	;Store state of int	LD	(HL),A	INC	L		;Advance to int mask	AND	(HL)		;Mask the latch bits	JR	Z,TSTBRK	;Go if nothing interuptedNXTVCT	INC	L		;Ck on intvc$	RRA			;Ck if device interrupted	JR	C,ACTVTSKNXTMSK	INC	L		;Check all 8 bits	OR	A		;When fin, ck overhead	JR	NZ,NXTVCT	;  task routine;TSTBRK	CALL	KCK@		;Test <BREAK>, <SHIFT>	JR	NZ,BREAK?	;Go if breakTSKEXIT POP	AF		;Get previous mem config	LD	(OPREG$),A	;  and restore it	OUT	(084H),A	POP	AF	LD	(LBANK$),A	LD	HL,NFLAG$	;Now leaving tasker	RES	6,(HL)		;  tell the system	POP	AF		;Restore previous regs	POP	HL	EIRETINST RET;;;	Found active INTVC$;ACTVTSK PUSH	AF		;Save the whales	PUSH	BC	PUSH	DE	PUSH	HL	PUSH	IX	LD	DE,POPREGS	;Stack return vector	PUSH	DE	LD	E,(HL)		;Get intvc pointer vector	INC	L	LD	D,(HL)	EX	DE,HL		;Move it to hl	JP	(HL)		;Go to service routine;;	Register restoral after service routine;POPREGS POP	IX	POP	HL	POP	DE	POP	BC	POP	AF	JR	NXTMSK		;Loop to next mask bit;;	break key detected;BREAK?	JR	NC,GOTBRK	;Go if break only	PUSH	BC		;Was shift break	DI	CALL	TAPDRV		;Reselect drive	POP	BC	JR	TSKEXIT;;	Break during tasking - enter debug? - user break?;GOTBRK	LD	A,(SFLAG$)	;Check if break key is	AND	10H		;  disabled to inhibit	JR	NZ,TSKEXIT	;  debug or break vector	LD	HL,@DBGHK	;Merge debug flag &	OR	(HL)		;  hook (00h or c9h)	LD	(HL),0C9H	;Turn off debug	INC	HL		;Point to debug vector	JR	Z,EXITBRK	;  & go if debug active;	LD	A,(PCSAVE$+1)	;Don't allow vectored break	CP	MAXCOR$<-8	;  if old pc is in sysres	JR	C,TSKEXIT	LD	HL,HIGH$+1	;  or if above high$	CP	(HL)	JR	NC,TSKEXIT	LD	HL,0		;  else ck if break isBRKVEC$ EQU	$-2	LD	A,H		;  to be trapped by user	OR	L	JR	Z,TSKEXITEXITBRK POP	AF		;Discard old mem config	POP	AF		;Restore AF reg	POP	AF	EX	(SP),HL	EI	RET			;To debug or break vector;;	Real time clock interrupt processor;RTCPROC EQU	$	IN	A,(0ECH)	;Clear the rtc interrupt	LD	A,11		;Task 11 executes every	CALL	RTCTASK		;  rtc interrupt	LD	HL,TIMSL$	RLC	(HL)		;Check on time slice	RET	NC		;Ignore if nothing	LD	DE,TIMTSK$	;  on this interrupt	PUSH	DE		;  else init for clocker	LD	A,8		;Task 8 at int/2 if fast	CALL	RTCTASK	LD	A,9	CALL	RTCTASK	LD	A,10	CALL	RTCTASK	LD	HL,TIMER$	;Bump the timer at int/2	INC	(HL)	LD	A,(HL)		;Get heartbeat	AND	7		;For this interrupt,RTCTASK RLCA			;  consider 0-7 only	ADD	A,TCB$&0FFH	;Add offset to table	LD	L,A	LD	H,TCB$<-8	LD	(@RPTSK+1),HL	;Save (6.3.1)	LD	E,(HL)		;Get task vector addr	INC	L	LD	D,(HL)	PUSH	DE	POP	IX		;Also to IX	EX	DE,HL	LD	E,(HL)		;Get task entry point	INC	HL	LD	D,(HL)	EX	DE,HL	JP	(HL)		;Go to task;@KLTSK	POP	DE		;Remove ret	LD	A,(@RPTSK+1)	;Point to task table entry	SUB	TCB$&0FFH	RRCA			;  of the last task;@RMTSK	LD	DE,NOTASK	;Remove entry;@ADTSK	CP	12		;Too large a task?	RET	NC	RLCA			;Add to task table	ADD	A,TCB$&0FFH	;Add the offset	LD	L,A		;Point to vector	LD	H,TCB$<-8CHGTASK DI			;No interruptions	LD	(HL),E		;Put addr to ptr table	INC	L	LD	(HL),D	EI			;Now it's okay	RET;NOTASK	DW	$-1		;Current task vector;@RPTSK	LD	HL,0		;Get last task done	LD	E,(HL)		;Get task vector addr	INC	HL	LD	D,(HL)	EX	DE,HL	POP	DE		;Pop ret addr	JR	CHGTASK;;	Routine to see if a task slot active;@CKTSK	RLCA			;Task # times 2	ADD	A,TCB$&0FFH+1	;Index into task table	LD	L,A	LD	H,TCB$<-8	LD	A,NOTASK<-8	;Check match of high	CP	(HL)		;  order only	RET			;Z or NZ;