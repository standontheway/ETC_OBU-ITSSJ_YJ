;**********************************************************************
;描述：DSRC通讯程序集
;函数申明
;_FUN_DSRC_VST					---	VST配置函数[只组装数据，不发送数据]
;_FUN_DSRC_NSpecial				---	非广播DSRC信号处理程序入口(除VST，其它DSRC信号处理由此进入)
;	附属序段:SEG_DSRCSpecial_ComplexSeg	---	DSRC复用段（处理从'字段头'到'FildID||ChannelID'之间的数据）
;	附属序段:SEG_DSRC_GETSendBufLen		---	记录HDLC发送绶冲长度
;	附属序段:SEG_DSRC_GetSecure		---	GetSecure配置函数
;	附属序段:SEG_DSRC_TransferChannel	---	TransferChannel配置函数
;	附属序段:SEG_DSRC_SetMMI		---	SetMMI配置函数
;	
;	附属序段:SEG_DSRC_SetSecure(空)		---	SetSecure配置函数[只组装数据，不发送数据]
;	附属序段:SEG_DSRC_GetRand(空)		---	GetRand配置函数[只组装数据，不发送数据]
			
;函数关系
;	DSRC信号 -> _FUN_DSRC_NSpecial
;			|
;		SEG_DSRCSpecial_ComplexSeg(DSRC复用段) <--------|
;			|					|					  	
;			|-----> SEG_DSRC_GetSecure -------------|
;			|		|			|
;			|	     <有后继段> ------ok------->|
;			|		|NO			|
;			|		结束(RET)		|
;			|					|
;			|-----> SEG_DSRC_TransferChannel ------>|
;			|		|			|
;			|	     <有后继段> ------ok------->|
;			|		|NO			|
;			|		结束(RET)		|
;			|					|
;			|-----> SEG_DSRC_SetMMI			|
;			|		|			|
;			|	     <有后继段> ------ok------->|
;			|		|NO
;			|		结束(RET)
;			|----->SEG_DSRC_SetSecure(空)
;			|----->SEG_DSRC_GetRand(空)
;
;**********************************************************************
NAME	DSRC

$INCLUDE(DSRC.INC)
$INCLUDE(COMMON.INC)
	
	RSEG	?pr?DSRC?Mater
	USING	0
	
;--------------------------------------------------------------------------
;描述:;VST配置函数[只组装数据，不发送数据]
;外部参数
;DATA_RXBUF	---	接收到的 BST 绶冲
;XDATA_TXBUF	---	将要发送 VST
;内部参数:
;返回值
;R3		---	长度
;R7		---	状态码。如果接收到的bst不正确就返回错误代码
;XDATA_TXBUF	--- 	发送绶冲
;DATA_DSRCLEN	---	dsrc数据帧长度，以便在重发时使用
;--------------------------------------------------------------------------	
_FUN_DSRC_VST:
	
CLR	BIT_privateInfo
CLR	BIT_gbICCInfo
	
		
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	CLR	BIT_Cellinfo
	MOV	R1,#DATA_RXBUF + 18			;Parameter
	MOV	A,@R1
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;MOV	R1,#DATA_RXBUF + 19			;Parameter
	;MOV	A,@R1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;MOV	C,ACC.1
	;MOV	BIT_ISCell,C
	;mov	a,#33
	;call	_fun_test_display
	
	JnB	acc.1,_FUN_DSRC_VSTzc
	JMP	_FUN_DSRC_VSTCell
_FUN_DSRC_VSTzc:	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	;设置MAC ID
	MOV	DPTR,#STR_SYS_OBUID
	MOV	R7,#XDATA_TXBUF
	CALL	_FUN_LIB_FLASHTOXDATA
	
	;MOV	R3,#CONST_SYS_OBUIDLEN
	;CALL	_FUN_LIB_FLASHTODATAEX
	
	;记录天线ID & 记录Unix时间 [ 因为 XDATA_BeaconID 和 XDATA_UnixTime 空间定成连体,所以一齐Copy]
	;XDATA_BeaconID
	;可能到时还要将两个值放入到flash中
	MOV	R1,#DATA_RXBUF + 8
	MOV	R0,#XDATA_BeaconID
	MOV	R2,#CONST_Flash_BeaconIDUnixTimeLen
DSRC_VST_BeanconLoop:
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R1
	INC	R0
	DJNZ	R2,DSRC_VST_BeanconLoop
	
	;~~~~~~~~ 调用测试段 ~~~~~
	;MOV	R0,#XDATA_UnixTime
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	;设置VST基本信息
	MOV	DPTR,#STR_DSRC_VST
	MOV	R7,#XDATA_TXBUF + 4
	CALL	_FUN_LIB_FLASHTOXDATA
	
	;记录信道号
	MOV	R1,#DATA_RXBUF + 16
	MOV	A,@R1
	MOV	C,ACC.0
	MOV	BIT_CHANNELFLAG,C 
	
	;JNB	BIT_CHANNELFLAG,DSRC_VST_BeanconLoop1
	;PUSH	AR1
	;PUSH	AR0
	
	;~~~~~~~~ 调用测试段 ~~~~~
	;MOV	A,#1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~
	
	;CALL	_FUN_HDLC_CHANGECHANNEL			;设置通讯信道
	;POP	AR0
	;POP	AR1
	
	;400us	
DSRC_VST_BeanconLoop1:
		
	;设置返回信道号
	MOV	R0,#XDATA_TXBUF + 8
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	C,BIT_CHANNELFLAG
	MOV	ACC.0,C
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;设置 ApplicationList
	INC	R1
	INC	R0
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;设置Parameter & 无扩展, AID = 1 (ETC)
	INC	R1
	INC	R0
	MOV	A,@R1
	SETB	ACC.7
	SETB	ACC.6	;Paramter
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	;Bit5――gbICCInfo存在标志
	;BIT_ISContact	
	MOV	R0,#XDATA_TXBUF + 12
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
;	JNB	BIT_INSERTCARD,DSRC_VST_infoo
;	SETB	C
;	JNB	BIT_ISContact,DSRC_VST_privateInfo
;DSRC_VST_DgbICCInfo:
;	MOV	ACC.5,C
;	JMP	DSRC_VST_infoo
;DSRC_VST_privateInfo:
;	MOV	ACC.6,C
;DSRC_VST_infoo:
;	;MOV	C,BIT_INSERTCARD
;	;MOV	ACC.5,C


	MOV	R0,#XDATA_TXBUF + 14
	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
		
	;--- 从EPPROM中读取IC卡信息 ---
	;JNB	BIT_INSERTCARD,DSRC_VST_NotUserCard	;没有插卡跳过不读不读IC卡信息
	
	MOV	R1,#DATA_RXBUF + 18			;Parameter
	MOV	A,@R1
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;MOV	R1,#DATA_RXBUF + 19			;Parameter
	;MOV	A,@R1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	JNB	ACC.6,DSRC_VST_NotUserCard		;没有扩展应用时跳过不读不读IC卡信息
	
	MOV	R1,#DATA_RXBUF + 19
	MOV	A,@R1
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;MOV	R1,#DATA_RXBUF + 19			;Parameter
	;MOV	A,@R1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	JNB	ACC.7,DSRC_VST_NotUserCard		;没有扩展应用时跳过不读不读IC卡信息		
		
	MOV	R1,#DATA_RXBUF + 18			;Parameter
	MOV	A,@R1		
	JMP	DSRC_VST_PRE				;BST带预处理流程
	
	;没有用户卡或没有扩展应用时
DSRC_VST_NotUserCard:	

	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#23
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	;从 EPPROM 中读取 26 Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,#26
	CALL	_RDFlashXR

	MOV	R0,#XDATA_TXBUF + 40
	JMP	DSRC_VST_SEGVSTTAIL

DSRC_VST_PRE: 	;BST 带预处理流程

	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#23
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	;---JNB	ACC.0,DSRC_VST_PREAID00
	JMP	DSRC_VST_PREAID01
	;ACC.0=0/=1
DSRC_VST_PREAID00:	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#24
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	;---从 EPPROM 中读取 26 Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,#26
	CALL	_RDFlashXR
		
	;1 设置第13个字节		
	;2 获取随机数及ESAM卡复位信息
	MOV	R0,#XDATA_TXBUF+12	
	MOV	R1,#DATA_RXBUF+19	;Init Mode
	MOV	A,@R1

	CJNE	A,#0,DSRC_VST_InitMode01
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#25
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#90H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R0,#XDATA_TXBUF+40
	MOV	A,#1DH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R0,#XDATA_TXBUF+49
	MOV	A,#50H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;复位卡片
	;CLR	PIN_ESAM_RST
	;MOV	R7,#20H
	;SETB	PIN_ESAM_RST
	
	CLR	BIT_ESAMICC	
	setb	BIT_BUFADDR			;BIT_BUFADDR		---	=0，接收数据到内存；=1，接收数据到外存
	SETB	BIT_SERIALOVERTIMERX		;BIT_SERIALOVERTIMERX	---	串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;BIT_VERIFY		---	串口收发是否要加验位,=0不要，=1要
	MOV	R7,#XDATA_TXBUF+50		;R7			---	将要接收字符串buf的指针
	MOV	R3,#000			;	
	CALL	_FUN_SERIAL_RXSOFT		;
	MOV	A,R3				;
	
	;选DF01
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF + 72
	MOV	R3,#0dFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
	;取随机数	
	MOV	DPTR,#STR_DSRC_GETRND
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	SETB	BIT_GETRESULT		;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
	CLR	BIT_ESAMICC		;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
	MOV	R7,#XDATA_TXBUF	+ 41	;	R7			---	发送绶冲指针(内存)
	MOV	R5,#DATA_RXBUF		;	R5			---	接收送绶冲指针(外存)
					;	R3			---	将要发送数据的长度	
	
	CALL	_FUN_Contact_Channel
	CLR	A
	MOV	R0,#XDATA_TXBUF+45
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	R0,#XDATA_TXBUF + 65
	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#26
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	JMP	DSRC_VST_InitModeOver
DSRC_VST_InitMode01:
	CJNE	A,#1,DSRC_VST_InitMode02
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#80H	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R0,#XDATA_TXBUF+40
	MOV	A,#1DH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;取随机数
	MOV	DPTR,#STR_DSRC_GETRND
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	
	SETB	BIT_GETRESULT		;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
	CLR	BIT_ESAMICC		;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
	MOV	R7,#XDATA_TXBUF	+ 41	;	R7			---	发送绶冲指针(内存)
	MOV	R5,#DATA_RXBUF		;	R5			---	接收送绶冲指针(外存)
					;	R3			---	将要发送数据的长度	
	CALL	_FUN_Contact_Channel
	
	CLR	A
	MOV	R0,#XDATA_TXBUF+45
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A		

	;MOV	R0,#XDATA_TXBUF+49
	INC	R0

	;~~~~~ 调用测试函数 ~~~~~
	; MOV	A,#27
	; CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	JMP	DSRC_VST_InitModeOver
DSRC_VST_InitMode02:
	CJNE	A,#2,DSRC_VST_InitModeOther
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#80H	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R0,#XDATA_TXBUF+40
	MOV	A,#1DH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;取随机数
	MOV	DPTR,#STR_DSRC_GETRND
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	SETB	BIT_GETRESULT		;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
	CLR	BIT_ESAMICC		;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
	MOV	R7,#XDATA_TXBUF	+ 41	;	R7			---	发送绶冲指针(内存)
	MOV	R5,#DATA_RXBUF		;	R5			---	接收送绶冲指针(外存)
					;	R3			---	将要发送数据的长度
					
	CALL	_FUN_Contact_Channel
	
	CLR	A
	MOV	R0,#XDATA_TXBUF+45
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0
	;MOV	R0,#XDATA_TXBUF+49
	jmp	DSRC_VST_InitModeOver
DSRC_VST_InitModeOther:
	
	MOV	r0,#xdata_txbuf+40
	
	;原来好像没有加，要验证27
DSRC_VST_InitModeOver:
	
	JMP	DSRC_VST_SEGVSTTAIL
DSRC_VST_PREAID01:
	
	;JB	BIT_INSERTCARD,DSRC_VST_PREAID01Start	;没有插卡跳过不读不读IC卡信息
	;JMP	DSRC_VST_NotUserCard
	MOV	R1,#DATA_RXBUF + 19			;
	MOV	A,@R1
	JB 	ACC.7,DSRC_VST_PREAID01Start
	;---JMP	DSRC_VST_BJ				;北京处理方式
	JMP	DSRC_VST_NotUserCard
