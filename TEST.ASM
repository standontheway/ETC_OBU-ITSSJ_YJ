NAME	TEST
	
$INCLUDE(TEST.INC)
$INCLUDE(COMMON.INC)
	
	RSEG	?pr?TEST?Mater
	USING	0
	
;//////////////////////////////////////////////////////////////////////////////////////////////////
;_FUN_TEST_Master
;描述:OBU测试程序段
;改

;//////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_Master:
	
	;RET	
	;CALL	_FUN_TEST_TESTSOFTRX			;软串口测试接收函数
	;CALL	_FUN_Contact_CHANGEBAUD
	;CALL	_FUN_TEST_TESTSOFTTX			;软串口测试发送函数
	;CALL	_FUN_TEST_TESTSOFTTX2
	;CALL	_FUN_TEST_TESTHARDSERIALTXRX		;硬串口中断测试程序
	
	;CALL	_FUN_TEST_HARDTXTEST			;硬串口发送
	;CALL	_FUN_TEST_HARDRXTEST			;硬串口接收数据
	;CALL	_FUN_TEST_INITTEST			;复位卡片[采用软串口操作]
	;CALL	_FUN_TEST_ContactT1			;测试CPU卡T1协议指令
	;CALL	_FUN_TEST_OPRET0MODE2			;测试CPU卡T0协议指令
	;CALL	_FUN_TEST_OPRET0MODE1			;测试CPU卡T0协议指令
	;CALL	_FUN_TEST_OPRET0MODE			;测试CPU卡协议指令	
	;CALL	_FUN_TEST_PPS				;测试PPS卡片
	;CALL	_FUN_TEST_HDLCTX			;测试HDLC发送程序
	;CALL	_FUN_TEST_HDLCRX			;测试HDLC接收程序
	;CALL	_FUN_TEST_HDLCRXTX			;测试HDLC接收发送程序
	;CALL	_FUN_TEST_COLLIGATETEST			;综合HDLC测试
	;CALL	_FUN_TEST_DISPLAYMONEY			;测试CLD
	;CALL	_FUN_TEST_GETCRC			;测试CRC
	;CALL	_FUN_TEST_HDLCSERTX			;HDLC及硬串口接收综合测试
	
	;CALL	_FUN_TEST_HDLCPPS			;HDLC及PPS综合测试	
	;CALL	_FUN_TEST_ESAMRST			;ESAM复位
	;CALL	_FUN_TEST_ESAMOPR			;ESAM操作
	;CALL	_FUN_TEST_ESAMHDLC			;HDLC及ESAM综合测试
	;CALL	_FUN_TEST_ESAMVehicle			;ESAM卡读车辆信息文件
	
	;CALL	_FUN_TEST_EFALSH			;测试擦除falsh
	;CALL	_FUN_TEST_WFALSH			;测试写falsh
	;CALL	_FUN_TEST_RFALSH			;测试读falsh
	
	;CALL	_FUN_TEST_FALSHOBUFILE			;	
	;CALL	_FUN_TEST_CPUAPP			;测试CPU 应用函数	
	;JMP	_FUN_TEST_DSRCGetSecure	
	;CALL	_FUN_LIB_BEEP				;响铃	
	;CALL	_FUN_TEST_WRITE0019			;测试0019文件写	
	;CALL	_FUN_TEST_NEWT0				;测试新T0卡	
	;CALL	_FUN_TEST_PL				;频率测试	
	;CALL	TEST_PL_JLContact			;压力测试CPU卡指令	
	;CALL	_FUN_TEST_BEEP				;响铃测试
	
	;CALL	_FUN_TEST_MF				;MF卡测试	
	;CALL	_FUN_TEST_PRO				;PRO卡测试
	;CALL	_FUN_TEST_MFComplex			;认证MF测试
	;CALL	_FUN_TEST_PROCHANNEL			;PRO卡通道函数测试
	;---以上测试程序是60版前---	
	;CALL	_FUN_TEST_PROZH				;PRO卡综合测试
	;CALL	_FUN_TEST_CONTACTUSER			;测试接触式用户卡
	;CALL	_FUN_TEST_CONTACTESAM			;测试接触式ESAM卡
	;CALL	_FUN_TEST_SUBB				;带进位的减法
	;CALL	_FUN_TEST_PRO2				;PRO卡测试	
	;CALL	_FUN_TEST_PCSerial			;PC串口通讯 TX
	;CALL	_FUN_TEST_PCSerial2			;PC串口通讯 RX
	;CALL	_FUN_TEST_IssueTX			;发行发送程序	
	;CALL	_FUN_TEST_IssueRX			;发行接收程序
	;call	_FUN_TEST_230KTX
	;call	_FUN_TEST_initcard
	;CALL	_FUN_TEST_LCDACT
	;CALL	_FUN_TEST_FB
	;CALL	_FUN_TEST_TZ
	;CALL	_fun_test_randdelay
	;CALL	_FUN_TEST_BF
	;CALL	_FUN_TEST_TXPro02	
	;CALL	_FUN_TEST_HDLCTX
	;CALL	_FUN_TEST_GSM	
	;CALL	_FUN_TEST_GSM02
	;CALL	_FUN_TEST_HDLC
	;CALL	_FUN_TEST_HDLC02
	;CALL	_FUN_TEST_Card
	;CALL	_FUN_TEST_Card02
	;CALL	_fun_test_lcd
	
	;CALL	_FUN_TEST_contact
	;CALL	_FUN_TEST_WAVEET6601
	
	;CALL	_FUN_TEST_WAVEET6601RX		
	;CALL	_FUN_TEST_GSMTX
	;CALL	_FUN_TEST_GSMRX
	
	;CALL	_FUN_TEST_INT
	;CALL	_FUN_TEST_WAVEET6601ZB
	;CALL	_FUN_TEST_WAVEET6601TX
	;CALL	_FUN_TEST_RTCMODE
	;CALL	_FUN_TEST_CC1101
	;JMP	_FUN_TEST_CC1101_03
	;JMP	_FUN_TEST_CC1101_04
	;jmp	_fun_test_hvhv
	;jmp	_fun_test_hvhv02
	;jmp	_fun_test_low
	
	JMP	_fun_test_current
	
TEST_MASTER_OVER:
	JMP	TEST_MASTER_OVER	
		
	RET
	
	RSEG	?pr?TEST?Mater2
	USING	0
	
;---------------------------------------			
;把绶冲的数据发到串口显示
;	R7	---	绶冲
;	R3	---	长度
;	BIT_BUFADDR	绶冲 =0内存;=1外存
;	A=其它 表示函数执行完不返回。=0 表示返回
;---------------------------------------
_FUN_TEST_UARTDISPLAY:
	
;11	PUSH	ACC
	
	;CALL	_FUN_ContactIssue_INIT
	;CALL	_FUN_ContactIssue_INIT
	
;11	PUSH	AR7
;11	PUSH	AR3
	;---CALL	_FUN_ContactIssue_INIT
;11	CALL	_FUN_ContactIssue_INIT02
;11	POP	AR3
;11	POP	AR7
	
	;MOV	R2,#255
	;DJNZ	R2,$
	
	;MOV	R7,#DATA_RXBUF
	;MOV	R3,#23
	
;11	JB	BIT_BUFADDR,TEST_UARTDISPLAY_XData
;11TEST_UARTDISPLAY_Data:
	
;11	MOV	AR5,AR7
;11	MOV	R7,#XDATA_TXBUF
;11	PUSH	AR3
;11	CALL	_FUN_LIB_DATATOXDATA
;11	POP	AR3
	
;11	MOV	R7,#XDATA_TXBUF		
	
;	MOV	AR5,AR7
;	MOV	R7,#XDATA_TXBUF
;	PUSH	AR3
;	CALL	_FUN_LIB_DATATOXDATA
;	POP	AR3
;	MOV	R7,#XDATA_TXBUF	
	
;11	CALL	_FUN_ContactIssue_TX
;11	JMP	TEST_UARTDISPLAY_OVER
TEST_UARTDISPLAY_XData:	
;11	CALL	_FUN_ContactIssue_TX
	
TEST_UARTDISPLAY_OVER:
;11	POP	ACC
;11	JZ	TEST_UARTDISPLAY_Return
TEST_UARTDISPLAY_Stop:
;11	JMP	TEST_UARTDISPLAY_Stop
TEST_UARTDISPLAY_Return:

	RET
;---------------------------------------			
;显示
;---------------------------------------
_FUN_TEST_DISPLAY:
	
	;ret
	PUSH	ACC
	CALL	_Func_LCD_INIT
	POP	ACC
	
	MOV 	money,#0h			;
	MOV 	money + 1,#0h			;
	MOV 	money + 2,#0h			;
	MOV 	money + 3,A			;
	MOV 	R7,#DATA_RXBUF + 90		;
	CALL	_dspmoney			; 显示新余额
	
OO0KK:
	MOV	REG_5412AD_P0M0,#00000000B
	MOV	REG_5412AD_P0M1,#00000000B
	JMP	OO0KK
	
	RET
	
	
_FUN_TEST_DISPLAY02:
	
	;ret
;11	PUSH	ACC
;11	CALL	_Func_LCD_INIT
;11	POP	ACC
	
