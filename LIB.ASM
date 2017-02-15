;***********************************
;描述：公共函数程序集
;函数申明
 ;_FUN_LIB_DELAY		---	延时函数1
;_FUN_LIB_DELAYSIMPLAY		---	延时函数2
;_FUN_LIB_LCD			---	延时函数3

;_FUN_LIB_DELAY50		---	延时50周期
;_FUN_LIB_DELAY49		---	延时49周期
;_FUN_LIB_DELAY48		---	延时48周期
;_FUN_LIB_DELAY47		---	延时47周期
;_FUN_LIB_DELAY46		---	延时46周期
;_FUN_LIB_DELAY45		---	延时45周期
;_FUN_LIB_DELAY44		---	延时44周期
;_FUN_LIB_DELAY43		---	延时43周期
;_FUN_LIB_DELAY42		---	延时42周期
;_FUN_LIB_DELAY41		---	延时41周期
;_FUN_LIB_DELAY40		---	延时40周期
;_FUN_LIB_DELAY39		---	延时39周期
;_FUN_LIB_DELAY38		---	延时38周期
;_FUN_LIB_DELAY37		---	延时37周期
;_FUN_LIB_DELAY36		---	延时36周期
;_FUN_LIB_DELAY35		---	延时35周期
;_FUN_LIB_DELAY34		---	延时34周期
;_FUN_LIB_DELAY33		---	延时33周期
;_FUN_LIB_DELAY32		---	延时32周期
;_FUN_LIB_DELAY31		---	延时31周期
;_FUN_LIB_DELAY30		---	延时30周期
;_FUN_LIB_DELAY29		---	延时29周期
;_FUN_LIB_DELAY28		---	延时28周期
;_FUN_LIB_DELAY27		---	延时27周期
;_FUN_LIB_DELAY26		---	延时26周期
;_FUN_LIB_DELAY25		---	延时25周期
;_FUN_LIB_DELAY24		---	延时24周期
;_FUN_LIB_DELAY23		---	延时23周期
;_FUN_LIB_DELAY22		---	延时22周期
;_FUN_LIB_DELAY21		---	延时21周期
;_FUN_LIB_DELAY20		---	延时20周期
;_FUN_LIB_DELAY19		---	延时19周期
;_FUN_LIB_DELAY18		---	延时18周期
;_FUN_LIB_DELAY17		---	延时17周期
;_FUN_LIB_DELAY16		---	延时16周期
;_FUN_LIB_DELAY15		---	延时15周期
;_FUN_LIB_DELAY14		---	延时14周期
;_FUN_LIB_DELAY13		---	延时13周期
;_FUN_LIB_DELAY12		---	延时12周期
;_FUN_LIB_DELAY11		---	延时11周期
;_FUN_LIB_DELAY10		---	延时10周期

;_getrsuadcrc			---	计算CRC
;_FUN_LIB_CompareTime		---	unix time时间计算
;_FUN_LIB_POWERDOWN		---	OBU进入掉电状态
;_FUN_LIB_GetBCC		---	获得BCC

;_FUN_LIB_XDATATODATA		---	复制数据从外存到内存
;_FUN_LIB_DATATOXDATA		---	复制数据从内存到外存
;_FUN_LIB_FLASHTODATA		---	复制数据从FLASH到内存(FALSH 数据定义需为 长度 + 数据)
;_FUN_LIB_FLASHTOXDATA		---	复制数据从FLASH到外存(FALSH 数据定义需为 长度 + 数据)
;***********************************
NAME	LIB

$INCLUDE(LIB.INC)
$INCLUDE(COMMON.INC)
	
	RSEG	?pr?LIB?Mater
	USING	0
	
_FUN_LIB_MASTER:
	MOV	R7,#9
	RET
;-------------------------
;随机延时
;内部参数
;A/B/R0
;R5/R6/R7
;r3 返回延时时间ms
;-------------------------
_FUN_LIB_RANDDELAY:	
	;RET
	CALL	_FUN_LIB_RAND
	CALL	_FUN_LIB_1MSDELAY
	
	RET
;-------------------------
;返回值 a(0~2)
;内部参数
;-------------------------
_FUN_LIB_RAND:
;	MOV	R0,#DATA_OBUID + 2
;	CLR	A
;	XRL	A,@R0
;	INC	R0
;	XRL	A,@R0
;	MOV	B,A	
	
	;--- 异或随机因子 ---
;	MOV	R0,#XDATA_RAND
;		;MOVX	A,@R0

;	XRL	A,B
	
	;---随机因子加1 ---
;	INC	A
;	anl	a,#3
	;--- 留下两位 ---			
;	CJNE	A,#3,$+3
;	JC	LIB_RAND_CK
;	CLR	A
	
LIB_RAND_CK:

;	MOV	R0,#XDATA_RAND
;		;MOVX	@R0,A