DSRC_VST_PREAID01Start:
	
	MOV	R1,#DATA_RXBUF + 22			;系统信息文件预处理模式（长度）
	MOV	A,@R1
	
	;置位 gbICCInfo
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#26
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	JNZ	DSRC_VST_PREAID01READSYSINFO
	MOV	R0,#XDATA_TXBUF + 13
	JMP	DSRC_VST_PREREADSYSINFOOVER
	
DSRC_VST_PREAID01READSYSINFO:
	
	;从 EPPROM 中读取 XX Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,A
	PUSH	ACC
	CALL	_RDFlashXR
	POP	ACC
	
	MOV	R0,#XDATA_TXBUF + 14
	ADD	A,R0
	MOV	R0,A
DSRC_VST_PREREADSYSINFOOVER:
	
	JB	BIT_ISContact,DSRC_VST_CPUPre
	JB	BIT_PROMF,DSRC_VST_CPUPre
	JMP	DSRC_VST_MFPre
DSRC_VST_CPUPre:	;CPU卡预读
	
	MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	MOV	A,@R1

	JNZ	DSRC_VST_CPUPreStart			;当没有预读信息时，则结束
	JMP	DSRC_VST_SEGVSTTAIL
DSRC_VST_CPUPreStart:		
	JB	BIT_INSERTCARD,DSRC_VST_CPUPreHaveCard
	JMP	DSRC_VST_SEGVSTTAIL
DSRC_VST_CPUPreHaveCard:;有预读，有卡
	SETB	BIT_gbICCInfo	

	MOV	B,A
	MOV	A,#28H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,B
	
	INC	R1	;23[]
	INC	R1	;24
	
	;JNB	ACC.7,DSRC_VST_SEG0015	
	PUSH	ACC	;各预读信息存在标志
	PUSH	AR1	;预读0002偏移量
	;MOV	R1,#DATA_RXBUF+21
	;MOV	A,@R1
	;MOV	R1,#DATA_RXBUF+24

	JB	ACC.5,DSRC_VST_SEG0015Start
	JMP	DSRC_VST_SEG0012
DSRC_VST_SEG0015Start:
	JNB	ACC.7,DSRC_VST_SEG001512E
	INC	R1
	INC	R1
DSRC_VST_SEG001512E:	
	JNB	ACC.6,DSRC_VST_SEG0015		
	INC	R1
	INC	R1
	
DSRC_VST_SEG0015:
	;PUSH	AR1
	;MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	;MOV	A,@R1	
	;POP	AR1
	;JNB	ACC.5,DSRC_VST_SEG0012


	;读0015文件
	MOV	DPH,#CONST_FLASH_0015H
	MOV	A,#CONST_FLASH_0015L
	ADD	A,@R1					;0015偏移量
	MOV	DPL,A

	INC	R1	
	MOV	A,@R1	
	MOV	R3,A					;0015文件长度
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;MOV	A,R0
	;ADD	A,#39
	;MOV	R0,A
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY


	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		

	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#16
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		

	;POP	AR1	;预读0002偏移量
	;POP	ACC	;各预读信息存在标志
	;JMP	SEG_DSRC_GETSendBufLen
DSRC_VST_SEG0012:
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	POP	AR1	;预读0002偏移量
	POP	ACC	;各预读信息存在标志

	PUSH	ACC	;各预读信息存在标志
	PUSH	AR1	;预读0002偏移量

	JB	ACC.6,DSRC_VST_SEG0012Start
	JMP	DSRC_VST_SEG0019
DSRC_VST_SEG0012Start:

	JNB	ACC.7,DSRC_VST_SEG001202E
	INC	R1
	INC	R1
DSRC_VST_SEG001202E:

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#13
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	

	;读0012文件
	MOV	DPH,#CONST_FLASH_0012H
	MOV	A,#CONST_FLASH_0012L
	ADD	A,@R1					;0012偏移量
	MOV	DPL,A

	INC	R1
	MOV	A,@R1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	MOV	R3,A					;0012文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读Flash函数只操作了	R0，所以暂不PUSH R1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1

	MOV	A,R0
	ADD	A,R3
	MOV	R0,A

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#16
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;POP	AR1	;预读0002偏移量
	;POP	ACC	;各预读信息存在标志
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
DSRC_VST_SEG0019:
	
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;PUSH	AR1
	;MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	;MOV	A,@R1	
	;POP	AR1
	;JNB	ACC.4,DSRC_VST_SEG0002
	;~~~~~~~~~~~~~~~~~~~~~~~~
	POP	AR1	;预读0002偏移量
	POP	ACC	;各预读信息存在标志

	PUSH	ACC	;各预读信息存在标志
	PUSH	AR1	;预读0002偏移量

	JB	ACC.4,DSRC_VST_SEG0019Start
	JMP	DSRC_VST_SEG0002
DSRC_VST_SEG0019Start:
	
	JNB	ACC.7,DSRC_VST_SEG001902E
	INC	R1
	INC	R1
DSRC_VST_SEG001902E:
	JNB	ACC.6,DSRC_VST_SEG001912E
	INC	R1
	INC	R1
DSRC_VST_SEG001912E:
	JNB	ACC.5,DSRC_VST_SEG001915E
	INC	R1
	INC	R1
DSRC_VST_SEG001915E:
	
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#19
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	;读0019文件
	MOV	DPH,#CONST_FLASH_0019H
	MOV	A,#CONST_FLASH_0019L
	ADD	A,@R1					;0019偏移量
	MOV	DPL,A

	INC	R1	
	MOV	A,@R1	
	MOV	R3,A					;0019文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
DSRC_VST_SEG0002:

	POP	AR1	;预读0002偏移量
	POP	ACC	;各预读信息存在标志

	;PUSH	AR1
	;MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	;MOV	A,@R1	
	;POP	AR1
	;---JNB	ACC.7,DSRC_VST_SEGVSTTAIL
	JB	ACC.7,DSRC_VST_READ0002
	JMP	DSRC_VST_SEGVSTTAIL
DSRC_VST_READ0002:
	
	;MOV	R1,#DATA_RXBUF + 23			;定位r1到bst'预读0002偏移量'

	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#02
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;读0002文件
	MOV	DPH,#CONST_FLASH_0002H
	MOV	A,#CONST_FLASH_0002L
	ADD	A,@R1					;0002偏移量
	MOV	DPL,A

	INC	R1	
	MOV	A,@R1	
	MOV	R3,A					;0002文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A

	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#02
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~


	JMP	DSRC_VST_SEGVSTTAIL			;结束预读

	
	;--- MF卡预读 ---
DSRC_VST_MFPre:
	JB	BIT_INSERTCARD,DSRC_VST_MFPreHaveCard
	JMP	DSRC_VST_SEGVSTTAIL	
DSRC_VST_MFPreHaveCard:
;	SETB	BIT_privateInfo
	
;	MOV	A,#65H					;Container
;	INC	R0
	
	;--- 物理卡号 ---
;	PUSH	AR1
;	MOV	R1,#DATA_CardNO
;	MOV	A,@R1
	
;	INC	R1
;	INC	R0
;	MOV	A,@R1
	
;	INC	R1
;	INC	R0
;	MOV	A,@R1
	
;	INC	R1
;	INC	R0
;	MOV	A,@R1
	
;	INC	R0	
;	POP	AR1
	
	;--- 01H block ---
;	MOV	DPH,#CONST_FLASH_01BlockH
;	MOV	DPL,#CONST_FLASH_01BlockL
;	MOV	R3,#16
;	MOV	AR7,AR0
;	PUSH	AR0
;	PUSH	AR3
;	CALL	_RDFlashXR		
;	POP	AR3
;	POP	AR0
;	MOV	A,R0
;	ADD	A,R3
;	MOV	R0,A
	
	;--- 04H Block ---
;	MOV	DPH,#CONST_FLASH_04BlockH
;	MOV	DPL,#CONST_FLASH_04BlockL
;	MOV	R3,#16
;	MOV	AR7,AR0
;	PUSH	AR0
;	PUSH	AR3
;	CALL	_RDFlashXR		
;	POP	AR3
;	POP	AR0
;	MOV	A,R0
;	ADD	A,R3
;	MOV	R0,A	
	
	;--- 10H block ---
;	MOV	DPH,#CONST_FLASH_10BlockH
;	MOV	DPL,#CONST_FLASH_10BlockL
;	MOV	R3,#16
;	MOV	AR7,AR0
;	PUSH	AR0
;	PUSH	AR3
;	CALL	_RDFlashXR		
;	POP	AR3
;	POP	AR0
;	MOV	A,R0
;	ADD	A,R3
;	MOV	R0,A
	
	;--- R0接到发送绶冲的位置 ---
DSRC_VST_SEGVSTTAIL:
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R0
	;CLR	C
	;SUBB	A,#XDATA_TXBUF
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	PUSH	AR0
	
	MOV	R0,#XDATA_TXBUF + 12
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	MOV	C,BIT_privateInfo
	MOV	ACC.6,C
	MOV	C,BIT_gbICCInfo
	MOV	ACC.5,C
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	POP	AR0
	
	;设置MACID
	MOV	DPTR,#STR_SYS_OBUID
	MOV	AR7,AR0
	CALL	_FUN_LIB_FLASHTOXDATA

	;--- 设备类型 ---
	;dcba
	;10H0 为不支持 IC 卡接口，1 为支持 IC 卡接口
	;0 为不支持自主路径标识， 1 为支持自主路径标识
	MOV	A,#30h
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0

	;--- 设备状态 ---
	CLR	A					
	MOV	C,BIT_INSERTCARD				;=1表示当前OBU插卡;=0表示当前OBU没插卡;
	CPL	C						;与国标DSRC定义相反，所以反一下
	MOV	ACC.7,C						;iccPresent -- 存在（0），无（1）
	MOV	ACC.3,C						;iccStatus -- IC卡正常（0），出错（1）
	
	;~~~~~~~~~~ 调用测试段 ~~~~~~~~~~
;	JB	BIT_PROMF,ASDFSDAF	
;	MOV	A,#3
;	JMP	DISPLAY
;ASDFSDAF:
;	MOV	A,#4
;DISPLAY:
;	JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	 
	CLR	A	
	MOV	C,BIT_INSERTCARD
	CPL	C
	MOV	ACC.7,C
	
	JNB	BIT_INSERTCARD,DSRC_VST_CardTypeOver		;当前无卡
	JNB	BIT_ISContact,DSRC_VST_CardTypePro		;当前是非接卡
DSRC_VST_CardTypeContact:					;接触式CPU卡		0	0	0	
	JMP	DSRC_VST_CardTypeOver				;当前是接触卡
DSRC_VST_CardTypePro:						;非接触式CPU卡		0	1	0
	JNB	BIT_PROMF,DSRC_VST_CardTypeMF	
	SETB	ACC.5
	JMP	DSRC_VST_CardTypeOver
DSRC_VST_CardTypeMF:						;非接触式逻辑加密卡	0	1	1	
	SETB	ACC.5
	SETB	ACC.4
DSRC_VST_CardTypeOver:
	
	;Locked -- OBU未锁（0），被锁（1） Acc.2
	;Tampered -- OBU未被拆动（0），被拆动（1） acc.1
	;拆动的标记由，拆动次数是否为0。=0表示拆动，<> 0 表示没有拆动过。
;	MOV	R1,#XDATA_FIX
;	PUSH	ACC
;	ANL	A,#0FH
		
;	JZ	DSRC_VST_Tampered
;	CLR	C
;	JMP	DSRC_VST_TamperedOver
;DSRC_VST_Tampered:	
;	SETB	C
;	;SETB	
;DSRC_VST_TamperedOver:
;	POP	ACC
	
	MOV	C,BIT_CD
	;---CLR	C
	MOV	ACC.1,C
	
	;Battery – OBU电池正常（0），电池电量低（1）	acc.0	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	INC	R0	
	
	;ESAM第27字节"拆卸状态"
	;---MOV	A,#0FFH
	;PUSH	AR0
	;MOV	DPH,#CONST_FLASH_SYSINFOH
	;MOV	DPL,#CONST_FLASH_SYSINFOL + 26
	;MOV	AR7,#XDATA_FIX
	;MOV	R3,#1
	;CALL	_RDFlashXR	
	;POP	AR0
	
	MOV	R1,#XDATA_FIX
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	;MOV	A,#0FFH;暂加
	;CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	
	JMP	SEG_DSRC_GETSendBufLen ;VST_OVER
	
