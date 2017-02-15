;******************************************************************
;描述：ESAM接触式发行
;_FUN_ContactIssue_INIT		---	发行初始化
;_FUN_ContactIssue_RXBST	---	发行_接收BST
;_FUN_ContactIssue_RX		---	接收发行信息（从PC）
;_FUN_ContactIssue_TX		---	发送发行回应信息（到PC）
;******************************************************************
NAME	ContactIssue
	
$INCLUDE(COMMON.INC)
$INCLUDE(C_Issue.INC)
	
	RSEG	?pr?ContactIssue?Mater
	USING	0
	
;--------------------------------------------------------------------------
;描述:发行初始化 串口2 115200
;外部参数
;--------------------------------------------------------------------------
_FUN_ContactIssue_INIT:
	
	;LCALL	_FUN_SERIAL_InitUART
	CALL	_FUN_SERIAL_INIT
	;MOV	IE2,#0
	;CLR	ET0
	;CLR	ET1
	MOV	R7,#CONST_BAUD_115200PC
	;MOV	R7,#CONST_BAUD_9600PC
	CALL	_FUN_Contact_CHANGEBAUD		;在 24.576 下设成 115200 的波特率
	
	MOV	SCON,#40H			;设成不需要检验位
	MOV	A,REG_51_AUXR1
	ORL	A,#10000000B
	;ANL	A,#01111111B
	MOV	REG_51_AUXR1,A
	
	RET
;--------------------------------------------------------------------------
;描述:发行释放 串口01 115200*6.144/3.58
;外部参数
;--------------------------------------------------------------------------	
_FUN_ContactIssue_Release:
	
	MOV	R7,#CONST_BAUD_115200
	CALL	_FUN_Contact_CHANGEBAUD		;在 24.576 下设成  115200 * 6 / 3.58 的波特率	
	MOV	SCON,#0C0H			;设成需要检验位
	
	MOV	A,REG_51_AUXR1
	;ORL	A,#10000000B
	ANL	A,#01111111B
	MOV	REG_51_AUXR1,A
	
	RET
;--------------------------------------------------------------------------
;描述:发行初始化  串口01 115200
;外部参数
;--------------------------------------------------------------------------
_FUN_ContactIssue_INIT02:
	
	CALL	_FUN_SERIAL_INIT
	MOV	R7,#CONST_BAUD_115200PC
	CALL	_FUN_Contact_CHANGEBAUD		;在 24.576 下设成  115200 * 6 / 3.58 的波特率	
	MOV	SCON,#40H			;设成不需要检验位
	
	MOV	A,REG_51_AUXR1
	;ORL	A,#10000000B
	ANL	A,#01111111B
	MOV	REG_51_AUXR1,A
	
	RET
;--------------------------------------------------------------------------
;	
;--------------------------------------------------------------------------
_FUN_ContactIssue_INITDown:
	
	CALL	_FUN_SERIAL_INIT
	
	MOV	R7,#CONST_BAUD_38400PC
	CALL	_FUN_Contact_CHANGEBAUD		;在 24.576 下设成  115200 * 6 / 3.58 的波特率	
	MOV	SCON,#40H			;设成不需要检验位
	
	MOV	A,REG_51_AUXR1
	;ORL	A,#10000000B
	
	ANL	A,#01111111B
	MOV	REG_51_AUXR1,A
	
	RET
;--------------------------------------------------------------------------
;描述:发行_接收 BST 
;外部参数
;	XXX
;返回值
;	BIT_ContactIssue	---	发行开始标记=0，没有接收发行信息，接收到发行信息
;	R3			---	接收到BST的长度
;	R7			---	接收状态
;--------------------------------------------------------------------------	
_FUN_ContactIssue_RXBST:
	
	SETB	BIT_SERIALOVERTIMERX
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_ContactIssue_RX
	MOV	A,R3
	JNZ	ContactIssue_RXBST_RXED
	JMP	ContactIssue_RXBST_ERR
	