;11	MOV 	money,#0h			;
;11	MOV 	money + 1,#0h			;
;11	MOV 	money + 2,#0h			;
;11	MOV 	money + 3,A			;
;11	MOV 	R7,#DATA_RXBUF + 90		;
;11	CALL	_dspmoney			; 显示新余额
	
OO0KK2:

;11	MOV	REG_5412AD_P0M0,#00000000B
;11	MOV	REG_5412AD_P0M1,#00000000B
	
;11	JMP	OO0KK2
	
	RET	
	
_FUN_TEST_RED:
 
	RET
	
	
_FUN_TEST_checkrtcmode:
 
	RET
sfdsdfdsccc6:	
;11	pop	acc	
	ret
;---------------------------------------			
;显示 R7为主的4个字节 
	
 
OO0KK02:	

	JMP	OO0KK02
	
;11	MOV	R7,#200
;11	call	_FUN_LIB_DELAY
	
	RET
;---------------------------------------	
;响铃测试
;---------------------------------------
_FUN_TEST_BEEP:
;11	MOV	R7,#200
;11	CALL	_FUN_LIB_BEEP
TEST_BEEP_LOOP:
;11	JMP	TEST_BEEP_LOOP
	RET
	
;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
;;PC串口通讯		
_FUN_TEST_PCSerial:
	RET
;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_TESTSOFTTX: 
	RET		
;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_TESTSOFTTX2:
 
	RET

;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_PCSerial2:
	RET
	
;////////////////////////////////////////////////////////////////////////////////
;发送发送程序	
;////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_IssueTX:
	RET
;////////////////////////////////////////////////////////////////////////////////
;发行接收程序
;////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_IssueRX:
	RET


;////////////////////////////////////////////////////////////////////////////////
;230k发送
;////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_230KTX:
 

	RET
;/////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_initcard:
 
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////////////////	
;点lcd 'act'
;//////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_LCDACT:
	
	RET
;///////////////////VV////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_FB:
	
	;打开T0中断
;	CLR	TF0
;	SETB	TR0
	
;	SETB	ex0
;	SETB	EA
		
TEST_FB_OVER:
;	JMP	TEST_FB_OVER
	RET
;//////////////////////////////////////////////////////	
_FUN_TEST_TZ:
;	CLR	BIT_CHANNELFLAG
;	CALL	_FUN_HDLC_CHANGECHANNEL			;设置通讯信道	

TEST_TZ_LOOP:	
;	CPL	PIN_WAVE_CHANNEL0			;4
;	CPL	PIN_WAVE_CHANNEL1			;4
	
;	NOP
;	NOP
;	NOP
;	NOP
;	NOP

;	NOP
;	NOP
;	NOP
;	NOP
;	NOP
;	
;	JMP	TEST_TZ_LOOP	
	RET
;//////////////////////////////////////////////////////		
_fun_test_randdelay:
test_randdelayLOOP:
	
;11	CPL	P2.1
;11	CALL	_FUN_LIB_RANDDELAY
	;MOV	R7,#3
	;CALL	_FUN_LIB_1MSDELAYC
	;CPL	P2.1
	;CALL	_FUN_LIB_RANDDELAY
	;MOV	R7,#6
	;CALL	_FUN_LIB_1MSDELAYC	
;11	JMP	test_randdelayLOOP
	
	;JMP	

	RET
	
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_BF:
	
	;MOV	DPTR,#STR_Contact_DATA
	;MOV	R7,#DATA_RXBUF
	;CALL	_FUN_LIB_FLASHTODATA
	
	;MOV	A,DATA_DSRCRXLEN	
	;MOV	A,#6
	
	;MOV	B,A
	;CLR	C
	;MOV	A,#120
	;SUBB	A,B
	;MOV	R0,#DATA_RXBUF
	
	;MOV	R1,A
	;MOV	A,#DATA_RXBUF
	;ADD	A,R1
	;MOV	R1,A
	;MOV	R3,B
	;R1 目地地址 R0 源址
	
OBUMAIN_WAVEACTIVE_BFLOOP:
	
	;MOV	A,@R0
	;MOV	@R1,A
	;INC	R0
	;INC	R1
	;DJNZ	R3,OBUMAIN_WAVEACTIVE_BFLOOP	
	
	;MOV	DPTR,#STR_Contact_DATA2
	;MOV	R7,#DATA_RXBUF
	;CALL	_FUN_LIB_FLASHTODATA
		
	;MOV	A,DATA_DSRCRXLEN	
	;MOV	A,#6
	
	;MOV	B,A
	;CLR	C
	;MOV	A,#120
	;SUBB	A,B
	;MOV	R0,#DATA_RXBUF
	
	;MOV	R1,A
	;MOV	A,#DATA_RXBUF
	;ADD	A,R1
	;MOV	R1,A
	;MOV	R3,B
	;R1 目地地址 R0 源址
OBUMAIN_WAVEACTIVE_LYLOOP:
	;MOV	A,@R1
	;MOV	@R0,A
	;INC	R0
	;INC	R1
	;DJNZ	R3,OBUMAIN_WAVEACTIVE_LYLOOP
	
	;MOV	A,#0	
	
	RET
	
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////	
;rxfromcpupro
;rxfromcpucontact0_b
;00 84 00 00 08
_FUN_TEST_TXPro02:
	;MOV	A,#33
	;CALL	_FUN_TEST_DISPLAY

	;发送头部数据
	;CPL	BIT_PROF
;11	MOV	A,#0AH
;11	MOV	C,BIT_PROF
	;---CLR	C
;11	MOV	ACC.0,C
;11	CALL	_FUN_ProCard_TXBYTE
;11	CPL	BIT_PROF
	
;11	CLR	A
;11	CALL	_FUN_ProCard_TXBYTE
	
;11	MOV	A,#00H
;11	CALL	_FUN_ProCard_TXBYTE
;11	MOV	A,#84H
;11	CALL	_FUN_ProCard_TXBYTE	
;11	MOV	A,#00H
;11	CALL	_FUN_ProCard_TXBYTE	
;11	MOV	A,#00H
;11	CALL	_FUN_ProCard_TXBYTE
	;MOV	A,#08H
	;CALL	_FUN_ProCard_TXBYTE
								
	;=====================================接收===============================	
;11	SETB	BIT_BUFADDR		; 外存接收
;11	MOV	AR7,#XDATA_TXBUF			; 	
	;CALL	_FUN_ProCard_RXPro	
;11	MOV	DATA_IRQEN,#29H
;11	MOV	R7,#0CH	; 		
;11	CALL	_FUN_NContact_TESTRc500TxAndRx
	
	;读发射数据<=2，就补数据
TEST_TXPro02_LOOP:
;11	MOV	R7,#00H
;11	MOV	A,#REG_RC522_FIFOLevelReg
;11	RL	A
;11	SETB	ACC.7
;11	CALL	_FUN_NContact_spio
;11	MOV	A,REG_5412AD_spdat
;11	CJNE	A,#1,$+3
;11	JNC	TEST_TXPro02_LOOP
		
;11	MOV	A,#08H
;11	CALL	_FUN_ProCard_TXBYTE	
	;MOV	DATA_IRQEN,#29H
	;MOV	R7,#0CH	; 		
	;CALL	_FUN_NContact_TESTRc500TxAndRx	
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY
	
	;MOV	R7,#255
	;DJNZ	R7,$
	
	
	;MOV	R7,#00H
	;MOV	A,#REG_RC522_FIFOLevelReg
	;RL	A
	;SETB	ACC.7
	;CALL	_FUN_NContact_spio
	;MOV	A,REG_5412AD_spdat	
	
	
;11	SETB	BIT_BUFADDR		; 外存接收
;11	MOV	AR7,#XDATA_TXBUF			; 
;11	CALL	_FUN_ProCard_RXPro02	
	
	;CALL	_FUN_TEST_DISPLAY
	;=========================================================================

	;CALL	_FUN_TEST_DISPLAY
;11SDFDSFDSF:
;11	JMP	SDFDSFDSF
	
	RET	
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_HDLCTX:
	
	
;11	MOV	DPTR,#STR_ERRTX
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_LIB_FLASHTOXDATA
	
;11	MOV	A,R3
;11	MOV	DATA_DSRCTXLEN,A
TEST_HDLCTX_LOOP:
		
;	CALL	_FUN_HDLC_TX
	
;11	MOV	R7,#5
;11	CALL	_FUN_LIB_DELAY
	
;11	JMP	TEST_HDLCTX_LOOP
	
	RET	
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////		
;
;r3 len
;r7 data
;
_FUN_TEST_GSM:
	
;11	CALL	_FUN_ContactIssue_INIT
	;LCALL	Initial_UART2
	;MOV	IE2,#0
	
TEST_GSM_LOOP01:
	
;11	MOV	R3,#10	
;11	MOV	R0,#XDATA_TXBUF	
	
TEST_GSM_LOOP:

;11	INC	R0
;11	INC	A
;11	DJNZ	R3,TEST_GSM_LOOP
	
;11	MOV	R3,#10
;11	SETB	BIT_BUFADDR
;11	CLR	BIT_VERIFY
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_SERIAL_TXHARD
	;CALL	_FUN_ContactIssue_TX
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY
	
;11	JMP	TEST_GSM_LOOP01
	
	RET	
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////		
_FUN_TEST_GSM02:
	
;11	CALL	_FUN_ContactIssue_INIT
	
