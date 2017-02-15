;******************************************************************
;描述：CPU接触卡操作程序集[用于用户卡和ESAM卡的基础函数（它的基础函数是串口函数集Searial.asm）]
;_FUN_Contact_INIT		---	复位卡片[ 硬串口 ]
;_FUN_Contact_Channel		---	卡操作[软发送，硬接收(用户卡)或软发送，软接收(ESAM卡)]
;_FUN_Contact_Channel0		---	T0卡操作[软发送，硬接收(用户卡)或软发送，软接收(ESAM卡)]
;_FUN_Contact_Channel1		---	T1卡操作[软发送，硬接收(用户卡)或软发送，软接收(ESAM卡)]
;_FUN_Contact_PPS		---	PPS[设置指令(只针对用户卡)]
;_FUN_Contact_CHANGEBAUD	---	设置波特率[软串口，硬口同时设定(但ESAM卡软接收的波特率暂时不受此函数影响)]
;******************************************************************
NAME	Contact

$INCLUDE(COMMON.INC)
$INCLUDE(Contact.INC)

	RSEG	?pr?Contact?Mater
	USING	0

;---------------------------------------------------------
;描述:复位卡片[ 采用软串口操作]
;外部参数
;Pin_Contact_RST	---	CPU卡复位脚
;PIN_ESAM_RST		---	ESAM卡复位脚
;BIT_T0T1		---	当前卡片协议=1表示T1;	=0表示T0协议;
;BIT_ESAMICC		---	=1  复位用户卡  ; = 0  复位ESAM卡
;内部参数
;	R7		---	临时用
;返回值	
;	R7		---	=#CONST_STATE_TRUE 表示正确=A其它表示错误码
;	BIT_T0T1	---	当前卡片协议=1表示T1;	=0表示T0协议;
;	DATA_RXBUF	---	复位信息
;	R3		---	复位信息长度
;调用子函数
;-------------------------------------------------------------
_FUN_Contact_INIT:
		
	JB	BIT_ESAMICC,Contact_INIT_USERCARD	;当前操作接触卡的类型=1表示用户卡;=0表示ESAM	
	
	;ESAM复位
Contact_INIT_ESAM:
	;--- 强行复位CPU卡 ---
	CLR	PIN_ESAM_RST
	MOV	R7,#030H
	CALL	_FUN_LIB_DELAYSIMPLAY
	SETB	PIN_ESAM_RST
	
	;--- 接收数据 ---
	CLR	BIT_BUFADDR			;BIT_BUFADDR		---	=0，接收数据到内存；=1，接收数据到外存
	SETB	BIT_SERIALOVERTIMERX		;BIT_SERIALOVERTIMERX	---	串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;BIT_VERIFY		---	串口收发是否要加验位,=0不要，=1要
	MOV	R7,#DATA_RXBUF			;R7			---	将要接收字符串buf的指针
	MOV	R3,#0
	CALL	_FUN_SERIAL_RXSOFT
	;---------------
	;JMP	Contact_INIT_OVER
	;MOV	A,#13
	;MOV	A,R3	
	;JMP	_FUN_TEST_DISPLAY
	;-------------------
	
	MOV	R7,#CONST_STATE_TRUE
	JMP	Contact_INIT_RSTDEAL	

	;--- 用户卡复位 ---
Contact_INIT_USERCARD:
jmp	Contact_INIT_ERR02

	;--- 强行复位CPU卡 ---
;---	CLR	Pin_Contact_RST
;	MOV	R7,#255;030H
;	CALL	_FUN_LIB_DELAYSIMPLAY
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$
	MOV	R7,#255
	DJNZ	R7,$	
	
	;---SETB	Pin_Contact_RST
	
	;PUSH	AR7
	;MOV	R7,#1
	;CALL	_FUN_LIB_DELAY
	;POP	AR7
	
	;--- 接收数据 ---
	CLR	BIT_BUFADDR
	SETB	BIT_SERIALOVERTIMERX
	SETB	BIT_VERIFY
	MOV	R7,#DATA_RXBUF
	MOV	R3,#0
	
;	MOV R0,#XDATA_SOFTFIRSTSCANTIME
;	MOV A,#5
;	MOVX @R0,A
	;---CALL	_FUN_SERIAL_RXHARD
	;CALL	_FUN_SERIAL_RXHBYTE
	CALL	_FUN_SERIAL_RXHBYTE
	MOV	A,R7
	JNZ	Contact_INIT_ERR02
	MOV	A,R5
	XRL	A,#3BH
	JNZ	Contact_INIT_ERR02
	CLR	BIT_T0T1
	MOV	R7,#CONST_STATE_TRUE
	
	RET	
Contact_INIT_ERR02:
	MOV	R7,#CONST_STATE_FALSE
	RET
	
;	MOV R0,#XDATA_SOFTFIRSTSCANTIME
;	MOV A,#30H
;	MOVX @R0,A

	;MOV	R7,#CONST_STATE_TRUE
	
	;~~~~~~~~~~调试段~~~~~~~~~~
	; JMP	Contact_INIT_OVER
	; MOV	A,#131
	; MOV	A,R3
	; JMP	_FUN_TEST_DISPLAY
	; JMP	Contact_INIT_HEAD
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
Contact_INIT_RSTDEAL:
	
	;--- 判断复位读取的返回的字节数是否为零 ---	
	MOV	A,R3
	JNZ	Contact_INIT_ZERO
	MOV	R7,#CONST_STATE_FALSE
	MOV	R3,#0
	JMP	Contact_INIT_OVER
	
