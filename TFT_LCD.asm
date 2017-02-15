;**********************************************************
;液晶说明
;本LCD共4行，每行96列
;1-3行是点阵行，8行是图案行

;_Func_LCD_Wdata 函数是向LCD发送指命
;	R7 = 0表示发送指令;R5 = 可以是行值、列值
;	先发行值,再发列值
;	行值XH,		参数应填 	R7 = 0 R5 = BXH
;	列值XYH,	参数应填	R7 = 0 R5 = 1XH		R7 = 0 R5=0YH, 所以发送列值调用_Func_LCD_Wdata两次
;	R7 = 1表示发送数据;R5可以是点阵数据
;	R5=0 表示当前点阵暗，R5 = FF 表示当前点阵亮
;==========================================================
;_Func_LCD_INIT			---	初始化LCD
;_dspmoney			---	显示金额
;_FUN_LCD_DisplayExChina	---	显示汉字
;_FUN_LCD_ICON			---	显示图案
;**********************************************************
NAME 	LCD_SPACE
	
$INCLUDE(LCD.INC)
$INCLUDE(COMMON.INC)
	
	RSEG	?pr?Lcd?Mater
	USING	0
	
_dspmoney:
	push ar7
	mov a,r7
	;---add a,#7
	add a,#9
	mov r3,a
	;add a,#6
	;mov r0,a
	
	mov r4,money
	mov r5,money + 1
	mov r6,money + 2
	mov r7,money + 3
       	;---mov r1,#8
       	mov r1,#10
       	mov a,r4
       	jnb acc.7,_dspmoney1			; 显示金额
       	mov a,#0ffh
       	xrl ar4,a
       	xrl ar5,a
       	xrl ar6,a
       	xrl ar7,a
_dspmoney1:
	;push	ar3
       	call	_fdiv10
	POP	AR7
       	CALL	_FUN_LCD_DisplayExMoney
       	;pop	acc
	RET
	
;显示错误代码	
_dspERRNUM:
	push ar7
	mov a,r7
	;---add a,#7
	add a,#9
	mov r3,a
	;add a,#6
	;mov r0,a
	
	mov r4,money
	mov r5,money + 1
	mov r6,money + 2
	mov r7,money + 3
       	;---mov r1,#8
       	mov r1,#10
       	mov a,r4
       	jnb acc.7,_dspERRNUM1			; 显示金额
       	mov a,#0ffh
       	xrl ar4,a
       	xrl ar5,a
       	xrl ar6,a
       	xrl ar7,a
_dspERRNUM1:
	;push	ar3
       	call	_fdiv10
	POP	AR7
       	CALL	_FUN_LCD_DisplayExMoney02
       	;pop	acc
	RET	
	
	
; r7,r5
_fdiv10:	
        mov a,r3
        xch a,r1
        mov r3,a
_fdiv10a:
        mov r2,#4
        mov r0,#ar4
        clr a
_fdiv10b:
        xchd a,@r0
        xch a,@r0               ;; (r+h) /10
        swap a                  ;; @r0 = l
        mov b,#10
        div ab
        swap a
        xch a,@r0               ;; h=s
        swap a
        orl a,b
        swap a                  ;; (r+l)/10
        mov b,#10
        div ab
        xchd a,@r0              ;; l=s
        mov a,b
        inc r0
        djnz r2,_fdiv10b

        mov @r1,a
        ;inc r1
        dec r1

        mov a,r4
        orl a,r5
        orl a,r6
        orl a,r7
        jz _fdiv10e

        djnz r3,_fdiv10a

        ret
_fdiv10d:
        mov @r1,#0bh
        ;inc r1
        dec r1
_fdiv10e:
        djnz r3,_fdiv10d
        ret
;--------------------------------	
;向LCD发送数据或命令(单字节)
;外部参数:
;R7	---	标记当前对LCD是发送指令还是数据。其值只能=0(表cmd)或=1(表data)
;R5	---	将要发送的字节
;内部参数
;R3	---	
;无返回
;--------------------------------
_Func_LCD_Wdata:
	;---CLR	Pin_LCD_CS

	MOV	A,R7
	CLR	C	
	RRC	A
	MOV	Pin_LCD_DC,C

	PUSH	AR3
	MOV	R3,#08	
	MOV	A,R5
