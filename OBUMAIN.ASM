;**********************************************************************
;59 板程序中断强迫跳回主程序，堆栈SP会乱，所以强迫置 SP = 0A7h + 002H
;休眠拆卸中断唤醒后，应对 5830 重新初始化
;注意:	1.	59 板的红灯与中断P3.3(EX1),在开EX1中断前须清IE1标识，在开ex1中断后不能亮红灯,在收到bst后，撤ex1中断使能。
;	2.	在 接收过程中开外部中断EX0、EX1和定时器中断T0,EX0为数据接收pin,ex1为插卡和拆卸pin。
;	3.	在 休眠前灭红灯,清IE1标识，开IE1中断使能。
;	 改			加一句	  加一句
;描述：OBU 主程序集
;函数申请
;_FUN_OBUMAIN_MASTER			 		---	OBU 主程序
;	附属程序段:SEG_OBUMAIN_CDACTIVE			---	拆动激活
;	附属程序段:SEG_OBUMAIN_CARDACTIVE		---	插卡激活
;	附属程序段:SEG_OBUMAin_WAVEACTIVE		---	微波激活
;	
;_FUN_OBUMAIN_INITSYS					---	系统初始化(寄存器、变量等初始化)
;_FUN_OBUMain_BASEINIT					---	应用初始化
;_FUN_OBUMain_CARDPreDeal				---	卡片预处理
;_FUN_OBUMain_CardInfoDisplay				---	卡信息显示
;交易不顺，会出现车牌不一致
;按下拆动，交易会不顺
; 002
;分支2
;分支3
; org
;加一行中文看看 
;**********************************************************************
$INCLUDE(OBUMAIN.INC)
$INCLUDE(COMMON.INC)
	
;-----------------------------------------------------------------
;描述:中断 向量 
;-----------------------------------------------------------------
;External Interrupt 0	0003H
;Timer 0		000BH
;External Interrupt 	0013H
;Timer 1		001BH
;UART			0023H
;ADC/SPI		002BH
;PCA/LVD		0033H
;			;
;IE			;
;IE.0	INT0		;微波唤醒中断
;IE.1	Timer0		;T0定时器
;IE.2	INT1		;插卡中断[状态:电平触发][平时为高，插入为低]
;IE.3	Timer1		;拆动中断 [状态:按下为高，放开为低] [电平触发]td 
;IE.4	UART		
;IE.5	ADC/SPI		
;IE.6	PCA/LVD		
;注意: 串口 用BRT 做 波特率 发生器
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	CSEG	AT	00H
	JMP		AP_start		; 主处理程序
	
	CSEG	AT	03H
	JMP		Int_WaveActive			; 外部中断0，微波唤醒中断
	
	CSEG	AT	0BH
	JMP		Int_Timer0			; T0定时器中断
	
	CSEG	AT	13H			; 外部中断1，插卡中断
	JMP 	Int_InsertActive		
	
	CSEG	AT	1BH
	JMP		Int_UnixActive			; 拆动中断
	
	CSEG	AT	23H
	JMP	Int_UART			; 串口中断	
	
	RSEG	?pr?OBUMAIN?tf0_timer_1
	USING	0
;--------------------------------------
;描述:
;	串口断接收程序
;触发方式
;	下降延触发
;--------------------------------------
Int_UART:
	
	CLR	TR0
	CLR	PIN_WAVE_CHANNEL1
	ANL	REG_MCU_WKCTH,#01111111B
	CLR	EA
	CLR	ES 			;允许外部中断0
	;[2013-7-20] MOV	REG_WDT_CONTR,#00111111B	
	MOV	SP,#IDATA_STACK
	MOV	A,#LOW	_FUN_TEST_SerialTX03	;_FUN_CC1101_RX
	PUSH	ACC
	MOV	A,#HIGH	_FUN_TEST_SerialTX03	;_FUN_CC1101_RX
	PUSH	ACC
	
Int_UART_OVER:
	
	RETI
;--------------------------------------
;描述:  拆动开关按下继续微波唤醒流程;弹开跳转到AP_start
;触发方式
;	下降延 触发
;功能： 微波唤醒拆动开关防抖
;--------------------------------------
Int_Invalid:
	CLR	EA
	mov	r7,#1
	call	_fun_lib_delay		
	JB	Pin_unfix,Int_WaveActive_S			;Pin_unfix=1(拆卸已按)
	
	MOV	IE,#0
	MOV	SP,#IDATA_STACK
	MOV	A,#low AP_start;OBUMain_sys_OVER
	PUSH	ACC
	MOV	A,#high AP_start ;OBUMain_sys_OVER
	PUSH	ACC
	
	RETI
;--------------------------------------;
;描述：;
;	外部中断0，微波唤醒中断
;触发方式
;	下降延触发
;--------------------------------------
Int_WaveActive:
	
	JnB	Pin_unfix,Int_Invalid				;Pin_unfix=0(拆卸未按)
Int_WaveActive_S:
	ANL	REG_MCU_WKCTH,#01111111B			;禁止内部停机唤醒定时器
	CLR	EA
	CLR	ES
	
	CLR	EX0 														;允许外部中断0
	MOV	SP,#IDATA_STACK
	MOV	A,#low SEG_OBUMAIN_WAVEACTIVE;TEST_5823_Loop
	PUSH	ACC
	MOV	A,#high SEG_OBUMAIN_WAVEACTIVE;TEST_5823_Loop
	PUSH	ACC
	
	RETI
;--------------------------------------
;描述：
;	插卡中断 中断
;触发方式
;	下降延触发
;	状态
;状态
;--------------------------------------
Int_InsertActive:	
	CLR	EA
	ANL	REG_MCU_WKCTH,#01111111B
	CLR	EA
	CLR	ES
	CLR	EX1	
	MOV	SP,#IDATA_STACK
	MOV	a,#low SEG_OBUMAIN_CARDACTIVE
	PUSH	acc
	MOV	a,#high SEG_OBUMAIN_CARDACTIVE
	PUSH	acc	
Int_InsertActive_Over:	
	RETI
	
Int_InsertActive_RET:
	SETB	EA
	RETI	
;--------------------------------------
;描述：
;	T0定时器 中断
;触发方式
;	定时器触发
;	状态
;--------------------------------------
Int_Timer0:
	
	push 	acc
	mov 	a,#01
	add 	a,DATA_PowerONTimer						;DATA_PowerONTimer计数器
	mov 	DATA_PowerONTimer,a
	jnc	Int_T0_RET
	;超时处理
	pop	acc
	CLR	TR0															; 关闭T0
	CLR	ET0															; 关闭T0使能
	MOV	SP,#IDATA_STACK
	mov	A,#low OBUMAIN_WAVEACTIVE_OVER
	push	ACC
	mov	A,#high OBUMAIN_WAVEACTIVE_OVER
	push	ACC
	
Int_T0_OVER:
	
	RETI
	
Int_T0_RET:													  ;未超时
	POP 	ACC
	RETI
;--------------------------------------
;描述：
;描述：
;	拆动中断 & T1定时器
;触发方式
;	电平触发
;状态	
;	拆动：按下为高，放开为低
;	定时器1，暂时没有用到中断，仅为串口1的波特率发生器
;--------------------------------------
Int_UnixActive:	
	JB	Pin_unfix,Int_UnixActive_Over				;Pin_unfix=0未按；Pin_unfix=1按下
	CLR	EA
	
	PUSH	AR7	
	mov	r7,#10
	call	_fun_lib_delay		
	POP	AR7
	
	JnB	Pin_unfix,Int_UnixActive_01	
	setb	EA
	jmp	Int_UnixActive_Over	
Int_UnixActive_01:	
	ANL	REG_MCU_WKCTH,#01111111B	
	CLR	EA
	CLR	ES
	CLR 	ET1 															;允许外部中断1	
	
	MOV	SP,#IDATA_STACK
	mov 	a,#low SEG_OBUMAIN_CDACTIVE
	push 	acc
	mov 	a,#high SEG_OBUMAIN_CDACTIVE
	push 	acc
Int_UnixActive_Over:
	RETI
;///////////////////////////////////////////////////////////////////////////////////////////
Sleep:

_Fun_OBUmain_PinSleep:

	MOV	A,REG_5412AD_P4SW
	ORL	A,#01110000B
	MOV	REG_5412AD_P4SW,A
	
	MOV	REG_5412AD_P0M0,#00000000B
	MOV	REG_5412AD_P0M1,#00000001B
	
	MOV	REG_5412AD_P2M0,#00000000B
	MOV	REG_5412AD_P2M1,#00000000B
	
	MOV	REG_5412AD_P3M0,#00000000B
	MOV	REG_5412AD_P3M1,#00101100B
	
	MOV	REG_5412AD_P4M0,#00000000B
	MOV	REG_5412AD_P4M1,#00000000B
	
	;JMP	OBUmain_PinSleep_RTCOff	
	MOV	R0,#XDATA_RTCMode
	;	MOVX	A,@R0
	MOV	DPH,#2
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_RTC_ON
	JNZ	OBUmain_PinSleep_RTCOff
	
;/////////////////////////////////////////////////////////////////////////
OBUmain_PinSleep_RTCON:
	MOV	REG_5412AD_P1M0,#00000000B
	MOV	REG_5412AD_P1M1,#01000100B      ; MISO 为输入	
	
	CLR	PIN_PWR_GSM			; P2.0	
	;	SETB	PIN_PWR_GSM
	SETB	PIN_UART2_TX
	SETB	PIN_UART2_RX
	;SETB	PIN_Bluetooth_RST
	
	;---CLR	PIN_SE_IO1
	;CLR	PIN_CC1101_MOSI	
	SETB	Pin_5823BK_IRQ
	SETB	PIN_BK_CE
	
	;COM下载
	setb	PIN_SOFTSERIALRX
	setb	PIN_SOFTSERIALTXH
	
	clr	Pin_Gre
	JMP	OBUmain_PinSleep_RTCSWOver
;/////////////////////////////////////////////////////////////////////////
OBUmain_PinSleep_RTCOff:
	MOV	REG_5412AD_P1M0,#00000000B	 ;
	MOV	REG_5412AD_P1M1,#00000100B	 ; MISO 为输入(高阻)
	
	SETB	PIN_PWR_GSM			; P2.4			 ; [GSM] 
 	CLR	PIN_UART2_TX			; p3.6
	CLR	PIN_UART2_RX			; P1.6
	;CLR	PIN_Bluetooth_RST		; p3.7
	;---CLR	PIN_SE_IO1			; P2.2
;	CLR	PIN_CC1101_MOSI			; P2.3
	
	SETB	Pin_5823BK_IRQ			; p1.2
	SETB	PIN_BK_CE			; p1.1
						
	;LCD
	SETB	PIN_PWRDWN_LCD			; [液晶电源 LCD 背光]放到休眠前
	CLR     Pin_LCD_RST             	;液晶复位腿为低	
	CLR     Pin_LCD_SDA             	;液晶数据腿为低
	CLR     Pin_LCD_SCL       		;液晶时钟腿为低
	CLR     Pin_LCD_CS			;液晶片选腿为低
	CLR     Pin_LCD_DC 			;液晶命令腿为低						

	;COM下载
	clr	PIN_SOFTSERIALRX
	clr	PIN_SOFTSERIALTXH

	SETB	Pin_Gre

			
OBUmain_PinSleep_RTCSWOver:			; 
						; 
	CLR	PIN_ESAM_RST			; 
	CLR	Pin_ES_Rst			; 
	CLR	Pin_522_RST			; 
	SETB	Pin_pwrdwn			; [外 围 电 源]
	setb	PIN_PWR_SE
	
	SETB	Pin_unfix
	SETB	PIN_card_exist
	SETB	WKO_BK
	
	SETB	Pin_5823BK_MISO
	
	;LCD
	;CLR     Pin_LCD_RST             ;液晶复位腿为低	
	;CLR     Pin_LCD_SDA             ;液晶数据腿为低
	;CLR     Pin_LCD_SCL       	 ;液晶时钟腿为低
	;CLR     Pin_LCD_CS		 ;液晶片选腿为低
	;CLR     Pin_LCD_DC 		 ;液晶命令腿为低


	;LCD
	;SETB	PIN_PWRDWN_LCD			; [液晶电源 LCD 背光]放到休眠前
	;CLR     Pin_LCD_RST             	;液晶复位腿为低	
	;CLR     Pin_LCD_SDA             	;液晶数据腿为低
	;CLR     Pin_LCD_SCL       		;液晶时钟腿为低
	;CLR     Pin_LCD_CS			;液晶片选腿为低
	;CLR     Pin_LCD_DC 			;液晶命令腿为低						


	
	;RC522
	CLR     Pin_522_RST		;522复位腿为低
	CLR     PIN_522_MOSI		;522 MISO为低
	CLR     Pin_522_SS		;522 SS腿为低
	CLR   	PIN_522_MISO
	CLR     PIN_522_SCLK		;522 SCLK腿为低
	
	;ESAM
	CLR     PIN_ESAM_RX		;ESAM 数据腿为低
	CLR     PIN_SE_IO1		;ESAM 数据腿为低
	
	CLR     PIN_ESAM_RST		;ESAM 复位腿为低
	CLR	Pin_ES_Rst
	CLR	PIN_PWR_LOWIO

	
	;BEEP		
	CLR	PIN_BELL_01
	CLR	PIN_BELL_02
	
	;LED
	;SETB	Pin_Red
	;SETB	Pin_Gre
	;SETB	Pin_Red	
	SETB	Pin_Red	
	
	;BK5823
	SETB 	PIN_BK_CE				
	SETB 	Pin_5823BK_CS				
	SETB 	Pin_5823BK_MISO		
	SETB 	Pin_5823BK_IRQ				
	SETB 	Pin_5823BK_MOSI				
	CLR 	Pin_5823BK_SCLK				
	CLR 	PIN_WAVE_CHANNEL1	
		
	clr	Pin_SW		
	
	RET
;////////////////////////////////////////////////////////////////////////////
_Fun_OBUmain_SysUNSleep:
	
	CALL	_Fun_OBUmain_PinUNSleep
	;RET
	CALL	_FUN_ContactIssue_RELEASE
	;RET
	CALL	start_user			; 原来程序一开始要做的工作，现改成子程序的形式，在微波激活，插卡，拆动前调节器用		
	CLR	REN
	CLR	ES
	
	RET
;////////////////////////////////////////////////////////////////////////////	
_Fun_OBUmain_SysUNSleep02:
	
	CALL	_Fun_OBUmain_PinUNSleep
	CALL	_FUN_ContactIssue_RELEASE
	CALL	start_user02			; 原来程序一开始要做的工作，现改成子程序的形式，在微波激活，插卡，拆动前调节器用	
	CLR	REN
	CLR	ES
	
	RET	
;////////////////////////////////////////////////////////////////////////////
unsleep:


	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;设置 P4.4 为普通 IO 脚
	;设置 P4.5 为普通 IO 脚
	;设置 P4.6 为普通 IO 脚	Pin_522_RST
	
	;推换输出
;	0.3	推换			蜂鸣器01
;	0.2	推换			蜂鸣器02

;	xx	输入			USB充电检测
;	xx	输入			低电压检测
;	3.2	输入			微波唤醒
;	3.3	输入			插卡
;	3.5	输入			拆动
;	xx	输入			接收灵敏度开关
;	1.6	输入[GMS ON]		433 中断
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_Fun_OBUmain_PinUNSleep:
	
	
	
	MOV	A,REG_5412AD_P4SW							;P4.4\P4.5\P4.6设置为普通IO
	ORL	A,#01110000B
	MOV	REG_5412AD_P4SW,A
	
	;MOV	REG_5412AD_spctl,#0d4h				;0dch	;0dfh	
;---	MOV	REG_5412AD_P0M0,#00001100B
	MOV	REG_5412AD_P0M0,#00000100B
	MOV	REG_5412AD_P0M1,#00000001B
	
	MOV	REG_5412AD_P2M0,#00000000B
	MOV	REG_5412AD_P2M1,#00000000B	 	; 低电压 检测（未焊）
;	MOV	REG_5412AD_P2M1,#00000010B	 	; 低电压 检测（焊）
	
	MOV	REG_5412AD_P3M0,#00010000B
	MOV	REG_5412AD_P3M1,#00101100B
	
	MOV	REG_5412AD_P4M0,#00000000B
	MOV	REG_5412AD_P4M1,#00000000B
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;jmp	OBUmain_PinUNSleep_RTCOff
	MOV	R0,#XDATA_RTCMode
		;MOVX	A,@R0
	MOV	DPH,#2
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_RTC_ON
	JNZ	OBUmain_PinUNSleep_RTCOff
	
OBUmain_PinUNSleep_RTCON:
	MOV	REG_5412AD_P1M0,#00000000B
	MOV	REG_5412AD_P1M1,#01000100B      ; MISO 为输入
	
	CLR	PIN_PWR_GSM			;P2.0
	SETB	PIN_UART2_RX
	SETB	PIN_UART2_TX
	;SETB	PIN_Bluetooth_RST
	
	;---CLR	PIN_SE_IO1
	;CLR	PIN_CC1101_Mosi
	
	SETB	Pin_5823BK_IRQ						;BK5823 IRQ低电平有效
	SETB	PIN_BK_CE
	
	JMP	OBUmain_PinUNSleep_RTCSWOver
OBUmain_PinUNSleep_RTCOff:
	
	MOV	REG_5412AD_P1M0,#00000000B	 ;
	MOV	REG_5412AD_P1M1,#00000100B	 	; MISO 为输入(高阻)
	
	SETB	PIN_PWR_GSM				; P2.0
  	CLR	PIN_UART2_TX
	;---CLR	PIN_SE_IO1
	;CLR	PIN_CC1101_MOSI
	;CLR	PIN_Bluetooth_RST
	CLR	PIN_UART2_RX 
	
	SETB	Pin_5823BK_IRQ
	SETB	PIN_BK_CE
	
OBUmain_PinUNSleep_RTCSWOver:	
	SETB	PIN_PWR_SE	
	CLR	Pin_pwrdwn		;[开外围电源]
	SETB	Pin_unfix
	SETB	PIN_card_exist
	SETB	WKO_BK
	SETB	Pin_5823BK_MISO
	
;	RET
;	LCD
;	SETB    Pin_LCD_RST             ;液晶复位腿为低	
;	CLR     Pin_LCD_SDA             ;液晶数据腿为低
;	CLR     Pin_LCD_SCL       	;液晶时钟腿为低
;	SETB    Pin_LCD_CS		;液晶片选腿为低
;	CLR     Pin_LCD_DC 		;液晶命令腿为低
	
	;522
	CLR     Pin_522_RST		;522复位腿为低
	CLR     PIN_522_MOSI		;522 MISO为低
	CLR     Pin_522_SS		;522 SS腿为低
	SETB	PIN_522_MISO
	CLR     PIN_522_SCLK		;522 SCLK腿为低
	
	;ESAM
	SETB    PIN_ESAM_RX		;ESAM 数据腿为低
	SETB	PIN_SE_IO1		
	SETB    PIN_ESAM_RST		;ESAM 复位腿为低
	SETB	Pin_ES_Rst
	;CLR	PIN_ESAM_RST
	
	;低电压
	SETB	PIN_PWR_LOWIO
	
	;COM下载
	SETB	PIN_SOFTSERIALRX
	SETB	PIN_SOFTSERIALTXH
	
	;BEEP
	CLR	PIN_BELL_01
	CLR	PIN_BELL_02
	
	;LED	
	SETB	Pin_Red
	SETB	Pin_Gre	
	
	;5823
	SETB 	PIN_BK_CE
