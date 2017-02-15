;******************************************************************
;描述：PRO卡片操作扩展程序集
;_FUN_ProCard_RXBYTE		---	Pro卡接收单个字节的数据
;_FUN_ProCard_RXPro		---	Pro卡接收数据
;_FUN_ProCard_TXBYTE		---	Pro卡发送单个字节的数据
;_FUN_ProCard_TXPro		---	Pro卡发送数据
;_FUN_ProCard_Channel		---	Pro卡通道操作函数
;******************************************************************
NAME	ProCard
	
$INCLUDE(COMMON.INC)
$INCLUDE(ProCard.INC)
	
	RSEG	?pr?ProCard?Mater
	USING	0
	
;--------------------------------------------------------------------------
;描述:Pro卡接收单个字节的数据(_FUN_ProCard_RXBYTE)
;外部参数
;	XXX		---	XXX
;内部参数:
;返回值
;--------------------------------------------------------------------------	
_FUN_ProCard_RXBYTE:

	PUSH	AR7
	MOV	R7,#00H
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	SETB	ACC.7
	CALL	_FUN_NContact_spio
	;---MOV	A,REG_5412AD_spdat
	POP	AR7
	RET
;--------------------------------------------------------------------------			
_FUN_ProCard_RXNUM:
	
	MOV	R7,#00H
	MOV	A,#REG_RC522_FIFOLevelReg
	RL	A
	SETB	ACC.7
	CALL	_FUN_NContact_spio
	;MOV	A,REG_5412AD_spdat	
	
	RET	
;--------------------------------------------------------------------------
;描述:Pro卡接收数据(_FUN_ProCard_RXPro)
;外部参数
;	R7		---	接收绶冲
;	BIT_BUFADDR	---	=0 接收数据到内存;	=1 接收数据到外存
;	BIT_GETRESULT	---	=1 表示取，取返回结果;	=0 表示不取返回结果
;内部参数:
;	XXX
;返回值
;	R3		---	接收到的数据长度

;--------------------------------------------------------------------------	
_FUN_ProCard_RXPro:	

	MOV	AR0,AR7
_FUN_ProCard_RXPro_j:	
	MOV	DATA_IRQEN,#29H
	PUSH	AR0
	CALL	_FUN_NContact_Rc500Rx	;读PRO卡前所要做的准备工作,返回接收长度
	POP	AR0

ProCard_RXPro_StartRX01:
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#33
	;JMP	_FUN_TEST_DISPLAY	
	;~~~~~~~~~~~~~~~~~~~~~~~~~	
;	mov	a,r2
;	xrl	a,#30
;	jnz	xxxxx
;	mov	a,r7
;	CALL	_FUN_TEST_DISPLAY
;xxxxx:	
	MOV	A,R7				;获取接收长度_D
	XRL	A,#0FFH
	JNZ	ProCard_RXPro_StartRX
	JMP	ProCard_RXPro_ERR

ProCard_RXPro_StartRX:
	MOV	A,R7				;获取接收长度_D
	XRL	A,#03H
	JNZ	ProCard_RXPro_StartRX_J

	CALL	_FUN_ProCard_RXBYTE
	XRL	A,#0FAh
	JNZ	ProCard_RXPro_StartRX_J1
	
	CALL	_FUN_ProCard_RXBYTE		
	CALL	_FUN_ProCard_RXBYTE		

	mov	a,#REG_RC522_FIFODataReg;09h
	rl	a
	mov	r7,#0FAh
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_FIFODataReg;09h
	rl	a
	mov	r7,#01h
	call	_FUN_NContact_spio

	mov	a,#REG_RC522_FIFODataReg;09h
	rl	a
	mov	r7,#32h
	call	_FUN_NContact_spio

	mov	r7,#0ch
	;mov	r4,#0
	call	_FUN_NContact_Rc500TxAndRx

	jmp	_FUN_ProCard_RXPro_j

	;--- 读返回结果3非FA ---
ProCard_RXPro_StartRX_J1:
	MOV	A,R7
	DEC	A
	DEC	A
	MOV	R3,A
	
	CJNE	R3,#127,$+3
	JC	ProCard_RXPro_RXRESULT_j
	JMP	ProCard_RXPro_ERR
ProCard_RXPro_RXRESULT_j:
	CALL	_FUN_ProCard_RXBYTE		
	JMP	ProCard_RXPro_RXRESULT_j2
	
	;--- 读返回结果非03 ---
ProCard_RXPro_StartRX_J:
	MOV	A,R7
	DEC	A
	DEC	A
	MOV	R3,A
	
	;------ r3>127 ----
	cjne	r3,#127,$+3
	jc	ProCard_RXPro_RXRESULT	
	jmp	ProCard_RXPro_ERR
	