LIB_RAND_CK1:		
;	RET
	
	;随机因子01 	OBUID
	;随机因子02	内存 OBUMAIN_MASTER_MEMORYCLR
	;随机因子03	内存 DATA_RXBUF+12+
	;随机因子04	XDATA_RAND累加01
	

	mov 	dptr,#STR_SYS_OBUID+4
	movc 	a,@a+dptr
	anl 	a,#3
	
	mov 	dpl,#low OBUMAIN_MASTER_MEMORYCLR
	mov 	dph,#high OBUMAIN_MASTER_MEMORYCLR	
	add 	a,dph
	mov 	dph,a
	
	mov 	r0,#DATA_RXBUF+12+3
	mov 	a,@r0
	mov 	b,a
	
	mov 	r0,#XDATA_RAND
	;movx 	a,@r0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	inc 	a
	movx 	@r0,a

	dec 	a
	xrl 	a,b

;	mov 	b,a
;	mov 	r0,a
;	movx 	a,@r0
;	xrl 	a,b

	add 	a,dpl
	mov 	dpl,a
	movc 	a,@a+dptr
	anl 	a,#3
	
	ret
;---------------------------------------------------------------------------
;外部参数：
;A
;R7	---	要延时的调节参数,1个单位等于1ms 23576个周期
;内部参数
;R5
;R6
;---------------------------------------------------------------------------
_FUN_LIB_1MSDELAY:
	
	;CALL	_FUN_TEST_DISPLAY

;mov a,#3
LIB_1MSDELAY_1:
	CJNE	A,#0,LIB_1MSDELAY_3
	MOV	R7,#0
	JMP	LIB_1MSDELAY_SOver
	;JMP	LIB_1MSDELAY_OVER
LIB_1MSDELAY_3:
	CJNE	A,#1,LIB_1MSDELAY_6
	MOV	R7,#3
	JMP	LIB_1MSDELAY_SOver
LIB_1MSDELAY_6:
	CJNE	A,#2,LIB_1MSDELAY_7
	MOV	R7,#6
	JMP	LIB_1MSDELAY_SOver
LIB_1MSDELAY_7:
	;mov 	a,DATA_OBUID+3
	;anl 	a,#1
	
	mov 	dptr,#STR_SYS_OBUID+4
	movc 	a,@a+dptr		
	anl	a,#00000001b
	mov	b,a
	
	mov 	r0,#XDATA_RAND
	;movx 	a,@r0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	anl	a,#00000001b
	add	a,b
	
	jmp 	LIB_1MSDELAY_1
LIB_1MSDELAY_SOver:
	
	;~~~~~~~~~TETS~~~~~~~~~~~~~~~~
	;MOV	R7,#0
	;~~~~~~~~~~~~~~~~~~~~~~~~~
	MOV	A,R7
	mov	r3,a
	;~~~~~~~~~TETS~~~~~~~~~~~~~~~~
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~
	JZ	LIB_1MSDELAY_OVER
	
	;MOV	A,#14
	;CALL	_FUN_TEST_DISPLAY
_FUN_LIB_1MSDELAYC:
LIB_1MSDELAY_Loop:
	MOV	R5,#24
LIB_1MSDELAY_Loop1:
	MOV	R6,#255
LIB_1MSDELAY_Loop2:
	DJNZ	R6,LIB_1MSDELAY_Loop2
	DJNZ	R5,LIB_1MSDELAY_Loop1
	DJNZ	R7,LIB_1MSDELAY_Loop
	
LIB_1MSDELAY_OVER:
	
	RET
;---------------------------------------------------------------------------
;外部参数：
;R7	---	要延时的调节参数
;---------------------------------------------------------------------------
_FUN_LIB_DELAY:

	PUSH	AR6			;4
	PUSH	AR5
LIB_DELAY_LOOP:	
	MOV R6,#15
	MOV R5,#0FFH
LIB_DELAY_LOOP1:	
	;10
	NOP				;1
	NOP				;1
	NOP				;1
	NOP				;1
	NOP				;1
	
	NOP				;1
	NOP				;1
	NOP				;1
	NOP				;1
	NOP				;1
	DJNZ	R5,LIB_DELAY_LOOP1	;4
	DJNZ	R6,LIB_DELAY_LOOP1	;4
	DJNZ	R7,LIB_DELAY_LOOP	;4

	POP	AR5			;3
	POP	AR6			;3
	
	RET	
;-------------------------
;简单元延时函数
;外部参数：
;R7	---	要延时的调节参数
;-------------------------
_FUN_LIB_DELAYSIMPLAY:
	NOP	
	DJNZ	R7,_FUN_LIB_DELAYSIMPLAY
	RET

_FUN_LIB_LCD:
	DJNZ	R7,_FUN_LIB_LCD
	RET
	
;--------------------------------------------------------------------------
;延时      
;--------------------------------------------------------------------------
_FUN_LIB_DELAY2550:
	mov	r7,#78
	djnz	r7,$
	djnz	r7,$
	mov	r7,#254
	nop
	nop
	djnz	r7,$