;	CLR	PIN_BK_CE
	SETB 	Pin_5823BK_CS
	SETB 	Pin_5823BK_MISO
	SETB 	Pin_5823BK_IRQ
	SETB 	Pin_5823BK_MOSI
	CLR 	Pin_5823BK_SCLK
	CLR 	PIN_WAVE_CHANNEL1	
	CLR		Pin_SW

	
	
	RET	
;========================================================	
	RSEG	?pr?OBUMAIN?Mater
	USING	0
;-----------------------------------------------------------------
;描述:	OBU 主执行函数
;-----------------------------------------------------------------
AP_start:
		
	MOV	SP,#IDATA_STACK
	MOV	IE,#0
	SETB	IT1				; 程序一开始就是设置下降延触发，不然插卡时，会电平触发
	SETB	IT0
	
	CALL	_FUN_OBUMAIN_CheckMemoryAndEx
	MOV	A,R7
	JZ	OBUMAIN_MASTER_CheckMemoryOver
OBUMAIN_MASTER_CheckMemoryErr:
	;MOV	A,#CONST_STATE_ExMemoryEr
	CALL	_FUN_OBUMAIN_ErrShow03
	;JMP	AP_start	
OBUMAIN_MASTER_CheckMemoryOver:			
	
	;初始化初次上电的标记=0
	;=0非初次上电
	;=0x55初次上电
	MOV	R0,#IDATA_POWUP
	MOV	A,#0
	MOV	@R0,A
	
	;上电判断
	;第一个上电 看门狗
	;=0 看门狗没有工作，空闲
	;=1 看门狗工作，非空闲
	MOV	A,REG_WDT_CONTR
	JB	ACC.3,AP_start_1
	
	;上电复位(拆动未按下，插卡上电)
	;IDATA_POWUP = 55H && Pin_unfix=0(拆卸未按) && PIN_card_exist=0(卡存在)
	JB	Pin_unfix,AP_start_1
	JB	PIN_card_exist,AP_start_1
	
	;看门狗初次上电的标记
	MOV	R0,#IDATA_POWUP
	MOV	A,#55H
	MOV	@R0,A
	
AP_start_1:
	;MOV	REG_WDT_CONTR,#00111111B	; 下载后看门狗有可能喂狗时间变的很短，需要立即设置看门狗喂狗时间
	MOV	SP,#IDATA_STACK
	MOV	IE,#0
	SETB	IT1				; 程序一开始就是设置下降延触发，不然插卡时，会电平触发
	SETB	IT0
	MOV	R0,#IDATA_STACK	- 2		;保留初次插卡上电标示
	
OBUMAIN_MASTER_MEMORYCLR00:
	MOV	@R0,#0
	DJNZ	R0,OBUMAIN_MASTER_MEMORYCLR00	;清内存
	
	SETB	PIN_BK_CE
	CLR	PIN_RED
	CALL	_FUN_HDLC_5830Init		;初始化需作频率校准，寄存器不能直接配置为休眠模式
	SETB	PIN_RED	
	 
	;检查9~18寄存器是否初始化成功
	CALL	_FUN_HDLC_CheckReg9To18
	MOV	A,R7
	JZ	OBUMAIN_MASTER_Checked	
	MOV	A,#CONST_STATE_5823INIER
	CALL	_FUN_OBUMAIN_ErrShow
	JMP	AP_start
	
OBUMAIN_MASTER_Checked:
	 
	MOV	R0,#XDATA_RTCMode
	MOV	A,#CONST_RTC_off
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	CALL	_Fun_OBUmain_PinSleep
	CALL	_FUN_OBUMAIN_INITSYS				; 系统初始化
	
	CLR	IE1
	CLR	IE0
	
;OBUMAIN_MASTER_int:
	;注：P3.5 与 T1 是同一个中断复用，P3.4与T0是同一个中断复用，需要在中断程序区分
	;外部中断0 	[微波唤醒中断] 	使能	下降沿触发
	;外部中断1 	[微波接收中断] 	禁止	XX
	;P3.5		[拆动中断]	使能	电平触发
	;P3.4		[拆动中断]	使能	电平触发
	;定时器 1中断	[定时器1中断]	禁止	XX
	;定时器 0中断	[定时器0中断]	禁止	XX
	;串口 中断	[串口中断]	禁止	XX
	MOV	IE,#0
	MOV	Reg_WakeClk0,#0
		
	;开启 P3.5 中断[拆动中断]	 注：本中断与T1中断复用
	MOV	A,Reg_WakeClk0		
	ORL	A,#00100000B		; 设置P3.5为外部中断脚
	MOV	Reg_WakeClk0,A		; 
	SETB	ET1			; 开启拆动中断
	
	;串口 串断 接收初始化
	CALL	_FUN_ContactIssue_INIT02
	MOV	A,Reg_WakeClk0
	ORL	A,#01000000b;40H
	MOV	Reg_WakeClk0,A
	
	CLR	TI
	CLR	RI
	SETB	REN
	CLR	ES
	
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;CALL	_FUN_TEST_Master
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~		
OBUMAIN_MASTER_MAINSleep:
	
	;MOV	REG_WDT_CONTR,#00111111B
	CALL	_Enter_Sleep_Mode	
	
	SETB	PIN_PWRDWN_LCD		;关液晶
	CLR	RI
	CLR	TI
	CLR	IE0
	CLR	IE1
	CLR	TF0
	CLR	TF1
	CLR	TR0
	CLR	TR1
	
	SETB	pin_gre
	SETB	pin_RED
	
	;-------------------------------;
;	SETB	EX0			; 使能外部中断0
;	SETB	IT0			; 外部中断0，下降沿触发中断
	;外部 中断 01 [插卡中断] 使能	; 下降沿触
	;SETB	EX1			; 使能外部中断0
	;SETB	IT1			; 外部中断0，下降沿触发中断
	;-------------------------------;
	
	MOV	A,Reg_WakeClk0
	ORL	A,#01000000b;40H
	MOV	Reg_WakeClk0,A	
	
	SETB	P3.0
	SETB	P3.1
	
	CLR	A
	SETB	REN
	MOV	IE,A
	
	SETB	ES			; 串口中断
	SETB	EX0			; 使能外部中断0
	SETB	IT0			; 外部中断0，下降沿触发中断

	SETB	EA
	
	NOP
	NOP
	NOP
	NOP
	NOP	
;	CLR	PIN_PWRDWN_LCD
;ASDFSADFDSAFDSF:
;	JMP	ASDFSADFDSAFDSF	

	clr	a
	mov	r2,#3
	;jmp	TEST_SerialTX03_issue
	
	MOV	PCON,#82H
	
	NOP
	NOP
	
	JMP	AP_START
;/////////////////////////////////////////////////////////////////////////	
Int_UART_Point:
	call	_fun_test_display
	jmp	Int_UART_Point
;=========================================================================
;原用户程序开始处
;=========================================================================
start_user:	;原来程序一开始要做的工作，现改成子程序的形式，在微波激活，插卡，拆动前调节器用
	
	;--- 初始化堆栈和内存 ---
	;522 RST 因为复用低电压检测做VCC，要推挽
	;RET
	MOV	R7,#250						; 华大ESAM卡复位要比捷德的短
	CALL	_FUN_LIB_DELAYSIMPLAY 	
	;复位 ESAM 卡，但不接收数据
	CLR	PIN_ESAM_RST	
	MOV	R7,#030H					; 华大ESAM卡复位要比捷德的短
	CALL	_FUN_LIB_DELAYSIMPLAY
	SETB	PIN_ESAM_RST
	MOV	R7,#03
	CALL	_FUN_LIB_DELAY
	
start_user02:
	MOV	R0,#IDATA_STACK
OBUMAIN_MASTER_MEMORYCLR:
	MOV	@R0,#0
	DJNZ	R0,OBUMAIN_MASTER_MEMORYCLR
	
	;生成随机因子
	MOV 	R0,#XDATA_RAND				
	CLR 	A
	MOV 	DPTR,#STR_SYS_OBUID+4
	MOVC 	A,@A+dptr
	RL 	A
	RL 	A
	;MOVX 	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	CALL	_FUN_OBUMAIN_INITSYS				; 系统初始化
	
	MOV	DATA_PowerONTimer,#210
	CLR	A
	
	ORL	A,#00100000B			;设置t1为8位重装载定时器
	ORL	A,#00000001B			;设置t0为16位定时器
	MOV	TMOD,A

	CLR	A
	ORL	A,#00000100B			;TCON.2	INT1中断控制	= 0 电平触发	= 1 边没触发
	ORL	A,#00000001B			;TCON.0	INT0中断控制	= 0 电平触发	= 1 边没触发
	MOV 	TCON,A
	
	RET
;-----------------------------------------------------------------------
;SEG_OBUMAIN_CDACTIVE(附属序段)
;附属:_FUN_OBUMAIN_MASTER
;描述:拆动激活(拆动)
;流程:
;	拆动激活	-> 	显示标签失效	-> 	进入插卡处理流程
;-----------------------------------------------------------------------
SEG_OBUMAIN_CDACTIVE:
	CLR	EA
	CLR	ES
	CLR 	ET1 				;不允许外部中断1	
	
	CALL	_Fun_OBUmain_SysUNSleep
	
 	;对用户卡和ESAM卡做基本复位和选目录操作。
;	MOV	R7,#10				; 50
;	CALL	_FUN_LIB_DELAY			; MCU启动时要加延时，以便电压稳定后再操作卡片	
	CALL	_Func_LCD_INIT			
	
	SETB	BIT_CD_SW			;=0表示未被拆动，=1 被拆动
	SETB 	BIT_ACTIVECARD			;=0 非拆动激活;=1 拆动激活
	CALL	_FUN_OBUMAIN_INITSYS		; 系统初始化
	CALL	_FUN_OBUMain_BASEINIT		;初始化ESAM,用户卡	
;test_current_loop:
;	MOV	REG_WDT_CONTR,#00111111B
;	JMP	test_current_loop
	;MOV	R7,#20
	;CALL	_FUN_LIB_DELAY
	
OBUMAIN_CDACTIVE_SELECT3F00:
	JNB	BIT_ESAM,OBUMAIN_CDACTIVE_DISPLAYMOVE		;没有ESAM时，跳过
	
	;选择ESAM卡的3F00目录
	CLR	BIT_ESAMICC
	SETB	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile				
	
	;--- 减记数器 ---
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	CALL	_FUN_CARDAPP_DECCounter
	MOV	A,R7

OBUMAIN_CDACTIVE_DISPLAYMOVE:					; 显示拆动
	
	;--- 显示 ---	
	JZ	OBUMAIN_CDACTIVE_DISPLAYNCD
OBUMAIN_CDACTIVE_DISPLAYCD:					; 拆完，显示“标签失效”
	CLR	Pin_red
	MOV	R7,#00000010B
	CALL	_FUN_LCD_ICON
	MOV	R7,#DATA_RXBUF + 90
	MOV	DPTR,#STR_UNFIX
	SETB	BIT_CD										;拆完置拆动标记
	JMP	OBUMAIN_CDACTIVE_DISPLAYCDOver
	
OBUMAIN_CDACTIVE_DISPLAYNCD:					;没有拆完，显示“拆卡”
	MOV	R7,#DATA_RXBUF + 90
	MOV	DPTR,#STR_MoveCARD
	CLR	BIT_CD										;未拆完置清拆动标记
	
OBUMAIN_CDACTIVE_DISPLAYCDOver:
	CALL	_FUN_LCD_DisplayExChina	
	setb	Pin_red		;2010-04-21
	CALL	_FUN_OBUMain_CARDPreDeal			; 卡片预处理
	
OBUMAIN_CDACTIVE_REBeaconID:
	;在拆动前收到过bst，则不记当beaconid,而在函数_FUN_OBUMain_CARDPreDeal中根据bit_setmmi来记录
	JB	BIT_BST,OBUMAIN_CDACTIVE_REBeaconIDOver		
	;写卡片信息到Flash中去
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	R7,#XDATA_LastBeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen	
	CALL	_wrflashXR	
	
OBUMAIN_CDACTIVE_REBeaconIDOver:
	SETB 	pin_red
OBUMAIN_CDACTIVE_REBeaconIDOver02:
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	JMP	AP_start
	
;-------------------------------------------------------------------------------------------
;SEG_OBUMAIN_CARDACTIVE(附属序段)
;附属:_FUN_OBUMAIN_MASTER
;描述:插卡激活(插卡处理流程)
;流程:
;插卡	-> 复位卡片
;		Err ->	显示无卡，同时置插卡标记为无 -> 进入微波激活处理流程
;		OK- >	插卡预处理(读0015/0019/0012/0002文件并写入到Flash中去)
;				Err ->	显示无卡或错卡，同时置插卡标记为无 -> 进入微波激活处理流程
;						根据0015第9个字节
;							= 23 表示记账卡->显示0002的内容
;							= 22 表示通行卡->显示通行卡
;								进入插卡激活处理流程
;-------------------------------------------------------------------------------------------
FUN_OBUMAIN_RST:
	MOV	ISP_CONTR,#60H
OBUMAIN_rst_over:
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
	JMP	OBUMAIN_rst_over
;-------------------------------------------------------------------------------------------	
SEG_OBUMAIN_CARDACTIVE:	
;	jmp	OBUMAIN_CARDACTIVE_Start	
	;jmp	AP_start
	
	CALL	_Fun_OBUmain_SysUNSleep
	
	CALL	_FUN_ContactIssue_INITDown
	SETB	P3.1
	SETB	P3.0
	
	CLR	BIT_BUFADDR		;= 0，接收数据到内存； = 1，接收数据到外存
	SETB	BIT_SERIALOVERTIMERX	;=0,没有限制 ; =1有时间限制
	CLR	BIT_VERIFY
	MOV	R7,#DATA_RXBUF
	MOV	R3,#000H
	CALL	_FUN_SERIAL_RXHARD
	;330ms
	
	MOV	A,R3
	JZ	OBUMAIN_CARDACTIVE_Start
	
	XRL	A,#2
	JNZ	OBUMAIN_CARDACTIVE_Start
	
	MOV	R0,#DATA_RXBUF
	MOV	a,@R0
	XRL	A,#07FH
	JNZ	OBUMAIN_CARDACTIVE_Start
	
	MOV	R0,#DATA_RXBUF+1
	MOV	A,@R0
	XRL	A,#07FH
	JNZ	OBUMAIN_CARDACTIVE_Start
	
	JMP	fun_OBUMAIN_rst
	
OBUMAIN_CARDACTIVE_Start:
	
	CALL	_FUN_ContactIssue_Release	
	CALL	_Fun_OBUmain_SysUNSleep
;	MOV	R7,#010H
;	CALL	_FUN_LIB_DELAY		
	CALL	_FUN_OBUMAIN_INITSYS
	SETB	BIT_ACTIVECARD
	CALL	_FUN_OBUMain_BASEINIT	;20	
 	CALL	_FUN_OBUMain_CARDPreDeal ;80  				;预处理
	
OBUMAIN_CARDACTIVE_REBeaconID:
	
	;在拆动前收到过BST，则不记当 beaconid ,而在函数_FUN_OBUMain_CARDPreDeal中根据bit_setmmi来记录
	;---JB	BIT_BST,OBUMAIN_CDACTIVE_REBeaconIDOver		
	JnB	BIT_BST,OBUMAIN_CARDACTIVE_REBeaconID22
	JMP	OBUMAIN_CDACTIVE_REBeaconIDOver
OBUMAIN_CARDACTIVE_REBeaconID22:
	;写卡片信息到Flash中去
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	R7,#XDATA_LastBeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen
	CALL	_wrflashXR
OBUMAIN_CARDACTIVE_REBeaconIDOver:
	
OBUMain_CardInfoDisplay_DisplayInfo:
	
	JB	BIT_INSERTCARD,OBUMain_CardInfoDisplay_ZC
	JMP	OBUMAIN_CARDACTIVE_NoCard
	
OBUMain_CardInfoDisplay_ZC:
	JMP	OBUMAIN_CARDACTIVE_ZC

	JB	BIT_ISContact,OBUMAIN_CARDACTIVE_NZC			; 如果是接触卡，则选 1001，如果是非接卡，则Pro卡才选1001
	JB	BIT_proMF,OBUMAIN_CARDACTIVE_NZC
	;显示 " 逻辑卡 " 
	CALL	_Func_LCD_INIT
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_LoGCard
	CALL	_FUN_LCD_DisplayExChina
	
	JMP	OBUMAIN_CARDACTIVE_beep
	
OBUMAIN_CARDACTIVE_NZC:
	;读出 0015 文件里的分散码
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#4
	CALL	_RDFlashXR
	
	;不是 四川 的卡
	;CB C4 B4 A8
	;JMP	OBUMain_CardInfoDisplay_btVH
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0CBH
	JNZ	OBUMAIN_CARDACTIVE_ZZSC
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0C4H
	JNZ	OBUMAIN_CARDACTIVE_ZZSC
	INC	R0
	
	;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0B4H
	
	JNZ	OBUMAIN_CARDACTIVE_ZZSC
	INC	R0	
		;MOVX	A,@R0	
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0A8H
	JNZ	OBUMAIN_CARDACTIVE_ZZSC
	
	;~~~~~~~~~~调试段~~~~~~~~~~~
	;mov	r7,#33
	;call	_FUN_TEST_checkrtcmode
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~
	JMP	OBUMain_CardInfoDisplay_btVH
OBUMAIN_CARDACTIVE_ZZSC:
	JMP	OBUMAIN_CARDACTIVE_SC			;显示不是四川卡
;///////////////////////////////////////////////////////////////////////////
	;===== 当前 是 四川 的卡时，比对 车牌号 =====
OBUMain_CardInfoDisplay_btVH:
	JB	BIT_ESAMOK,OBUMain_CardInfoDisplay_btVHZZ
	JMP	OBUMAIN_CARDACTIVE_ZC
OBUMain_CardInfoDisplay_btVHZZ:
	
	;=== 读出 0015 文件里的车牌 ===
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L + 28
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#10					;10
	CALL	_RDFlashXR
	
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	
	;读系统信息文件
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF	
	MOV	R4,#01H							;R4		---	文件ID
	MOV	R3,#1	
	MOV	R2,#1BH							;R2		---	Offset
	CALL	_FUN_CARDAPP_ReadBinary	
	MOV	A,R7
	
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	MOV	R0,#XDATA_SC
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	;读出系统信息文件里的车牌1
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 36
	MOV	AR7,#XDATA_HOLD + 10
	MOV	R3,#10
	CALL	_RDFlashXR
			
	;读出系统信息文件里的车牌1
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 56
	MOV	AR7,#XDATA_HOLD + 20
	MOV	R3,#10;8
	CALL	_RDFlashXR
	
	; 读出系统信息文件里的车牌 1
	MOV	DPH,#CONST_FLASH_SYSINFOH		;
	MOV	DPL,#CONST_FLASH_SYSINFOL + 76		;
	MOV	AR7,#XDATA_HOLD + 30			; 24
	MOV	R3,#10					; 8
	CALL	_RDFlashXR
	
	;~~~~~~~~~~~~~~~~~~~~~~~
	;MOV	R0,#XDATA_HOLD	+ 12
	;INC	R0
	;	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR
	;CALL	_fun_test_Display
	;~~~~~~~~~~~~~~~~~~~~~~~	
	PUSH	AR0
	MOV	R0,#XDATA_SC
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	POP	AR0
	JZ	OBUMAIN_CARDACTIVE_ZC
		
	MOV	R2,#0
