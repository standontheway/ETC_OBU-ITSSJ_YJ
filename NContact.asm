;**********************************************************************
;描述：非接触卡程序集
;函数申明
;_FUN_NContact_Rc500Rst		---	非接触卡芯片复位
;_FUN_NContact_spio		---	
;_FUN_NContact_Rc500Config	---	非接触卡复位
;_FUN_NContact_Rc500Request	---	请求
;_FUN_NContact_Rc500Anticoll	---	防碰撞
;_FUN_NContact_Rc500Select	---	选卡
;**********************************************************************
NAME	NContact

$INCLUDE(NContact.INC)
$INCLUDE(COMMON.INC)

	RSEG	?pr?NContact?Mater
	USING	0

_FUN_NContact_Mater:
	MOV	A,#0	
	RET	
;--------------------------------------------------------------------------
;描述:	非接触卡芯片复位
;外部参数
;	Pin_MCU_RC500RST	---	非接触复位引脚
;	Pin_SS			---	
;	REG_5412AD_spctl	---	
;内部参数:
;	XXX
;返回值
;	XXX
;--------------------------------------------------------------------------	
_FUN_NContact_Rc500Rst:	
	MOV	REG_5412AD_spctl,#0dch	;0dfh
	CLR	A
	MOV	REG_5412AD_spctl,A		
	SETB	Pin_522_SS
	
	SETB	PIN_522_SCLK
	SETB	PIN_522_MOSI
	SETB	PIN_522_MISO
	
	SETB	Pin_522_RST	
	MOV	R7,#1;02
	CALL	_FUN_LIB_DELAY	
	CLR	Pin_522_RST		
	MOV	R7,#1;02
	CALL	_FUN_LIB_DELAY	
	SETB	Pin_522_RST
	
	MOV	R7,#2
	CALL	_DELAY	
;	SETB	Pin_522_SS	
	mov	a,#REG_RC522_CommandReg
	rl	a
	mov	r7,#0fh						;3dh;3fh;6363
	CALL	_FUN_NContact_spio
	MOV	R7,#1
	CALL	_DELAY	
	RET	
	
;--------------------------------------------------------------------------
;描述:	xxx
;外部参数
;	Pin_ss			---	???
;	A			---	地址
;	R7			---	数据
;内部参数:
;	xxx
;返回值
;	xxx
;--------------------------------------------------------------------------	
_FUN_NContact_spio:
	
	JMP	_FUN_NContact_spioSoft

	clr	Pin_522_SS
	nop
	nop
	;写地址
	mov	REG_5412AD_spdat,A
	
	;查看是否写成功，没写成功，就等待，直到写成功
	mov	A,REG_5412AD_spstat
	jnb	ACC.7,$-2
	
	;清空SPI状态寄存器
	mov	REG_5412AD_spstat,#0c0h	;1100 0000
	;写数据
	mov	REG_5412AD_spdat,R7
	
	;查看是否写成功，没写成功，就等待，直到写成功	
	mov	A,REG_5412AD_spstat
	jnb	ACC.7,$-2
	
	;清空SPI状态寄存器
	mov	REG_5412AD_spstat,#0c0h
	
	setb	Pin_522_SS
	
	ret
;--------------------------------------------------------------------------
;描述:	软SPI写读数据函数
;外部参数
;	Pin_ss			---	???
;	A			---	地址
;	R7			---	数据
;内部参数:
;	xxx
;返回值
;	xxx
;--------------------------------------------------------------------------	
_FUN_NContact_spioSoft:
	
	PUSH	AR3
	
	CLR	Pin_522_SS
	NOP
	NOP
	
	;写地址
	MOV	R3,#8
NContact_spioSoft_WriteAddrLOOP:
	CLR	PIN_522_SCLK				;4	
	RLC	A					;1
	MOV	PIN_522_MOSI,C				;4	
	SETB	PIN_522_SCLK				;4	
	NOP
	DJNZ	R3,NContact_spioSoft_WriteAddrLOOP	;4
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	;写读数据
	MOV	A,R7
	MOV	R3,#8
