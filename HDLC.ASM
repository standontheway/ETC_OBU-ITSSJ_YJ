;**********************************************************************
;描述：HDLC通讯程序集
;函数申明
;做成下行256K; 上行512K
;_FUN_HDLC_RX					---	HDLC接收函数
;	附属序段:;SEG_HDLC_GETF1Cycle		---	查询第一个"1"的脉冲
;	附属序段:;SEG_RX_GET7E			---	查询第一个"7E"的脉冲
;	附属序段:;SEG_RX_GETCycle		---	搜索脉冲
;_FUN_HDLC_RXForBST				---	HDLC接收函数(接收第一个BST专用)
;_FUN_HDLC_TX					---	HDLC发送函数
;	附属序段:SEG_HDLC_TX7E			---	发送7E
;_FUN_HDLC_CHANGECHANNEL			---	更改通道
;**********************************************************************
;Rx_En			接收使能或禁止
;Tx_Carrier_En		发送载波使能或禁止
;_Power_Up		使能上电或关闭上电
;Wake_up			唤醒使能或禁用
;_Enter_Idle_Mode	进入待机模式
;_Enter_Sleep_Mode	进入睡眠模式
;_Enter_Receive_Mode	进入接收模式
;_Enter_TX_Carrier_Mode	进入发载波模式
;_Enable_Wake_Up		进入唤醒模式
;_Disable_Wake_Up	关闭唤醒模式
;_TXDIOpin		发送DIO pin 数据流配置
;_BK_SPIRST		复位或使能BK5822 SPI寄存器
;_BK5822_RST		复位BK5822
;_AutoASKReg		初始化BK5822
;_FUN_HDLC_5822Init	
;wkoup_sj
;_FUN_HDLC_Frexiaodui
;**********************************************************************
	
NAME	HDLC

$INCLUDE(HDLC.INC)
$INCLUDE(COMMON.INC)
	
	RSEG	?pr?HDLC?Mater
	USING	0
	
;--------------------------------------------------------------------------
;描述:HDLC发送函数
;外部参数
;BIT_CHANNELFLAG	---	=1表示当前使用信道1;=0表示当前使用信道0
;PIN_WAVE_CHANNEL0	---	微波收发腿0
;PIN_WAVE_CHANNEL1	---	微波收发腿1
;R7			---	将要发送字符串buf的指针
;R3			---	将要发送数据字节长度

;内部参数:
;R0
;--------------------------------------------------------------------------
_FUN_HDLC_TX:
 	MOV	R7,#1
	CALL	Tx_Carrier_En
	
	JB	Pin_unfix,HDLC_TX_unfix
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	JB	Pin_unfix,HDLC_TX_unfix
	
 	MOV	R7,#0
	CALL	Tx_Carrier_En
	
	JMP	ap_start

HDLC_TX_unfix:
	MOV	R0,#XDATA_TOTALNUML
	CLR	C
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
	MOV	A,#1
	ADDC	A,B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	DEC	R0			;[1]
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A	
	MOV	A,#0
	ADDC	A,B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;当超过0x800=2048次时，强行关发射休眠
	CJNE	A,#4,$+3
	JC	HDLC_TX_WDT
	
 	MOV	R7,#0
	CALL	Tx_Carrier_En
	
	JMP	ap_start
	
HDLC_TX_WDT:	
	;---MOV	REG_WDT_CONTR,#00111111B
	;MOV	REG_WDT_CONTR,#00111110B
	;240us
	MOV	R7,#255
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	DJNZ	R7,$
	
	CALL	HDLC_TX_T
	
 	MOV	R7,#00
	CALL	Tx_Carrier_En
	
	;开接收使能
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	orl	A,#00000010B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg

	RET
;///////////////////////////////////////////////////////////////////////////
	
HDLC_TX_T:
	CLR 	PIN_WAVE_CHANNEL1
 
;	MOV 	R0,#XDATA_TXBUF				;1
	mov	dph,#1
	mov	dpl,#XDATA_TXBUF
	MOV 	A,DATA_DSRCTXLEN
	
	MOV 	R3,a
	
	;---补发16个"1"---
	MOV	R2,#16					;2
HDLC_TX_SET:;(0,7)					;1
;	CPL	PIN_WAVE_CHANNEL0			;4	
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	
	CJNE	R2,#2,$+3				;4
	JC	HDLC_TX_SETOVER				;3
	
	;*** Insert 48 - 19 = 29 Cycle ***
	CALL	_FUN_LIB_DELAY29
	
	DJNZ	R2,HDLC_TX_SET				;4 = 8	
HDLC_TX_SETOVER:
	;*** Insert 48 - 17 = 31 Cycle ***
	CALL	_FUN_LIB_DELAY31
	
	;2 发送前导码发17个零
	MOV	R2,#34					;2
HDLC_TX_PRECODE:;(0,7)					;1
;	CPL	PIN_WAVE_CHANNEL0			;4
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	
	CJNE	R2,#2,$+3				;4
	JC	HDLC_TX_FALGCODESTART			;3
	
	NOP
	NOP
	NOP
	
	NOP
	NOP
	
	DJNZ	R2,HDLC_TX_PRECODE			;4 = 8	
	;3 发送7E 0111 1110
HDLC_TX_FALGCODESTART:	
	NOP						;1
	NOP
	NOP
	CALL	SEG_HDLC_TX7E;(10,8)
	NOP						;1
	;3 发送HDLC数据
	;R0	---	绶冲指针
	;R3	---	绶冲长度
	;R2	---	位循环
	;R4	---	位记录
HDLC_TX_SENDDATASTART:
	MOV	R4,#00H					;2
HDLC_TX_SENDDATA:					;大循环
	MOV	R2,#08					;2
	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0					;
	MOVX	A,@DPTR					;3				;3
HDLC_TX_DATAFLAGCODE:					;小循环
	RRC	A					;1
	JNC	HDLC_TX_DATAFLAGCODE_0			;3
;**********************************************************************
HDLC_TX_DATAFLAGCODE_1:
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4

	INC	R4					;300
	CJNE	R4,#5,HDLC_TX_DATAFLAGCODE_1ZC		;4   不等于5时跳转
	;插入一位的"0"
	;*** Insert 48-19= 29 cycle ***
	CALL	_FUN_LIB_DELAY29
	JMP	HDLC_TX_DATAFLAGCODE_0			;4 插入一位的"0"
HDLC_TX_DATAFLAGCODE_1ZC:
	; Insert 6 Cycle 
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1	
	NOP
	
	CJNE	R2,#2,$+3				;4
	JC	HDLC_TX_DATAFLAGCODE_1ZCOVER		;3
	;小循环比大循环少了11脉冲，补齐
	;*** Insert 12 Cycle ***
	CALL	_FUN_LIB_DELAY12
HDLC_TX_DATAFLAGCODE_1ZCOVER:
	DJNZ	R2,HDLC_TX_DATAFLAGCODE			;4
	
	;INC	R0					;3
	inc	dptr					;1
	nop
	nop	
	
	DJNZ	R3,HDLC_TX_SENDDATA			;4 发送字循环
	
	NOP						;1
	NOP
	NOP	
	CALL	SEG_HDLC_TX7E				;(10,8)
	JMP	HDLC_TX_SENDENDCODE
;**********************************************************************
HDLC_TX_DATAFLAGCODE_0:					;发送0
;	CPL	PIN_WAVE_CHANNEL0			;4
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	MOV	R4,#0					;2
	CJNE	R2,#2,$+3				;4  R2=1 跳转
	JC	HDLC_TX_DATAFLAGCODE_0FZC		;3