OBUMAIN_CARDACTIVE_CPStartLOOP:
	INC	R2
OBUMAIN_CARDACTIVE_CP01:
	CJNE	R2,#1,OBUMAIN_CARDACTIVE_CP02
	MOV	R1,#XDATA_HOLD+10
	JMP	OBUMAIN_CARDACTIVE_CP04

OBUMAIN_CARDACTIVE_CP02:
	CJNE	R2,#2,OBUMAIN_CARDACTIVE_CP03	
	MOV	R1,#XDATA_HOLD + 20
	JMP	OBUMAIN_CARDACTIVE_CP04
	
OBUMAIN_CARDACTIVE_CP03:
	MOV	R1,#XDATA_HOLD+30
OBUMAIN_CARDACTIVE_CP04:
	
	MOV	R0,#XDATA_HOLD
	MOV	R3,#10							;8
OBUMAIN_CARDACTIVE_VErrCPLOOP:; 比对 车牌 循环 	
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
	JZ	OBUMAIN_CARDACTIVE_VErrCPLOOPZZ
	JMP	OBUMAIN_CARDACTIVE_CPDif
OBUMAIN_CARDACTIVE_VErrCPLOOPZZ:
	INC	R0
	INC	R1
	DJNZ	R3,OBUMAIN_CARDACTIVE_VErrCPLOOP

OBUMAIN_CARDACTIVE_ZC:
	JB	BIT_INSERTCARD,OBUMAIN_CARDACTIVE_ZCZZ
	JMP	OBUMAIN_CARDACTIVE_CardDis

OBUMAIN_CARDACTIVE_ZCZZ:

;	R7	=0成功,=ff失败
;	R5	=0D导入卡 ; = 0EH 激活卡
	CALL	_FUN_CARDAPP_ISInOrACT
	MOV	A,R7
	JZ	OBUMAIN_CARDACTIVE_CardDisZZ
	JMP	OBUMAIN_CARDACTIVE_CardDis

OBUMAIN_CARDACTIVE_CardDisZZ:
	MOV	A,R5
	XRL	A,#0DH
	JZ	OBUMAIN_CARDACTIVE_GDFXOBU
	
	MOV	A,R5
	XRL	A,#0EH
	jnz	OBUMAIN_CARDACTIVE_03
	jmp	OBUMAIN_CARDACTIVE_ACTIVEOBU
	
OBUMAIN_CARDACTIVE_03:
	JMP	OBUMAIN_CARDACTIVE_CardDis
;----------------------------------------------------------------
;导入卡
;	在确认0015.9 = 0DH 后
;		一般性错误	01	导入失败	STR_InputFail
;		合同号不同	02	非法导入卡	STR_IllegalInputCard
;		使用次数=FFH	03	导入卡失效	STR_InputCardInvalid
;		成功		00	导入成功	STR_InputOk
;		非导入卡	FF
;----------------------------------------------------------------
OBUMAIN_CARDACTIVE_GDFXOBU:
	PUSH	AR5
	CALL	_FUN_CARDAPP_GDFXOBU
	PUSH	AR7
	CALL	_Func_LCD_INIT	
	POP	AR7
	POP	AR5
	
	push	ar0
	CALL	_FUN_OBUMAIN_DR
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LCD_DisplayExChina
	
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	pop	ar7
	
	MOV	A,R7
	JZ	OBUMAIN_CARDACTIVE_GDFXOBUdishv
	JMP	AP_start
	
OBUMAIN_CARDACTIVE_GDFXOBUdishv:
	;选择 ESAM 的 MF 目录,只进行到61
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	OBUMAIN_CARDACTIVE_ReadSeldf01OK
	JMP	OBUMAIN_CARDACTIVE_ReadOver
	
OBUMAIN_CARDACTIVE_ReadSeldf01OK:
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD
	MOV	R4,#9dh							;R4		---	文件ID
	MOV	R3,#1bh							;R3		---	长度
	MOV	R2,#12;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7	
	JZ	OBUMAIN_CARDACTIVE_ReadESAMHTHOK
	JMP	OBUMAIN_CARDACTIVE_ReadOver
	
OBUMAIN_CARDACTIVE_ReadESAMHTHOK:
	;XDATA_HOLD[0~11] 车牌
	;R7   外存车牌
	;R5   翻译后的内存指针
	MOV	R7,#XDATA_HOLD			;8
	MOV	R5,#DATA_RXBUF + 90		;
	mov	R3,#12
	CALL	FUN_LCD_HVTransfer		;
	
	MOV	R7,#DATA_RXBUF + 90 + 1 	 	
	MOV	R5,#1
	
	MOV	R0,#DATA_RXBUF + 90
	MOV	A,@R0
	MOV	R3,A
	CALL	_Func_LCD_Display
	
OBUMAIN_CARDACTIVE_ReadOver:
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	
	JMP	AP_start
;----------------------------------------------------------------
;激活卡
;	在确认0015.9=0EH后
;		一般性错误	04	激活失败	STR_ActiveFail
;		合同号不同	05	非法激活卡	STR_IllegalACTCard
;		使用次数=FFH	06	激活卡失效	STR_ACTCardInvalid
;		成功		00	激活成功	STR_ActiveOK
;		非激活卡	FF
;----------------------------------------------------------------
OBUMAIN_CARDACTIVE_ACTIVEOBU:
	
	PUSH	AR5
	CALL	_FUN_CARDAPP_ACTIVEOBU
	PUSH	AR7
	CALL	_Func_LCD_INIT
	POP	AR7
	POP	AR5
	
	CALL	_FUN_OBUMAIN_DR

	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LCD_DisplayExChina

	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	;选择 ESAM 的 MF 目录,只进行到61
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	OBUMAIN_CARDACTIVE_ACTIVESeldf01OK
	JMP	OBUMAIN_CARDACTIVE_ACTIVEOver
	
OBUMAIN_CARDACTIVE_ACTIVESeldf01OK:
	CLR	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_HOLD
	MOV	R4,#9dh							;R4		---	文件ID
	MOV	R3,#1bh							;R3		---	长度
	MOV	R2,#12;04;03
	CALL	_FUN_CARDAPP_ReadBinary02
	MOV	A,R7
	JZ	OBUMAIN_CARDACTIVE_ACTIVEESAMHTHOK
	JMP	OBUMAIN_CARDACTIVE_ACTIVEOver
	
OBUMAIN_CARDACTIVE_ACTIVEESAMHTHOK:	
	;R7   外存车牌
	;R5   翻译后的内存指针
	MOV	R7,#XDATA_HOLD			;8
	MOV	R5,#DATA_RXBUF + 90		;
	mov	R3,#12
	CALL	FUN_LCD_HVTransfer		;
	
	MOV	R7,#DATA_RXBUF + 90 + 1
	MOV	R5,#1
	
	MOV	R0,#DATA_RXBUF + 90
	MOV	A,@R0
	MOV	R3,A
	CALL	_Func_LCD_Display
	
OBUMAIN_CARDACTIVE_ACTIVEOver:
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	JMP	AP_start
	
;----------------------------------------------------------------
	;非导入、激活卡
OBUMAIN_CARDACTIVE_CardDis:
	CALL	_FUN_GSM_Insert						;=0表示 从ESAM卡导出数据到用户卡成功
	
;mov	A,#30
;clr	A
;mov	C,BIT_USEROK
;mov	Acc.0,C
;call	_fun_test_display
	
	;当预读用户卡失败后，重做预读
	;如果还出错则不向下显示
	jb	BIT_USEROK,OBUMAIN_CARDACTIVE_disandpowerdown
	;call	_FUN_OBUMAIN_PreSleep
	;jb	BIT_USEROK,OBUMAIN_CARDACTIVE_disandpowerdown
	CALL	_Func_LCD_INIT
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_ErrCARD
	CALL	_FUN_LCD_DisplayExChina
	mov	r7,#200
	call	_fun_lib_delay
	mov	r7,#100
	call	_fun_lib_delay
	JMP	ap_start	
OBUMAIN_CARDACTIVE_disandpowerdown:
	
	;保存导出是否成功状态 = 0 表成功
	MOV	A,R7
	;~~~~~~~~~~~~~
	;国标跳过导出功能
	MOV	A,#0FFH	
	;~~~~~~~~~~~~~	
	MOV	R0,#XDATA_LoadCellToUser
	
		;MOVX	@R0,A
	MOV 	DPH,#1
	MOV 	DPL,R0
	MOVX 	@DPTR,A
	
	;=== 低电压 === 
	setb	PIN_PWR_LOWIO
	nop
	nop
	nop
	nop
	
	JB	PIN_PWR_LOWIO,OBUMAIN_CARDACTIVE_LOWVO
	;关外围
	clr	PIN_ESAM_RST	
	clr	Pin_522_RST
	setb	Pin_pwrdwn	
	CALL	_Func_LCD_INIT	
	;MOV	R7,#250
	;CALL	_FUN_LIB_DELAY
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_LOWVo
	CALL	_FUN_LCD_DisplayExChina
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
OBUMAIN_CARDACTIVE_LOWVO:
	
	;=== 关外围 ===
	CLR	PIN_ESAM_RST	
	CLR	Pin_522_RST
	SETB	Pin_pwrdwn
	
	CALL	_FUN_OBUMain_CardInfoDisplay02
	
	;mov	a,#36
	;call	_fun_test_display
	
	SETB	pin_red
	SETB	pin_gre
	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY
OBUMAIN_CARDACTIVE_Insert:
	
	MOV	R0,#XDATA_LoadCellToUser
	;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	JNZ	OBUMAIN_CARDACTIVE_Insert02	
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_ReWrOK
	CALL	_FUN_LCD_DisplayExChina	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	
OBUMAIN_CARDACTIVE_Insert02:
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;=1不启用 =0启用
	MOV	A,#CONST_INPUT_ISEnable
	JNZ	OBUMAIN_CARDACTIVE_ZCKQ02
	MOV	DPH,#CONST_FLASH_0019H
	MOV	DPL,#CONST_FLASH_0019L + 13
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#1
	CALL	_RDFlashXR	
	MOV	R0,#XDATA_HOLD
	;入口
	;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	XRL	A,#CONST_ETC_INPUT
	JZ	OBUMAIN_CARDACTIVE_ZCKQ
	;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	
	XRL	A,#CONST_MTC_INPUT
	JZ	OBUMAIN_CARDACTIVE_ZCKQ
OBUMAIN_CARDACTIVE_ZCKQ02:
	JMP	OBUMAIN_CARDACTIVE_ZCNOKQ
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OBUMAIN_CARDACTIVE_ZCKQ:
	MOV 	R7,#80
	CALL	_FUN_LIB_BEEP	;响铃
	MOV 	R7,#100
	CALL	_FUN_LIB_DELAY	;响铃
	MOV 	R7,#80
	CALL	_FUN_LIB_BEEP	;响铃
	JMP	OBUMAIN_CARDACTIVE_ZCKQOVER

OBUMAIN_CARDACTIVE_ZCNOKQ:
	MOV 	R7,#100
	CALL	_FUN_LIB_BEEP	;响铃

OBUMAIN_CARDACTIVE_ZCKQOVER:
	JMP	OBUMain_BEEP_OVER
	
;-----------------------------------------------------------------------	
OBUMAIN_CARDACTIVE_CPDif:
	PUSH	AR0
	MOV	R0,#XDATA_SC
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	POP	AR0
	MOV	B,R2
	XRL	A,B
	;---JNZ	OBUMAIN_CARDACTIVE_CPStartLOOP
	JZ	OBUMAIN_CARDACTIVE_HVDIF
	JMP	OBUMAIN_CARDACTIVE_CPStartLOOP
OBUMAIN_CARDACTIVE_HVDIF:	
	;~~~~~~~~~~~~~~~~~~~~~~~
	;mov	r0,#XDATA_HOLD+12
	;	;MOVX	A,@R0
	;MOV	DPH,#1
	;MOV	DPL,R0
	;MOVX	A,@DPTR
	;mov	a,r3
	;MOV	A,#15
	;call	_fun_test_Display
	;~~~~~~~~~~~~~~~~~~~~~~~
	;显示车牌不一致
	CALL	_Func_LCD_INIT	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_VHDif
	CALL	_FUN_LCD_DisplayExChina	
OBUMAIN_CARDACTIVE_beep:
	CALL	_FUN_GSM_Insert	
	JMP	OBUMain_BEEP_OVER 
	CLR 	Pin_Pwrdwn	
	SETB    PIN_ESAM_RX		;ESAM 数据腿为低

	MOV	R6,#1;3
	MOV	R3,#1

OBUMAIN_CARDACTIVE_BEEPLOOP:	
	MOV	R7,#20
	PUSH	AR6
	PUSH	AR3
	CALL	_FUN_LIB_BEEP
	POP	AR3
	POP	AR6
	DJNZ	R3,OBUMAIN_CARDACTIVE_BEEPLOOP
	DJNZ	R6,OBUMAIN_CARDACTIVE_BEEPLOOP

OBUMAIN_CARDACTIVE_overov:
	JMP	OBUMAIN_CARDACTIVE_DISOVER	

OBUMAIN_CARDACTIVE_SC:;非四川卡		
	;显示"非四川卡"
	CALL	_Func_LCD_INIT		
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_IsNotSC
	CALL	_FUN_LCD_DisplayExChina				
	JMP	OBUMAIN_CARDACTIVE_beep

OBUMAIN_CARDACTIVE_KPCW:;“卡片错误”
	;显示"“卡片错误"
	CALL	_Func_LCD_INIT	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_ErrCARD
	CALL	_FUN_LCD_DisplayExChina	
	JMP	OBUMAIN_CARDACTIVE_beep

OBUMAIN_CARDACTIVE_NoCard:	
	;显示"非四川卡"
	CALL	_Func_LCD_INIT	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_NOCARD
	CALL	_FUN_LCD_DisplayExChina	

OBUMAIN_CARDACTIVE_OVER:
	JMP	OBUMAIN_CARDACTIVE_DISOVER
	;--- 显示卡信息 ---
OBUMAIN_CARDACTIVE_DISOVER:
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY		
	JMP	AP_start

;-----------------------------------------------------------------------
;SEG_OBUMAIN_WAVEACTIVE(附属序段)
;附属:_FUN_OBUMAIN_MASTER
;描述:微波激活
;流程描述：
;	接收 BST
;	初始化卡片
;	发送 VST
;	接收 DSRC信号	<------------------ |
;		专用指令->重发------------> |
;		非专用指令	  	    |
;	       		N 位没有变--->重发->|
;		根据 ActioneType 做相应处理   |
;		发送响应数据到RSU	    |
;		      |___________________> |
;-----------------------------------------------------------------------
OBUMAIN_WAVEACTIVENOCARD_DEAL:
	MOV	DPH,#CONST_FALSH_PREFlag03H
	MOV	DPL,#CONST_FALSH_PREFlag03L
	MOV	AR7,#XDATA_TXBUF
	MOV	R3,#1
	CALL	_RDFlashXR
	; 验证 上回预处理是否做成功,如果没有则要做一次预处理
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_SYS_AA
	
OBUMAIN_WAVEACTIVENOCARD_YD:
	CALL	_Fun_OBUmain_SysUNSleep
	CLR	REN
	CLR	ES
	;MOV	R7,#04						; 5;50
	;CALL	_FUN_LIB_DELAY					; MCU启动时要加延时，以便电压稳定后再操作卡片
	CALL	_FUN_OBUMain_BASEINIT

	CALL	_FUN_OBUMAIN_PrePu
	;验证上回预处理是否做成功,如果没有则要做一次预处理
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0dFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
	JMP	OBUMAIN_WAVEACTIVE_GETBST
;-------------------------------------------------
;微波唤醒外部中断转来入口 	
;-------------------------------------------------
	
SEG_OBUMAIN_WAVEACTIVE:
	
	CLR	Pin_pwrdwn			;[外围电源]
	
	MOV	R7,#1
	CALL	_Power_Up
 	MOV	R7,#1
	CALL	Tx_Carrier_En		
	
	SETB 	PIN_WAVE_CHANNEL1
	CLR	PIN_PWRDWN_LCD

	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
		
	clr	PIN_WAVE_CHANNEL1
	setb	PIN_PWRDWN_LCD
	CALL	_Enter_Sleep_Mode	
	CLR	RI
	CLR	TI
	CLR	IE0
	CLR	IE1
	CLR	TF0
	CLR	TF1
	CLR	TR0
	CLR	TR1
	
 	SETB	ES
 	SETB	EX0	
	SETB	EA
	
OBUMAIN_WAVEACTIVE_OVERXXXX:
	JMP	OBUMAIN_WAVEACTIVE_OVERXXXX
	
	;call	_fun_test_display
	;=== 测试段[开背光，响一下] ===
	;CLR	PIN_PWRDWN_LCD
	
	;MOV	REG_5412AD_P0M0,#00001100B
	;MOV	REG_5412AD_P0M1,#00000000B
	
	;MOV	R7,#100
	;CALL	_fun_lib_beep
	CLR	Pin_pwrdwn			;[外围电源]	
	SETB    PIN_ESAM_RX		;ESAM 数据腿为低

	CLR	PIN_GRE
	CLR	BIT_INITCard
	CLR	REN
	CLR	ES
	
	MOV	R7,#1
	CALL	Rx_En
	MOV	R0,#XDATA_TOTALNUML
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	DEC	R0			;[1]
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	;跳过 255 秒限制
	;CLR	PIN_ESAM_RST
	;MOV	R7,#030H			; 华大ESAM卡复位要比捷德的短
	;CALL	_FUN_LIB_DELAYSIMPLAY	
	
;	MOV	R7,#20
;	CALL	_FUN_LIB_DELAY
;
;	SETB	PIN_ESAM_RST	
;	SETB	PIN_ESAM_RX
	
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	AR7,#XDATA_LastBeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen
	CALL	_RDFlashXR	
	
	MOV	DPH,#CONST_FLASH_LASTCARDH
	MOV	DPL,#CONST_FLASH_LASTCARDL
	MOV	AR7,#DATA_RXBUF
	MOV	R3,#1
	CALL	_RDFlash
;SETB	PIN_ESAM_RST
	
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	MOV	C,ACC.0
	MOV	BIT_ISContact,C	;接触卡=1，还是非接触卡=0	
	MOV	C,ACC.1
	MOV	BIT_ProMF,C
	mov	C,PIN_card_exist
	cpl	C
	mov	BIT_INSERTCARD,C
	
;clr	a
;mov	c,BIT_INSERTCARD
;mov	acc.0,c
;call	_fun_test_display	
	
	;唤配检查低电压 ,没有焊比较器时，跳过
OBUMAIN_WAVEACTIVE_VolNormal:
	jb	BIT_INSERTCARD,OBUMAIN_WAVEACTIVE_PREss
	jmp	OBUMAIN_WAVEACTIVENOCARD_DEAL
OBUMAIN_WAVEACTIVE_PREss:
	JNB	BIT_ProMF,OBUMAIN_WAVEACTIVE_PREPRE