;-------------------------------------------------------------------------	
;北京BST处理
;RX[21].7 = 0
;	RX[21].0 = 0 没有预处理,只返回26个字节系统信息文件
;	RX[21].0 = 1 有预处理
;	储值卡
;		RX[21].2 = 0	返回0012
;		RX[21].2 = 1	返回0019
;	记账卡	
;		RX[21].1 = 0	返回0012
;		RX[21].1 = 1	返回0019
;返26个系统信息文件
;返0015 		33  Byte
;返0012/0019 		24  Byte
;返0002			4   Byte
;------------------------------------------------------------------------	
DSRC_VST_BJ:
	;读系统信息文件	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	MOV	a,#26;长度
	;从 EPPROM 中读取 XX Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,A
	PUSH	ACC
	CALL	_RDFlashXR
	POP	ACC
	
	MOV	R0,#XDATA_TXBUF + 14
	ADD	A,R0
	MOV	R0,A
	
;	JB	BIT_ISContact,DSRC_VST_BJCPUPre
;	JB	BIT_PROMF,DSRC_VST_BJCPUPre
;	JMP	DSRC_VST_MFPre
;DSRC_VST_BJCPUPre:	;CPU卡预读
	
;	JB	BIT_INSERTCARD,DSRC_VST_BJCPUPreHaveCard
;	JMP	DSRC_VST_SEGVSTTAIL
;DSRC_VST_BJCPUPreHaveCard:;有预读，有卡
;	SETB	BIT_gbICCInfo	
	

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	MOV	R1,#DATA_RXBUF + 19
	MOV	A,@R1
		
	JNB	ACC.0,VST_BJ_SETBJNOPRE
	JNB	BIT_INSERTCARD,VST_BJ_SETBJNOPRE;没有插卡时也不预读
;	SETB	BIT_BJPRE	
	JMP	VST_BJ_SETBJPREOVER
VST_BJ_SETBJNOPRE:
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#44
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	JMP	DSRC_VST_SEGVSTTAIL
VST_BJ_SETBJPREOVER:		
	JB	BIT_ISContact,DSRC_VST_BJCPUPre
	JB	BIT_PROMF,DSRC_VST_BJCPUPre
	JMP	DSRC_VST_MFPre
DSRC_VST_BJCPUPre:	;CPU卡预读
	SETB	BIT_gbICCInfo	


	PUSH	ACC
	MOV	A,#28H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	POP	ACC
	
	;JMP	DSRC_VST_SEGVSTTAIL

	;读0015文件中第9个字节[ 卡类型 ]
	PUSH	ACC
	PUSH	AR0
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L + 8
	MOV	R3,#1								;0015文件长度	
	MOV	R7,#XDATA_TXBUF+100
	CALL	_RDFlashXR							;读Falsh函数只操作了	r0，所以暂不push r1	
	MOV	R0,#XDATA_TXBUF+100
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	mov	R2,a
	POP	AR0
	POP	ACC
	
	CJNE	R2,#CONST_CARD_CONSUME,DSRC_VST_BJCPUPrePASS
DSRC_VST_BJCPUPreCONSUME:
	MOV	C,ACC.2		
	JMP	DSRC_VST_BJCPUPrePASSCONSUME
DSRC_VST_BJCPUPrePASS:
	MOV	C,ACC.1
DSRC_VST_BJCPUPrePASSCONSUME:	
	MOV	BIT_BJ1219,C	;读0012还是0019
			
	;容器			
;	MOV	A,#28H
;	INC	R0		;
	
	;读0015
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;JMP	DSRC_VST_SEGVSTTAIL

	;读0015文件
	;mov	a,#8;offset
	MOV	DPH,#CONST_FLASH_0015H
	MOV	A,#CONST_FLASH_0015L
	ADD	A,#8;@R1					;0015偏移量
	MOV	DPL,A

	;INC	R1	
	;MOV	A,@R1	

	mov	a,#33;0015 len	
	MOV	R3,A					;0015文件长度

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;MOV	A,R0
	;ADD	A,#39
	;MOV	R0,A
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		

	MOV	A,R0
	ADD	A,R3
	MOV	R0,A

	;JMP	DSRC_VST_SEGVSTTAIL
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	;读0012或0019
	JNB	BIT_BJ1219,VST_BJ_read0012
	JMP	VST_BJ_read0019
VST_BJ_read0012:
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	;读0012文件
	;mov	a,#0 ;offset
	MOV	DPH,#CONST_FLASH_0012H
	MOV	A,#CONST_FLASH_0012L
	;ADD	A,@R1					;0012偏移量
	MOV	DPL,A

	;INC	R1
	;MOV	A,@R1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	mov	a,#24
	MOV	R3,A					;0012文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读Flash函数只操作了	R0，所以暂不PUSH R1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A

	JMP	VST_BJ_read0002
VST_BJ_read0019:
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#19
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		

	;读0019文件
	;mov	a,#3
	MOV	DPH,#CONST_FLASH_0019H
	MOV	A,#CONST_FLASH_0019L
	ADD	A,#3;@R1					;0019偏移量
	MOV	DPL,A

	;INC	R1	
	;MOV	A,@R1	
	mov	a,#24
	MOV	R3,A					;0019文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A

VST_BJ_read0002:
	;读0002文件
	;mov	a,#0
	MOV	DPH,#CONST_FLASH_0002H
	MOV	A,#CONST_FLASH_0002L
	;ADD	A,@R1					;0002偏移量
	MOV	DPL,A

	;INC	R1	
	;MOV	A,@R1	
	mov	a,#4
	MOV	R3,A					;0002文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
	
	;读0002	
;VST_BJ_Over:
	JMP	DSRC_VST_SEGVSTTAIL;结束北京卡处理
;	JMP	SEG_DSRC_GETSendBufLen ;VST_OVER
		
;-------------------------------------------------------------------------
;描述:非广播DSRC信号处理程序入口
;外部参数
;DATA_RXBUF	---	接收到的非广播DSR绶冲
;XDATA_TXBUF	---	非广播DSR
;内部参数:
;
;返回值:
;	BIT_N				---	N位的值
;	XDATA_TXBUF			---	非广播DSRC	
;	DATA_DSRCRXLEN			---	接收长度
;	BIT_SETMMI			---	是否接收到SetMMI的标记
;--------------------------------------------------------------------------	
_FUN_DSRC_NSpecial:
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
;	mov	r1,#DATA_RXBUF + 15
;	mov	a,@r1
;	xrl	a,#54h
;	jnz	DSRC_NSpecialor
	;---CLR	PIN_RED
	;mov	a,#54
	;CALL	_FUN_TEST_DISPLAY
;DSRC_NSpecialor:
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

	;--- 设置MACID ---
	MOV	DPTR,#STR_SYS_OBUID
	MOV	R7,#XDATA_TXBUF
	CALL	_FUN_LIB_FLASHTOXDATA
	
	;--- 基本信息 ---
	MOV	A,#0E0H						;MAC控制域
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A						;MAC控制域
	
	INC	R0						;LLC控制域
	MOV	R1,#DATA_RXBUF + 5				;LLC控制域(抄)
	MOV	A,@R1
	
	MOV	C,ACC.7
	MOV	BIT_N,C
	CPL	C
	MOV	ACC.7,C
	;MOV	BIT_N,C
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0						;LLC状态域
	MOV	A,#00H						;LLC状态域
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A					
	
	INC	R0						;字段字头
	MOV	R1,#DATA_RXBUF + 6				;字段字头
	
;**********************************************************************
;描述:"DSRC_Special_ComplexSeg"  DSRC复用段
;	Getsecure & Transferchannel & SetMMI & Event 都可以调用本段
;外部参数:
;	R1	---	指向HDLC接收绶冲的'字段字头'位置
;	R0	---	指向HDLC发送绶冲的'字段字头'位置
;步骤:
;	R1[1].3 = 0，则无需响应
;规则如下：
;	R0[0]				---	抄R1[0]					---	字段头
;	R0[1] = 10H			---	r1[3] = 4
;		||
;	R0[1] = 18H			---	r1[3] <> 4

;	R0[2]				---	抄R1[2]					---	Dsrc-Did

;	R0[3](15H)			---	R1.[3] = 0 (GetSecure)			---	Channel.response
;		||
;	R0[3](19H)			---	R1.[3] = 3 (TransferChannel)
;		||
;	R0[3](1BH)			---	R1.[3] = 4 (setmmi)

;	R0[4]				--- 	抄R1.[6] 或R1.[6]+8。根据R1.[1].4决定	---	FID  (GetSecure)
;		||
;	R0[4]				---	抄R1.[5] 				---	ChannelID (TransferChannel)
;		||
;	R0[4]				---	0 (RET)(SetMMI)
;返回值：
;	BIT_KEY				---	记录非广播地址中 'fill' R1[5] 或 R1[5+8] 第7位 ‘keyedForEncrypt’的值，(表示是否存在加密索引号)
;	BIT_ACCESS			---	记录非广播地址中 'ACTION.request R1[1] '第三位 ‘accessCredentials’的值，表示是否存在'访问许可码'
;**********************************************************************		
SEG_DSRCSpecial_ComplexSeg:
	
	INC	R1				;R1[1]
	MOV	A,@R1
	;---JNB	ACC.2,DSRC_Special_Over		;Paramter=0,则无需响应
	JB	ACC.2,DSRCSpecial_ComplexSegSpecialZZ
	JMP	DSRC_Special_Over
DSRCSpecial_ComplexSegSpecialZZ:
	
	;字段头
	DEC	R1				;R1[0]
	MOV	A,@R1				
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A				;R0[0]
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	inc	r1
	inc	r1
	inc	r1
	mov	a,@r1	
;call	_fun_test_display
	xrl	a,#81
	jnz	DSRC_Special_zclc
	dec	r1	;01
	dec	r1	;05
	inc	r0
	jmp	DSRC_Special_SWGSM
DSRC_Special_zclc:
	dec	r1
	dec	r1
	dec	r1
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	;记录 AccessCredentials 
	INC	R1				;R1[1]
	MOV	A,@R1
	MOV	C,ACC.3
	MOV	BIT_ACCESS,C
	
	;取ActionType的值
	INC	R1				;R1[2]
	INC	R1				;R1[3]
	MOV	A,@R1
	MOV	R7,A
	
	;--- ACTION.REQUEST ---
	INC	R0				;R0[1]
	CJNE	R7,#4,DSRC_Special_ACTIONOther
DSRC_Special_ACTIONSetMMI:
	;--- MOV	A,#10H	
	MOV	A,#18H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JMP	DSRC_Special_ACTIONOVER
DSRC_Special_ACTIONOther:	
	MOV	A,#18H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
DSRC_Special_ACTIONOVER:

	;Dsrc-Did
	INC	R0				;R0[2]
	DEC	R1				;R1[2]
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;Channel.response
	INC	R0				;R0[3]
	CJNE	R7,#0,DSRC_Special_ChannelTransferChannel
DSRC_Special_ChannelGetSecure:
	MOV	A,#15H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JMP	DSRC_Special_ChannelOver
DSRC_Special_ChannelTransferChannel:	
	CJNE	R7,#3,DSRC_Special_ChannelSetMMI
	MOV	A,#19H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JMP	DSRC_Special_ChannelOver	
DSRC_Special_ChannelSetMMI:
	MOV	A,#1BH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
DSRC_Special_ChannelOver:

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,r7
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
	;如果是Getsecure 记录r1[5]的值，如果是TransferChannel，则将ChannelID的值给发送,如果是SetMMI则给0	
	INC	R1				;R1[3]
	INC	R1				;R1[4]
	INC	R1				;R1[5]
	INC	R0				;R0[4]
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R7
	;JMP	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~			

	CJNE	R7,#0,DSRC_Special_IDTransferChannel
DSRC_Special_IDGetSecure:	;认证指令
	;INC	R1						;R1[6]		
	;MOV	A,@R1
	
	;INC	R1						;R1[7] Offset_H & 访问许可码
	JNB	BIT_ACCESS,DSRC_Special_IDGetSecureACCES	;不存在访问许可码	
		
	;存在访问许可码
	MOV	A,R1
	ADD	A,#8
	MOV	R1,A
DSRC_Special_IDGetSecureACCES:
	MOV	ACC,@R1
	MOV	C,ACC.7
	MOV	BIT_KEY,C

	INC	R1				;R1[6] & R1[6+8]
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R1				;R1[7] & R1[6+8]   Offset_H & 访问许可码
	INC	R0				;R0[5] ESAM返回的加密数据
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,@R1
	;JMP	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;---JMP	DSRC_GetSecure_ReadVehicleInfo
	JMP	SEG_DSRC_GetSecure
;****************************************************	
	;-- 通道指令 ---
DSRC_Special_IDTransferChannel:	;通道指令
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R7
	;JMP	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	CJNE	R7,#3,DSRC_Special_IDSetMMI
	;记录ChannelID	
	MOV	A,@R1				;R1[5]


	;call	_fun_test_display