HDLC_TX_DATAFLAGCODE_0ZC:				;0
	;*** Insert Cycle 7 ***
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1	
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	;*** Insert Cycle 8 ***
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	DJNZ	R2,HDLC_TX_DATAFLAGCODE			;4
HDLC_TX_DATAFLAGCODE_0FZC:
	;4 Cycle
	NOP
	NOP
	NOP
	NOP
	;INC	R0					;3
	inc	dptr
	nop	
	nop
	
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	NOP
	NOP
	NOP
	DJNZ	R3,HDLC_TX_SENDDATA			;4
	
	NOP						;1
	NOP
	NOP	
	CALL	SEG_HDLC_TX7E				;(10,8)
	NOP
	NOP
	NOP
	NOP
	;--- 发送后导码 ---
HDLC_TX_SENDENDCODE:
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	NOP						;1
	
	MOV	R2,#8;35					;2
HDLC_TX_ENDCODE:;(0,7)					;1
;	CPL	PIN_WAVE_CHANNEL0			;4
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4

	CJNE	R2,#2,$+3				;4
	JC	HDLC_TX_OVER				;3

	NOP
	NOP
	NOP
	NOP
	NOP

	DJNZ	R2,HDLC_TX_ENDCODE			;4 = 8	
HDLC_TX_OVER:
	;--- 将发送引脚拉高 ---
	NOP
	NOP
	NOP
	NOP
	CLR	PIN_WAVE_CHANNEL1
	
	RET						;4
;**********************************************************************
;SEG_HDLC_TX7E(附属序段)
;附属:_FUN_HDLC_TX
;描述:发送7E
;**********************************************************************
SEG_HDLC_TX7E:;(10,8)
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	;*** Insert Cycle 24 - 8 =16 ***
	CALL	_FUN_LIB_DELAY16
	
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	;*** Insert Cycle 24 - 10 =14 ***
	CALL	_FUN_LIB_DELAY14
	
 	MOV	R2,#6					;2
HDLC_TX7E_FALGCODE:
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4
	
	CJNE	R2,#2,$+3				;4
	JC	HDLC_TX7E_FALGCODE0			;3	
	;*** Insert Cycle 48 - 19 = ***
	CALL	_FUN_LIB_DELAY29

	DJNZ	R2,HDLC_TX7E_FALGCODE			;4
HDLC_TX7E_FALGCODE0:
	;*** Insert Cycle 48 - 15 = 33 ***
	CALL	_FUN_LIB_DELAY33
	
	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4	
	;*** Insert Cycle 24 - 8 = 16***
	CALL	_FUN_LIB_DELAY16	

	NOP
	NOP
	NOP
	NOP
	CPL	PIN_WAVE_CHANNEL1			;4	
	
	RET
;--------------------------------------------------------------------------
;描述:HDLC接收函数
;外部参数
;BIT_HDLCLASTD		---	记录HDLC上一次的s电平状态
;PIN_WAVE_RX		---	微波接收腿
;DATA_RXBUF		---	将要接收字符串buf的指针
;内部参数:
;R4			---	记录"1"的个数
;返回值:
;R3			---	接收的数据长度
;--------------------------------------------------------------------------
;96 / 72
_FUN_HDLC_RX:
	;已接收到数据，先清，防止收到上一次的数据
	JB	Pin_5823BK_IRQ,HDLC_5823_RXLOOPS
;	MOV	A,#3	
;	CALL	_FUN_TEST_DISPLAY
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
HDLC_5823_RXLOOPS:
	;开接 收 使能
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	orl	A,#00000010B; 防止AGC锁死及防止5823接收没有使能
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
HDLC_5823_RXLOOP:
	JB	Pin_5823BK_IRQ,HDLC_5823_RXLOOP	
;	MOV	A,#4
;	CALL	_FUN_TEST_DISPLAY

	;=== 读接收标记寄存器 ===
	;reg6.2 =1 表示接收出错[解码出错，或CRC出错这一位都为置]
	;reg6.1 = 1 表示接收到数据	
	MOV	R5,#06h
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;接收出错标记
	MOV	C,ACC.2
	JC	hdlc_5823_ClearRXEr
	;接收正克标记
	MOV	C,ACC.1
	JC	hdlc_5823_ReceviceData
	;接收出错，清reg15.26 接收出错标记，不清，则5823会处在一直在idle模式,irq脚会一直为低
	;注意清是用 1 清，不是 0 
	;注意接收出错标记，不清，则5823会处在一直在idle模式,irq脚会一直为低
hdlc_5823_ClearRXEr:
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
	JMP	hdlc_5823_RXLOOP
	
;///////////////////////////////////////////////////////////////////////////////////////////
	;接收到数据，
	;读Reg5<0~7>，FIFO 接收长度
	;如果接收到的数据长度为 0
	; 	清Reg 15.25 
	;	否则，读空 FIFO [Reg16]
	;注意清是用 1 清，不是 0 
	;注意接收标记，不清，则5823会处在一直在idle模式,irq脚会一直为低
	;注意读空FIFO或清接收标记，都会将5823从idle模式转成接收模式
;///////////////////////////////////////////////////////////////////////////////////////////
hdlc_5823_ReceviceData:	
	;=== 关接收使能 ===
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	anl	A,#11111101B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg 
	
	;=== 读接收数据长度 ===
	MOV	R5,#05h
	MOV	R6,#04h
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;mov	r7,#200
	;call	_fun_lib_delay
 	JNZ	hdlc_5823_RXFIFO
 	;接收len度为0时，清接收位
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg	
	JMP	hdlc_5823_RXLOOP	
hdlc_5823_RXFIFO:	;减CRC 长度后,接收长度是否大于0
	DEC	A
	DEC	A
	JZ	hdlc_5823_ClearRXEr	
	CJNE	A,#129,$+3
	JC	hdlc_5823_RXFIFOLENOK
	JMP	hdlc_5823_ClearRXEr
hdlc_5823_RXFIFOLENOK:
	MOV	R0,#DATA_DSRCRXLEN
	MOV	@R0,a
	
	SETB	PIN_ESAM_RST	
	SETB	PIN_ESAM_RX
	
	;=== 接数据 ===
	MOV	R5,#16
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R6,A		
	;-------------------------------------------
	;入口：	R5	要读的寄存器
	;	R6	读出R6个字节
	;	R7	读出字节存放地址指针
	;MOV	R7,#XDATA_HOLD
	;-------------------------------------------	
	CLR	BIT_BUFADDR
	MOV	R7,#DATA_RXBUF
	PUSH	AR6
	CALL	SPI_Read_Reg
	POP	AR6
	;=== 清标记 ===
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg	
	MOV	R0,#DATA_DSRCRXLEN
	MOV	A,@R0
	MOV	AR3,A	
	
	RET	
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;描述:;5830初始化
;外部参数
;PIN_5830_CLK		---	5830时钟线
;PIN_5830_DATA		---	5830数据线
;PIN_5830_EN		---	5830使能线
;BIT_CHANNELFLAG	---	= 1表示当前使用信道1,  =0 表示当前使用信道0
;12.288
;5.79G	20 A0	04 EF	32 00	00 07	83 38
;5.80G	AB 80	04 EF	32 00	00 07	83 38
;16.3849M
;579
;00952009AF320000078338
;580
;00FD5009AF320000078338
;--------------------------------------------------------------------------
_FUN_HDLC_5830Init:
	CLR	Pin_5823BK_SCLK
	SETB	Pin_5823BK_CS	
	CALL	_FUN_HDLC_5822Init
	CALL	_FUN_HDLC_Frexiaodui
	RET