OBUMAIN_WAVEACTIVE_PRE:
	
	;---读取 预处理 标记 ---
	MOV	DPH,#CONST_FALSH_PREFlagH
	MOV	DPL,#CONST_FALSH_PREFlagL
	MOV	AR7,#XDATA_TXBUF
	MOV	R3,#1
	CALL	_RDFlashXR
	
	;验证上回预处理是否做成功,如果没有则要做一次预处理
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_SYS_PREFlag
	JZ	OBUMAIN_WAVEACTIVE_PRE02
	
OBUMAIN_WAVEACTIVE_PREPRE:
	
	CALL	_Fun_OBUmain_SysUNSleep
	CLR	REN
	CLR	ES
;	MOV	R7,#4						; 5;50
;	CALL	_FUN_LIB_DELAY					; MCU启动时要加延时，以便电压稳定后再操作卡片
	CALL	_FUN_OBUMain_BASEINIT
	
	CALL	_FUN_OBUMAIN_PrePu
	;~~~~~ 调用测试函数 ~~~~~
	;MOV	A,#16
	;CALL	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~	
	;选择回 DF01 文件
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0dFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile		
	JMP	OBUMAIN_WAVEACTIVE_GETBST
	;--- 读取预处理标记01(看预处理标记是否成功) ---	
OBUMAIN_WAVEACTIVE_PRE02:	
	MOV	DPH,#CONST_FALSH_PREFlag02H
	MOV	DPL,#CONST_FALSH_PREFlag02L
	MOV	AR7,#XDATA_TXBUF
	MOV	R3,#1
	CALL	_RDFlashXR
	
	;验证上回预处理是否做成功,如果没有则要做一次预处理
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_SYS_AA
	JZ	OBUMAIN_WAVEACTIVE_GETBST	; 
	
	CALL	_Fun_OBUmain_SysUNSleep
	CLR	REN
	CLR	ES
;	MOV	R7,#4						; 5;50
;	CALL	_FUN_LIB_DELAY					; MCU启动时要加延时，以便电压稳定后再操作卡片				
	CALL	_FUN_OBUMain_BASEINIT	
	CALL	_FUN_OBUMAIN_PrePu
	;选择回DF01文件
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0dFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
		
	JMP	OBUMAIN_WAVEACTIVE_GETBST
OBUMAIN_WAVEACTIVE_PRE03:
	JNB	BIT_INSERTCARD,OBUMAIN_WAVEACTIVE_GETBST
	
	;读卡片0019数据到外存
	SETB	BIT_ESAMICC						; 当前对用户卡操作
	SETB	BIT_GETRESULT						; XXX
	MOV	R7,#DATA_RXBUF						; R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF						; 
	MOV	R4,#19H							; R4		---	文件 ID
	MOV	R3,#CONST_Flash_0019Len					; R3		---	长度
	MOV	R2,#1
	CALL	_FUN_CARDAPP_ReadRecord		

	;读flash 0019 数据到内存
	MOV	DPH,#CONST_FLASH_0019H
	MOV	DPL,#CONST_FLASH_0019L
	MOV	R7,#DATA_RXBUF
	MOV	R3,#CONST_Flash_0019Len
	CALL	_rdflash
	
	;判断卡片中的0019与预读的信息是否相同
	MOV	R3,#CONST_Flash_0019Len
	MOV	R0,#XDATA_TXBUF
	MOV	R1,#DATA_RXBUF
WAVEACTIVE_PRE03_LOOP:
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	MOV	B,A
	MOV	A,@R1
	XRL	A,B
	JNZ	WAVEACTIVE_PRE03_PREDeal
	INC	R1
	INC	R0
	DJNZ	R3,WAVEACTIVE_PRE03_LOOP
	
	JMP	OBUMAIN_WAVEACTIVE_GETBST				;OBUMAIN_WAVEACTIVE_GETBST	
WAVEACTIVE_PRE03_PREDeal:
	
	;---CALL	_FUN_OBUMain_CARDPreDeal				;做卡片预处理
	call	_FUN_OBUMAIN_PrePu
	;选择回DF01文件
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0dFH
	MOV	R2,#001H
	CALL	_FUN_CARDAPP_SelectFile
	
OBUMAIN_WAVEACTIVE_GETBST:
;2ms	
	
	;本次无卡时，建立预读标记
	JB	BIT_INSERTCARD,OBUMAIN_WAVEACTIVE_ZLYD
	
	;--- 写入预处理成功标记 02 --- 
	MOV	R0,#XDATA_TXBUF
	MOV	A,#CONST_SYS_55
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	DPH,#CONST_FALSH_PREFlag02H
	MOV	DPL,#CONST_FALSH_PREFlag02L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#2
	CALL	_wrflashXR
	
OBUMAIN_WAVEACTIVE_ZLYD:	
;部份OBU不可靠
;	SETB	PIN_ESAM_RST	
;	SETB	PIN_ESAM_RX
	
	MOV	IE,#10001100b
	CALL	_FUN_HDLC_RX
	
;	mov	r0,#XDATA_CELLID
;	movx	a,@r0
	
;mov	a,DATA_DSRCRXLEN	
;mov	a,#2
;call	_fun_test_display		

;	SETB	PIN_ESAM_RST	
;	SETB	PIN_ESAM_RX
	
	;读取 System Info  拆卸位(第27个字节)
	;放在这里读，重要的原因是，上电时需延时，所以可以省时。
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 26
	MOV	AR7,#XDATA_FIX
	MOV	R3,#001
	CALL	_RDFlashXR
	
	MOV	R1,#XDATA_FIX
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ANL	A,#0FH
	
	JZ	OBUMAIN_WAVEACTIVE_Tampered
	CLR	BIT_CD
	JMP	OBUMAIN_WAVEACTIVE_TamperedOver
	
OBUMAIN_WAVEACTIVE_Tampered:
	SETB	BIT_CD
OBUMAIN_WAVEACTIVE_TamperedOver:		
		
;1	;如果接收到的 不是 专用 信号，则 重新 接收
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_GETBST
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_GETBST
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_GETBST
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH	
	JNZ	OBUMAIN_WAVEACTIVE_GETBST


	CLR	Pin_GRE	;设置绿灯亮	
OBUMAIN_WAVEACTIVE_RXBST:
	;表示收到过 BST
	SETB	BIT_BST
	CLR	TR0		;禁止T0
	CLR	ET0		;禁止T0使能
	
	;记录DSRC接收长度
	MOV	A,R3
	PUSH	AR0
	MOV	R0,#DATA_DSRCRXLEN
	MOV	@R0,A
	POP	AR0
	
	;255 秒限制
	;--- 判断上回交易成功后的天线ID与本次的是否一样，如果一样，则进一步判断是否超过255秒的限制 ---
	MOV	R1,#DATA_RXBUF + 8			;BeaonID
	MOV	R0,#XDATA_LastBeaconID			;XDATA_BeaconID
	MOV	R3,#4
OBUMAIN_WAVEACTIVE_BeaconID:				;判断天线ID是否一样
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,@R1
	JNZ	OBUMAIN_WAVEACTIVE_SendVST		;天线ID不同，则向下执行
	INC	R1
	INC	R0
	DJNZ	R3,OBUMAIN_WAVEACTIVE_BeaconID
	
	;判断两次交易间隔是否大于 CONST_SYS_TradeConfine 秒
	MOV	R7,#XDATA_LastBeaconID+4;XDATA_UnixTime			;上一次交易成功后记录的 unix time	
	MOV	R5,#DATA_RXBUF + 12			;本次unix time
	MOV	R3,#CONST_SYS_TradeConfine		;秒数差
	CALL	_FUN_LIB_CompareTime
	JNC	OBUMAIN_WAVEACTIVE_SendVST		;天线ID相同，时间大于上限，则向下执行	
	JMP	AP_start
	
OBUMAIN_WAVEACTIVE_SendVST:
	
	;---只是做卡片的 基本 复位，不预处理(esam 复位信息可以不接收)
	CALL	_FUN_LIB_RANDDELAY	;随机延
	MOV	a,r3
	MOV	r0,#XDATA_VSTDELAY
	
	;MOVX	@R0,A
	MOV 	DPH,#1
	MOV 	DPL,R0
	MOVX 	@DPTR,A
	
	;加 400US
	CALL	_FUN_DSRC_VST				;组织VST发送数据绶冲
	CALL	_FUN_HDLC_CHANGECHANNEL			;改发射信道
	CALL 	_FUN_HDLC_TX
	
	;CLR	BIT_CKXT
	;MOV	A,#34
	;CALL	_fun_test_display
	
	JB	BIT_INITCard,OBUMAIN_WAVEACTIVE_txone
	CLR	EA
	;---CALL	_Fun_OBUmain_SysUNSleep02
	CLR	A
	MOV	C,BIT_Cellinfo
	MOV	ACC.0,C
	;---CLR	BIT_ISCell
	PUSH	ACC
	CALL	_Fun_OBUmain_SysUNSleep02
	POP	ACC
	MOV	C,ACC.0
	MOV	BIT_Cellinfo,C
	
	CLR	REN
	CLR	ES	
	
;MOV	R7,#1
;CALL	_fun_lib_delay
	
	MOV	r0,#XDATA_VSTDELAY	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	JNZ	OBUMAIN_WAVEACTIVE_ovdelay
	MOV	R7,#1
	CALL	_fun_lib_delay
	;CALL	_FUN_TEST_DISPLAY
OBUMAIN_WAVEACTIVE_ovdelay:
	
	;扫esam rx 1MS = 16
	MOV	R7,#32
	MOV	R6,#191
OBUMAIN_WAVEACTIVE_spanesamrst:
	JB	PIN_ESAM_RX,OBUMAIN_WAVEACTIVE_spanesamrstH	
	djnz	r6,OBUMAIN_WAVEACTIVE_spanesamrst
	mov	r6,#191
	djnz	r7,OBUMAIN_WAVEACTIVE_spanesamrst
	
	;--- ESAM 位失败，重复位---
;	CLR	PIN_ESAM_RST
;	MOV	R7,#030H					; 华大 ESAM 卡复位要比捷德的短
;	CALL	_FUN_LIB_DELAYSIMPLAY
;	SETB	PIN_ESAM_RST
		
;	MOV	R7,#3
;	CALL	_FUN_LIB_DELAY
	
;	JMP	OBUMAIN_WAVEACTIVE_spanesamrstOV
	
	;为高后，200US，才认为复位完成
OBUMAIN_WAVEACTIVE_spanesamrstH:
	
	MOV	R6,#254	
OBUMAIN_WAVEACTIVE_spanesamrstHH:
	JNB	PIN_ESAM_RX,OBUMAIN_WAVEACTIVE_spanesamrst
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
;	NOP
;	NOP
	mov	r7,#6
	djnz	r7,$
	djnz	r6,OBUMAIN_WAVEACTIVE_spanesamrstHH
;	
;OBUMAIN_WAVEACTIVE_spanesamrstOV:


;________________________________________________________________________
	CALL	_FUN_OBUMain_BASEINIT02
OBUMAIN_WAVEACTIVE_txone:
	jnb	BIT_Cellinfo,OBUMAIN_WAVEACTIVE_txtwo
	call	GSM_SerialINTRX_RXRight
OBUMAIN_WAVEACTIVE_txtwo:
	
	;唤配检查低电压 ,没有焊比较器时，跳过
	;JMP	OBUMAIN_WAVEACTIVE_VolNormal	
	setb	PIN_PWR_LOWIO
	nop
	nop
	nop
	nop
	
	JB	PIN_PWR_LOWIO,OBUMAIN_WAVEACTIVE_HDLCTX01OVER
	mov	R7,#1
	call	_fun_lib_delay
	JB	PIN_PWR_LOWIO,OBUMAIN_WAVEACTIVE_HDLCTX01OVER
	
	CALL	_Func_LCD_INIT
	;MOV	R7,#250
	;CALL	_FUN_LIB_DELAY
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_LOWVo
	CALL	_FUN_LCD_DisplayExChina
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY
OBUMAIN_WAVEACTIVE_HDLCTX01OVER:
OBUMAIN_WAVEACTIVE_LOOP:
	
	;接收 DSRC 信号
	MOV	R7,#DATA_RXBUF	
	JB	BIT_SETMMI,OBUMAIN_WAVEACTIVE_SETMMIEA
	MOV	IE,#10001100b
	CALL 	_FUN_HDLC_RX
	JMP	OBUMAIN_WAVEACTIVE_NOEAOV
OBUMAIN_WAVEACTIVE_SETMMIEA:
	MOV	IE,#10000010B
	CALL	_FUN_HDLC_RXSetMMI
OBUMAIN_WAVEACTIVE_NOEAOV:
	
	;+++CPL	pin_gre
	;如果接收到的是专用信号，则重发
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_NotBroadCast 	;非广播地址
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_NotBroadCast 	;非广播地址
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_NotBroadCast 	;非广播地址
	INC	R0
	MOV	A,@R0
	XRL	A,#0FFH
	JNZ	OBUMAIN_WAVEACTIVE_NotBroadCast 	;非广播地址
	
OBUMAIN_WAVEACTIVE_BroadCast:				;广播地址
	;接收到 N 次 BST 就休眠
	MOV	R0,#XDATA_BSTNUM
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	INC	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	JB	BIT_ISRXNB,OBUMAIN_WAVEACTIVE_bst100	
OBUMAIN_WAVEACTIVE_bst10:
	CJNE	A,#CONST_BSTLIMIT,$+3
	JMP	OBUMAIN_WAVEACTIVE_10Ov
OBUMAIN_WAVEACTIVE_bst100:
	CJNE	A,#CONST_BSTLIMIT02,$+3
OBUMAIN_WAVEACTIVE_10Ov:
	JC	OBUMAIN_WAVEACTIVE_BroadCastov
	JNB	BIT_SETMMI,OBUMAIN_WAVEACTIVE_BSTOVER
	CALL	_FUN_OBUMAIN_PreSleep
OBUMAIN_WAVEACTIVE_BSTOVER:
	mov	r7,#20
	call	_fun_lib_delay
	JMP	AP_start
OBUMAIN_WAVEACTIVE_BroadCastov:
	;255 秒限制
	;--- 判断上回交易成功后的天线ID与本次的是否一样，如果一样，则进一步判断是否超过255秒的限制 ---
	MOV	R1,#DATA_RXBUF + 8			;BeaonID
	MOV	R0,#XDATA_LastBeaconID;XDATA_BeaconID
	MOV	R3,#4
OBUMAIN_WAVEACTIVE_BeaconID2:				;判断天线ID是否一样
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,@R1
	JNZ	OBUMAIN_WAVEACTIVE_SendVST2		;天线ID不同，则向下执行
	INC	R1
	INC	R0
	DJNZ	R3,OBUMAIN_WAVEACTIVE_BeaconID2
	
	;判断两次交易间隔是否大于 CONST_SYS_TradeConfine 秒
	MOV	R7,#XDATA_LastBeaconID + 4;XDATA_UnixTime			;上一次交易成功后记录的 unix time	
	MOV	R5,#DATA_RXBUF + 12			;本次unix time
	MOV	R3,#CONST_SYS_TradeConfine		;秒数差
	CALL	_FUN_LIB_CompareTime
	JNC	OBUMAIN_WAVEACTIVE_SendVST2		;天线ID相同，时间大于上限，则向下执行	
	jmp	AP_start
OBUMAIN_WAVEACTIVE_SendVST2:
	;表示已经收到过非广播地址，则此时，再收到广播则不做响应，进入休眠	
	JB	BIT_ISRXNB,OBUMain_WAVEACTIVE_AgainVST
OBUMAIN_WAVEACTIVE_SLEEP:
	;+++ SETB	PIN_GRE 
	JMP	OBUMAIN_WAVEACTIVE_LOOP		; _FUN_OBUMAIN_MASTER
OBUMain_WAVEACTIVE_AgainVST:	
OBUMain_WAVEACTIVE_AgainVSTCON:	
OBUMain_WAVEACTIVE_PPS:
	
	CALL	_FUN_LIB_RANDDELAY				; 随机延时
	CALL	_FUN_DSRC_VST					;组织VST发送数据绶冲
	CALL	_FUN_HDLC_CHANGECHANNEL		;改发射信道
	CALL 	_FUN_HDLC_TX
	
	JNB	BIT_Cellinfo,OBUMAIN_WAVEACTIVE_txtwo02
	JB	BIT_HaveRecordCellID,OBUMAIN_WAVEACTIVE_txtwo02;已经记录的，则不再记录
	CALL	GSM_SerialINTRX_RXRight
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OBUMAIN_WAVEACTIVE_txtwo02:
	JMP	OBUMAIN_WAVEACTIVE_LOOP				;重新等待接收DSRC数据
	
OBUMAIN_WAVEACTIVE_NotBroadCast:   				;非广播地址
	;判断当前通讯是否针对本OBU,如果不是，则重新接收DSRC信号
	MOV	R0,#DATA_RXBUF
	MOV	R1,#DATA_OBUID
	MOV	A,@R0
	XRL	A,@R1
	JZ	OBUMAIN_WAVEACTIVE_BroadCast00
	JMP	OBUMAIN_WAVEACTIVE_LOOP
OBUMAIN_WAVEACTIVE_BroadCast00:		
	INC	R0
	INC	R1
	MOV	A,@R0
	XRL	A,@R1
	JZ	OBUMAIN_WAVEACTIVE_BroadCast01
	JMP	OBUMAIN_WAVEACTIVE_LOOP
OBUMAIN_WAVEACTIVE_BroadCast01:		
	INC	R0
	INC	R1
	MOV	A,@R0
	XRL	A,@R1	
	JZ	OBUMAIN_WAVEACTIVE_BroadCast02
	JMP	OBUMAIN_WAVEACTIVE_LOOP
OBUMAIN_WAVEACTIVE_BroadCast02:			
	INC	R0
	INC	R1
	MOV	A,@R0
	XRL	A,@R1
	JZ	OBUMAIN_WAVEACTIVE_BroadCast03
	JMP	OBUMAIN_WAVEACTIVE_LOOP
OBUMAIN_WAVEACTIVE_BroadCast03:			
	MOV	R0,#XDATA_BSTNUM
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;+++ SETB	pin_gre
	MOV	R1,#DATA_RXBUF + CONST_DSRC_LLCCTRL	;取LLC控制域数据
	MOV	A,@R1
	
	JNB	BIT_ISRXNB,OBUMAIN_WAVEACTIVE_SecondRX	;=1 表示未收到过非广播地址 =0 表示已经收到过非广播地址
OBUMAIN_WAVEACTIVE_FristRX:	;第一次收到非广播地址
	CLR	BIT_ISRXNB
	MOV	C,ACC.7
	MOV	BIT_N,C		;记录N位
	
	;--- 写入预处理成功标记02 --- 
	MOV	R0,#XDATA_TXBUF
	MOV	A,#CONST_SYS_55
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	INC	R0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A			
	MOV	DPH,#CONST_FALSH_PREFlag02H
	MOV	DPL,#CONST_FALSH_PREFlag02L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#2
	CALL	_wrflashXR	
	
	JMP	OBUMAIN_WAVEACTIVE_ActionType
