;****************************************************************;* Filename: PRDVR/ASM						*;* Rev Date: 30 Nov 97						*;* Revision: 6.3.1						*;****************************************************************;* TRS-80 Model 4 Printer Driver routines			*;****************************************************************;	SUBTTL	'<Printer Driver>'*MODPRPORT	EQU	0F8H		;Address of printer port;;	PR driver entry point;	It passes 00-FF unless;	international version;PRDVR	JR	PRBGN		;Branch around linkage	DW	PREND		;Last byte used	DB	3,'$PR'	DW	PRDCB$		;Pointer to its DCB	DW	0		;Reserved;;	Driver Code;PRBGN	JR	Z,$?2		;Go if output	JR	C,$?1		;Go if input req;;	Character CTL request;	LD	A,C		;if CTL 0 return	OR	A		;  status else	JR	Z,$?4		;  treat as a GET;;	Character GET request;$?1	OR	0FFH		;Set NZ	CPL			;  & A=0 to show	RET			;  no char available;;	Character PUT request;$?2	LD	DE,-1		;Check status 65535 times$?2A	CALL	$?4		;PR ready?	JR	Z,$?3		;Go if so;;	Ten second timeout delay loop;	PUSH	BC		;Printer was not ready	LD	BC,8	CALL	PAUSE@		;Delay a bit	POP	BCTSLPX@	DEC	DE		;Time up?	LD	A,D	OR	E	JR	NZ,$?2A		;Nope, continue check	LD	A,8		;Device not available	OR	A		;Set NZ condition	RET$?3	EQU	$;	IF	@INTL	LD	A,(IFLAG$)	BIT	6,A		;Special DMP PR?	ENDIF;	LD	A,C;	IF	@INTL	JR	Z,PVAL3	CP	0C0H		;Values C0-FF (-20H)	JR	C,PVAL2		;Go if less	SUB	20H		;Shift to European chars	JR	PVAL3PVAL2	CP	0A0H		;A0-BF (+40H)	JR	C,PVAL3		;Go if less	ADD	A,40H		;Shift to graphics	ENDIF;PVAL3	OUT	(PRPORT),A	;Put out char;	IF	@INTL	LD	A,C		;Restore original	CP	A		;Set Z	ENDIF;	RET;$?4	IN	A,(PRPORT)	;Scan PR status	AND	0F0H		;Mask unused portions	CP	30H		;PR ready?	RET			;Return with answerPREND	EQU	$-1