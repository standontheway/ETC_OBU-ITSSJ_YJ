NAME	GSM
	
;--------------------------------------------------------------------------
;_FUN_GSM_Insert		插卡处理程序
;_FUN_GSM_GetOffset		根据 CellID 获得相应的偏移量
;_FUN_GSM_RTCDeal		RTC 中断处理
;_FUN_GSM_ETCInputDeal		GSM在ETC入口处理流程
;_FUN_GSM_ETCOnputDeal		GSM在ETC出口处理流程
	
;_FUN_GSM_PlayInputOutput	播放出入口状态
;_FUN_GSM_SerialINTRX		串口中断接收
;_FUN_GSM_ReportMSG		播报短信功能
;_FUN_GSM_LowVotage		低电压报警
	
;_FUN_GSM_RTCCtrl		
;_Fun_GSM_RTCDis		禁用RTC
;_Fun_GSM_RTCEn			开启RTC
;_FUN_GSM_RTCON			开RTC
;_FUN_GSM_RTCOFF		关RTC
;--------------------------------------------------------------------------
$INCLUDE(GSM.INC)
$INCLUDE(COMMON.INC)
	
	RSEG	?pr?GSM?Mater
	USING	0
	
;----------------------------------------------------------
;描述：
;	用户插卡，时GSM相关的处理
;参数	
;	
;流程
;	检查当前出入口状态
;	出口(mtc etc 1,3)
;		1.清 GSM 0020
;		2.清卡片 0020
;		3.禁止 RTC，关 GSM ，关
;	入口(mtc etc 2,4)
;		检查OBU 0020 的入口时间及入口地点与0019是否相同
;			相同
;				检查OBU CellID总数是否相同
;					相同
;						结束流程
;					不同
;						检查卡片上最后一个 CellID 与 obu 对应位置的CelliD是否相同
;							相同
;								写入相差的cellID
;							不相同
;								重新将OBU0020文件中的ID导入到卡片中去
;			不相同
;				1.导入0019的 入口时间及入口地点到OBU  0020
;				2.导入0019的 入口时间及入口地点到卡片 0020
;				3.结束流程
;			
;使用了 DATA_RXBUF XDATA_TXBUF
;前提:	
;	预读的信息是对的


;流程
;读出用户卡前5个数据+unixtime
;读出ESAM卡前5个数据+unixtime
;用户卡 = 出口 结束
;用户卡 = 入口 
;	用户卡时间小于等于ESAM
;		导出ESAM数据到用户卡中
;			更新数据域
;				更新数据域52个byte 5~56
;				更新数据域52个byte 57~108
;			更新前5 0~4
;			更新unixtime 4 109~113
;	用户卡时间大于ESAM
;		ESAM中比用户时间新的记录前移
;			获得前移的第一个记录号，及需要前移的记录数
;			前移数据
;			前移unixtime
;			更新总记录数
;		导出ESAM数据到用户卡中
;----------------------------------------------------------
_FUN_GSM_Insert:
	
	;--- RET 
	JB	BIT_INSERTCARD,GSM_Insert_ReadESAMbaseinfo
	JMP	GSM_Insert_Over
	
	;读出 ESAM 前 5 个数据 unixtime
	;	读出 ESAM 前5个数据
	;	读出ESAM unixtime	
GSM_Insert_ReadESAMbaseinfo:
	
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0DFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#CONST_ESAMCellfile_H
	MOV	R2,#CONST_ESAMCellfile_L
	CALL	_FUN_CARDAPP_SelectFile
	
	;;xdata_hold [0~4] ESAM 前5 0~4
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD
	MOV	R4,#00	
	MOV	R3,#00	
	MOV	R2,#05							;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	;;---jnz	GSM_Insert_Over
	JZ	GSM_Insert_ReadESAMbaseinfo02
	JMP	GSM_Insert_Over
GSM_Insert_ReadESAMbaseinfo02:	
	
	;xdata_hold [5~8] ESAM unixtime  109~113
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_HOLD+5
	MOV	R4,#00						
	MOV	R3,#109						
	MOV	R2,#4;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	;---jnz	GSM_Insert_Over
	JZ	GSM_Insert_ReadUserbaseinfo
	JMP	GSM_Insert_Over
	
	;读出用户卡前5个数据 + unixtime
	;	读出用户卡前5个数据
	;	读出用户卡unixtime
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113
GSM_Insert_ReadUserbaseinfo:
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#010H
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#CONST_Cellfile_H
	MOV	R2,#CONST_Cellfile_L
	CALL	_FUN_CARDAPP_SelectFile
	
	;xdata_hold [9~13] User 前5 0~4
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+9
	MOV	R4,#00
	MOV	R3,#00
	MOV	R2,#05;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	;---jnz	GSM_Insert_Over
	JZ	GSM_Insert_ReadESAMbaseinfo3
	JMP	GSM_Insert_Over
GSM_Insert_ReadESAMbaseinfo3:
	
	;xdata_hold [14~17] User unixtime  109~113	
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_HOLD+14
	MOV	R4,#00
	MOV	R3,#109
	MOV	R2,#4;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	;---jnz	GSM_Insert_Over
	JZ	GSM_Insert_ReadESAMbaseinfo4
	JMP	GSM_Insert_Over
GSM_Insert_ReadESAMbaseinfo4:
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113		
	
	MOV	R0,#xdata_hold+11
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	;---CALL	_FUN_TEST_DISPLAY
	XRL	A,#CONST_Flag_INPUT
	;---JZ	GSM_Insert_Input
	JNZ	GSM_Insert_Output
	JMP	GSM_Insert_Input
	
;用户卡 = 出口 结束
GSM_Insert_Output:
	
	;=== 清 unixtime ===
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113	
	;xdata_hold [29] TMP OFFSET 01
	;xdata_hold [30] TMP OFFSET 02
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R0,#DATA_RXBUF + 5
	MOV	R3,#52
	CLR	A	
Insert_Output_loopclr:
	MOV	@R0,A
	INC	R0
	DJNZ	R3,Insert_Output_loopclr	
	
	MOV	R0,#XDATA_HOLD+30
	MOV	A,#71H
	;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	CLR	A
	DEC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R6,#4
Insert_Output_loop:
	;assign offset H/L into r4 / r3
	MOV	R0,#XDATA_HOLD+29
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A;#0	
	
	MOV	R0,#XDATA_HOLD+30
		;MOVX	A,@R0
	MOV	DPH,#01
	MOV	DPL,R0
	MOVX	A,@DPTR	
	MOV	R3,A;#1
	
	MOV	R2,#52;#1
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	PUSH	AR6
	CALL	_FUN_CARDAPP_UpdateBinary
	POP	AR6
	
	MOV	A,R7	
	JNZ	GSM_Insert_Over
	
	MOV	R0,#XDATA_HOLD+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#52
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	DJNZ	R6,Insert_Output_loop


	;=== 清ESAM前 5 总数 ===
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R0,#DATA_RXBUF + 5
	mov	a,#0
	mov	@r0,a	
	inc	r0
	mov	@r0,a	
	inc	r0
	mov	@r0,a	
	inc	r0
	mov	@r0,a	
	inc	r0
	mov	@r0,a	


	;assign offset H/L into r4 / r3
	MOV	R4,#0	
	MOV	R3,#0
	MOV	R2,#5
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	CALL	_FUN_CARDAPP_UpdateBinary
	MOV	A,R7
	jnz	GSM_Insert_Over


	;=== 清用户卡总数 ===
	SETB	BIT_GETRESULT
	setb	BIT_ESAMICC
	
	MOV	R0,#DATA_RXBUF + 5
	mov	a,#0
	mov	@r0,a
	
	;assign offset H/L into r4 / r3
	MOV	R4,#0	
	MOV	R3,#1
	MOV	R2,#1		
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	CALL	_FUN_CARDAPP_UpdateBinary

	JMP	GSM_Insert_Over