LCD_Wdata_lOOPSEND:
	CLR	Pin_LCD_SCL
	CLR	C
	RLC	A
	MOV	Pin_LCD_SDA,C
	SETB	Pin_LCD_SCL		
	DJNZ	R3,LCD_Wdata_lOOPSEND
	POP	AR3

	;MOV	A,R7
	;CPL	A
	;CLR	C	
	;RRC	A		
	;MOV	Pin_LCD_DC,C
	
	CPL	Pin_LCD_DC
	;SETB	Pin_LCD_CS

	RET
;-----------------------------------	
;初始化LCD
;参数(无)
;返回值(无)
;-----------------------------------
_Func_LCD_INIT:	
	
	;SETB	PIN_LCD_BG
	CLR	PIN_PWRDWN_LCD
	MOV	R7,#1
	CALL	_FUN_LIB_DELAY
	
SETB    Pin_LCD_RST             ;液晶复位腿为低	
CLR     Pin_LCD_SDA             ;液晶数据腿为低
CLR     Pin_LCD_SCL       	;液晶时钟腿为低
SETB    Pin_LCD_CS		;液晶片选腿为低
CLR     Pin_LCD_DC 		;液晶命令腿为低
MOV 	r7,#7;L4
djnz 	r7,$
	
	CLR	Pin_LCD_CS	
	CLR	Pin_LCD_RST
	
	MOV 	r7,#7;L4
	djnz 	r7,$
	
	SETB	Pin_LCD_RST
	
;===============================================
;        voidWriteCMD(0x00);   
;	 voidWriteCMD(0x10);	        
;        voidWriteCMD(0x40);	    // Set Startline to 00H        
;        voidWriteCMD(0xb0);	            
;	 voidWriteCMD(0xa2);	    // Set Bias to 1/9        
;	 voidWriteCMD(0xa1);//a0	 a1	// MX=0,Normal direction: Seg0->SEG131        
;	 voidWriteCMD(0xc0);//c8		// MY=1,Reverse direction: COM63->COM0        
;    	 voidWriteCMD(0xa6);     // Normal Display    
;    	 voidWriteCMD(0xa4);     // Normal Display       
;    	 voidWriteCMD(0x27);     // Set RR to 7.5V
;                            // V0=1.4*RR*(99+EV)/162=9.5V, So, set RR=5.0, EV=40(0x28)
;	 voidWriteCMD(0x81);     // Set EV to 0x28
;	 voidWriteCMD(0x0f);
 ;  	 voidWriteCMD(0x2f);     // All Boost on
;	 voidWriteCMD(0xaf);     // Set Display on
;===============================================	
	
      	MOV	R7,#0
      	MOV	R5,#000H
      	CALL	_Func_LCD_Wdata;LCD BIAS SET
      	
      	MOV	R5,#010H
      	CALL	_Func_LCD_Wdata;//ENTIRE DISPLAY ON/OFF

      	MOV	R5,#040H
      	CALL	_Func_LCD_Wdata;//NORMAL/REVERSE DISPLAY
     	
      	MOV	R5,#0B0H
      	CALL	_Func_LCD_Wdata;//Regulator Select 0x20-0x27
      	
      	MOV	R5,#0A2H
      	CALL	_Func_LCD_Wdata;///Set Reference Voltage Select Mode

      	MOV	R5,#0A1H
      	CALL	_Func_LCD_Wdata;///Set Reference Voltage Register 0x00-0x3F
      	     	
      	MOV	R5,#0C0H
      	CALL	_Func_LCD_Wdata;///Power Control On VC、VR、VF ON
      	      	
      	MOV	R5,#0A6H
      	CALL	_Func_LCD_Wdata      	
     
      	MOV	R5,#0A4H
      	CALL	_Func_LCD_Wdata;///Initial DisPlay Line 	

      	MOV	R5,#027H
      	CALL	_Func_LCD_Wdata;///Page Address Set BOH-B8H
      	
      	MOV	R5,#081H
      	CALL	_Func_LCD_Wdata;///DisPlay On   	
      	
      	MOV	R5,#00FH
      	CALL	_Func_LCD_Wdata;///ADC SET       	
      	
      	MOV	R5,#02FH
      	CALL	_Func_LCD_Wdata;///SHL Select   COM0-COM63  	
      	
      	MOV	R5,#0AFH
      	CALL	_Func_LCD_Wdata

      	;--- 清空液晶的符号页 --- 
      	MOV	R7,#1
	CALL	_FUN_Display_Clr
      	MOV	R7,#2
	CALL	_FUN_Display_Clr	