_FUN_LIB_DELAY205:
	nop
	nop
	nop
	nop
	nop
_FUN_LIB_DELAY199:
	NOP
	NOP
	NOP
_FUN_LIB_DELAY197:
	
	MOV	R7,#1
	DJNZ	R7,$
_FUN_LIB_DELAY190:
	NOP
	MOV	R7,#15
	DJNZ	R7,$
_FUN_LIB_DELAY127:
	NOP
_FUN_LIB_DELAY126:
	NOP	
_FUN_LIB_DELAY125:
	NOP
_FUN_LIB_DELAY124:
	NOP
_FUN_LIB_DELAY123:
	NOP
_FUN_LIB_DELAY122:
	NOP
_FUN_LIB_DELAY121:
	NOP	
_FUN_LIB_DELAY120:
	NOP
_FUN_LIB_DELAY119:
	NOP
_FUN_LIB_DELAY118:
	NOP	
_FUN_LIB_DELAY117:
	NOP
_FUN_LIB_DELAY116:
	NOP
_FUN_LIB_DELAY115:
	NOP
_FUN_LIB_DELAY114:
	NOP	
_FUN_LIB_DELAY113:
	NOP
_FUN_LIB_DELAY112:
	NOP
_FUN_LIB_DELAY111:
	NOP	
_FUN_LIB_DELAY110:
	NOP
_FUN_LIB_DELAY109:
	NOP
_FUN_LIB_DELAY108:
	NOP	
_FUN_LIB_DELAY107:
	NOP
	NOP
	NOP
	MOV	R7,#9
	DJNZ	R7,$
_FUN_LIB_DELAY66:
	NOP
_FUN_LIB_DELAY65:
	NOP
_FUN_LIB_DELAY64:
	NOP
_FUN_LIB_DELAY63:
	NOP
_FUN_LIB_DELAY62:
	NOP
_FUN_LIB_DELAY61:
	NOP
_FUN_LIB_DELAY60:
	NOP	
_FUN_LIB_DELAY59:
	NOP
_FUN_LIB_DELAY58:
	NOP
_FUN_LIB_DELAY57:
	NOP
_FUN_LIB_DELAY56:
	NOP
_FUN_LIB_DELAY55:
	NOP
_FUN_LIB_DELAY54:
	NOP
_FUN_LIB_DELAY53:
	NOP
_FUN_LIB_DELAY52:
	NOP
_FUN_LIB_DELAY51:
	NOP
_FUN_LIB_DELAY50:
	NOP
_FUN_LIB_DELAY49:
	NOP
_FUN_LIB_DELAY48:
	NOP
_FUN_LIB_DELAY47:
	NOP
_FUN_LIB_DELAY46:
	NOP
_FUN_LIB_DELAY45:
	NOP
_FUN_LIB_DELAY44:
	NOP
_FUN_LIB_DELAY43:
	NOP
_FUN_LIB_DELAY42:
	NOP
_FUN_LIB_DELAY41:
	NOP
_FUN_LIB_DELAY40:
	NOP
_FUN_LIB_DELAY39:
	NOP
_FUN_LIB_DELAY38:
	NOP
_FUN_LIB_DELAY37:
	NOP
_FUN_LIB_DELAY36:
	NOP
_FUN_LIB_DELAY35:
	NOP
_FUN_LIB_DELAY34:
	NOP
_FUN_LIB_DELAY33:
	NOP
_FUN_LIB_DELAY32:
	NOP
_FUN_LIB_DELAY31:
	NOP
_FUN_LIB_DELAY30:
	NOP
_FUN_LIB_DELAY29:
	NOP
_FUN_LIB_DELAY28:
	NOP
_FUN_LIB_DELAY27:
	NOP
_FUN_LIB_DELAY26:
	NOP
_FUN_LIB_DELAY25:
	NOP
_FUN_LIB_DELAY24:
	NOP
_FUN_LIB_DELAY23:
	NOP
_FUN_LIB_DELAY22:
	NOP
_FUN_LIB_DELAY21:
	NOP
_FUN_LIB_DELAY20:
	NOP
_FUN_LIB_DELAY19:
	NOP
_FUN_LIB_DELAY18:
	NOP
_FUN_LIB_DELAY17:
	NOP
_FUN_LIB_DELAY16:
	NOP
_FUN_LIB_DELAY15:
	NOP
_FUN_LIB_DELAY14:
	NOP
_FUN_LIB_DELAY13:
	NOP
_FUN_LIB_DELAY12:
	NOP
_FUN_LIB_DELAY11:
	NOP
_FUN_LIB_DELAY10:
	RET