DSRC_Special_ChannelOBU:;OBU指令
	CJNE	A,#0,DSRC_Special_ChannelICC
	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0				;R0[5]	总段数
	INC	R1				;R1[6]  总段数	
	
	JMP	SEG_DSRC_TransferChannelOBU
DSRC_Special_ChannelICC:;Channelid = ICC
	CJNE	A,#1,DSRC_Special_ChannelESAM
	
	SETB	BIT_ESAMICC
	JMP	DSRC_Special_ChannelIDOver
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
DSRC_Special_ChannelESAM:	;Channelid = ICC
	CJNE	A,#2,DSRC_Special_ChannelPower;DSRC_Special_ChannelOther
	CLR	BIT_ESAMICC
	JMP	DSRC_Special_ChannelIDOver
	
	
	
DSRC_Special_ChannelPower:	;Channelid = Power
	CJNE	A,#0aah,DSRC_Special_ChannelOther
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0				;R0[5]	总段数
	INC	R1				;R1[6]  总段数
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
	JMP	SEG_DSRC_Power

DSRC_Special_ChannelOther:	;其它channelid,除ICC 和ESAM的其它Channel暂不做处理
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	JMP	DSRC_Special_Over	
DSRC_Special_ChannelIDOver:

		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0				;R0[5]	总段数
	INC	R1				;R1[6]  总段数	
	
	;~~~~~~~~~ 调用测试段 ~~~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	JMP	SEG_DSRC_TransferChannel
;****************************************************
	;--- 响铃指令 ---
DSRC_Special_IDSetMMI:				;响铃指令
	;CJNE	R7,#4,DSRC_Special_IDSetMMI
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0				;RET
	;~~~~~~~~~~~ 调用测试段 ~~~~~~~~~~~
	;MOV	A,#37
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	SETB	BIT_SETMMI			;设置接收到SetMMI的标记	
	JMP	DSRC_Special_Over		;结束
	;jmp	SEG_DSRC_GETSendBufLen
	
DSRC_Special_SWGSM:				;开关GSM指令
	;CJNE	R7,#81,DSRC_Special_OverSWGSM
	;r1	---	ACTION.request
	;r0	---	05
	
	mov	a,@r1	;05
	mov	a,#10h
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	inc	r1
	inc	r0
	
	mov	a,@r1	;01
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	inc	r1
	
;	inc	r0	
;	mov	a,@r1	;81
	
	inc	r1	;gsm 控制
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;mov	a,@r1
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	mov	a,@r1
	mov	b,a
	inc	r0	;ret
	
	clr	a
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	inc	r1
	inc	r0
	
	push	ar1
	push	ar0
	
	MOV	A,B
	XRL	A,#2
	JZ	DSRC_Special_output
	JMP	DSRC_Special_input
	
;=2 出口
;		1.清 GSM 0020
;		2.清卡片 0020
;		3.禁止 RTC，关 GSM ，关	
DSRC_Special_output:
	
	MOV	DPH,#CONST_FLASH_Sys0020H
	MOV	DPL,#CONST_FLASH_Sys0020L
	MOV	R3,#1
	CALL	_eraseflash
	
	MOV	DPH,#CONST_FLASH_Sys0020numH
	MOV	DPL,#CONST_FLASH_Sys0020numL
	MOV	R3,#1
	CALL	_eraseflash
	
	CLR	A
	MOV	R0,#XDATA_HOLD
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	DPH,#CONST_FLASH_Sys0020numH
	MOV	DPL,#CONST_FLASH_Sys0020numL
	MOV	R7,#XDATA_HOLD
	MOV	R3,#2
	CALL	_wrflashxr
	
DSRC_Special_ClearCard:
	
	;2.则清卡片 总数 0020
	;SETB	BIT_GETRESULT
	;SETB	BIT_ESAMICC
	;MOV	R7,#DATA_RXBUF+90
	;MOV	R5,#XDATA_TXBUF+90
	;MOV	R3,#10
	;MOV	R2,#01
	;CALL	_FUN_CARDAPP_SelectFile
	
	;mov	A,R7
	;CALL	_fun_test_display
	
	CLR	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF+90
	MOV	R5,#XDATA_TXBUF+50
	MOV	R3,#10H
	MOV	R2,#01H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	
;	2.则清卡片 总数 0020
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF+90
	MOV	R5,#XDATA_TXBUF+90
	MOV	R3,#const_cellfile_H
	MOV	R2,#const_cellfile_L
	CALL	_FUN_CARDAPP_SelectFile
		
	;mov	A,R7
	;CALL	_fun_test_display
		
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	MOV	R3,#12	
	MOV	R0,#DATA_RXBUF+90+5
	CLR	A
DSRC_Special_Card0020init:
	MOV	@R0,a	
	INC	R0
	DJNZ	R3,DSRC_Special_Card0020init
	
	MOV	R7,#DATA_RXBUF+90
	MOV	R5,#XDATA_TXBUF+90	
	MOV	R4,#00
	MOV	R3,#00
	MOV	R2,#12					;02H
	CALL	_FUN_CARDAPP_UpdateBinary	
	MOV	A,R7
	
	;MOV	A,R7
	;CALL	_fun_test_display
	JNZ	DSRC_Special_DisableRTC
	;3.禁止RTC，关GSM关
	CALL	_Fun_GSM_RTCDis
	
	;SETB	BIT_BUFADDR
	;MOV	R7,#XDATA_TXBUF+90
	;MOV	DPTR,#STR_GSM_CRR
	;---CALL	_Fun_GSM_Audio\
	
DSRC_Special_DisableRTC:
	
	;关 GSM 的电源(引脚待定)
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;MOV	DPH,#CONST_FLASH_Sys0020numH
	;MOV	DPL,#CONST_FLASH_Sys0020numL
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#2
	;CALL	_rdflashxr
	
	;SETB	BIT_BUFADDR
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#2
	;CALL	_FUN_TEST_UARTDISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	JMP	DSRC_Special_OverSWGSM	;结束
	
;=1 入口
DSRC_Special_input:		
	
;DSRC_Special_0019NOEaualOBU:	;0019与obu 0020不相同
	
	MOV	A,#CONST_FLASH_Sys0020H
	MOV	R3,#6
DSRC_Special_0019NOEaualOBUlooper:
	
	; 擦除 flash
	PUSH	ACC
	PUSH	AR3
	
	MOV	DPH,A
	MOV	DPL,#CONST_FLASH_Sys0020L
	MOV	R3,#1
	CALL	_eraseflash
	
	POP	AR3
	POP	ACC
	
	INC	A
	DJNZ	R3,DSRC_Special_0019NOEaualOBUlooper
	
	clr	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF+90
	MOV	R5,#XDATA_TXBUF+50
	MOV	R3,#10H
	MOV	R2,#01H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	
	;读 0019
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF+90						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF+50			
	MOV	R4,#19H							;R4		---	文件ID
	MOV	R2,#1
	MOV	R3,#CONST_Flash_0019Len					;R3		---	长度
	CALL	_FUN_CARDAPP_ReadRecord	
	
	MOV	r7,#XDATA_TXBUF+50+3
	MOV	r5,#XDATA_HOLD+1
	MOV	r3,#9
	CALL	_FUN_LIB_XDATATOXDATA
	
	;1.导入 0019 的 入口时间及入口地点到obu 0020	
	;0020
	mov	r0,#XDATA_HOLD
	mov	a,#CONST_LHX_FLAG
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	DPH,#CONST_FLASH_Sys0020H
	MOV	DPL,#CONST_FLASH_Sys0020L+3
	MOV	R7,#XDATA_HOLD
	MOV	R3,#10;9
	CALL	_wrflashxr	
	
	;2.导入 0019 的 入口时间及入口地点到card 0020
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF+90
	MOV	R5,#XDATA_TXBUF+50
	MOV	R3,#const_cellfile_H
	MOV	R2,#const_cellfile_L
	CALL	_FUN_CARDAPP_SelectFile
	
	;MOV	A,R7
	;CALL	_fun_test_display
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	CLR	A
	mov	R0,#DATA_RXBUF+90+5
	mov	@r0,a
	inc	r0
	mov	@r0,a
	inc	r0
	
	MOV	r7,#XDATA_HOLD
	MOV	r5,#DATA_RXBUF+90+5+2
	MOV	r3,#10;9
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R7,#DATA_RXBUF+90
	MOV	R5,#XDATA_TXBUF+50
	MOV	R4,#00
	;---MOV	R3,#02
	MOV	R3,#00
	;MOV	R2,#09
	MOV	R2,#12;11
	CALL	_FUN_CARDAPP_UpdateBinary
	MOV	A,R7
	
	
	;3.结束流程
;	SETB	BIT_BUFADDR
;	MOV	R7,#XDATA_TXBUF+50
;	MOV	DPTR,#STR_GSM_SRR
;	CALL	_Fun_GSM_Audio	

	;开启 GSM
	CALL	_Fun_GSM_RTCEn
	;JMP	DSRC_Special_OverSWGSM
	
DSRC_Special_OverSWGSM:
	
	pop	ar0
	pop	ar1
	
DSRC_Special_Over:
	
	JMP	SEG_DSRC_GETSendBufLen				;计算并保存HDLC发送绶冲总长度，此时R0需指向数据后一个字节	
;--------------------------------------------------------------------------
;描述:;GETSECURE配置函数
;外部参数
;	BIT_KEY		---	记录非广播地址中 'fill'第7位 ‘keyedForEncrypt’的值，(表示是否存在加密索引号)
;	BIT_ACCESS	---	记录非广播地址中 'ACTION.request'第三位 ‘accessCredentials’的值，表示是否存在'访问许可码'
;	R0		---	指向将要返回车辆信息的外存
;	R1		---	指向  Offset_H 操作数据起始位置
;返回值
;--------------------------------------------------------------------------	
SEG_DSRC_GetSecure:	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R2
	;mov	a,#13
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~
	;--- 从ESAM卡中读取车辆信息文件 ---
	;描述:读车辆信息文件(专用指令)
	;00 + B4 + Offset_H + Offset_L + Random(8 Byte) + ReadLen(XXX Byte) + KeyID(1 Byte)	
	;Offset_H + Offset_L + Len + Random + Key	
	;~~~~~~~~~~~~~~ 调用测试段 ~~~~~~~~~~~~~~
	;MOV	A,#17
	;MOV	R0,#DATA_RXBUF+15+9
	;MOV	A,@R0
	;JMP	_FUN_TEST_DISPLAY
	;00 B4 00 00 0A Random(8 Byte) Len  keyID
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	;MOV	R1,#DATA_RXBUF + 13
	;INC	R1		;Offset_H
	JNB	BIT_ESAMOK,DSRC_GetSecure_Right	
	DEC	R1		;Fill
	DEC	R1		;Contain	
	PUSH	AR1		;FILL
	;---MOV	A,@R1
	;---MOV	C,ACC.7
	;---MOV	BIT_ACCESS,C	;记录 GetSecure 指令中是否包括有 [ 加密密钥索引号（可选）]
	
	MOV	@R1,#00		;Contain
	INC	R1		;Fill
	MOV	@R1,#0B4H	;
	INC	R1		;Offset_H
	INC	R1		;Offset_L
	INC	R1		;Len
	MOV	A,@R1		;Record Length	
	MOV	@R1,#0AH	;VALUE = CMD LEN 	
	
	PUSH	ACC		;Record Length	

	MOV	A,R1		;LEN
	ADD	A,#9		;MAC KEY
	MOV	R1,A

	POP	ACC		;Length

	XCH	A,@R1		;MAC KEY VALUE
	INC	R1		;加密密钥索引号
	;XCH	@R1,A		;加密密钥索引号	或 下一段的字段头
	XCH	A,@R1
	MOV	R2,A		;保存 加密密钥索引号 或 下一段的字段头

	POP	AR1		;FILL

	CLR	BIT_ESAMICC
	SETB	BIT_GETRESULT
	MOV	AR7,AR1
	MOV	AR5,AR0
	MOV	AR3,#0FH

	PUSH	AR1
	PUSH	AR0
	PUSH	AR2	;保存 加密密钥索引号 或 下一段的字段头
	;CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R3
	
	;POP	AR2	;保存 加密密钥索引号 或 下一段的字段头
	;POP	AR0
	;POP	AR1
	
	;MOV	A,R0
	;ADD	A,R3
	;MOV	R0,A
	;DEC	R0	;去掉读车辆信息文件的IC卡返回的SW12
	;DEC	R0	
	;mov	a,r3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~	
	POP	AR2	;保存 加密密钥索引号 或 下一段的字段头
	POP	AR0
	POP	AR1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R2
	;SETB	BIT_BUFADDR;
	;MOV	AR7,AR0
	;MOV	R3,#15
	;MOV	A,#1
	;CALL	_FUN_TEST_UARTDISPLAY
	;MOV	a,#23
	;mov	
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~				
					
	;偏移 R0到xdata_txbuf已有数据的后一个字节
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
	DEC	R0	;去掉读车辆信息文件的IC卡返回的SW12
	DEC	R0
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;~~~~~ 调用测试段 ~~~~~
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~		
	XRL	A,#90H
	JZ	DSRC_GetSecure_Right
	JNB	BIT_ESAMErr,DSRC_GetSecure_Right
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R2
	;SETB	BIT_BUFADDR;
	;MOV	AR7,AR1
	;MOV	R3,#15
	;MOV	A,#1
	;CALL	_FUN_TEST_UARTDISPLAY
	;MOV	a,#23
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~		

	CALL	_FUN_LIB_ESAMErr	