;-----------------------------------------------------
;SPI读写子程序
;入口：ACC
;出口：ACC
;-----------------------------------------------------
SPI_RW:
	CLR	Pin_5823BK_CS
	PUSH	AR7
	MOV	R7,#8
SPI_RW_1:	
	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;4
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;4
	CLR	Pin_5823BK_SCLK		;4
	
	DJNZ	R7,SPI_RW_1		;4
	CLR	Pin_5823BK_MOSI		;
	RLC	A			;
	POP	AR7			;
		
	RET
;////////////////////////////////////////////////////////	
SPI_R:	
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1

	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1

	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1
	
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1
	
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1
	
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1p
	
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1
	
	SETB	Pin_5823BK_SCLK		;4
	MOV	C,Pin_5823BK_MISO	;3
	CLR	Pin_5823BK_SCLK		;4
	RLC	A			;1
	
	RET
;--------------------------------------------------------------
;参数
;入口：	R5	要读的寄存器
;	R6	读出R6个字节
;	R7	读出字节存放地址指针
;	A	---	接收值
;--------------------------------------------------------------
SPI_Read_Reg:		;从R5所指向的BK5822寄存器读出R6个字节存放到指针R7所指向的内存(DATA/IDATA)
	CLR	Pin_5823BK_CS
	MOV	R2,#1;0
	DJNZ	R2,$

	MOV	A,R5
	CALL	SPI_W	;读地址命令
	
	MOV	A,R7
	MOV	R0,A
SPI_Read_Reg_1:
	MOV	A,#0
	CALL	SPI_R
	JB	BIT_BUFADDR,SPI_Read_Reg_movx
SPI_Read_Reg_mov:
	MOV	@R0,A
	jmp	SPI_Read_Reg_movov
SPI_Read_Reg_movx:
		;MOVX	@R0,A
	push	dph
	push	dpl
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph

SPI_Read_Reg_movov:
	INC	R0
	DJNZ	R6,SPI_Read_Reg_1
	MOV	R2,#1;0
	DJNZ	R2,$
	SETB	Pin_5823BK_CS
	
	RET	
;--------------------------------------------------------------
;参数
;	A	---	发送值
;--------------------------------------------------------------
SPI_W:
	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4
	
	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4

	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4

	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4

	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4

	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4

	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4


	RLC	A			;1
	MOV	Pin_5823BK_MOSI,C	;3
	SETB	Pin_5823BK_SCLK		;4
	CLR	Pin_5823BK_SCLK		;4
 
  	CLR	Pin_5823BK_MOSI
	RET
;-------------------------------------------------------
;从R5所指向的BK5822寄存器写入R6个字节,指针R7所指向的内存
;入口：	R5	要写的寄存器
;	R6	写入R6个字节
;	R7	写入字节存放地址指针
;出口：	R5	操作状态返回
;-------------------------------------------------------
SPI_Write_Reg:		;从R5所指向的BK5822寄存器写入R6个字节,指针R7所指向的外存(XDATA)
	CLR	Pin_5823BK_CS
	
	MOV	R2,#1
	DJNZ	R2,$
	
	MOV	A,R5
	ORL	A,#020H
	Call	SPI_W
	
	MOV	R5,A
	MOV	A,R7
	MOV	R0,A

SPI_Write_Reg_1:	
		;MOVX	A,@R0
	push	dph
	push	dpl		
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	pop	dpl
	pop	dph

	CALL	SPI_W
	INC	R0	
	DJNZ	R6,SPI_Write_Reg_1
	
	MOV	R2,#1
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS
	
	RET
;-----------------------------------------------------------------
;接收使能或禁止
;入口：	R7	1使能接收，0禁接收
;set REG15<1> 1 or 0
;从高字节开始
;-----------------------------------------------------------------
Rx_En:
	CLR	Pin_5823BK_CS
	
	MOV	R2,#10
	DJNZ	R2,$
	
	MOV	A,#15
	ORL	A,#020H		;写命令
	CALL	SPI_W

	MOV	DPTR,#RegArrOBU
				;15 * 4 = 60	寄存器15
	MOV	A,R7
	JNZ	Rx_En_1		;关接收
	
	MOV	A,#60
	MOVC	A,@A+DPTR
	ANL	A,#0FDH;1111 1101
	JMP	Rx_En_2
	
Rx_En_1:			;打开接收
	MOV	A,#60
	MOVC	A,@A+DPTR
	ORL	A,#002H

Rx_En_2:
	CALL	SPI_W
	
	MOV	A,#61
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#62
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#63
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	R2,#10
	DJNZ	R2,$	

	SETB	Pin_5823BK_CS	
	
	RET
;-----------------------------------------------------------
;发送载波使能或禁止
;入口：	R7	1使能接收，0禁接收
;set REG4<1,0>  1 or 0
;从低字节开始 16 17 18 19
;-----------------------------------------------------------------
Tx_Carrier_En:
	CLR	Pin_5823BK_CS
	
	mov	r2,#10
	djnz	r2,$
	
	MOV	A,#4
	ORL	A,#020H			;写命令
	CALL	SPI_W			;
	
	MOV	DPTR,#RegArrOBU		;
	MOV	A,R7			;
	JZ	Tx_Carrier_En_1		;
					;关闭发载波
Tx_Carrier_En_0:			;使能发载波				
	MOV	A,#19
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#18
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#17
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#16
	MOVC	A,@A+DPTR
	ANL	A,#11111101B;0FDH
	ANL	A,#11111110B;0FEH
	CALL	SPI_W
	
	mov	r2,#10
	djnz	r2,$
	
	SETB	Pin_5823BK_CS	
	RET
	
Tx_Carrier_En_1:	;使能发载波
	MOV	A,#19
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#18
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#17
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#16
	MOVC	A,@A+DPTR
	ORL	A,#00000010B;002H
	ORL	A,#00000001B;001H
	CALL	SPI_W
	
	mov	r2,#10
	djnz	r2,$
	
	SETB	Pin_5823BK_CS	
	RET	
;///////////////////////////////////////////////////////////////////
;0 调制接收
;1 包接收
Rx_Carrier_En:
	CLR	Pin_5823BK_CS
	
	mov	R2,#10
	djnz	R2,$
	
	MOV	A,#4
	ORL	A,#020H			;写命令
	CALL	SPI_W			;
	
	MOV	DPTR,#RegArrOBU		;
	MOV	A,R7			;
	JnZ	Rx_Carrier_En_1		;
;0 包接收
Rx_Carrier_En_0:			 			
	MOV	A,#19
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#18
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#17
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#16
	MOVC	A,@A+DPTR
	;orl	A,#00000010b
	anl	A,#11111110b	
	CALL	SPI_W
	
	mov	r2,#10
	djnz	r2,$
	
	SETB	Pin_5823BK_CS	
	RET
	
;1 调制接收
Rx_Carrier_En_1:	 
	MOV	A,#19
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#18
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#17
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#16
	MOVC	A,@A+DPTR
	orl	A,#00000001b
	CALL	SPI_W
	
	mov	r2,#10
	djnz	r2,$
	
	SETB	Pin_5823BK_CS	
	RET	