;---------------------------------------------------------------------------
;计算CRC
;外部参数：
;BIT_BUFADDR	---	表示当前操作的存储区,=0内存;=1外存
;R5		---	BUF长度
;R7		---	BUF指针
;内部参数:
;R6
;返回值:
;	R7[R5]		---	CRC1
;	R7[R5+1]	---	CRC2
;---------------------------------------------------------------------------
;///////////////////////////////////////////////////////////////////////////////////////////////////   
_getnewcrc:
	
        mov a,r7
        mov r0,a
        mov a,r5
        mov r2,a
	mov r6,#0FFh		;000h
	mov r7,#0FFh		;000h
;	mov r6,#000h		;000h
;	mov r7,#000h		;000h
_getnewcrcbyte:
	mov DPTR,#crctb		;3
	mov a,r7		;1	
	xrl a,@r0		;3	4
	clr c			;1	5
	rlc a			;1	6
	jnc _getnewcrcbyte1	;3	9
	inc 83h			;4	13
_getnewcrcbyte1:
	mov r4,a		;2	15
	inc a			;2
	movc a,@a+dptr		;4	19
	xrl a,r6		;3	22
	mov r7,a		;2	24
	mov a,r4		;1	25
	movc a,@a+dptr		;4	31
	mov r6,a		;2	33
	inc r0			;4	37
        djnz r2,_getnewcrcbyte	;4	41+3=44
        mov a,r7
        cpl a
	mov @r0,a
        inc r0
        mov a,r6
        cpl a
	mov @r0,a
        ret

_getnewcrc_xr:
        mov a,r7
        mov r0,a
        mov a,r5
        mov r2,a
	mov r6,#0FFh		;000h
	mov r7,#0FFh		;000h
;	mov r6,#000h		;000h
;	mov r7,#000h		;000h
_getnewcrcbyte_xr:
	mov DPTR,#crctb		;3
;	mov a,r7		;1	
;	xrl a,@r0		;3	4


	;MOVX	A,@R0
	push	dph
	push	dpl
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	pop	dpl
	pop	dph	
	xrl a,r7

	clr c			;1	5
	rlc a			;1	6
	jnc _getnewcrcbyte_xr1	;3	9
	inc 83h			;4	13
_getnewcrcbyte_xr1:
	mov r4,a		;2	15
	inc a			;2
	movc a,@a+dptr		;4	19
	xrl a,r6		;3	22
	mov r7,a		;2	24
	mov a,r4		;1	25
	movc a,@a+dptr		;4	31
	mov r6,a		;2	33
	inc r0			;4	37
        djnz r2,_getnewcrcbyte_xr	;4	41+3=44
        mov a,r7
        cpl a
	;movx	@r0,a
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
        inc 	r0
        mov 	a,r6
        cpl 	a
	movx	@r0,a
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
        RET
        