ContactIssue_RXBST_RXED:
	
	;判断BST前4个字节是否是BST，如果，是，则设定发行开始标记
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	ContactIssue_RXBST_ERR
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH	
	JNZ	ContactIssue_RXBST_ERR
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	ContactIssue_RXBST_ERR
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH	
	JNZ	ContactIssue_RXBST_ERR

	;SETB	BIT_ContactIssue
		
	RET
	
ContactIssue_RXBST_ERR:
	MOV	R3,#0
	MOV	R7,#CONST_STATE_FALSE
	RET
;--------------------------------------------------------------------------
;描述:接收发行信息（从PC）
;外部参数
;	BIT_BST			---	;=1表示收到过bst,=0表示没有收到过bst	(=0时，在命令字后会多1 Byte 的状态码)
;	BIT_SERIALOVERTIMERX	---	=0,没有限制 ; =1有时间限制
;	R7			---	接收指针（内存）
;返回值
;	R3			---	接收数据长度
;	R7			---	接收状态
;	AR5			---	数据头
;	XDATA_IssueRSCTL	---	有线发行序号
;	XDATA_IssueCMD		---	有线发行命令字

;STX(2) + RSCTL(1) + LEN(2) + CMD(1)+State(1 byte bit_bst=1时才有) + DATA(XX)+ BCC(1)
;--------------------------------------------------------------------------	
_FUN_ContactIssue_RX:
	
	CLR	BIT_BUFADDR		;= 0，接收数据到内存； = 1，接收数据到外存
	CLR	BIT_VERIFY		;串口收发是否要加验位,=0不要，=1要
	
	MOV	R3,#000H
	PUSH	AR7
	CALL	_FUN_SERIAL_RXHARD
	POP	AR7
	MOV	A,R3
		
	;~~~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	CJNE	A,#7,$+3			;STX(2) + RSCTL(1) + LEN(2) + CMD(1) DATA(XX)+ BCC(1) >= 7 BYTE
	;JNC	ContactIssue_RX_VerifyBCC
	JNC	ContactIssue_RX_VerifyHead
	JMP	ContactIssue_RX_ERR
	
ContactIssue_RX_VerifyHead:
	;扫描0x55 0xAA
	;PUSH	AR3
	;PUSH	AR7
	mov	AR0,AR7
ContactIssue_RX_VerifyHeadloop:
	MOV	A,@R0
	XRL	A,#055H
	JZ	ContactIssue_RX_VerifyHeadloop02
	INC	R0
	DJNZ	R3,ContactIssue_RX_VerifyHeadloop
	
ContactIssue_RX_VerifyHeadloop02:
	MOV	A,@R0
	XRL	A,#0AAH
	JZ	ContactIssue_RX_VerifyBCC
	INC	R0
	DJNZ	R3,ContactIssue_RX_VerifyHeadloop02
	;pop	ar7
	;pop	ar3	
	JMP	ContactIssue_RX_ERR
	
ContactIssue_RX_VerifyBCC:			;验证BCC
	
	DEC	R3
	INC	R0
	MOV	AR0,AR7
	;DEC	R0
	
	;--- 验证 BCC 是否正确 ---
	PUSH	AR3
	PUSH	AR7
	
	;---DEC	R3
	;---DEC	R3
	;---INC	R7
	;---INC	R7
	
	CLR	BIT_BUFADDR
	CALL	_FUN_LIB_GetBCC
	POP	AR7
	POP	AR3
	
	;~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R6
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	JZ	ContactIssue_RX_GetData
	JMP	ContactIssue_RX_ERR	; 验证BCC出错，返回
ContactIssue_RX_GetData:		; 只留数据，其它清除

	MOV	AR1,AR7			; HEAD 0 55	
	INC	R1			; HEAD 1 AA
	INC	R1			; RSCTL
	
	;记录序号
	MOV	A,@R1
	MOV	R0,#XDATA_IssueRSCTL
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1			; LEN 0
	INC	R1			; LEN 1
	INC	R1			; CMD
	
	;记录命令字
	MOV	A,@R1
	MOV	R0,#XDATA_IssueCMD
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	AR5,AR7
		