Contact_INIT_ZERO:
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	;~~~~~~~~~~调试段~~~~~~~~~~
	; JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	XRL	A,#3BH
	JZ	Contact_INIT_HEAD
	MOV	R7,#CONST_STATE_FALSE
	MOV	R3,#0
	JMP	Contact_INIT_OVER
Contact_INIT_HEAD:
	
	;--- 记录当前用户卡的波特率 ---
	MOV	R0,#DATA_RXBUF+2
	MOV	A,@R0
	MOV	R0,#XDATA_HighBaud
	;~~~~~~~~~~调试段~~~~~~~~~~
	; JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;--- 设置协议 ---
	MOV	R0,#DATA_RXBUF + 1
	MOV	A,@R0
	MOV	C,ACC.7
	MOV	BIT_T0T1,C
	
Contact_INIT_OVER:
	CLR	BIT_T0T1
	RET	
;///////////////////////////////////////////////////////////////////////////////////////////////////////
	
	;--- 强行复位CPU卡 ---
	;---CLR	Pin_Contact_RST
	MOV	R7,#030H
	CALL	_FUN_LIB_DELAYSIMPLAY
	;---SETB	Pin_Contact_RST
	
	;--- 读取首字节 ---
	SETB	BIT_VERIFY	
	CALL	_FUN_SERIAL_RXHBYTE
	;~~~~~~~~~~调试段~~~~~~~~~~
	; JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	XRL	A,#3BH
	JZ	Contact_INIT_ReadCtrl
	JMP	Contact_INIT_ERR
Contact_INIT_ReadCtrl:;控制字节
	CALL	_FUN_SERIAL_RXHBYTE
	
	MOV	R3,A
	;~~~~~~~~~~调试段~~~~~~~~~~
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
	;--- 记录卡片协议 ---
	MOV	C,ACC.7
	MOV	BIT_T0T1,C
		
	;RRC	A
	ANL	A,#0FH
        MOV	R6,A
	
	;~~~~~~~~~~调试段~~~~~~~~~~
	; JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~	             
	
;-------------------------------------------------------------------
_cpucardresctl1:
	
        MOV	A,R3			;E9	31
        jbc	acc.4,_cpucardresctl2	;TA1	无 jbc = jb + clr bit
      	jbc	acc.5,_cpucardresctl2	;TB1	00
        jbc	acc.6,_cpucardresctl2	;TC1	00
        jnb	acc.7,_cpucardresdat	;TD1	81

        CALL	_FUN_SERIAL_RXHBYTE
        JB	BIT_RXSerialBaud,_cpucardresctl1_ReadBaud
        SETB	BIT_RXSerialBaud
	MOV	R0,#XDATA_HighBaud	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
_cpucardresctl1_ReadBaud:   
	
        mov	r3,a			;31
        anl	A,#0fh
        cjne	A,#1,_cpucardresctl1
        setb	BIT_rstype
        jmp	_cpucardresctl1
_cpucardresctl2:
        MOV	R3,A
	PUSH	AR3
        call	_FUN_SERIAL_RXHBYTE

        JB	BIT_RXSerialBaud,_cpucardresctl2_ReadBaud
        SETB	BIT_RXSerialBaud
	MOV	R0,#XDATA_HighBaud	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
_cpucardresctl2_ReadBaud:   

        POP	AR3
        jmp	_cpucardresctl1

;-------------------------------------------------------------------

_cpucardresdat:						; 
	MOV	A,r6					; R2	???
	MOV	r3,A					; 
	;~~~~~~~~~~调试段~~~~~~~~~~
	; JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	;INC	R6
_cpucardresdat1:					; 
        CALL	_FUN_SERIAL_RXHBYTE			; 

        JB	BIT_RXSerialBaud,_cpucardresdat1_ReadBaud
        SETB	BIT_RXSerialBaud
	MOV	R0,#XDATA_HighBaud	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
_cpucardresdat1_ReadBaud:   
							; R1 ???
        ;CJNE	r1,#0,_cpucardresdat2			; 
	;MOV	@R1,a					; 
        ;INC	R1					; 
_cpucardresdat2:        				; 
        DJNZ	R6,_cpucardresdat1			; 历史字节

;-------------------------------------------------------------------        
	
        jnb	BIT_rstype,_cpucardresdat3
        call	_FUN_SERIAL_RXHBYTE
	
        cjne	r6,#0,Contact_INIT_ERR
        mov	a,r3
        mov	r6,a

_cpucardresdat3:
	;~~~~~~~~~~调试段~~~~~~~~~~
	; MOV	A,#33
	; JMP	_FUN_TEST_DISPLAY
	; CLR	BIT_T0T1
	
	;MOV	R0,#XDATA_HighBaud	
	;MOV	A,#18H
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	
	MOV	r7,#255
	DJNZ	r7,$
	
	MOV	r7,#255
	DJNZ	r7,$	
	
	MOV	r7,#255
	DJNZ	r7,$
	
	MOV	r7,#255
	DJNZ	r7,$		
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~	

	mov	r7,#CONST_STATE_TRUE
        ret
	RET
	