;11	MOV	R3,#128	
;11	CLR	A
;11	MOV	R0,#XDATA_TXBUF
TEST_GSM02_loop01:
;11		;MOVX	@R0,A

;11	INC	A
;11	INC	R0	
;11	DJNZ	R3,TEST_GSM02_loop01
	
;11	MOV	R3,#128
;11	SETB	BIT_BUFADDR
;11	CLR	BIT_VERIFY
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_SERIAL_TXHARD
	
TEST_GSM02_LOOP:
	
;11	SETB	BIT_BUFADDR		;= 0，接收数据到内存； = 1，接收数据到外存
;11	CLR	BIT_VERIFY		;串口收发是否要加验位,=0不要，=1要
;11	CLR	BIT_SERIALOVERTIMERX
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_SERIAL_RXHARD
	
	;MOV	A,R3
	;JZ	TEST_GSM02_LOOP
	;MOV	R3,#10
	
;11	SETB	BIT_BUFADDR
;11	CLR	BIT_VERIFY
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_SERIAL_TXHARD
	
;11	JMP	TEST_GSM02_LOOP
		
	RET
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////			
_FUN_TEST_HDLC:
	
	;p0.5
;	MOV	REG_5412AD_P0M0,#00000000B
;	MOV	REG_5412AD_P0M1,#00100000B
			
	;CALL	_AutoASKReg	;BK5822初始化
	;MOV	R7,#10
	;CALL	_FUN_LIB_DELAY	

	;CALL	_BK5822_RST	;复位BK5822 寄存器
	;MOV	R7,#10
	;CALL	_FUN_LIB_DELAY	
	
	;CALL	_AutoASKReg	;BK5822初始化	
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY	
	
	;MOV	R7,#1	
	;CALL	_BK5822_RXTX
		
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY
		
;11	MOV	R3,#100	
;11	CLR	A
;11	MOV	R0,#XDATA_TXBUF
TEST_HDLC_loop01:
;11		;MOVX	@R0,A

;11	INC	A
;11	INC	R0	
;11	DJNZ	R3,TEST_HDLC_loop01	
	
	;设置VST基本信息
;11	MOV	DPTR,#STR_DSRC_VST02
;11	MOV	R7,#XDATA_TXBUF; + 4
;11	CALL	_FUN_LIB_FLASHTOXDATA			

	;计算DSRC帧数据长度
	;MOV	R3,#10
;11	MOV	A,R3;#10
	;记录发送长度以便在重发时使用
;11	MOV	DATA_DSRCTXLEN,A
;11	MOV	R7,#XDATA_TXBUF	

;11	MOV 	r5,a
;11	CALL 	_getnewcrc_xr
;11	MOV 	A,DATA_DSRCTXLEN
;11	INC 	A
;11	INC 	A
;11	MOV 	DATA_DSRCTXLEN,A
			
TEST_HDLC_loop02:
;	CALL	_FUN_HDLC_TX	
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY
;11	JMP	TEST_HDLC_loop02


	RET
;//////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_HDLC02:
	
;11	MOV	REG_5412AD_P0M0,#00000000B
;11	MOV	REG_5412AD_P0M1,#00100000B
;11	MOV	IE,#0	
	
;11	CALL	_FUN_HDLC_RX
	
;11	JMP	_FUN_TEST_HDLC
;	JMP	_FUN_TEST_HDLC02
;	MOV	REG_5412AD_P0M0,#00000000B
;	MOV	REG_5412AD_P0M1,#00101000B
;	MOV	A,R3
;	CJNE	R3,#3,$+3
;	JC	_FUN_TEST_HDLC02
	;MOV	R7,#1	
	;CALL	_BK5822_RXTX	
	
	;设置VST基本信息
;11	MOV	DPTR,#STR_DSRC_VST02
;11	MOV	R7,#XDATA_TXBUF; + 4
;11	CALL	_FUN_LIB_FLASHTOXDATA	
	
	;计算DSRC帧数据长度
	;MOV	R3,#10
;11	MOV	A,R3;#10
	;记录发送长度以便在重发时使用
;11	MOV	DATA_DSRCTXLEN,A
;11	MOV	R7,#XDATA_TXBUF	
	
;11	MOV 	r5,a
;11	CALL 	_getnewcrc_xr
;11	MOV 	A,DATA_DSRCTXLEN
;11	INC 	A
;11	INC 	A
;11	MOV 	DATA_DSRCTXLEN,A
	
;	CALL	_FUN_HDLC_TX	
	
	;MOV	R7,#0
	;CALL	_BK5822_RXTX	
	
	;CALL	_AutoASKReg	;BK5822初始化
	;MOV	R7,#10
	;CALL	_FUN_LIB_DELAY	
	
	;CALL	_BK5822_RST	;复位BK5822 寄存器
	;MOV	R7,#10
	;CALL	_FUN_LIB_DELAY	
	
	;CALL	_AutoASKReg	;BK5822初始化
	;MOV	R7,#10
	;CALL	_FUN_LIB_DELAY
	
;11	JMP	_FUN_TEST_HDLC02
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_Card:
	
	;MOV	IE,#0
	;MOV	REG_5412AD_P2M0,#00000000B
	;MOV	REG_5412AD_P2M1,#00000100B	
	;CLR	Pin_pwrdwn		
	;CLR	PIN_RED
	
SDFSFSDFS:
	;JMP	SDFSFSDFS	
	
;11	MOV	R7,#30
;11	CALL	_FUN_LIB_DELAY	
	
;11	SETB	PIN_RED	
;11	SETB	BIT_ESAMICC
;11	CALL	_FUN_Contact_INIT
	
;11	MOV	A,R7
;11	JNZ	_FUN_TEST_Card
	
	;CJNE	R3,#10,$+3
	;JC	_FUN_TEST_Card
	
;11	CLR	PIN_RED
;11TEST_Card_OVER:
;11	JMP	TEST_Card_OVER
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////		
_FUN_TEST_Card02:
	
;11	MOV	R7,#CONST_BAUD_9600
;11	CALL	_FUN_Contact_CHANGEBAUD
;11	MOV	R7,#50
;11	CALL	_FUN_LIB_DELAY
	
;11	SETB	PIN_RED	
;11	SETB	BIT_ESAMICC
;11	CALL	_FUN_Contact_INIT
	
;11	MOV	A,R7	
;11	JNZ	_FUN_TEST_Card02
	
	;JMP	_FUN_TEST_Card02
;ASDFSDFSDFS:
;	JMP	ASDFSDFSDFS
;ASDFSDFSDFS01:
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY	

;11	MOV	R7,#CONST_PPS_115200	
;11	CLR	BIT_T0T1
;11	CALL	_FUN_Contact_PPS
	
;11	MOV	R7,#CONST_BAUD_115200
;11	CALL	_FUN_Contact_CHANGEBAUD
	
	;JMP	_FUN_TEST_Card02	
;	CALL	_FUN_ContactIssue_INIT	
	
;	CLR	BIT_BUFADDR		;=0，接收数据到内存； =1，接收数据到外存
;	CLR	BIT_VERIFY		;串口收发是否要加验位,=0不要，=1要
;	CLR	BIT_SERIALOVERTIMERX
;	MOV	R7,#DATA_RXBUF
;	CALL	_FUN_SERIAL_RXHARD
	
;	MOV	A,R3
;	JZ	TEST_Card02_OVER
	
;	PUSH	AR3
;	CALL	_FUN_ContactIssue_Release
;	POP	AR3
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY	
	
;11	MOV	R0,#DATA_RXBUF
;11	MOV	@R0,#00h
;11	INC	R0
;11	MOV	@R0,#0A4h
;11	INC	R0
;11	MOV	@R0,#00h
;11	INC	R0
;11	MOV	@R0,#00h
;11	INC	R0
;11	MOV	@R0,#02h
;11	INC	R0
;11	MOV	@R0,#10h
;11	INC	R0
;11	MOV	@R0,#01h
;11	INC	R0
;11	MOV	R3,#7
	
;11	SETB	BIT_GETRESULT
;11	SETB	BIT_ESAMICC
;11	MOV	R7,#DATA_RXBUF
;11	MOV	R5,#XDATA_TXBUF
	;R3
;11	CALL	_FUN_Contact_Channel	
	
	;JMP	_FUN_TEST_Card02
	
;	MOV	A,R3
;	JZ	TEST_Card02_OVER

;11	CALL	_FUN_ContactIssue_INIT	

;11	SETB	BIT_BUFADDR
;11	CLR	BIT_VERIFY
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_SERIAL_TXHARD	

TEST_Card02_OVER:
;11	CALL	_FUN_ContactIssue_Release
;11	JMP	_FUN_TEST_Card02
	RET
	
;----------------------------------------------------------------------
;打开外围
;打开背光
;----------------------------------------------------------------------
_fun_test_LCD:
	
	;推挽
	;	蜂鸣器			P4.6
	;	BK5822发射供电脚	P0.5
	;	电源控制		P2.2	
	;P0.5
;11	MOV	REG_5412AD_P0M0,#00100000B
;11	MOV	REG_5412AD_P0M1,#00000000B
	
	;p0.3	wave din
	;MOV	REG_5412AD_P0M0,#00001000B
	;MOV	REG_5412AD_P0M1,#00000000B
	