crctb:
	DB 0x00,0x00, 0x11,0x89, 0x23,0x12, 0x32,0x9b, 0x46,0x24, 0x57,0xad, 0x65,0x36, 0x74,0xbf
	DB 0x8c,0x48, 0x9d,0xc1, 0xaf,0x5a, 0xbe,0xd3, 0xca,0x6c, 0xdb,0xe5, 0xe9,0x7e, 0xf8,0xf7
	DB 0x10,0x81, 0x01,0x08, 0x33,0x93, 0x22,0x1a, 0x56,0xa5, 0x47,0x2c, 0x75,0xb7, 0x64,0x3e
	DB 0x9c,0xc9, 0x8d,0x40, 0xbf,0xdb, 0xae,0x52, 0xda,0xed, 0xcb,0x64, 0xf9,0xff, 0xe8,0x76
	DB 0x21,0x02, 0x30,0x8b, 0x02,0x10, 0x13,0x99, 0x67,0x26, 0x76,0xaf, 0x44,0x34, 0x55,0xbd
	DB 0xad,0x4a, 0xbc,0xc3, 0x8e,0x58, 0x9f,0xd1, 0xeb,0x6e, 0xfa,0xe7, 0xc8,0x7c, 0xd9,0xf5
	DB 0x31,0x83, 0x20,0x0a, 0x12,0x91, 0x03,0x18, 0x77,0xa7, 0x66,0x2e, 0x54,0xb5, 0x45,0x3c
	DB 0xbd,0xcb, 0xac,0x42, 0x9e,0xd9, 0x8f,0x50, 0xfb,0xef, 0xea,0x66, 0xd8,0xfd, 0xc9,0x74
	DB 0x42,0x04, 0x53,0x8d, 0x61,0x16, 0x70,0x9f, 0x04,0x20, 0x15,0xa9, 0x27,0x32, 0x36,0xbb
	DB 0xce,0x4c, 0xdf,0xc5, 0xed,0x5e, 0xfc,0xd7, 0x88,0x68, 0x99,0xe1, 0xab,0x7a, 0xba,0xf3
	DB 0x52,0x85, 0x43,0x0c, 0x71,0x97, 0x60,0x1e, 0x14,0xa1, 0x05,0x28, 0x37,0xb3, 0x26,0x3a
	DB 0xde,0xcd, 0xcf,0x44, 0xfd,0xdf, 0xec,0x56, 0x98,0xe9, 0x89,0x60, 0xbb,0xfb, 0xaa,0x72
	DB 0x63,0x06, 0x72,0x8f, 0x40,0x14, 0x51,0x9d, 0x25,0x22, 0x34,0xab, 0x06,0x30, 0x17,0xb9
	DB 0xef,0x4e, 0xfe,0xc7, 0xcc,0x5c, 0xdd,0xd5, 0xa9,0x6a, 0xb8,0xe3, 0x8a,0x78, 0x9b,0xf1
	DB 0x73,0x87, 0x62,0x0e, 0x50,0x95, 0x41,0x1c, 0x35,0xa3, 0x24,0x2a, 0x16,0xb1, 0x07,0x38
	DB 0xff,0xcf, 0xee,0x46, 0xdc,0xdd, 0xcd,0x54, 0xb9,0xeb, 0xa8,0x62, 0x9a,0xf9, 0x8b,0x70
	DB 0x84,0x08, 0x95,0x81, 0xa7,0x1a, 0xb6,0x93, 0xc2,0x2c, 0xd3,0xa5, 0xe1,0x3e, 0xf0,0xb7
	DB 0x08,0x40, 0x19,0xc9, 0x2b,0x52, 0x3a,0xdb, 0x4e,0x64, 0x5f,0xed, 0x6d,0x76, 0x7c,0xff
	DB 0x94,0x89, 0x85,0x00, 0xb7,0x9b, 0xa6,0x12, 0xd2,0xad, 0xc3,0x24, 0xf1,0xbf, 0xe0,0x36
	DB 0x18,0xc1, 0x09,0x48, 0x3b,0xd3, 0x2a,0x5a, 0x5e,0xe5, 0x4f,0x6c, 0x7d,0xf7, 0x6c,0x7e
	DB 0xa5,0x0a, 0xb4,0x83, 0x86,0x18, 0x97,0x91, 0xe3,0x2e, 0xf2,0xa7, 0xc0,0x3c, 0xd1,0xb5
	DB 0x29,0x42, 0x38,0xcb, 0x0a,0x50, 0x1b,0xd9, 0x6f,0x66, 0x7e,0xef, 0x4c,0x74, 0x5d,0xfd
	DB 0xb5,0x8b, 0xa4,0x02, 0x96,0x99, 0x87,0x10, 0xf3,0xaf, 0xe2,0x26, 0xd0,0xbd, 0xc1,0x34
	DB 0x39,0xc3, 0x28,0x4a, 0x1a,0xd1, 0x0b,0x58, 0x7f,0xe7, 0x6e,0x6e, 0x5c,0xf5, 0x4d,0x7c
	DB 0xc6,0x0c, 0xd7,0x85, 0xe5,0x1e, 0xf4,0x97, 0x80,0x28, 0x91,0xa1, 0xa3,0x3a, 0xb2,0xb3
	DB 0x4a,0x44, 0x5b,0xcd, 0x69,0x56, 0x78,0xdf, 0x0c,0x60, 0x1d,0xe9, 0x2f,0x72, 0x3e,0xfb
	DB 0xd6,0x8d, 0xc7,0x04, 0xf5,0x9f, 0xe4,0x16, 0x90,0xa9, 0x81,0x20, 0xb3,0xbb, 0xa2,0x32
	DB 0x5a,0xc5, 0x4b,0x4c, 0x79,0xd7, 0x68,0x5e, 0x1c,0xe1, 0x0d,0x68, 0x3f,0xf3, 0x2e,0x7a
	DB 0xe7,0x0e, 0xf6,0x87, 0xc4,0x1c, 0xd5,0x95, 0xa1,0x2a, 0xb0,0xa3, 0x82,0x38, 0x93,0xb1
	DB 0x6b,0x46, 0x7a,0xcf, 0x48,0x54, 0x59,0xdd, 0x2d,0x62, 0x3c,0xeb, 0x0e,0x70, 0x1f,0xf9
	DB 0xf7,0x8f, 0xe6,0x06, 0xd4,0x9d, 0xc5,0x14, 0xb1,0xab, 0xa0,0x22, 0x92,0xb9, 0x83,0x30
	DB 0x7b,0xc7, 0x6a,0x4e, 0x58,0xd5, 0x49,0x5c, 0x3d,0xe3, 0x2c,0x6a, 0x1e,0xf1, 0x0f,0x78
	
;/////////////////////////////////////////////////////////////////////////////////////////////////
	
;---------------------------------------------------------------------------
;描述:复制数据从内存到外存
;外部参数：
;R7		---	外存BUF指针
;R5		---	内存BUF指针长度
;R3		---	将要COPY的长度
;---------------------------------------------------------------------------
_FUN_LIB_DATATOXDATA:
	MOV	AR2,AR3
	MOV	AR0,AR7
	MOV	AR1,AR5