NContact_spioSoft_WriteDALOOP:
	CLR	PIN_522_SCLK				;4
	RLC	A					;1
	MOV	PIN_522_MOSI,C				;4
	NOP
	NOP	
	SETB	PIN_522_SCLK				;4
	MOV	C,PIN_522_MISO				;3
	DJNZ	R3,NContact_spioSoft_WriteDALOOP	;4
	RLC	A					;1
	;MOV	REG_5412AD_spdat,A	
	MOV	B,A	
	
	SETB	Pin_522_SS		
	POP	AR3
	
	RET
	
;-------------------------------------------------
_FUN_NContact_Rc500_PPS_Config:
	mov	a,#REG_RC522_TxModeReg
	rl	a
	mov	r7,#0a0h
	call	_FUN_NContact_spio

	MOV	a,#REG_RC522_RxModeReg
	RL	a
	MOV	r7,#0a0h
	CALL	_FUN_NContact_spio	
	

	MOV	a,#REG_RC522_ModWidthReg	;新增mytest_gl 调制宽度(4倍频)
	RL	a
	MOV	r7,#009h	
	CALL	_FUN_NContact_spio	

;MOV	a,#REG_RC522_RFCfgReg		;新增mytest_gl 接收增益
;	RL	a
;	MOV	r7,#07fh
;	CALL	_FUN_NContact_spio	

;MOV	a,#REG_RC522_RxThresholdReg	;新增mytest_gl 位解码阈值
;	RL	a
;	MOV	r7,#050h
;	CALL	_FUN_NContact_spio		
	;MOV	R7,#02;02
	;CALL	_FUN_LIB_DELAY	
	
	MOV	R7,#0
	RET
	
;--------------------------------------------------------------------------
;描述:	非接触卡复位
;外部参数
;	ModeReg
;	TxAutoReg
;	TModeReg
;	TPrescalerReg
;	TReloadRegL
;	TReloadRegH
;	BitFramingReg
;	TxControlReg
;内部参数:
;	xxx
;返回值
;	xxx
;--------------------------------------------------------------------------	
_FUN_NContact_Rc500Config:
	
	;3d=0011 1101
	;bit.6~7	RFU
	;bit.5		?
	;bit.4		RFU
	;bit.3		Sigin高电平有效	
	;bit.2=1 	RFU
	;BIT.0~1 	CRC 初值
	mov	a,#REG_RC522_ModeReg;11
	rl	a
	;setb	acc.7
	mov	r7,#3dh						;3dh;3fh;6363
	CALL	_FUN_NContact_spio
	
	mov	a,#REG_RC522_TxAutoReg;15			;15h;必需有
	rl	a
	mov	r7,#40h
	call	_FUN_NContact_spio
	
	mov	a,#REG_RC522_TModeReg	;2a
	;2a	
	rl	a
	mov	r7,#8dh;82h;8dh
	call	_FUN_NContact_spio
	
	mov	a,#REG_RC522_TPrescalerReg;2bh
	rl	a
	mov	r7,#01;0a6h;01h
	call	_FUN_NContact_spio
	
	mov 	a,#REG_RC522_TReloadRegL;2dh
	rl 	a
	mov 	r7,#150;0b8h;150				;30;8;30;75;#155;30 1eh
	call 	_FUN_NContact_spio
	
	mov 	a,#REG_RC522_TReloadRegH;2ch
	rl 	a
	mov 	r7,#01;0bh;01h				;00h
	call 	_FUN_NContact_spio
	
	mov 	a,#REG_RC522_BitFramingReg;0dh
	rl 	a
	mov 	r7,#07h
	call 	_FUN_NContact_spio
	
	mov 	a,#REG_RC522_TxControlReg;14h
	rl 	a
	mov 	r7,#81h
	call 	_FUN_NContact_spio

	MOV	R7,#5
	;---MOV	R7,#20
	CALL	_DELAY
	
	RET