;11	MOV	REG_5412AD_P1M0,#00000000B
;11	MOV	REG_5412AD_P1M1,#00000000B
	
	;p2.2	Pin_pwrdwn
	;MOV	REG_5412AD_P2M0,#00000100B
;11	MOV	REG_5412AD_P2M0,#01100110B
;11	MOV	REG_5412AD_P2M1,#10000000B
	
	;p3.7	isDownload
	;MOV	REG_5412AD_P3M0,#01000000B
;11	MOV	REG_5412AD_P3M0,#01000000B
	;MOV	REG_5412AD_P3M1,#10000000B
;11	MOV	REG_5412AD_P3M1,#00000000B
	
	;p4.6 bell
	;---MOV	REG_5412AD_P4M0,#00000000B
;11	MOV	REG_5412AD_P4M0,#00010000B
;11	MOV	REG_5412AD_P4M1,#01000000B
	
	;设置 P4.4 为普通 IO 脚	522复位
	;设置 P4.5 为普通 IO 脚 绿灯
	;设置 P4.6 为普通 IO 脚	bell
;11	MOV	A,REG_5412AD_P4SW
;11	ORL	A,#01110000B
;11	MOV	REG_5412AD_P4SW,A
	
	
;11	CLR	PIN_PWRDWN_LCD

	
	
;11	PUSH	ACC
;11	CALL	_Func_LCD_INIT
;11	POP	ACC
	
;11	MOV 	money,#0h			;
;11	MOV 	money + 1,#0h			;
;11	MOV 	money + 2,#0h			;
;11	MOV 	money + 3,A			;
;11	MOV 	R7,#DATA_RXBUF + 90		;
;11	CALL	_dspmoney			; 显示新余额
	
ASDFSFSDF:	
		
	;CLR	PIN_PWRDWN_LCD

		
;11JMP	ASDFSFSDF
;11	MOV	A,#10
	;CALL	_FUN_TEST_DISPLAY
	
	RET
	
;//////////////////////////////////////////////////////////////////////////////////////			
_FUN_TEST_contact:
	
;11	CLR	Pin_pwrdwn
	
	;设置 P4.4 为普通 IO 脚	522复位
	;设置 P4.5 为普通 IO 脚 绿灯
	;设置 P4.6 为普通 IO 脚	bell
;11	MOV	A,REG_5412AD_P4SW
;11	ORL	A,#01110000B
;11	MOV	REG_5412AD_P4SW,A
	
;11	CLR	PIN_PWRDWN_LCD

	
	;初始化系统
	;CALL	start_user
;11	MOV	REG_5412AD_P0M0,#10000000B
;11	MOV	REG_5412AD_P0M1,#00000000B
	
	;开外围电源 P1.1
;11	MOV	REG_5412AD_P1M0,#00000010B
;11	MOV	REG_5412AD_P1M1,#00000000B
	
	;522 RST 因为复用低电压检测做vcc，要推挽
;11	MOV	REG_5412AD_P2M0,#10000000B
;11	MOV	REG_5412AD_P2M1,#00000000B
	
;11	MOV	REG_5412AD_P3M0,#01000000B
;11	MOV	REG_5412AD_P3M1,#00000000B
	
;ASDFSFDSDDDD:	
;	CPL	Pin_Contact_RST
;	JMP	ASDFSFDSDDDD
	
	;初始化 卡片
;11	CALL	_FUN_OBUMain_BASEINIT
	
	;PUSH	ACC
	;CALL	_Func_LCD_INIT
	;POP	ACC	
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_WAVEET6601:
	
	;设置 P4.4 为普通 IO 脚	522复位
	;设置 P4.5 为普通 IO 脚 绿灯
	;设置 P4.6 为普通 IO 脚	bell
;11	MOV	A,REG_5412AD_P4SW
;11	ORL	A,#01110000B
;11	MOV	REG_5412AD_P4SW,A
	
	;初始化系统
	;CALL	start_user
	
	;开外围电源 P1.1
;11	MOV	REG_5412AD_P1M0,#00000010B
;11	MOV	REG_5412AD_P1M1,#00000000B
	
	;522 RST 因为复用低电压检测做vcc，要推挽
;11	MOV	REG_5412AD_P2M0,#10000000B
;11	MOV	REG_5412AD_P2M1,#00000000B
	
;11	MOV	REG_5412AD_P4M0,#00001000B
;11	MOV	REG_5412AD_P4M1,#00000000B	
	
;11	CLR	PIN_PWRDWN_LCD
;11	CLR	Pin_pwrdwn
	
	;MOV	A,#17
	;CALL	_FUN_TEST_DISPLAY
;11	CALL	_FUN_HDLC_5830Init
	
	;计算DSRC帧数据长度
;11	MOV	R0,#XDATA_TXBUF+5
;11	MOV	A,R0
;11	CLR	C
;11	SUBB	A,#XDATA_TXBUF
;11	MOV	R3,A
	
	;记录发送长度以便在重发时使用
;11	MOV	DATA_DSRCTXLEN,A
;11	MOV	R7,#XDATA_TXBUF	
	
;11	MOV 	R5,A
;11	CALL 	_getnewcrc_xr
;11	MOV 	A,DATA_DSRCTXLEN
;11	INC 	A
;11	INC 	A
;11	MOV 	DATA_DSRCTXLEN,A
	;SETB	PIN_5830_CE
_FUN_TEST_LOOP:	

;	CALL	_FUN_HDLC_TX
	
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY	
;11	JMP	_FUN_TEST_LOOP
	

	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_WAVEET6601RX:
	
	;设置 P4.4 为普通 IO 脚	522复位
	;设置 P4.5 为普通 IO 脚 绿灯
	;设置 P4.6 为普通 IO 脚	bell
;11	MOV	A,REG_5412AD_P4SW
;11	ORL	A,#01110000B
;11	MOV	REG_5412AD_P4SW,A
	
	;初始化系统
	;CALL	start_user
	
	;开外围电源 P1.1
;11	MOV	REG_5412AD_P1M0,#00000010B
;11	MOV	REG_5412AD_P1M1,#00000000B
	
	;522 RST 因为复用低电压检测做vcc，要推挽
;11	MOV	REG_5412AD_P2M0,#10000000B
;11	MOV	REG_5412AD_P2M1,#00000000B
	
;11	MOV	REG_5412AD_P4M0,#00001000B
;11	MOV	REG_5412AD_P4M1,#00000000B	
	
;11	CLR	PIN_PWRDWN_LCD
;11	CLR	Pin_pwrdwn
;11	MOV	IE,#00
	
	;MOV	A,#17
	;CALL	_FUN_TEST_DISPLAY
;11	CALL	_FUN_HDLC_5830Init
	;CLR	PIN_5830_CE
	
;11	CALL	_FUN_HDLC_RX
	
;11	MOV	A,R3
	;JZ	_FUN_TEST_WAVEET6601RX
	
	;CALL	_FUN_TEST_DISPLAY
			
	RET
;/////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_GSMTX:
	
;11	MOV	REG_5412AD_P1M0,#00000010B
;11	MOV	REG_5412AD_P1M1,#01000000B
	
	;SETB	BIT_BUFADDR
	;SETB	BIT_SERIALOVERTIMERX
	;CLR	BIT_VERIFY
	;MOV	R7,#XDATA_TXBUF	
	;MOV	R3,#0
	;CLR	BIT_ISFRX
	;CALL	_FUN_SERIAL_RXHARD
	
;11	SETB	BIT_BUFADDR
;11	SETB	BIT_SERIALOVERTIMERX
;11	CLR	BIT_VERIFY
;11	MOV	R7,#XDATA_TXBUF
;11	CALL	_FUN_ContactIssue_RX02
	
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY
		
;11	MOV	A,R7
;11	JNZ	_FUN_TEST_GSMTX
	
;MOV	A,R3
;CALL	_FUN_TEST_DISPLAY	
	
	;MOV	R7,#XDATA_TXBUF
;11	MOV	AR7,AR5
	;MOV	R3,#10
;11	CALL	_FUN_ContactIssue_TX
	
;11	CLR	RI
;11	CLR	TI
;11	SETB	ES
	;--SETB	EA
	;SETB	REN
	
	;JMP	TEST_GSMRX_over	
	
TEST_GSMTX_OVER:	
;11	JMP	TEST_GSMTX_OVER	
	
	Ret
;/////////////////////////////////////////////////////////////////////////////////////////////
;IE.4	UART
_FUN_TEST_GSMRX:
	RET
	;设置 P4.4 为普通 IO 脚	522复位
	;设置 P4.5 为普通 IO 脚 绿灯
	;设置 P4.6 为普通 IO 脚	bell
	;MOV	A,REG_5412AD_P4SW
	;ORL	A,#01110000B
	;MOV	REG_5412AD_P4SW,A
	
	;初始化系统
	;CALL	start_user
		
	;开外围电源 P1.1
	;MOV	REG_5412AD_P1M0,#00000010B
	;MOV	REG_5412AD_P1M1,#01000000B
	
TEST_GSMRX_Over:
;11	clr	Pin_pwrdwn

;11	JMP	TEST_GSMRX_Over	
	
	;///////////////////////////////////////////////////////////////	
	;522 RST 因为复用低电压检测做vcc，要推挽
;11	MOV	REG_5412AD_P2M0,#10000000B
;11	MOV	REG_5412AD_P2M1,#00000000B
	