;      	MOV	R7,#3
;	CALL	_FUN_Display_Clr	
      	MOV	R7,#0
	CALL	_FUN_Display_Clr
	
	;显示电源图案
;	MOV	R7,#00001000B
;	CALL	_FUN_LCD_ICON
	RET	


	
;-----------------------------------	
;清除液晶显示
;内部参数
;R7
;-----------------------------------	
_FUN_Display_Clr:
	MOV	AR4,AR7

      	MOV	R7,#00H
      	MOV	A,#0B0H
      	ORL	A,R4
     	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
      	MOV	R7,#0
      	ORL	A,#10H
      	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
      	MOV	R7,#0
      	MOV	R5,#0
      	CALL	_Func_LCD_Wdata
      	
      	MOV	R2,#96
Display_Clr_lOOP:
      	MOV	R7,#01H
      	MOV	A,#00H
      	MOV	R5,A
      	CALL	_Func_LCD_Wdata
	DJNZ	R2,Display_Clr_lOOP
	
	RET

;-----------------------------------	
;显示金钱在液晶上
;外部参数
;R7	---	字符指针
;注数字必须在r7指向的buf的第三个字节开始
;如 69 70 01 02 3 04 05 06 07 -> 余额1234567
;-----------------------------------	
_FUN_LCD_DisplayExMoney:
	
	;--- 补上‘余额’两个汉字 ---
	MOV	AR0,AR7
	MOV	@R0,#69
	INC	R0
	MOV	@R0,#70
	INC	R0
	
	;--- 在金额最后两位前加小数点。如1234567 ->12345.67 ---	
	MOV	AR1,AR0
	INC	R1
	;---MOV	R3,#4
	MOV	R3,#5
LCD_DisplayExMoney_LOOP:
	MOV	A,@R1
	MOV	@R0,A
	INC	R1
	INC	R0
	DJNZ	R3,LCD_DisplayExMoney_LOOP	
	MOV	@R0,#10
	
	MOV	R5,#1		;R5	---	字符启始位置
	MOV	R3,#12		;r3	---	字符长度	
	JMP	_Func_LCD_Display 
;-----------------------------------	
;显示错误代码在液晶上
;外部参数
;R7	---	字符指针
;注数字必须在r7指向的buf的第三个字节开始
;如 69 70 01 02 3 04 05 06 07 -> 余额1234567
;-----------------------------------	
_FUN_LCD_DisplayExMoney02:
	
	;--- 补上'错误’两个汉字 ---
	MOV	AR0,AR7
	MOV	@R0,#63
	INC	R0
	MOV	@R0,#117
	INC	R0
	
	;--- 在金额最后两位前加小数点。如1234567 ->12345.67 ---	
	MOV	AR1,AR0
	INC	R1
	;---MOV	R3,#4
	MOV	R3,#5
LCD_DisplayExMoney_LOOP02:
	MOV	A,@R1
	MOV	@R0,A
	INC	R1
	INC	R0
	DJNZ	R3,LCD_DisplayExMoney_LOOP02	
	MOV	@R0,#10
	
	MOV	R5,#1		;R5	---	字符启始位置
	MOV	R3,#12		;r3	---	字符长度	
	JMP	_Func_LCD_Display 	
