;******************************************************************
;描述：卡片操作扩展程序集[它在Contact.asm的函数做扩展应用]
;_FUN_CARDAPP_SelectFile		---	选目录或文件
;_FUN_CARDAPP_ReadBinary		---	读二进制文件
;_FUN_CARDAPP_GetBalance		---	读余额
;_FUN_CARDAPP_ReadRecord		---	读记录文件
;_FUN_CARDAPP_CardChannel		---	卡片通道函数(支持contact cpu/esam/pro/mf/)
;_FUN_CARDAPP_DECCounter		---	减记数器	
;_FUN_CARDAPP_UpdateBinary		---	写二进制文件
;******************************************************************
NAME	CARDAPP

$INCLUDE(COMMON.INC)
$INCLUDE(CARDAPP.INC)
	
	RSEG	?pr?CARDAPP?Mater
	USING	0
;--------------------------------------------------------------------------
;描述:写二进制文件
;00 d6 Offset Offset Len data
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R7+5			---	将要写入的数据
;	R5			---	接收送绶冲指针(外存)
;	R4			---	offset01
;	R3			---	offset02
;	R2			---	len

;内部参数:
;返回值
;	R7			---	接收状态(正确为0 ，其它为不正确)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------
_FUN_CARDAPP_UpdateBinary:
	
	MOV	AR0,AR7
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#0d6H
	INC	R0
	;MOV	A,#80H
	;XRL	A,R4
	MOV	A,R4
	MOV	@R0,A
	INC	R0
	MOV	A,R3
	MOV	@R0,A
	INC	R0
	MOV	A,R2
	MOV	@R0,A	
	add	A,#5	
	MOV	R3,A
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	POP	AR5
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	;MOV	R7,#0
	
	RET
;--------------------------------------------------------------------------
;描述:选目录或文件(_FUN_CARDAPP_SelectFile)
;00 A4 00 00 02 XX XX
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡   ;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R3			---	文件ID_High
;	R2			---	文件ID_Low
;内部参数:
;返回值
;	R7			---	接收状态(正确为0 ，其它为不正确)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------	
_FUN_CARDAPP_SelectFile:

	MOV	AR0,AR7
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#0A4H
	INC	R0	
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#00
	INC	R0		
	MOV	@R0,#02
	INC	R0		
	MOV	A,R3
	MOV	@R0,A
	INC	R0
	MOV	A,R2
	MOV	@R0,A
	MOV	R3,#07H				;LEN	
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	;CALL	_FUN_TestContact_Channel0
	POP	AR5

	;MOV	a,r3							;有的ESAM选1001快比PPS回应还快，所以要再补上一些延时
	;CALL	_FUN_TEST_DISPLAY	
		
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	

	;MOV	A,#31

	JNB	BIT_GETRESULT,CARDAPP_SelectFile_NOResult
CARDAPP_SelectFile_Result:	
	XRL	A,#90H
	JMP	CARDAPP_SelectFile_ResultOver
CARDAPP_SelectFile_NOResult:
	XRL	A,#61H
CARDAPP_SelectFile_ResultOver:
	
	MOV	R7,A
	
	RET
		
;_FUN_TESTContact_OPRET0	
_FUN_TESTCARDAPP_SelectFile:
	MOV	AR0,AR7
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#0A4H
	INC	R0	
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#00
	INC	R0		
	MOV	@R0,#02
	INC	R0		
	MOV	A,R3
	MOV	@R0,A
	INC	R0
	MOV	A,R2
	MOV	@R0,A
	MOV	R3,#07H				;LEN	
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	;---CALL	_FUN_CARDAPP_CardChannel
	CALL	_FUN_ProCard_Channel
	;CALL	_FUN_TestContact_Channel0
	POP	AR5
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	RET
;--------------------------------------------------------------------------
;描述:读二进制文件
;00 B0 80^FildID Offset Len
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R4			---	文件ID
;	R3			---	长度
;	R2			---	offset

;内部参数:
;返回值
;	R7			---	接收状态(正确为0 ，其它为不正确)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------	
_FUN_CARDAPP_ReadBinary:
	
	MOV	AR0,AR7
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#0B0H
	INC	R0	
	MOV	A,#80H
	XRL	A,R4
	MOV	@R0,A
	INC	R0
	MOV	A,R2
	MOV	@R0,A
	INC	R0
	MOV	A,R3
	MOV	@R0,A
	MOV	R3,#05H
	
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	POP	AR5
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	;MOV	R7,#0
	
	RET
	
;--------------------------------------------------------------------------
;描述:读二进制文件
;00 B0 Offset Offset Len
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R4			---	offset01
;	R3			---	offset02
;	R2			---	len

;内部参数:
;返回值
;	R7			---	接收状态(正确为0 ，其它为不正确)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------	
_FUN_CARDAPP_ReadBinary02:
	
	MOV	AR0,AR7
	MOV	@R0,#00
	INC	R0	
	MOV	@R0,#0B0H
	INC	R0	
	;MOV	A,#80H
	;XRL	A,R4
	MOV	A,R4
	MOV	@R0,A
	INC	R0
	MOV	A,R3
	MOV	@R0,A
	INC	R0
	MOV	A,R2
	MOV	@R0,A
	MOV	R3,#05H
	
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	POP	AR5
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	;MOV	R7,#0
	
	RET	
;--------------------------------------------------------------------------
;描述:读余额	
;80 5C 00 02 04
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;内部参数:
;返回值
;	R7			---	接收状态(正确为0 ，其它为不正确)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------		
_FUN_CARDAPP_GetBalance:
	
	MOV	AR0,AR7
	MOV	@R0,#80H
	INC	R0
	MOV	@R0,#5CH
	INC	R0
	MOV	@R0,#00H
	INC	R0
	MOV	@R0,#02H
	INC	R0
	MOV	@R0,#04H
	;INC	R0
	
	MOV	R3,#05H
	PUSH	AR5
	;MOV	A,R5
	;MOV	A,#35
;	MOV	R2,#30
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel
	
;mov	a,r3
;CALL	_FUN_TEST_DISPLAY	
	POP	AR5

	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	
	RET
	
;--------------------------------------------------------------------------
;描述:读记录文件
;00 B2 01 CC 2B 
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R4			---	文件名
;	R3			---	长度
;	R2			---	记录号	
;内部参数:
;返回值
;	R7			---	接收状态(正确为0 ，其它为不正确)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------	
_FUN_CARDAPP_ReadRecord:
	
	MOV	AR0,AR7
	MOV	@R0,#00H
	INC	R0
	MOV	@R0,#0B2H
	INC	R0
	mov	a,r2
	MOV	@R0,a;#02H
	INC	R0
	
	MOV 	A,R4
	SWAP 	A		;91
	RR 	A		;48
	ORL 	A,#4		;4c
	MOV	@R0,A
	
	INC	R0
	MOV	A,R3
	MOV	@R0,A
	
	MOV	R3,#05H
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel		
	POP	AR5
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	
	RET