;	MOV	R2,#7
;	JNB	BIT_BST,ContactIssue_RX_Broad01
;ContactIssue_RX_NBroad01:
;	INC	R1			; State
;	INC	R2			; 7+1 加上状态码的长度
;ContactIssue_RX_Broad01:		; 
;	INC	R1			; DATA 0	
;	CLR	C
;ContactIssue_RX_Broad01Over:
;	MOV	A,R3
;	SUBB	A,R2
;	MOV	R3,A

	;~~~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;将Data前移,去除STX(2) / RSCTL(1) / LEN(2) / CMD(1) / BCC(1)
;	MOV	AR2,AR3
;	MOV	AR0,AR7			;HEAD 0
;ContactIssue_RX_PREMOV:
;	MOV	A,@R1
;	MOV	@R0,A
	
;	INC	R1
;	INC	R0
	
;	DJNZ	R2,ContactIssue_RX_PREMOV
	MOV	R7,#CONST_STATE_TRUE
ContactIssue_RX_OVER:
	RET	
;////////////////////////////////////////////////////////////////////////////
ContactIssue_RX_ERR:			;接收发行信息出错	
	MOV	R7,#CONST_STATE_FALSE	
	
	RET	
;////////////////////////////////////////////////////////////////////////////	
_FUN_ContactIssue_RX03:
	;CLR	BIT_BUFADDR		;= 0，接收数据到内存； = 1，接收数据到外存
	;CLR	BIT_VERIFY		;串口收发是否要加验位,=0不要，=1要	
	MOV	R3,#000H		;
	PUSH	AR7			;
	CALL	_FUN_SERIAL_RXHARD	;
	POP	AR7			;
	MOV	A,R3			;
	JMP	ContactIssue_RX02_RXO	;
	
;////////////////////////////////////////////////////////////////////////////
_FUN_ContactIssue_RX02:	
	;CLR	BIT_BUFADDR		;= 0，接收数据到内存； = 1，接收数据到外存
	;CLR	BIT_VERIFY		;串口收发是否要加验位,=0不要，=1要
	
	MOV	R3,#000H
	PUSH	AR7
	CALL	_FUN_SERIAL_RXHARD
	POP	AR7
	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;描述
;	验证接收数据
;参数
;	R7		数据绶冲
;	BIT_BUFADDR 	=1外存 =0 内存
;返回值
;	R5	数据域[去除 55aaserlen0len1cmd xxx bcc]，绶冲头在R5上
;	R3	表数据长度
;	R7=0	表数据正确
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ContactIssue_RX02_Deal:
	
	MOV	A,R3
	
ContactIssue_RX02_RXO:
	
	;~~~~~~~~~~~~TEST~~~~~~~~
	;MOV	R7,#0
	;JMP	ContactIssue_RX02_OVER
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	CJNE	A,#7,$+3			;STX(2) + RSCTL(1) + LEN(2) + CMD(1) DATA(XX)+ BCC(1) >= 7 BYTE
	;JNC	ContactIssue_RX02_VerifyBCC
	JNC	ContactIssue_RX02_VerifyHead
	JMP	ContactIssue_RX02_ERR
	
ContactIssue_RX02_VerifyHead:
	
	;扫描0x55 0xAA
	;PUSH	AR3
	;PUSH	AR7
	
	MOV	AR0,AR7
ContactIssue_RX02_VerifyHeadloop:
	JB	BIT_BUFADDR,ContactIssue_RX02_55X
	MOV	A,@R0
	JMP	ContactIssue_RX02_55O
ContactIssue_RX02_55X:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
ContactIssue_RX02_55O:
	
	XRL	A,#055H
	JZ	ContactIssue_RX02_VerifyHeadloop02P
	INC	R0
	DJNZ	R3,ContactIssue_RX02_VerifyHeadloop
	
	JMP	ContactIssue_RX02_ERR
	