;--------------------------------------------------------------------------
;描述:	请求卡片
;外部参数
;	DATA_RXBUF
;	FIFODataReg			---	???
;	ComIrqReg
;	CommandReg
;	BitFramingReg
;	BitFramingReg
;	ComIrqReg
;	ErrorReg
;	FIFOLevelReg
;	FIFODataReg
;	ControlReg
;	FIFOLevelReg
;	CommandReg
;	spdat
;	spstat
;	irqEn
;	SS
;	MCU_RC500RST
;	cpu_pro
;	xdata_flag
;内部参数:
;	xxx
;返回值
;	xxx
;--------------------------------------------------------------------------
_FUN_NContact_Rc500Request:
	mov	a,#REG_RC522_FIFODataReg;09h
	rl	a
	mov	r7,#52h;26h
	call	_FUN_NContact_spio
	
	;---mov	irqEn,#23h
	;PUSH	AR0
	MOV	A,#23H
	MOV	R0,#DATA_irqEn
	MOV	@R0,A
	;POP	AR0
	;mov	r6,#55h
	CLR	BIT_BUFADDR
	CLR	BIT_ProMF		
	mov	r5,#DATA_RXBUF
	
	mov	r7,#0ch
	;mov	A,#REG_RC522_CommandReg;01H
 	;rl	A
	;call	_FUN_NContact_spio	
	push	ar7
	mov	a,#REG_RC522_ComIrqReg;04H
	rl	a
	mov	r7,#7FH
	call	_FUN_NContact_spio
	pop	ar7
	
	mov	A,#REG_RC522_CommandReg;01H
 	rl	A
	call	_FUN_NContact_spio
	
	MOV	A,#REG_RC522_BitFramingReg;0d		;必需有
	RL	A
	SETB	acc.7
	MOV	r7,#00h
	CALL	_FUN_NContact_spio
	
	setb	acc.7
	mov	r7,a
	mov	a,#REG_RC522_BitFramingReg;0d
	rl	a
	call	_FUN_NContact_spio
	
	jnb	PIN_card_exist,NContact_Rc500Request_Card
NContact_Rc500Request_NoCard:
	MOV	r6,#4;150;150;10;0ffh	
	jmp	NContact_Rc500Request_cardov
NContact_Rc500Request_Card:	
	MOV	r6,#150;150;150;10;0ffh		
NContact_Rc500Request_cardov:	
	mov	r7,#0ffh
;	call	_FUN_NContact_Rc500TxAndRx
	call	_Rc500TxAndRx1

	ret

;-----------------------------------
;	R7	---	搜索时间
;-----------------------------------
_FUN_NContact_Rc500TxAndRx:	
	push	ar7
	mov	a,#REG_RC522_ComIrqReg;04H
	rl	a
	mov	r7,#7FH
	call	_FUN_NContact_spio
	pop	ar7
	
	mov	A,#REG_RC522_CommandReg;01H
 	rl	A
	call	_FUN_NContact_spio

	MOV	A,#REG_RC522_BitFramingReg;0d		;必需有
	RL	A
	SETB	acc.7
	MOV	r7,#00h
	CALL	_FUN_NContact_spio
 
	setb	acc.7
	mov	r7,a
	mov	a,#REG_RC522_BitFramingReg;0d
	rl	a
	call	_FUN_NContact_spio

	;mov	a,r4
	;jz	_Rc500TxAndRx1001
	;ret
_FUN_NContact_Rc500Rx:

_Rc500TxAndRx1001:
	MOV	r6,#150;150;10;0ffh	
_Rc500TxAndRx1:
	nop
	nop
	nop
	nop
	nop
	djnz	r7,_Rc500TxAndRx1b
	djnz	r6,_Rc500TxAndRx1b
	JMP	_Rc500TxAndRx3
	
_Rc500TxAndRx1b:
	mov	a,#REG_RC522_ComIrqReg;04H
	rl	a
	setb	acc.7
	PUSH	AR7
	MOV	R7,#00
	call	_FUN_NContact_spio
	POP	AR7

	;MOV	R0,#DATA_irqEn
	;MOV	A,@R0
	MOV	A,DATA_irqEn
	ANL	A,B
	JZ	_Rc500TxAndRx1
	MOV	A,B
	jnb	Acc.0,_Rc500TxAndRx1b001
	jmp	_Rc500TxAndRx3

