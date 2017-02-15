;******************************************************************
;描述：MF卡片操作扩展程序集
;_FUN_MF_Rc500Auth		---	认证扇区
;_FUN_MF_Rc500Read		---	读块
;_FUN_MF_Rc500Write		---	写块
;_FUN_MF_Rc500Decrement		---	扣款
;_FUN_MF_Rc500Transfer		---	传送
;_FUN_MF_RC500Restore		---	备份块
;_FUN_MF_Channel	---	MF卡认证复合操作

;;函数关系
;	_FUN_MF_Channel 
;		| 
;	_FUN_MF_Rc500Auth-- Err -->返回 XX F1
;		|(OK)
;		|
;		|--->_FUN_MF_Rc500Read -> Err -->返回 00 FF
;		|		|(OK) 
;		|		返回--> 00  00 	[16 Byte数据]
;		|
;		|--->_FUN_MF_Rc500Write -> Err -->返回 01 FF
;		|		|(OK)
;		|		返回--> 01 00
;		|
;		|--->_FUN_MF_Rc500Decrement -> Err--->返回 02 FF 
;		|		|(OK)
;		|		返回--> 02 00
;		|
;		|--->_FUN_MF_Rc500Increment -> Err--->返回 03 FF 
;		|		|(OK)
;		|		返回--> 03 00
;		|
;		|--->_FUN_MF_RC500Restore -> Err--->返回 04 FF 
;				|(OK)
;				返回--> 04 00 

;******************************************************************
NAME	MFCard

$INCLUDE(COMMON.INC)
$INCLUDE(MFCard.INC)

	RSEG	?pr?MFCard?Mater
	USING	0
	
;--------------------------------------------------------------------------
;描述:	认证
;外部参数:
;	R6		---	密钥A/B(0/1)   
;	R4		---	Block number 
;	R5		---	6 byte密钥(内存)
;	DATA_CardNO	---	卡号(内存)
;返回值:
;	R7		--- 	=0 表示执行成功;=ff 表示执行失败
;--------------------------------------------------------------------------	
_FUN_MF_Rc500Auth:

	ret

_Rc500Autherr:
	mov	r7,#0FFh
	ret		
;--------------------------------------------------------------------------
;描述:	读块
;外部参数
;	R4		---	读取块块号
;	R5		---	存放读取数据绶冲指针
;	BIT_BUFADDR	---	返回数据存放在内存，还是外存标识;表示当前操作的存储区,=0内存;=1外存
;返回值:
;	R7		--- 	=0 表示执行成功;=ff 表示执行失败
;--------------------------------------------------------------------------	
;r7: 返回状态,r5:buf of addr , r4;block addr
_FUN_MF_Rc500Read:

	RET

;--------------------------------------------------------------------------
;描述:	写块
;外部参数

;	R4		---	读取块块号
;	R5		---	存放读取数据绶冲指针
;	BIT_BUFADDR	---	写块数据存放在内存，还是外存标识;表示当前操作的存储区,=0内存;=1外存

;内部参数:
;	XXX
;返回值
;	R7		--- 	=0 表示执行成功;=ff 表示执行失败
;--------------------------------------------------------------------------	
;r7 返回状态,r5:buf of addr , r4;block addr
_FUN_MF_Rc500Write:

	RET	
	
;--------------------------------------------------------------------------
;描述:	消费
;外部参数
;	R4		---	消费块块号
;	R5		---	存放金额绶冲指针(内存)
;返回值
;	R7		--- 	=0 表示执行成功;=ff 表示执行失败
;--------------------------------------------------------------------------
;r7: 返回状态,r5:buf of addr, r4;block addr
_FUN_MF_Rc500Decrement:

	
	RET
;--------------------------------------------------------------------------
;描述:	传送
;外部参数
;	R4		---	将要确认执行指令的块号
;返回值:
;	R7		--- 	=0 表示执行成功;=ff 表示执行失败
;--------------------------------------------------------------------------
_FUN_MF_Rc500Transfer:

	ret

;--------------------------------------------------------------------------
;描述:	备份块
;外部参数
;	R4		---	将要备份的块号;	
;返回值
;	R7		--- 	=0 表示执行成功;=ff 表示执行失败
;--------------------------------------------------------------------------
_FUN_MF_RC500Restore:

	RET