ProCard_RXPro_RXRESULT:
	CALL	_FUN_ProCard_RXBYTE
	CALL	_FUN_ProCard_RXBYTE			
	
ProCard_RXPro_RXRESULT_j2:
	MOV	AR4,AR3	
	
ProCard_RXPro_StartLoop:
	PUSH	AR4
	PUSH	AR3	;保存接收长度
	
ProCard_RXPro_Loop:
	CALL	_FUN_ProCard_RXBYTE
	;需要加延时，不然数据太长，有时接收不完整
	MOV	R7,#10
	DJNZ	R7,$
	
	JB	BIT_BUFADDR,RXPro_Loop_ADDRMOVX
RXPro_Loop_ADDRMOV:
	MOV	@R0,A
	JMP	RXPro_Loop_ADDROVER
RXPro_Loop_ADDRMOVX:
		;MOVX	@R0,A
;	push	dph
;	push	dpl	
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
;	pop	dpl
;	pop	dph	
RXPro_Loop_ADDROVER:
	INC	R0
	DJNZ	R3,ProCard_RXPro_Loop		
		
	POP	AR3
	POP	AR4

	;FIFOLevelReg Indicate the number of bytes store in the fifo
	MOV	A,#REG_RC522_FIFOLevelReg
	RL	A
	SETB	ACC.7
	MOV	R7,#00h
	CALL	_FUN_NContact_spio
	
	JZ	ProCard_RXPro_OVER
	MOV	R3,A
	ADD	A,R4
	MOV	R4,A

	;------ r3>127 ----
	cjne	r4,#127,$+3
	jc	ProCard_RXPro_fhfh	
	jmp	ProCard_RXPro_ERR	
	
ProCard_RXPro_fhfh:
	JMP	ProCard_RXPro_StartLoop	
	
ProCard_RXPro_OVER:

;	DEC	R0
;	DEC	R0
	
;		;MOVX	A,@R0

;	CALL	_FUN_TEST_DISPLAY
;xxxx:

;	mov	a,r2
;	xrl	a,#30
;	jnz	xxxxx
	;mov	a,r7
	;CALL	_FUN_TEST_DISPLAY

;dec	r0
;dec	r0
;	;MOVX	A,@R0
	
;call	_fun_test_display		
;xxxxx:	
	

	MOV	AR3,AR4
	PUSH	AR3
	CALL	_FUN_ProCard_CLRResult
	POP	AR3
	


;call	_fun_test_display	



	;dec	r0
	;dec	r0
	;	;MOVX	A,@R0

	;clr	a
	;mov	c,BIT_GETRESULT
	;mov	acc.0,c
	;mov	a,r3
	;call	_fun_test_display
	JB	BIT_GETRESULT,ProCard_RXPro_Ret
	;--- 返回 61 + 长度(不返结果) ---
	MOV	A,R0
	CLR	C
	SUBB	A,R4
	; INC	A
	MOV	R0,A
	MOV	A,#61H
		;MOVX	@R0,A
;	push	dph
;	push	dpl

	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,R4
		;MOVX	@R0,A
;	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
;	pop	dpl
;	pop	dph
	MOV	R3,#2
	
ProCard_RXPro_Ret:	
	;---setb	BIT_GETRESULT
	RET		
	
ProCard_RXPro_ERR:
	MOV	R7,#CONST_STATE_FALSE
	MOV	R3,#0
	RET	
	
;--------------------------------------------------------------------------
;描述:清除FIFO及终止RC522的Excution(_FUN_ProCard_TXBYTE)
;外部参数
;	A		---	将要发送的数据
;内部参数:
;返回值
;--------------------------------------------------------------------------

_FUN_ProCard_CLRResult:
	mov	a,#REG_RC522_ControlReg
	rl	a
	setb	acc.7
	mov	r7,#00h
	call	_FUN_NContact_spio
	;mov	a,REG_5412AD_spdat

	setb	acc.7
	mov	r7,a
	mov	a,#REG_RC522_ControlReg
	rl	a
	call	_FUN_NContact_spio

	;clear FIFO buffer
	mov	a,#REG_RC522_FIFOLevelReg
	rl	a
	mov	r7,#80h
	call	_FUN_NContact_spio

	;stop execution
	mov	a,#REG_RC522_CommandReg
	rl	a
	mov	r7,#00h
	call	_FUN_NContact_spio 	
	RET