Contact_INIT_ERR:
	MOV	R7,#CONST_STATE_FALSE
	MOV	R3,#0
	RET
	
;---------------------------------------------------------
;描述:卡操作[ 采用硬串口操作 ]
;外部参数
;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R3			---	将要发送数据的长度
;返回值
;	R3			---	将要发送数据的长度数据的长度
;---------------------------------------------------------
_FUN_Contact_Channel:
	
	;CLR	PIN_5830_CE	
	;---JB	BIT_T0T1,_FUN_Contact_Channel1EX
	JMP	_FUN_Contact_Channel0
		
;Contact cpu card T1	
_FUN_Contact_Channel1EX:
	MOV	R3,#0
	RET
;t1:	
;	MOV	A,#XDATA_TXBUF
;	ADD	A,R3
;	MOV	R1,A
;	DEC	R1
	
;	INC	A
;	INC	A
;	MOV	R0,A
;	INC	A
	
;	MOV	A,R3
;	ADD	A,#3
;	MOV	R2,A	
;Contact_OPRET_LOOP:
;		;MOVX	A,@R1

;		;MOVX	@R0,A

;	DEC	R1
;	DEC	R0
;	DJNZ	R2,Contact_OPRET_LOOP	
;	JMP	_FUN_Contact_Channel1		
;	RET

;---------------------------------------------------------
;描述:T1卡操作[ 采用硬串口操作 ]
;	发送规则是在发送PSAM卡命令前加 0x00 + 0x0x00/0x40 + 长度
;	如要发送给PSAM卡的数据是 0x01,0x02,0x03则
;	完整的发送数据是0x00 + 0x0x00/0x40 + 0x03 + 0x01 + 0x02 + 0x03 + BCC
;外部参数
;	XDATA_TXBUFCPUSTART	---	发送数据绶冲
;	DATA_RXBUFCPUSTART	---	接收数据绶冲
;	BIT_LASTF		---	卡片上一次发送的序号 = 0则为0x00； = 1则表示0x40;
;	R3			---	将要发送数据的长度数据的长度
;	R6			---	BCC
;内部参数
;	XXX			---	YYY
;调用子函数
;返回值
;	R3			---	接收到数据的长度
;	R7			---	接收状态
;-------------------------------------------------------------
_FUN_Contact_Channel1:

	;--- 加入[0x00 + 0x00/0x40]的头部 ---
	;MOV	R0,#XDATA_TXBUFCPUSTART
	;DEC	R0
	;DEC	R0
	;DEC	R0

;	MOV	R0,#XDATA_TXBUF
;	CLR	A
;		;MOVX	@R0,A

;	INC	R0

;	JB	BIT_LASTF,Contact_OPRET1_40
;	CLR	A
;		;MOVX	@R0,A

;	JMP	Contact_OPRET1_NUM

Contact_OPRET1_40:
;	MOV	A,#40H
;		;MOVX	@R0,A

Contact_OPRET1_NUM:
;	CPL	BIT_LASTF
;	INC	R0

;	MOV	A,R3						;LEN
;		;MOVX	@R0,A

	;计算BCC 00 00 05 00 84 00 00 08 05
;	MOV	A,R3
;	ADD	A,#3
;	MOV	R2,A
;	MOV	R6,#0
;	MOV	R0,#XDATA_TXBUF
Contact_OPRET1_SENDBCC:
;		;MOVX	A,@R0

;	XRL	A,R6
;	XCH	A,R6
;	INC	R0
;	DJNZ	R2,Contact_OPRET1_SENDBCC

	;---------MOV	A,#XDATA_TXBUFCPUSTART
;	ADD	A,R3
;	MOV	R0,A
;	MOV	A,R6
;		;MOVX	@R0,A


;	SETB	BIT_BUFADDR					;BIT_BUFADDR	---	= 0，发送的是内存数据；=1，发送的是外存数据
;	SETB	BIT_VERIFY					;BIT_VERIFY	---	串口收发是否要加验位,=0不要，=1要	
;	MOV	R7,#XDATA_TXBUF					;R7		---	将要发送数据的buf
;	MOV	A,R3
;;	ADD	A,#4
;	MOV	R3,A
;	MOV	R5,#CONST_SOFTBYTESP
;	CALL	_FUN_SERIAL_TXSOFT

;	JB	BIT_ESAMICC,Contact_OPRET1_USERCARD
	
Contact_OPRET1_ESAM:
	;---- 接收数据 ----
;	CLR	BIT_BUFADDR
;	SETB	BIT_SERIALOVERTIMERX
;	SETB	BIT_VERIFY
;	MOV	R7,#DATA_RXBUF
;	MOV	R3,#0
;	CALL	_FUN_SERIAL_RXHARD
;	JMP	Contact_OPRET1_RXOVER
Contact_OPRET1_USERCARD:
	;---- 接收数据 ----