;11	MOV	REG_5412AD_P4M0,#00001000B
;11	MOV	REG_5412AD_P4M1,#00000000B
	
;11	CLR	PIN_PWRDWN_LCD
;11	CALL	_FUN_ContactIssue_INIT
	
;11	CLR	TI
;11	CLR	RI
;11	SETB	REN
	;---ORL	IE,#90H
		
	;MOV	IE,#11111111B	
	RET
;/////////////////////////////////////////////////////////////////////////////////////////////
_FUN_TEST_INT:
	
	RET
;/////////////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_WAVEET6601ZB:
	
;11	CLR	BIT_CHANNELFLAG
;11	CALL	_FUN_HDLC_5830Init
	
TEST_WAVEET6601ZB_LOOP:	
	

	;SETB	PIN_5830_CE
	;SETB	PIN_WAVE_CHANNEL1
		
;11	JMP	TEST_WAVEET6601ZB_LOOP
	
	RET
	
_FUN_TEST_WAVEET6601TX:
	
;11	CLR	BIT_CHANNELFLAG
;11	CALL	_FUN_HDLC_5830Init
	
;11	MOV	DATA_DSRCTXLEN,#118
TEST_WAVEET6601TX_LOOP:	
	

	;SETB	PIN_5830_CE
	;SETB	PIN_WAVE_CHANNEL1
	
;11	DJNZ	R7,$
;11	DJNZ	R7,$
;11	DJNZ	R7,$	
;11	DJNZ	R7,$
;11	DJNZ	R7,$	
;11	DJNZ	R7,$
;11	DJNZ	R7,$	
;11	DJNZ	R7,$
;11	DJNZ	R7,$	
;11	DJNZ	R7,$
	
;	CALL	_FUN_HDLC_TX
		
;11	MOV	R7,#10
;11	CALL	_FUN_LIB_DELAY
;11	JMP	TEST_WAVEET6601TX_LOOP
	
	RET		
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_RTCMODE:
	
;11	MOV	R0,#XDATA_RTCMode
;11		;MOVX	A,@R0

	
;11	MOV	REG_MCU_WKCTH,#08fH
;11	MOV	REG_MCU_WKCTL,#0ffH
	;---MOV	PCON,#82H;
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
;EXTRN CODE(_FUN_CC1101_RESET)		;复位
;EXTRN CODE(_FUN_CC1101_INIT)		;初始化 CC1101
;EXTRN CODE(_FUN_CC1101_SetWakeUpTime)	;初始化1101唤醒时间
;EXTRN CODE(_FUN_CC1101_RVOn)		;打开接收	
;EXTRN CODE(_FUN_CC1101_RVOff)		;关闭接收
;EXTRN CODE(_FUN_CC1101_RVWR)		;回读
;EXTRN CODE(_FUN_CC1101_Idle)		;设置当前为空闲状态
;EXTRN CODE(_FUN_CC1101_WakeUP)		;设置当前为唤醒状态
_FUN_TEST_CC1101:
	
;读
;PIN_CC1101_GDO2			BIT	P1.6	
;PIN_CC1101_MISO			BIT	P1.7
	
;一般
;Pin_CC1101_SS				BIT	P3.7
;PIN_CC1101_SCLK			BIT	P0.5
;PIN_CC1101_MOSI			BIT	 P0.6
	
;11	CLR	EA

;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY	
	

;11	CLR	PIN_PWR_GSM
;11	MOV	REG_5412AD_P0M0,#00000000B
;11	MOV	REG_5412AD_P0M1,#00000000B
	
;11	MOV	REG_5412AD_P1M0,#00000000B
;11	MOV	REG_5412AD_P1M1,#10000000B
	
;11	MOV	REG_5412AD_P3M0,#00000000B
;11	MOV	REG_5412AD_P3M1,#00000000B
	
;11	CLR	Pin_CC1101_SS
;11	CLR	PIN_CC1101_SCLK
;11	CLR	PIN_CC1101_MOSI

;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY		

TEST_CC1101_S:
	
	;CPL	Pin_CC1101_SS	
;11	CALL	_FUN_CC1101_RESET
;11	CALL	_FUN_CC1101_INIT
	
;11	CALL	_FUN_CC1101_RVOn
;11	MOV	R7,#1
;11	CALL	_FUN_LIB_DELAY	
;11	CALL	_FUN_CC1101_RVOff
	
;11	CALL	_FUN_CC1101_SetWakeUpTime
;11	CALL	_FUN_CC1101_RVWR
;11	CALL	_FUN_CC1101_Idle
;11	CALL	_FUN_CC1101_WakeUP
;11	SETB	EA
	
	;---CPL	Pin_CC1101_SS
	;---CPL	PIN_CC1101_SCLK
	;---CPL	PIN_CC1101_MOSI
;	CPL	PIN_CC1101_MISO
;	CPL	PIN_CC1101_GDO2
;	JB	Pin_CC1101_SS,CC1101_spioSingleSoft_S02
;CC1101_spioSingleSoft_S:
;	JB	PIN_CC1101_MISO,CC1101_spioSingleSoft_S
;CC1101_spioSingleSoft_S02:
	;MOV	R7,#1
	;CALL	_FUN_LIB_DELAY
	;JMP	TEST_CC1101_S
	
	;MOV	R7,#200
	;CALL	_FUN_LIB_DELAY
	
	;MOV	R7,#200
	;CALL	_FUN_LIB_DELAY	
;	CPL	Pin_CC1101_SS
;	CPL	PIN_CC1101_SCLK
;	CPL	PIN_CC1101_MOSI
;	CPL	PIN_CC1101_MISO
;	CPL	PIN_CC1101_GDO2	
TEST_CC1101_S_OVER:
	;JMP	TEST_CC1101_S_OVER
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_CC1101_02:
;11 	CLR	ES
 
	;设置 RTC 开启运行标记
;11	MOV	R0,#XDATA_RTCMode
;11	MOV	A,#CONST_RTC_ON
;11		;MOVX	@R0,A

	
	;开启RTC [h0~3 L0~7]fffh = 6s
	;MOV	REG_MCU_WKCTH,#CONST_MCU_WKCTH
	;ORL	REG_MCU_WKCTH,#10000000B
	;MOV	REG_MCU_WKCTL,#CONST_MCU_WKCTL
;11	CALL	_FUN_GSM_RTCON
	;CALL	_Fun_GSM_GetCellIDEN
	
;11	Anl	REG_5412AD_P1M0,#00111111B	 ;
;11	Orl	REG_5412AD_P1M1,#11000000B	 ; MISO 为输入(高阻)	
	
;11	CLR	PIN_PWR_GSM			 ; [GSM] 
;11       	SETB	Pin_CC1101_SS
;11	CLR	PIN_CC1101_SCLK
;11	CLR	PIN_CC1101_MOSI
	;PIN_CC1101_MISO
	;CLR	PIN_CC1101_GDO2 
	
;11	CALL	_FUN_CC1101_RESET
;11	CALL	_FUN_CC1101_INIT
	
;11	CALL	_FUN_CC1101_RVOn
	
;11	MOV	R7,#1
;11	CALL	_FUN_LIB_DELAY	
	;MOV	R7,#255
	;DJNZ	R7,$
	
;11	CALL	_FUN_CC1101_RVOff
	
;11	CALL	_FUN_CC1101_SetWakeUpTime
;11	CALL	_FUN_CC1101_RVWR
;11	CALL	_FUN_CC1101_Idle
;11	CALL	_FUN_CC1101_WakeUP
	;SETB	EA
	RET
;//////////////////////////////////////////////////////////////////////////////////////		
_FUN_TEST_CC1101_03:
;11	CLR	EA
;11	CLR	ES
	;设置 RTC 开启运行标记
;11	MOV	R0,#XDATA_RTCMode
;11	MOV	A,#CONST_RTC_ON
;11		;MOVX	@R0,A

	
	;开启RTC [h0~3 L0~7]fffh = 6s
	;MOV	REG_MCU_WKCTH,#CONST_MCU_WKCTH
	;ORL	REG_MCU_WKCTH,#10000000B
	;MOV	REG_MCU_WKCTL,#CONST_MCU_WKCTL
;11	CALL	_FUN_GSM_RTCON
	;CALL	_Fun_GSM_GetCellIDEN
	
;11	Anl	REG_5412AD_P1M0,#00111111B	 ;
;11	Orl	REG_5412AD_P1M1,#01000000B	 ; MISO 为输入(高阻)
	
;11	CLR	PIN_PWR_GSM			 ; [GSM] 
;11       	SETB	Pin_CC1101_SS
;11	CLR	PIN_CC1101_SCLK
;11	CLR	PIN_CC1101_MOSI
	;JMP	TEST_CC1101_03OVER
;11	SETB	PIN_CC1101_MISO
	;setb	PIN_CC1101_GDO2 
	;MOV	r7,#10
	;CALL	_fun_lib_delay
	