;--------------------------------------------------------------------------
;描述:Pro卡发送单个字节的数据(_FUN_ProCard_TXBYTE)
;外部参数
;	A		---	将要发送的数据
;内部参数:
;返回值

;--------------------------------------------------------------------------	
_FUN_ProCard_TXBYTE:

	PUSH	AR7
	MOV	R7,A
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	CALL	_FUN_NContact_spio
	POP	AR7

	RET
;--------------------------------------------------------------------------
;描述:Pro卡发送数据(_FUN_ProCard_TXPro)
;规则:
;		要在发送数据前加 0a/0b + 00，如要发送0x01,0x02,0x03
;		则完整的发送数据是 0a/0b + 0x00 + 0x01 + 0x02 + 0x03
;外部参数
;BIT_BUFADDR	---	=0，发送的是内存数据；=1，发送的是外存数据
;R7		---	将要发送数据的buf
;R3		---	发送数据的长度
;BIT_PROF	---	Pro卡发送序号	= 0 表示0A ;= 1 表示0B
;内部参数:
;返回值
;--------------------------------------------------------------------------	
;一次最多向绶冲区写入50个字节
;超过50个字节时，则要写入50个字节后，要等待绶冲中小于25个字节后，再向绶冲写入<=25个字节，直到结束
;--------------------------------------------------------------------------		
_FUN_ProCard_TXPro:
	;发送头部数据
;PUSH AR7
;	mov	a,#REG_RC522_TmodeReg
;	rl	a
;	mov	r7,#82h
;	CALL	_FUN_NContact_spio
	
;	mov	a,#REG_RC522_TPrescalerReg
;	rl	a
;	mov	r7,#0a6h
;	call	_FUN_NContact_spio
	
;	mov	a,#REG_RC522_TModeReg
;	rl	a
;	mov	r7,#82h
;	call	_FUN_NContact_spio

;	mov	a,#REG_RC522_TmodeReg
;	rl	a
;	mov	r7,#82h
;	call	_FUN_NContact_spio
	
;	mov 	a,#REG_RC522_TReloadRegL
;	rl 	a
;	mov 	r7,#150				;30;8;30;75;#155;30 1eh
;	call 	_FUN_NContact_spio
	
;	mov 	a,#REG_RC522_TReloadRegH
;	rl 	a
;	mov 	r7,#01h				;00h
;	call 	_FUN_NContact_spio
;POP AR7


	MOV	A,#0AH
	MOV	C,BIT_PROF
	MOV	ACC.0,C
	CALL	_FUN_ProCard_TXBYTE
	CPL	BIT_PROF
	mov	a,#1
	CALL	_FUN_ProCard_TXBYTE
	
	CJNE	R3,#54,$+3
	JNC	ProCard_TXPro_Len
	MOV	R4,#0
	JMP	ProCard_TXPro_LenTX

ProCard_TXPro_Len:
	CLR	C
	MOV	A,AR3
	SUBB	A,#53
	MOV	R4,A
	MOV	R3,#53
	
ProCard_TXPro_LenTX:
	;发送指令数据
	MOV	AR0,AR7
		
ProCard_TXPro_lenLOOP:
	JB	BIT_BUFADDR,TXPro_LOOP_ADDRMOVX
TXPro_LOOP_ADDRMOV:
	MOV	A,@R0
	JMP	TXPro_LOOP_ADDROVER
TXPro_LOOP_ADDRMOVX:
		;MOVX	A,@R0

;	push	dph
;	push	dpl
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
;	pop	dpl
;	pop	dph
TXPro_LOOP_ADDROVER:
	CALL	_FUN_ProCard_TXBYTE
	INC	R0
	DJNZ	R3,ProCard_TXPro_lenLOOP
	
	MOV	DATA_IRQEN,#29H
	MOV	R7,#0ch
	;PUSH	AR4
	CALL	_FUN_NContact_Rc500TxAndRx02
	;CALL	_FUN_NContact_Rc500TxAndRx
	;POP	AR4
	mov	a,r4
	jnz	ProCard_TXPro_TXWAIt
	jmp	ProCard_TXPro_LENOver
ProCard_TXPro_TXWAIT:	
	MOV	R7,#00H
	MOV	A,#REG_RC522_FIFOLevelReg
	RL	A
	SETB	ACC.7
	CALL	_FUN_NContact_spio	

	CJNE	A,#30,$+3
	JNC	ProCard_TXPro_TXWAIT
	MOV	AR3,AR4
	
ProCard_TXPro_lenLOOP2:
	;需要加延时，不然数据太长，FiFo满出
	MOV	r7,#18
	DJNZ	r7,$
	
	JB	BIT_BUFADDR,TXPro_LOOP_ADDRMOVX2