;--------------------------------------------------------------------------
;描述:减记数器
;00 59 00 00 01
;当返回69 85时，表示已经减记数器为零
;外部参数
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;内部参数:
;返回值	  
;	R7			---	执行状态码; =0 表示执行成功	;=1 表示执行失败
;	r3			---	减记数次数
;--------------------------------------------------------------------------
_FUN_CARDAPP_DECCounter:
	
	MOV	AR0,AR7
	MOV	@R0,#00H
	INC	R0
	MOV	@R0,#59H
	INC	R0
	MOV	@R0,#00H
	INC	R0
	MOV	@R0,#00H
	INC	R0
	MOV	@R0,#01H
	;INC	R0
	
	MOV	R3,#05H
	PUSH	AR5
	;---CALL	_FUN_Contact_Channel
	CALL	_FUN_CARDAPP_CardChannel	
	;CALL	_FUN_TestContact_Channel0	
	POP	AR5	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	
;	JNZ	CARDAPP_DECCounter_ZTCL	
	
	MOV	AR0,AR5
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR			;所省减记数次数
	MOV	R3,A
;	JMP	CARDAPP_DECCounter_OVER
	
;CARDAPP_DECCounter_ZTCL:	
;	MOV	R7,#CONST_STATE_FALSE
;	MOV	AR0,AR5
;		;MOVX	A,@R0

;	XRL	A,#69H
;	JNZ	CARDAPP_DECCounter_OVER
;	INC	R0
;		;MOVX	A,@R0

;	XRL	A,#82H
;	JNZ	CARDAPP_DECCounter_OVER
;	MOV	R7,#CONST_STATE_TRUE	
;	MOV	R3,#0			;所省减记数次数为零
CARDAPP_DECCounter_OVER:	
	
	RET

;--------------------------------------------------------------------------
;描述:写二进制文件
;00 A4 00 00 02 XX XX
;外部参数
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R4			---	文件ID
;	R3			---	长度
;	R2			---	Offset
;内部参数:
;返回值	
;	R7			---	接收送绶冲指针(外存)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------	
_FUN_CARDAPP_WriteBinary:	;---	写二进制文件
	JMP	_FUN_Contact_Channel
;--------------------------------------------------------------------------
;描述:读车辆信息文件(专用指令)
;00 + B4 + Offset_H + Offset_L + Random(8 Byte) + ReadLen(xx Byte) + KeyID(1 Byte)
;外部参数
;	BIT_ESAMICC		---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM
;	R7			---	发送绶冲指针(内存)
;	R5			---	接收送绶冲指针(外存)
;	R3			---	文件ID_High
;	R2			---	文件ID_Low

;内部参数:
;返回值
;	R7			---	接收送绶冲指针(外存)
;	R3			---	接收到数据的长度
;--------------------------------------------------------------------------
_FUN_CARDAPP_ReadVehicleInfo:	
	JMP	_FUN_Contact_Channel
	
	
;--------------------------------------------------------------------------
;描述:卡片通道函数(支持contact cpu/esam/pro/mf/)	
;外部参数:
;BIT_ISContact			---	上一次及本次插卡类型，=1是接触卡=0是非接触卡
;BIT_cpu_ProMF 			---	=1 表示是PRO卡，=0表示，MF卡

;BIT_ESAMICC			---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM(只在接触卡通道用)
;BIT_GETRESULT				=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)

;R7				---	发送绶冲指针(内存)
;R5				---	接收送绶冲指针(外存)
;R3				---	将要发送数据的长度
;返回值
;	R7			---	接收送绶冲指针(外存)
;	R3			---	接收到数据的长度
;
;优先级	BIT_ESAMICC > BIT_ISContact > BIT_ProMF
;--------------------------------------------------------------------------
_FUN_CARDAPP_CardChannel:
	JB	BIT_ESAMICC,CARDAPP_CardChannel_ICC
CARDAPP_CardChannel_ESAM:;ESAM 卡

	CALL	_FUN_Contact_Channel	;ESAM卡通道
	JMP	CARDAPP_CardChannel_Over
	
CARDAPP_CardChannel_ICC:;用户卡	
	
	JNB	BIT_ISContact,CARDAPP_CardChannel_NContact	
	
	;mov	a,#19
	;call	_fun_test_display
	
	CALL	_FUN_Contact_Channel	;CPU接触卡通道
	JMP	CARDAPP_CardChannel_Over
CARDAPP_CardChannel_NContact:;非接卡
	JB	BIT_ProMF,CARDAPP_CardChannel_PRO
CARDAPP_CardChannel_MF:	;MF卡
	CALL	_FUN_MF_Channel		;MF卡通道
	JMP	CARDAPP_CardChannel_Over
CARDAPP_CardChannel_PRO:;PRO卡
	CALL	_FUN_ProCard_Channel	;Pro卡通道
;	MOV	a,r3							;有的ESAM选1001快比PPS回应还快，所以要再补上一些延时
;	CALL	_FUN_TEST_DISPLAY	
		
CARDAPP_CardChannel_Over:
	
	RET
	
;--------------------------------------------------------------------------	
;描述:卡片通道函数(支持contact cpu/esam/pro/mf/)	
;外部参数:
;BIT_ISContact			---	上一次及本次插卡类型，=1是接触卡=0是非接触卡
;BIT_cpu_ProMF 			---	=1 表示是PRO卡，=0表示，MF卡

;BIT_ESAMICC			---	当前操作接触卡的类型=1表示用户卡;=0表示ESAM(只在接触卡通道用)
;BIT_GETRESULT				=1表示取0时，取返回结果，=0表示不取返回结果(只对T0卡，指令大于5个字节的指令有效或pro有效)

;R7				---	发送绶冲指针(内存)
;R5				---	接收送绶冲指针(外存)
;R3				---	将要发送数据的长度
;返回值
;	R7			---	返回值
;	R3			---	接收到数据的长度
;
;优先级	BIT_ESAMICC > BIT_ISContact > BIT_ProMF
;--------------------------------------------------------------------------	
_FUN_CARDAPP_InnerCardChannel:
	
	PUSH	AR5
	CALL	_FUN_CARDAPP_CardChannel		
	POP	AR5
	
	;返回状态码
	MOV	A,R5
	ADD	A,R3
	DEC	A
	DEC	A
	MOV	R0,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#90H
	MOV	R7,A
	
	RET
	