;-----------------------------------	
;显示汉字显示在液晶上
;外部参数
;R7	---	字符指针
;dptr	---	要显示的汉字地址
;-----------------------------------		
_FUN_LCD_DisplayExChina:
		
	MOV	AR0,AR7
	
	MOV	A,#0
	MOVC	A,@A + DPTR
	MOV	R3,A
	MOV	R1,#1
LCD_DisplayExChina_Loop:	
	MOV	A,R1
	MOVC	A,@A + DPTR
	MOV	@R0,A

	INC	R1
	INC	R0

	DJNZ	R3,LCD_DisplayExChina_Loop	
	
	MOV	R5,#1
	;---MOV	R3,#8
	MOV	R3,#12
		
;-----------------------------------	
;显示字符在液晶上(最多可以显示6个汉字,12个字符)
;汉字16*24 字符 8*24
;外部参数	
;R7	---	字符指针
;R5	---	字符启始位置
;R3	---	字符长度
;内部参数	
;R2	---	12-R3
;R0	---	临时变量
;R3	---	字符长度
;R4	---	当前显示字符的列值
;返回值(无)	
;-----------------------------------
_Func_LCD_Display:
;---	mov 	P2M0,#00H
;---	mov	p1m0,#0
		
 	;---反向--
 	MOV	AR6,AR7

	;计算第一字符的列值
	MOV	R4,#00H
	MOV	AR0,AR5
	DEC	R0
	MOV	A,R0
	JZ	LCD_Display_STARTLOOPOVER
LCD_Display_STARTLOOP:
	MOV	A,R4
	ADD	A,#8		
	MOV	R4,A
	DJNZ	R0,LCD_Display_STARTLOOP	
LCD_Display_STARTLOOPOVER:

	;--- 长度为零则退出 --- 	
	MOV	A,R3
	JZ	LCD_Display_TMP003
	JMP	LCD_Display_BYTELOOP
LCD_Display_TMP003:
	JMP	LCD_Display_Over
LCD_Display_BYTELOOP:

	;---定位字库---	
	;MOV	R2,#24
	;MOV	DPTR,#STR_Fontlib_50	;字库
	;--- 定位字库 ---
	MOV	R0,AR6
	MOV	A,@R0
	MOV	R7,A
	CJNE	R7,#50,$+3					;字符编码小于50，汉字编码大于等于50
	JC	LCD_Display_FontByte
	JMP	LCD_Display_FontChina
LCD_Display_FontByte:
	;---MOV	R2,#12
	MOV	R2,#8
	CLR	C
	MOV	A,R7
	SUBB	A,#0
	;---MOV	B,#36
	MOV	B,#24
	MUL	AB
	
	ADD	A,#LOW	STR_Fontlib_0
	MOV	DPL,A
	CLR	A
	MOV	A,B
	ADDC	A,#HIGH STR_Fontlib_0
	MOV	DPH,A
		
	JMP	LCD_Display_FontOver

LCD_Display_FontChina:
	;---MOV	R2,#24
	MOV	R2,#16
	CLR	C
	MOV	A,R7
	SUBB	A,#50
	;---MOV	B,#72
	MOV	B,#48
	MUL	AB
	
	ADD	A,#LOW	STR_Fontlib_50
	MOV	DPL,A
	CLR	A
	MOV	A,B
	ADDC	A,#HIGH STR_Fontlib_50
	MOV	DPH,A	
LCD_Display_FontOver:	

	;--- 定位行座标和纵座标 ---
	;MOV	R0,#1						;行座标
	MOV	R0,#0;1		;----------------------------------;行座标
	MOV	R1,#00H						;当前将要显示的字符	