;用户卡 = 入口 
;	用户卡时间小于等于ESAM
;		导出ESAM数据到用户卡中
;			更新数据域
;				更新数据域52个byte 5~56
;				更新数据域52个byte 57~108
;			更新前5 0~4
;			更新unixtime 4 109~113
;	用户卡时间大于ESAM
;		ESAM中比用户时间新的记录前移
;			获得前移的第一个记录号，及需要前移的记录数
;			前移数据
;			前移unixtime
;			更新总记录数
;		导出ESAM数据到用户卡中
	
GSM_Insert_Input:
;用户卡 = 入口 
	
	;比较 unixtime
;	用户卡时间小于等于ESAM
;		导出ESAM数据到用户卡中
;	用户卡时间大于ESAM
;		ESAM中比用户时间新的记录前移
;		导出ESAM数据到用户卡中
	
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113
GSM_Insert_compareunixtime:
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;导出ESAM数据到用户卡中
	;1、写满ESAM 前0~4 /所有记录 5~108 / unixtime 109~112
	;2、清空所有用户卡信息
	;user < esam
	;>= 导出
	;3、检查 0~112 是否相同	
	;CALL	_FUN_GSM_ESAMToUserCard;	r5<=r7 返回 C=1
	;CALL	_FUN_GSM_ESAMQY
	;mov	a,#37
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	r5<=r7 返回 C=1
;	R5>r7 返回C = 0

;	r5<r7 返回 C=1
;	R5>=r7 返回C = 0
	MOV	r5,#xdata_hold+5
	MOV	r7,#xdata_hold+14
	CALL	_fun_GSM_compareunixtime2
	
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;mov	a,#37
	;clr	a
	;mov	acc.0,c	
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	JNC	GSM_Insert_XiaoDunYu
;	用户卡时间大于ESAM
;		ESAM中比用户时间新的记录前移
;			获得前移的第一个记录号，及需要前移的记录数
;			前移数据
;			前移unixtime
;			更新总记录数
;		导出ESAM数据到用户卡中	
GSM_Insert_DaYu:
	CALL	_FUN_GSM_ESAMQY
	;CALL	_FUN_GSM_ESAMToUserCard	
;	用户卡时间小于等于ESAM
;		导出ESAM数据到用户卡中
;			更新数据域
;				更新数据域52个byte 5~56
;				更新数据域52个byte 57~108
;			更新前5 0~4
;			更新unixtime 4 109 ~ 113
GSM_Insert_XiaoDunYu:
	CALL	_FUN_GSM_ESAMToUserCard
GSM_Insert_Over:
	RET
;////////////////////////////////////////////////////////////////
;参数
;	r5	xdata 4 byte
;	r7	xdata 4 byte
;	r5<=r7 返回 C=1
;	R5>r7 返回C = 0
_fun_GSM_compareunixtime:
	
	MOV	AR0,AR5
	MOV	AR1,AR7
	
	;相同，返回C=1
	MOV	R3,#4
GSM_compareunixtime_LOOP1:
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
	JNZ	GSM_compareunixtime_S
	INC	R0
	INC	R1	
	DJNZ	R3,GSM_compareunixtime_LOOP1	
		
	SETB	C
	JMP	GSM_compareunixtime_OVER
	
	;不相同，R5<r7 返回 C=1 ，否则，返回C=0
GSM_compareunixtime_S:
	MOV	AR0,AR5
	MOV	AR1,AR7
	INC	R1
	INC	R0
	INC	R1
	INC	R0
	INC	R1
	INC	R0

	CLR	C
	MOV	R3,#4
GSM_compareunixtime_LOOP2:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	SUBB	A,B

	DEC	R0
	DEC	R1
	DJNZ	R3,GSM_compareunixtime_LOOP2
	
	JC	GSM_compareunixtime_OVER
	
GSM_compareunixtime_OVER:
	
	RET
;--------------------------------------------------------------------------
;参数
;	r5	xdata 4 byte
;	r7	xdata 4 byte
;	r5<r7 返回 C=1
;	R5>=r7 返回C = 0
;--------------------------------------------------------------------------
_fun_GSM_compareunixtime2:
		
	;R5<r7 返回 C=1 ，否则，返回C=0
GSM_compareunixtime2_S:
	MOV	AR0,AR5
	MOV	AR1,AR7
	INC	R1
	INC	R0
	INC	R1
	INC	R0
	INC	R1
	INC	R0

	CLR	C
	MOV	R3,#4
GSM_compareunixtime2_LOOP2:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	B,A
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	SUBB	A,B
	
	DEC	R0
	DEC	R1
	DJNZ	R3,GSM_compareunixtime2_LOOP2
		
	;JC	GSM_compareunixtime2_OVER	
GSM_compareunixtime2_OVER:

	RET
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;描述
;	获得前移的第一个记录号，及需要前移的记录数
;前提
;	1.已具备操作ESAM usercard的条件，如打开外围，卡片已复位成功
;	2.已选择ESAM df01 ef07 及 usercard 1001 0009 文件
;参数
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113	
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数	
	;xdata_hold [26] unixtime 偏移量 01 lingshi
	;xdata_hold [27] unixtime 偏移量 02 
	;xdata_hold [28] unixtime总长度
;返回值：
;	R7=第一个记录号,R5=需要前移的记录数
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_FUN_GSM_GETRecordCode:
	
	;unixtime 偏移量 01 / 02
	MOV	R0,#xdata_hold + 26
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#113
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;unixtime总长度
	MOV	R0,#xdata_hold + 28
	MOV	R1,#xdata_hold + 1
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	;---JZ	GSM_GETRecordCode_ER
	JNZ	GSM_GETRecordCode_RVLOOPPre
	JMP	GSM_GETRecordCode_ER
GSM_GETRecordCode_RVLOOPPre:
	MOV	B,A	
	MOV	A,#4
	MUL	AB
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R6,#1
GSM_GETRecordCode_RVLOOP:
	
	;=== 读出ESAM Unixtime===
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	
	MOV	R0,#xdata_hold + 26
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A
	
	MOV	R0,#xdata_hold + 27
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A
	
	MOV	R0,#xdata_hold + 28
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CJNE	A,#104,$+3
	JNC	GSM_GETRecordCode_ReadNum
	;需要读出的数量
GSM_GETRecordCode_ReadNumSY:;读剩余部份
	MOV	R2,A
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JMP	GSM_GETRecordCode_ReadNumOV
GSM_GETRecordCode_ReadNum:
	MOV	R2,#104	
	CLR	C
	subb	a,#104
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R0,#xdata_hold + 27
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	clr	c
	addc	a,#104
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	dec	r0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	addc	a,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
GSM_GETRecordCode_ReadNumOV:
	PUSH	AR2
	PUSH	AR6
	CALL	_FUN_CARDAPP_ReadBinary02
	POP	AR6
	POP	AR2
	MOV	A,R7
	JNZ	GSM_GETRecordCode_ER	