;---------------------------------------------------------------------------
;描述：
;	是否是导入卡或激活卡
;参数:
;	无
;返回值
;	R7	=0成功,=ff失败
;	R5	=0D导入卡 ; = 0EH 激活卡
;--------------------------------------------------------------------------	
_FUN_CARDAPP_ISInOrACT:	
	;=== 选择导入卡的1001目录 ===
	; BIT_ESAMICC=1表示用户卡;=0表示ESAM
	CLR	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#010H
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	CARDAPP_ISInOrACT_Sel1001OK
	JMP	CARDAPP_ISInOrACT_Err
	
CARDAPP_ISInOrACT_Sel1001OK:		
	;读取导入卡 0015 文件，判断是否为导入卡0E[第9个字节，下标由1开始]
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD
	MOV	R4,#95h							;R4		---	文件ID
	MOV	R3,#08							;R3		---	长度
	MOV	R2,#01
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	CARDAPP_ISInOrACT_Read0015OK
	JMP	CARDAPP_ISInOrACT_Err
		
CARDAPP_ISInOrACT_Read0015OK:	
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;XRL	A,#0EH
	MOV	R5,A
CARDAPP_ISInOrACT_OVER:
	MOV	R7,#CONST_STATE_TRUE
	RET
	
CARDAPP_ISInOrACT_Err:
	MOV	R7,#CONST_STATE_FALSE
	
	RET
;---------------------------------------------------------------------------
;广东导入卡流程
;	选择导入卡的1001目录
;	读取导入卡0015文件，判断是否为导入卡0D[第9个字节，下标由1开始]
;	选择ESAM的MF目录
;	读取OBU合同序号
;	读取导入卡0019文件,判断其中的合同序列号与OBU合同序列号是否相同
;	选择ESAM的DF01目录
;	
;返回值
;	01 表示导入卡失效
;--------------------------------------------------------------------------	
_FUN_CARDAPP_GDFXOBU:
	
	;=== 选择导入卡的 1001 目录 ===
	; BIT_ESAMICC=1表示用户卡;=0 表示ESAM
;	SETB	BIT_GETRESULT
;	SETB	BIT_ESAMICC
;	MOV	R7,#DATA_RXBUF
;	MOV	R5,#XDATA_TXBUF
;	MOV	R3,#010H
;	MOV	R2,#001H
;	CALL	_FUN_CARDAPP_SelectFile
	
	;读取导入卡 0015 文件，判断是否为导入卡0D[第9个字节，下标由1开始]
;	SETB	BIT_ESAMICC						;当前对用户卡操作
;	SETB	BIT_GETRESULT	
;	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
;	MOV	R5,#XDATA_HOLD
;	MOV	R4,#95h							;R4		---	文件ID
;	MOV	R3,#08							;R3		---	长度
;	MOV	R2,#01;04;03
;	CALL	_FUN_CARDAPP_ReadBinary02
;	MOV	A,R7
;	JZ	CARDAPP_GDFXOBU_Read0015OK
;	JMP	CARDAPP_GDFXOBU_Err
	
;CARDAPP_GDFXOBU_Read0015OK:
;	MOV	R0,#XDATA_HOLD
;		;MOVX	A,@R0

;	XRL	A,#0DH
;	JZ	CARDAPP_GDFXOBU_DRCard
;	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_DRCard:
	
	;选择 ESAM 的 MF 目录,只进行到61
	CLR	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_ReadSel3f00OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_ReadSel3f00OK:
	
	;==============================
	;读取 OBU 合同序号
	;XDATA_HOLD[0~7] ESAM 合同序号
	;==============================
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD
	MOV	R4,#81h							;R4		---	文件ID
	MOV	R3,#0ah							;R3		---	长度
	MOV	R2,#08;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	JZ	CARDAPP_GDFXOBU_ReadESAMHTHOK
	MOV	R7,#CONST_STATE_InputFail	
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_ReadESAMHTHOK:
	;读取导入卡 0019 合同序号
	;XDATA_HOLD[0~7] ESAM 合同序号
	;XDATA_txbuf[0~12] 0019文件
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#99h							;R4		---	文件ID
	MOV	R3,#00							;R3		---	长度
	MOV	R2,#13;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	JZ	CARDAPP_GDFXOBU_Read0019OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Read0019OK:
	
	;比较 合同号 是否相同
	MOV	r1,#xdata_txbuf+4
	MOV	r0,#xdata_HOLD
	MOV	R3,#8
CARDAPP_GDFXOBU_COMP:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,B
	
	JZ	CARDAPP_GDFXOBU_NoErZZ
	MOV	R7,#CONST_STATE_IllegalInputCard
	JMP	CARDAPP_GDFXOBU_Err
CARDAPP_GDFXOBU_NoErZZ:	
	INC	R1
	INC	R0
	DJNZ	R3,CARDAPP_GDFXOBU_COMP
	