TXPro_LOOP_ADDRMOV2:
	MOV	A,@R0
	JMP	TXPro_LOOP_ADDROVER2
TXPro_LOOP_ADDRMOVX2:
		;MOVX	A,@R0

;	push	dph
;	push	dpl
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
;	pop	dpl
;	pop	dph
	
TXPro_LOOP_ADDROVER2:
	CALL	_FUN_ProCard_TXBYTE
	INC	R0
	DJNZ	R3,ProCard_TXPro_lenLOOP2

	;MOV	R7,#00H
	;MOV	A,#REG_RC522_FIFOLevelReg
	;RL	A
	;SETB	ACC.7
	;CALL	_FUN_NContact_spio	
	;call	_fun_test_display
;xxx:	
ProCard_TXPro_LENOver:
	
	RET
;/////////////////////////////////////////////////////////
;	JMP	ProCard_TXPro_Len
	;<=50个字节的指令处理流程
;ProCard_TXPro_Short:
	;发送指令数据
;	MOV	AR0,AR7
;ProCard_TXPro_LOOP:
;	JB	BIT_BUFADDR,TXPro_LOOP_ADDRMOVX
;TXPro_LOOP_ADDRMOV:
;	MOV	A,@R0
;	JMP	TXPro_LOOP_ADDROVER
;TXPro_LOOP_ADDRMOVX:
;		;MOVX	A,@R0

;	NOP
;	NOP
;	NOP
;TXPro_LOOP_ADDROVER:
;	CALL	_FUN_ProCard_TXBYTE
;	INC	R0
;	DJNZ	R3,ProCard_TXPro_LOOP
;ProCard_TXProOVER:
;	RET	
;--------------------------------------------------------------------------	
	;PUSH	AR7
	;MOV	R7,#122
	;DJNZ	R7,$
	;POP	AR7
;超过50个字节的指令处理
;ProCard_TXPro_Len:
;	CLR	C
;	MOV	A,AR3
;	SUBB	A,#53
	
;	MOV	R4,A
;	MOV	R3,#53
;ProCard_TXPro_LenTX:

	;发送指令数据
;	MOV	AR0,AR7
;ProCard_TXPro_lenLOOP:
;	MOV	A,@R0
;	CALL	_FUN_ProCard_TXBYTE
;	INC	R0
;	DJNZ	R3,ProCard_TXPro_lenLOOP
;	MOV	A,R4
;	JZ	ProCard_TXPro_LENOver
;	MOV	AR3,AR4
	;发送FiFo中第一部份的数据
;	MOV	DATA_IRQEN,#29H			
;	MOV	R7,#0CH				
;	CALL	_FUN_NContact_TESTRc500TxAndRx	
	
	;等街FiFo中的数据<=25个字节
;ProCard_TXPro_TXWAIT:
;	MOV	R7,#00H
;	MOV	A,#REG_RC522_FIFOLevelReg
;	RL	A
;	SETB	ACC.7
;	CALL	_FUN_NContact_spio
;	CJNE	A,#30,$+3
;	JNC	ProCard_TXPro_TXWAIT
;ProCard_TXPro_lenLOOP2:
;	MOV	A,@R0

;	MOV	R7,#1;122
;	DJNZ	R7,$

;	CALL	_FUN_ProCard_TXBYTE

;	INC	R0
;	DJNZ	R3,ProCard_TXPro_lenLOOP2
	
;	RET
;///////////////////////////////////////////////////
	
	;MOV	A,R4
	;CALL	_FUN_TEST_DISPLAY	
	
;ProCard_TXPro_PRE:
	;CJNE	R3,#26,$+3
	;JNC	ProCard_TXPro_dy25
;	MOV	R4,#0
	
	;MOV	A,R3
	;MOV	AR0,AR7
	;MOV	A,@R0
	;CALL	_FUN_TEST_DISPLAY	
;	JMP	ProCard_TXPro_LenTX
	
	;大于25时
;ProCard_TXPro_dy25:
;	CLR	C
;	MOV	A,AR3
;	SUBB	A,#25
	
;	MOV	R4,A
;	MOV	R3,#25
;	JMP	ProCard_TXPro_LenTX
;ProCard_TXPro_PREWC25:		
	
;ProCard_TXPro_LENOver:
	
	;MOV	A,#33
	;CALL	_FUN_TEST_DISPLAY

	;RET
	
;--------------------------------------------------------------------------
;描述:XXX
;外部参数
;XXX	---	XXX
;内部参数:
;返回值
;--------------------------------------------------------------------------		
;_rats:
_FUN_ProCard_rats:
	
	;mov	r7,#20
	;call	_fun_lib_delay
	