;GSM_GETRecordCode_TWORV:
	

	MOV	r5,#XDATA_TXBUF
	
	MOV	A,#4
	MOV	B,A
	MOV	a,r2
	DIV	ab
	MOV	R3,A
	
GSM_GETRecordCode_Loop:
	
;	r5	xdata 4 byte
;	r7	xdata 4 byte
;	r5<r7 返回 C=1
;	R5>=r7 返回C = 0
	;xdata_hold [14~17] User unixtime  109~113	
	MOV	r7,#xdata_hold+14	
	push	ar6
	PUSH	AR5
	push	ar3
	CALL	_fun_GSM_compareunixtime2
	pop	ar3
	POP	AR5
	pop	ar6
	
	JNC	GSM_GETRecordCode_over
	INC	ar6
	
	;unixtime 向后读一条记录
	INC	R5
	INC	R5
	INC	R5
	INC	R5	
	DJNZ	R3,GSM_GETRecordCode_loop
	
	;查看是否还存没有没读完的unixtime
	MOV	R0,#xdata_hold + 28
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;---JNZ	GSM_GETRecordCode_RVLOOP
	JZ	GSM_GETRecordCode_RVLOOPZZ
	JMP	GSM_GETRecordCode_RVLOOP
GSM_GETRecordCode_RVLOOPZZ:

	;R7=第一个记录号
	MOV	A,#0FFH
	MOV	AR7,A
	
	;R5=需要前移的记录数
	MOV	A,#0
	MOV	R5,A
	
	RET

	;JMP	GSM_GETRecordCode_ER
	;R7=第一个记录号，没有符合时，使第一个记录号与总数一至
	;SETB	C
	;DEC	AR6
	;MOV	AR7,AR6	
	;R5=需要前移的记录数
	;mov	r5,#0
GSM_GETRecordCode_over:
	;R7=第一个记录号
	MOV	AR7,AR6
	
	MOV	A,R7
	XRL	A,#1
	JZ	GSM_GETRecordCode_ER
	
	;R5=需要前移的记录数
	;CLR	C
	;MOV	A,#1
	;MOV	B,A
	;MOV	A,R7
	;SUBB	A,B
	;MOV	R5,A
	
	MOV	R0,#XDATA_HOLD+1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	clr	c
	SUBB	A,R7
	INC	A
	MOV	R5,A
	
	RET
	
GSM_GETRecordCode_ER:
	;R7=第一个记录号
	MOV	A,#0
	MOV	AR7,A
	
	;R5=需要前移的记录数
	MOV	R5,A
	
	RET	


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;描述
;		ESAM中比用户时间新的记录前移
;前提
;	1.已具备操作ESAM usercard的条件，如打开外围，卡片已复位成功
;	2.已选择ESAM df01 ef07 及 usercard 1001 0009 文件
;流程：
;			获得前移的第一个记录号，及需要前移的记录数
;				R7=第一个记录号,R5=需要前移的记录数
;			前移数据
;				需要移动的数据长度>52，分二次移，不然一次移
;					将要移动的数据，读到xdata_txbuf中
;					将要移动的数据，写回ESAM中
;			前移unixtime
;					将要移动的数据，读到xdata_txbuf中
;					将要移动的数据，写回ESAM中
;			更新总记录数
;					
;参数
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113	
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数	
	;xdata_hold [26] unixtime 偏移量 01 lingshi
	;xdata_hold [27] unixtime 偏移量 02 lingshi
	;xdata_hold [28] unixtime总长度	    lingshi
	
	;xdata_hold [29] TMP OFFSET 01
	;xdata_hold [30] TMP OFFSET 02
	
	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_FUN_GSM_ESAMQY:
	
	CALL	_FUN_GSM_GETRecordCode
	MOV	A,R5
	
	;mov	a,r7
	;call	_fun_test_display
	
	;---JZ	GSM_ESAMQY_OVER
	jnz	GSM_ESAMQY_KS
	MOV	A,R7
	JZ	GSM_ESAMQY_NORecord
	
	;=== 清总数 ===
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R0,#DATA_RXBUF + 5
	mov	a,#0
	mov	@r0,a
	
	;assign offset H/L into r4 / r3
	MOV	R4,#0	
	MOV	R3,#1
	MOV	R2,#1		
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	CALL	_FUN_CARDAPP_UpdateBinary
	
	
GSM_ESAMQY_NORecord:
	jmp	GSM_ESAMQY_OVER
GSM_ESAMQY_KS:
	;R7=第一个记录号,R5=需要前移的记录数
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数
	;R7=第一个记录号,R5=需要前移的记录数
	MOV	R0,#xdata_hold + 18
	MOV	A,R7
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R0,#xdata_hold + 19
	MOV	A,R5
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;JNZ	GSM_ESAMQY_COMPY
	;JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_COMPY:
	
	;xdata_hold [0~4] ESAM前5 0~4
	;xdata_hold [5~8] ESAM unixtime  109~113
	;xdata_hold [9~13] User 前5 0~4
	;xdata_hold [14~17] User unixtime  109~113	
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数

	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数	

	MOV	R0,#xdata_hold + 18
	MOV	R1,#xdata_hold + 21
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	DEC	A
	
	CLR	C
	MOV	B,A
	MOV	A,#2
	MUL	AB
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	DEC	R1
	MOV	A,B
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	CLR	C
	INC	R1
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ADDC	A,#5
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	DEC	R1
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	;xdata_hold [22] 需要移动的字节数
	MOV	R1,#xdata_hold + 22
	MOV	R0,#xdata_hold + 19
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	MOV	B,A
	MOV	A,#2
	MUL	AB
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	MOV	R0,#xdata_hold + 18
	MOV	R1,#xdata_hold + 24
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	DEC	A
	
	CLR	C
	MOV	B,A
	MOV	A,#4
	MUL	AB
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	DEC	R1
	MOV	A,B
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	CLR	C
	INC	R1
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ADDC	A,#113
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	DEC	R1
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	;xdata_hold [25] 需要移动的UNIXTIME的字节数
	MOV	R1,#xdata_hold + 25
	MOV	R0,#xdata_hold + 19
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	MOV	B,A
	MOV	A,#4
	MUL	AB
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数

	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数	

	;xdata_hold [29] TMP OFFSET 01 前移目标地址 offset01
	;xdata_hold [30] TMP OFFSET 02 前移目标地址 offset02
	
	
	
	
	MOV	R0,#xdata_hold+30
	MOV	A,#5
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
GSM_ESAMQY_ReadESAMdataS:
	MOV	R0,#xdata_hold+22
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	;CALL	_FUN_TEST_DISPLAY
	;CJNE	A,#53,$+3
	CJNE	A,#52,$+3
	JNC	GSM_ESAMQY_ReadESAMdataTWO
GSM_ESAMQY_ReadESAMdataOne:

	;R7=第一个记录号,R5=需要前移的记录数
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数

	;读出ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R0,#xdata_hold+20
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	
	MOV	R0,#xdata_hold+21
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		
	
	MOV	R0,#xdata_hold+22
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R2,A	
	
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	;---JNZ	GSM_ESAMQY_OVER
	jz	GSM_ESAMQY_ReadESAMdataOneup
	JMP	GSM_ESAMQY_OVER
	