;///////////////////////////////////////////////////////////////////
;---------------------------------------------------------
;使能上电或关闭上电
;入口：	R7
;set REG9<0> 1 or 0
;从高字节开始
;---------------------------------------------------------
_Power_Up:
	CLR	Pin_5823BK_CS
	
	mov	r2,#10
	djnz	r2,$
		
	MOV	A,#9
	ORL	A,#020H			;写命令
	CALL	SPI_W
	
	MOV	DPTR,#RegArrOBU 	;9 * 4 = 36	寄存器15
	MOV	A,R7
	JNZ	Power_Up_1		;关接收
	
	MOV	A,#36
	MOVC	A,@A+DPTR
	ANL	A,#0FEH
	JMP	Power_Up_2
	
Power_Up_1:				;打开接收
	MOV	A,#36
	MOVC	A,@A+DPTR
	ORL	A,#001H

Power_Up_2:
	CALL	SPI_W
	
	MOV	A,#37
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#38
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#39
	MOVC	A,@A+DPTR
	CALL	SPI_W

	mov	r2,#10
	djnz	r2,$
	
	SETB	Pin_5823BK_CS
	
	RET
;---------------------------------------------------------
;唤醒使能或禁用
;入口：	R7
;set REG4<7> wkdisen 1 or 0
;从低字节开始 16 17 18 19
;---------------------------------------------------------
Wake_up:
	CLR	Pin_5823BK_CS
	
	MOV	A,#4
	ORL	A,#020H		;写命令
	CALL	SPI_RW

	MOV	DPTR,#RegArrOBU
				;4 * 4 = 16	寄存器4
	MOV	A,#19
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#18
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#17
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,R7
	JZ	Wake_up_1
	;WriteArr[3]&=0x7f;		;唤醒禁用
	MOV	A,#16
	MOVC	A,@A+DPTR
	ANL	A,#07FH
	CALL	SPI_RW
	
	SETB	Pin_5823BK_CS
	
	RET
	
Wake_up_1:				
	;WriteArr[3]|=0x80;		;唤醒使能
	MOV	A,#16
	MOVC	A,@A+DPTR
	ORL	A,#080H
	CALL	SPI_RW
	
	SETB	Pin_5823BK_CS
	
	RET
	
;------------------------------------------------------------
;进入待机模式
;	
;------------------------------------------------------------
_Enter_Idle_Mode:
	
	MOV	R7,#0
	CALL	Rx_En
	
	MOV	R2,#200
	djnz	R2,$
	MOV	R2,#100
	djnz	R2,$

	MOV	R7,#0
	CALL	Tx_Carrier_En
	
	MOV	R2,#200
	djnz	R2,$
	MOV	R2,#100
	djnz	R2,$
	
	MOV	R7,#1
	CALL	_Power_Up
	
	RET
;-----------------------------------------------------------
;进入睡眠模式
;-----------------------------------------------------------
_Enter_Sleep_Mode:
	
;	PUSH	AR7
;	PUSH	AR6
;	PUSH	AR5
;	PUSH	AR4
;	PUSH	AR3
;	PUSH	AR2
;	PUSH	AR1
;	PUSH	AR0
	
	MOV	R7,#00
	CALL	Rx_En
	
;	MOV	R2,#200
;	djnz	r2,$
;	MOV	R2,#100
;	djnz	r2,$
	
	MOV	R7,#000
	CALL	Tx_Carrier_En

;	MOV	R2,#200
;	djnz	r2,$
;	MOV	R2,#100
;	djnz	r2,$
	
	;=== soft wake end ===
	MOV	R5,#9
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	;写1
	MOV	R0,#XDATA_HOLD+1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00000100B;
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	MOV	R5,#9
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
	;写0
	MOV	R0,#XDATA_HOLD+1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	anl	A,#11111011B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	MOV	R5,#9
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg		
	

	MOV	R7,#0
	CALL	_Power_Up
	
	clr	PIN_WAVE_CHANNEL1
	
;	POP	AR0
;	POP	AR1
;	POP	AR2
;	POP	AR3
;	POP	AR4
;	POP	AR5
;	POP	AR6
;	POP	AR7		
	
	RET
;------------------------------------------------------------
;进入接收模式
;------------------------------------------------------------
_Enter_Receive_Mode:
	
	MOV	R7,#0
	CALL	Tx_Carrier_En
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	R2,$
	
	MOV	R7,#1
	CALL	_Power_Up
	
	MOV	R2,#200
	Djnz	R2,$
	MOV	R2,#100
	Djnz	R2,$
	
	MOV	R7,#1
	CALL	Rx_En
	
	RET
;------------------------------------------------------------
;进入发载波模式
;------------------------------------------------------------
_Enter_TX_Carrier_Mode:
	MOV	R7,#1
	CALL	_Power_Up
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$

	MOV	R7,#1
	CALL	Tx_Carrier_En
	RET
;------------------------------------------------------------
;进入唤醒模式
;------------------------------------------------------------
_Enable_Wake_Up:
	MOV	R7,#0
	CALL	Rx_En
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$

	MOV	R7,#0
	CALL	Tx_Carrier_En
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$
	
	MOV	R7,#0
	CALL	_Power_Up
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$
	
	MOV	R7,#1
	CALL	Wake_up
	RET
;------------------------------------------------------------
;关闭唤醒模式
;------------------------------------------------------------
_Disable_Wake_Up:
	MOV	R7,#0
	CALL	Rx_En
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$
	
	MOV	R7,#0
	CALL	_Power_Up
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$
	
	MOV	R7,#0
	CALL	Tx_Carrier_En
	
	MOV	R2,#200
	djnz	r2,$
	MOV	R2,#100
	djnz	r2,$
	
	MOV	R7,#0
	CALL	Wake_up
	RET

;---------------------------------------------------------
;发送DIO pin 数据流配置
;REG15[3:2] = 11	0-orl-0CH
;REG15[15] = 1		1-orl-80H
;REG4[1] = 0		0-anl-fdH
;REG4[22] = 1		2-orl-40H

;DB	03DH,0EFH,05CH,02CH,;//4 	DIO 发送
;DB 	0DFH,093H,074H,007H;,//15	DIO 发送
;---------------------------------------------------------
;_TXDIOpin:
;	CLR	Pin_5823BK_CS
;	MOV	R2,#10
;	DJNZ	R2,$
	
;	MOV	DPTR,#RegArrOBU

;	MOV	A,#15
;	ORL	A,#020H		;写命令
;	CALL	SPI_RW
	
;	MOV	A,#60
;	MOVC	A,@A+DPTR
;	ORL	A,#00CH
;	CALL	SPI_RW
	
;	MOV	A,#61
;	MOVC	A,@A+DPTR
;	ORL	A,#080H
;	CALL	SPI_RW
	
;	MOV	A,#62
;	MOVC	A,@A+DPTR
;	CALL	SPI_RW
	
;	MOV	A,#63
;	MOVC	A,@A+DPTR
;	CALL	SPI_RW
	
;	MOV	R2,#10
;	DJNZ	R2,$
;	SETB	Pin_5823BK_CS	
	
;	MOV	R2,#200
;	DJNZ	R2,$
;	MOV	R2,#100
;	DJNZ	R2,$
	
;	CLR	Pin_5823BK_CS
;	mov	r2,#10
;	djnz	r2,$
	
;	MOV	A,#4
;	ORL	A,#020H		;写命令
;	CALL	SPI_RW

;	MOV	DPTR,#RegArrOBU
					;关闭发载波
;	MOV	A,#19
;	MOVC	A,@A+DPTR
;	CALL	SPI_RW
	
;	MOV	A,#18
;	MOVC	A,@A+DPTR
;	ORL	A,#040H
;	CALL	SPI_RW
	
;	MOV	A,#17
;	MOVC	A,@A+DPTR
;	CALL	SPI_RW
	