LIB_DATATOXDATA_LOOP:
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	INC	R1
	DJNZ	R2,LIB_DATATOXDATA_LOOP
	RET	
;---------------------------------------------------------------------------
;描述:复制数据从外存到外存	
;外部参数：
;R7		---	目标
;R5		---	源
;R3		---	将要COPY的长度
;---------------------------------------------------------------------------
	
;---------------------------------------------------------------------------
;描述:复制数据从外存到内存
;外部参数：
;R7		---	Soure
;R5		---	direct
;R3		---	将要COPY的长度
;---------------------------------------------------------------------------
_FUN_LIB_XDATATODATA:
	MOV	AR2,AR3
	MOV	AR0,AR7
	MOV	AR1,AR5
LIB_XDATATODATA_LOOP:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	@R1,A
	INC	R0
	INC	R1
	DJNZ	R2,LIB_XDATATODATA_LOOP
	RET
;---------------------------------------------------------------------------
;描述:复制数据从外存到外存
;外部参数：
;R7		---	Soure
;R5		---	direct
;R3		---	将要COPY的长度
;---------------------------------------------------------------------------
_FUN_LIB_XDATATOXDATA:
	MOV	AR2,AR3
	MOV	AR0,AR7
	MOV	AR1,AR5
LIB_XDATATOXDATA_LOOP:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	INC	R0
	INC	R1
	DJNZ	R2,LIB_XDATATOXDATA_LOOP
	RET	
;---------------------------------------------------------------------------
;描述:复制数据从FLASH到内存(FALSH 数据定义需为 长度 + 数据)
;外部参数：
;R7		---	内存BUF指针
;DPTR		---	flash地址
;内部参数：
;R2
;R1
;返回值
;R3		---	长度
;-----------------------------------------------------------------------
_FUN_LIB_FLASHTODATA:
	
	MOV	AR0,AR7
	MOV	A,#0
	MOVC	A,@A + DPTR
	MOV	R2,A
	MOV	R3,A
	
	MOV	R1,#1
LIB_FLASHTODATA_Loop:
	MOV	A,R1
	MOVC	A,@A + DPTR
	MOV	@R0,A
	INC	R1
	INC	R0
	DJNZ	R2,LIB_FLASHTODATA_Loop
	
	RET
;---------------------------------------------------------------------------
;描述:复制数据从FLASH到内存(FALSH 数据定义需为 长度 + 数据)
;外部参数：
;R7		---	内存BUF指针
;DPTR		---	flash地址
;R3		---	长度
;内部参数：
;R2
;R1
;返回值

;-----------------------------------------------------------------------
_FUN_LIB_FLASHTODATAEX:
	
	MOV	AR0,AR7
	;MOV	A,R3
	;MOV	R2,A
	;MOV	A,#0
	;MOVC	A,@A + DPTR
	;MOV	R2,A
	;MOV	R3,A
	
	MOV	R1,#1
LIB_FLASHTODATAEX_Loop:	
	MOV	A,R1
	MOVC	A,@A + DPTR
	MOV	@R0,A
	INC	R1
	INC	R0
	
	DJNZ	R3,LIB_FLASHTODATAEX_Loop
	
	RET
;---------------------------------------------------------------------------
;描述:复制数据从FLASH到外存(FALSH 数据定义需为 长度 + 数据)
;外部参数：
;R7		---	外存BUF指针
;DPTR		---	flash地址
;内部参数：
;R2
;R1
;返回值
;R3		---	长度
;---------------------------------------------------------------------------
_FUN_LIB_FLASHTOXDATA:
	
	MOV	AR0,AR7
	MOV	A,#0
	MOVC	A,@A + DPTR
	MOV	R2,A
	MOV	R3,A
	
	MOV	R1,#1
LIB_FLASHTOXDATA_Loop:
	MOV	A,R1
	MOVC	A,@A + DPTR
		;MOVX	@R0,A
	push	dph
	push	dpl
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph
	
	INC	R1
	INC	R0
	DJNZ	R2,LIB_FLASHTOXDATA_Loop
	
	RET
;---------------------------------------------------------------------------
;描述:复制数据从FLASH到外存(FALSH 数据定义需为 长度 + 数据)
;外部参数：
;R7		---	外存BUF指针
;DPTR		---	flash地址
;R3		---	长度
;内部参数：
;R2
;R1
;返回值
;---------------------------------------------------------------------------
_FUN_LIB_FLASHTOXDATALen:	
	MOV	R1,#0
LIB_FLASHTOXDATALen_Loop:
	MOV	A,R1
	MOVC	A,@A + DPTR
		;MOVX	@R0,A
	push	dph
	push	dpl
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph

	INC	R1
	INC	R0
	DJNZ	R3,LIB_FLASHTOXDATALen_Loop
	
	RET