;--------------------------------------------------------------------------
;描述:	MF卡认证复合操作
;外部参数
;	R7	---	指令绶冲指针(内存) (指令类型 扇区号   块号     "A"/"B"(41H|42H)   密钥 + UUU
;					读块	指令类型 = 00 ,UUU = 空
;					写块	指令类型 = 01 ,UUU = 16 Byte Data
;					扣款	指令类型 = 02 ,UUU = 4 Byte 金额
;					充值 	指令类型 = 03 ,UUU = 4 Byte 金额
;					备份	指令类型 = 04 ,UUU = 目标块号
;	R5	---	回应绶冲指针(外存)
;					读块	正确返回 00 00 16 Byte	错误返回 00 FF
;					写块	正确返回 01 00 		错误返回 01 FF
;					扣款	正确返回 02 00 		错误返回 02 FF
;					充值 	正确返回 03 00 		错误返回 03 FF
;					备份	正确返回 04 00 		错误返回 04 FF
;返回值
;	R3	---	返回回应绶冲数据长度
;--------------------------------------------------------------------------	
_FUN_MF_Channel:


	MOV	A,#CONST_STATE_FALSE

	MOV	AR0,AR5
	
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

		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	MOV	R3,#2
	JMP	MF_Channel_Over 				; 结束指令
	RET

;-------------------------------------------------------------


;	MOV	AR1,AR7
;	MOV	AR0,AR5

;	MOV	A,@R1						; R1[0] 指令类型
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,R0
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A						; R0[0] 指令类型
;	INC	R0						; R0[1]
		
;MF_Channel_AuthRead:
	
;	MOV	A,R3
;	XRL	A,#03H
;	JNZ	MF_Channel_NeedAuth01
;	JMP	MF_Channel_AUTHOK	;不需要认证，直接跳转	
	
MF_Channel_NeedAuth01:
;	MOV	A,R3
;	XRL	A,#04H
;	JNZ	MF_Channel_NeedAuth02
;	JMP	MF_Channel_AUTHOK	;不需要认证，直接跳转	
		
MF_Channel_NeedAuth02:
;	MOV	A,R3
;	XRL	A,#07H
;	JNZ	MF_Channel_NeedAuth03
;	JMP	MF_Channel_AUTHOK	;不需要认证，直接跳转	
MF_Channel_NeedAuth03:
;	MOV	A,R3
;	XRL	A,#13H
;	JNZ	MF_Channel_NeedAuth04
	
;	JMP	MF_Channel_AUTHOK	;不需要认证，直接跳转
MF_Channel_NeedAuth04:			;需要认证
			
			
			
			
			
;	PUSH	AR0
;	PUSH	AR1
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,@R1
	;XRL	A,#2
	;JNZ	MF_Channel_Consume
	;INC	R1
	;INC	R1
	;MOV	A,@R1	
	;CALL	_FUN_TEST_DISPLAY
;MF_Channel_Consume:		
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
;	INC	R1						; R1[1] 扇区号
;	INC	R1						; R1[2] 块号	
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,@R1
;	MOV	A,@R1
;	XRL	A,#9
;	JNZ	MF_Channel_Consume
;;	mov	a,#9
;	dec	r1
;	dec	r1
;	MOV	A,@R1
;	CALL	_FUN_TEST_DISPLAY
;MF_Channel_Consume:	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
;	MOV	A,@R1
;	MOV	R4,A						; 块号

;	INC	R1						; R1[3] 密钥类型
;	MOV	A,@R1
;	ANL	A,#01H						; 0000 0001
;	XRL	A,#01H						; 
;	MOV	R6,A						; 
	
;	INC	R1						; R1[3]	密钥
;	MOV	AR5,AR1						;
	
;	CALL	_FUN_MF_Rc500Auth
;	POP	AR1
;	POP	AR0
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,@R1
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
;	MOV	A,R7
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#35
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;	JZ	MF_Channel_AUTHOK
MF_Channel_AUTHERR:						; 认证失败
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#35
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
;	MOV	A,#CONST_STATE_AUTHER
;		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A	
;;	MOV	R3,#02H						; 返回数据长度=2 
;	JMP	MF_Channel_Over
	
MF_Channel_AUTHOK:						; 认证通过	
;	
;	MOV	A,@R1						; R1[0] 指令类型	
;	INC	R1						; R1[1] 扇区号
;	INC	R1						; R1[2] 块号	
	
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#35
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
;************************************************************************************************
MF_Channel_Read:	; 读块操作
;	CJNE	A,#CONST_MF_READ,MF_Channel_Write	
	
	;R7: 返回状态,R5:BUF Of Addr , R4;Block Addr
;	MOV	A,@R1						; R1[2] 块号
;	MOV	R4,A	 	;
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#36
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;	PUSH	AR0						; R0[1] 指令执行状态
;	INC	R0						; R0[2] 指令附加返回
;	MOV	AR5,AR0						; R0[2]
;	SETB	BIT_BUFADDR					; 将数据存到外存
;;	CALL	_FUN_MF_Rc500Read
;	POP	AR0						; R0[1]指令执行状态
;	MOV	A,R7
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#36
	;INC	R0
	;INC	R0
	;	;MOVX	A,@R0
;	MOV	DPH,#1
;	MOV	DPL,R0
;	MOVX	A,@DPTR
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
;	JNZ	MF_Channel_ReadERR
	
MF_Channel_ReadOK:	; 读块成功
;	MOV	A,#CONST_STATE_TRUE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A						; R0[1] 指令执行状态
	
;	MOV	R3,#18
;	JMP	MF_Channel_Over 				; 结束指令
MF_Channel_ReadERR:	
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#36
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~						; 读块失败
;	MOV	A,#CONST_STATE_FALSE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A
;	MOV	R3,#2
;	JMP	MF_Channel_Over 				; 结束指令
	
MF_Channel_ReadOver:	
;************************************************************************************************		
MF_Channel_Write:	; 写块操作

;	CJNE	A,#CONST_MF_WRITE,MF_Channel_Decrement	
	;R7: 返回状态,r5:buf of addr , r4;block addr
;	MOV	A,@R1						; R1[2] 块号
;	MOV	R4,A	 					;
;	MOV	A,R1
;	ADD	A,#8
;	MOV	R1,A
;	MOV	AR5,AR1
;
;	CLR	BIT_BUFADDR					; 写数据存放在内存中
;	PUSH	AR0						; R0[1] 指令执行状态
;	CALL	_FUN_MF_Rc500Write
;	POP	AR0						; R0[1]指令执行状
;	MOV	A,R7
;	JNZ	MF_Channel_WriteERR
MF_Channel_WriteOK:	; 写块成功
;	MOV	A,#CONST_STATE_TRUE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A						; R0[1] 指令执行状态
	
;	MOV	R3,#2
;	JMP	MF_Channel_Over 				; 结束指令
MF_Channel_WriteERR:
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#37
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~							; 写块失败
;	MOV	A,#CONST_STATE_FALSE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A
;	MOV	R3,#2	
;;	JMP	MF_Channel_Over 				; 结束指令
	
MF_Channel_WriteOver:	

;************************************************************************************************	
MF_Channel_Decrement:	; 扣款操作
;	CJNE	A,#CONST_MF_DECREMENT,MF_Channel_Increment
	;R7: 返回状态,r5:buf of addr , r4;block addr

	
;	MOV	A,@R1						; R1[2] 块号
;	MOV	R4,A	 					;
;	MOV	A,R1
;	ADD	A,#8
;	MOV	R1,A
;	MOV	AR5,AR1


	;如果扣款金额为0，则不做扣款操作
	;PUSH	AR1
;	MOV	A,@R1
;	JNZ	MF_Channel_DecrementVerifyEnd
;
;	INC	R1
;	MOV	A,@R1
;	JNZ	MF_Channel_DecrementVerifyEnd
;
;	INC	R1
;	MOV	A,@R1
;	JNZ	MF_Channel_DecrementVerifyEnd

;	INC	R1
;	MOV	A,@R1
;	JNZ	MF_Channel_DecrementVerifyEnd
;	JMP	MF_Channel_DecrementOK
MF_Channel_DecrementVerifyEnd:	
	;POP	AR1
	


;	CLR	BIT_BUFADDR					; 扣款金额存放在内存中
;	MOV	DATA_CMDTYPE,#CONST_MF_RC500DECREMENT		; 扣款
;	PUSH	AR0						; R0[1] 指令执行状态
;	PUSH	AR4
;	CALL	_FUN_MF_Rc500Decrement
;	POP	AR4
;	POP	AR0						; R0[1]指令执行状

;	MOV	A,R7
;	JNZ	MF_Channel_DecrementERR
	
	;MOV	R4,#10
;	PUSH	AR0
;	CALL	_FUN_MF_Rc500Transfer
;	POP	AR0
;	MOV	A,R7
;	JNZ	MF_Channel_DecrementERR	
	
MF_Channel_DecrementOK:	; 扣款成功

;	MOV	A,#CONST_STATE_TRUE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A						; R0[2] 指令执行状态
	
;	MOV	R3,#2
;	JMP	MF_Channel_Over 				; 结束指令
MF_Channel_DecrementERR:					; 扣款失败
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#38
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;	MOV	A,#CONST_STATE_FALSE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A
;	MOV	R3,#2	
;	JMP	MF_Channel_Over 				; 结束指令
	
MF_Channel_DecrementOver:	
;************************************************************************************************	
MF_Channel_Increment:	; 充值操作	
;	CJNE	A,#CONST_MF_INCREMENT,MF_Channel_Restore
	
	;R7: 返回状态,r5:buf of addr , r4;block addr
;	MOV	A,@R1						; R1[2] 块号
;	MOV	R4,A	 					;
;	MOV	A,R1
;	ADD	A,#8
;	MOV	R1,A
;	MOV	AR5,AR1
	
	
	;如果扣款金额为0，则不做扣款操作
	;PUSH	AR1
;	MOV	A,@R1
;	JNZ	MF_Channel_IncrementVerifyEnd

;	INC	R1
;	MOV	A,@R1
;	JNZ	MF_Channel_IncrementVerifyEnd

;	INC	R1
;	MOV	A,@R1
;	JNZ	MF_Channel_IncrementVerifyEnd

;	INC	R1
;	MOV	A,@R1
;	JNZ	MF_Channel_IncrementVerifyEnd
;	JMP	MF_Channel_IncrementOK
;MF_Channel_IncrementVerifyEnd:	
	;POP	AR1
		
;	CLR	BIT_BUFADDR					; 充值金额存放在内存中
;	MOV	DATA_CMDTYPE,#CONST_MF_RC500Increment		; 充值
;	PUSH	AR0						; R0[1] 指令执行状态
;	PUSH	AR4
;	CALL	_FUN_MF_Rc500Decrement
;	POP	AR4
;	POP	AR0						; R0[1]指令执行状
;	MOV	A,R7
;	JNZ	MF_Channel_IncrementERR
	
;	PUSH	AR0
;	CALL	_FUN_MF_Rc500Transfer
;	POP	AR0
	;MOV	A,R7
	;JNZ	MF_Channel_IncrementERR	
	
MF_Channel_IncrementOK:	; 充值成功
;	MOV	A,#CONST_STATE_TRUE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A						; R0[2] 指令执行状态
	
;	MOV	R3,#2
;	JMP	MF_Channel_Over 				; 结束指令
MF_Channel_IncrementERR:					; 充值失败
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#39
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;	MOV	A,#CONST_STATE_FALSE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A
;	MOV	R3,#2	
;	JMP	MF_Channel_Over 			; 结束指令
	
MF_Channel_IncrementOver:
;************************************************************************************************	
MF_Channel_Restore:	; 备份
;	CJNE	A,#CONST_MF_RESTOR,MF_Channel_Over
	
	;R7: 返回状态,R5:buf of addr , r4;block addr
;	MOV	A,@R1						; R1[2] 块号
;	MOV	R4,A	 					;
;	MOV	A,R1
;	ADD	A,#8
;	MOV	R1,A
;	MOV	A,@R1
;	MOV	R5,A

	;CLR	BIT_BUFADDR					; 写数据存放在内存中
;	PUSH	AR0						; R0[1] 指令执行状态
;	PUSH	AR5
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#36
	;MOV	A,R4
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
;	CALL	_FUN_MF_Rc500Restore
;	POP	AR5
;	POP	AR0						; R0[1]指令执行状
;	MOV	A,R7
;	JNZ	MF_Channel_RestoreERR
;	
;	MOV	AR4,AR5						;备份的目标块号		
;	PUSH	AR0
;	CALL	_FUN_MF_Rc500Transfer
;	POP	AR0
;;	MOV	A,R7
;	
;	JNZ	MF_Channel_RestoreERR		
;	
MF_Channel_RestoreOK:	; 备份成功
;	MOV	A,#CONST_STATE_TRUE
;		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A						; R0[1] 指令执行状态
;	
;	MOV	R3,#2
;	JMP	MF_Channel_Over 				; 结束指令
MF_Channel_RestoreERR:						; 备份失败
	;~~~~~~~~~~~~~~~~调试段~~~~~~~~~~~~
	;MOV	A,#40
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;	MOV	A,#CONST_STATE_FALSE
		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A
;	MOV	R3,#2	
;	JMP	MF_Channel_Over 				; 结束指令
	
MF_Channel_RestoreOver:
;************************************************************************************************	
MF_Channel_Other:	;其它MF指令
;	MOV	A,#CONST_STATE_FALSE
;		;MOVX	@R0,A
;	MOV 	DPH,#1 
;	MOV 	DPL,R0 
;	MOVX 	@DPTR,A
;	MOV	R3,#2	
MF_Channel_OtherOver:
;************************************************************************************************	
MF_Channel_Over:

	RET
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////////		

	END