;	MOV	A,#16
;	MOVC	A,@A+DPTR
;	ANL	A,#0FDH
;	CALL	SPI_RW
	
;	mov	r2,#10
;	djnz	r2,$
	
;	SETB	Pin_5823BK_CS	
	;-----SETB	TX_SW_BK	;发射供电
	
;	RET
;-----------------------------------------------------------------
;复位或使能BK5822 SPI寄存器
;入口：	R7	1使能，0复位
;set REG15<0> 1 or 0
;从高字节开始
;-----------------------------------------------------------------
_BK_SPIRST:		;复位或使能 BK5822 SPI寄存器	R7:1 使能，0 复位	
	CLR	Pin_5823BK_CS
	
	MOV	A,#15
	ORL	A,#020H			;写命令
	CALL	SPI_RW
	
	MOV	DPTR,#RegArrOBU 	;15 * 4 = 60	寄存器15
	MOV	A,R7
	JNZ	BK_SPIRST_1		;0复位
	
	MOV	A,#60
	MOVC	A,@A+DPTR
	ANL	A,#0FEH
	JMP	BK_SPIRST_2
	
BK_SPIRST_1:				;1使能
	MOV	A,#60
	MOVC	A,@A+DPTR
	ORL	A,#001H
BK_SPIRST_2:
	CALL	SPI_RW
	
	MOV	A,#61
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#62
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#63
	MOVC	A,@A+DPTR
	CALL	SPI_RW

	SETB	Pin_5823BK_CS
	
	RET
;-----------------------------------------------------------
_BK5822_RST:	;复位BK5822
;------rst SPI------------------------
	MOV	R7,#0
	CALL	_BK_SPIRST
	
;	MOV	R7,#255						; 5;50
;	djnz	r7,$
	MOV	R7,#1;10						; 5;50
	CALL	BK5822_1MSDELAY
	
	MOV	R7,#1
	CALL	_BK_SPIRST

	RET
;----------------------------------------
;
;----------------------------------------
BK5822_1MSDELAY:
BK5822_Loop:
	MOV	R5,#24
BK5822_Loop1:
	MOV	R6,#255
BK5822_Loop2:
	DJNZ	R6,BK5822_Loop2
	DJNZ	R5,BK5822_Loop1
	DJNZ	R7,BK5822_Loop
	
BK5822_OVER:
	
	RET
;------------------------------------------------------------
;初始化BK5822
;------------------------------------------------------------
_AutoASKReg:
	clr	Pin_5823BK_SCLK
	clr	Pin_5823BK_MOSI
	SETB	Pin_5823BK_CS
	MOV	R2,#200
	DJNZ	R2,$
	MOV	DPTR,#RegArrOBU
	;0---8
	MOV	R7,#0		;第几个字节		
	MOV	R6,#9		;寄存器个数
	MOV	R5,#0		;寄存器地址号
AutoASKReg_08:
	;300=48us
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$
	
	CLR	Pin_5823BK_CS		
	MOV	A,R5
	ORL	A,#020H		;写命令
	CALL	SPI_W
	
	MOV	A,#3
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#2
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#1
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#0
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS
	
	MOV	A,#4
	ADD	A,R7
	MOV	R7,A
	INC	R5
	DJNZ	R6,AutoASKReg_08
;-----------------------------------------------
	;9---15
	MOV	R7,#36		;第几个字节	
	MOV	R6,#7;8		;寄存器个数
	MOV	R5,#9		;寄存器地址号
AutoASKReg_916:
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$	
	CLR	Pin_5823BK_CS
	MOV	R2,#10
	DJNZ	R2,$
				
	MOV	A,R5
	ORL	A,#020H		;写命令
	CALL	SPI_W
	
	MOV	A,#0
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#1
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#2
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	A,#3
	ADD	A,R7
	MOVC	A,@A+DPTR
	CALL	SPI_W
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS
	
	MOV	A,#4
	ADD	A,R7
	MOV	R7,A
	INC	R5
	DJNZ	R6,AutoASKReg_916
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$

	CLR	Pin_5823BK_CS
	
	MOV	R2,#10
	DJNZ	R2,$
	
	MOV	DPTR,#RegArrASKAnalogReg17
	
	MOV	A,#17
	ORL	A,#020H		;写命令
	CALL	SPI_W
	
	MOV	R6,#14;13		;寄存器字节个数为14个，先初始化13--1个，再初始化0
	mov	r2,#0
AutoASKReg_17:
	MOV	a,r2
	MOVC	A,@A+DPTR
	CALL	SPI_W
	INC	r2
	DJNZ	R6,AutoASKReg_17
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$
	
	
	
	
	CLR	Pin_5823BK_CS
	MOV	R2,#10
	DJNZ	R2,$
	MOV	DPTR,#RegArrASKAnalogReg18
	
	MOV	A,#18
	ORL	A,#020H		;写命令
	CALL	SPI_W
	
	
	
	MOV	R6,#11;10		;寄存器字节个数为11个，先初始化11--1个，再初始化0
	MOV	R2,#0
AutoASKReg_18:
	MOV	A,R2
	MOVC	A,@A+DPTR
	CALL	SPI_W
	INC	R2
	DJNZ	R6,AutoASKReg_18
	
	MOV	R2,#10
	DJNZ	R2,$
	SETB	Pin_5823BK_CS	
	;ret	
	call	wkoup_sj	;唤醒校准
		
	MOV	R7,#6
	CALL	BK5822_1MSDELAY	
	;------------------------------------
	;唤醒校准
	;把寄存器reg7的数据放到DATA_RXBUF+5
	MOV	DPTR,#RegArrOBU
	MOV	R0,#DATA_RXBUF+5
	MOV	A,#31
	MOVC	A,@A+DPTR
	MOV	@R0,A
	
	INC	R0
	MOV	A,#30
	MOVC	A,@A+DPTR
	MOV	@R0,A
	
	INC	R0
	MOV	A,#29
	MOVC	A,@A+DPTR
	MOV	@R0,A
	
	INC	R0
	MOV	A,#28
	MOVC	A,@A+DPTR
	MOV	@R0,A
	
	MOV	R5,#7
	MOV	R6,#4
	MOV	R7,#DATA_RXBUF
	clr	BIT_BUFADDR
	CALL	SPI_Read_Reg		;从R5所指向的BK5822寄存器读出R6个字节存放到指针R7所指向的内存(DATA/IDATA)
	
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	CJNE	A,#0AH,$+3
	JNC	WKO_SJ_1
	
	MOV	R0,#DATA_RXBUF+5	
	MOV	A,@R0
	ANL	A,#07FH		;0111
	JMP	WKO_SJ_2
	
WKO_SJ_1:
	MOV	R0,#DATA_RXBUF+5	
	MOV	A,@R0
WKO_SJ_2:	
	ORL	A,#40H
	MOV	@R0,A
	CALL	WIRTE_REG7	;写寄存器7，要写的数据在DATA_RXBUF
	call	wkoup_sj	;唤醒校准
	MOV	R7,#6
	CALL	BK5822_1MSDELAY

	MOV	R5,#7
	MOV	R6,#4
	MOV	R7,#DATA_RXBUF
	CLR	BIT_BUFADDR
	CALL	SPI_Read_Reg		;从R5所指向的BK5822寄存器读出R6个字节存放到指针R7所指向的内存(DATA/IDATA)
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	CJNE	A,#0AH,$+3
	JNC	WKO_SJ_3
	MOV	R0,#DATA_RXBUF+5	
	MOV	A,@R0
	ANL	A,#0BFH		;1011
	JMP	WKO_SJ_4