CARDAPP_GDFXOBU_COMPOV:	
	;XDATA_HOLD[0~7] ESAM 合同序号
	;XDATA_txbuf[0~12] 0019文件
	MOV	R1,#xdata_txbuf+12
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	XRL	A,#0FFH
	JNZ	CARDAPP_GDFXOBU_Valid	
	MOV	R7,#CONST_STATE_InputCardInvalid
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Valid:
	
	;选择 ESAM 的 DF01 目录
	CLR	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0DFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_SelESAMDF01OK
	MOV	R7,#CONST_STATE_InputFail	
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_SelESAMDF01OK:		
	;获取 ESAM 随机数
	;XDATA_HOLD[0~3] ESAM df01 rand
	;XDATA_Txbuf[0~12] 0019 文件
	MOV	DPTR,#STR_CARDAPP_Rand
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD
	;R3
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_GetESAMRandOK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_GetESAMRandOK:
	;将4字节随机数与“04D68100”（16进制数，4字节）进行异域
	;XDATA_HOLD[0~3] 	DF01 RAND
	;XDATA_txbuf[0~12] 	0019文件
	MOV	R7,#XDATA_HOLD
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#4
	MOV	DPtr,#STR_CARDAPP_xor04d68100
	CALL	_FUN_CARDAPP_xxDATAFlashXOR
	
	;获得0019文件中的车辆信息
	;XDATA_HOLD[0~3] ESAM DF01 随机数
	;XDATA_txbuf[0~78] 0019 车辆信息
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT						;
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#99h							;R4		---	文件ID
	MOV	R3,#00DH						;R3		---	长度
	MOV	R2,#04FH
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_Read0019VehicleOK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Read0019VehicleOK:
	
	;获得 0015 文件中的车辆信息
	;XDATA_HOLD[0~3]	ESAM DF01 随机数
	;XDATA_HOLD[4~6]	PIN
	;XDATA_txbuf[0~78] 	0019 车辆信息
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD+4
	MOV	R4,#95h							;R4		---	文件ID
	MOV	R3,#00EH						;R3		---	长度
	MOV	R2,#06H
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	JZ	CARDAPP_GDFXOBU_Read0015CardNoOK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
CARDAPP_GDFXOBU_Read0015CardNoOK:

	;MOV			R7,#CONST_STATE_TRUE
	;XOR			pre 3 / next 3
	;XDATA_HOLD[0~3]	ESAM DF01 随机数
	;XDATA_HOLD[4~9]	Card NO
	;XDATA_txbuf[0~78] 	0019 车辆信息
	;MOV			R0,#XDATA_HOLD+4
	;MOV			R1,#XDATA_HOLD+4+3
	
	;倒一下
	MOV	R0,#XDATA_HOLD + 4 + 3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
	
	MOV	R0,#XDATA_HOLD + 4 + 5
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	MOV	R0,#XDATA_HOLD + 4 + 3
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R0,#XDATA_HOLD + 4 + 5
	MOV	A,B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R7,#XDATA_HOLD + 4
	MOV	R5,#XDATA_HOLD + 4 + 3
	MOV	R3,#3
	CALL	_FUN_CARDAPP_xxDATAXOR
		
	
	;XDATA_HOLD[0~3]	ESAM DF01 随机数
	;XDATA_HOLD[4~6]	PIN
	;XDATA_txbuf[0~78] 	0019 车辆信息	
	MOV	R7,#XDATA_HOLD+4
	MOV	R5,#XDATA_HOLD+4+3
	MOV	R3,#3
	MOV	DPTR,#STR_CARDAPP_xor3e267a
	CALL	_FUN_CARDAPP_xxDATAFLASHXOR
	
	;PIN 认证 '0020000003' + strPIN
	;XDATA_HOLD[0~3]	ESAM DF01 随机数
	;XDATA_HOLD[4~6]	PIN
	;XDATA_txbuf[0~78] 	0019 车辆信息
	MOV	DPTR,#STR_CARDAPP_PIN
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_HOLD+4
	MOV	R3,#3
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7
	
	MOV	R3,#5+3
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_PINOK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_PINOK:

	;MOV	R7,#CONST_STATE_TRUE
	;RET
	
	;内部 认证 计算MAC01
	;XDATA_HOLD[0~3]	RAND
	;XDATA_HOLD[4~6]	PIN
	;XDATA_HOLD[7~10]	MAC
	;xdata_txbuf[0~78]	车辆信息
	;0088020054 + ran + 53 + 车辆信息
	;008802003f + ran + 3E + 车辆信息[3Fh - 5h = 3A ]
	MOV	DPTR,#STR_CARDAPP_88
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_HOLD
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R0,#DATA_RXBUF+5+4
	;MOV	A,#3EH
	MOV	A,#53H
	MOV	@R0,A
	
	MOV	R5,#DATA_RXBUF+5+4+1
	MOV	R7,#XDATA_TXBUF
	;MOV	R3,#3AH
	MOV	R3,#4fH
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7
	;MOV	R3,#5H+4H+1H+3AH;63
	MOV	R3,#5H+4H+1H+4fH;63
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_88OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_88OK:
	;MOV	R7,#CONST_STATE_TRUE
	;RET
	
	;更新 EF01 文件
	;XDATA_HOLD[0~3]	RAND
	;XDATA_HOLD[4~6]	PIN
	;XDATA_HOLD[7~A]	MAC
	;xdata_txbuf[0~78]	车辆信息
	;04H,0d6H,81H,00H,53H + 车辆信息 + MAC
	;04H,0d6H,81H,00H,3eH + 车辆信息 + MAC
	MOV	DPTR,#STR_CARDAPP_D681
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#4fh;58 3a
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	AR5,#DATA_RXBUF + 5 + 4fh;58
	MOV	R7,#XDATA_HOLD + 7
	MOV	R3,#04
	CALL	_FUN_LIB_XDATATODATA
	
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7+4
	;MOV	R3,#5+58+4
	MOV	R3,#5+4fh+4
	CALL	_FUN_CARDAPP_InnerCardChannel
	
;	MOV	R7,#DATA_RXBUF
;	MOV	R5,#CONST_SOFTBYTESP
;	CLR	BIT_BUFADDR					;=0，发送的是内存数据；=1，发送的是外存数据
;	SETB	BIT_VERIFY					;串口收发是否要加验位,=0不要，=1要							
;	CALL	_FUN_SERIAL_TXSOFT
		
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_D681OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
CARDAPP_GDFXOBU_D681OK:
	

;----------------------------------------------------------------------------	
	;MOV	R7,#0
	;RET
	
	;写系统信息
	;选择ESAM的 3F00 目录
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	
	JZ	CARDAPP_GDFXOBU_Sel3F00OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Sel3F00OK:	
;----------------------------------------------------------------------------	
;将导入卡中1001,001C，车辆信息写入ESAM 3F00  EF1D[50~128]
;EF1D[1~49] [50~128]
;(1)、	对ESAM执行指令”00A40000023F00”,
; 读 [导入卡].1001.001c.4fh个字节
;00 b0 9c 00h 4fh 
; 再执行” 0084000004”，产生4字节随机数；
;04 D6 9d offset

;(2)、	将4字节随机数与“04 D6 9D 00”（16进制数，4字节）进行异域，得到的结果假定为异或值。

;00 88 02 01 + datalen + 4 + 1 + 异或值 + “datalen+4” + 数据
;(3)、	对导入卡执行指令00 88 02 01 54 + 异或值  + 53 + data,得到结果为4字节的内容，假定为MAC。

;“04 D6 fileid offset +datalen+4”+ 数据+　MAC
;(4)、	对ESAM执行指令04H,0d6H,9dH,31H,53H+ 数据+　MAC，即完成对MF下的EF1d文件的更新。