LCD_Display_BYTELineLOOP:
      	
      	MOV	R7,#00H
      	MOV	A,#0B0H
      	ORL	A,R0
      	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
      	MOV	R7,#0
      	MOV	A,R4
      	SWAP	A
      	ANL	A,#0FH
      	ORL	A,#10H
      	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
      	MOV	R7,#0
      	MOV	A,R4
      	ANL	A,#0FH
      	MOV	R5,A
      	CALL	_Func_LCD_Wdata
			
	;CJNE	R2,#24,$+3
	CJNE	R2,#16,$+3
	JC	LCD_Display_BYTELINEBYTELOOP12START
	PUSH	AR3
	;---MOV	R3,#24	
	MOV	R3,#16	
LCD_Display_BYTELINEBYTELOOP24:		
	MOV	R7,#1
	MOV	A,R1
	MOVC	A,@A+DPTR
	MOV	R5,A
	CALL	_Func_LCD_Wdata
	INC	R1   	    	
	DJNZ	R3,LCD_Display_BYTELINEBYTELOOP24 
	POP	AR3	
	JMP	LCD_Display_BYTELINEBYTEOver	
	;MOV	A,R4						;移动当前列值
	;ADD	A,#24
	;MOV	R4,A	
	
	
LCD_Display_BYTELINEBYTELOOP12START:
	PUSH	AR3
	;---MOV	R3,#12
	MOV	R3,#8
LCD_Display_BYTELINEBYTELOOP12:		
	MOV	R7,#1
	MOV	A,R1
	MOVC	A,@A+DPTR
	MOV	R5,A
	CALL	_Func_LCD_Wdata
	INC	R1    	
	;CJNE	R1,#12,LCD_Display_BYTELINEBYTELOOP12      	
	DJNZ	R3,LCD_Display_BYTELINEBYTELOOP12 
	POP	AR3		
	;MOV	A,R4						;移动当前列值
	;ADD	A,#12
	;MOV	R4,A	
LCD_Display_BYTELINEBYTEOver:

      	INC	R0
	CJNE	R0,#4,LCD_Display_TMP001			;行循环
	
	;---CJNE	R2,#24,$+3
	CJNE	R2,#16,$+3
	JC	LCD_Display_DB
	DEC	R3						;当前是汉字时，因为R3是要显示的字节总长度，所以要减2,即 dec + djnz	
	MOV	A,R4						;移动当前列值
	;---ADD	A,#12
	ADD	A,#8
	MOV	R4,A		
LCD_Display_DB:
	MOV	A,R4						;移动当_FUN_LIB_LCD前列值
	;---ADD	A,#12
	ADD	A,#8
	MOV	R4,A	
	DJNZ	R3,LCD_Display_TMP002
LCD_Display_Over:	
	RET  
	    	
LCD_Display_TMP001:						;_FUNC_LCD_Display的临时段
	JMP	LCD_Display_BYTELineLOOP	
LCD_Display_TMP002:						;_FUNC_LCD_Display的临时段
	INC	R6
	JMP	LCD_Display_BYTELOOP

;	SETB	Pin_LCD_CS
	
	RET	        	
;-----------------------------------	
;显示图案
;外部参数

;	
;R7	---	 将要点亮的图案;
;	bit0 = 1 表示'信号'图案;
;	bit1 = 1 表示'C'图案;
;	bit2 = 1 表示'T'图案;
	
;	bit3 = 1 表示'电源'外框图案;
;	bit4 = 1 表示'电源'电源格1图案;
;	bit5 = 1 表示'电源'电源格2图案;
;	bit6 = 1 表示'电源'电源格3图案;
;	

;返回值(无)
;-----------------------------------
_FUN_LCD_ICON:
	
	MOV	A,R7
	
	;--- 显示信号 ---	
LCD_ICON_Signal:
	JNB	ACC.0,LCD_ICON_C
	PUSH	ACC

      	MOV	R7,#00H
      	MOV	A,#0B0H
      	ORL	A,#8
     	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
;      	MOV	R7,#0
      	MOV	R5,#10H
      	CALL	_Func_LCD_Wdata
      	
;      	MOV	R7,#0
      	MOV	R5,#4
      	CALL	_Func_LCD_Wdata
	
	MOV	R3,#10