;	CLR	BIT_BUFADDR
;	SETB	BIT_SERIALOVERTIMERX
;	SETB	BIT_VERIFY
;	MOV	R7,#DATA_RXBUF
;	MOV	R3,#0
;	CALL	_FUN_SERIAL_RXHARD
Contact_OPRET1_RXOVER:
	
	;--- 验证BCC是否正确 ---
;	MOV	R0,#DATA_RXBUF
;	MOV	R6,#0
;	PUSH	AR3
Contact_OPRET1_ValidateBCC:
;	MOV	A,@R0
;	XRL	A,R6
;	XCH	A,R6
;	INC	R0
;	DJNZ	R3,Contact_OPRET1_ValidateBCC
;	POP	AR3
;;
;	MOV	A,R6
;	MOV	R7,A

Contact_OPRET1_OVER:

	RET

;---------------------------------------------------------
;描述:T0卡操作[ 采用软串口操作 ]
;	发送规则：先发送CLS + INC + P1 + P2 + LC + DATAs
;	如： 00A40000023F00	---	(CLS + INC + P1 + P2 + LC + DATA)
;	再如:0084000008		---	(CLS + INC + P1 + P2 + LC + LE)
;方式一
;	1、发送数据：CLS + INC + P1 + P2 + LC
;	2、接收数据：INC
;	3、发送数据：Data 或 LE
;	4、接收数据：61 + Len(数据长度) 或 SW12[这种情况没有5、6步]
;	5、发送数据：长度 00 + 0C + 00 + 00 + Len(数据长度)
;	6、接收数据：数据 + SW12
;方式二
;	1、发送数据：CLS + INC + P1 + P2 + LC
;	2、接收数据：INC + DATA

;外部参数
;	BIT_GETRESULT		=1表示取T0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效)
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R3			---	将要发送数据的长度

;内部参数
;返回值:
;	R7		---	执行状态
;	R3		---	接收长度
;调用子函数
;-------------------------------------------------------------
_FUN_Contact_Channel0:
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#31
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	

	;1、发送数据：CLS + INC + P1 + P2 + LC
	;发送数据
	PUSH	AR3
	SETB	BIT_BUFADDR					;BIT_BUFADDR	---	= 0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY					;BIT_VERIFY	---	串口收发是否要加验位,=0不要，=1要
	
	;记录接收绶冲起点
	MOV	A,R5
	MOV	R0,#DATA_XDATAP
	MOV	@R0,A	
	
	;记录发送绶冲起点
	MOV	A,R7
	MOV	R0,#DATA_DATAP	
	MOV	@R0,A
	
	;记录发送命令字
	INC	A		
	MOV	R0,A
	MOV	A,@R0				
	MOV	R6,A			
	;~~~~~~~~~~~~~~~~~~
	;XRL	A,#0B2H						;0A4H
	;JNZ	Contact_Channel0_Start
	;JMP	TESTContact_Channel0_Start		
	;inc	r0
	;inc	r0
	;inc	r0
	;inc	r0	
	;MOV	A,@R0	
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~	
Contact_Channel0_Start:
	
	;--- 发送指令(5 Byte) ---
	MOV	R0,#DATA_DATAP
	MOV	A,@R0
	MOV	R7,A
	MOV	R5,#CONST_SOFTBYTESP
	MOV	R3,#5
	CLR	BIT_BUFADDR					;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY					;串口收发是否要加验位,=0不要，=1要						
	PUSH	AR6
	CALL	_FUN_SERIAL_TXSOFT
	POP	AR6
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#32
	;MOV	A,R6
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	;--- 计算将要接收卡片返回数据的长度 ---
	;如果指令长度<=5，则接收长度为Le + 2，如果>=6，则应是0[除命令字，但如果接收出错，则为SW12，应再收一个字节然后返回]
	POP	AR3
	MOV	AR2,AR3
	
	PUSH	AR2
	CJNE	R3,#6,$+3
	JC	Contact_Channel0_RXOther
Contact_Channel0_RX1:;接收1个字节的长度
	MOV	R3,#0
	JMP	Contact_Channel0_RXOver
Contact_Channel0_RXOther:	;接收N个字节的长度
	MOV	R0,#DATA_DATAP	
	MOV	A,@R0
	ADD	A,#4
	MOV	R0,A
	MOV	A,@R0
	INC	A
	INC	A
	MOV	R3,A	
Contact_Channel0_RXOver:
	
	;--- 接收命令字	---
	PUSH	AR3
	JB	BIT_ESAMICC,Contact_Channel0_USERCARDRXCMD
Contact_Channel0_ESAM0RXCMD:	
	SETB	BIT_SERIALOVERTIMERX		;串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要
	SETB	BIT_SERFIRBYTE			;=1 启用长超时接收（用于接收卡片第一个字节返回）,启用短超时接收(用于接收卡片第一个之后的字节返回)
	CALL	_FUN_SERIAL_RXSBYTE		;软串口接收单个字节的数据
	JMP	Contact_Channel0_RXCMD