;5) 读 [导入卡].1001.001c.49个字节
;00 b0 9c 4fh 31h 
;6) 向esam 取 rand
;00 84 00 00 08
;7).rand xor 04 d6 9d offset 
; rand xor 04 d6 9d 4f => xorValue
;8)计算mac .00 88 02 01 + datalen + 4 + 1 + 异或值 + “datalen+4” + 数据
;00 88 02 01 31h+4+1 + xorValue +  31h+4 + data
;9.向esam.3f00.ef1d,写入128-79个字节，起启位置79 “04 D6 fileid offset +datalen+4”+ 数据+　MAC
;“04 D6 9d 4fh +31h+4”+ 数据+　MAC
;----------------------------------------------------------------------------

	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT						;
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#9Ch							;R4		---	文件ID
	MOV	R3,#000H						;R3		---	长度
	MOV	R2,#04FH
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_Read0019Vehicle02OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Read0019Vehicle02OK:	

	;mov	r0,#xdata_txbuf+27
	;	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR
	;MOV	A,#37
	;call	_fun_test_display

	;获取ESAM随机数
	;XDATA_HOLD[0~3]
	;xdata_txbuf[0~78]	车辆信息
	MOV	DPTR,#STR_CARDAPP_Rand
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA	
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD	
	CALL	_FUN_CARDAPP_InnerCardChannel
	
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_GetESAMRand04OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err	
CARDAPP_GDFXOBU_GetESAMRand04OK:
	
	;将 4 字节随机数与  04 D6 9D 31（16进制数，4字节）进行异域
	;XDATA_HOLD[0~3]	RAND
	MOV	R7,#XDATA_HOLD
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#4
	MOV	DPtr,#STR_CARDAPP_xor04d69D31
	CALL	_FUN_CARDAPP_xxDATAFlashXOR
	
	;XDATA_HOLD[0~3]	RAND	
	;XDATA_HOLD[4~7]	MAC
	;xdata_txbuf[0~78]	车辆信息
	;00 88 02 01 + datalen + 4 + 1 + 异或值 + “datalen+4” + 数据
	;00 88 02 01 54 + rand + 53 + data
	;0E = 随机数后面的长度即日期长度加1 
	;计算 MAC
	MOV	DPTR,#STR_CARDAPP_88_05
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	;MOV	R0,#DATA_RXBUF + 5
	;MOV	R1,#XDATA_HOLD
	
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF + 5
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R0,#DATA_RXBUF+5+4
	MOV	A,#53H	
	MOV	@R0,A
	
	MOV	AR5,#DATA_RXBUF+5+4+1
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#4fh
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#5+4+1+4fh
	CALL	_FUN_CARDAPP_InnerCardChannel
	
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_8804OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_8804OK:	

	;EF01 文件的更新
	;XDATA_HOLD[0~3]	RAND
	;XDATA_HOLD[4~7]	MAC
	;XDATA_TXBUF[0~8]	0019 文件中的日期
	;“04 D6 fileid offset +datalen+4”+ 数据+　MAC
	;04H,0d6H,9dH,31H,53H+ 数据+　MAC
	MOV	DPTR,#STR_CARDAPP_D68105
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#4fh
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	AR5,#DATA_RXBUF + 5 + 4fh
	MOV	R7,#XDATA_HOLD + 4
	MOV	R3,#04
	CALL	_FUN_LIB_XDATATODATA
		
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7+4
	MOV	R3,#5H+4fh+4H
	CALL	_FUN_CARDAPP_InnerCardChannel	
	MOV	A,R7
	;---JZ	CARDAPP_GDFXOBU_UpdataEF01OK
	JZ	CARDAPP_GDFXOBU_Updatesysinfo
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err

CARDAPP_GDFXOBU_Updatesysinfo:

;5) 读 [导入卡].1001.001c.49个字节
;00 b0 00 4fh 31h 
;6) 向esam取rand
;00 84 00 00 08
;7).rand xor 04 d6 9d offset 
; rand xor 04 d6 9d 4f => xorValue
;8)计算mac .00 88 02 01 + datalen + 4 + 1 + 异或值 + “datalen+4” + 数据
;00 88 02 01 31h+4+1 + xorValue +  31h+4 + data
;9.向esam.3f00.ef1d,写入128-79个字节，起启位置79 “04 D6 fileid offset +datalen+4”+ 数据+　MAC
;“04 D6 9d 4fh +31h+4”+ 数据+　MAC
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT						;
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#9Ch							;R4		---	文件ID
	MOV	R3,#04fH						;R3		---	长度
	MOV	R2,#031H
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_Read0019Vehicle03OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Read0019Vehicle03OK:	

	;获取ESAM随机数
	;XDATA_HOLD[0~3]
	;xdata_txbuf[0~48]	车辆信息
	MOV	DPTR,#STR_CARDAPP_Rand
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA	
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD	
	CALL	_FUN_CARDAPP_InnerCardChannel
	
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_GetESAMRand05OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err	
CARDAPP_GDFXOBU_GetESAMRand05OK:
	
	;将 4 字节随机数与  04 D6 9D 31（16进制数，4字节）进行异域
	;XDATA_HOLD[0~3]	RAND
	MOV	R7,#XDATA_HOLD
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#4
	MOV	DPtr,#STR_CARDAPP_xor04d69D4f
	CALL	_FUN_CARDAPP_xxDATAFlashXOR
	
	;XDATA_HOLD[0~3]	RAND	
	;XDATA_HOLD[4~7]	MAC
	;xdata_txbuf[0~48]	车辆信息
	;00 88 02 01 + datalen + 4 + 1 + 异或值 + “datalen+4” + 数据
	;00 88 02 01 54 + rand + 53 + data
	;00 88 02 01 31h+4+1 + xorValue +  31h+4 + data
	;0E = 随机数后面的长度即日期长度加1 
	;计算 MAC
	MOV	DPTR,#STR_CARDAPP_88_06
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	;MOV	R0,#DATA_RXBUF + 5
	;MOV	R1,#XDATA_HOLD
	
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF + 5
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R0,#DATA_RXBUF+5+4
	MOV	A,#35H	
	MOV	@R0,A
	
	MOV	AR5,#DATA_RXBUF+5+4+1
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#31h
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#5+4+1+31h
	CALL	_FUN_CARDAPP_InnerCardChannel
	
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_88042OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_88042OK:	

	;EF01 文件的更新
	;XDATA_HOLD[0~3]	RAND
	;XDATA_HOLD[4~7]	MAC
	;XDATA_TXBUF[0~8]	0019 文件中的日期
	;“04 D6 fileid offset +datalen+4”+ 数据+　MAC
	;“04 D6 9d 4fh +31h+4”+ 数据+　MAC
	MOV	DPTR,#STR_CARDAPP_D68106
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#31h
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	AR5,#DATA_RXBUF + 5 + 31h
	MOV	R7,#XDATA_HOLD + 4
	MOV	R3,#04
	CALL	_FUN_LIB_XDATATODATA
		
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7+4
	MOV	R3,#5H+31h+4H
	CALL	_FUN_CARDAPP_InnerCardChannel	
	MOV	A,R7
	;---JZ	CARDAPP_GDFXOBU_UpdataEF01OK
	JZ	CARDAPP_GDFXOBU_Updatesysinfo2
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err

CARDAPP_GDFXOBU_Updatesysinfo2:

;----------------------------------------------------------------------------	
	;mov	r0,#DATA_RXBUF+5+1bh
	;mov	a,@r0
	;mov	a,r3
	;call	_fun_test_display	
	
	;CLR	BIT_ESAMICC						;当前对用户卡操作
	;SETB	BIT_GETRESULT	
	;MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	;MOV	R5,#XDATA_HOLD
	;MOV	R4,#00h							;R4		---	文件ID
	;MOV	R3,#1bh							;R3		---	长度
	;MOV	R2,#12;04;03
	;CALL	_FUN_CARDAPP_ReadBinary02
	;MOV	A,R7	
	
	;mov	r0,#XDATA_HOLD
	;	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR
	;MOV	A,#37
	;call	_fun_test_display	
	
	;mov	a,#37
	;call	_fun_test_display
;----------------------------------------------------------------------------	
	;获取ESAM随机数
	;XDATA_HOLD[0~3]
	MOV	DPTR,#STR_CARDAPP_Rand
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA	
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD	
	CALL	_FUN_CARDAPP_InnerCardChannel

	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_GetESAMRand03OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_GetESAMRand03OK:	
	;将 4 字节随机数与  “04d68112” （16进制数，4字节）进行异域
	;XDATA_HOLD[0~3]	RAND
	MOV	R7,#XDATA_HOLD
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#4
	MOV	DPtr,#STR_CARDAPP_xor04d68112
	CALL	_FUN_CARDAPP_xxDATAFlashXOR
	
	;获得 0019 文件中的系统信息	
	;XDATA_TXBUF[0~8]	0019文件中的日期
	;00 B0 99 5C 09		5C偏移量,09长度
	SETB	BIT_ESAMICC						; 当前对用户卡操作
	SETB	BIT_GETRESULT						; 
	MOV	R7,#DATA_RXBUF						; R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF						; 
	MOV	R4,#99h							; R4		---	文件ID
	MOV	R3,#05CH						; R3		---	长度
	MOV	R2,#009H
	CALL	_FUN_CARDAPP_ReadBinary02

	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_Read0019DATAOK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_Read0019DATAOK:
	;XDATA_HOLD[0~3]	RAND	
	;XDATA_HOLD[4~7]	MAC
	;XDATA_TXBUF[0~8]	0019文件中的日期
	;00 88 02 01 0E + rand + 0D + data
	;0E = 随机数后面的长度即日期长度加1 
	;计算 MAC
	MOV	DPTR,#STR_CARDAPP_88_03
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	;MOV	R0,#DATA_RXBUF + 5
	;MOV	R1,#XDATA_HOLD
	
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF + 5
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R0,#DATA_RXBUF+5+4
	MOV	A,#0DH	
	MOV	@R0,A
	
	MOV	AR5,#DATA_RXBUF+5+4+1
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#09
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#5+4+1+9
	CALL	_FUN_CARDAPP_InnerCardChannel
	
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_8803OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_8803OK:		
	
	;EF01 文件的更新
	;XDATA_HOLD[0~3]	RAND
	;XDATA_HOLD[4~7]	MAC
	;XDATA_TXBUF[0~8]	0019 文件中的日期
	;“ 04 D6 81 12 0D ” + 0019 文件中的日期	 +　MAC
	MOV	DPTR,#STR_CARDAPP_D68103
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#09H
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	AR5,#DATA_RXBUF + 5 + 09H
	MOV	R7,#XDATA_HOLD + 4
	MOV	R3,#04
	CALL	_FUN_LIB_XDATATODATA
		
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7+4
	MOV	R3,#5H+09H+4H
	CALL	_FUN_CARDAPP_InnerCardChannel	
	MOV	A,R7
	;---JZ	CARDAPP_GDFXOBU_UpdataEF01OK
	JZ	CARDAPP_GDFXOBU_UpdateOBUID
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
	;=== 回写OBUID，回写导入次数 ===
CARDAPP_GDFXOBU_UpdateOBUID:
	
	;读取导入卡 0019 合同序号
	;XDATA_txbuf[0~12] 0019文件
	;XDATA_txbuf[13~13+12] 0019文件 车牌
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#99h							;R4		---	文件ID
	MOV	R3,#00							;R3		---	长度
	MOV	R2,#13+12						;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	JZ	CARDAPP_GDFXOBU_Read001902OK
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err

CARDAPP_GDFXOBU_Read001902OK:	
	;写车牌到flash
	;MOV	DPH,#CONST_FLASH_SysHVH
	;MOV	DPL,#CONST_FLASH_SysHVL
	;MOV	R3,#1
	;CALL	_eraseflash
	
	;MOV	DPH,#CONST_FLASH_SysHVH
	;MOV	DPL,#CONST_FLASH_SysHVL
	;MOV	R7,#XDATA_TXBUF+13
	;MOV	R3,#12
	;CALL	_wrflashXR

	MOV	R7,#XDATA_TXBUF
	MOV	R5,#DATA_OBUID
	MOV	R3,#4
	CALL	_FUN_LIB_DATATOXDATA
		
	MOV	R0,#XDATA_TXBUF+12
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0FFH
	JNZ	CARDAPP_GDFXOBU_Read001902COUNT
	;MOV	R7,#CONST_STATE_InputFail
	;JMP	CARDAPP_GDFXOBU_Err
	JMP	CARDAPP_GDFXOBU_UpdataEF01OK
CARDAPP_GDFXOBU_Read001902COUNT:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;---INC	A
	DEC	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;更新0019
	;写用户卡 32 byte 5~56
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#13
	CALL	_FUN_LIB_XDATATODATA
	MOV	R4,#00
	MOV	R3,#00	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#13
	CALL	_FUN_CARDAPP_UpdateBinary
	MOV	A,R7
	JZ	CARDAPP_GDFXOBU_UpdataEF01OK	
	MOV	R7,#CONST_STATE_InputFail
	JMP	CARDAPP_GDFXOBU_Err
	
CARDAPP_GDFXOBU_UpdataEF01OK:
	
	MOV	R7,#CONST_STATE_TRUE
	
	RET
;--------------------------------------------------------------------------
CARDAPP_GDFXOBU_Err:
	
	RET
;--------------------------------------------------------------------------
;广东激活卡流程
;返回值
;	01 表示导入卡失效
;--------------------------------------------------------------------------
_FUN_CARDAPP_ACTIVEOBU:	
	
	;=== 选择导入卡的1001目录 ===
	; BIT_ESAMICC=1表示用户卡;=0表示ESAM
;	CLR	BIT_GETRESULT
;	SETB	BIT_ESAMICC
;	MOV	R7,#DATA_RXBUF
;	MOV	R5,#XDATA_TXBUF
;	MOV	R3,#010H
;	MOV	R2,#001H
;	CALL	_FUN_CARDAPP_SelectFile
;	MOV	A,R7
;	JZ	CARDAPP_ACTIVEOBU_Sel1001OK
;	JMP	CARDAPP_ACTIVEOBU_Err
	