DSRC_GetSecure_Right:
	
	;鉴别码（8个字节），暂时全为0 + RET[0]
	MOV	R3,#9
DSRC_GetSecure_JBM:
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	DJNZ	R3,DSRC_GetSecure_JBM	
		
	;偏移R1
	MOV	A,R1
	JB	BIT_KEY,DSRC_GetSecure_ENKey	
DSRC_GetSecure_NotENKey:;GetSecure 指令中没有 '加密密钥索引号'
	ADD	A,#14;15
	MOV	R1,A
	MOV	A,R2
	;INC	R1
	MOV	@R1,A
	MOV	A,R1
	;INC	A	
	JMP	DSRC_GetSecure_ENKeyOver
DSRC_GetSecure_ENKey:;GetSecure 指令中有 '加密密钥索引号'
	ADD	A,#15
	;~~~~~ 调用测试段 ~~~~~	
	;MOV	A,@R1
	;MOV	A,#15
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~	
DSRC_GetSecure_ENKeyOver:
	MOV	R1,A
	
DSRC_GetSecure_Over:
	
	;判断是否还有后继段 (HDLC接收总长-当前长度-4) >0则表示还有后继段
	PUSH	AR0
	MOV	R0,#DATA_DSRCRXLEN		;HDLC接收到的数据总长
	MOV	A,@R0
	POP	AR0	
	MOV	R3,#DATA_RXBUF
	ADD	A,R3
	
	CLR	C
	SUBB	A,#4
	
	CLR	C
	SUBB	A,R1
	
	JC	DSRC_GetSecure_NOTNextSeg
	
	JMP	SEG_DSRCSpecial_ComplexSeg	;DSRC复用段
DSRC_GetSecure_NOTNextSeg:	;没有后继段

	JMP	SEG_DSRC_GETSendBufLen ;Getseucre Segment Over

;--------------------------------------------------------------------------
;描述:;SEG_DSRC_Power配置函数[只组装数据，不发送数据]
;外部参数
;R1	---	接收到的TransferChannel绶冲,指向总段数的位置
;R0	---	将要发送TransferChannel响应
;内部参数:
;返回值
;--------------------------------------------------------------------------	
SEG_DSRC_Power:
	
	INC	R1	;APDU指令的长度
	INC	R1	;APDU指令
	INC	R1	;下一条APDU指令的长度
	
	MOV	A,#1	;总段数
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0	;APDU指令的长度
	MOV	A,#2
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;INC	R0	;APDU指令01
	;CLR	A
	
	INC	R0	;APDU指令02
	PUSH	AR0
	MOV	R0,#XDATA_Power	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	;MOV	A,#99

	MOV	B,#100
	XCH	A,B
	CLR	C
	SUBB	A,B	
	POP	AR0

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	;MOV	A,#99
	MOV	B,#10
	DIV	AB
	CJNE	A,#10,$+3
	JC	DSRC_Power_1Byte
	;100
	MOV	A,#1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JMP	DSRC_Power_Over
DSRC_Power_1Byte:	
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	INC	R0
	CLR	C	
	RLC	A
	RLC	A
	RLC	A
	RLC	A	
	ORL	A,B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
DSRC_Power_Over:
	
	;JNC	DSRC_Power_Per
	;CLR	A
;DSRC_Power_Per:		
		
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	INC	R0	;下一条APDU指令的长度
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	
	;PUSH	AR1
	;MOV	R1,#XDATA_Power
	
	;INC	R1
	;INC	R0
	
	;INC	R1
	;INC	R0
		
	;INC	R1
	;INC	R0
	
	;POP	AR1
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~		

	;JMP	DSRC_TransferChannel_Over
	JMP	DSRC_TransferChannel_LoopEnd


;--------------------------------------------------------------------------
;描述:;TransferChannel配置函数[只组装数据，不发送数据]
;外部参数
;R1	---	接收到的TransferChannel绶冲,指向总段数的位置
;R0	---	将要发送TransferChannel响应
;内部参数:
;返回值
;--------------------------------------------------------------------------
SEG_DSRC_TransferChannel:
	
	;总段数
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	R4,A
	
	;~~~~~ 调用测试段 ~~~~~	
;	PUSH	ar0
;	MOV	R0,#DATA_DSRCRXLEN
;	MOV	A,@R0
;	XRL	A,#27

;	JZ	DSRC_TransferChannel_t001
;	MOV	A,@R0
;	POP	ar0	
;	MOV	R0,#DATA_RXBUF+15
;	MOV	A,@R0
;	MOV	a,#13
;	CALL	_FUN_TEST_DISPLAY
;DSRC_TransferChannel_t001:
;	pop	ar0

	;MOV	A,R3
	;MOV	A,#31
	;JMP	_FUN_TEST_DISPLAY
	;INC	R0
	;JMP	SEG_DSRC_GETSendBufLen	


;	JNB	BIT_ESAMICC,DSRC_TransferChannel_ESAMCard
;DSRC_TransferChannel_UserCard:	;用户卡
;	JNB	BIT_INSERTCARD,DSRC_TransferChannel_NOCARD	;	
;	JMP	DSRC_TransferChannel_Card
;DSRC_TransferChannel_ESAMCard:	;ESAM卡
;	JNB	BIT_ESAM,DSRC_TransferChannel_NOCARD	;	
	;JMP	DSRC_TransferChannel_Card	
;DSRC_TransferChannel_CardOver:
	;BIT_ESAM	
	
;	jb	BIT_ESAMICC,DSRC_TransferChannel_esamor
;DSRC_TransferChannel_esam:
;	MOV	A,#41
;	JMP	_FUN_TEST_DISPLAY
;DSRC_TransferChannel_esamor:	
;	jnb	BIT_INSERTCARD,DSRC_TransferChannel_haveCARDor
;DSRC_TransferChannel_haveCARD:
;	MOV	A,#42
;	JMP	_FUN_TEST_DISPLAY
;DSRC_TransferChannel_haveCARDor:
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;没有插卡 不做 IC 卡处理
	JNB	BIT_ESAMICC,DSRC_TransferChannel_Card 	;当前Channel如果是ESAM卡，则没有插卡问题
	JB	BIT_INSERTCARD,DSRC_TransferChannel_Card	;
;***************************************************************	
	;--- 无卡处理 ---	
DSRC_TransferChannel_NOCARD:
	;~~~~~ 调用测试段 ~~~~~	
	;MOV	A,R3
	;MOV	A,@R1
	;MOV	A,#32
	;JMP	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;CALL	_FUN_TEST_BEEP
	;~~~~~~~~~~~~~~~~~~~~~~
	INC	R0				;长度	
	INC	R1				;长度	
DSRC_TransferChannel_NOCardLOOP:		;无卡，但RSU又要求返回IC卡信息时，返回 总段数 + 段长1+ 状态码1(FFFF)+ 段长2+ 状态码2(FFFF)+...
	;~~~~~ 调用测试段 ~~~~~	
	;MOV	A,R3
	;MOV	A,@R1
	;MOV	A,#32
	;JMP	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~
		
	MOV	A,#2
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#0FFH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	
	MOV	A,@R1
	ADD	A,R1
	INC	A
	MOV	R1,A
	DJNZ	R4,DSRC_TransferChannel_NOCardLOOP
	JMP	DSRC_TransferChannel_Over
	
;****************************************************************	
	
	;--- 有卡处理 ---	
DSRC_TransferChannel_Card:
	;~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~~~~~~~
	
	;2、验证每一次r1的位置是否正确
	;3、验证每次下发给卡片函数的指令是否正确
	;MOV	A,R1
	;XRL	A,#47
	;JZ	TransferChannel_Card_CON
	;CALL	_FUN_TEST_BEEP
	;mov	a,r1
	;JMP	_FUN_TEST_DISPLAY
;TransferChannel_Card_CON:
	;1、将 transferchannel 指令写死，以做检查
	;05 00 84 00 00 08 
	;push	ar1
	;inc	r1
	;mov	@r1,#05
	;inc	r1
	;mov	@r1,#00
	;inc	r1
	;mov	@r1,#84h
	;inc	r1
	;mov	@r1,#00
	;inc	r1
	;mov	@r1,#00
	;inc	r1
	;mov	@r1,#08	
	;pop	ar1
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	INC	R0				;长度	
	INC	R1				;长度	
DSRC_TransferChannel_CardLOOP:
	MOV	A,@R1
	MOV	R3,A
	
	INC	R1				;指令头
	INC	R0				;指令头
	
	MOV	AR7,AR1
	MOV	AR5,AR0
	
	PUSH	AR4
	PUSH	AR1
	PUSH	AR0
	
	;当是选目录指令时，置位BIT_GETRESULT，表只返回61长度
	INC	R1
	MOV	A,@R1
	
	;~~~~~  调用测试段  ~~~~~
	;MOV	A,@R1
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~
	JNB	BIT_ESAMICC,DSRC_TransferChannel_ESAMSpe
DSRC_TransferChannel_UserSpe:;用户卡特殊处理
	;当前指令，如果是选目录指令，则不做操作。
	
	XRL	A,#0A4H
	SETB	BIT_GETRESULT
	;-JNZ	DSRC_TransferChannel_SpeOver
	;---CLR	BIT_GETRESULT
	
	MOV	A,@R1
	XRL	A,#054H
	
	JNZ	DSRC_TransferChannel_SpeOver
	;---CLR	BIT_GETRESULT
	;---SETB	BIT_8054_flag	
	push	ar0
	mov	r0,#XDATA_54
	mov	a,#CONST_SYS_55
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	pop	ar0
	
	JMP	DSRC_TransferChannel_SpeOver
DSRC_TransferChannel_ESAMSpe:;ESAM卡特殊处理
	;~~~~~  调用测试段  ~~~~~	
	;MOV	A,@R1
	;mov	A,#34
	;JMP	_FUN_TEST_DISPLAY	
	;~~~~~~~~~~~~~~~~~~~~~~~~~	
	SETB	BIT_GETRESULT
	XRL	A,#0E4H
	JNZ	DSRC_TransferChannel_ESAMSpeNOADDTIME
DSRC_TransferChannel_ESAMSpeADDTIME:
	;加大搜索时间限制
	PUSH	AR0
 	MOV	R0,#XDATA_SOFTFIRSTSCANTIME		
	MOV	A,#CONST_SOFTFIRSTSCANTIMEXX		
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A						;串口第一个字节最大搜索时间		
	POP	AR0	
	JMP	DSRC_TransferChannel_SpeOver
DSRC_TransferChannel_ESAMSpeNOADDTIME:
	;正常时间限制
	PUSH	AR0					
 	MOV	R0,#XDATA_SOFTFIRSTSCANTIME		
	MOV	A,#CONST_SOFTFIRSTSCANTIME		
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A						;串口第一个字节最大搜索时间		
	POP	AR0					
DSRC_TransferChannel_SpeOver:
	;JNB	BIT_ESAMICC,DSRC_TransferChannel_Result	;如果当前是ESAM卡，则要取返回值
	
	;~~~~~  调用测试段  ~~~~~
	;CALL	_FUN_TESTContact_OPRET0
	;MOV	A,r3
	;JMP	_FUN_TEST_DISPLAY	
	;JMP	DSRC_TransferChannel_DEALOVER	
	;~~~~~~~~~~~~~~~~~~~~~~~~~
	
DSRC_TransferChannel_Result:
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	
	;mov	a,#35
	;call	_fun_test_display	
	;---CALL	_FUN_TESTContact_OPRET0