;///////////////////////////////////////////////////////////////
;---------------------------------------------------------------
;响铃指令
;---------------------------------------------------------------
        
_FUN_LIB_BEEP:
	;---clr Pin_MCU_RC500RST
;        cpl bp
	setb	PIN_BELL_01
	clr	PIN_BELL_02
_onbp1:
;        mov r5,#0;255;71
        mov r6,#7
_onbp2:
;        djnz r5,$
	MOV	R5,#20
	 djnz 	r5,$
        djnz r5,$
        djnz r5,$
	djnz r5,$
	cpl	PIN_BELL_01
        cpl	PIN_BELL_02
;        mov r5,#0;255;73 ;;60-70
        djnz r6,_onbp2
        djnz r7,_onbp1
	setb Pin_red
	;+++ setb Pin_gre        
        ret	
                
        
        
;---------------------------------------------------------------
_DELAY:
	push acc 	;4
	mov a,r6	;2
	push acc	;4
_DELAY3:
	MOV A,#28;4	;2
_DELAY1:
        MOV R6,#255	;2	;XTAL/12*128
_DELAY2:
        DJNZ R6,_DELAY2
	DJNZ ACC,_DELAY1
        DJNZ R7,_DELAY3
        
        POP acc
	mov r6,a
	pop acc
        RET
;---------------------------------------------------------------
;Unix_Time 时间差计算(r5-r7-r3的时间，是否大于0)
;外部参数:
;	R7	---	小时间 高字节,外存
;	R5	---	大时间 高字节,内存
;	R3	---	X秒
;返回值:
;	C	= 0 大时间与小时间的差，大于或等于X秒，= 1 表示小于X秒
;---------------------------------------------------------------
_FUN_LIB_CompareTime:
	
	;将时间存放到HOLD
	MOV	AR1,AR7
	MOV	R0,#XDATA_HOLD
	
	;PUSH	AR0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	INC	R1
	INC	R0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1
	INC	R0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1
	INC	R0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;POP	AR0	
	;JMP	LIB_CompareTime_OVER	
	
	;--- 用大时间-小时间,并将新时间放到小时间绶冲 ---
	INC	R5
	INC	R5
	INC	R5	;移大时间到最低位
	
	MOV	AR1,AR5
	MOV	AR2,AR3	
	
	PUSH	AR0
	CLR	C
	MOV	R3,#4
LIB_CompareTime_LOOP:

;		;MOVX	A,@R0

;	XCH	A,@R1
;	SUBB	A,@R1

		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
	MOV	A,@R1	
	SUBB	A,B



		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
	DEC	R1
	DJNZ	R3,LIB_CompareTime_LOOP
	POP	AR0	

	
	;当小时间>大时间时，表示小时间不正确，返回C=0，以便通行
	JNC	LIB_CompareTime_SecDif
	
	;---CLR	C
	;---JMP	LIB_CompareTime_OVER
	jmp	LIB_CompareTime_Tow
LIB_CompareTime_SecDif:
	
	;--- 用时间差，再减秒数差 ---	
	CLR	C
	;MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	SUBB	A,R2
	
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	SUBB	A,#0
	
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	SUBB	A,#0
	
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	SUBB	A,#0	
	
LIB_CompareTime_OVER:		

	RET
	
;---------------------------------------------------------------
; 
;外部参数:
;	R7	---	大时间 高字节,外存
;	R5	---	小时间 高字节,内存
;	R3	---	X秒
;返回值:
;	C	= 0 大时间与小时间的差，大于或等于X秒，= 1 表示小于X秒
;---------------------------------------------------------------
LIB_CompareTime_Tow:	
	
	; 将时间存放到HOLD 
;	dec	r5
;	dec	r5
;	dec	r5
	
;	MOV	AR1,aR5
;	MOV	R0,#XDATA_HOLD
	
	;PUSH	AR0
;	MOV	A,@R1
;		;MOVX	@R0,A

	
;	INC	R1
;	INC	R0
;	MOV	A,@R1
;		;MOVX	@R0,A

;	
;	INC	R1
;	INC	R0
;	MOV	A,@R1
;		;MOVX	@R0,A

	
;	INC	R1
;	INC	R0
;	MOV	A,@R1
;		;MOVX	@R0,A

	
 
;	MOV	AR1,ar7
;	PUSH	AR0
;	CLR	C
;	MOV	R3,#4
;CompareTime_Tow_LOOP: 

;		;MOVX	A,@R0

;	MOV	B,A
;		;MOVX	A,@R1

;	SUBB	A,B


;		;MOVX	@R0,A