Contact_Channel0_USERCARDRXCMD:
	CALL	_FUN_SERIAL_RXHBYTE		;硬串口接收单个字节的数据
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#33
	;MOV	A,R7
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
Contact_Channel0_RXCMD:	
	
	POP	AR3	;接收指令长度
	POP	AR2	;发送指令长度
	
	MOV	A,R7
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#34
	;MOV	A,R7
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	XRL	A,#CONST_STATE_TRUE
	JZ	Contact_Channel0_CMDState	;接收正确	
	JMP	Contact_Channel0_ERR		;如果接收出错，则出错返回
Contact_Channel0_CMDState:
	MOV	A,R5
	;~~~~~ 调用测试段 ~~~~~	
;	XRL	A,#0B4H
;	JNZ	Contact_Channel0_TEST01
;	SETB	BIT_CKXT
	;CALL	_fun_test_display
;Contact_Channel0_TEST01:
;	MOV	A,R5
	;MOV	A,#35
	;MOV	A,R5
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	XRL	A,R6		;查看命令字，是否和发关的一样
	JZ	Contact_Channel0_CMDOK
	
	;--- 如果命令字不对，表示收到的是SW12 ---
Contact_Channel0_CMDErr:	;命令字不对
	PUSH	AR5
	SETB	BIT_SERIALOVERTIMERX		;串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要
	SETB	BIT_SERFIRBYTE			;=1 启用长超时接收（用于接收卡片第一个字节返回）,启用短超时接收(用于接收卡片第一个之后的字节返回)	
	CALL	_FUN_SERIAL_RXSBYTE
	MOV	AR4,AR5
	POP	AR5	
	
	MOV	A,R7
	XRL	A,#CONST_STATE_TRUE
	JZ	Contact_Channel0_RXSW2OK		;接收SW02正确
	JMP	Contact_Channel0_ERR
Contact_Channel0_RXSW2OK:		
	
	MOV	R3,#2			;接收长度为2
	;接收绶冲起点
	MOV	R0,#DATA_XDATAP		
	MOV	A,@R0	
	MOV	R0,A
	
	;保存sw12到接收绶冲并返回
;	MOV	A,R4
;		;MOVX	@R0,A

;	INC	R0
;	MOV	A,R5

	MOV	A,R5
		;MOVX	@R0,A

	;push	dph
	;push	dpl
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
	JMP	Contact_Channel0_OVER	;接收SW12，然后返回
	;JMP	Contact_Channel0_ERR								;如果接收出错，则出错返回
	
	;--- 接收命命字正确 ---
Contact_Channel0_CMDOK:
		
	;MOV	AR2,AR3				;保存接收长度
	;POP	AR3				;弹出发送长度
	MOV	A,R2
	CJNE	A,#6,$+3	
	JNC	Contact_Channel0_MODE1
	JMP	Contact_Channel0_MODE2
Contact_Channel0_MODE1:				;T0方式一		接收长度必须 = 1
	

	;~~~~~~~ 调用测试段 ~~~~~
	;MOV	A,#36
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	;发送数据：Data 或 Lc
	CLR	BIT_BUFADDR			;BIT_BUFADDR	---	= 0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY			;BIT_VERIFY	---	串口收发是否要加验位,=0不要，=1要
	MOV	R0,#DATA_DATAP
	MOV	A,@R0
	ADD	A,#5
	MOV	R7,A	
	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~
	;MOV	AR0,AR7
	;INC	R0
	;MOV	A,@R0
	;MOV	A,R2
	;jmp	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	MOV	R5,#CONST_SOFTBYTESP
	MOV	A,R2		;卡片指令长度暂存在R2中
	CLR	C
	SUBB	A,#5
	MOV	R3,A
	CALL	_FUN_SERIAL_TXSOFT	
	
	;4、接收数据：61 + Len(数据长度)
	JB	BIT_ESAMICC,Contact_Channel0_USERCARD02
Contact_Channel0_ESAM02:
	
	;---- 接收数据 ----
	SETB	BIT_BUFADDR			;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		;;软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要	
	;---MOV	R7,#DATA_RXBUF
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A
	MOV	R3,#2	
	CALL	_FUN_SERIAL_RXSOFT
	JMP	Contact_Channel0_RXOVER02
Contact_Channel0_USERCARD02:
	;---- 接收数据 ----
	SETB	BIT_BUFADDR			;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		;;软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要	
	;CLR	BIT_ISFRX			;=0表示串口第一个字节接收   ;1表示第一个字节不接收		
	;--- MOV	R7,#DATA_RXBUF
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A
	MOV	R3,#2
	CALL	_FUN_SERIAL_RXHARD
Contact_Channel0_RXOVER02:
	;~~~~~~~ 调用测试段 ~~~~~
	;MOV	A,#37
;	JNB	BIT_CKXT,Contact_Channel0_TEST02
;	MOV	A,R3
;	CALL	_FUN_TEST_DISPLAY
;Contact_Channel0_TEST02:
	;~~~~~~~~~~~~~~~~~~~~~~~~		
		
	MOV	A,R3
	XRL	A,#2
	;---JNZ	Contact_Channel0_ERR	
	JZ	Contact_Channel0_RX61Right
	JMP	Contact_Channel0_ERR
	
Contact_Channel0_RX61Right:	
	
	;返回值此时有可能是61 + 长度,也可能是SW12
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R0,A
		;MOVX	A,@R0
	;push	dph
	;push	dpl
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;pop	dpl
	;pop	dph
	XRL	A,#61H
	
	;~~~~~~~ 调用测试段 ~~~~~