ContactIssue_RX02_VerifyHeadloop02P:
	INC	R0
	DEC	R3
	
ContactIssue_RX02_VerifyHeadloop02:
	JB	BIT_BUFADDR,ContactIssue_RX02_AAX
	MOV	A,@R0
	JMP	ContactIssue_RX02_AAO
ContactIssue_RX02_AAX:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
ContactIssue_RX02_AAO:
	
	XRL	A,#0AAH
	JZ	ContactIssue_RX02_VerifyBCC
	
	INC	R0
	DEC	R3
	
	MOV	A,R3
	JNZ	ContactIssue_RX02_VerifyHeadloop
	
	JMP	ContactIssue_RX02_ERR
	
	
ContactIssue_RX02_VerifyBCC:			;验证BCC
	
	;~~~~~~~~~~~~TEST~~~~~~~~
	;MOV	R7,#0
	;JMP	ContactIssue_RX02_OVER
	;MOV	A,R3
	;MOV	A,#37
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	DEC	R3
	INC	R0
	
	;MOV	AR0,AR7
	MOV	AR7,AR0
	;DEC	R0
	
	;--- 验证 BCC 是否正确 ---
	PUSH	AR3
	PUSH	AR7
	
	;---DEC	R3
	;---DEC	R3
	;---INC	R7
	;---INC	R7
	
	;~~~~~~~~~~ TEST ~~~~~~~~
	;MOV	A,R6
	;	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR
	
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	;CLR	BIT_BUFADDR
	CALL	_FUN_LIB_GetBCC
	POP	AR7
	POP	AR3
	
	;~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R6
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	;~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R6
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	JZ	ContactIssue_RX02_GetData
	JMP	ContactIssue_RX02_ERR	; 验证BCC出错，返回
	
ContactIssue_RX02_GetData:		; 只留数据，其它清除

	;~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R6
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY	
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	MOV	AR1,AR7			; RSCTL
	JB	BIT_BUFADDR,ContactIssue_RX02_RecordX
	
ContactIssue_RX02_Record:
	;记录序号
	MOV	A,@R1
	MOV	R0,#XDATA_IssueRSCTL
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1			; LEN 0
	INC	R1			; LEN 1
	INC	R1			; CMD
	
	;记录命令字
	MOV	A,@R1
	MOV	R0,#XDATA_IssueCMD
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JMP	ContactIssue_RX02_RecordOver
	
ContactIssue_RX02_RecordX:
	
	;记录序号
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	R0,#XDATA_IssueRSCTL
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R1			; LEN 0
	INC	R1			; LEN 1
	INC	R1			; CMD
	
	;记录命令字
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	R0,#XDATA_IssueCMD
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;~~~~~~~~~~ TEST ~~~~~~~~
	; MOV	A,R3
	; JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
ContactIssue_RX02_RecordOver:
	
	;~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R6
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	INC	R7
	INC	R7
	INC	R7
	INC	R7
	
	DEC	R3
	DEC	R3
	DEC	R3
	DEC	R3
	DEC	R3	;BCC
	
	MOV	AR5,AR7
	MOV	R7,#CONST_STATE_TRUE
	
ContactIssue_RX02_OVER:
	
	;~~~~~~~~~~TEST~~~~~~~~
	;MOV	A,R6
	;MOV	A,R3
	;MOV	A,R7
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	RET
;////////////////////////////////////////////////////////////////////////////
ContactIssue_RX02_ERR:			;接收发行信息出错	
	MOV	R3,#0
	MOV	R7,#CONST_STATE_FALSE	
	
	RET		
	
	