;;	DEC	R0
;	DEC	R1
;	DJNZ	R3,CompareTime_Tow_LOOP
;	POP	AR0		
	
	
	MOV	AR1,AR7
	MOV	R0,#XDATA_HOLD
	
	;PUSH	AR0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	INC	R1
	INC	R0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1
	INC	R0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1
	INC	R0
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;POP	AR0	
	;JMP	LIB_CompareTime_OVER	
	
	;--- 用大时间-小时间,并将新时间放到小时间绶冲 ---
	;INC	R5
	;INC	R5
	;INC	R5	;移大时间到最低位
	;dec	r5
	;dec	r5	
	;dec	r5	
	
	MOV	AR1,AR5
	;MOV	AR2,AR3	
	
	PUSH	AR0
	CLR	C
	MOV	R3,#4
LIB_CompareTime02_LOOP:
	
;		;MOVX	A,@R0

;	MOV	B,A
;	MOV	A,@R1	
;	SUBB	A,B


	;MOV	B,A
	MOV	A,@R1
	mov	b,a
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	SUBB	A,B


	
	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
	DEC	R1
	DJNZ	R3,LIB_CompareTime02_LOOP
	POP	AR0		
	
	jmp	LIB_CompareTime_SecDif
;---------------------------------------------------------------
;OBU进入掉电状态	
;外部参数:
;返回值:
;---------------------------------------------------------------
;_FUN_LIB_POWERDOWN:
;	SETB	PIN_RED
	
;	CLR	Pin_522_RST
;	CLR	Pin_LCD_RST
	
	;SETB	PD
;	ANL	PCON,#0FDH	;XXXX XX0X Power Down
;LIB_POWERDOWN_OVER:
;	JMP	LIB_POWERDOWN_OVER
	
;	RET
;--------------------------------------------------------------------------
;描述:获得BCC	
;外部参数
;	BIT_BUFADDR		;= 0，数据在内存； = 1，数据在外存
;	R7			---	接收指针
;	R3			---	长度
;	
;返回值
;	R6
;--------------------------------------------------------------------------	
_FUN_LIB_GetBCC:
	
	MOV	AR0,AR7
	MOV	R6,#0
	
LIB_GetBCC_LOOP:
	JB	BIT_BUFADDR,LIB_GetBCC_MOVX
LIB_GetBCC_MOV:
	MOV	A,@R0
	JMP	LIB_GetBCC_SetOver
LIB_GetBCC_MOVX:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
LIB_GetBCC_SetOver:
	
	XRL	A,R6
	MOV	R6,A
	
	INC	R0
	
	DJNZ	R3,LIB_GetBCC_LOOP
	
	RET
;--------------------------------------------------------------------------
;描述:读取电量使用次数 
;外部参数

;	R7			---	内存接收指针
;	DPTR			---	存放数据的地方

;返回值
;	R7(Old)			---	完整结果
;--------------------------------------------------------------------------	
_FUN_LIB_PowerPer:
	
	MOV	DPH,#CONST_FALSH_PowerH
	MOV	DPL,#CONST_FALSH_PowerL
	;MOV	AR7,#XDATA_TXBUF
	;MOV	R7,#XDATA_Power
	MOV	R3,#3
	CALL	_RDFlashXR	
	
	RET
;--------------------------------------------------------------------------
;描述:电量使用次数加1 
;外部参数

;	R7			---	内存接收指针
;	DPTR			---	存放数据的地方

;返回值
;	R7(Old)	
;--------------------------------------------------------------------------	
_FUN_LIB_PowerADD:
	
	MOV	AR0,AR7
	;Load DPTR Value To DataBuf
	CLR	C
	
	;ADD_01
	INC	R0			;[1]
	INC	R0			;[2]
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
	MOV	A,#1
	ADDC	A,B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	DEC	R0			;[1]
	;MOV	B,@R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A	
	MOV	A,#0
	ADDC	A,B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;SUBB - 1000(3E8)
	CLR	C
	INC	R0			;[2]
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,#0E8H;2;0E8H
	SUBB	A,B
	
	DEC	R0			;[1]
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,#3;0;3
	SUBB	A,B
	
	JC	LIB_PowerADD_OVER	;<1000 JMP
	
	;When >= 1000			,Per add 1
	DEC	R0	;[0]
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	INC	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;When >= 1000,CLR 1000
	CLR	A
	INC	R0	;[1]
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0	;[2]
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
LIB_PowerADD_OVER:	
	
	RET	
	
_FUN_LIB_ESAMErr:
	MOV	R7,#100
	CALL	_FUN_LIB_BEEP
	MOV	R7,#100
	CALL	_FUN_LIB_BEEP
	MOV	R7,#100
	CALL	_FUN_LIB_BEEP
	MOV	R7,#100
	CALL	_FUN_LIB_BEEP
	MOV	R7,#100
	CALL	_FUN_LIB_BEEP
	MOV	R7,#100
	CALL	_FUN_LIB_BEEP

	MOV	R7,#DATA_RXBUF + 90
	MOV	DPTR,#STR_ErresamCARD
	CALL	_FUN_LCD_DisplayExChina

LIB_ESAMErr_Over:
	JMP	LIB_ESAMErr_Over
	
	RET	   
	                           
	END