;选择应答请求--->E0 +参数字节(FSDI+CID)+CRC1+CRC2
;bit8~bit5-->FSDI  bit4~bit1-->CID
;FSDI	‘0’	‘1’	‘2’	‘3’	‘4’	‘5’	‘6’	‘7’	‘8’	‘9’-‘F’
;FSD-->设备帧长度
;(字节)	16	24	32	40	48	64	96	128	256	RFU>256	
	
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	MOV	R7,#0e0h
	CALL	_FUN_NContact_spio
	
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	;---MOV	R7,#50h			;即64字节
	MOV	R7,#71h			;即128字节
	CALL	_FUN_NContact_spio
	CLR	BIT_BUFADDR
	SETB	BIT_ProMF	
	MOV	DATA_IRQEN,#23h
	MOV	R5,#DATA_RXBUF

	
	MOV	R7,#0ch
	CALL	_FUN_NContact_Rc500TxAndRx

	CJNE	R7,#0ffh,_rats1
_ratserr:
	MOV	R7,#0ffh
	
	RET
_rats1:
	MOV	A,R7
	
	JZ	_ratserr
_rats2:
	mov	ar1,#DATA_RXBUF			;保存DATA_RXBUF
_rats2_1:

	CALL	_FUN_ProCard_RXBYTE
	mov	@r1,a				;保存DATA_RXBUF
	;mov	a,r7
	;call	_fun_test_display	
	inc	ar1				;保存DATA_RXBUF
	DJNZ	r7,_rats2_1
	
	RET
	
;///////////////////////////////////////////////////////////////////////////////////	
_FUN_Pro_PPS:

;协议和参数选择请求=====发PPS命令--->PPSS+PPS0+PPS1+CRC1+CRC21	
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	MOV	R7,#0d1h;0d0h			;PPPS
	CALL	_FUN_NContact_spio
	
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	;---MOV	R7,#50h				
	MOV	R7,#11h				;PPS0
	CALL	_FUN_NContact_spio
	
	MOV	A,#REG_RC522_FIFODataReg
	RL	A
	;---MOV	R7,#50h			
	MOV	R7,#0ah				;PPS1
	CALL	_FUN_NContact_spio
	
	CLR	BIT_BUFADDR
	SETB	BIT_ProMF	
	MOV	DATA_IRQEN,#23h
	MOV	R5,#DATA_RXBUF
	MOV	R7,#0ch
	CALL	_FUN_NContact_Rc500TxAndRx
	
	CJNE	R7,#0ffh,_rat_NContact_PPS_s1
_rat_NContact_PPS_serr:
	MOV	R7,#0ffh	
	RET
	
_rat_NContact_PPS_s1:
	MOV	A,R7
	
	JZ	_rat_NContact_PPS_serr
_rat_NContact_PPS_s2:
	mov	ar1,#DATA_RXBUF			;保存DATA_RXBUF

_rat_NContact_PPS_s2_1:
	CALL	_FUN_ProCard_RXBYTE
	mov	@r1,a				;保存DATA_RXBUF
	inc	ar1	
	DJNZ	r7,_rat_NContact_PPS_s2_1
	
	RET
;--------------------------------------------------------------------------
;描述:Pro卡通道操作函数(_FUN_ProCard_Channel)
;规则:
;		要在发送数据前加 0a/0b + 00，如要发送0x01,0x02,0x03
;		则完整的发送数据是 0a/0b + 0x00 + 0x01 + 0x02 + 0x03
;外部参数
;R7		---	将要发送数据的buf
;R5		---	将要接收数据的buf
;R3		---	发送数据的长度
;BIT_PROF	---	Pro卡发送序号	= 0 表示0A ;= 1 表示0B
;BIT_GETRESULT	---	=1 表示取，取返回结果;	=0 表示不取返回结果
;内部参数:
;返回值
;	接收数据的长度
;--------------------------------------------------------------------------	
_FUN_ProCard_Channel:

	CLR	BIT_BUFADDR		; 内存发送
	PUSH	AR5	
	PUSH	AR3			; 
	CALL	_FUN_ProCard_TXPro	; 	
	POP	AR3
	POP	AR5			; 

	SETB	BIT_BUFADDR		; 外存接收
	MOV	AR7,AR5			; 
	CALL	_FUN_ProCard_RXPro

	;MOV	a,r3							;有的ESAM选1001快比PPS回应还快，所以要再补上一些延时
	;CALL	_FUN_TEST_DISPLAY	
	
	
	RET				;

	END
;/////////////////////////////////////////////////////////////////////////////