WKO_SJ_3:
	MOV	R0,#DATA_RXBUF+5	
	MOV	A,@R0
WKO_SJ_4:	
	ORL	A,#20H
	MOV	@R0,A
	CALL	WIRTE_REG7	;写寄存器7，要写的数据在DATA_RXBUF
	call	wkoup_sj	;唤醒校准
	MOV	R7,#6
	CALL	BK5822_1MSDELAY	
	
	MOV	R5,#7
	MOV	R6,#4
	MOV	R7,#DATA_RXBUF
	CLR	BIT_BUFADDR
	CALL	SPI_Read_Reg		;从R5所指向的BK5822寄存器读出R6个字节存放到指针R7所指向的内存(DATA/IDATA)
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	CJNE	A,#0AH,$+3
	JNC	WKO_SJ_5
	MOV	R0,#DATA_RXBUF+5	
	MOV	A,@R0
	ANL	A,#0DFH		;1101
	JMP	WKO_SJ_6
WKO_SJ_5:
	MOV	R0,#DATA_RXBUF+5	
	MOV	A,@R0
WKO_SJ_6:
	MOV	@R0,A
	CALL	WIRTE_REG7	;写寄存器7，要写的数据在DATA_RXBUF
	call	wkoup_sj	;唤醒校准
	MOV	R7,#6
	CALL	BK5822_1MSDELAY	
	
	MOV	R5,#7
	MOV	R6,#4
	MOV	R7,#DATA_RXBUF
	CLR	BIT_BUFADDR
	CALL	SPI_Read_Reg		;从R5所指向的BK5822寄存器读出R6个字节存放到指针R7所指向的内存(DATA/IDATA)
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0

	RET
;======================================================
wkoup_sj:	;唤醒校准	
;//toggle reg15 bit 28	
;WriteArr[3]=WriteArr[3]|0x10;
	MOV	R2,#240
	DJNZ	R2,$
	MOV	R2,#130
	DJNZ	R2,$

	MOV	DPTR,#RegArrOBU
	
	CLR	Pin_5823BK_CS
	
	MOV	R2,#10
	DJNZ	R2,$

	MOV	A,#15
	ORL	A,#020H		;写命令
	CALL	SPI_RW
	
	
	MOV	A,#60
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#61
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#62
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#63
	MOVC	A,@A+DPTR
	ORL	A,#010H
	CALL	SPI_RW
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS	

	MOV	R7,#4	;2mS
	CALL	BK5822_1MSDELAY	

	MOV	R2,#240
	DJNZ	R2,$
	MOV	R2,#130
	DJNZ	R2,$	

	MOV	A,#15
	ORL	A,#020H
	CALL	SPI_RW
	
	
	MOV	A,#60
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#61
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#62
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#63
	MOVC	A,@A+DPTR
	ANL	A,#0EFH
	CALL	SPI_RW
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS
	RET
;======================================================
WIRTE_REG7:	;写寄存器7，要写的数据在DATA_RXBUF	
	MOV	A,#7
	ORL	A,#020H		;写命令
	CALL	SPI_RW
				;4 * 7 = 28	寄存器7
	MOV	R0,#DATA_RXBUF+5
	MOV	A,@R0
	CALL	SPI_RW
	
	INC	R0
	MOV	A,@R0
	CALL	SPI_RW
	
	INC	R0
	MOV	A,@R0
	CALL	SPI_RW
	
	INC	R0
	MOV	A,@R0
	CALL	SPI_RW
	
	SETB	Pin_5823BK_CS
	
	RET			
;=====================================================
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$

	MOV	DPTR,#RegArrOBU	

	MOV	A,#15
	ORL	A,#020H		;写命令
	CALL	SPI_RW
	
	MOV	A,#60
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#61
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#62
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#63
	MOVC	A,@A+DPTR
	ORL	A,#010H
	CALL	SPI_RW
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS	

	MOV	R7,#20
	CALL	BK5822_1MSDELAY	
;	WriteArr[3]=WriteArr[3]&0xef;
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$
	
	MOV	A,#15
	ORL	A,#020H		;写命令
	CALL	SPI_RW
	
	MOV	A,#60
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#61
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#62
	MOVC	A,@A+DPTR
	CALL	SPI_RW
	
	MOV	A,#63
	MOVC	A,@A+DPTR
	ANL	A,#0EFH
	CALL	SPI_RW
	
	MOV	R2,#10
	DJNZ	R2,$
	
	SETB	Pin_5823BK_CS	
	
	MOV	R7,#20
	CALL	BK5822_1MSDELAY
	
	RET	
;//////////////////////////////////////////////////////	
_FUN_HDLC_5822Init:
	
	CALL	_BK5822_RST
;	MOV	R7,#1
;	CALL	_FUN_LIB_DELAY	
	
	CALL	_AutoASKReg
;	MOV	R7,#3
;	CALL	_FUN_LIB_DELAY
	RET
;//////////////////////////////////////////////////////		
;/////////////////////////////////////////////////////////////////////////////////////
;将reg5<26>先写 1 ,再写 0 ，做频率效准
;20 21 22 23
;/////////////////////////////////////////////////////////////////////////////////////
_FUN_HDLC_Frexiaodui:
	
	MOV	DPTR,#RegArrOBU	
	mov	r0,#XDATA_HOLD
	MOV	A,#20
	MOVC	A,@A+DPTR
	
		;MOVX	@R0,A
	push	dph
	push	dpl
	
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph
	
	INC	R0
	MOV	A,#21
	MOVC	A,@A+DPTR
		;MOVX	@R0,A
	push	dph
	push	dpl		
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph

	INC	R0
	MOV	A,#22
	MOVC	A,@A+DPTR
		;MOVX	@R0,A
	push	dph
	push	dpl		
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph
	INC	R0
	MOV	A,#23
	MOVC	A,@A+DPTR
		;MOVX	@R0,A
	push	dph
	push	dpl		
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	dpl
	pop	dph
	CLR	Pin_5823BK_CS
	
	MOV	R2,#10
	DJNZ	R2,$
	
	MOV	A,#5
	ORL	A,#020H		;写命令
	CALL	SPI_W		
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00000100B
	CALL	SPI_W
	
	MOV	R0,#XDATA_HOLD+2
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CALL	SPI_W	
	
	MOV	R0,#XDATA_HOLD+1
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CALL	SPI_W	
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CALL	SPI_W
	
	MOV	R2,#10
	DJNZ	R2,$	
	SETB	Pin_5823BK_CS	
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$

	CLR	Pin_5823BK_CS
	
	MOV	R2,#10
	DJNZ	R2,$
	
	MOV	A,#5
	ORL	A,#020H		;写命令
	CALL	SPI_W		

	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ANL	A,#11111011B
	CALL	SPI_W	
	
	MOV	R0,#XDATA_HOLD+2
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CALL	SPI_W	
	
	MOV	R0,#XDATA_HOLD+1
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CALL	SPI_W	
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CALL	SPI_W
	
	MOV	R2,#10
	DJNZ	R2,$	
	SETB	Pin_5823BK_CS	
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$

	RET
	
;/////////////////////////////////////////////////////////////////////////////////////	

_FUN_HDLC_RXSetMMI:	
	;已接收到数据，先清，防止收到上一次的数据
	JB	Pin_5823BK_IRQ,HDLC_5823_RXSetMMILOOPS
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
;	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
HDLC_5823_RXSetMMILOOPS:
	;开接 收 使能
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	orl	A,#00000010B; 防止AGC锁死及防止5823接收没有使能
		;MOVX	@R0,A