OBUMAIN_WAVEACTIVE_SecondRX:						;第二次收到非广播地址
	MOV	R0,#DATA_RXBUF + CONST_DSRC_ACTION			;ActionType;取LLC控制域数据
	MOV	A,@R0
	
	XRL	A,#60H
	JNZ	OBUMAIN_WAVEACTIVE_ZC01

	MOV	R0,#DATA_RXBUF + 9;CONST_DSRC_ACTIONTYPE			;ActionType;取LLC控制域数据	
	MOV	A,@R0
	JNZ	OBUMAIN_WAVEACTIVE_ZC01
	JB	BIT_SETMMI,OBUMAIN_WAVEACTIVE_OVERZZ
	JMP	AP_start
OBUMAIN_WAVEACTIVE_OVERZZ:						;收到SETMMI，收到Event
	JMP	OBUMAIN_WAVEACTIVE_OVER
OBUMAIN_WAVEACTIVE_ZC01:	
	MOV	R1,#DATA_RXBUF + CONST_DSRC_LLCCTRL	;取LLC控制域数据
	MOV	A,@R1	
	JNB	ACC.7,OBUMAIN_WAVEACTIVE_NBITLOW
OBUMAIN_WAVEACTIVE_NBITHIGH:
	JNB	BIT_N,OBUMAIN_WAVEACTIVE_NBITOVER
	JMP	OBUMAIN_WAVEACTIVE_DSRCSENDOLD
OBUMAIN_WAVEACTIVE_NBITLOW:
	JB	BIT_N,OBUMAIN_WAVEACTIVE_NBITOVER
OBUMAIN_WAVEACTIVE_DSRCSENDOLD:   					;N位没有改变时，重发DSRC数据	
mov r7,#0
djnz r7,$	;43us
djnz r7,$	;43us	
	CPL	PIN_RED	
	;--- 重发 DSRC 信号 ---
	MOV	R7,#XDATA_TXBUF
	MOV	R0,#DATA_DSRCTXLEN
	MOV	A,@R0
	MOV	R3,A	
OBUMAIN_WAVEACTIVE_NOSETMMI:
	CLR	EA	
	CALL 	_FUN_HDLC_TX
OBUMAIN_WAVEACTIVE_NOEAOV01:	
	JMP	OBUMAIN_WAVEACTIVE_LOOP					;回到DSRC信号循环处理流程		
OBUMAIN_WAVEACTIVE_NBITOVER:						;N位有改变时，执行新指令	
	CPL	BIT_N							;记录N位	
OBUMAIN_WAVEACTIVE_ActionType:	
	MOV	R0,#DATA_RXBUF + CONST_DSRC_ACTIONTYPE			;ActionType;取LLC控制域数据
	MOV	A,@R0	
	CJNE	A,#Const_ActionType_GetSecure,OBUMAIN_WAVEACTIVE_SetSecure	
OBUMAIN_WAVEACTIVE_GetSecure:;(认证)	
	;+++ SETB	Pin_GRE							;收到GetSecure灭绿灯
	JNB	BIT_INSERTCARD,OBUMAIN_WAVEACTIVE_Selected	; 当用户卡复位没有成功时，不对用户卡做选目录操作
	JB	BIT_ISContact,OBUMAIN_WAVEACTIVE_Select1001	; 如果是接触卡，则选 1001，如果是非接卡，则Pro卡才选1001
	JNB	BIT_proMF,OBUMAIN_WAVEACTIVE_Selected	
OBUMAIN_WAVEACTIVE_Select1001:	
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF
	MOV	R3,#7
	CALL	_FUN_LIB_DATATOXDATA	
OBUMAIN_WAVEACTIVE_Se1001PPS:	
	CLR	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#10H
	MOV	R2,#01H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	OBUMAIN_WAVEACTIVE_Se1001ED	
	MOV	A,#CONST_STATE_GetSecureSelFileEr
	CALL	_FUN_OBUMAIN_ErrShow	
	JMP	AP_start
	
OBUMAIN_WAVEACTIVE_Se1001ED:	
	SETB	BIT_Sel1001
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF
	MOV	R3,#7
	CALL	_FUN_LIB_XDATATODATA	
OBUMAIN_WAVEACTIVE_Selected:
	CALL	_FUN_DSRC_NSpecial
	JMP	OBUMAIN_WAVEACTIVE_DESL
OBUMAIN_WAVEACTIVE_SetSecure:;SET_Secure	
	CJNE	A,#Const_ActionType_SetSecure,OBUMAIN_WAVEACTIVE_GetRand
	JMP	OBUMAIN_WAVEACTIVE_DESL	
OBUMAIN_WAVEACTIVE_GetRand:;(取随机数)	
	CJNE	A,#Const_ActionType_GetRand,OBUMAIN_WAVEACTIVE_TransferChannel
	JMP	OBUMAIN_WAVEACTIVE_DESL	
OBUMAIN_WAVEACTIVE_TransferChannel:;(通道)
	CJNE	A,#Const_ActionType_TransferChannel,OBUMAIN_WAVEACTIVE_SetMMI
	
	JNB	BIT_INSERTCARD,OBUMAIN_WAVEACTIVE_TransferSelected		; 当用户卡复位没有成功时，不对用户卡做选目录操作
	JB	BIT_ISContact,OBUMAIN_WAVEACTIVE_TransferSel1001	; 如果是接触卡，则选 1001，如果是非接卡，则Pro卡才选1001
	JNB	BIT_proMF,OBUMAIN_WAVEACTIVE_TransferSelected
OBUMAIN_WAVEACTIVE_TransferSel1001:
	JB	BIT_Sel1001,OBUMAIN_WAVEACTIVE_TransferSelected	
	
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF
	MOV	R3,#7
	CALL	_FUN_LIB_DATATOXDATA

	CLR	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#10H
	MOV	R2,#01H
	CALL	_FUN_CARDAPP_SelectFile
	SETB	BIT_Sel1001	
OBUMAIN_WAVEACTIVE_TransferChannelSELOV:	
	MOV	R7,#XDATA_HOLD
	MOV	R5,#DATA_RXBUF
	MOV	R3,#7
	CALL	_FUN_LIB_XDATATODATA
OBUMAIN_WAVEACTIVE_TransferSelected:
	MOV	R0,#DATA_RXBUF+11
	MOV	A,@R0
	XRL	A,#2
	JNZ	OBUMAIN_WAVEACTIVE_TransferPPS02
	SETB	BIT_esamtran
	
OBUMAIN_WAVEACTIVE_TransferPPS02:
	CALL	_FUN_DSRC_NSpecial
	JMP	OBUMAIN_WAVEACTIVE_DESL
	
OBUMAIN_WAVEACTIVE_SetMMI:;(响铃)
	CJNE	A,#Const_ActionType_SetMMI,OBUMAIN_WAVEACTIVE_SWGSM
	MOV	R0,#DATA_RXBUF+11
	MOV	A,@R0
	MOV	R1,#XDATA_SETMMI
		;MOVX	@R1,A
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	@DPTR,A	
	CALL	_FUN_DSRC_NSpecial
	JMP	OBUMAIN_WAVEACTIVE_DESL	
OBUMAIN_WAVEACTIVE_SWGSM:;
	CJNE	A,#81,OBUMAIN_WAVEACTIVE_DESL
	CALL	_FUN_DSRC_NSpecial
	
	JMP	OBUMAIN_WAVEACTIVE_DESL
OBUMAIN_WAVEACTIVE_Other:;(保留)ss	
OBUMAIN_WAVEACTIVE_DESL:	
OBUMAIN_WAVEACTIVE_Response:
	
	;---  发送DSRC信号 ---	
	CALL 	_FUN_HDLC_TX	
	JNB	BIT_SETMMI,OBUMAIN_WAVEACTIVE_NOEA02x	
	CALL	_FUN_OBUMain_TIMERX
OBUMAIN_WAVEACTIVE_NOEA02x:		
	;---JB	BIT_SETMMI,OBUMAIN_WAVEACTIVE_OVER
	JMP	OBUMAIN_WAVEACTIVE_LOOP					; 重新等待接收DSRC数据	
OBUMAIN_WAVEACTIVE_OVER:						; 微波激活流程结束	
	CLR	TR0		;关闭T0
	CLR	ET0		;关闭T0使能
	CLR	EA		
	CALL	_FUN_HDLC_CLOSECLR

	;--- 清除Flash ---
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	R3,#1
	CALL	_eraseflash	
	;--- 如果交易成功就记录天线ID ---
	JNB	BIT_SetMMI,OBUMAIN_WAVEACTIVE_predeal	
	;写卡片信息到Flash中去
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	R7,#XDATA_BeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen
	CALL	_wrflashXR
OBUMAIN_WAVEACTIVE_predeal:	
	CALL	OBUMain_CARDPreDeal_ReadSysInfo				;简化版预读		

OBUMAIN_WAVEACTIVE_display:
	clr	PIN_ESAM_RST	
	clr	Pin_522_RST
	SETB	Pin_pwrdwn
	CALL	_FUN_OBUMain_CardInfoDisplay				; 显示卡信息	
	;--- RC522和主单片机下电() ---	
OBUMAIN_WAVEACTIVE_END:
	;-------重新开始前延时显示------------	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	JMP	AP_start
	JMP	OBUMAIN_WAVEACTIVE_END
	RET	
;///////////////////////////////////////////////////////////////////////////////////////////////////
;------------------------------------
;描述:系统初始化
;参数:(无)
;------------------------------------
_FUN_OBUMAIN_INITSYS:	
	;--- 清空所有寄存器 ---
	CLR	A
	MOV	PSW,#CONST_WORKSTAION_0	
	;设置当前PSW操作工作区0
	CLR	RS0
	CLR	RS1	
	MOV	IP,A
		
	MOV	PCON,A
	MOV	SCON,A
	
	MOV	TH1,A
	MOV	TL1,A
	MOV	TH0,A
	MOV	TL0,A
	MOV	IP,A
	
	CLR	BIT_FIRSTTX						; 硬串口发送第一个字节标记=0表示还没发送第一个字节，=1表示已发送			
	CLR	BIT_CHANNELFLAG						; = 1表示当前使用信道1,  =0 表示当前使用信道0
	SETB	BIT_9600						; =1当前波特率是9600;=0当前波特率不是9600		
	CLR	BIT_T0T1						; T0还是T1
	SETB	BIT_ESAMICC						; 是用户卡，还是ESAM卡
	CLR	BIT_INSERTCARD						; 未插卡
	CLR	BIT_ISFRX						; =0 表示串口第一个字节接收	=1 表示第一个字节不接收		
	SETB	BIT_ISRXNB						; =1 表示未收到过非广播地址	=0 表示已经收到过非广播地址	
	CLR	BIT_SETMMI						; =0 表没有收到过SetMMI,		=1 SetMMI	
	SETB	BIT_ESAM						; =1 表示有ESAM =0 表示没有ESAM卡	
	CLR	BIT_PROF						; Pro卡发送序号	= 0 表示0A ;= 1 表示0B
	CLR	BIT_proMF						; =1 表示是pro卡，=0表示，MF卡
	CLR	BIT_GetSecure						; =1表示收到GetSecure指令，=0表示没有收到GetSecure
	CLR	BIT_BST							; =1表示收到过bst,=0表示没有收到过bst		
	;CLR	BIT_ContactIssue					;发行开始标记	=0，没有接收发行信息，=1接收到发行信息
	CLR	BIT_gbICCInfo
	
	CLR	BIT_HaveRecordCellID
	CLR	BIT_privateInfo
	CLR	BIT_CD							;=0表示未被拆动，=1 被拆动	
	CLR	BIT_ACTIVECARD						;=0 非插卡激活;=1 插卡激活
	CLR	BIT_CDJH
	CLR	BIT_ESAMOK
	SETB	BIT_InsertEr
	CLR	BIT_PPS	
	CLR	BIT_ESAMErr
	CLR	BIT_MMITIRMSTART
	CLR	BIT_esamtran
	CLR	BIT_Sel1001
	CLR	BIT_USEROK
	
	MOV	R0,#DATA_VARBAUDFULL
	MOV	@R0,#CONST_BAUD_FULL9600	
	MOV	R0,#DATA_VARBAUDHALF
	MOV	@R0,#CONST_BAUD_HALF9600
	MOV	R7,#CONST_BAUD_HAND9600					;波特率初值	
	SETB	BIT_VERIFY						;串口收发是否要加验位,=0不要，=1要		
	CALL	_FUN_SERIAL_INIT					;串口相关寄存器初始化	
 	MOV	R0,#XDATA_SOFTFIRSTSCANTIME
	MOV	A,#CONST_SOFTFIRSTSCANTIME
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A							;串口第一个字节最大搜索时间	
	MOV	R0,#XDATA_SETMMI
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	MOV	R0,#XDATA_BSTNUM					;接收到BST的个数
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	MOV	R0,#xdata_setmminum					;接收到BST的个数
	CLR	A
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	CLR	A
	MOV	R0,#XDATA_VSTNUM
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	;看重发用
	MOV	R0,#XDATA_NUM
	MOV	A,#0
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	DATA_MFCOM,#0
	
	RET
;----------------------------------------------------------------------------------
;描述:相关的应用初始化
;参数:
;
;BIT_ACTIVE	---	=1 微波激活时的应用初始化; =0 插卡激活时的应用初始化 
;			=0 ESAM DF01 文件不选
;			=1 ESAM DF01 文件要选
;
;步骤:
;		read last card type
;			|
;		init esma
;			|
;		[if IsContact = contact] jmp init cpu contact	Else jmp init not contact
;			|
;		init cpu contact - err - >jmp init not contact sec--err->显示无卡并置插卡标记为无										
;		init not contact - err - >jmp init cpu contact sec--err->显示无卡并置插卡标记为无
;			|(ini ok)
;			|
;		[if IsContact = Contact ]	-> pps(不接返回)
;			|
;		(change baud)
;			|
;		Select DF01
;			|
;		[if not mf] -> Select 1001
;----------------------------------------------------------------------------------
_FUN_OBUMain_BASEINIT:
	clr	BIT_INSERTCARD
	CLR	BIT_BUFADDR
	;读取 	OBUID
	MOV	DPTR,#STR_SYS_OBUID
	MOV	R7,#DATA_OBUID
	CALL	_FUN_LIB_FLASHTODATA
	;读取System Info 拆卸位(第27个字节)
	;放在这里读，重要的原因是，上电时需延时，所以可以省时。
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 26
	MOV	AR7,#XDATA_FIX
	MOV	R3,#1
	CALL	_RDFlashXR	
	
	MOV	R1,#XDATA_FIX
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ANL	A,#0FH
	
	JZ	OBUMain_BASEINIT_Tampered
	CLR	BIT_CD
	JMP	OBUMain_BASEINIT_TamperedOver
	
OBUMain_BASEINIT_Tampered:	
	SETB	BIT_CD
OBUMain_BASEINIT_TamperedOver:
	;读取上回天线ID和unixtime 
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	AR7,#XDATA_LastBeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen
	CALL	_RDFlashXR	
	;--- 从 Flash 中读取上一次插卡类型 ---
	;接触卡 还是 非接触卡
	;CONST_FLASH_LASTCARDH
	MOV	DPH,#CONST_FLASH_LASTCARDH
	MOV	DPL,#CONST_FLASH_LASTCARDL
	MOV	AR7,#DATA_RXBUF
	MOV	R3,#1
	CALL	_RDFlash
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	MOV	C,ACC.0
	MOV	BIT_ISContact,C	;接触卡=1，还是非接触卡=0			
	CLR	BIT_ISContact
OBUMain_BASEINIT_InitESAMCard:
	JNB	BIT_ESAM,OBUMain_BASEINIT_InitUserCard
	
OBUMain_BASEINIT_InitUserCard:
	JB	BIT_ISContact,OBUMain_BASEINIT_InitContact	;
	JMP	OBUMain_BASEINIT_InitNContact			;	
OBUMain_BASEINIT_InitContactSEC:				; 初始化非接失败后，转向复位接触卡
	jmp	OBUMain_BASEINIT_SelectDF01
	JB	BIT_ISContact,OBUMain_BASEINIT_SelectDF01	; 如果已经复位过，接触卡，则不再复位
OBUMain_BASEINIT_InitContact:					; 初始化接触卡
	
	;初始化用户卡
	CLR	Pin_522_RST
	SETB	BIT_ESAMICC					; =1  复位接触式用户卡  ;= 0  复位ESAM卡
	CALL	_FUN_Contact_INIT
	MOV	A,R7
	JNZ	OBUMain_BASEINIT_InitNContactSEC
	SETB	BIT_INSERTCARD					; 置插卡位	;=1表示当前OBU插卡;=0表示当前OBU没插卡;	
	SETB	BIT_ISContact					; 更新卡类型标记
	JMP	OBUMain_BASEINIT_PPS
OBUMain_BASEINIT_InitNContactSEC:				; 初始化接失败后，转向复位非接触卡	
	JNB	BIT_ISContact,OBUMain_BASEINIT_SelectDF01	; 如果已经复位过，非接触卡，则不再复位
OBUMain_BASEINIT_InitNContact:					; 初始化非接触卡
	
	CALL	_FUN_NContact_Rc500Rst
	CALL	_FUN_NContact_Rc500Config
	CALL	_FUN_NContact_Rc500Request
	MOV	A,R7
	;---JNZ	OBUMain_BASEINIT02_SelectDF01
	JZ	OBUMain_BASEINIT_Request
	JB	PIN_card_exist,OBUMain_BASEINIT_Request01
	CALL	_FUN_NContact_Rc500Rst
	CALL	_FUN_NContact_Rc500Config
	CALL	_FUN_NContact_Rc500Request
	MOV	A,R7
	JZ	OBUMain_BASEINIT_Request
	;Baseinit02函数，初始化卡片失败
	MOV	A,#CONST_STATE_Base02Re
	CALL	_FUN_OBUMAIN_ErrShow02
OBUMain_BASEINIT_Request01:
	JMP	OBUMain_BASEINIT_SelectDF01
OBUMain_BASEINIT_Request:
	CALL	_FUN_NContact_Rc500AntiColl
	MOV	A,R7
	JNZ	OBUMain_BASEINIT_SelectDF01
	CALL	_FUN_NContact_Rc500Select
	MOV	A,R7
	
	JNZ	OBUMain_BASEINIT_SelectDF01	
	
	CLR	BIT_ProMF				; 默认为MF卡	
	MOV	A,DATA_RXBUF
	;08 20	
	XRL	A,#20H
	JZ	OBUMain_BASEINIT_ISPrO
	MOV	A,DATA_RXBUF
	XRL	A,#28H
	JNZ	OBUMain_BASEINIT_InitNContactOVER		
OBUMain_BASEINIT_ISPrO:	
	SETB	BIT_ProMF				; 设置当前为Pro卡标记		
	CALL	_FUN_ProCard_Rats			; 如果当前是pro卡，则再做rat操作

	SETB	BIT_INSERTCARD				; 置插卡位	;=1表示当前OBU插卡;=0表示当前OBU没插卡;		
	CLR	BIT_ISContact				; 更新卡类型标记
	MOV	R0,#DATA_RXBUF+1
	MOV	A,@R0	
	MOV	C,ACC.4
	JNC	OBUMain_BASEINIT_InitNSelDF01
	
	MOV	R0,#DATA_RXBUF+2			; 
	MOV	A,@R0					; 
	MOV	C,ACC.1					; 
	JNC	OBUMain_BASEINIT_InitNSelDF01		; 
	MOV	C,ACC.5					; 
	JNC	OBUMain_BASEINIT_InitNSelDF01		; 
							; 
	CALL	_FUN_Pro_PPS				; 非接PPS（插卡唤醒）
	CALL	_FUN_NContact_Rc500_PPS_Config		; RC522 寄存器
	MOV	A,R7