LCD_ICON_DISSignal:
	MOV	R7,#1
	MOV	R5,#0FFH
      	CALL	_Func_LCD_Wdata	
	DJNZ	R3,LCD_ICON_DISSignal
	
	POP	ACC
	;--- 显示C ---	
LCD_ICON_C:
	JNB	ACC.1,LCD_ICON_T
	PUSH	ACC
	
      	MOV	R7,#00H
      	MOV	A,#0B0H
      	ORL	A,#8
     	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
;      	MOV	R7,#0
      	MOV	R5,#13H
      	CALL	_Func_LCD_Wdata
      	
;      	MOV	R7,#0
      	MOV	R5,#1
      	CALL	_Func_LCD_Wdata
      	
	MOV	R7,#1
	MOV	R5,#0FFH
	CALL	_Func_LCD_Wdata	
      	
	POP	ACC
	;--- 显示T ---
LCD_ICON_T:
	JNB	ACC.2,LCD_ICON_Power
	PUSH	ACC
	
      	MOV	R7,#00H
      	MOV	A,#0B0H
      	ORL	A,#8
     	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      	
      	MOV	R5,#14H
      	CALL	_Func_LCD_Wdata
      	
	;MOV	R7,#0
      	MOV	R5,#0
      	CALL	_Func_LCD_Wdata
      	
	MOV	R7,#1
	MOV	R5,#0FFH
      	CALL	_Func_LCD_Wdata
	
	POP	ACC
	
	;--- 显示电源 ---
LCD_ICON_Power:
	;JMP	LCD_ICON_Power01
	JNB	ACC.3,LCD_ICON_Over
	
	PUSH	ACC	
      	MOV	A,#0B0H
      	ORL	A,#8
     	MOV	R5,A
      	CALL	_Func_LCD_Wdata
      		
      	MOV	R5,#15H
      	CALL	_Func_LCD_Wdata
      		
      	MOV	R5,#0ch
      	CALL	_Func_LCD_Wdata

	;MOV	R3,#4
;LCD_INIT_DISPower:
	
	MOV	R7,#1
	MOV	R5,#0FFH
      	CALL	_Func_LCD_Wdata	      	
	POP	ACC
	
	PUSH	ACC
	MOV	R5,#0FFH
	JB	ACC.4,LCD_INIT_DISPower1
	MOV	R5,#0
LCD_INIT_DISPower1:	
	MOV	R7,#1	
      	CALL	_Func_LCD_Wdata	
      	POP	ACC
      	
	PUSH	ACC
	MOV	R5,#0FFH
	JB	ACC.6,LCD_INIT_DISPower2
	MOV	R5,#0
LCD_INIT_DISPower2:	
	MOV	R7,#1	
      	CALL	_Func_LCD_Wdata	
      	POP	ACC
      	
	PUSH	ACC
	MOV	R5,#0FFH
	JB	ACC.5,LCD_INIT_DISPower3
	MOV	R5,#0
LCD_INIT_DISPower3:	
	MOV	R7,#1	
      	CALL	_Func_LCD_Wdata	
      	POP	ACC      	    	

	;DJNZ	R3,LCD_INIT_DISPower
	;POP	ACC
	
LCD_ICON_Power01:
	;PUSH	ACC	
      	;MOV	A,#0B0H
      	;ORL	A,#8
     	;MOV	R5,A
      	;CALL	_Func_LCD_Wdata
      		
      	;MOV	R5,#15H
      	;CALL	_Func_LCD_Wdata
      	
      	;MOV	R5,#0ch
      	;CALL	_Func_LCD_Wdata	
	;MOV	R7,#1
	;MOV	R5,#0FFH
      	;CALL	_Func_LCD_Wdata	
	;POP	ACC
	
LCD_ICON_Power02:

	;JMP	LCD_ICON_Over
	;PUSH	ACC
      	;MOV	A,#0B0H
      	;ORL	A,#8
     	;MOV	R5,A
      	;CALL	_Func_LCD_Wdata
      	      	
      	;MOV	R5,#15H
      	;CALL	_Func_LCD_Wdata
      	      	
      	;MOV	R5,#0fh
      	;CALL	_Func_LCD_Wdata	      	
      	
	;MOV	R7,#1
	;MOV	R5,#0FFH
      	;CALL	_Func_LCD_Wdata	    
      	;POP	ACC
      	