_Rc500TxAndRx1b001:
;	mov	a,#REG_RC522_BitFramingReg	;0dh
;	rl	a
;	setb	acc.7
;	mov	r7,#00h
;	call	_FUN_NContact_spio

;	clr	ACC.7
;	mov	R7,A
;	mov	A,#REG_RC522_BitFramingReg	;0dh
;	rl	A
;	CALL	_FUN_NContact_spio
	
	mov	A,#REG_RC522_ErrorReg		;06h
	rl	A
	setb	ACC.7
	mov	R7,#00h
	call	_FUN_NContact_spio
	;---*mov	A,REG_5412AD_spdat
	;MOV	A,B
	anl	A,#1bh
	jnz	_Rc500TxAndRx3
	
	mov	A,#REG_RC522_FIFOLevelReg	;0ah
	rl	A
	setb	ACC.7
	mov	R7,#00h
	call	_FUN_NContact_spio
	;---*mov	A,REG_5412AD_spdat
	;MOV	A,B
	
	;---JNB	cpu_pro,_Rc500TxAndRx2_b
	JNB	BIT_proMF,_Rc500TxAndRx2_b
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;MOV	A,#14
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	MOV	R7,A
	
	RET
;仅对MF卡
_Rc500TxAndRx2_b:
	JZ	_Rc500TxAndRx4
	
	MOV	ar1,ar5
	MOV	r5,a
_Rc500TxAndRx2:
	mov	a,#REG_RC522_FIFODataReg
	rl	a
	setb	acc.7
	mov	r7,#00h
	call	_FUN_NContact_spio
	;---*mov	A,REG_5412AD_spdat
	;MOV	A,B
	cjne	r1,#0,_Rc500TxAndRx2_e
	jmp	_Rc500TxAndRx2_c
_Rc500TxAndRx2_e:
	;---jb	xdata_flag,_Rc500TxAndRx2_e1
	
	jb	BIT_BUFADDR,_Rc500TxAndRx2_e1
	mov	@r1,a
	sjmp	_Rc500TxAndRx2_e2
_Rc500TxAndRx2_e1:
		;MOVX	@R1,A
	push	dph
	push	dpl
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	pop	dpl
	pop	dph

_Rc500TxAndRx2_e2:
	inc	r1
_Rc500TxAndRx2_c:
	djnz	r5,_Rc500TxAndRx2
_Rc500TxAndRx4:
		
	mov	a,#REG_RC522_ControlReg	;0ch
	rl	a
	setb	acc.7
	mov	r7,#00h
	call	_FUN_NContact_spio
	;---*mov	A,REG_5412AD_spdat
	;MOV	A,B
	setb	acc.7
	mov	r7,a
	mov	a,#REG_RC522_ControlReg
	rl	a
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_FIFOLevelReg
	rl	a
	mov	r7,#80h
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_CommandReg
	rl	a
	mov	r7,#00h
	call	_FUN_NContact_spio
	mov	r7,#00h	
	ret	
	
_Rc500TxAndRx3:	
	;~~~~~~~~~~~~~~~~~~~~~~~~
 
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	mov	r7,#0ffh
	clr	Pin_522_RST
	
	ret	
;--------------------------------------------------------------------------
;描述:	防碰撞
;外部参数

;	BitFramingReg
;	FIFODataReg
;	FIFODataReg

;	cardsno
;	irqEn

;内部参数:
;	xxx
;返回值
;	xxx
;--------------------------------------------------------------------------	
_FUN_NContact_Rc500Anticoll:

	mov	a,#REG_RC522_BitFramingReg	;0dh	;必需有
	rl	a
	mov	r7,#00h
	CALL	_FUN_NContact_spio
	
	mov	a,#REG_RC522_FIFODataReg
	rl	a
	mov	r7,#93h
	CALL	_FUN_NContact_spio
	
	mov	a,#REG_RC522_FIFODataReg
	rl	a
	mov	r7,#20h
	CALL	_FUN_NContact_spio

	;---mov	irqEn,#23h
	MOV	A,#23h
	MOV	R0,#DATA_irqEn
	MOV	@R0,A

	CLR	BIT_BUFADDR
	CLR	BIT_ProMF	
	mov	r5,#DATA_CardNO
	mov	r7,#0CH
	CALL	_FUN_NContact_Rc500TxAndRx
	
	cjne	r7,#0,_Rc500Anticoll_b
	mov	r0,#DATA_CardNO
	mov	r5,#5
	clr	a
	