;	JNB	BIT_CKXT,Contact_Channel0_TEST02
	;MOV	A,R3
;	CALL	_FUN_TEST_DISPLAY
;Contact_Channel0_TEST02:	
	;MOV	A,#38
	;MOV	A,R3
	;inc	r0
	;	;MOVX	A,@R0
;	MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR	

	;CALL	_FUN_TEST_DISPLAY
			
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	JZ	Contact_Channel0_61LEN
	JMP	Contact_Channel0_OVER
	
Contact_Channel0_61LEN:
	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~	
	;JNB	BIT_CKXT,Contact_Channel0_TEST02
	;MOV	A,R3
;	CLR	A
;	MOV	C,BIT_GETRESULT
;	MOV	ACC.0,C
	;CALL	_FUN_TEST_DISPLAY
;Contact_Channel0_TEST02:	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	;~~~~~~~ 调用测试段 ~~~~~
	;MOV	A,#38
;	clr	a
;	mov	c,BIT_GETRESULT
;	mov	acc.0,c
;	CALL	_FUN_TEST_DISPLAY

	;~~~~~~~~~~~~~~~~~~~~~~~~	
	JB	BIT_GETRESULT,Contact_Channel0_GetResult	
	JMP	Contact_Channel0_OVER;结束接收
	
Contact_Channel0_GetResult:;最返回结果
	
	;--- 接收到的长度 ---
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	INC	A
	MOV	R0,A
		;MOVX	A,@R0
	;push	dph
	;push	dpl
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;pop	dpl
	;pop	dph
	
	cjne	a,#120,$+3
	jc	Contact_Channel0_GetResultrx
	;call	_fun_test_display
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#31
	;mov	a,sp
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	jmp	Contact_Channel0_ERR
	
Contact_Channel0_GetResultrx:
	PUSH	ACC
	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~
	;为适应握奇的ESAM卡，加了40us
	jb	BIT_ESAMICC,Contact_Channel0_GetC0
	push	ar7
	mov	r7,#240
	djnz	r7,$
	pop	ar7
Contact_Channel0_GetC0:
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	;5、发送数据：长度 00 + 0C + 00 + 00 + Len(数据长度)
	;---MOV	R0,#XDATA_TXBUF
	MOV	R0,#DATA_DATAP
	MOV	A,@R0	
	MOV	R0,A
	
	CLR	A
	MOV	@R0,A
	INC	R0
	MOV	A,#0C0H
	MOV	@R0,A
	INC	R0		
	CLR	A
	MOV	@R0,A
	INC	R0
	MOV	@R0,A
	INC	R0
	POP	ACC
	MOV	@R0,A
	
	;--- 计算实际将要接收的数据长度 ---
	INC	A
	INC	A
	MOV	R3,A
	PUSH	AR3
	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
	CLR	BIT_BUFADDR	;BIT_BUFADDR	---	= 0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY	;BIT_VERIFY	---	串口收发是否要加验位,=0不要，=1要
	;---MOV	R7,#XDATA_TXBUF	;R7		---	将要发送数据的buf
	MOV	R0,#DATA_DATAP
	MOV	A,@R0
	MOV	R7,A
	
	MOV	R5,#CONST_SOFTBYTESP
	MOV	R3,#5
	CALL	_FUN_SERIAL_TXSOFT
		
	;--- 接收C0 ---
Contact_Channel0_rxc00:
	JB	BIT_ESAMICC,Contact_Channel0_USERCARDRXC0
Contact_Channel0_ESAM0RXC0:	
	SETB	BIT_SERIALOVERTIMERX		;串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要
	SETB	BIT_SERFIRBYTE			;=1 启用长超时接收（用于接收卡片第一个字节返回）,启用短超时接收(用于接收卡片第一个之后的字节返回)
	CALL	_FUN_SERIAL_RXSBYTE		;软串口接收单个字节的数据
	JMP	Contact_Channel0_RXC0
Contact_Channel0_USERCARDRXC0:
	CALL	_FUN_SERIAL_RXHBYTE		;硬串口接收单个字节的数据
Contact_Channel0_RXC0:	
	POP	AR3				;

;	MOV	A,R7
;	XRL	A,#CONST_STATE_TRUE
;	JZ	Contact_Channel0_RXC0STATEOK	;接收正确	
;	JMP	Contact_Channel0_ERR		;如果接收出错，则出错返回
;Contact_Channel0_RXC0STATEOK:
	MOV	A,R5
	XRL	A,#0C0H

	JZ	Contact_Channel0_RXC0OK
	JMP	Contact_Channel0_ERR		;如果接收出错，则出错返回	
Contact_Channel0_RXC0OK:
		
	;6、接收数据：数据 + SW12
	JB	BIT_ESAMICC,Contact_Channel0_USERCARD03
Contact_Channel0_ESAM03:
	;---- 接收数据 ----
	SETB	BIT_BUFADDR			;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		;;软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要	
	;CLR	BIT_ISFRX			;=0表示串口第一个字节接收   ;1表示第一个字节不接收		
	;---MOV	R7,#DATA_RXBUF
	;MOV	R3,A		
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A
	CALL	_FUN_SERIAL_RXSOFT
	JMP	Contact_Channel0_RXOVER03