GSM_ESAMQY_ReadESAMdataOneup:
	;写ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	;MOV	R3,#52
	MOV	R0,#xdata_hold+22
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		
	CALL	_FUN_LIB_XDATATODATA
	
	MOV	R0,#xdata_hold+29
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	MOV	R0,#xdata_hold+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		
	MOV	R0,#xdata_hold+22
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R2,A
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7	
	;CALL	_fun_test_display
	;---JNZ	GSM_ESAMQY_OVER	
	;---JMP	GSM_ESAMQY_ReadESAMdataOVER
	;---JZ	GSM_ESAMQY_ReadESAMdataOVER
	JNZ	GSM_ESAMQY_ReadESAMdataOVERZZ
	JMP	GSM_ESAMQY_ReadESAMdataOVER
GSM_ESAMQY_ReadESAMdataOVERZZ:
	JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_ReadESAMdataTWO:
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数
	;读出ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	
	MOV	R0,#xdata_hold+20
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	;CALL	_FUN_TEST_DISPLAY
	MOV	R0,#xdata_hold+21
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A	
	;CALL	_FUN_TEST_DISPLAY
	MOV	R2,#52	
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	
	;---JNZ	GSM_ESAMQY_OVER
	JZ	GSM_ESAMQY_ReadESAMdataTWOup
	JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_ReadESAMdataTWOup:
	;写ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数

	;xdata_hold [29] TMP OFFSET 01 前移目标地址 offset01
	;xdata_hold [30] TMP OFFSET 02 前移目标地址 offset02

	;MOV	R0,#xdata_hold+30	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#52	
	CALL	_FUN_LIB_XDATATODATA
	
	;assign offset H/L into r4 / r3
	MOV	R0,#xdata_hold+29
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	
	MOV	R0,#xdata_hold+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		

	MOV	R2,#52					
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7
	;CALL	_fun_test_display
	;---JNZ	GSM_ESAMQY_OVER
	JZ	GSM_ESAMQY_ReadESAMdataTWOJS
	JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_ReadESAMdataTWOJS:
	
	;R7=第一个记录号,R5=需要前移的记录数
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数
	
	;xdata_hold [29] TMP OFFSET 01 前移目标地址 offset01
	;xdata_hold [30] TMP OFFSET 02 前移目标地址 offset02		
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址
	MOV	R0,#xdata_hold+21
	
	;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#52
	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;xdata_hold [21] 需要移动的字节数
	MOV	R0,#xdata_hold+22
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	SUBB	A,#52
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	JZ	GSM_ESAMQY_ReadESAMdataOVER
	
	
	MOV	R0,#xdata_hold+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#52
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	JMP	GSM_ESAMQY_ReadESAMdataS
	
GSM_ESAMQY_ReadESAMdataOVER:


	MOV	R0,#xdata_hold+30
	MOV	A,#113
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

;///////////////////////////////////////////////////////////////////
;GSM_ESAMQY_QYESAMUnixS:
GSM_ESAMQY_QYESAMUnixS2:
	MOV	R0,#xdata_hold+25
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CJNE	A,#52,$+3
	JNC	GSM_ESAMQY_QYESAMUnixTWO
GSM_ESAMQY_QYESAMUnixOne:
	
	;R7=第一个记录号,R5=需要前移的记录数
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数
	
	;xdata_hold [29] TMP OFFSET 01 前移目标地址 offset01
	;xdata_hold [30] TMP OFFSET 02 前移目标地址 offset02	

	;读出ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R0,#xdata_hold+23
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	
	MOV	R0,#xdata_hold+24
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		
	
	MOV	R0,#xdata_hold+25
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R2,A	
	
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	;---JNZ	GSM_ESAMQY_OVER
	JZ	GSM_ESAMQY_QYESAMUnixOneUP
	JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_QYESAMUnixOneUP:
	
	;写ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	;MOV	R3,#52
	MOV	R0,#xdata_hold+25
		;MOVX	A,@R0
	MOV	DPH,#1				
	MOV	DPL,R0				
	MOVX	A,@DPTR				
	MOV	R3,A				
	CALL	_FUN_LIB_XDATATODATA		
	
	MOV	R0,#xdata_hold+29
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	
	MOV	R0,#xdata_hold+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		
	
	MOV	R0,#xdata_hold+25
	;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R2,A
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF	
	CALL	_FUN_CARDAPP_UpdateBinary
	MOV	A,R7	
	;CALL	_fun_test_display
	;---JNZ	GSM_ESAMQY_OVER
	JZ	GSM_ESAMQY_OVERZZ02
	JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_OVERZZ02:
	JMP	GSM_ESAMQY_QYESAMUnixOVER

GSM_ESAMQY_QYESAMUnixTWO:
	
	;读出ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R0,#xdata_hold+23
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	
	MOV	R0,#xdata_hold+24
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A	
	
	MOV	R2,#52	
	
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	;---JNZ	GSM_ESAMQY_OVER
	JZ	GSM_ESAMQY_OVERZZ03
	JMP	GSM_ESAMQY_OVER
GSM_ESAMQY_OVERZZ03:

	;写ESAM xdata_hold [21] 需要移动的字节数个byte XX~XX
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#52	
	CALL	_FUN_LIB_XDATATODATA
	
	;assign offset H/L into r4 / r3
	MOV	R0,#xdata_hold+29
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R4,A	
	
	MOV	R0,#xdata_hold+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R3,A		

	MOV	R2,#52		
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7	
	;CALL	_fun_test_display
	JNZ	GSM_ESAMQY_OVER
	
	
	;R7=第一个记录号,R5=需要前移的记录数
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数
	
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 01
	;xdata_hold [21] 获得前移的第一个记录号，对应的起启偏移地址 OFFSET 02
	;xdata_hold [22] 需要移动的字节数
	
	;xdata_hold [23] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 01
	;xdata_hold [24] 获得前移的第一个记录号，对应UNIXTIME的起启偏移地址 OFFSET 02
	;xdata_hold [25] 需要移动的UNIXTIME的字节数
	
	;xdata_hold [29] TMP OFFSET 01 前移目标地址 offset01
	;xdata_hold [30] TMP OFFSET 02 前移目标地址 offset02		
	;xdata_hold [20] 获得前移的第一个记录号，对应的起启偏移地址
	MOV	R0,#xdata_hold+24
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#52
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;xdata_hold [21] 需要移动的字节数
	MOV	R0,#xdata_hold+25
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	SUBB	A,#52
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	JZ	GSM_ESAMQY_QYESAMUnixOVER
	
	MOV	R0,#xdata_hold+30
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#52
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	JMP	GSM_ESAMQY_QYESAMUnixS2
	
GSM_ESAMQY_QYESAMUnixOVER:

	;===更新总的记录数===
	;xdata_hold [18] 获得前移的第一个记录号
	;xdata_hold [19] 需要前移的记录数	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	mov	r0,#xdata_hold+19
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	R0,#DATA_RXBUF + 5
	mov	@r0,a
	
	;assign offset H/L into r4 / r3
	MOV	R4,#0	
	MOV	R3,#1
	MOV	R2,#1		
	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	
	CALL	_FUN_CARDAPP_UpdateBinary
	
GSM_ESAMQY_OVER:
	
	RET
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;描述
;		导出ESAM数据到用户卡中
;前提
;	1.已具备操作ESAM usercard的条件，如打开外围，卡片已复位成功
;	2.已选择ESAM df01 ef07 及 usercard 1001 0009 文件
;流程：
;				
;				更新数据域
;					更新数据域52个byte 5~56
;					更新数据域52个byte 57~108
;				更新前5 0~4
;				更新unixtime 4 109~113
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_FUN_GSM_ESAMToUserCard:

	;===更新数据域52个byte 5~56===
	;读出ESAM 52个byte 5~56
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#00		
	MOV	R3,#5		
	MOV	R2,#52;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	
	;mov	a,#66
	;call	_fun_test_display
	
	;---JNZ	GSM_ESAMToUserCard_OVER
	JZ	GSM_ESAMToUserCardUPDATA1
	JMP	GSM_ESAMToUserCard_OVER