_Rc500Anticoll_b1:
	xrl	a,@r0
	inc	r0
	djnz	r5,_Rc500Anticoll_b1
	jz	_Rc500Anticoll_b
	mov	r7,#0ffh
	
_Rc500Anticoll_b:
	ret
	
	
;--------------------------------------------------------------------------
;描述:	选卡
;外部参数

;	TPrescalerReg
;	TReloadRegL
;	TReloadRegH
;	FIFODataReg
;	TxModeReg
;	XXXX
;	XXXX
;	XXXX
;	XXXX
;	XXXX

;	Cardsno
;	XXXX
;	XXXX
;	XXXX
;	XXXX
;	XXXX
;	XXXX
;	XXXX
;	XXXX

;内部参数:
;	XXX
;返回值
;	XXX
;--------------------------------------------------------------------------		
_FUN_NContact_Rc500Select:
		
	mov	a,#REG_RC522_TPrescalerReg
	rl	a
	mov	r7,#3eh
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_TReloadRegL
	rl	a
	mov	r7,#250;30;8;30;75;#155;30 1eh
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_TReloadRegH
	rl	a
	mov	r7,#02;01h;00h
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_FIFODataReg
	rl	a
	mov	r7,#93h
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_FIFODataReg
	rl	a
	mov	r7,#70h;70h
	call	_FUN_NContact_spio

	mov	r0,#DATA_CardNO
	mov	r2,#4
	mov	r6,#0

_Rc500Select1:
	mov	a,@r0
	mov	r7,a
	xrl	ar6,a
	mov	a,#REG_RC522_FIFODataReg
	rl	a
	call	_FUN_NContact_spio
	inc	r0
	djnz	r2,_Rc500Select1
	
	mov 	a,r6
	mov	r7,a
	mov	a,#REG_RC522_FIFODataReg
	rl	a
	call	_FUN_NContact_spio
	
	mov	a,#REG_RC522_TxModeReg
	rl	a
	mov	r7,#80h
	Call	_FUN_NContact_spio
	
	MOV	A,#REG_RC522_RxModeReg
	RL	A
	MOV	R7,#80h
	CALL	_FUN_NContact_spio
	
	;---MOV	irqEn,#33h
	MOV	R0,#DATA_IRQEN
	MOV	@R0,#33H
	CLR	BIT_BUFADDR
	CLR	BIT_ProMF		
	MOV	r5,#DATA_RXBUF
	;MOV	R5,#DATA_NCONTACTTYPE
	MOV	R7,#0ch
	CALL	_FUN_NContact_Rc500TxAndRx
	
	RET
	
	
	
	
;////////////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////////
;_FUN_NContact_Rc500Rx:
;	RET
	
_FUN_NContact_Rc500TxAndRx02:	
	push	ar7
	mov	a,#REG_RC522_ComIrqReg;04H
	rl	a
	mov	r7,#7FH
	call	_FUN_NContact_spio
	pop	ar7
	
	mov	A,#REG_RC522_CommandReg;01H
 	rl	A
	call	_FUN_NContact_spio

	MOV	A,#REG_RC522_BitFramingReg;0d		;必需有
	RL	A
	SETB	acc.7
	MOV	r7,#00h
	CALL	_FUN_NContact_spio
 
	setb	acc.7
	mov	r7,a
	mov	a,#REG_RC522_BitFramingReg;0d
	rl	a
	call	_FUN_NContact_spio

	;mov	a,r4
	;jNz	NContact_Rc500TxAndRx02_OVER

;	JMP	_Rc500TxAndRx1001
;NContact_Rc500TxAndRx02_OVER:
	
	RET	
	
	END	