OBUMain_BASEINIT_InitNSelDF01:				;
	JNZ	OBUMain_BASEINIT_SelectDF01
OBUMain_BASEINIT_InitNContactOVER:
	;~~~~~~~ 调用测试段 ~~~~~~~
	;MOV	A,#120
	;JMP	_FUN_TEST_DISPLAY
	;~~~~~~~~~~~~~~~~~~~~~~~~~~
	SETB	BIT_INSERTCARD				; 置插卡位	;=1表示当前OBU插卡;=0表示当前OBU没插卡;		
	CLR	BIT_ISContact				; 更新卡类型标记
OBUMain_BASEINIT_PPS:	
OBUMain_BASEINIT_SelectDF01:				;选择ESAM卡DF01目录	
	CALL	_FUN_OBUMAIN_SELECTDF01



OBUMain_BASEINIT_OVER:
OBUMain_BASEINIT_OVER02:
	setb	BIT_INITCard	
	RET

;////////////////////////////////////////////////////////////	
_FUN_OBUMain_BASEINIT02:	
	
	CLR	BIT_INSERTCARD
	CLR	BIT_BUFADDR
	
	;读取 	OBUID
	MOV	DPTR,#STR_SYS_OBUID
	MOV	R7,#DATA_OBUID
	CALL	_FUN_LIB_FLASHTODATA
	
	;读取System Info 拆卸位(第27个字节)
	;放在这里读，重要的原因是，上电时需延时，所以可以省时。
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 26
	MOV	AR7,#XDATA_FIX
	MOV	R3,#1
	CALL	_RDFlashXR
	
	MOV	R1,#XDATA_FIX
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ANL	A,#0FH
	
	JZ	OBUMain_BASEINIT02_Tampered
	CLR	BIT_CD
	JMP	OBUMain_BASEINIT02_TamperedOver
	
OBUMain_BASEINIT02_Tampered:	
	SETB	BIT_CD
OBUMain_BASEINIT02_TamperedOver:
		
	;--- 从 Flash 中读取上一次插卡类型 ---
	;接触卡 还是 非接触卡
	MOV	DPH,#CONST_FLASH_LASTCARDH
	MOV	DPL,#CONST_FLASH_LASTCARDL
	MOV	AR7,#DATA_RXBUF
	MOV	R3,#1
	CALL	_RDFlash
	MOV	R0,#DATA_RXBUF
	MOV	A,@R0
	MOV	C,ACC.0
	MOV	BIT_ISContact,C	;接触卡=1，还是非接触卡=0
			
	;~~~~~~~~~调好非接卡去掉~~~~~~~~~~~~~~
	clr	BIT_ISContact	
OBUMain_BASEINIT02_InitESAMCard:
	JNB	BIT_ESAM,OBUMain_BASEINIT02_InitUserCard	
OBUMain_BASEINIT02_InitUserCard:
	JB	BIT_ISContact,OBUMain_BASEINIT02_InitContact	;
	JMP	OBUMain_BASEINIT02_InitNContact			;	
OBUMain_BASEINIT02_InitContactSEC:				; 初始化非接失败后，转向复位接触卡
	jmp	OBUMain_BASEINIT02_SelectDF01
	;---JB	BIT_ISContact,OBUMain_BASEINIT02_SelectDF01	; 如果已经复位过，接触卡，则不再复位
	JNB	BIT_ISContact,OBUMain_BASEINIT02_InitContact	; 如果已经复位过，接触卡，则不再复位
	JMP	OBUMain_BASEINIT02_SelectDF01
OBUMain_BASEINIT02_InitContact:					; 初始化接触卡	
	;初始化用户卡
	CLR	Pin_522_RST
	SETB	BIT_ESAMICC					; =1  复位接触式用户卡  ;= 0  复位ESAM卡
	CALL	_FUN_Contact_INIT
	MOV	A,R7
	JNZ	OBUMain_BASEINIT02_InitNContactSEC 
	SETB	BIT_INSERTCARD					; 置插卡位	;=1表示当前OBU插卡;=0表示当前OBU没插卡;	
	SETB	BIT_ISContact					; 更新卡类型标记
	JMP	OBUMain_BASEINIT02_PPS	
OBUMain_BASEINIT02_InitNContactSEC:				; 初始化接失败后，转向复位非接触卡	
	JNB	BIT_ISContact,OBUMain_BASEINIT02_SelectDF01	; 如果已经复位过，非接触卡，则不再复位
OBUMain_BASEINIT02_InitNContact:					; 初始化非接触卡

	;---jb	PIN_card_exist,OBUMain_BASEINIT02_SelectDF01	
	;先发送 00a4000002 操作完用户卡后再发df01 并接收，看是否可以收到61+len
	MOV	DPTR,#STR_DSRC_SELDF
	MOV	R7,#data_rxbuf
	CALL	_FUN_LIB_FLASHTODATA

	clr	BIT_ESAMICC
	MOV	R7,#data_rxbuf
	MOV	R5,#CONST_SOFTBYTESP
	MOV	R3,#5
	CLR	BIT_BUFADDR					;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY					;串口收发是否要加验位,=0不要，=1要						
	CALL	_FUN_SERIAL_TXSOFT	

	CALL	_FUN_NContact_Rc500Rst

	CALL	_FUN_NContact_Rc500Config
	CALL	_FUN_NContact_Rc500Request
	MOV	A,R7
	;---JNZ	OBUMain_BASEINIT02_SelectDF01
	JZ	OBUMain_BASEINIT02_Request
	JB	PIN_card_exist,OBUMain_BASEINIT02_Request01
	CALL	_FUN_NContact_Rc500Rst
	CALL	_FUN_NContact_Rc500Config
	CALL	_FUN_NContact_Rc500Request
	MOV	A,R7
	JZ	OBUMain_BASEINIT02_Request
	;Baseinit02函数，初始化卡片失败
	MOV	A,#CONST_STATE_Base02Re
	CALL	_FUN_OBUMAIN_ErrShow02
OBUMain_BASEINIT02_Request01:
	JMP	OBUMain_BASEINIT02_SelectDF01
OBUMain_BASEINIT02_Request:
	
	CALL	_FUN_NContact_Rc500AntiColl
	MOV	A,R7
	JNZ	OBUMain_BASEINIT02_SelectDF01
	CALL	_FUN_NContact_Rc500Select
	MOV	A,R7
	JNZ	OBUMain_BASEINIT02_SelectDF01
	CLR	BIT_ProMF				; 默认为MF卡	
	MOV	A,DATA_RXBUF
	XRL	A,#20H
	JZ	OBUMain_BASEINIT02_ISPrO
	MOV	A,DATA_RXBUF
	XRL	A,#28H
	JNZ	OBUMain_BASEINIT02_InitNContactOVER		; 
OBUMain_BASEINIT02_ISPrO:					; 
	SETB	BIT_ProMF				; 设置当前为Pro卡标记		
	CALL	_FUN_ProCard_Rats			; 如果当前是pro卡，则再做rat操作
	MOV	A,R7
	JNZ	OBUMain_BASEINIT02_SelectDF01
	
	SETB	BIT_INSERTCARD				; 置插卡位	;=1表示当前OBU插卡;=0表示当前OBU没插卡;		
	CLR	BIT_ISContact				; 更新卡类型标记	

	MOV	R0,#DATA_RXBUF+1
	MOV	A,@R0	
	MOV	C,ACC.4
	JNC	OBUMain_BASEINIT02_InitNContactOVER
	
	MOV	R0,#DATA_RXBUF+2
	MOV	A,@R0
	MOV	C,ACC.1
	JNC	OBUMain_BASEINIT02_InitNContactOVER
	MOV	C,ACC.5
	JNC	OBUMain_BASEINIT02_InitNContactOVER	
	
	CALL	_FUN_Pro_PPS				; 非接PPS（插卡唤醒）
	CALL	_FUN_NContact_Rc500_PPS_Config		; RC522 寄存器
	MOV	A,R7					; 
OBUMain_BASEINIT02_InitNContactOVER:
	SETB	BIT_INSERTCARD				; 置插卡位	;=1表示当前OBU插卡;=0表示当前OBU没插卡;		
	CLR	BIT_ISContact				; 更新卡类型标记		
OBUMain_BASEINIT02_PPS:
OBUMain_BASEINIT02_SelectDF01:				;选择ESAM卡DF01目录		
	clr	BIT_ESAMOK	
	;jnb	PIN_card_exist,OBUMain_BASEINIT02_SelectDF0102
	jb	BIT_INSERTCARD,OBUMain_BASEINIT02_SelectDF0102
	;jb	BIT_INSERTCARD,OBUMain_BASEINIT02_SelectDF0102
	CALL	_FUN_OBUMAIN_SELECTDF01
	jmp	OBUMain_BASEINIT02_OVER02	
OBUMain_BASEINIT02_SelectDF0102:	
	;先发送 00a4000002 操作完用户卡后再发df01 并接收，看是否可以收到61+len
	MOV	DPTR,#STR_DSRC_DF
	MOV	R7,#data_rxbuf
	CALL	_FUN_LIB_FLASHTODATA
	
	CLR	BIT_ESAMICC
	MOV	R7,#data_rxbuf
	MOV	R5,#CONST_SOFTBYTESP
	MOV	R3,#2
	CLR	BIT_BUFADDR					;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_VERIFY					;串口收发是否要加验位,=0不要，=1要						
	CALL	_FUN_SERIAL_TXSOFT
	
	;---- 接收数据 ----
	CLR	BIT_ESAMICC
	SETB	BIT_BUFADDR			;=0，发送的是内存数据；=1，发送的是外存数据
	SETB	BIT_SERIALOVERTIMERX		;;软串口等待接收是否有时间,限制=0没有限制;=1有时间限制
	SETB	BIT_VERIFY			;串口收发是否要加验位,=0不要，=1要	
	MOV	R0,#xdata_txbuf
	MOV	A,@R0
	MOV	R7,A
	MOV	R3,#2	
	CALL	_FUN_SERIAL_RXSOFT
	MOV	A,R3
;CALL	_FUN_TEST_DISPLAY
	XRL	A,#2		
	JNZ	OBUMain_BASEINIT02_ESAMerrrr
	
	MOV	R0,#xdata_txbuf
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#61h
	jnz	OBUMain_BASEINIT02_ESAMerrrr
	jmp	OBUMain_BASEINIT02_ESAMRight	
OBUMain_BASEINIT02_ESAMerrrr:		
	JNB	BIT_ESAMErr,OBUMain_BASEINIT02_OVER02	
	CALL	_FUN_LIB_ESAMErr
OBUMain_BASEINIT02_ESAMRight:
	
	SETB	BIT_ESAMOK			;设置ESAM操作成功标记	
OBUMain_BASEINIT02_OVER02:	
	SETB	BIT_INITCard	
	RET	
;-------------------------------------------------------------------------------------------
;_FUN_OBUMain_CARDPreDeal (附属序段)
;附属: _FUN_OBUMAIN_MASTER
;描述: 卡片预处理
;流程: XXX
;-------------------------------------------------------------------------------------------
_FUN_OBUMain_CARDPreDeal:		
	;--- 清除Flash预处理区 ---
	;注：Erase不能放在_FUN_OBUMain_BASEINIT前，因为复位用户卡前要读Flash
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	R3,#001H
	CALL	_eraseflash	
OBUMain_CARDPreDeal_ReadSysInfo: ;读系统信息文件
	clr	BIT_USEROK
	;--- 用户卡插卡预处理程序 ---
	JB	BIT_INSERTCARD,OBUMain_CARDPreDeal_USER
	JMP	OBUMain_CARDPreDeal_USEROver				;没有插卡时，结束预处理，并显示卡片信息		
OBUMain_CARDPreDeal_USER:						;用户卡预处理	
	JB	BIT_ISCONTACT,OBUMain_CARDPreDeal_PreDealCPUCard	;当插卡是接触式卡时，则做CPU卡预处理
	JB	BIT_ProMF,OBUMain_CARDPreDeal_PreDealCPUCard		;当插卡是非接，且是pro卡时，则做CPU卡预处理
	JMP	OBUMain_CARDPreDeal_PreDealMF				;当插卡是非接，是MF卡时，则做MF预处理		
OBUMain_CARDPreDeal_PreDealCPUCard:					;CPU卡预处理
OBUMain_CARDPreDeal_PPS:	
	SETB	BIT_GETRESULT
	SETB	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#10H
	MOV	R2,#01H
	CALL	_FUN_CARDAPP_SelectFile

OBUMain_CARDPreDeal_Read0002: 						;读0002文件
	;读 0002 文件
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	 
		
	MOV	R7,#DATA_RXBUF						;R7 发送绶冲指针(内存)
	MOV	R5,#XDATA_TXBUF		
	CALL	_FUN_CARDAPP_GetBalance	
	MOV	A,R7

	JZ	OBUMain_CARDPreDeal_Write0002
	JMP	OBUMain_CARDPreDeal_USEROver			;出错，则结束预处理	
OBUMain_CARDPreDeal_Write0002:	
	;将值Copy到#Money内存中去
	MOV	R3,#4
	MOV	AR1,AR5
	MOV	R0,#MONEY
OBUMain_CARDPreDeal_CopyMoney:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	INC	R0
	INC	R1
	DJNZ	R3,OBUMain_CARDPreDeal_CopyMoney	
	;写0002到FLASH
	MOV	DPH,#CONST_FLASH_0002H
	MOV	DPL,#CONST_FLASH_0002L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_0002Len		
	CALL	_wrflashXR		
OBUMain_CARDPreDeal_Read0012: ;读0012文件	
	;读0012文件
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT			
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)
	MOV	R5,#XDATA_TXBUF			
	MOV	R4,#012H						;R4		---	文件ID
	MOV	R3,#CONST_Flash_0012Len					;R3		---	长度
	MOV	R2,#000H						;R2		---	offset
	CALL	_FUN_CARDAPP_ReadBinary	
	MOV	A,R7
	
	JZ	OBUMain_CARDPreDeal_Write0012
	JMP	OBUMain_CARDPreDeal_USEROver			;出错，则结束预处理
OBUMain_CARDPreDeal_Write0012:
	;写0012到FLASH
	MOV	DPH,#CONST_FLASH_0012H
	MOV	DPL,#CONST_FLASH_0012L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_0012Len		
	CALL	_wrflashXR		
OBUMain_CARDPreDeal_Read0015: ;读0015文件	
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)
	MOV	R5,#XDATA_TXBUF			
	MOV	R4,#015H						;R4		---	文件ID
	MOV	R3,#CONST_Flash_0015Len					;R3		---	长度
	MOV	R2,#00H							;R2		---	offset
	CALL	_FUN_CARDAPP_ReadBinary	
	MOV	A,R7
	JZ	OBUMain_CARDPreDeal_Write0015
	JMP	OBUMain_CARDPreDeal_USEROver
OBUMain_CARDPreDeal_Write0015:

	;写0015到FLASH
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_0015Len
	CALL	_wrflashXR	
		
OBUMain_CARDPreDeal_Read0019: ;读0019文件	
;////////////////////////////////////////////////////////////////////////////////
;B9 E3 B6 AB	广东
;1,00a40000021001
;1,00b0950008	
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L
	MOV	R7,#XDATA_Hold
	MOV	R3,#CONST_Flash_0015Len
	CALL	_rdflashxr	
	
	mov	r0,#XDATA_Hold
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0b9h	
	jnz	OBUMain_CARDPreDeal_0019GB
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0E3h	
	jnz	OBUMain_CARDPreDeal_0019GB
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0b6h	
	jnz	OBUMain_CARDPreDeal_0019GB
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0ABH
	JNZ	OBUMain_CARDPreDeal_0019GB	
	JMP	OBUMain_CARDPreDeal_0019GD
OBUMain_CARDPreDeal_0019GB:;国标
;		mov	a,#38
;		call	_fun_test_display
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF			
	MOV	R4,#19H							;R4		---	文件ID
	mov	r2,#1
	MOV	R3,#CONST_Flash_0019GBLen					;R3		---	长度
	CALL	_FUN_CARDAPP_ReadRecord		
	MOV	A,R7

	JZ	OBUMain_CARDPreDeal_Write0019GB
	JMP	OBUMain_CARDPreDeal_USEROver
OBUMain_CARDPreDeal_Write0019GB:	
	;写0019到FLASH
	MOV	DPH,#CONST_FLASH_0019H
	MOV	DPL,#CONST_FLASH_0019L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_0019GBLen		
	CALL	_wrflashXR			
	JMP	OBUMain_CARDPreDeal_RecordCardType		
	
OBUMain_CARDPreDeal_0019GD:;广东
	;	mov	a,#37
	;	call	_fun_test_display
	SETB	BIT_ESAMICC						;当前对用户卡操作
	SETB	BIT_GETRESULT	
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)\
	MOV	R5,#XDATA_TXBUF			
	MOV	R4,#19H							;R4		---	文件ID
	mov	r2,#2
	MOV	R3,#CONST_Flash_0019Len					;R3		---	长度
	CALL	_FUN_CARDAPP_ReadRecord		
	MOV	A,R7
	;		call	_fun_test_display
	JZ	OBUMain_CARDPreDeal_Write0019gd
	JMP	OBUMain_CARDPreDeal_USEROver
OBUMain_CARDPreDeal_Write0019gd:	
	;写0019到FLASH
	MOV	DPH,#CONST_FLASH_0019H
	MOV	DPL,#CONST_FLASH_0019L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_0019Len		
	CALL	_wrflashXR			
	JMP	OBUMain_CARDPreDeal_RecordCardType
	
;//////////////////////////////////////////////////////////////////////////////////
OBUMain_CARDPreDeal_PreDealMF:						;MF卡插卡预处理		
	JMP	OBUMain_CARDPreDeal_RecordCardType
OBUMain_CARDPreDeal_ReadBlock01: ;读01块
	MOV	DPTR,#STR_ReadBlock01
	MOV	R7,#DATA_RXBUF
	CALL	_FUN_LIB_FLASHTODATA
		
	SETB	BIT_ESAMICC		
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF		
	CALL	_FUN_CARDAPP_CardChannel
	MOV	R0,#XDATA_TXBUF	+ 1
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	JZ	OBUMain_CARDPreDeal_ReadBlock0101			;出错，则结束预处理	
	JMP	OBUMain_CARDPreDeal_USEROver
OBUMain_CARDPreDeal_ReadBlock0101:
OBUMain_CARDPreDeal_ReadBlock04: ;读04块
OBUMain_CARDPreDeal_ReadBlock10: ;读04块
OBUMain_CARDPreDeal_RecordCardType:;记录卡片信息
	setb	BIT_USEROK
	
 	;--- 记录卡片类型 ---
 	MOV	R0,#XDATA_TXBUF
	CLR	A
	MOV	C,BIT_ISContact
	MOV	ACC.0,C
	;2013-09-18 
	mov	c,BIT_ProMF
	mov	acc.1,c	
	mov	c,BIT_INSERTCARD
	mov	acc.2,c
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	
	;写卡片信息到 Flash 中去
	MOV	DPH,#CONST_FLASH_LASTCARDH
	MOV	DPL,#CONST_FLASH_LASTCARDL
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_CardTypeLEN		
	CALL	_wrflashXR
	
	;如果ESAM没有预处理成功，一样不可以置预处理成功标记
	JNB	BIT_ESAMOK,OBUMain_CARDPreDeal_USEROver
	
	;--- 写入预处理成功标记 --- 
	MOV	R0,#XDATA_TXBUF
	MOV	A,#CONST_SYS_PREFlag
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	DPH,#CONST_FALSH_PREFlagH
	MOV	DPL,#CONST_FALSH_PREFlagL
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_FALSH_PREFlagLen
	CALL	_wrflashXR
	
	MOV	R0,#XDATA_TXBUF
	MOV	A,#CONST_SYS_AA
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	DPH,#CONST_FALSH_PREFlag02H
	MOV	DPL,#CONST_FALSH_PREFlag02L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#1
	CALL	_wrflashXR	