GSM_ESAMToUserCardUPDATA1:
	;写用户卡 52 byte 5~56
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#52
	CALL	_FUN_LIB_XDATATODATA
	
	;assign offset H/L into r4 / r3
	mov	r4,#000h	
	mov	r3,#005h
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#52
	CALL	_FUN_CARDAPP_UpdateBinary
	
	;MOV	A,R7	
	;CALL	_fun_test_display
	;---JNZ	GSM_SerialINTRX_OVER	
	JZ	GSM_ESAMToUserCardRVDATA2
	JMP	GSM_SerialINTRX_OVER
GSM_ESAMToUserCardRVDATA2:	
	;===更新数据域52个byte 57~108===
	;读出ESAM 52个byte 57~108
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#00		
	MOV	R3,#57		
	MOV	R2,#52;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	;---JNZ	GSM_ESAMToUserCard_OVER
	JZ	GSM_ESAMToUserCardUPDATA02
	JMP	GSM_ESAMToUserCard_OVER
GSM_ESAMToUserCardUPDATA02:
	;写用户卡 52个byte 57~108
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#52
	CALL	_FUN_LIB_XDATATODATA
	
	;assign offset H/L into r4 / r3
	mov	r4,#000h	
	mov	r3,#57
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#52
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7	
	;CALL	_fun_test_display
	;---JNZ	GSM_SerialINTRX_OVER
	JZ	GSM_ESAMToUserCardRV5
	JMP	GSM_SerialINTRX_OVER
GSM_ESAMToUserCardRV5:
	;=== 更新前5 0~4 ===
	;读出ESAM 5 byte 0~4
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#00		
	MOV	R3,#00		
	MOV	R2,#5;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	JNZ	GSM_ESAMToUserCard_OVER

	;写用户卡 5 byte 0~4
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#5
	CALL	_FUN_LIB_XDATATODATA
	
	;assign offset H/L into r4 / r3
	mov	r4,#000h	
	mov	r3,#000h
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#5
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7	
	;CALL	_fun_test_display
	;----JNZ	GSM_SerialINTRX_OVER	
	JZ	GSM_ESAMToUserCardRVUNIX
	JMP	GSM_SerialINTRX_OVER
GSM_ESAMToUserCardRVUNIX:						
	;=== 更新unixtime 4 109~113 ===
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF	
	MOV	R5,#XDATA_TXBUF
	MOV	R4,#00		
	MOV	R3,#109		
	MOV	R2,#4							;04 + 03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JNZ	GSM_ESAMToUserCard_OVER
	
	;写用户卡 4 109~113
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	;assign offset H/L into r4 / r3
	mov	r4,#000h	
	mov	r3,#109
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#4
	;---CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7	
	;CALL	_fun_test_display
	;JNZ	GSM_SerialINTRX_OVER	
GSM_ESAMToUserCard_OVER:
	

	
	RET		
;----------------------------------------------------------
;描述：
;	获得偏移量
;参数
;	R7	---	CellID数量(外存)
;	R5	---	返回的偏移量(外存)r5=r7*2
;流程
;		
;----------------------------------------------------------
_FUN_GSM_GetOffset:
	
	MOV	AR0,AR7
	MOV	AR1,AR5
	
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,#2
	MUL	AB
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	DEC	R1
	MOV	A,B
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	RET
	
;----------------------------------------------------------
;描述：
;	获得偏移量
;参数
;	R7	---	CellID数量(外存)
;	R5	---	返回的偏移量(外存)r5=r7*4
;流程
;		
;----------------------------------------------------------
_FUN_GSM_GetOffset02:
	
	MOV	AR0,AR7
	MOV	AR1,AR5
	
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,#4
	MUL	AB
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	DEC	R1
	MOV	A,B
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	RET	
		
;////////////////////////////////////////////////////////////	
;ORG
	MOV	AR0,AR7
	MOV	AR1,AR5
	
	INC	R1
	INC	R0
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;MOV	A,@R0
	MOV	B,#4
	MUL	AB
	
	MOV	Money,B		
	;MOV	@R1,A
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	DEC	R0
	DEC	R1
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;MOV	A,@R0
	MOV	B,#4
	MUL	AB
	
	CLR	C
	ADD	A,MONEY
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	;MOV	@R1,A
	
	RET
;----------------------------------------------------------
;描述：	
;	串口中断接受程序
;参数
;	
;流程	
;	1.接受数据
;	2.如果当前是CellID返回
;		检查返回的 cellid 与 obu 0020文件中记录的最后一个cellid是否相同
;		不相同
;			1.写obu0020及卡片
;			2.关串口接收中断
;			3.更改cellid总数
;		相同
;			退出程序
;	3.重新初始化程序，进入
;	
;STX(2) + RSCTL(1) + LEN(2) + CMD(1)+ DATA(XX)+ BCC(1)
;FA	返回 CellID指令
;----------------------------------------------------------	
_FUN_GSM_SerialINTRX:
	;接收一帧数据，并且完成。
GSM_SerialINTRX_RXRight:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	MOV	R0,#XDATA_CELLID
	MOV	R1,#XDATA_HOLD
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
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	
	;入口 处理 流程
GSM_SerialINTRX_SelectFile:
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;获得 OBU CellID 总数
	;MOV	DPH,#CONST_FLASH_Sys0020numH
	;MOV	DPL,#CONST_FLASH_Sys0020numL
	;MOV	AR7,#XDATA_HOLD
	;MOV	R3,#1					;2
	;CALL	_RDFlashXR
	;MOV	R0,#XDATA_HOLD
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0DFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#CONST_ESAMCellfile_H
	MOV	R2,#CONST_ESAMCellfile_L
	CALL	_FUN_CARDAPP_SelectFile
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID

	
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD+2
	MOV	R4,#00							;R4		---	文件ID
	MOV	R3,#00							;R3		---	长度
	MOV	R2,#05;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	;~~~~~~~~~~ 调用测试段 ~~~~~~~~~~
	;mov	A,#53
	;call	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	;---JNZ	GSM_SerialINTRX_NOInput02 
	;---JNZ	GSM_SerialINTRX_OVER
	JZ	GSM_SerialINTRX_lOWvO
	JMP	GSM_SerialINTRX_OVER
	
GSM_SerialINTRX_lOWvO:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID
	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CJNE	A,#CONST_GSM_MaxNum,$+3
	JC	GSM_SerialINTRX_IsNotMax
	
	;---CALL	_Fun_GSM_RTCDis
	JMP	GSM_SerialINTRX_OVER
	
GSM_SerialINTRX_IsNotMax:
	
	; 比较最后一个Cell_ID与串口过来的CellID是否相同
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID		
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	JZ	GSM_SerialINTRX_getoffset	
	
	MOV	R0,#XDATA_HOLD 		;当前接收 CellID	
	MOV	R1,#XDATA_HOLD+5;4	;上一次最后一个 CellID	
	MOV	R3,#2			;4