;	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
_HDLC_RXSetMMIRXLOOP:
	setb	ea

_HDLC_RXSetMMIRXLOOP02:
	JB	Pin_5823BK_IRQ,_HDLC_RXSetMMIRXLOOP02	
	clr	ea
	;=== 读接收标记寄存器 ===
	;reg6.2 =1 表示接收出错[解码出错，或CRC出错这一位都为置]
	;reg6.1 = 1 表示接收到数据	
	MOV	R5,#06h
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	;接收出错标记
	MOV	C,ACC.2
	JC	_HDLC_RXSetMMIClearRXEr
	
	;接收正克标记
	MOV	C,ACC.1
	JC	_HDLC_RXSetMMIReceviceData
	
	;接收出错，清reg15.26 接收出错标记，不清，则5823会处在一直在idle模式,irq脚会一直为低
	;注意清是用 1 清，不是 0 
	;注意接收出错标记，不清，则5823会处在一直在idle模式,irq脚会一直为低
	
_HDLC_RXSetMMIClearRXEr:
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
;	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
	JMP	_HDLC_RXSetMMIRXLOOP
	
;///////////////////////////////////////////////////////////////////////////////////////////
	;接收到数据，
	;读Reg5<0~7>，FIFO 接收长度
	;如果接收到的数据长度为 0
	; 	清Reg 15.25 
	;	否则，读空 FIFO [Reg16]
	;注意清是用 1 清，不是 0 
	;注意接收标记，不清，则5823会处在一直在idle模式,irq脚会一直为低
	;注意读空FIFO或清接收标记，都会将5823从idle模式转成接收模式
;///////////////////////////////////////////////////////////////////////////////////////////
_HDLC_RXSetMMIReceviceData:	
	;=== 关接收使能 ===
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	anl	A,#11111101B
		;MOVX	@R0,A
	;MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg 
	
	;=== 读接收数据长度 ===
	MOV	R5,#05h
	MOV	R6,#04h
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
 	JNZ	_HDLC_RXSetMMIRXFIFO
 	;接收度为0时，清接收位
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	;MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#00001111B
		;MOVX	@R0,A
;	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
	JMP	_HDLC_RXSetMMIRXLOOP
	
_HDLC_RXSetMMIRXFIFO:;减CRC 长度后,接收长度是否大于0
	dec	a
	dec	a
	jz	_HDLC_RXSetMMIClearRXEr
	
	CJNE	A,#129,$+3
	JC	hdlc_5823_RXSETFIFOLENOK
	JMP	_HDLC_RXSetMMIClearRXEr
hdlc_5823_RXSETFIFOLENOK:	
	mov	r0,#DATA_DSRCRXLEN
	mov	@r0,a
	;=== 接数据 ===
	MOV	R5,#16
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R6,A		

	CLR	BIT_BUFADDR	
	MOV	R7,#DATA_RXBUF
	PUSH	AR6
;入口：	R5	要读的寄存器
;	R6	读出R6个字节
;	R7	读出字节存放地址指针	
	CALL	SPI_Read_Reg
	POP	AR6
	
	mov	r0,#DATA_DSRCRXLEN
	mov	a,@r0
	mov	ar3,a
	
	RET
;--------------------------------------------------------------
;=0关调置;=1开调置(把DIO设输入)
;--------------------------------------------------------------
;_FUN_HDLC_TiaoZhi:
;	PUSH	AR7
	
;	MOV	R5,#15
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	SETB	BIT_BUFADDR
;	CALL	SPI_Read_Reg
	
;	MOV	R0,#XDATA_HOLD+1
;		;MOVX	A,@R0

;	MOV	B,A

;	POP	AR7	
;	MOV	A,R7
;	MOV	C,ACC.0
;	MOV	A,B
;	MOV	ACC.7,C	
;		;MOVX	@R0,A


;	MOV	R5,#15
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	CALL	SPI_Write_Reg

;	RET
;---------------------------------------------------------
;改变发射通道
;---------------------------------------------------------------------------------------------
;描述:更改通道
;外部参数
;BIT_CHANNELFLAG	---	=1表示当前使用信道1,=0表示当前使用信道0
;REG1
;从低字节开始
;---------------------------------------------------------
_FUN_HDLC_CHANGECHANNEL:
	JB 	BIT_CHANNELFLAG,HDLC_CHANGECHANNEL_1
				;5.79GHz  由020H,0e6H,03aH,0ECH改050H,0e4H,03aH,0ecH ;5.79G 
	CLR	Pin_5823BK_CS
	MOV	R2,#1;0
	DJNZ	R2,$
	
	MOV	A,#1
	ORL	A,#020H		;写命令
	CALL	SPI_W

	MOV	A,#0ECH
	CALL	SPI_W
	
	MOV	A,#03AH
	CALL	SPI_W
	
	MOV	A,#0E4H
	CALL	SPI_W
	
	MOV	A,#050H
	CALL	SPI_W
	
	MOV	R2,#1;0
	DJNZ	R2,$
	SETB	Pin_5823BK_CS
	
	MOV	R2,#1;200
	DJNZ	R2,$
	MOV	R2,#1;00
	DJNZ	R2,$
	
	RET
	
HDLC_CHANGECHANNEL_1:		;5.8GHz	020H,000H,03bH,0ECH 改040H 0FEH 03AH 0ECH,
	CLR	Pin_5823BK_CS
	MOV	R2,#1;0
	DJNZ	R2,$
	
	MOV	A,#1
	ORL	A,#020H		;写命令
	CALL	SPI_W

	MOV	A,#0ECH
	CALL	SPI_W
	
	MOV	A,#03AH
	CALL	SPI_W
	
	MOV	A,#0FEH
	CALL	SPI_W
	
	MOV	A,#040H
	CALL	SPI_W
	
	MOV	R2,#1;0
	DJNZ	R2,$
	SETB	Pin_5823BK_CS
	MOV	R2,#1;200
	DJNZ	R2,$
	MOV	R2,#1;00
	DJNZ	R2,$
	
	RET
;-----------------------------------------------------------
;关接收使能
;清接收标记
_FUN_HDLC_CLOSECLR:
	
	CALL	_BK5822_RST
	MOV	R7,#0
	CALL	Rx_En
	
	RET	
	;=== 关接收使能 ===
;	MOV	R7,#0
;	CALL	Rx_En
	;=== 清标记=== 
;	MOV	R5,#15
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	SETB	BIT_BUFADDR
;	CALL	SPI_Read_Reg
	;清接收标记
;	MOV	R0,#XDATA_HOLD+3
;		;MOVX	A,@R0

;	ORL	A,#00001111B
;		;MOVX	@R0,A


	;关接收使能
	;MOV	R0,#XDATA_HOLD
	;	;MOVX	A,@R0

	;anl	A,#11111101B
	;	;MOVX	@R0,A


;	MOV	R5,#15
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	CALL	SPI_Write_Reg
	
	;=== soft wake end ===
;	MOV	R5,#9
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	SETB	BIT_BUFADDR
;	CALL	SPI_Read_Reg
	
	;写1
;	MOV	R0,#XDATA_HOLD+2
;		;MOVX	A,@R0

;	ORL	A,#00000100B
;		;MOVX	@R0,A

;	MOV	R5,#15
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	CALL	SPI_Write_Reg
	
	;写0
;	MOV	R0,#XDATA_HOLD+2
;		;MOVX	A,@R0

;	anl	A,#11111011B
;		;MOVX	@R0,A