DSRC_TransferChannel_DEALOVER:	
	POP	AR0
	POP	AR1
	POP	AR4
	
	MOV	A,R3
	
	;~~~~~  调用测试段  ~~~~~	
	;INC	R1
	;MOV	A,@R1
	;XRL	A,#0DCH
	;XRL	A,#0A4H
	;JNZ	DSRC_TransferChannelTEST
	;MOV	A,#121
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
;DSRC_TransferChannelTEST:
;	DEC	R1
	;INC	R0
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~		
	
	JNZ	DSRC_TransferChannel_CardRight
;****************************************************************
DSRC_TransferChannel_CardErr:			;通道指令执行失败
	;~~~~~ 调用测试段 ~~~~~	
	;将接收数据全copy到发送区
;	mov	a,#01
;	inc	a
;	inc	r0
;	inc	a
;	inc	r0
;	mov	a,#0ffh
;	inc	r0
;	inc	r0

;	push	ar0
;	MOV	R0,#DATA_DSRCRXLEN
;	MOV	A,@R0
;	pop	ar0
;	inc	r0
;	mov	r3,a
;	mov	r1,#data_rxbuf	
;TransferChannel_CardErr_lp:
;	mov	a,@r1
;	inc	r1
;	inc	r0
;	djnz	r3,TransferChannel_CardErr_lp
;	JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~

	DEC	R0				;将R0退到长度值
	MOV	A,#2
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#0FFH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		
	DEC	R1				;长度
	MOV	A,@R1
	INC	R1				;指令头
	ADD	A,R1				;下一段指令的长度
	MOV	R1,A
	DJNZ	R4,DSRC_TransferChannel_CardLOOP
	JMP	DSRC_TransferChannel_LoopEnd
	
DSRC_TransferChannel_CardRight:			;通道指令执行成功
	MOV	A,R3
	
	DEC	R0				;长度
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,R0		
	ADD	A,R3				
	MOV	R0,A				;下一段指令的长度
	
	DEC	R1				;长度
	MOV	A,@R1
	INC	R1				;指令头
	ADD	A,R1				;下一段指令的长度
	MOV	R1,A
	;---DJNZ	R4,DSRC_TransferChannel_CardLOOP
	DEC	R4
	;CJNE	R4,#0,DSRC_TransferChannel_CardLOOP
	CJNE	R4,#0,DSRC_TransferChannel_CardRightZZ
	JMP	DSRC_TransferChannel_LoopEnd
DSRC_TransferChannel_CardRightZZ:;太长了，需要中转一下	
	JMP	DSRC_TransferChannel_CardLOOP
DSRC_TransferChannel_LoopEnd:
	CLR	A				;Ret
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0				;下一段指令的字段头(如果有后继段的话)
	
	;~~~~~ 调用测试段 ~~~~~	
	;MOV	A,R3
	;MOV	A,@R1
	;MOV	A,#33
	;JMP	_FUN_TEST_DISPLAY
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~
	
DSRC_TransferChannel_Over:
	;判断是否还有后继段 (HDLC接收总长-当前长度-4) >0则表示还有后继段
	PUSH	AR0
	MOV	R0,#DATA_DSRCRXLEN		;HDLC接收到的数据总长
	MOV	A,@R0
	POP	AR0
	MOV	R3,#DATA_RXBUF
	ADD	A,R3
	
	CLR	C
	SUBB	A,#4
	
	CLR	C
	SUBB	A,R1
	
	JC	DSRC_TransferChannel_NOTNextSeg	
	
	;~~~~~ 调用测试段 ~~~~~	
	;MOV	A,R3
	;DEC	R1
	;DEC	R1
	;MOV	A,@R1
	;MOV	A,#40
	;MOV	A,R1
	;JMP	_FUN_TEST_DISPLAY	
	;~~~~~~~~~~~~~~~~~~~~~~	
	JMP	SEG_DSRCSpecial_ComplexSeg	;DSRC复用段
DSRC_TransferChannel_NOTNextSeg:;没有后继段
	JMP	SEG_DSRC_GETSendBufLen				;计算并保存HDLC发送绶冲总长度，此时R0需指向数据后一个字节
		
;--------------------------------------------------------------------------
;描述:;TransferChannelOBU OBU通道指令[只组装数据，不发送数据]
;外部参数
;R1	---	接收到的TransferChannel绶冲,指向总段数的位置
;R0	---	将要发送TransferChannel响应
;内部参数:
;返回值		[OBU默认已选择了OBU中的1001下的0020文件。指令参考 00 B0 Offset.01 Offset.00 Len]
;--------------------------------------------------------------------------
SEG_DSRC_TransferChannelOBU:	
	
	; 总段数 
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	R4,A
	
	INC	R0				;长度	
	INC	R1				;长度	
DSRC_TransferChannelOBU_CardLOOP:
	MOV	A,@R1
	MOV	R3,A				;Len
	
	INC	R1				;指令头
	INC	R0				;指令头
	
	MOV	AR7,AR1
	MOV	AR5,AR0	
	PUSH	AR4
	PUSH	AR1
	PUSH	AR0
	
	;当是选目录指令时，置位 BIT_GETRESULT，表只返回61长度
	;INC	R1
	;MOV	A,@R1	
	;处理函数
	
	CALL	_FUN_DSRC_OBUChannel
	
	POP	AR0
	POP	AR1
	POP	AR4
	
	MOV	A,R3
	JNZ	DSRC_TransferChannelOBU_CardRight
	
DSRC_TransferChannelOBU_CardErr:			;通道指令执行失败

	DEC	R0					;将R0退到长度值
	MOV	A,#2
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#0FFH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		
	DEC	R1					;长度
	MOV	A,@R1
	INC	R1					;指令头
	ADD	A,R1					;下一段指令的长度
	MOV	R1,A
	DJNZ	R4,DSRC_TransferChannelOBU_CardLOOP	
	JMP	DSRC_TransferChannelOBU_LoopEnd
DSRC_TransferChannelOBU_CardRight:		;通道指令执行成功
	MOV	A,R3	
	
	DEC	R0				;长度
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,R0		
	ADD	A,R3				
	MOV	R0,A				;下一段指令的长度
	
	DEC	R1				;长度
	MOV	A,@R1
	INC	R1				;指令头
	ADD	A,R1				;下一段指令的长度
	MOV	R1,A
	;---DJNZ	R4,DSRC_TransferChannel_CardLOOP
	DEC	R4
	CJNE	R4,#0,DSRC_TransferChannelOBU_CardLOOP
;	JMP	DSRC_TransferChannel_LoopEnd
;DSRC_TransferChannelOBU_CardRightZZ:;太长了，需要中转一下	
;	JMP	DSRC_TransferChannelOBU_CardLOOP
DSRC_TransferChannelOBU_LoopEnd:
	CLR	A				;Ret
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0				;下一段指令的字段头(如果有后继段的话)
		
	;判断是否还有后继段 (HDLC接收总长-当前长度-4) >0则表示还有后继段，没有就结束
	JMP	DSRC_TransferChannel_Over	
;**********************************************************************
;SEG_DSRC_GETSendBufLen(附属序段)
;附属于:_FUN_DSRC_VST & SEG_DSRC_GetSecure & SEG_DSRC_SetSecure & SEG_DSRC_GetRand & SEG_DSRC_TransferChannel & SEG_DSRC_SetMMI & SEG_DSRC_GETSendBufLen
;描述:DSRC cpu卡指令处理函数
;	R0		---	指向发送绶冲最后一个字节的后一个字节
;	DATA_DSRCLEN	---	1 BYTE 用于记录DSRC发送长度，以便在重发时使用
;返回值:
;	R3		---	发送绶冲的长度，以便在重发DSRC帧时使用
;**********************************************************************	
SEG_DSRC_GETSendBufLen:

	;计算DSRC帧数据长度
	MOV	A,R0
	CLR	C
	SUBB	A,#XDATA_TXBUF
	MOV	R3,A
	
	;记录发送长度以便在重发时使用
	MOV	DATA_DSRCTXLEN,A
	MOV	R7,#XDATA_TXBUF	

	mov 	r5,a
	call 	_getnewcrc_xr
	mov 	a,DATA_DSRCTXLEN
	inc 	a
	inc 	a
	mov 	DATA_DSRCTXLEN,a
	
	RET
;--------------------------------------------------------------------------
;描述:;SetMMI 配置函数[只组装数据，不发送数据]
;外部参数	
;DATA_RXBUF	---	接收到的SetMMI绶冲
;XDATA_TXBUF	---	将要发送SetMMI响应
;内部参数:	
;R0		
;返回值		
;--------------------------------------------------------------------------	
SEG_DSRC_SetMMI:
	
	RET
;--------------------------------------------------------------------------
;描述:;SETSECURE配置函数[只组装数据，不发送数据]
;外部参数
;DATA_RXBUF	---	接收到的SETSECURE绶冲
;XDATA_TXBUF	---	将要发送SETSECURE响应
;内部参数:
;R0
;返回值
;--------------------------------------------------------------------------	
SEG_DSRC_SetSecure:
	
	RET
;--------------------------------------------------------------------------
;描述:;GetRand配置函数[只组装数据，不发送数据]
;外部参数
;DATA_RXBUF	---	接收到的GetRand绶冲
;XDATA_TXBUF	---	将要发送GetRand响应
;内部参数:
;R0
;返回值
;--------------------------------------------------------------------------	
SEG_DSRC_GetRand:
	
	RET
;--------------------------------------------------------------------------
;描述:;GetRand配置函数[只组装数据，不发送数据]
;外部参数
;AR7	---	指令(内存)
;AR5	---	返回(外存)
;内部参数:
;R3	---	返回长度
;返回值
;	[ OBU默认已选择了OBU中的1001下的0020文件。指令参考 00 B0 Offset.01 Offset.00 Len ]
;--------------------------------------------------------------------------
_FUN_DSRC_OBUChannel:
	
	;PUSH	AR3
	MOV	AR1,AR7				;head
	INC	R1				;cmd
	
	MOV	A,@R1
	XRL	A,#0B0H
	;JNZ	DSRC_OBUChannel_NOCMD
	JZ	DSRC_OBUChannel_ZZ01
	JMP	DSRC_OBUChannel_NOCMD
DSRC_OBUChannel_ZZ01:
	
	;---读取预处理标记 ---	
	INC	R1				;OFFSET 01
	INC	R1				;OFFSET 02
	
	;------------------------------------------------------------------------
	;如果offset=00 00 ，则需要从CONST_FLASH_Sys0020numH/l读入相应的cellid个数
	PUSH	AR1				;OFFSET 02
	PUSH	AR2
	PUSH	AR3
	PUSH	AR4
	PUSH	AR5
	PUSH	AR6
	PUSH	AR7
	
	CLR	C
	MOV	A,@R1				;OFFSET 02
	MOV	B,A
	DEC	R1				;OFFSET 01
	MOV	A,@R1
	ORL	A,B
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
DSRC_OBUChannel_B01:				;补一个字节
	
	CJNE	A,#1,DSRC_OBUChannel_B02
	;INC	R1				;OFFSET 01
	MOV	A,@R1
	JNZ	DSRC_OBUChannel_BBB
	
	PUSH	AR0
	MOV	DPH,#CONST_FLASH_Sys0020numH
	MOV	DPL,#CONST_FLASH_Sys0020numL+1
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#1
	CALL	_RDFlashXR
	POP	AR0
	
	;POP	AR0
	MOV	R1,#XDATA_HOLD
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	
	;MOV	B,#1
	JMP	DSRC_OBUChannel_Bover
	
DSRC_OBUChannel_B02:				;补两个字节
	JNZ	DSRC_OBUChannel_BBB
	;CJNE	A,#2,DSRC_OBUChannel_BBB
	;INC	R1				;OFFSET 01
	;MOV	A,@R1
	;JNZ	DSRC_OBUChannel_BBB	
	
	PUSH	AR0
	MOV	DPH,#CONST_FLASH_Sys0020numH
	MOV	DPL,#CONST_FLASH_Sys0020numL
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#2
	CALL	_RDFlashXR
	POP	AR0
	
	MOV	R1,#XDATA_HOLD
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	r0
	INC	r1
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	r0
	
	MOV	B,#2
	JMP	DSRC_OBUChannel_Bover
DSRC_OBUChannel_BBB:;不补
	mov	B,#0
DSRC_OBUChannel_Bover:
	;POP	AR0
	POP	AR7
	POP	AR6
	POP	AR5
	POP	AR4
	POP	AR3
	POP	AR2			
	POP	AR1	;OFFSET 02
	
	;------------------------------------------------------------------------
	MOV	A,@R1				;offset 02
	CLR	C
	ADDC	A,#CONST_FLASH_Sys0020L
	MOV	DPL,A
	DEC	R1				;offset 01
	MOV	A,@R1
	ADDC	A,#CONST_FLASH_Sys0020H
	MOV	DPH,A
	
	CLR	C
	MOV	A,DPL
	addc	A,B
	MOV	DPL,A
	MOV	A,DPH
	addc	A,#0
	MOV	DPH,A
	