LCD_ICON_Power03:
	;JNB	ACC.6,LCD_ICON_Over	
	;PUSH	ACC

	;MOV	A,#0B0H
      	;ORL	A,#8
     	;MOV	R5,A
      	;CALL	_Func_LCD_Wdata
      	
      	;MOV	R5,#15H
      	;CALL	_Func_LCD_Wdata
      	
      	;MOV	R5,#0eh
      	;CALL	_Func_LCD_Wdata	
      	
	;MOV	R7,#1
	;MOV	R5,#0FFH
      	;CALL	_Func_LCD_Wdata	       	  	
	;POP	ACC
LCD_ICON_Over:
	;JMP	LCD_ICON_Over
	
	RET
	
;------------------------------------------
;车牌翻译
;参数
;	R7	外存车牌
;	R5 	翻译后的内存指针
;1、头两个字节，对照表 STR_S_CODE 31个省份编码内如果找到，则编码号加108，否则用11代替
;2、后面的6个字节，则	>=41H <=5AH，则-51
;			>=61H <=7AH,则-83
;			>=30H <=39H，则-48
;	
;3、汉字区的内码范围高字节从B0-F7,低字节从A1-FE
;4、其它用11代替
;------------------------------------------
FUN_LCD_HVTransfer:
	
 	PUSH	AR7
	PUSH	AR5
	
	;样板车牌
	;R5	direct[0]
	;R7	
	MOV	DPTR,#STR_HV
	MOV	AR7,AR5
	INC	R7
	CALL	_FUN_LIB_FLASHTODATA
	POP	AR5
	POP	AR7
	;direct 11,11,122,0,1,2,3,4,5,11,11
	;sourde 0BDH,0F2H,39h,31h,32h,33h,34h,35h,00,00,00,00
	;r0	direct
	MOV	AR0,AR5
	
	MOV	A,R3		;len
	MOV	@R0,A		;diretct[0]
	
	MOV	A,R5		;
	ADD	A,#3		;8
	MOV	R5,A		;diretct[3]
	
	PUSH	AR5		;diretct[3]
	PUSH	AR7		;source[0]
	
	;direct 11,11,122,0,1,2,3,4,5,11,11
	;sourde 0BDH,0F2H,39h,31h,32h,33h,34h,35h,00,00,00,00	
	MOV	AR0,AR7		;r0 source
		;MOVX	A,@R0
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR		;
	MOV	B,A		;source.[0]
	
	;CALL	_FUN_test_display
	;=======================
	;r0 	source[0]
	;b  	source[0] content
	;r1 	p
	;r3 	count
	;R5	diretct[3]
	;R7	source[0]
	;=======================
	MOV	DPTR,#STR_S_CODE	;字库
	MOV	R1,#0
	MOV	R3,#41;31
LCD_HVTransfer_LOOP:
	MOV	A,R1
	MOVC	A,@A+DPTR
	XRL	A,B
	JNZ	LCD_HVTransfer_LOOPDIF
	
	INC	R0
		;MOVX	A,@R0
	push	dph
	push	dpl
	
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	pop	dpl
	pop	dph
	MOV	B,A
	;CALL	_FUN_test_display
	INC	R1
	MOV	A,R1
	MOVC	A,@A+DPTR
	XRL	A,B
	JZ	LCD_HVTransfer_LOOPOVER
	INC	R1
	
	DEC	R0
		;MOVX	A,@R0
	push	dph
	push	dpl		
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR
	pop	dpl
	pop	dph	
	MOV	B,A
	
	DJNZ	R3,LCD_HVTransfer_LOOP
	JMP	LCD_HVTransfer_LOOPOVER
	
LCD_HVTransfer_LOOPDIF:
	INC	R1
	INC	R1
	DJNZ	R3,LCD_HVTransfer_LOOP