OBUMain_CARDPreDeal_USEROver:					;用户卡片预处理完成	
	CALL	_fun_OBUMAIN_bdcb
	;--- ESAM 卡插卡预处理程序 ---
	JNB	BIT_ESAM,OBUMain_CARDPreDeal_ESAMPreDealOver		;当ESAM卡不存在时，则不读sys info文件	
	JNB	BIT_ESAMOK,OBUMain_CARDPreDeal_ESAMPreDealOver		;当ESAM卡复位不成功时，则不读sys info文件		
	CLR	BIT_ESAMOK	
	;选择 3F00 文件
	CLR	BIT_ESAMICC
	CLR	BIT_GETRESULT
	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#03FH
	MOV	R2,#000H
	CALL	_FUN_CARDAPP_SelectFile
	MOV	A,R7
	JZ	OBUMain_CARDPreDeal_Select3F00R
	JNB	BIT_ESAMErr,OBUMain_CARDPreDeal_Select3F00R
	CALL	_FUN_LIB_ESAMErr	
OBUMain_CARDPreDeal_Select3F00R:	
	;读系统信息文件
	SETB	BIT_GETRESULT
	CLR	BIT_ESAMICC
	MOV	R7,#DATA_RXBUF						;R7		---	发送绶冲指针(内存)
	MOV	R5,#XDATA_TXBUF	
	MOV	R4,#01H							;R4		---	文件ID
	MOV	R3,#CONST_Flash_SysinfoLen				;R3		---	长度
	MOV	R2,#00H							;R2		---	Offset
	CALL	_FUN_CARDAPP_ReadBinary	
	MOV	A,R7
	
	JZ	OBUMain_CARDPreDeal_WriteSysInfo
	JNB	BIT_ESAMErr,OBUMain_BASEINIT_ESAMSysInfoERR
	CALL	_FUN_LIB_ESAMErr
OBUMain_BASEINIT_ESAMSysInfoERR:
	JMP	OBUMain_CARDPreDeal_ESAMPreDealOver
OBUMain_CARDPreDeal_WriteSysInfo:	
	SETB	BIT_ESAMOK	
	; 写 Sysinfo 到 FLASH
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#CONST_Flash_SysinfoLen
	CALL	_wrflashXR
	
	MOV	R0,#XDATA_TXBUF
	MOV	A,#CONST_SYS_AA
		;MOVX	@R0,A
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A
	
	MOV	DPH,#CONST_FALSH_PREFlag03H
	MOV	DPL,#CONST_FALSH_PREFlag03L
	MOV	R7,#XDATA_TXBUF
	MOV	R3,#1
	CALL	_wrflashXR	
OBUMain_CARDPreDeal_ESAMPreDealOver:	
	;更新与预读相关的标记。
	;读取System Info 拆卸位(第27个字节)。
	;放在这里读，重要的原因是，上电时需延时，所以可以省时。
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 26
	MOV	AR7,#XDATA_FIX
	MOV	R3,#1
	CALL	_RDFlashXR
	
	MOV	R1,#XDATA_FIX
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	ANL	A,#0FH
	
	JZ	OBUMain_CARDPreDeal_Tampered
	CLR	BIT_CD
	JMP	OBUMain_CARDPreDeal_TamperedOver
OBUMain_CARDPreDeal_Tampered:
	SETB	BIT_CD
OBUMain_CARDPreDeal_TamperedOver:
OBUMain_CARDPreDeal_Over:
	RET	
;------------------------------------
;描述:卡信息显示
;参数:
;DATA_CARDTYPE	---	22	显示余额
;			23	显示通行卡
;			XX	显示错卡
;------------------------------------
_FUN_OBUMain_CardInfoDisplay:
	CALL	_Func_LCD_INIT
OBUMain_CardInfoDisplay_BDQLLOOP:;比对全零	
OBUMain_CardInfoDisplay_BDCP:;比对车牌	
OBUMain_CardInfoDisplay_BDCPLOOP:;比对车牌循环	
OBUMain_CardInfoDisplay_cpbf:;显示车牌子不符
	
	JNB	BIT_CD,OBUMain_CardInfoDisplay_Start			;如果不是失效，则跳过
	JNB	BIT_ACTIVECARD,OBUMain_CardInfoDisplay_Start		;如果不是插卡，则跳过
	
	CLR	Pin_red							;2010-04-21
	;显示拆动标记
	MOV	R7,#00000010B
	CALL	_FUN_LCD_ICON
	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_UNFIX
	CALL	_FUN_LCD_DisplayExChina	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY					; MCU启动时要加延时，以便电压稳定后再操作卡片
	SETB	Pin_red						;2010-04-21
;--------------------------------------------------------	
OBUMain_CardInfoDisplay_Start:
	JB	BIT_INSERTCARD,OBUMain_CardInfoDisplay_CardInfo	
OBUMain_CardInfoDisplay_NOCardInfo:						;没卡信息处理	
OBUMain_CardInfoDisplay_CKOver:	
	CLR	Pin_522_RST
	CLR	PIN_RED
	;+++ SETB	PIN_GRE	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_NOCARD
	CALL	_FUN_LCD_DisplayExChina
	JNB	BIT_SETMMI,OBUMain_CardInfoDisplay_NOCardSetmmiOV	
	MOV 	R7,#100
	CALL	_FUN_LIB_BEEP;响铃	
	SETB	PIN_RED		
OBUMain_CardInfoDisplay_NOCardSetmmiOV:		
	JMP	OBUMain_CardInfoDisplay_Over	
OBUMain_CardInfoDisplay_CardInfo:;有卡信息处理	
	JB	BIT_ISContact,OBUMain_CardInfoDisplay_GETCPUINFO		; 当前是接触卡时，取CPU卡信息，并显示
	JB	BIT_PROMF,OBUMain_CardInfoDisplay_GETCPUINFO			; 当前是PRO卡时，取CPU卡信息，并显示
	MOV	A,#CONST_CARD_PASS						; 当前是MF卡时，则显示'通行卡'
	JMP	OBUMain_CardInfoDisplay_Info
OBUMain_CardInfoDisplay_GETCPUINFO:						; 取CPU卡信息	
	
	;选目录
;	clr	BIT_GETRESULT
;	SETB	BIT_ESAMICC	
;	MOV	R7,#DATA_RXBUF
;	MOV	R5,#XDATA_TXBUF
;	MOV	R3,#10H
;	MOV	R2,#01H
;;	CALL	_FUN_CARDAPP_SelectFile
;	MOV	A,R3	
;	XRL	A,#2	
;	JNZ	OBUMain_CardInfoDisplay_NOCardInfo				;如果选目录出错，则显示无卡
	;交易成功显示记账卡或余额
	;交易成功交易失败
;	MOV	R0,#XDATA_SETMMI
;		;MOVX	A,@R0

;	JZ	OBUMain_CardInfoDisplay_InfoS
;	JMP	OBUMain_CardInfoDisplay_TradeErr
;OBUMain_CardInfoDisplay_InfoS:
	
	;读0015文件中第9个字节[ 卡类型 ]
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L + 8
	MOV	R3,#1								;0015文件长度	
	MOV	R7,#XDATA_TXBUF
	CALL	_RDFlashXR							;读Falsh函数只操作了	r0，所以暂不push r1	
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
OBUMain_CardInfoDisplay_Info:							;显示卡信息	
	CJNE	A,#CONST_CARD_CONSUME,OBUMain_CardInfoDisplay_PassCard
OBUMain_CardInfoDisplay_CashCard:						;储值卡
	
;	CLR	A
;	MOV	R0,#MONEY
;	MOV	@R0,A
;	INC	R0
;	MOV	@R0,A
;	INC	R0
;	MOV	@R0,A
;	INC	R0
;	MOV	@R0,A
;	SETB	BIT_ESAMICC						;当前对用户卡操作
;	SETB	BIT_GETRESULT
;	MOV	R7,#DATA_RXBUF						;R7 发送绶冲指针(内存)
;	MOV	R5,#XDATA_TXBUF
;	CALL	_FUN_CARDAPP_GetBalance
;	MOV	A,R7
;	JNZ	OBUMain_CardInfoDisplay_Money
	
	
	
 	;读钱包
	MOV	DPH,#CONST_FLASH_0002H
	MOV	DPL,#CONST_FLASH_0002L
	MOV	R3,#4								;0015文件长度	
	MOV	R7,#XDATA_TXBUF
	CALL	_RDFlashXR							;读Falsh函数只操作了	r0，所以暂不push r1	
	
	;判断是否都是0xFF
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay_CashCardcpv
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay_CashCardcpv
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay_CashCardcpv	

	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay_CashCardcpv	
	jmp	OBUMain_CardInfoDisplay_Other	
OBUMain_CardInfoDisplay_CashCardcpv:	
	;将值 Copy 到 #Money 内存中去
	MOV	R3,#4
	MOV	R1,#XDATA_TXBUF
	MOV	R0,#MONEY
CARDACTIVE_CashCard_CopyMoney:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	INC	R0
	INC	R1
	DJNZ	R3,CARDACTIVE_CashCard_CopyMoney
	
OBUMain_CardInfoDisplay_Money:
	
	CLR	Pin_522_RST
	CLR	PIN_GRE
	SETB	PIN_RED
	
	;--- 显示 余额 或 通行卡 ---
	MOV	R7,#00000100B
	CALL	_FUN_LCD_ICON
	
	MOV 	R7,#DATA_RXBUF
	LCall 	_dspmoney						;显示新余额	
	CALL	_FUN_OBUMain_BEEP
	;+++ SETB	PIN_GRE
	CLR	PIN_GRE	
	SETB	PIN_RED
	JMP	OBUMain_CardInfoDisplay_Over
	
OBUMain_CardInfoDisplay_PassCard:	;通行卡
	CJNE	A,#CONST_CARD_PASS,OBUMain_CardInfoDisplay_Other
	CLR	Pin_522_RST
	
	;--- 显示通行卡 ---
	CLR	PIN_GRE
	SETB	PIN_RED
	
	MOV	R7,#DATA_RXBUF + 90
	MOV	DPTR,#STR_PASS
	CALL	_FUN_LCD_DisplayExChina
	CALL	_FUN_OBUMain_BEEP
	;+++ SETB	PIN_GRE
	;---CLR	PIN_GRE
	setb	PIN_GRE
	SETB	PIN_RED
	JMP	OBUMain_CardInfoDisplay_Over
	
OBUMain_CardInfoDisplay_Other:	;其它	
	;--- 卡类型不对时，显示"错卡" ---
	CLR	Pin_522_RST
	MOV	R7,#DATA_RXBUF+90
	MOV	DPTR,#STR_ErrCARD
	CALL	_FUN_LCD_DisplayExChina
	;+++ SETB	PIN_GRE	
	JMP	OBUMain_CardInfoDisplay_Over
	
	;交易失败
OBUMain_CardInfoDisplay_TradeErr:
	CLR	Pin_522_RST
	MOV	R7,#DATA_RXBUF+90
	MOV	DPTR,#STR_SetMMIEr
	CALL	_FUN_LCD_DisplayExChina
	CALL	_FUN_OBUMain_BEEP
	;+++ SETB	PIN_GRE
OBUMain_CardInfoDisplay_Over:
	;---------------------
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY	
	;---------------------	
	JMP	AP_start	
	;//////////////////////////////////
_FUN_OBUMain_BEEP:
	clr	PIN_ESAM_RST	
	clr	Pin_522_RST
	SETB	Pin_pwrdwn
OBUMain_BEEP_B:
	MOV	R0,#XDATA_SETMMI
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	JNZ	OBUMain_BEEP_err
OBUMain_BEEP_Secueed:	
	jb	PIN_PWR_GSM,OBUMain_BEEP_SecueedNOKQ
OBUMain_BEEP_SecueedKQ:
	MOV 	R7,#80
	CALL	_FUN_LIB_BEEP	;响铃

	MOV 	R7,#100
	CALL	_FUN_LIB_DELAY	;响铃

	MOV 	R7,#80
	CALL	_FUN_LIB_BEEP	;响铃
	JMP	OBUMain_BEEP_SecueedKQOVER
OBUMain_BEEP_SecueedNOKQ:
	MOV 	R7,#100
	CALL	_FUN_LIB_BEEP	;响铃
	
OBUMain_BEEP_SecueedKQOVER:
	JMP	OBUMain_BEEP_OVER	
OBUMain_BEEP_err:	
	MOV 	R7,#50
	CALL	_FUN_LIB_BEEP	;响铃	
	MOV 	R7,#100
	CALL	_FUN_LIB_delay	;响铃	
	MOV 	R7,#50
	CALL	_FUN_LIB_BEEP	;响铃	
		
OBUMain_BEEP_OVER:
	clr	PIN_ESAM_RST	
	clr	Pin_522_RST
	SETB	Pin_pwrdwn	
	CLR	A
	MOV	IE,#0
	;-------重新开始前延时显示------------
	MOV	R7,#200
	CALL	_FUN_LIB_DELAY	
	
	JB	BIT_esamtran,OBUMain_BEEP_APPAGAIN
	SETB	PIN_PWRDWN_LCD	
	JMP	AP_start		
OBUMain_BEEP_APPAGAIN:
	MOV	R7,#250
	;---CALL	_FUN_LIB_DELAY	
	JMP	AP_start
	
OBUMain_sys_OVER:
	MOV	IE,#0
	JMP	AP_start	
;/////////////////////////////////////////////////////////////////////////////////	
_FUN_OBUMAIN_SELECTDF01:
	JNB	BIT_ESAM,OBUMAIN_SELECTDF01_OVER
	;选择ESAM卡的DF01目录
	CLR	BIT_ESAMICC	
;	setb	BIT_GETRESULT
	clr	BIT_GETRESULT

	MOV	R7,#DATA_RXBUF
	MOV	R5,#XDATA_TXBUF
	MOV	R3,#0DFH
	MOV	R2,#001H		
	CALL	_FUN_CARDAPP_SelectFile			; 要将用户卡是否接收设成可选状态

	JZ	OBUMAIN_SELECTDF01_ESAMRight
	JNB	BIT_ESAMErr,OBUMAIN_SELECTDF01_OVER	
	CALL	_FUN_LIB_ESAMErr
OBUMAIN_SELECTDF01_ESAMRight:
	SETB	BIT_ESAMOK			;设置ESAM操作成功标记	
OBUMAIN_SELECTDF01_OVER:	
	RET
;------------------------------------
;描述:在发送结束后定时，接收，如果定时器超时，则程序从头开始执行。
;	1、发行正常结束
;	2、在XXms内没有任何RSU响应
;参数:
;无
;------------------------------------	
_FUN_OBUMain_TIMERX:
	
	JB	BIT_MMITIRMSTART,OBUMain_TIMERX_OVER
	SETB	BIT_MMITIRMSTART
	CLR	A
	;设置t1为8位重装载定时器
	;ORL	A,#00100000B
	;设置t0为16位定时器
	ORL	A,#00000001B
	MOV	TMOD,A
	;开启超时处理		超时时间限制
	SETB	TR0		;开启T0
	;---SETB	ET0		;开启T0使能
	;---SETB	EA
	MOV	DATA_PowerONTimer,#CONST_Pro_OverTime2S	
OBUMain_TIMERX_OVER:	
	RET		
;///////////////////////////////////////////////////////////////////////////////////// 
;	DBCB	
;/////////////////////////////////////////////////////////////////////////////////////
_fun_OBUMAIN_bdcb:
	ret
	
	JB	BIT_ISContact,OBUMAIN_bdcb_NZC			; 如果是接触卡，则选 1001，如果是非接卡，则Pro卡才选1001
	JB	BIT_proMF,OBUMAIN_bdcb_NZC
	jmp	OBUMAIN_bdcb_over
OBUMAIN_bdcb_NZC:
	
	;读出 0015 文件里的分散码
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#4
	CALL	_RDFlashXR
	
	;不是四川的卡
	;CB C4 B4 A8
	MOV	R0,#XDATA_HOLD
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0CBH
	JNZ	OBUMAIN_bdcb_ZZSC
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0C4H
	JNZ	OBUMAIN_bdcb_ZZSC
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0B4H
	JNZ	OBUMAIN_bdcb_ZZSC
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#0A8H
	JNZ	OBUMAIN_bdcb_ZZSC
	
	JMP	OBUMain_CardInfoDisplay_btVH02
OBUMAIN_bdcb_ZZSC:
	JMP	OBUMAIN_bdcb_over
	;当前是 四川 的卡时，比对车牌号
OBUMain_CardInfoDisplay_btVH02:
	
	;=== 读出0015文件里的车牌 ===
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L + 28
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#10
	CALL	_RDFlashXR
	
	;读出系统信息文件里的车牌1
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 27
	MOV	AR7,#XDATA_SC
	MOV	R3,#1
	CALL	_RDFlashXR
	
	;读出系统信息文件里的车牌1
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 36
	MOV	AR7,#XDATA_HOLD + 10
	MOV	R3,#10
	CALL	_RDFlashXR
	
	;读出系统信息文件里的车牌1
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL + 56
	MOV	AR7,#XDATA_HOLD + 20
	MOV	R3,#10;8
	CALL	_RDFlashXR
	
	;读出系统信息文件里的 车 牌 1
	MOV	DPH,#CONST_FLASH_SYSINFOH				; 
	MOV	DPL,#CONST_FLASH_SYSINFOL + 76				; 
	MOV	AR7,#XDATA_HOLD + 30					; 24
	MOV	R3,#10							; 8
	CALL	_RDFlashXR						; 
		
	PUSH	AR0
	MOV	R0,#XDATA_SC
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	
	POP	AR0	
	JZ	OBUMAIN_bdcb_over
	
	MOV	R2,#0				
OBUMAIN_bdcb_CPStartLOOP:			
	INC	R2				
OBUMAIN_bdcb_CP01:			
	CJNE	R2,#1,OBUMAIN_bdcb_CP02	
	MOV	R1,#XDATA_HOLD+10		
	JMP	OBUMAIN_bdcb_CP04		
OBUMAIN_bdcb_CP02:			
	CJNE	R2,#2,OBUMAIN_bdcb_CP03	
	MOV	R1,#XDATA_HOLD + 20
	JMP	OBUMAIN_bdcb_CP04		
OBUMAIN_bdcb_CP03:
	MOV	R1,#XDATA_HOLD+30
OBUMAIN_bdcb_CP04:		
	MOV	R0,#XDATA_HOLD
	MOV	R3,#10;8
OBUMAIN_bdcb_VErrCPLOOP:;比对车牌循环
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
	JNZ	OBUMAIN_bdcb_CPDif
	INC	R0
	INC	R1
	DJNZ	R3,OBUMAIN_bdcb_VErrCPLOOP	