;11	CALL	_FUN_CC1101_RESET
;11	CALL	_FUN_CC1101_INIT
;	A			---	地址
;	R7			---	数据
;	R6			---	外存
;	R4			---	总数
;11	MOV	R4,#8
;11	MOV	A,#7EH
;11	MOV	R6,#XDATA_TXBUF
;11	MOV	R7,#0C0H
;11	CALL	_FUN_CC1101_spioSoftRXCC1101RXCC1101
;11	
;11	CALL	_FUN_CC1101_RVOn
;11	PUSH	AR7
;11	MOV	R7,#255
;11	DJNZ	R7,$	
;11	DJNZ	R7,$	
;11	DJNZ	R7,$	
;11	DJNZ	R7,$		
;11	DJNZ	R7,$	
;11	DJNZ	R7,$	
;11	DJNZ	R7,$	
;11	DJNZ	R7,$		
;11	DJNZ	R7,$	
;11	DJNZ	R7,$
;11	POP	AR7
;11	CALL	_FUN_CC1101_RVOff
	
;11	CALL	_FUN_CC1101_SetWakeUpTime
;11	CALL	_FUN_CC1101_RVWR
;11	CALL	_FUN_CC1101_Idle
;11	CALL	_FUN_CC1101_WakeUP
	
;clr	ea
;	orl	REG_5412AD_P1M0,#10000000B	 ;
;	anl	REG_5412AD_P1M1,#01111111B	 ; MISO 为
	
;11clr	RI
;11clr	TI	
;11mov	ie,#00

;setb	es
;setb	ea
TEST_CC1101_03OVER:
	
	;SETB	PIN_CC1101_MISO
	;JMP	TEST_CC1101_03OVER
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////			
_FUN_TEST_CC1101_04:
;11	CALL	_FUN_TEST_CC1101_03
TEST_CC1101_04OVER:

	RET
	
;//////////////////////////////////////////////////////////////////////////////////////		
_FUN_TEST_UARTDebug:


;11	SETB	BIT_BUFADDR
;11	MOV	R7,#XDATA_TXBUF
;11	MOV	R3,#10
;11	clr	a
;11	CALL	_FUN_TEST_UARTDISPLAY
;11	JMP	_FUN_TEST_UARTDebug
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////
;
;
;
;//////////////////////////////////////////////////////////////////////////////////////
TEST_5823_Loop:
 
TEST_5823_RXLOOP02:
	
;11	Call	_fun_hdlc_rx	
	;mov	a,#33
 	;MOV	R0,#DATA_DSRCRXLEN
 	;MOV	A,@R0
	;CALL	_FUN_TEST_DISPLAY
	;mov	r7,#200
	;call	_fun_lib_delay
	;jmp	ap_start
;R7		---	外存BUF指针
;R5		---	内存BUF指针长度
;R3		---	将要COPY的长度	
;11 	MOV	R0,#DATA_DSRCRXLEN
;11 	MOV	A,@R0
 	
;11 	MOV	R3,A
;11	MOV	R7,#XDATA_TXBUF
;11	MOV	R5,#DATA_RXBUF	
;11 	CALL	_FUN_LIB_DATATOXDATA
	
	;记录发送长度以便在重发时使用
;BIT_BUFADDR	---	表示当前操作的存储区,=0内存;=1外存
;R5		---	BUF长度
;R7		---	BUF指针
;11	SETB	BIT_BUFADDR
;11	MOV	R7,#XDATA_TXBUF
;11 	MOV	R0,#DATA_DSRCRXLEN
;11 	MOV	A,@R0
;11	MOV 	R5,A
;11	call 	_getnewcrc_xr
	
;11 	MOV	R0,#DATA_DSRCRXLEN
;11 	MOV	A,@R0
	
	;MOV 	A,DATA_DSRCTXLEN
;11	INC 	A
;11	INC 	A
	
;11 	MOV	R0,#DATA_DSRCRXLEN
;11 	MOV	@R0,A
;11	MOV 	DATA_DSRCTXLEN,A
		
;	CALL	_FUN_HDLC_TX
;11	JMP	TEST_5823_RXLOOP02
	
	RET	
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_hvhv:	
	
	;STR_HV02	12,11,11,6,7,0,1,2,3,4,5,11,11
;	CALL	_Func_LCD_INIT
;	MOV	DPTR,#STR_HV
;	MOV	R7,#XDATA_HOLD
;	CALL	_FUN_LIB_FLASHTOXDATA
	
;	MOV	R5,#DATA_RXBUF+90
;	MOV	R7,#XDATA_HOLD
;	CALL	_FUN_LIB_XDATATODATA
	
	;11,11,6,7,0,1,2,3,4,5,11,11
;	MOV	R7,#DATA_RXBUF + 90
;	MOV	R5,#1
;	MOV	R3,#11
;	CALL	_Func_LCD_Display
	
;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY
;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY
;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_hvhv02:
	
;	CALL	_Func_LCD_INIT
	
;;	MOV	DPTR,#str_test_hv
;	MOV	R7,#XDATA_HOLD
;	CALL	_FUN_LIB_FLASHTOXDATA
;	
	;R7   外存车牌
;	;R5   翻译后的内存指针
;	MOV	R7,#XDATA_HOLD			;8
;	MOV	R5,#DATA_RXBUF + 90		;
;	CALL	FUN_LCD_HVTransfer		;
	
;	MOV	R7,#DATA_RXBUF + 90 + 1 	 	
;	MOV	R5,#1
;	MOV	R0,#DATA_RXBUF + 90
;	MOV	A,@R0
;	MOV	R3,A
;	CALL	_Func_LCD_Display
	
;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY
;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY
;	MOV	R7,#200
;	CALL	_FUN_LIB_DELAY
	
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_fun_test_low:
	
;	CALL	_Func_LCD_INIT	
;	MOV	R7,#DATA_RXBUF
;	MOV	DPTR,#STR_LOWVo
;	CALL	_FUN_LCD_DisplayExChina
;sdfsdfds:
;	jmp	sdfsdfds
;//////////////////////////////////////////////////////////////////////////////////////	
;测试	单片机		14.28
;	5823 接收
;	5823 发射
;	522
;	ESAM 复位前后
;	ESAM 复位脚拉低，拉高
;//////////////////////////////////////////////////////////////////////////////////////	
_fun_Test_Current:
	
;	CLR	EA
;	CALL	_Fun_OBUmain_SysUNSleep
;	SETB     Pin_522_RST	
;	18.2 ma
	
;	CLR	PIN_BK_CE
;	MOV	R7,#2
;	CALL	_fun_lib_delay
;	SETB	PIN_BK_CE
;	CALL	_FUN_HDLC_5830Init		;初始化需作频率校准，寄存器不能直接配置为休眠模式	
;	CALL	_Enter_Sleep_Mode			
;	CLR	PIN_BK_CE
;	17.9 ma

;	CALL	_FUN_OBUMAIN_INITSYS		; 系统初始化
;	CALL	_FUN_OBUMain_BASEINIT		;初始化ESAM,用户卡	
	;49.7	ma
	
	;MOV	R7,#1
	;CALL	_Power_Up

;	MOV	R7,#0
;	CALL	Rx_En

	;75.1
	
;	MOV	R7,#1
;	CALL	Tx_Carrier_En

;	SETB	PIN_WAVE_CHANNEL1
	;120
;test_current_loop:
	;MOV	REG_WDT_CONTR,#00111111B
	;JMP	test_current_loop
	RET
;//////////////////////////////////////////////////////////////////////////////////////	
_FUN_TEST_Pictest:
	
	;mov	a,#36
	;call	_fun_test_display
	MOV		IE,#0
	;auxr.7	= 0 T0不分频
	;auxr.7	= 0 T1不分频
	;MOV	08eH,#0c0H	;AUXR
	ORL	REG_5412AD_AUXR,#10000000b
	
	MOV	REG_5412AD_P3M0,#00010000B
	MOV	REG_5412AD_P3M1,#00000001B
		
	;MOV	REG_5412AD_P0M0,#00000100B
	;MOV	REG_5412AD_P0M1,#00000000B
	
	SETB	PIN_WAVE_RX
	
;	SETB	p1.0				;pin clk
;	SETB	p1.1				;?
	
	;---CLR	PIN_GSM_IO
	;T0 8位重装
	MOV	TMOD,#02H			;22h
	;关T0
	CLR	TR0
	
	SETB	PIN_OUTPUT_CLK
	MOV	A,#208				;CONST_DELAY_VALUE
	MOV	TL0,A
	MOV	A,#208
	MOV	TH0,A
	SETB	TR0
	
	mov	ie,#0
	setb	es
	setb	ea
	
	;REG_WAKE_CLK0.0 = 1，高置T0对应脚P3.4为时钟输出脚
	;Sysclk / (256-TH0) / 2
	MOV	REG_WAKE_CLK0,#01H;03h
	
	JMP	TEST_Pictest_Start
	
;///////////////////////////////////////////////////////////////////
;1   		24.576
;1   clk 	25	6
;0.5 clk 	12	3
;1.5 clk 	37	9
;	
;1 CLK		48	12
  ;2 CLK		96	24
;1.5CLK		72	18
;///////////////////////////////////////////////////////////////////
TEST_Pictest_Start00:
	
	JNB	PIN_WAVE_RX,$				;4
	;<1.5 CLK 的脉冲重新收				
	;<2.5 ClK 脉冲为1				
	;>2.5 ClK 脉冲重新收				
	;空1.5个CLK
	;1   CLK 0.9765625 * 40 = 39.0625
	;2   CLK 39.0625 *2 = 78.125
	;1.5 CLK = 1.5 * 39.0625 = 58.59375 ->59
	;78 - 59 = 19					
	;1.5 CLK/4=59/4 = 14.75				
	;2.5 CLK/4=97.65625/4 = 24.4140625		
	
	; 1.5 CLK
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4	60

	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4	60

	;1 clk	
	;2.5 CLK =4*39.0625=97.65625
	;97.65625/4=24.4
	;2.5clk-1.5clk=1clk=9
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne1		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne2		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne3		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne4		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne5		;4
	
	;之前19个	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne6		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne7		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne8		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne9		;4	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne10	;4	

	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne11		;4	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXOne12	;4	