Contact_Channel0_USERCARD03:
	;---- 接收数据 ----
	SETB	BIT_BUFADDR			;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		;;软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要	
	;CLR	BIT_ISFRX			;=0表示串口第一个字节接收   ;1表示第一个字节不接收		
	;---MOV	R7,#DATA_RXBUF
	;MOV	R3,A	
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A	
	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	CALL	_FUN_SERIAL_RXHARD
Contact_Channel0_RXOVER03:

	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~	
;	MOV	A,R3	
;	MOV	R0,#DATA_XDATAP
;	MOV	A,@R0
;	add	a,r3
;	dec	a
;	dec	a
;	MOV	R0,A
;		;MOVX	A,@R0

;	JMP	_FUN_TEST_DISPLAY	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	MOV	A,R3
	;CJNE	A,#4,$+3
	CJNE	A,#2,$+3
	JC	Contact_Channel0_ERR

	;---MOV	R7,#DATA_RXBUF
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A		
	JMP	Contact_Channel0_OVER
Contact_Channel0_MODE2:			;T0方式二,接收长度必须 > 1

	JB	BIT_ESAMICC,Contact_Channel0_USERLe
Contact_Channel0_ESAMLe:;接收ESAM卡LE数据

	;---- 接收数据 ----
	SETB	BIT_BUFADDR			; =0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		; 软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			; 串口收发是否要加验位,=0不要，=1要
	;CLR	BIT_ISFRX			; = 0 表示串口第一个字节接收   ;1 表示第一个字节不接收	
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A
	CALL	_FUN_SERIAL_RXSOFT
	
	JMP	Contact_Channel0_MODEOVER
Contact_Channel0_USERLe:;接收用户卡LE数据
	
	;---- 接收数据 ----
	SETB	BIT_BUFADDR			; =0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		; 软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			; 串口收发是否要加验位,=0不要，=1要	
	;CLR	BIT_ISFRX			; =0表示串口第一个字节接收   ;1表示第一个字节不接收		
	MOV	R0,#DATA_XDATAP
	MOV	A,@R0
	MOV	R7,A

	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~
	;MOV	A,R3
	;MOV	A,#33
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	CALL	_FUN_SERIAL_RXHARD

	JMP	Contact_Channel0_OVER	;操作完成,函数返回	
Contact_Channel0_MODEOVER:
	
Contact_Channel0_OVER:
	;~~~~~~~~~~~~~调试段~~~~~~~~~~~~~
	;为适应握奇的ESAM卡，加了40us
	jb	BIT_ESAMICC,Contact_Channel0_Getover
	push	ar7
	mov	r7,#240
	djnz	r7,$
	pop	ar7
Contact_Channel0_Getover:
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	RET	
	
	

Contact_Channel0_ERR:
	MOV	R3,#0			;临时单元
	MOV	R7,#CONST_STATE_FALSE	

	RET



Contact_Channel0_ERR001:
	MOV	R3,#0			;临时单元
	MOV	R7,#134	
	RET

Contact_Channel0_ERR002:
	MOV	R7,A
	RET
	
	
;---------------------------------------------------------	
;描述:设置波特率
;外部参数
;R7	---	CONST_BAUD_9600:表示 9600
;		CONST_BAUD_38400:表示 38400
;		CONST_BAUD_115200:表示 115200
;		CONST_BAUD_115200PC 表示发送正常的115200数据
;---------------------------------------------------------	
_FUN_Contact_CHANGEBAUD:
	
	CJNE	R7,#CONST_BAUD_9600,Contact_CHANGEBAUD38400
	;--- 设置波特率为9600 ---
	SETB	BIT_9600
	
	;设置软串口波特率
	MOV	R0,#DATA_VARBAUDFULL
	MOV	@R0,#CONST_BAUD_FULL9600
	MOV	R0,#DATA_VARBAUDHALF
	MOV	@R0,#CONST_BAUD_HALF9600
	
	;设置硬串口波特率
	;MOV	TH1,#CONST_BAUD_HAND9600
	;MOV	TL1,#CONST_BAUD_HAND9600
	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND9600
	
	JMP	Contact_CHANGEBAUD_OVER
Contact_CHANGEBAUD38400:
	CJNE	R7,#CONST_BAUD_38400,Contact_CHANGEBAUD115200
	;--- 设置波特率为38400 ---
	CLR	BIT_9600

	;设置软串口波特率
	MOV	R0,#DATA_VARBAUDFULL
	MOV	@R0,#CONST_BAUD_FULL38400
	MOV	R0,#DATA_VARBAUDHALF
	MOV	@R0,#CONST_BAUD_HALF38400

	;设置硬串口波特率
	;MOV	TH1,#CONST_BAUD_HAND38400
	;MOV	TL1,#CONST_BAUD_HAND38400
	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND38400
	
	JMP	Contact_CHANGEBAUD_OVER