;	MOV	DPH,A						;#CONST_FALSH_PREFlagH	
;	INC	R1
;	MOV	A,@R1
;	MOV	DPL,A						;#CONST_FALSH_PREFlagL
	
	INC	R1	;offset 02	
	INC	R1	;len
	MOV	A,@R1	

	clr	c
	subb	a,b
	MOV	R3,A
	
	
	;DEC	R3
	;DEC	R3
	
	MOV	A,B
	PUSH	ACC	
	PUSH	AR3
	PUSH	AR5
	MOV	AR7,AR0
	
	;MOV	A,DPL
	;CALL	_FUN_TEST_DISPLAY
	
	;MOV	AR7,#XDATA_TXBUF
	CALL	_RDFlashXR
	POP	AR5
	POP	AR3
	POP	ACC
	
	CLR	C
	ADDC	A,R3
	MOV	R3,A
	;MOV	A,R3
	
	MOV	A,R5
	ADD	A,R3
	MOV	R0,A
	MOV	A,#90H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R3
	INC	R3
	
	JMP	DSRC_OBUChannel_Over
	
DSRC_OBUChannel_NOCMD:
	
	;POP	AR3
	CLR	A
	MOV	R3,A
DSRC_OBUChannel_Over:
	
	RET
;--------------------------------------------------------------------------	
;--------------------------------------------------------------------------	
_FUN_DSRC_VSTCell:
	

	
CLR	BIT_privateInfo
CLR	BIT_gbICCInfo
	;设置MAC ID
	MOV	DPTR,#STR_SYS_OBUID
	MOV	R7,#XDATA_TXBUF
	CALL	_FUN_LIB_FLASHTOXDATA
	
	;MOV	R3,#CONST_SYS_OBUIDLEN
	;CALL	_FUN_LIB_FLASHTODATAEX
	
	;记录天线ID & 记录Unix时间 [ 因为 XDATA_BeaconID 和 XDATA_UnixTime 空间定成连体,所以一齐Copy]
	;XDATA_BeaconID
	;可能到时还要将两个值放入到flash中
	MOV	R1,#DATA_RXBUF + 8
	MOV	R0,#XDATA_BeaconID
	MOV	R2,#CONST_Flash_BeaconIDUnixTimeLen
DSRC_VSTCell_BeanconLoop:
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R1
	INC	R0
	DJNZ	R2,DSRC_VSTCell_BeanconLoop
	
	;~~~~~~~~ 调用测试段 ~~~~~
	;MOV	R0,#XDATA_UnixTime
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	;设置VST基本信息
	MOV	DPTR,#STR_DSRC_VST02
	MOV	R7,#XDATA_TXBUF + 4
	CALL	_FUN_LIB_FLASHTOXDATA
	
	;记录信道号
	MOV	R1,#DATA_RXBUF + 16
	MOV	A,@R1
	MOV	C,ACC.0
	MOV	BIT_CHANNELFLAG,C 
	
	JNB	BIT_CHANNELFLAG,DSRC_VSTCell_BeanconLoop1
	PUSH	AR1
	PUSH	AR0
	
	;~~~~~~~~ 调用测试段 ~~~~~
	;MOV	A,#1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~	
	CALL	_FUN_HDLC_CHANGECHANNEL			;设置通讯信道
	POP	AR0
	POP	AR1
	;400us
	
DSRC_VSTCell_BeanconLoop1:
	
	;设置返回信道号
	MOV	R0,#XDATA_TXBUF + 8
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	C,BIT_CHANNELFLAG
	MOV	ACC.0,C
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;设置 ApplicationList
	INC	R1
	INC	R0
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;设置Parameter & 无扩展, AID = 1 (ETC)
	INC	R1
	INC	R0
	MOV	A,@R1
	SETB	ACC.7
	SETB	ACC.6	;Paramter
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	;Bit5――gbICCInfo存在标志
	;BIT_ISContact	
	MOV	R0,#XDATA_TXBUF + 12
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
;	JNB	BIT_INSERTCARD,DSRC_VSTCell_infoo
;	SETB	C
;	JNB	BIT_ISContact,DSRC_VSTCell_privateInfo
;DSRC_VSTCell_DgbICCInfo:
;	MOV	ACC.5,C
;	JMP	DSRC_VSTCell_infoo
;DSRC_VSTCell_privateInfo:
;	MOV	ACC.6,C
;DSRC_VSTCell_infoo:
;	;MOV	C,BIT_INSERTCARD
;	;MOV	ACC.5,C


	MOV	R0,#XDATA_TXBUF + 14
	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
		
	;--- 从EPPROM中读取IC卡信息 ---
	;JNB	BIT_INSERTCARD,DSRC_VSTCell_NotUserCard	;没有插卡跳过不读不读IC卡信息
	
	MOV	R1,#DATA_RXBUF + 18			;Parameter
	MOV	A,@R1
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;MOV	R1,#DATA_RXBUF + 19			;Parameter
	;MOV	A,@R1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	JNB	ACC.6,DSRC_VSTCell_NotUserCard		;没有扩展应用时跳过不读不读IC卡信息
	
	MOV	R1,#DATA_RXBUF + 19
	MOV	A,@R1
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#22
	;MOV	R1,#DATA_RXBUF + 19			;Parameter
	;MOV	A,@R1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	JNB	ACC.7,DSRC_VSTCell_NotUserCard		;没有扩展应用时跳过不读不读IC卡信息		
		
	MOV	R1,#DATA_RXBUF + 18			;Parameter
	MOV	A,@R1		
	JMP	DSRC_VSTCell_PRE				;BST带预处理流程
	
	;没有用户卡或没有扩展应用时
DSRC_VSTCell_NotUserCard:	

	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#23
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	;从 EPPROM 中读取 26 Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,#26
	CALL	_RDFlashXR
	
	MOV	R0,#XDATA_TXBUF + 40
	JMP	DSRC_VSTCell_SEGVSTTAIL
	
DSRC_VSTCell_PRE: 	;BST 带预处理流程
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#23
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;---JNB	ACC.0,DSRC_VSTCell_PREAID00
	JMP	DSRC_VSTCell_PREAID01
	;ACC.0=0/=1
DSRC_VSTCell_PREAID00:	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#24
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	;---从 EPPROM 中读取 26 Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,#26
	CALL	_RDFlashXR
		
	;1 设置第13个字节		
	;2 获取随机数及ESAM卡复位信息
	MOV	R0,#XDATA_TXBUF+12	
	MOV	R1,#DATA_RXBUF+19	;Init Mode
	MOV	A,@R1

	CJNE	A,#0,DSRC_VSTCell_InitMode01
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#25
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#90H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R0,#XDATA_TXBUF+40
	MOV	A,#1DH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R0,#XDATA_TXBUF+49
	MOV	A,#50H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;复位卡片
	;CLR	PIN_ESAM_RST
	;MOV	R7,#20H
	;SETB	PIN_ESAM_RST
	
	CLR	BIT_ESAMICC	
	setb	BIT_BUFADDR			;BIT_BUFADDR		---	=0，接收数据到内存；=1，接收数据到外存
	SETB	BIT_SERIALOVERTIMERX		;BIT_SERIALOVERTIMERX	---	串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;BIT_VERIFY		---	串口收发是否要加验位,=0不要，=1要
	MOV	R7,#XDATA_TXBUF+50		;R7			---	将要接收字符串buf的指针
	MOV	R3,#000			;	
	CALL	_FUN_SERIAL_RXSOFT		;
	MOV	A,R3				;
	
	;选DF01
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF + 72
	MOV	R3,#0dFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
	;取随机数	
	MOV	DPTR,#STR_DSRC_GETRND
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	SETB	BIT_GETRESULT		;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
	CLR	BIT_ESAMICC		;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
	MOV	R7,#XDATA_TXBUF	+ 41	;	R7			---	发送绶冲指针(内存)
	MOV	R5,#DATA_RXBUF		;	R5			---	接收送绶冲指针(外存)
					;	R3			---	将要发送数据的长度
	
	CALL	_FUN_Contact_Channel
	
	CLR	A
	MOV	R0,#XDATA_TXBUF+45
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	R0,#XDATA_TXBUF + 65
	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#26
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	JMP	DSRC_VSTCell_InitModeOver
DSRC_VSTCell_InitMode01:
	CJNE	A,#1,DSRC_VSTCell_InitMode02
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#80H	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R0,#XDATA_TXBUF+40
	MOV	A,#1DH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;取随机数
	MOV	DPTR,#STR_DSRC_GETRND
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	
	SETB	BIT_GETRESULT		;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
	CLR	BIT_ESAMICC		;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
	MOV	R7,#XDATA_TXBUF	+ 41	;	R7			---	发送绶冲指针(内存)
	MOV	R5,#DATA_RXBUF		;	R5			---	接收送绶冲指针(外存)
					;	R3			---	将要发送数据的长度	
	CALL	_FUN_Contact_Channel
	
	CLR	A
	MOV	R0,#XDATA_TXBUF+45
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A		

	;MOV	R0,#XDATA_TXBUF+49
	INC	R0

	;~~~~~ 调用测试函数 ~~~~~
	; MOV	A,#27
	; CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~

	JMP	DSRC_VSTCell_InitModeOver
DSRC_VSTCell_InitMode02:
	CJNE	A,#2,DSRC_VSTCell_InitModeOther
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ORL	A,#80H	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R0,#XDATA_TXBUF+40
	MOV	A,#1DH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;取随机数
	MOV	DPTR,#STR_DSRC_GETRND
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
		
	SETB	BIT_GETRESULT		;	BIT_GETRESULT		=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)
	CLR	BIT_ESAMICC		;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
	MOV	R7,#XDATA_TXBUF	+ 41	;	R7			---	发送绶冲指针(内存)
	MOV	R5,#DATA_RXBUF		;	R5			---	接收送绶冲指针(外存)
					;	R3			---	将要发送数据的长度	
	CALL	_FUN_Contact_Channel
	
	CLR	A
	MOV	R0,#XDATA_TXBUF+45
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A		

	INC	R0
	;MOV	R0,#XDATA_TXBUF+49
	jmp	DSRC_VSTCell_InitModeOver
DSRC_VSTCell_InitModeOther:
	
	MOV	r0,#xdata_txbuf+40
	
	;原来好像没有加，要验证27
DSRC_VSTCell_InitModeOver:

	JMP	DSRC_VSTCell_SEGVSTTAIL

DSRC_VSTCell_PREAID01:
	
	;JB	BIT_INSERTCARD,DSRC_VSTCell_PREAID01Start	;没有插卡跳过不读不读IC卡信息
	;JMP	DSRC_VSTCell_NotUserCard
	MOV	R1,#DATA_RXBUF + 19			;
	MOV	A,@R1
	JB 	ACC.7,DSRC_VSTCell_PREAID01Start
	;---JMP	DSRC_VSTCell_BJ				;北京处理方式
	JMP	DSRC_VSTCell_NotUserCard
DSRC_VSTCell_PREAID01Start:
	

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	;2013-11-06
	MOV	R1,#DATA_RXBUF + 20
	MOV	A,@R1
	MOV	C,ACC.1
	
	;CALL	_fun_test_display
	MOV	BIT_Cellinfo,C
	;MOV	A,#26
	;JB	BIT_Cellinfo,DSRC_VSTCell_PREAID01READSYSINFO
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	MOV	R1,#DATA_RXBUF + 22			;系统信息文件预处理模式（长度）
	MOV	A,@R1
	
	;置位 gbICCInfo
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#26
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	JNZ	DSRC_VSTCell_PREAID01READSYSINFO
	MOV	R0,#XDATA_TXBUF + 13
	JMP	DSRC_VSTCell_PREREADSYSINFOOVER
	
DSRC_VSTCell_PREAID01READSYSINFO:
	
	;从 EPPROM 中读取 XX Byte 已事先从ESMA 中预读到Flash中的 SysInfo 文件
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	AR7,#XDATA_TXBUF + 14
	MOV	R3,A
	PUSH	ACC
	CALL	_RDFlashXR
	POP	ACC
	
	MOV	R0,#XDATA_TXBUF + 14
	ADD	A,R0
	MOV	R0,A