;	MOV	R5,#15
;	MOV	R6,#4
;	MOV	R7,#XDATA_HOLD
;	CALL	SPI_Write_Reg
;	RET
;-----------------------------------------------------------
;	读reg9寄存器，查看5823是否Sleep
;返回值
;c	=0 sleep
;	=1 no sleep
;-----------------------------------------------------------
_FUN_HDLC_ISSleepMod:
	;=== 关接收使能 ===
	MOV	R5,#09
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	;关接收使能
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	mov	c,acc.0
	RET
;-----------------------------------------------------------
;	检查5823 reg9~18写的是否正确
;返回值
;	R7=0 正确,=FF 不正确
;-----------------------------------------------------------
_FUN_HDLC_CheckReg9To18:
	;比较reg9 ~ reg15
	MOV	DPTR,#RegArrOBU14
	MOV	R2,#6
HDLC_CheckReg9To18_LOOP:
	PUSH	AR2

	MOV	A,R2
	ADD	A,#8
	MOV	R5,A
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R7,#XDATA_HOLD+4
	MOV	R3,#04	
	CALL	_FUN_LIB_FLASHTOXDATALen
		
	MOV	R0,#XDATA_HOLD
	MOV	R1,#XDATA_HOLD+4
	MOV	R3,#4
HDLC_CheckReg9To18_CompLOOP:
		;MOVX	A,@R0
	push	dph
	push	dpl
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R1
;	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	pop	dpl
	pop	dph
	XRL	A,B
	JZ	HDLC_CheckReg9To18_CompCon
	POP	AR2
	JMP	HDLC_CheckReg9To18_ERR
HDLC_CheckReg9To18_CompCon:	
	INC	R0
	INC	R1
	DJNZ	R3,HDLC_CheckReg9To18_CompLOOP

	CLR	C
	MOV	A,#4
	MOV	B,A
	MOV	A,DPL	
	SUBB	A,B
	MOV	DPL,A
	
	CLR	A
	MOV	B,A
	MOV	A,DPH
	SUBB	A,B
	MOV	DPH,A
	POP	AR2
	DJNZ	R2,HDLC_CheckReg9To18_LOOP
	;=== 比较reg17 ===
	MOV	R5,#17
	MOV	R6,#14
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	DPTR,#RegArrASKAnalogReg17
	MOV	R7,#XDATA_HOLD+14
	MOV	R3,#14
	CALL	_FUN_LIB_FLASHTOXDATALen
	
	MOV	R0,#XDATA_HOLD
	MOV	R1,#XDATA_HOLD+14
	MOV	R3,#14
HDLC_CheckReg9To18_Comp17LOOP:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	XRL	A,B
	JZ	HDLC_CheckReg9To18_Comp17Con
	POP	AR3
	JMP	HDLC_CheckReg9To18_ERR
HDLC_CheckReg9To18_Comp17Con:
	INC	R0
	INC	R1
	DJNZ	R3,HDLC_CheckReg9To18_Comp17LOOP
	;=== 比较 Reg18 ===
	MOV	R5,#18
	MOV	R6,#11
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	DPTR,#RegArrASKAnalogReg18
	MOV	R7,#XDATA_HOLD+11
	MOV	R3,#11
	CALL	_FUN_LIB_FLASHTOXDATALen
	
	MOV	R0,#XDATA_HOLD
	MOV	R1,#XDATA_HOLD+11
	MOV	R3,#11
HDLC_CheckReg9To18_Comp18LOOP:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	XRL	A,B
	JZ	HDLC_CheckReg9To18_Comp18Con
	POP	AR3
	JMP	HDLC_CheckReg9To18_ERR
HDLC_CheckReg9To18_Comp18Con:	
	INC	R0
	INC	R1
	DJNZ	R3,HDLC_CheckReg9To18_Comp18LOOP
	
	MOV	R7,#CONST_STATE_TRUE
	RET
HDLC_CheckReg9To18_ERR:
	MOV	R7,#CONST_STATE_FALSE
	RET
;-----------------------------------------------------------
;REG4.0
;	1 Normal
;	0 CW
;R7	=1 NORMAL
;R7	=0 CW
_FUN_HDLC_SWRX:
	
	PUSH	AR7
	MOV	R5,#4
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+3
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	POP	AR7
	
	MOV	A,R7
	JNZ	HDLC_SWRX_1
HDLC_SWRX_0:
	ANL	A,#11111110B
	JMP	HDLC_SWRX_01OVER
HDLC_SWRX_1:
	ORL	A,#00000001B
HDLC_SWRX_01OVER:
	
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	MOV	R5,#4
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
	RET
	
;////////////////////////////////////////////////////////////////////////////////
;REG15.15 = 0 OUTPUT
;REG15.15 = 1 INPUT
;R7
_FUN_HOLD_DIOPOINT:
	
	PUSH	AR7
	;开接收使能
	MOV	R5,#15
	MOV	R6,#4
	MOV	R7,#XDATA_HOLD
	SETB	BIT_BUFADDR
	CALL	SPI_Read_Reg
	
	MOV	R0,#XDATA_HOLD+1
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	
	POP	AR7
	
	CJNE	R7,#00,HOLD_DIOPOINT_1
HOLD_DIOPOINT_0:
	ANL	A,#01111111B
	JMP	HOLD_DIOPOINT_10
HOLD_DIOPOINT_1:
	ORL	A,#10000000B
HOLD_DIOPOINT_10:
	
	MOV 	DPL,R0
	MOVX 	@DPTR,A
	
	MOV	R5,#15
	MOV	R6,#04
	MOV	R7,#XDATA_HOLD
	CALL	SPI_Write_Reg
	
	RET
;////////////////////////////////////////////////////////////////////////////////

;///////////////////////////////
_Write_18_H:
	
	CLR	Pin_5823BK_CS	
 
 
	mov	r2,#10
	djnz	r2,$
	
	SETB	Pin_5823BK_CS

	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$
	
	CLR	Pin_5823BK_CS
	MOV	R2,#10
	DJNZ	R2,$
	MOV	DPTR,#RegArrASKAnalogReg18_H
	
	MOV	A,#18
	ORL	A,#020H		;写命令
	CALL	SPI_W
	
	
	
	MOV	R6,#11;10		;寄存器字节个数为11个，先初始化11--1个，再初始化0
	MOV	R2,#0
_Write_18_H_Loop:
	MOV	A,R2
	MOVC	A,@A+DPTR
	CALL	SPI_W
	INC	R2
	DJNZ	R6,_Write_18_H_Loop
	
	MOV	R2,#10
	DJNZ	R2,$
	SETB	Pin_5823BK_CS		
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$


	RET
	
;//////////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////////////////////////////
	
_Write_18_L:
	;ret
 
	
	
	
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$
	
	CLR	Pin_5823BK_CS
	MOV	R2,#10
	DJNZ	R2,$
	MOV	DPTR,#RegArrASKAnalogReg18_L
	
	MOV	A,#18
	ORL	A,#020H		;写命令
	CALL	SPI_W
	
	
	
	MOV	R6,#11;10		;寄存器字节个数为11个，先初始化11--1个，再初始化0
	MOV	R2,#0
_Write_18_L_Loop:
	MOV	A,R2
	MOVC	A,@A+DPTR
	CALL	SPI_W
	INC	R2
	DJNZ	R6,_Write_18_L_Loop
	
	MOV	R2,#10
	DJNZ	R2,$
	SETB	Pin_5823BK_CS		
	
	MOV	R2,#200
	DJNZ	R2,$
	MOV	R2,#100
	DJNZ	R2,$
	
	RET	



 


	END