;/////////////////////////////////////////////////////////////
TEST_Pictest_RXOne:
	JMP	TEST_Pictest_Start

;/////////////////////////////////////////////////////////////
;1 clk
TEST_Pictest_RXOne1:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne2:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne3:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne4:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne5:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne6:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne7:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne8:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne9:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne10:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne11:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
TEST_Pictest_RXOne12:
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	
;1 clk	
	
	;14-4=10
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4

	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOne		;4
	
;1个CLK
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXOneOK		;4
	
	JMP	TEST_Pictest_RXOne
	
TEST_Pictest_RXOneOK:
	
	MOV	R7,#CONST_DATA_VALUE1;20		;15
	DJNZ	R7,$		;62
	call	_FUN_LIB_DELAY10
	call	_FUN_LIB_DELAY10
	call	_FUN_LIB_DELAY10
	call	_FUN_LIB_DELAY10
	
;	call	_FUN_LIB_DELAY10
;	call	_FUN_LIB_DELAY10
	
nop
nop
nop
nop
nop

;	call	_FUN_LIB_DELAY10	
;	nop
;	nop
;	nop
;	nop
;	nop		
;	NOP
;	NOP		
	
	CLR	TR0			;4
	SETB	PIN_OUTPUT_CLK		;4
	MOV	A,#CONST_DATA_VALUE2;208+CONST_DATA_VALUE2		;2
	MOV	TL0,A			;2
	SETB	TR0			;2
	JMP	TEST_Pictest_Start
	
;	MOV	r7,#CONST_DATA_VALUE1		;15
;	DJNZ	r7,$		;62
	
;NOP	
;NOP	
	
;	CLR	TR0			;4
;	SETB	PIN_OUTPUT_CLK		;4
;	MOV	A,#CONST_DATA_VALUE2;208+CONST_DATA_VALUE2		;2
;	MOV	TL0,A			;2
;	SETB	TR0			;2
;	JMP	TEST_Pictest_Start
	
	
;////////////////////////////////////////////////////////////////////
;===================================================================
	
	;空1.5个CLK
	;CLK 0.9765625 * 24.576 = 24[实测为25个周期]
	;1.5 CLK = 1.5* 25 = 37.5->38 = 50-38=12
	
	;空1.5个CLK
	;1 CLK 0.9765625 * 40 = 39.0625
	;2 CLK 39.0625 *2 = 78.125
	;1.5 CLK = 1.5 * 39.0625 = 58.59375 ->59
	;78 - 59 = 19
	;NOP
	;MOV	R7,#14
	;DJNZ	R7,$
	
;===================================================================	
TEST_Pictest_Start:
	
	;---JNB	PIN_WAVE_RX,TEST_Pictest_Start00	
	JB	PIN_WAVE_RX,TEST_Pictest_Start01
	JMP	TEST_Pictest_Start00
TEST_Pictest_Start01:
	JB	PIN_WAVE_RX,$				;4
	
	;<1.5 CLK 的脉冲重新收
	;<2.5 ClK 脉冲为1
	;>2.5 ClK 脉冲重新收
	;空1.5个CLK
	;1 CLK 0.9765625 * 40 = 39.0625
	;2 CLK 39.0625 *2 = 78.125
	;1.5 CLK = 1.5 * 39.0625 = 58.59375 ->59
	;78 - 59 = 19	
	;1.5CLK/4=59/4=14.75
	;2.5CLK/4=97.65625/4 = 24.4140625
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4	60
	
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4	60
	
	;2.5 CLK =4*39.0625=97.65625
	;97.65625/4=24.4
	;2.5clk-1.5clk=1clk=9
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO1		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO2		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO3		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO4		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO5		;4
	
	;之前19个	
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO6		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO7		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO8		;4
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO9		;4	
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO10	;4	

	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO11		;4	
	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO12	;4	

;/////////////////////////////////////////////////////////////
TEST_Pictest_RXTWO:
	JMP	TEST_Pictest_Start

;/////////////////////////////////////////////////////////////
TEST_Pictest_RXTWO1:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO2:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO3:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO4:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO5:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO6:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO7:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO8:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO9:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO10:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO11:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
TEST_Pictest_RXTWO12:
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	
	;14-4=10
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWO		;4
	
	;半个CLK
;	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO
;	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO
;	JB	PIN_WAVE_RX,TEST_Pictest_RXTWO
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4

	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4

	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4

;	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
;	JNB	PIN_WAVE_RX,TEST_Pictest_RXTWOOK		;4
	
	JMP	TEST_Pictest_RXTWO
	
TEST_Pictest_RXTWOOK:		
	
	MOV	r7,#CONST_DATA_VALUE1		;15
	DJNZ	r7,$		;62
	call	_FUN_LIB_DELAY10
	call	_FUN_LIB_DELAY10

	call	_FUN_LIB_DELAY10
	call	_FUN_LIB_DELAY10
	
;	call	_FUN_LIB_DELAY10
;	call	_FUN_LIB_DELAY10	
	nop
	nop
	nop
	nop
	nop	
;NOP	
;NOP	
	CLR	TR0				;4
	SETB	PIN_OUTPUT_CLK			;4
	MOV	A,#CONST_DATA_VALUE2		;208+CONST_DATA_VALUE2		;2
	MOV	TL0,A				;2
	SETB	TR0				;2
	JMP	TEST_Pictest_Start		;4	
;/////////////////////////////////////////////////////////////////////	
	
;	MOV	REG_WDT_CONTR,#00111111B	;3
;	CPL	PIN_GSM_IO
;	JMP	TEST_CLK_Start03	
;	JMP	TEST_CLK_Start02		;4	
	
;/////////////////////////////////////////////////////////////////////
;TEST_CLK_Start03:
	
;	MOV	REG_WDT_CONTR,#00111111B	;3
;	CPL	PIN_GSM_IO
;	JMP	TEST_CLK_Start03
	
;////////////////////////////////////////////////////////////////////
;_FUN_TEST_Activeinfo:
	
;	CLR	IE1
;	SETB	EX0			;使能外部中断0
;	SETB	IT0			;外部中断0，下降沿触发中断	
;	SETB	EA
	
;TEST_Activeinfo_Loop:
	
;---	MOV	REG_WDT_CONTR,#00111111B
;---	JMP	TEST_Activeinfo_Loop
	
;	CLR	EA	
;	SETB	PIN_WAVE_CHANNEL1	
;	MOV	R7,#15
;	CALL	_FUN_LIB_DELAY
;	CLR	PIN_WAVE_CHANNEL1
	
;TEST_Activeinfo_Loop1:
	
;	MOV	REG_WDT_CONTR,#00111111B
;	CPL	PIN_WAVE_CHANNEL1
;	JMP	TEST_Activeinfo_Loop1
	
	RET
;////////////////////////////////////////////////////////////////////
_FUN_TEST_SerialTX03:
TEST_SerialTX03_LOOP:	


setb	PIN_PWR_GSM
;	CALL	_FUN_HDLC_5830Init
;	MOV	R7,#10
;	CALL	_FUN_LIB_DELAY
;	MOV	R7,#1
;	CALL	_Power_Up
;	MOV	R7,#1
;	CALL	Tx_Carrier_En
;	SETB	PIN_WAVE_CHANNEL1
;SDFDSFDSFDS:	
;	JMP	SDFDSFDSFDS
	SETB	BIT_BUFADDR
	SETB	BIT_SERIALOVERTIMERX
	CLR	BIT_VERIFY
	MOV	R7,#XDATA_TXBUF
	CALL	_FUN_ContactIssue_RX02
	MOV	A,R7
	;---JNZ	TEST_SerialTX03_RxNull
	JZ	TEST_SerialTX03_LOOP011
	JMP	TEST_SerialTX03_RxNull
TEST_SerialTX03_LOOP011:
	MOV	AR7,AR5	
	MOV	AR0,AR5
	
	INC	AR0
	INC	AR0
	INC	AR0
	INC	AR0
	
	;MOVX	A,@R0
	mov	dph,#1
	mov	dpL,r0
	movx	a,@dptr
	MOV	R2,A
	
	INC	R0
	;MOVX	A,@R0
	mov	dph,#1
	mov	dpL,r0
	movx	a,@dptr
	
	PUSH	AR2
	PUSH	ACC
	CALL	_FUN_ContactIssue_TX
	POP	ACC
	POP	AR2
	XCH	A,R2
	
;	CALL	_FUN_HDLC_5830Init
;	MOV	R7,#10
;	CALL	_FUN_LIB_DELAY
;	MOV	R7,#1
;	CALL	_Power_Up
;	MOV	R7,#1
;	CALL	Tx_Carrier_En
;	SETB	PIN_WAVE_CHANNEL1
;SDFDSFDSFDS:
;	JMP	SDFDSFDSFDS
	