Contact_CHANGEBAUD115200:
	CJNE	R7,#CONST_BAUD_115200,Contact_CHANGEBAUD115200PC
	;--- 设置波特率为115200 ---
	CLR	BIT_9600

	;设置软串口波特率
	MOV	R0,#DATA_VARBAUDFULL
	MOV	@R0,#CONST_BAUD_FULL115200
	MOV	R0,#DATA_VARBAUDHALF
	MOV	@R0,#CONST_BAUD_HALF115200
	
	;设置硬串口波特率
	;MOV	TH1,#CONST_BAUD_HAND115200
	;MOV	TL1,#CONST_BAUD_HAND115200
	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND115200
	
	JMP	Contact_CHANGEBAUD_OVER
Contact_CHANGEBAUD115200PC:
	CJNE	R7,#CONST_BAUD_115200PC,Contact_CHANGEBAUD230000
	
	;--- 设置波特率为115200 ---
	CLR	BIT_9600
	
	;设置硬串口波特率
	;MOV	TH1,#CONST_BAUD_HAND115200PC
	;MOV	TL1,#CONST_BAUD_HAND115200PC

	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND115200PC

	JMP	Contact_CHANGEBAUD_OVER
	
Contact_CHANGEBAUD230000:
	CJNE	R7,#CONST_BAUD_230000,Contact_CHANGEBAUD38400PC
	
	;--- 设置波特率为115200 ---
	CLR	BIT_9600
	
	;设置软串口波特率
	MOV	R0,#DATA_VARBAUDFULL
	MOV	@R0,#CONST_BAUD_FULL230000
	MOV	R0,#DATA_VARBAUDHALF
	MOV	@R0,#CONST_BAUD_HALF230000
	
	;设置硬串口波特率
	;MOV	TH1,#CONST_BAUD_HAND230000
	;MOV	TL1,#CONST_BAUD_HAND230000		

	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND230000
	JMP	Contact_CHANGEBAUD_OVER
Contact_CHANGEBAUD38400PC:
	CJNE	R7,#CONST_BAUD_38400PC,Contact_CHANGEBAUD9600PC
	;--- 设置波特率为115200 ---
	CLR	BIT_9600
	
	;设置硬串口波特率
	;MOV	TH1,#CONST_BAUD_HAND115200PC
	;MOV	TL1,#CONST_BAUD_HAND115200PC
	
	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND38400PC
	JMP	Contact_CHANGEBAUD_OVER
Contact_CHANGEBAUD9600PC:
	CLR	BIT_9600
	MOV	Reg_Sys_BRT,#CONST_BAUD_HAND9600PC
Contact_CHANGEBAUD_OVER:

	RET
;---------------------------------------------------------
;描述:PPS操作设置
;	FF + 10[T0] / 11[T1] +  13[BAUD代码] + BCC
;	FF,10,13,FC
;外部参数
;	R7		---	波特率代码
;	DATA_RXBUF	---	接收数据绶冲
;	BIT_T0T1	---	当前卡片协议=1表示T1;	=0表示T0协议;
;内部参数
;	XDATA_TXBUF	---	发送数据绶冲
;	R7		---	BAUD代码值
;	R3		---	将要发送数据的长度
;	R6		---	BCC
;调用子函数
;-------------------------------------------------------------
_FUN_Contact_PPS:
	
	MOV	R6,#0
	
	;MOV	R0,#XDATA_TXBUF
	MOV	R0,#DATA_RXBUF+80
	MOV	A,#0FFH
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	MOV	@R0,A
	XRL	A,R6
	XCH	A,R6
	
	INC	R0
	
	;--- 协议代码 ---
	;JNB	BIT_T0T1,Contact_PPS_T0
Contact_PPS_T1:
	
	;MOV	A,#011H
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	;XRL	A,R6
	;XCH	A,R6
	;JMP	Contact_PPS_OVER
Contact_PPS_T0:
	MOV	A,#010H
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	MOV	@R0,A
	XRL	A,R6
	XCH	A,R6
Contact_PPS_OVER:

	INC	R0	
	MOV	A,R7
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	MOV	@R0,A
	XRL	A,R6
	XCH	A,R6

	INC	R0
	MOV	A,R6
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	MOV	@R0,A

	SETB	BIT_ESAMICC
	;SETB	BIT_BUFADDR	;BIT_BUFADDR	---	= 0，发送的是内存数据；=1，发送的是外存数据
	CLR	BIT_BUFADDR	;BIT_BUFADDR	---	= 0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY	;BIT_VERIFY	---	串口收发是否要加验位,=0不要，=1要
	;MOV	R7,#XDATA_TXBUF	;R7		---	将要发送数据的buf
	MOV	R7,#DATA_RXBUF+80	;R7		---	将要发送数据的buf
	MOV	R5,#2
	MOV	R3,#4
	CALL	_FUN_SERIAL_TXSOFT

	RET
;///////////////////////////////////////////////////////////////////////////////////
_FUN_TESTContact_Channel0:	
	CLR	A
;TESTContact_Channel0_OVER:
	
	RET

TESTContact_Channel0_ERR:
;	MOV	R3,#0			;临时单元
;	MOV	R7,#CONST_STATE_FALSE	

	RET
	


;///////////////////////////////////////////////////////////////////////////////////
	END