LCD_HVTransfer_LOOPOVER:
	
	POP	AR7	;r7	source
	POP	AR5	;r5	diretct +3
	
	;根据R3[字库编码]，对应相应的字
	;如果R3=0，表示没有找到，在文件，或数字中找，如果还找不到，则用11,11空白表示
	;如果找到了则填写相应的字库编码
	MOV	A,R3
	;CALL	_FUN_test_display
	JNZ	LCD_HVTransfer_RICP
LCD_HVTransfer_ERRCP:
		
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	;DB	12,11,11,6,7,0,1,2,3,4,5,11,11
	;R5	diretct[3]
	;R7	source[0]	
	;样板车牌
 	PUSH	AR7
	PUSH	AR5
	MOV	DPTR,#STR_HV02
	MOV	AR7,AR5	;diretct[3]
	DEC	R7	;diretct[2]
	DEC	R7	;diretct[1]
	;INC	R7
	CALL	_FUN_LIB_FLASHTODATA
	POP	AR5
	POP	AR7
	
	;MOV	A,R5
	;ADD	A,#3		;8
	;MOV	R5,A		;diretct + 8
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	MOV	R3,#08
	MOV	AR1,AR7		;source[0]
	MOV	AR0,AR5		;direct[0]
	
	JMP	LCD_HVTransfer_CPOVER
LCD_HVTransfer_RICP:
	
	MOV	B,A		; 
	MOV	A,#41;31		; 
	CLR	C		; 
	SUBB	A,B		; 
	
	;call	_fun_test_display
	CLR	C		; 
	ADD	A,#122		; 108
	
	MOV	AR0,AR5		; diretct[3]
	MOV	@R0,A		; 
	INC	R0		; diretct[4]
	
	MOV	AR1,AR7		; source[0]
	INC	R1		; source[1]
	INC	R1		; source[2]
	
	MOV	R3,#06	
LCD_HVTransfer_CPOVER:	

	;R3	还有几个字符
	;R0	Direct
	;R1	Source
LCD_HVTransfer_LOOP02:
		;MOVX	A,@R1
	MOV	DPH,#1
	MOV	DPL,R1
	MOVX	A,@DPTR
	
	;>=30H <=39H，则-48
LCD_HVTransfer_LOOP02SZ:;数字	
	CJNE	A,#40H,$+3
	JNC	LCD_HVTransfer_LOOP02DZ
	
	CJNE	A,#30H,$+3
	JC	LCD_HVTransfer_LOOP02DZ
	
	CLR	C
	SUBB	A,#30H
	MOV	@R0,A
	
	JMP	LCD_HVTransfer_LOOP02Next
	
LCD_HVTransfer_LOOP02DZ:;大写字母
	
	;>=41H <=5AH，则-52
	CJNE	A,#5BH,$+3
	JNC	LCD_HVTransfer_LOOP02JZ

	CJNE	A,#41H,$+3
	JC	LCD_HVTransfer_LOOP02JZ
	
	CLR	C
	SUBB	A,#51
	MOV	@R0,A
	
	JMP	LCD_HVTransfer_LOOP02Next
	
LCD_HVTransfer_LOOP02JZ:;小写字母
	;>=61H <=7AH,则-84
	CJNE	A,#7BH,$+3
	JNC	LCD_HVTransfer_LOOP02WX

	CJNE	A,#61H,$+3
	JC	LCD_HVTransfer_LOOP02WX
	
	CLR	C
	SUBB	A,#83
	MOV	@R0,A
	
	JMP	LCD_HVTransfer_LOOP02Next

LCD_HVTransfer_LOOP02WX:;无效
	MOV	A,#11H
	MOV	@R0,A
LCD_HVTransfer_LOOP02Next:;无效
	INC	R0
	INC	R1
	DJNZ	R3,LCD_HVTransfer_LOOP02
	
	RET
;---------------------------------------
	
	END
;////////////////////////////////////////////////////////////////////////////////////////////////////////