OBUMAIN_bdcb_ZC:		
	;setb	BIT_CKXT
	jmp	OBUMAIN_bdcb_over
OBUMAIN_bdcb_CPDif:
	CJNE	R2,#4,$+3
	JNC	OBUMAIN_bdcb_over
	PUSH	AR0
	MOV	R0,#XDATA_SC
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	POP	AR0	
	MOV	B,R2
	XRL	A,B
	JNZ	OBUMAIN_bdcb_CPStartLOOP
OBUMAIN_bdcb_over:;
	ret		
;----------------------------------------------------------------------	
; RTC 处理函数
;	用于 RTC 取 CELLID 时
;----------------------------------------------------------------------
_FUN_OBUMain_RTCUP:	
	CALL	_FUN_GSM_RTCOFF	
	RET
;///////////////////////////////////////////////////////////////////////////////////
;低电压报警
;	1、查看当前是否连接USB
;	2、查看当前是否
;
;返回值
;	R7	=	CONST_STATE_FALSE  低电压
;		=	CONST_STATE_TRUE   电压正常
;///////////////////////////////////////////////////////////////////////////
_FUN_OBUMain_CardInfoDisplay02:		
	CALL	_Func_LCD_INIT	
OBUMain_CardInfoDisplay02_cpbf:;显示车牌子不符	
	
	JNB	BIT_CD,OBUMain_CardInfoDisplay02_Start			;如果不是失效，则跳过
	JNB	BIT_ACTIVECARD,OBUMain_CardInfoDisplay02_Start		;如果不是插卡，则跳过
	
;------------增加亮红灯----------------------------------
	CLR	Pin_red		;2010-04-21
;--------------------------------------------------------
	
	;显示拆动标记
	MOV	R7,#00000010B
	CALL	_FUN_LCD_ICON
	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_UNFIX
	CALL	_FUN_LCD_DisplayExChina
	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY							; MCU启动时要加延时，以便电压稳定后再操作卡片
	SETB	Pin_red								;2010-04-21
OBUMain_CardInfoDisplay02_Start:
	JB	BIT_INSERTCARD,OBUMain_CardInfoDisplay02_CardInfo	
OBUMain_CardInfoDisplay02_NOCardInfo:						;没卡信息处理	
OBUMain_CardInfoDisplay02_CKOver:	
	CLR	Pin_522_RST
	CLR	PIN_RED
	;+++ SETB	PIN_GRE	
	;--- 显示 ---
	MOV	R7,#DATA_RXBUF
	MOV	DPTR,#STR_NOCARD
	CALL	_FUN_LCD_DisplayExChina	
	JNB	BIT_SETMMI,OBUMain_CardInfoDisplay02_NOCardSetmmiOV	
	MOV 	R7,#100
	CALL	_FUN_LIB_BEEP							;响铃
	SETB	PIN_RED		
OBUMain_CardInfoDisplay02_NOCardSetmmiOV:		
	JMP	OBUMain_CardInfoDisplay02_Over	
OBUMain_CardInfoDisplay02_CardInfo:;有卡信息处理
	JB	BIT_ISContact,OBUMain_CardInfoDisplay02_GETCPUINFO		; 当前是接触卡时，取CPU卡信息，并显示
	JB	BIT_PROMF,OBUMain_CardInfoDisplay02_GETCPUINFO			; 当前是PRO卡时，取CPU卡信息，并显示
	MOV	A,#CONST_CARD_PASS						; 当前是MF卡时，则显示'通行卡'
	JMP	OBUMain_CardInfoDisplay02_Info
OBUMain_CardInfoDisplay02_GETCPUINFO:						; 取CPU卡信息	 
	;读0015文件中第9个字节[ 卡类型 ]
	MOV	DPH,#CONST_FLASH_0015H
	MOV	DPL,#CONST_FLASH_0015L + 8
	MOV	R3,#1								;0015文件长度	
	MOV	R7,#XDATA_TXBUF
	CALL	_RDFlashXR							;读Falsh函数只操作了	r0，所以暂不push r1	
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	;call	_fun_test_display
OBUMain_CardInfoDisplay02_Info:							;显示卡信息	
	CJNE	A,#CONST_CARD_CONSUME,OBUMain_CardInfoDisplay02_PassCard
OBUMain_CardInfoDisplay02_CashCard:						;储值卡
	
 	;读钱包
	MOV	DPH,#CONST_FLASH_0002H
	MOV	DPL,#CONST_FLASH_0002L
	MOV	R3,#4								;0015文件长度	
	MOV	R7,#XDATA_TXBUF
	CALL	_RDFlashXR							;读Falsh函数只操作了	r0，所以暂不push r1	
	
	;判断是否都是0xFF
	MOV	R0,#XDATA_TXBUF
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay02_CashCardcpv
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay02_CashCardcpv
	
	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay02_CashCardcpv	

	INC	R0
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	xrl	a,#0ffh
	jnz	OBUMain_CardInfoDisplay02_CashCardcpv	
	jmp	OBUMain_CardInfoDisplay02_Other	
OBUMain_CardInfoDisplay02_CashCardcpv:
	;将值 Copy 到 #Money 内存中去
	MOV	R3,#4
	MOV	R1,#XDATA_TXBUF
	MOV	R0,#MONEY
CARDACTIVE_CashCard_CopyMoney02:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	MOV	@R0,A
	INC	R0
	INC	R1
	DJNZ	R3,CARDACTIVE_CashCard_CopyMoney02	
OBUMain_CardInfoDisplay02_Money:	
	CLR	PIN_GRE
	SETB	PIN_RED
	
	;--- 显示余额或通行卡 ---
	MOV	R7,#00000100B
	CALL	_FUN_LCD_ICON
	
	MOV 	R7,#DATA_RXBUF
	LCall 	_dspmoney						;显示新余额	
	;+++ SETB	PIN_GRE
	JMP	OBUMain_CardInfoDisplay02_Over
	
OBUMain_CardInfoDisplay02_PassCard:	;通行卡
	CJNE	A,#CONST_CARD_PASS,OBUMain_CardInfoDisplay02_Other
	;--- 显示通行卡 ---
	CLR	PIN_GRE
	SETB	PIN_RED
	
	MOV	R7,#DATA_RXBUF + 90
	MOV	DPTR,#STR_PASS
	CALL	_FUN_LCD_DisplayExChina
	
	;+++ SETB	PIN_GRE
	JMP	OBUMain_CardInfoDisplay02_Over	
OBUMain_CardInfoDisplay02_Other:	;其它
	CLR	Pin_522_RST
	
	
	
	;--- 卡类型不对时，显示"错卡" ---
	MOV	R7,#DATA_RXBUF+90
	MOV	DPTR,#STR_ErrCARD
	CALL	_FUN_LCD_DisplayExChina
	;+++ SETB	PIN_GRE	
	CLR	PIN_RED	
	JMP	OBUMain_CardInfoDisplay02_Over		
	
OBUMain_CardInfoDisplay02_Over:		
	JNB	BIT_INSERTCARD,OBUMain_CardInfoDisplay02_Over02	
	
	;=1不启用 = 0启用
	MOV	A,#CONST_INPUT_ISEnable
	JNZ	OBUMain_CardInfoDisplay02_Over02	
	
	MOV	DPH,#CONST_FLASH_0019H
	MOV	DPL,#CONST_FLASH_0019L + 13
	MOV	AR7,#XDATA_HOLD
	MOV	R3,#1
	CALL	_RDFlashXR	
	MOV	R0,#XDATA_HOLD
	
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_MTC_INPUT
	JZ	OBUMain_CardInfoDisplay02_IN
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	XRL	A,#CONST_ETC_INPUT
	JZ	OBUMain_CardInfoDisplay02_IN
	JMP	OBUMain_CardInfoDisplay02_Over02
	
OBUMain_CardInfoDisplay02_IN:;显示入口信息
	
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY
	MOV	R7,#DATA_RXBUF+90
	MOV	DPTR,#STR_INFLAG
	CALL	_FUN_LCD_DisplayExChina
	
OBUMain_CardInfoDisplay02_Over02:
	MOV	R7,#250
	CALL	_FUN_LIB_DELAY
	
	RET
;///////////////////////////////////////////////////////////////////////////////////
_FUN_CC1101_spioSingleSoft02:
;	CLR	Pin_CC1101_SS
CC1101_spioSingleSoft02_S:
	NOP
	NOP
	NOP
	NOP
	NOP
		
	;写地址
	MOV	R3,#8
CC1101_spioSingleSoft02_WriteAddrLOOP:
;	CLR	PIN_CC1101_SCLK				;4	
	RLC	A					;1
;	MOV	PIN_CC1101_MOSI,C			;4	
	NOP
	NOP
;	SETB	PIN_CC1101_SCLK				;4	
	MOV	C,PIN_522_MISO
	DJNZ	R3,CC1101_spioSingleSoft02_WriteAddrLOOP	;4	
	RLC	A					;1
	MOV	B,A		
CC1101_spioSingleSoft02_WriteDAOVLOOP:
	NOP
	NOP
	NOP
	NOP
	NOP
	RET	
;///////////////////////////////////////////////////////////////////////////////////
_FUN_OBUMAIN_PreSleep:
	CLR	TR0		;关闭T0
	CLR	ET0		;关闭T0使能
	CLR	EA		
	;--- 清除Flash ---
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	R3,#1
	CALL	_eraseflash
	
	;--- 如果交易成功就记录天线ID ---
	;写卡片信息到Flash中去
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	R7,#XDATA_BeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen	
	CALL	_wrflashXR	
	CALL	OBUMain_CARDPreDeal_ReadSysInfo				;简化版预读	
	CALL	_FUN_GSM_Insert
	
	RET	
;///////////////////////////////////////////////////////////////////////////////////
;	补充预读
;///////////////////////////////////////////////////////////////////////////////////
_FUN_OBUMAIN_PrePu:	
	MOV	DPH,#CONST_FLASH_SYSINFOH
	MOV	DPL,#CONST_FLASH_SYSINFOL
	MOV	R3,#1
	CALL	_eraseflash	
	;--- 如果交易成功就记录天线ID ---
	;写卡片信息到Flash中去
	MOV	DPH,#CONST_Flash_BeaconIDUnixTimeH
	MOV	DPL,#CONST_Flash_BeaconIDUnixTimeL
	MOV	R7,#XDATA_LastBeaconID
	MOV	R3,#CONST_Flash_BeaconIDUnixTimeLen	
	CALL	_wrflashXR	
	CALL	OBUMain_CARDPreDeal_ReadSysInfo				;简化版预读		
	RET
;///////////////////////////////////////////////////////////////////////////////////
;		一般性错误	01	导入失败	STR_InputFail
;		合同号不同	02	非法导入卡	STR_IllegalInputCard
;		使用次数=FFH	03	导入卡失效	STR_InputCardInvalid
;		成功		00	导入成功	STR_InputOk
;		非导入卡	FF

;		一般性错误	04	激活失败	STR_ActiveFail
;		合同号不同	05	非法激活卡	STR_IllegalACTCard
;		使用次数=FFH	06	激活卡失效	STR_ACTCardInvalid
;		成功		00	激活成功	STR_ActiveOK
;		非激活卡	FF
;参数
;	R7	错误代码
;	R5
;返回值
;	DPTR	液晶显示值
;返回值
;	DPTR	液晶显示值
;///////////////////////////////////////////////////////////////////////////////////
_FUN_OBUMAIN_DR:
	
OBUMAIN_DR_00:
	CJNE	R7,#0,OBUMAIN_DR_01
	
DR_00_0D:
	CJNE	R5,#0DH,DR_00_0E
	MOV	DPTR,#STR_InputOk
	JMP	DR_00_0D0EOV
DR_00_0E:
	MOV	DPTR,#STR_ActiveOK	
DR_00_0D0EOV:
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_01:
	CJNE	R7,#1,OBUMAIN_DR_02
	MOV	DPTR,#STR_InputFail
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_02:
	CJNE	R7,#2,OBUMAIN_DR_03
	MOV	DPTR,#STR_IllegalInputCard
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_03:
	CJNE	R7,#3,OBUMAIN_DR_04
	MOV	DPTR,#STR_InputCardInvalid
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_04:
	CJNE	R7,#4,OBUMAIN_DR_05
	MOV	DPTR,#STR_ActiveFail
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_05:
	CJNE	R7,#5,OBUMAIN_DR_06
	MOV	DPTR,#STR_IllegalACTCard
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_06:
	CJNE	R7,#6,OBUMAIN_DR_OVER
	MOV	DPTR,#STR_ACTCardInvalid
	JMP	OBUMAIN_DR_OVER
OBUMAIN_DR_OVER:
	RET	
	
;--------------------------------------------------------	
;描述:
;	主程序错误提示
;参数:
;	a	错误代码
;	dptr	出错提示
;--------------------------------------------------------	
_FUN_OBUMAIN_ErrShow03:
	PUSH	ACC
	CALL	_Func_LCD_INIT	
	POP	ACC
	;--- 显示 ---
	MOV 	money,#0h			;
	MOV 	money + 1,#0h			;
	MOV 	money + 2,#0h			;
	MOV 	money + 3,A			;
	MOV 	R7,#DATA_RXBUF + 90		;
	CALL	_dspERRNUM	
	
	MOV	A,REG_5412AD_P0M0
	ORL	A,#00001100B
	MOV	REG_5412AD_P0M0,A
	MOV	A,REG_5412AD_P0M1
	ANL	A,#11110011B
	MOV	REG_5412AD_P0M1,A
	
	MOV	REG_5412AD_P0M0,#00001100B
	MOV	REG_5412AD_P0M1,#00000001B	
	
	MOV	R7,#255
	CALL	_FUN_LIB_BEEP
	MOV	R7,#255
	CALL	_FUN_LIB_BEEP	
	;JMP	AP_start
	RET


_FUN_OBUMAIN_ErrShow:
	PUSH	ACC
	CALL	_Func_LCD_INIT	
	POP	ACC
	;--- 显示 ---
	MOV 	money,#0h			;
	MOV 	money + 1,#0h			;
	MOV 	money + 2,#0h			;
	MOV 	money + 3,A			;
	MOV 	R7,#DATA_RXBUF + 90		;
	CALL	_dspERRNUM	
	
	MOV	A,REG_5412AD_P0M0
	ORL	A,#00001100B
	MOV	REG_5412AD_P0M0,A
	MOV	A,REG_5412AD_P0M1
	ANL	A,#11110011B
	MOV	REG_5412AD_P0M1,A
	
	MOV	REG_5412AD_P0M0,#00001100B
	MOV	REG_5412AD_P0M1,#00000001B	
	
	MOV	R7,#255
	CALL	_FUN_LIB_BEEP
	MOV	R7,#255
	CALL	_FUN_LIB_BEEP	
	JMP	AP_start
	RET
		
;///////////////////////////////////////////////////////////////////////////////////////////////////////////
_FUN_OBUMAIN_ErrShow02:
	
;	PUSH	ACC
;	CALL	_Func_LCD_INIT	
;	POP	ACC
	
	;--- 显示 ---
;	MOV 	money,#0h			;
;	MOV 	money + 1,#0h			;
;	MOV 	money + 2,#0h			;
;	MOV 	money + 3,A			;
;	MOV 	R7,#DATA_RXBUF + 90		;
;	CALL	_dspERRNUM	
	
;	MOV	A,REG_5412AD_P0M0
;	ORL	A,#00001100B
;	MOV	REG_5412AD_P0M0,A
;	MOV	A,REG_5412AD_P0M1
;	ANL	A,#11110011B
;	MOV	REG_5412AD_P0M1,A
	
;	MOV	REG_5412AD_P0M0,#00001100B
;	MOV	REG_5412AD_P0M1,#00000001B

;	MOV	R7,#255
;	CALL	_FUN_LIB_BEEP
;	MOV	R7,#255
;	CALL	_FUN_LIB_BEEP	
	
;OBUMAIN_ErrShow02_loop:
;	MOV	R7,#255
;	CALL	_FUN_LIB_BEEP
;	MOV	R7,#255
;	CALL	_FUN_LIB_BEEP
;	MOV	REG_WDT_CONTR,#00111111B
;	jmp	OBUMAIN_ErrShow02_loop
;	JMP	AP_start
	RET
;/////////////////////////////////////////////////////////////////////////////////////////
_FUN_OBUMAIN_CheckMemoryAndEx:

	MOV	DPH,#1
	MOV	DPL,#0;0
	MOV	R3,#255
	MOV	A,#0
OBUMAIN_CheckMemoryAndEx2_CheckMovx:
	MOVX	@DPTR,A
	INC	A
	INC	DPTR
	DJNZ	R3,OBUMAIN_CheckMemoryAndEx2_CheckMovx
	
	;MOV	DPH,#1
	MOV	DPL,#0;0
	MOV	R3,#255
OBUMAIN_CheckMemoryAndEx2_CheckMovxISOK:
	MOVX	A,@DPTR
	XRL	A,DPL
	JNZ	OBUMAIN_CheckMemoryAndEx_CheckMovxERR03
	INC	DPTR
	DJNZ	R3,OBUMAIN_CheckMemoryAndEx2_CheckMovxISOK
	
	;MOV	DPH,#1
	MOV	DPL,#00;0
	MOV	R3,#255
OBUMAIN_CheckMemoryAndEx2_CheckMovxISOK2:
	MOVX	A,@DPTR
	XRL	A,DPL
	JNZ	OBUMAIN_CheckMemoryAndEx_CheckMovxERR
	INC	DPTR
	DJNZ	R3,OBUMAIN_CheckMemoryAndEx2_CheckMovxISOK2
	
	;内存
	MOV	R0,#7
	MOV	R3,#128
	;CLR	A
	MOV	A,#7
OBUMAIN_CheckMemoryAndEx_CheckMov:
	mov	@R0,A
	INC	A
	INC	R0
	DJNZ	R3,OBUMAIN_CheckMemoryAndEx_CheckMov
	
	MOV	R0,#7
	MOV	R3,#128
;	CLR	A
OBUMAIN_CheckMemoryAndEx_CheckMovISOK:
	mov	A,@R0
;	XRL	A,R0
	INC	R0
	DJNZ	R3,OBUMAIN_CheckMemoryAndEx_CheckMovISOK
	
	
	MOV	R0,#7
	MOV	R3,#128
	;CLR	A
OBUMAIN_CheckMemoryAndEx_CheckMovISOK2:
	mov	A,@R0
	XRL	A,R0
	JNZ	OBUMAIN_CheckMemoryAndEx_CheckMovERR
	INC	R0
	DJNZ	R3,OBUMAIN_CheckMemoryAndEx_CheckMovISOK2		
	MOV	R7,#CONST_STATE_TRUE
	RET
	
OBUMAIN_CheckMemoryAndEx_CheckMovxERR:	
	MOV	R7,#CONST_STATE_ExMemoryEr	
	RET
	
OBUMAIN_CheckMemoryAndEx_CheckMovERR:
	MOV	R7,#CONST_STATE_MemoryEr	
	RET
	
OBUMAIN_CheckMemoryAndEx_CheckMovxERR03:
	;MOV	AR7,AR0
	mov	r7,#CONST_STATE_ExMemoryEr02
	RET	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
;///////////////////////////////////////////////////////////////////////////////////////////////////////////	
		
		
	END