;CARDAPP_ACTIVEOBU_Sel1001OK:		
	;读取导入卡 0015 文件，判断是否为导入卡0E[第9个字节，下标由1开始]
;	SETB	BIT_ESAMICC						;当前对用户卡操作
;	SETB	BIT_GETRESULT	
;	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
;;	MOV	R5,#XDATA_HOLD
;	MOV	R4,#95h							;R4		---	文件ID
;	MOV	R3,#08							;R3		---	长度
;	MOV	R2,#01
;	CALL	_FUN_CARDAPP_ReadBinary02
;	MOV	A,R7
;	JZ	CARDAPP_ACTIVEOBU_Read0015OK
;	JMP	CARDAPP_ACTIVEOBU_Err
	
;CARDAPP_ACTIVEOBU_Read0015OK:	
;	MOV	R0,#XDATA_HOLD
;		;MOVX	A,@R0

;	XRL	A,#0EH
;	JZ	CARDAPP_ACTIVEOBU_DRCard
;	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_DRCard:
	;选择 ESAM 的 MF 目录,只进行到61
	CLR	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_ReadSel3f00OK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_ReadSel3f00OK:
	;==============================
	;读取 OBU 合同序号
	;XDATA_HOLD[0~7] ESAM 合同序号
	;==============================
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD
	MOV	R4,#81h							;R4		---	文件ID
	MOV	R3,#0ah							;R3		---	长度
	MOV	R2,#08
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_ReadESAMHTHOK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
CARDAPP_ACTIVEOBU_ReadESAMHTHOK:	
	;读取导入卡 001A 合同序号,共20条记录
	;XDATA_HOLD[0~7] ESAM 合同序号
	;XDATA_txbuf[0~1A] 001a文件
	;STR_CARDAPP_RX001A = 000H,0B2H,001H,0D4H,1AH
	MOV	R2,#14H
CARDAPP_ACTIVEOBU_RX001A:
	
	MOV	DPTR,#STR_CARDAPP_RX001A
	MOV	R7,#DATA_RXBUF
	PUSH	AR2
	CALL	_FUN_LIB_FLASHTODATA
	POP	AR2	
	
	;当前读记录号
	MOV	R0,#DATA_RXBUF+2
	MOV	A,R2
	MOV	@R0,A
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_txbuf
	PUSH	AR2
	CALL	_FUN_CARDAPP_InnerCardChannel
	POP	AR2
	
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_Read001AOK	
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_Read001AOK:
	;比较 合同号 是否相同
	MOV	r1,#xdata_txbuf+5
	MOV	r0,#xdata_HOLD
	MOV	R3,#8
CARDAPP_ACTIVEOBU_COMP:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R0
;	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,B
	JZ	CARDAPP_ACTIVEOBU_NoErZZ
	DJNZ	R2,CARDAPP_ACTIVEOBU_RX001A
	MOV	R7,#CONST_STATE_IllegalACTCard
	
	JMP	CARDAPP_ACTIVEOBU_Err
CARDAPP_ACTIVEOBU_NoErZZ:
	INC	R1
	INC	R0
	DJNZ	R3,CARDAPP_ACTIVEOBU_COMP
	
CARDAPP_ACTIVEOBU_COMPOV:
	;MOV	A,R2
	;CALL	_FUN_TEST_DISPLAY
	
	;XDATA_HOLD[11] 	记录号
	;XDATA_HOLD[0~7] 	ESAM 合同序号
	;XDATA_TXBUF[0~1A] 	001A文件
	MOV	R1,#xdata_txbuf+4
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	XRL	A,#0FFH
	JNZ	CARDAPP_ACTIVEOBU_Valid
	MOV	R7,#CONST_STATE_ACTCardInvalid
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_Valid:
	
	;~~~~~~~~~~~~~
	;记录次数
	MOV	R0,#XDATA_HOLD+13
	MOV	A,R2
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;~~~~~~~~~~~~~	
	;获取 ESAM 随机数
	;XDATA_HOLD[0~3] ESAM  rand
	;XDATA_HOLD[13] 记录号	
	;XDATA_txbuf[0~1A] 001a文件
	MOV	DPTR,#STR_CARDAPP_Rand
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_GetESAMRandOK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_GetESAMRandOK:
	;~~~~~~~~~~~~~
	;MOV	R0,#XDATA_HOLD+11
	;	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~	
	;将4字节随机数与“04D6811A”（16进制数，4字节）进行异域
	;XDATA_HOLD[0~3]   RAND
	;XDATA_HOLD[11] 记录号	
	;XDATA_txbuf[0~1A] 001a文件
	MOV	R7,#XDATA_HOLD
	MOV	R5,#XDATA_HOLD+4
	MOV	R3,#4
	MOV	DPtr,#STR_CARDAPP_xor04d6811A
	CALL	_FUN_CARDAPP_xxDATAFlashXOR
	
	;获得 0015 文件中的车辆信息
	;XDATA_HOLD[0~3]	ESAM DF01 随机数
	;XDATA_HOLD[4~6]	PIN
	;XDATA_HOLD[11] 	记录号	
	;XDATA_txbuf[0~1A] 001a文件
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD+4
	MOV	R4,#95h							;R4		---	文件ID
	MOV	R3,#00EH						;R3		---	长度
	MOV	R2,#06H
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_Read0015CardNoOK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_Read0015CardNoOK:
	;mov	a,#34
	;call	_fun_test_display
	;XDATA_HOLD[0~3]	ESAM DF01 随机数	
	;XDATA_HOLD[4~6]	PIN			
	;XDATA_HOLD[11] 	记录号			
	;XDATA_txbuf[0~14] 	001A 文件
	;倒一下
	MOV	R0,#XDATA_HOLD + 4 + 3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
	;call	_fun_test_display
	
	MOV	R0,#XDATA_HOLD + 4 + 5
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	MOV	R0,#XDATA_HOLD + 4 + 3
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R0,#XDATA_HOLD + 4 + 5
	MOV	A,B
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R7,#XDATA_HOLD + 4
	MOV	R5,#XDATA_HOLD + 4 + 3
	MOV	R3,#3
	CALL	_FUN_CARDAPP_xxDATAXOR	
			
	;MOV	R7,#XDATA_HOLD + 4	
	;MOV	R5,#XDATA_HOLD + 4 + 3	
	;MOV	R3,#03			
	;CALL	_FUN_CARDAPP_XXDATAXOR
	
	;XDATA_HOLD[0~3]	ESAM DF01 随 机 数	
	;XDATA_HOLD[4~6]	PIN			
	;XDATA_HOLD[11] 	记录号			
	;XDATA_TXBUF[0~14] 	001A 文件		
	MOV	R7,#XDATA_HOLD+4			
	MOV	R5,#XDATA_HOLD+4+3			
	MOV	R3,#03					
	MOV	DPTR,#STR_CARDAPP_xor3e267a		
	CALL	_FUN_CARDAPP_xxDATAFLASHXOR		
	
	;PIN 认证 '0020000003' + strPIN
	MOV	DPTR,#STR_CARDAPP_PIN
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_HOLD + 4
	MOV	R3,#3
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7
	
	MOV	R3,#5+3
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_PINOK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_PINOK:
	;mov	a,#35
	;call	_fun_test_display
	;MOV	R7,#CONST_STATE_TRUE
	;RET
	
	;内部 认证 计算MAC01
	;XDATA_HOLD[0~3]	ESAM 随机数
	;XDATA_HOLD[4~6]	PIN
	;XDATA_HOLD[7~10]	MAC
	;XDATA_HOLD[11] 	记录号	
	;XDATA_txbuf[0~14] 	001A文件	
	;00 88 02 + 密钥标识[1 BYTE] + 06H + RAND + 05H + OBU状态[1 BYTE]
	MOV	DPTR,#STR_CARDAPP_88_04
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	;密钥标识[1 BYTE]
	MOV	R0,#DATA_RXBUF + 3
	MOV	R1,#XDATA_txbuf + 14
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	
	;COPY RAND
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_HOLD
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R0,#DATA_RXBUF+5+4
	MOV	A,#05H
	MOV	@R0,A
	
	MOV	R0,#DATA_RXBUF+5+4+1
	MOV	R1,#XDATA_TXBUF+13
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7
	MOV	R3,#5H+4H+1H+1H
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_88OK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_88OK:

	;MOV	R7,#CONST_STATE_TRUE
	;RET
	;更新 EF01 文件
	;XDATA_HOLD[0~3]	ESAM 随机数
	;XDATA_HOLD[4~6]	PIN
	;XDATA_HOLD[7~10]	MAC
	;XDATA_HOLD[11] 	记录号	
	;XDATA_txbuf[0~14] 	001A文件
	;04 D6 81 1A 05 + OBU状态[1 BYTE] + MAC
	MOV	DPTR,#STR_CARDAPP_D68104
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R1,#XDATA_TXBUF+13
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	
	MOV	AR5,#DATA_RXBUF + 5 + 1
	MOV	R7,#XDATA_HOLD + 7
	MOV	R3,#04
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+7+4
	MOV	R3,#5+1+4
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_WR001A
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
	;回写 001A OBUID 和激活次数