DSRC_VSTCell_PREREADSYSINFOOVER:
	
	JB	BIT_ISContact,DSRC_VSTCell_CPUPre
	JB	BIT_PROMF,DSRC_VSTCell_CPUPre
	JMP	DSRC_VSTCell_MFPre
DSRC_VSTCell_CPUPre:	;CPU卡预读
	
	MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	MOV	A,@R1

	JNZ	DSRC_VSTCell_CPUPreStart			;当没有预读信息时，则结束
	JMP	DSRC_VSTCell_SEGVSTTAIL
DSRC_VSTCell_CPUPreStart:		
	JB	BIT_INSERTCARD,DSRC_VSTCell_CPUPreHaveCard
	JMP	DSRC_VSTCell_SEGVSTTAIL
DSRC_VSTCell_CPUPreHaveCard:;有预读，有卡
	SETB	BIT_gbICCInfo	

	MOV	B,A
	MOV	A,#28H
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	mov	c,BIT_Cellinfo
	mov	acc.1,c;BIT_Cellinfo
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0
	MOV	A,B
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;Jb	BIT_Cellinfo,DSRC_VSTCell_nosysinfolen
	INC	R1	;22 系统信息文件预处理模式（长度）
;DSRC_VSTCell_nosysinfolen:
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	INC	R1	;23 
	
	;JNB	ACC.7,DSRC_VSTCell_SEG0015	
	PUSH	ACC	;各预读信息存在标志
	PUSH	AR1	;预读0002偏移量
	;MOV	R1,#DATA_RXBUF+21
	;MOV	A,@R1
	;MOV	R1,#DATA_RXBUF+24


;Bit7――读取0002文件标志
;Bit6――读取0012文件标志
;Bit5――读取0015文件标志
;Bit4――读取0019文件标志
;Bit3～Bit0――填充

	JB	ACC.5,DSRC_VSTCell_SEG0015Start
	JMP	DSRC_VSTCell_SEG0012
DSRC_VSTCell_SEG0015Start:
	JNB	ACC.7,DSRC_VSTCell_SEG001512E
	INC	R1
	INC	R1
DSRC_VSTCell_SEG001512E:	
	JNB	ACC.6,DSRC_VSTCell_SEG0015		
	INC	R1
	INC	R1
	
DSRC_VSTCell_SEG0015:
	;PUSH	AR1
	;MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	;MOV	A,@R1	
	;POP	AR1
	;JNB	ACC.5,DSRC_VSTCell_SEG0012


	;读0015文件
	MOV	DPH,#CONST_FLASH_0015H
	MOV	A,#CONST_FLASH_0015L
	ADD	A,@R1					;0015偏移量
	MOV	DPL,A

	INC	R1	
	MOV	A,@R1	
	MOV	R3,A					;0015文件长度
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;MOV	A,R0
	;ADD	A,#39
	;MOV	R0,A
	;MOV	A,R3
	;CALL	_FUN_TEST_DISPLAY


	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		

	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#16
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		

	;POP	AR1	;预读0002偏移量
	;POP	ACC	;各预读信息存在标志
	;JMP	SEG_DSRC_GETSendBufLen
DSRC_VSTCell_SEG0012:
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#12
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	POP	AR1	;预读0002偏移量
	POP	ACC	;各预读信息存在标志

	PUSH	ACC	;各预读信息存在标志
	PUSH	AR1	;预读0002偏移量

	JB	ACC.6,DSRC_VSTCell_SEG0012Start
	JMP	DSRC_VSTCell_SEG0019
DSRC_VSTCell_SEG0012Start:

	JNB	ACC.7,DSRC_VSTCell_SEG001202E
	INC	R1
	INC	R1
DSRC_VSTCell_SEG001202E:

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#13
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	

	;读0012文件
	MOV	DPH,#CONST_FLASH_0012H
	MOV	A,#CONST_FLASH_0012L
	ADD	A,@R1					;0012偏移量
	MOV	DPL,A

	INC	R1
	MOV	A,@R1
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#15
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	MOV	R3,A					;0012文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读Flash函数只操作了	R0，所以暂不PUSH R1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1

	MOV	A,R0
	ADD	A,R3
	MOV	R0,A

	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#16
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;POP	AR1	;预读0002偏移量
	;POP	ACC	;各预读信息存在标志
	;JMP	SEG_DSRC_GETSendBufLen
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
DSRC_VSTCell_SEG0019:
	
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;PUSH	AR1
	;MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	;MOV	A,@R1	
	;POP	AR1
	;JNB	ACC.4,DSRC_VSTCell_SEG0002
	;~~~~~~~~~~~~~~~~~~~~~~~~
	POP	AR1	;预读0002偏移量
	POP	ACC	;各预读信息存在标志

	PUSH	ACC	;各预读信息存在标志
	PUSH	AR1	;预读0002偏移量

	JB	ACC.4,DSRC_VSTCell_SEG0019Start
	JMP	DSRC_VSTCell_SEG0002
DSRC_VSTCell_SEG0019Start:
	
	JNB	ACC.7,DSRC_VSTCell_SEG001902E
	INC	R1
	INC	R1
DSRC_VSTCell_SEG001902E:
	JNB	ACC.6,DSRC_VSTCell_SEG001912E
	INC	R1
	INC	R1
DSRC_VSTCell_SEG001912E:
	JNB	ACC.5,DSRC_VSTCell_SEG001915E
	INC	R1
	INC	R1
DSRC_VSTCell_SEG001915E:
	
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,#19
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	;读0019文件
	MOV	DPH,#CONST_FLASH_0019H
	MOV	A,#CONST_FLASH_0019L
	ADD	A,@R1					;0019偏移量
	MOV	DPL,A

	INC	R1	
	MOV	A,@R1	
	MOV	R3,A					;0019文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
DSRC_VSTCell_SEG0002:

	POP	AR1	;预读0002偏移量
	POP	ACC	;各预读信息存在标志


	;PUSH	AR1
	;MOV	R1,#DATA_RXBUF + 21			;各预读信息存在标志
	;MOV	A,@R1	
	;POP	AR1
	;---JNB	ACC.7,DSRC_VSTCell_SEGVSTTAIL
	JB	ACC.7,DSRC_VSTCell_READ0002
	JMP	DSRC_VSTCell_SEGVSTTAIL
DSRC_VSTCell_READ0002:
	
	;PUSH	ACC	;各预读信息存在标志
	;PUSH	AR1	;预读0002偏移量
	
	
	;MOV	R1,#DATA_RXBUF + 23			;定位r1到bst'预读0002偏移量'

	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#02
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;读0002文件
	MOV	DPH,#CONST_FLASH_0002H
	MOV	A,#CONST_FLASH_0002L
	ADD	A,@R1					;0002偏移量
	MOV	DPL,A

	INC	R1	
	MOV	A,@R1	
	MOV	R3,A					;0002文件长度
	
	MOV	AR7,AR0
	PUSH	AR3
	PUSH	AR0
	PUSH	AR1
	CALL	_RDFlashXR				;读falsh函数只操作了	r0，所以暂不push r1
	POP	AR1
	POP	AR0
	POP	AR3
	INC	R1
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
	
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#02
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;POP	AR1	;预读0002偏移量
	;POP	ACC	;各预读信息存在标志
	
	JMP	DSRC_VSTCell_SEGVSTTAIL			;结束预读
	
	;--- MF卡预读 ---
DSRC_VSTCell_MFPre:
	JB	BIT_INSERTCARD,DSRC_VSTCell_MFPreHaveCard
	JMP	DSRC_VSTCell_SEGVSTTAIL	
DSRC_VSTCell_MFPreHaveCard:

	
	;--- R0接到发送绶冲的位置 ---
DSRC_VSTCell_SEGVSTTAIL:
	
	;~~~~~ 调用测试段 ~~~~~
	;MOV	A,R0
	;CLR	C
	;SUBB	A,#XDATA_TXBUF
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	PUSH	AR0
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	JNB	BIT_Cellinfo,DSRC_VSTCell_SEGVSTTAILZC
	
	MOV	R1,#DATA_RXBUF+21
	MOV	A,@R1
	
	MOV	R1,#DATA_RXBUF+23;22
	MOV	R3,#4
DSRC_VSTCell_LOOP01:
	RLC	A
	JNC	DSRC_VSTCell_LOOP01OV
	INC	R1
	INC	R1
DSRC_VSTCell_LOOP01OV:
	DJNZ	R3,DSRC_VSTCell_LOOP01
 	
	;记录 	CellId
	INC	R1						;去掉长度
	MOV	R0,#XDATA_CELLID				;xdata_hold
	MOV	A,@R1
	
	;Call	_fun_test_display	
	
	;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1
	INC	R0
	MOV	A,@R1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	;回应表示已收到 CellID
	pop	ar0
	mov	a,#00H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	inc	r0
	push	ar0
DSRC_VSTCell_SEGVSTTAILZC:
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	MOV	R0,#XDATA_TXBUF + 12
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	C,BIT_privateInfo
	MOV	ACC.6,C
	MOV	C,BIT_gbICCInfo
	MOV	ACC.5,C
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	POP	AR0
	
	;设置MACID
	MOV	DPTR,#STR_SYS_OBUID
	MOV	AR7,AR0
	CALL	_FUN_LIB_FLASHTOXDATA
	
	;--- 设备类型 ---
	MOV	A,#30h						;10H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	
	;--- 设备状态 ---
	CLR	A					
	MOV	C,BIT_INSERTCARD				;=1表示当前OBU插卡;=0表示当前OBU没插卡;
	CPL	C						;与国标DSRC定义相反，所以反一下
	MOV	ACC.7,C						;iccPresent -- 存在（0），无（1）
	MOV	ACC.3,C						;iccStatus -- IC卡正常（0），出错（1）
	
	;~~~~~~~~~~ 调用测试段 ~~~~~~~~~~
;	JB	BIT_PROMF,ASDFSDAF	
;	MOV	A,#03
;	JMP	DISPLAY
;ASDFSDAF:
;	MOV	A,#04
;DISPLAY:
;	JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	CLR	A
	MOV	C,BIT_INSERTCARD
	CPL	C
	MOV	ACC.7,C
	JNB	BIT_INSERTCARD,DSRC_VSTCell_CardTypeOver		;当前无卡
	JNB	BIT_ISContact,DSRC_VSTCell_CardTypePro		;当前是非接卡
DSRC_VSTCell_CardTypeContact:					;接触式CPU卡		0	0	0	
	JMP	DSRC_VSTCell_CardTypeOver				;当前是接触卡
DSRC_VSTCell_CardTypePro:						;非接触式CPU卡		0	1	0
	JNB	BIT_PROMF,DSRC_VSTCell_CardTypeMF	
	SETB	ACC.5
	JMP	DSRC_VSTCell_CardTypeOver
DSRC_VSTCell_CardTypeMF:						;非接触式逻辑加密卡	0	1	1	
	SETB	ACC.5
	SETB	ACC.4
DSRC_VSTCell_CardTypeOver:
	
	;Locked -- OBU未锁（0），被锁（1） Acc.2
	;Tampered -- OBU未被拆动（0），被拆动（1） acc.1
	;拆动的标记由，拆动次数是否为0。=0表示拆动，<> 0 表示没有拆动过。
;	MOV	R1,#XDATA_FIX
;	PUSH	ACC
;	ANL	A,#0FH
		
;	JZ	DSRC_VSTCell_Tampered
;	CLR	C
;	JMP	DSRC_VSTCell_TamperedOver
;DSRC_VSTCell_Tampered:	
;	SETB	C
;	;SETB	
;DSRC_VSTCell_TamperedOver:
;	POP	ACC

	MOV	C,BIT_CD
	;---clr	c
	MOV	ACC.1,C
	
	;Battery – OBU电池正常（0），电池电量低（1）	acc.0	
		;MOVX	@R0,A
	MOV 	DPH,#1
	MOV 	DPL,R0
	MOVX 	@DPTR,A
	INC	R0
	
	;ESAM第 27 字节"拆卸状态"
	;---MOV	A,#0FFH
	;PUSH	AR0
	;MOV	DPH,#CONST_FLASH_SYSINFOH
	;MOV	DPL,#CONST_FLASH_SYSINFOL + 26
	;MOV	AR7,#XDATA_FIX
	;MOV	R3,#1
	;CALL	_RDFlashXR	
	;POP	AR0
	
	MOV	R1,#XDATA_FIX
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	;MOV	A,#0FFH;暂加
	;CLR	A
	
	;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	
	;CLR	A
	;MOV	C,BIT_Cellinfo
	;;MOV	ACC.0,C
	;CALL	_FUN_TEST_DISPLAY	
	JMP	SEG_DSRC_GETSendBufLen ;VST_OVER
	
	END
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	