TEST_SerialTX03_issue:
	
	PUSH	AR2
	PUSH	ACC
	
	;CALL	_Fun_OBUmain_SysUNSleep	
	;CALL	_FUN_HDLC_5830Init
	;jmp	TEST_SerialTX03_LH

	mov	a,r2
	xrl	a,#3					;rx
	jz	TEST_SerialTX03_H

TEST_SerialTX03_L:
	call	_Write_18_L	
	jmp	TEST_SerialTX03_LH
TEST_SerialTX03_H:
	call	_Write_18_H
TEST_SerialTX03_LH:
	
	MOV	R7,#1
	CALL	_Power_Up	
	MOV	R7,#1
	CALL	Tx_Carrier_En
	
	POP	ACC
	MOV	C,ACC.0
	MOV	BIT_CHANNELFLAG,C
	CALL	_FUN_HDLC_CHANGECHANNEL	
	CALL	_FUN_ContactIssue_INIT02
	
	CLR	RI
	CLR	TI
	CLR	IE0
	CLR	IE1
	CLR	TF0
	CLR	TF1
	CLR	TR0
	CLR	TR1
	
	MOV	IE,#0
	SETB	REN
	SETB	ES			;串口中断
	CLR	tr0			;
	;CLR	IE0			;
	;SETB	EX1			;使能外部中断0
	;SETB	IT1			;外部中断0，下降沿触发中断	
	
	SETB	EA
	
	POP	AR2
	MOV	A,R2
	
	
;sdfsdfdsfds:	
	;cpl	pin_red
	;mov	r7,#200
	;call	_fun_lib_delay
	;CLR	PIN_WAVE_CHANNEL1	
 
	;jmp	sdfsdfdsfds
	;clr	PIN_5830_CE
;	CALL	_FUN_TEST_DISPLAY
	;SETB	PIN_5830_CE
 	
TEST_PN9ZBZeroIntr_PN9:
	CJNE	A,#0,TEST_PN9ZBZeroIntr_ZB
	JMP		_TX_PN9_01
	
TEST_PN9ZBZeroIntr_ZB:
	CJNE	A,#1,TEST_PN9ZBZeroIntr_ALLZERO
	JMP	TEST_PN9ZBZERO_zb
TEST_PN9ZBZeroIntr_ALLZERO:
	CJNE	A,#2,TEST_PN9ZBZeroIntr_RX
	JMP	TEST_PN9ZBZERO_ALLZERO
TEST_PN9ZBZeroIntr_RX:
 	
	CJNE	A,#3,TEST_PN9ZBZeroIntr_Active
	
	SETB	PIN_WAVE_CHANNEL1	
	;MOV	REG_5412AD_P2M0,#00000000B
	;MOV	REG_5412AD_P2M1,#00000001B
	;CLR	PIN_5830_CE
	;MOV	R7,#1
	;CALL	_Power_Up	
;call	_Write_18_H	
	MOV	R7,#0
;---	CALL	Tx_Carrier_En
	 	
	MOV	R7,#1
	CALL	Rx_En	
	;MOV	R7,#1
	;CALL	Tx_Carrier_En
	;MOV	R7,#0
	;CALL	Rx_Carrier_En	
	;---------------------------------	
	;	REG15.15 = 0 OUTPUT data	接收 
	;	REG15.15 = 1 INPUT data		发射
	;---------------------------------
	MOV	R7,#CONST_HOLD_5823RX			;1
	CALL	_FUN_HOLD_DIOPOINT
 	
	JMP	_FUN_TEST_Pictest
TEST_PN9ZBZeroIntr_Active:	
	CJNE	A,#4,TEST_SerialTX03_OVER
	JMP	_FUN_TEST_ACTIVE
TEST_SerialTX03_OVER:
	;JMP	TEST_SerialTX03_OVER
	CLR	pin_red	
	JMP	AP_start
	;RET
TEST_SerialTX03_RxNull:
	
	CALL	_FUN_ContactIssue_INIT02
	SETB	EA
	SETB	ES 			;允许外部中断0
	CLR	IE0			;
	SETB	EX1			;使能外部中断0
	SETB	IT1			;外部中断0，下降沿触发中断	
	
	JMP	OBUMAIN_MASTER_MAINSleep	
;////////////////////////////////////////////////////////////////////
_FUN_TEST_ACTIVE:
	
	;CALL	_FUN_HDLC_5830Init
;---	CLR	PIN_5830_CE
 	;MOV	R7,#1
	;CALL	Tx_Carrier_En
	CALL	_Enter_Sleep_Mode		
	CLR	RI
	CLR	TI
	CLR	IE0
	CLR	IE1
	CLR	TF0
	CLR	TF1
	CLR	TR0
	CLR	TR1		

	CLR	PIN_WAVE_CHANNEL1
	SETB	EX0			; 使能外部中断0
	SETB	IT0			; 外部中断0，下降沿触发中断
	
	SETB	ES
	SETB	EA
	
	
	SETB	PIN_WAVE_CHANNEL1
TEST_ACTIVE_OVER:
	JMP	TEST_ACTIVE_OVER
;////////////////////////////////////////////////////////////////////
TEST_PN9ZBZERO_ALLZERO:
;	MOV	A,#35
;	CALL	_FUN_TEST_DISPLAY
PN9ZBZERO_ALLZERO_LOOP:
	NOP
	NOP
	NOP
	NOP

	NOP
	NOP
	NOP
	NOP

	NOP
	NOP
	NOP
	NOP

	NOP
	NOP
	NOP
	NOP
	;---MOV	REG_WDT_CONTR,#00111111B

	NOP
			
	CPL	PIN_WAVE_CHANNEL1
	;SETB	PIN_WAVE_CHANNEL1
	JMP	PN9ZBZERO_ALLZERO_LOOP	
;////////////////////////////////////////////////////////////////////
TEST_PN9ZBZERO_zb:
	;MOV	A,#33
	;CALL	_FUN_LIB_DELAY
	SETB	PIN_WAVE_CHANNEL1	
PN9ZBZERO_zb_Loop:
	;MOV	REG_WDT_CONTR,#00111111B
	JMP	PN9ZBZERO_zb_Loop
	
;////////////////////////////////////////////////////////////////////
_TX_PN9_01:
 
		
	mov 	r0,#DATA_RXBUF
	mov 	dptr,#pn9cord
	mov 	r3,#64
	mov 	r1,#0
	
pn9cpycm:
	
	mov 	A,r1
	movc 	A,@a+dptr
	;xrl 	A,@r0
	
	mov 	@R0,A
	inc 	R0
	inc 	R1
	djnz 	R3,pn9cpycm
	
;//////////////////////////////////////////////////////////////////////////////
_tx_pn9:


	
	;setb	p2.5
_tx_pn9_data4:
	;---MOV	REG_WDT_CONTR,#00111111B
	mov	r0,#DATA_RXBUF		;2	41
	mov	r5,#64		;2	43
	mov	r7,#7		;2	45
	sjmp	_tx_pn9_data1	;3	48
	
	;-------------------
_tx_pn9_zt4:
        nop			;1	37
        nop			;1	38
_tx_pn9_zt4_b:
	mov	A,@r0		;2	40
	inc	r0		;3	43
        mov	r7,#8		;2	45
        sjmp 	_tx_pn9_data1 ;3	48
	
_tx_pn9_data:
        nop		;1	9
        nop		;1	10
_tx_pn9_data_b:		
        mov 	r6,#2;3	;2	12
        djnz 	r6,$	;4 3x4	24
	nop
	nop
	nop
	nop
	
_tx_pn9_data1:
        cpl	PIN_WAVE_CHANNEL1		;4
        rrc 	a		;1	5
        jc 	_tx_pn9_data2 ;3	8
        
	mov	r6,#3	;2	10
	djnz	r6,$	;4 3x4	22
	
	mov	r4,#0	;2	24
	cpl	PIN_WAVE_CHANNEL1		;4
	djnz	r7,_tx_pn9_data	;4	10
	djnz	r5,_tx_pn9_zt4	;4
	sjmp	_tx_pn9_data4	;3
	
_tx_pn9_data2:
	inc	r4		;3	11
	cjne	r4,#5,_tx_pn9_data3	;4	15
	mov	r4,#0	;2	17
	mov	r6,#7	;2	19
	djnz	r6,$	;4 7x4	47
	nop		;1	48
	cpl	PIN_WAVE_CHANNEL1		;4
	mov	r6,#4	;2	6
        djnz	r6,$	;4 4x4	22
        nop		;1	23
        nop		;1	24
        cpl	PIN_WAVE_CHANNEL1		;4
        djnz	r7,_tx_pn9_data	;4	8(32)
	djnz	r5,_tx_pn9_zt4	;4	12(36)
	sjmp	_tx_pn9_data4	;3	15(39)
_tx_pn9_data3:
	mov	r6,#2	;2	17
	djnz	r6,$	;4 2x4	25
	nop		;1	26
	nop		;1	27
	nop		;1	28
        djnz	r7,_tx_pn9_data	;4	32
	djnz	r5,_tx_pn9_zt4	;4	36
	sjmp	_tx_pn9_data4	;3	39
	
;/////////////////////////////////////////////////////////////

;//////////////////////////////////////////////////////////////////////////////////////
	



	END
;//////////////////////////////////////////////////////////////////////////////////////	