CARDAPP_ACTIVEOBU_WR001A:
	
	;---读出激活卡中 OBUID 和激活次数
	MOV	DPTR,#STR_CARDAPP_RX001A
	MOV	R7,#DATA_RXBUF
	PUSH	AR2
	CALL	_FUN_LIB_FLASHTODATA
	POP	AR2
	
	;当前 读 记录号
	MOV	R0,#DATA_RXBUF+2
	MOV	R1,#XDATA_HOLD+13
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	
	;MOV	A,R2
	;MOV	A,#30
	;CALL	_FUN_TEST_DISPLAY
	
	MOV	@R0,A
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_txbuf
	;PUSH	AR2
	CALL	_FUN_CARDAPP_InnerCardChannel
	;POP	AR2
	MOV	A,R7
	JZ	CARDAPP_ACTIVEOBU_Read001A02OK
	
	;MOV	A,#31
	;CALL	_FUN_TEST_DISPLAY
	
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err
	
CARDAPP_ACTIVEOBU_Read001A02OK:
	
	;MOV	A,#40
	;CALL	_fun_test_display
	
	MOV	R7,#XDATA_TXBUF
	MOV	R5,#DATA_OBUID
	MOV	R3,#4
	CALL	_FUN_LIB_DATATOXDATA
	
	MOV	R0,#XDATA_TXBUF+4
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;CALL	_fun_test_display
	XRL	A,#0FFH
	;CALL	_fun_test_display
	JNZ	CARDAPP_ACTIVEOBU_Read001902COUNT
	;MOV	R7,#CONST_STATE_InputFail
	;JMP	CARDAPP_GDFXOBU_Err
	JMP	CARDAPP_ACTIVEOBU_D681OK
CARDAPP_ACTIVEOBU_Read001902COUNT:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;---INC	A
	DEC	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;MOV	A,#41
	;CALL	_fun_test_display	
	
	;回写数据
	MOV	DPTR,#STR_CARDAPP_WX001A
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
	
	MOV	R0,#DATA_RXBUF+2
	MOV	R1,#XDATA_hold+13
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	
	;CALL	_fun_test_display
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_txbuf
	MOV	R3,#26
	CALL	_FUN_LIB_XDATATODATA
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_txbuf
	;MOV	R3,#26+5
	MOV	R3,#40+5
	CALL	_FUN_CARDAPP_InnerCardChannel
	MOV	A,R7
	;CALL	_FUN_TEST_DISPLAY
	JZ	CARDAPP_ACTIVEOBU_D681OK
	MOV	R7,#CONST_STATE_ActiveFail
	JMP	CARDAPP_ACTIVEOBU_Err	
	
CARDAPP_ACTIVEOBU_D681OK:
	MOV	R7,#CONST_STATE_TRUE
	RET
	
CARDAPP_ACTIVEOBU_Err:
	RET	
;--------------------------------------------------------------------------
;外存异或
;	外存1		R7
;	外存2		R5
;	外存长度	R3
;返回值
;	返回值放入到R7中
;--------------------------------------------------------------------------
_FUN_CARDAPP_xXDATAXOR:
	
	MOV	AR0,AR7
	MOV	AR1,AR5
CARDAPP_xxDATAXOR_LOOP:
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
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R1
	INC	R0
	DJNZ	R3,CARDAPP_xxDATAXOR_LOOP
	
	RET
;--------------------------------------------------------------------------
;外存异或
;	flash		dptr
;	外存1		R7
;	外存2		R5
;	外存长度	R3
;返回值
;	返回值放入到 R7 中
;--------------------------------------------------------------------------
_FUN_CARDAPP_xXDATAFlashXOR:
	
	;将外存数据 Copy R5
	;MOV	DPTR,#STR_CARDAPP_8802
	;MOV	R7,#DATA_RXBUF
	PUSH	AR7
	PUSH	AR3
	PUSH	AR5
	MOV	AR7,AR5
	CALL	_FUN_LIB_FLASHTOXDATA
	POP	AR5
	POP	AR3
	POP	AR7
	
	CALL	_FUN_CARDAPP_xxDATAXOR
	
	RET
;--------------------------------------------------------------------------	


	
	
	END