GSM_SerialINTRX_CompareCellID:
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
	;JNZ	GSM_SerialINTRX_CompareCellIDXXX
	;JNZ	GSM_SerialINTRX_CompareCellIDover
	JNZ	GSM_SerialINTRX_getoffset
	INC	R0
	INC	R1
	DJNZ	R3,GSM_SerialINTRX_CompareCellID
	
	;/////////////////////////////////////////////////////////////////////////////////////////////	
	;比较UnixTime时间是否超255 S，更新 ESAM 及用户卡时间
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 = 0 入 = 1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量	
	;/////////////////////////////////////////////////////////////////////////////////////////////	
	CLR	BIT_ESAMICC
	CALL	_FUN_GSM_JSUnixtimeOff
	
GSM_SerialINTRX_outputovvv:
	;/////////////////////////////////////////////////////////////////////////////////////////////
	JMP	GSM_SerialINTRX_OVER					;如果CellID相同，结束流程
	;JMP	GSM_SerialINTRX_ESAMOVER	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;MOV	DPH,#CONST_FLASH_Sys0020H
	;MOV	DPL,#CONST_FLASH_Sys0020L+2
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#2
	;CALL	_rdflashxr
	
	;SETB	BIT_BUFADDR
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#2
	;MOV	A,#1
	;CALL	_FUN_TEST_UARTDISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
GSM_SerialINTRX_getoffset:
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	
	MOV	R0,#XDATA_HOLD+3;2
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;call	_FUN_TEST_DISPLAY
	
	JNZ	GSM_SerialINTRX_getLastCellIDaddrPY
	
	;CellID 总数为0
GSM_SerialINTRX_getLastCellIDaddr00:
	
	; 计算 卡片 当前cellid偏移
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量
	CLR	A
	MOV	R0,#XDATA_HOLD + 7;6
	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#5;4 
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	

	MOV	R1,#XDATA_HOLD+10 
	MOV	R0,#XDATA_HOLD+8 
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#108;108= 52*2+4=104+4=52个记录，每个记录2个字节，4个字节入口unixtime
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	;---INC	R0
	
	dec	r0
	dec	r1
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A	

	JMP	GSM_SerialINTRX_getLastCellIDaddrov	
	;CellID 总数不为0
GSM_SerialINTRX_getLastCellIDaddrPY:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量
	MOV	R7,#XDATA_HOLD+3	 
	MOV	R5,#XDATA_HOLD+7 
	CALL	_FUN_GSM_GetOffset
	
	
	MOV	R0,#XDATA_HOLD+8 
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#5
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;---INC	R0
	dec	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	
	MOV	R7,#XDATA_HOLD+3	 
	MOV	R5,#XDATA_HOLD+9 
	CALL	_FUN_GSM_GetOffset02
	
	MOV	R0,#XDATA_HOLD+10 
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#113
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;---INC	R0
	dec	r0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
 	
;////////////////////////////////////////////////////////////////////
GSM_SerialINTRX_CompareCellIDover:
	
GSM_SerialINTRX_getLastCellIDaddrov:
;////////////////////////////////////////////////////////////////////
	
	;== update binary data ==
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量		
	
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_HOLD
	MOV	R3,#2
	CALL	_FUN_LIB_XDATATODATA
	
	;MOV	R0,#XDATA_HOLD; + 5
	;CALL	_FUN_TEST_DISPLAY
	
	;assign offset H/L into r4 / r3
	CLR	C
	MOV	R0,#XDATA_HOLD+8
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#11
	MOV	r3,a
	
	dec	r0
	;INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#0
	MOV	r4,a
	
	;mov	r4,#0
	;mov	r3,#00h	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#2;04H
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7
	
	;CALL	_fun_test_display
	
	;---JNZ	GSM_SerialINTRX_OVER
	;---JZ	GSM_SerialINTRX_UPDATAESAM
	JZ	GSM_SerialINTRX_UPDATAESAMUNIX
	JMP	GSM_SerialINTRX_OVER
	
	;更新 unix time
GSM_SerialINTRX_UPDATAESAMUNIX:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC	
	
;R5	---	direct
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_UnixTime
	
;MOV	R0,#XDATA_UnixTime+3
;call	_fun_test_display	
	
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	;MOV	R0,#XDATA_HOLD; + 5
	;CALL	_FUN_TEST_DISPLAY
	
	;assign offset H/L into r4 / r3
	
;10:57	11:47
	
	CLR	c
	MOV	R0,#XDATA_HOLD+10
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#11
	mov	r3,a
	
	dec	r0
	;INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#0
	mov	r4,a
	;call	_fun_test_display
	;mov	r4,#0
	;mov	r3,#00h	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#4;04H
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7
	
	;CALL	_fun_test_display
		
	;---JNZ	GSM_SerialINTRX_OVER
	JZ	GSM_SerialINTRX_UPDATAESAM
	JMP	GSM_SerialINTRX_OVER
	
	
GSM_SerialINTRX_UPDATAESAM:
	
	;== update record num ==
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量		
	
	
	;COPY  新收到的 CellID
	MOV	R0,#XDATA_HOLD +3
	MOV	R1,#DATA_RXBUF+5
	
	MOV	A,#33
	mov	@r1,a
	inc	r1
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	INC	A
	MOV	@R1,A
	
	INC	R0
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	@R1,A

	;COPY  ESAM CellID个数
	MOV	R0,#XDATA_HOLD
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;INC	A
	MOV	@R1,A	
	INC	R0
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	@R1,A	
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;mov	a,r7	
	;call	_fun_test_display
	;setb	BIT_BUFADDR
	;MOV	R7,#XDATA_hold+4
	;CLR	BIT_BUFADDR
	;MOV	R7,#DATA_RXBUF+5	
	;MOV	R3,#4
	;CALL	_FUN_TEST_UARTDISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	r4,#0
	MOV	r3,#00h	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_txbuf
;	MOV	R2,#02H
	MOV	R2,#5
	CALL	_FUN_CARDAPP_UpdateBinary
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;SETB	BIT_BUFADDR
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#6
	;MOV	A,#1	
	;CALL	_FUN_TEST_UARTDISPLAY	
	;MOV	A,R7
	;Call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	MOV	A,R7
	;---JNZ	GSM_SerialINTRX_OVER
	JZ	GSM_SerialINTRX_ESAMOVER
	JMP	GSM_SerialINTRX_OVER
GSM_SerialINTRX_ESAMOVER:
	SETB	BIT_HaveRecordCellID
;///////////////////////////////////////////////////////////////////////////////////////////////////////

	JB	BIT_INSERTCARD,GSM_SerialINTRX_UserCardStart
	JMP	GSM_SerialINTRX_OVER
GSM_SerialINTRX_UserCardStart:
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#010H
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile	
	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#CONST_Cellfile_H
	MOV	R2,#CONST_Cellfile_L
	CALL	_FUN_CARDAPP_SelectFile
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID

	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD+2					;
	MOV	R4,#00							;R4		---	文件ID
	MOV	R3,#00							;R3		---	长度
	MOV	R2,#05							;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	;~~~~~~~~~~ 调用测试段 ~~~~~~~~~~
	;mov	A,#53
	;call	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;---JNZ	GSM_SerialINTRX_NOInput02
	JZ	GSM_SerialINTRX_USERCARDlOWvO
	;---JMP	GSM_SerialINTRX_NOInput02
	JMP	GSM_SerialINTRX_OVER
	
GSM_SerialINTRX_USERCARDlOWvO:
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CJNE	A,#CONST_GSM_MaxNum,$+3
	JC	GSM_SerialINTRX_USERCARDIsNotMax
	
	;CALL	_Fun_GSM_RTCDis
	JMP	GSM_SerialINTRX_OVER
	