;--------------------------------------------------------------------------
;描述:发送发行回应信息（到PC）
;外部参数
;	R7			---	发送指针（外存）
;	R3			---	发送数据长度
;	XDATA_IssueRSCTL	---	有线发行序号
;	XDATA_IssueCMD		---	有线发行命令字
;返回值
;	XXX
;--------------------------------------------------------------------------	
_FUN_ContactIssue_TX:
	
	;~~~~~~~~~~~~TEST~~~~~~~~~~~~	
	;JMP	ContactIssue_TX_SEND
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	MOV	A,R3
	JNZ	ContactIssue_TXVerifyParam
	JMP	ContactIssue_TX_Err
ContactIssue_TXVerifyParam:
		
	;将数据后移		
	MOV	A,R7	
	ADD	A,R3
	DEC	A
	MOV	R0,A	;DATA 0
	ADD	A,#6
	MOV	R1,A
	
	MOV	A,R3
	MOV	R2,A
ContactIssue_TX_BACKMOV:			; Data 域后移
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	DEC	R1
	DEC	R0
	
	DJNZ	R2,ContactIssue_TX_BACKMOV
	;~~~~~~~~~~~~TEST~~~~~~~~~~~~	
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	
	;INC	R3
	;INC	R3
	
	;INC	R3
	;INC	R3
	;INC	R3
	;MOV	R3,#10
	;JMP	ContactIssue_TX_SEND
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	
	;将数据加上STX(2) / RSCTL(1) / LEN(2) / CMD(1) / BCC(1)
	MOV	AR0,AR7	
	MOV	A,#055H
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;~~~~~~~~~~~~TEST~~~~~~~~~~~~	
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	INC	R0						;STX 1
	MOV	A,#0AAH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	;~~~~~~~~~~~~TEST~~~~~~~~~~~~	
	;MOV	A,R3
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	INC	R0						;RSCTL
	MOV	R1,#XDATA_IssueRSCTL
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	INC	A						;序号加1
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;~~~~~~~~~~~~TEST~~~~~~~~~~~~	
	;MOV	A,R0
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~		
	
	INC	R0	;LEN 0
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0	;LEN 1
	MOV	A,R3
	;---INC	A	;加上state的长度
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	INC	R0	;CMD
	MOV	R1,#XDATA_IssueCMD
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ANL	A,#0EFH	;
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;INC	R0	;State
	;CLR	A		
	;	;MOVX	@R0,A
	;MOV 	DPH,#1 
	;MOV 	DPL,R0 
	;MOVX 	@DPTR,A
	
	;~~~~~~~~~~~~TEST~~~~~~~~~~
	; MOV	A,R3
	; JMP	_FUN_TEST_DISPLAY
	
	; INC	R3
	; INC	R3
	
	; INC	R3
	; INC	R3
	; INC	R3
	; MOV	R3,#10
	; JMP	ContactIssue_TX_SEND
	;~~~~~~~~~~~~~~~~~~~~~~~~
	
	PUSH	AR7
	;--- 获得BCC ---
	SETB	BIT_BUFADDR
	INC	R7	;HEAD 1
	
	INC	R7	;RSCTL
	MOV	A,R3
	ADD	A,#4	; RSCTL(1) / LEN(2) / CMD(1)
	MOV	R3,A
	PUSH	AR3
	CALL	_FUN_LIB_GetBCC	
	POP	AR3
	POP	AR7	
	;CALL	_FUN_SERIAL_TXHARD
	;RET
	
	;---BCC---
	INC	R3	;加上 head0 head1的长度
	INC	R3
	
	MOV	A,R7
	ADD	A,R3
	MOV	R0,A
	MOV	A,R6
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	INC	R3	;加上BCC的长度
ContactIssue_TX_SEND:
	
	SETB	BIT_BUFADDR
	CLR	BIT_VERIFY
	push	ar3
	CALL	_FUN_SERIAL_TXHARD
	pop	AR3
	MOV	R7,#CONST_STATE_TRUE	
	RET
;///////////////////////////////////////////////////////////////////////////
ContactIssue_TX_Err:	;发送发行信息出错
	MOV	R7,#CONST_STATE_FALSE
	RET
;///////////////////////////////////////////////////////////////////////////


	
	END