GSM_SerialINTRX_USERCARDIsNotMax:
	
	; 比较最后一个Cell_ID与串口过来的CellID是否相同
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	JZ	GSM_SerialINTRX_USERCARDgetoffset
	
	MOV	R0,#XDATA_HOLD 		;当前接收 CellID	
	MOV	R1,#XDATA_HOLD+5	;上一次最后一个 CellID	
	MOV	R3,#2;4
GSM_SerialINTRX_USERCARDCompareCellID:
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
	;JNZ	GSM_SerialINTRX_USERCARDCompareCellIDXXX
	;JNZ	GSM_SerialINTRX_USERCARDCompareCellIDover
	jnz	GSM_SerialINTRX_USERCARDgetoffset
	INC	R0
	INC	R1
	DJNZ	R3,GSM_SerialINTRX_USERCARDCompareCellID
	
	
	
	JMP	GSM_SerialINTRX_OVER	;如果CellID相同，结束流程
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;MOV	DPH,#CONST_FLASH_Sys0020H
	;MOV	DPL,#CONST_FLASH_Sys0020L+2
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#2
	;CALL	_rdflashxr
	
	;SETB	BIT_BUFADDR
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#2
	;MOV	A,#1
	;CALL	_FUN_TEST_UARTDISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
GSM_SerialINTRX_USERCARDgetoffset:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	MOV	R0,#XDATA_HOLD+3
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;call	_FUN_TEST_DISPLAY
	
	JNZ	GSM_SerialINTRX_USERCARDgetLastCellIDaddrPY
	
	;CellID 总数为 0 
GSM_SerialINTRX_USERCARDgetLastCellIDaddr00:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量
	
	CLR	A
	MOV	R0,#XDATA_HOLD + 7;6
	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#5;4 
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A

	MOV	R1,#XDATA_HOLD+10 
	MOV	R0,#XDATA_HOLD+8 
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#108;108= 52*2+4=104+4=52个记录，每个记录2个字节，4个字节入口unixtime
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	;---INC	R0
	
	dec	r0
	dec	r1
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A	
	
	;CellID 总数不为0
	JMP	GSM_SerialINTRX_USERCARDgetLastCellIDaddrov	
	;CellID 总数不为0
GSM_SerialINTRX_USERCARDgetLastCellIDaddrPY:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量
	MOV	R7,#XDATA_HOLD+3	 
	MOV	R5,#XDATA_HOLD+7 
	CALL	_FUN_GSM_GetOffset
	
	
	MOV	R0,#XDATA_HOLD+8 
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#5
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;---INC	R0
	dec	r0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R7,#XDATA_HOLD+3	 
	MOV	R5,#XDATA_HOLD+9 
	CALL	_FUN_GSM_GetOffset02
	
	MOV	R0,#XDATA_HOLD+10 
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#113
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;---INC	R0
	dec	r0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
GSM_SerialINTRX_USERCARDCompareCellIDover:
	
GSM_SerialINTRX_USERCARDgetLastCellIDaddrov: 
	
	;== update binary data ==
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_HOLD
	MOV	R3,#2
	CALL	_FUN_LIB_XDATATODATA
	
	;MOV	R0,#XDATA_HOLD; + 5
	;CALL	_FUN_TEST_DISPLAY
	
	;assign offset H/L into r4 / r3
	CLR	c
	MOV	R0,#XDATA_HOLD+8
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#11
	mov	r3,a
	
	dec	r0
	;INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#0
	mov	r4,a
	
	;mov	r4,#0
	;mov	r3,#00h	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#2;04H
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7
	
	;CALL	_fun_test_display
	
	JNZ	GSM_SerialINTRX_OVER
	
	;== update record num ==
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量
	
	;COPY  新收到的 CellID
	MOV	R0,#XDATA_HOLD +3
	MOV	R1,#DATA_RXBUF+5
	
	MOV	A,#33
	mov	@r1,a
	inc	r1
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	INC	A
	MOV	@R1,A
	INC	R0
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	@R1,A

	;COPY  ESAM CellID个数
	MOV	R0,#XDATA_HOLD
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;INC	A
	MOV	@R1,A	
	INC	R0
	INC	R1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	@R1,A	
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;mov	a,r7	
	;call	_fun_test_display
	;setb	BIT_BUFADDR
	;MOV	R7,#XDATA_hold+4
	;CLR	BIT_BUFADDR
	;MOV	R7,#DATA_RXBUF+5	
	;MOV	R3,#4
	;CALL	_FUN_TEST_UARTDISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	r4,#0
	MOV	r3,#00h	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_txbuf
	;MOV	R2,#02H
	MOV	R2,#5
	CALL	_FUN_CARDAPP_UpdateBinary
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;SETB	BIT_BUFADDR
	;MOV	R7,#XDATA_HOLD
	;MOV	R3,#6
	;MOV	A,#1
	;CALL	_FUN_TEST_UARTDISPLAY
	;MOV	A,R7
	;call	_fun_test_display
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	MOV	A,R7
	JNZ	GSM_SerialINTRX_OVER
	
GSM_SerialINTRX_USERCARDESAM:

;///////////////////////////////////////////////////////////////////////////////////////////////////////		
	CALL	_FUN_ContactIssue_INIT				
	
GSM_SerialINTRX_OVER:
	;CALL	_FUN_ContactIssue_Release
	
	;---JMP	AP_satrt
	
	RET
	

;----------------------------------------------------------
;播报短信功能
;R7	---	短信绶冲
;R7+5	---	短信绶冲数据
;R3	---	短信长度
;head(1) + len(2) + cmd(1) + cmdPara(1) + data(n) + bcc(1)[from head to data xor]
;fd + xx xx + 01 + 03(unicode) + bcc
;流程
;	开启语音模块电源
;	发送短信消息给模块
;	开闭语音模块电源
;----------------------------------------------------------
_FUN_GSM_ReportMSG:
	
	MOV	AR0,AR7		;[head]
	MOV	A,#0FDH
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0		;len[0]
	INC	R0		;len[1]
	MOV	A,R3
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0
	MOV	A,#001H		;CMD
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0
	MOV	A,#003H		;CMD Para
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	INC	R0		;DATA[0]
	
	MOV	A,R0
	ADD	A,R3
	MOV	R0,A
	
	PUSH	AR3
	PUSH	AR7
	
	MOV	A,R3
	ADD	A,#5	
	MOV	R3,A	
	CLR	BIT_BUFADDR	
	CALL	_FUN_LIB_GetBCC
	
	POP	AR7
	POP	AR3
	
	JNZ	GSM_ReportMSG_OVER
	
	;发送语音信息
	
GSM_ReportMSG_OVER:
	RET
	
;----------------------------------------------------------
;描述:
;	开启RTC	
;----------------------------------------------------------
_Fun_GSM_RTCEn:
	
;clr	es
	;设置 RTC 开启运行标记
	MOV	R0,#XDATA_RTCMode
	MOV	A,#CONST_RTC_ON
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;初始化RTC记时器
	MOV	R0,#XDATA_RTCTime
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;开启RTC [h0~3 L0~7]fffh = 6s
	;MOV	REG_MCU_WKCTH,#CONST_MCU_WKCTH
	;ORL	REG_MCU_WKCTH,#10000000B
	;MOV	REG_MCU_WKCTL,#CONST_MCU_WKCTL
	CALL	_FUN_GSM_RTCON
	;CALL	_Fun_GSM_GetCellIDEN
	
	Anl	REG_5412AD_P1M0,#00111111B	 ;
	Orl	REG_5412AD_P1M1,#01000000B	 ; MISO 为输入(高阻)
	
	CLR	PIN_PWR_GSM			 ; [GSM] 
;       	SETB	Pin_CC1101_SS
;	CLR	PIN_CC1101_SCLK
;	CLR	PIN_CC1101_MOSI
;	setb	PIN_CC1101_MISO
	;setb	PIN_CC1101_GDO2 
	;MOV	r7,#10
	;CALL	_fun_lib_delay
	
	CALL	_FUN_CC1101_RESET
	CALL	_FUN_CC1101_INIT
;	A			---	地址
;	R7			---	数据
;	R6			---	外存
;	R4			---	总数
	;MOV	R4,#8
	;MOV	A,#7EH
	;MOV	R6,#XDATA_TXBUF
	;MOV	R7,#0C0H
	;CALL	_FUN_CC1101_spioSoftRXCC1101RXCC1101
	;34
	CALL	_FUN_CC1101_RVOn
	PUSH	AR7
	MOV	R7,#255
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

	POP	AR7
	;36 3A
	CALL	_FUN_CC1101_RVOff
	CALL	_FUN_CC1101_SetWakeUpTime
	CALL	_FUN_CC1101_RVWR
	CALL	_FUN_CC1101_Idle
	CALL	_FUN_CC1101_WakeUP
	
	RET
;----------------------------------------------------------
;描述:
;	禁用RTC	
;----------------------------------------------------------	
_Fun_GSM_RTCDis:
		
	;设置 RTC 开启运行标记
	MOV	R0,#XDATA_RTCMode
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;初始化 RTC 记时器
	MOV	R0,#XDATA_RTCTime
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;关闭 RTC [h0~3 L0~7]fffh = 6s
	;MOV	REG_MCU_WKCTH,#CONST_MCU_WKCTH
	;MOV	REG_MCU_WKCTL,#CONST_MCU_WKCTL
	CALL	_FUN_GSM_RTCOFF
	
	Anl	REG_5412AD_P1M0,#01111111B	 ;
	Anl	REG_5412AD_P1M1,#01111111B	 ; MISO 普通	
	
	SETB	PIN_PWR_GSM			 ; [GSM] 
;       	CLR	Pin_CC1101_SS
;	CLR	PIN_CC1101_SCLK
;	CLR	PIN_CC1101_MOSI
	;PIN_CC1101_MISO
;	CLR	PIN_CC1101_GDO2 
	
	RET
;----------------------------------------------------------
;描述:
;	开RTC
;----------------------------------------------------------	
_FUN_GSM_RTCON:
		
	MOV	REG_MCU_WKCTH,#CONST_MCU_WKCTH
	;---ORL	REG_MCU_WKCTH,#10000000B
	MOV	REG_MCU_WKCTL,#CONST_MCU_WKCTL	
	RET	
;----------------------------------------------------------
;描述:
;	关RTC	
;----------------------------------------------------------	
_FUN_GSM_RTCOFF:
	
	;ORL	REG_5412AD_P3M0,#01000000B
	;MOV	A,#39
	;CALL	_FUN_TEST_DISPLAY
	
	MOV	REG_MCU_WKCTH,#CONST_MCU_WKCTH
	MOV	REG_MCU_WKCTL,#CONST_MCU_WKCTL
	
	RET	
;----------------------------------------------------------
;描述:
;	获得cellid
;	1. 设置 GSMIO 为普通脚	3.7
;	2. GSMPow io推换脚	2.0
;	3. set gsmio L
;	4. set GSM Power H
;	5. sleep
;----------------------------------------------------------	
_Fun_GSM_GetCellIDEN:
	

	
	RET
;----------------------------------------------------------
;_FUN_GSM_LowVotage		低电压报警
;_FUN_GSM_ETCInputDeal		GSM在ETC入口处理流程
;_FUN_GSM_ETCOnputDeal		GSM在ETC出口处理流程
;----------------------------------------------------------
;DPTR	
;R7(外存)
;BIT_BUFADDR
;----------------------------------------------------------
_Fun_GSM_Audio:
	
	RET


;----------------------------------------------------------
	;比较UnixTime时间是否超255 S，更新 ESAM 及用户卡时间
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 = 0 入 = 1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
;----------------------------------------------------------
_FUN_GSM_JSUnixtimeOff:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量	
	MOV	R0,#XDATA_HOLD + 3;2
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;CALL	_FUN_TEST_DISPLAY
	
	JNZ	GSM_JSUnixtimeOff_getLastCellIDaddrPY
	
	CLR	A
	MOV	R0,#XDATA_HOLD + 7;6
	
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
	MOV	A,#5;4 
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	R1,#XDATA_HOLD+10 
	MOV	R0,#XDATA_HOLD+8 
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#108;108= 52*2+4=104+4=52个记录，每个记录2个字节，4个字节入口unixtime
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A
	;---INC	R0
	
	dec	r0
	dec	r1
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A	
	
	JMP	GSM_JSUnixtimeOff_UPDATEUNIXTIME	
	;CellID 总数不为0
GSM_JSUnixtimeOff_getLastCellIDaddrPY:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID	
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量
	MOV	R7,#XDATA_HOLD+3	 
	MOV	R5,#XDATA_HOLD+7 
	CALL	_FUN_GSM_GetOffset
	
	MOV	R0,#XDATA_HOLD+8 
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#5
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;---INC	R0
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
			
	MOV	R7,#XDATA_HOLD+3	 
	MOV	R5,#XDATA_HOLD+9 
	CALL	_FUN_GSM_GetOffset02
	
	MOV	R0,#XDATA_HOLD+10 
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	CLR	C
	ADDC	A,#109;113
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;---INC	R0
	DEC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	ADDC	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
GSM_JSUnixtimeOff_UPDATEUNIXTIME:
	
	;XDATA_HOLD[0~1] 新收到的 CellID
	;XDATA_HOLD[2] 33
	;XDATA_HOLD[3] ESAM CellID 个数
	;XDATA_HOLD[4] 最近出口、入口车道类型 =0 入 =1 出
	;XDATA_HOLD[5~6] 上一次最后一个 CellID
	;XDATA_HOLD[7~8] 上一次最后一个 esam CellID偏程量	
	;XDATA_HOLD[9~10] 上一次最后一个 esam CellID unix time偏程量	
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC	
	
;R5		---	direct
	MOV	R5,#DATA_RXBUF + 5
	MOV	R7,#XDATA_UnixTime
	
;MOV	R0,#XDATA_UnixTime+3
;call	_fun_test_display	
	
	MOV	R3,#4
	CALL	_FUN_LIB_XDATATODATA
	
	;MOV	R0,#XDATA_HOLD; + 5
	;CALL	_FUN_TEST_DISPLAY
	
	;assign offset H/L into r4 / r3
	
	CLR	c
	MOV	R0,#XDATA_HOLD+10
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#11
	mov	r3,a

	dec	r0
	;INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;addc	a,#0
	mov	r4,a
	;call	_fun_test_display
	;mov	r4,#0
	;mov	r3,#00h	
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R2,#4;04H
	CALL	_FUN_CARDAPP_UpdateBinary
	
	MOV	A,R7



	RET


;----------------------------------------------------------
;_Fun_GSM_GetCellID:

;///////////////////////////////////////////////////////////////////////////////////////////////
;----------------------------------------------------------

	END	


