	
BRT					EQU	09CH
Reg_Sys_BRT				EQU	09CH
;RegBit_SysBRT_S1BRS			BIT	Reg_Sys_BRT.1

S2CON					EQU	09AH
S2BUF					EQU	09BH
IE2					EQU	0AFH
RELOAD2_CONTR				EQU	0EAH
	
CONST_TIMEER02				EQU	1	;一周6秒
CONST_TIMEER03				EQU	254;245
CONST_TIMEER04				EQU	1

REG_51_AUXR1				EQU	0A2H
EPCAI					BIT	IE.6
;/////////////////////////////////////////////////////////////////////////////////////////////////
;NEW LCD
;PIN_Sys_IsDownload			BIT	P3.7
;PIN_LCD_OLEDD1				BIT	P1.2
;PIN_LCD_OLEDD0				BIT	P1.3
;PIN_LCD_OLEDDC				BIT	P1.4
;PIN_LCD_OLEDRES			BIT	P1.5
;PIN_LCD_OLEDCS				BIT	P4.3
;PIN_LCD_BG				BIT	P1.1
;PIN_OLED_ENSY7208			BIT	P4.0
P4					EQU	0C0H
;-----------------------------------------------------------------------------------------------
CONST_MAX_RXNUM				EQU	5
;TI_CCxxx0_SRES				EQU	30H
;Configuration Registers		
CONST_GDO2_VALUE			EQU	46h;046H	;06H
CONST_GDO2_MCSM2			EQU	2;03H
read_burst				EQU	0C0H
TI_CCxxx0_IOCFG2       			EQU	00H        ;GDO2 output pin configuration
TI_CCxxx0_IOCFG1       			EQU	01H        ;GDO1 output pin configuration
TI_CCxxx0_IOCFG0       			EQU	02H        ;GDO0 output pin configuration
TI_CCxxx0_FIFOTHR      			EQU	03H        ;RX FIFO and TX FIFO thresholds
TI_CCxxx0_SYNC1        			EQU	04H        ;Sync word, high byte
TI_CCxxx0_SYNC0        			EQU	05H        ;Sync word, low byte
TI_CCxxx0_PKTLEN       			EQU	06H        ;Packet length
TI_CCxxx0_PKTCTRL1     			EQU	07H        ;Packet automation control
TI_CCxxx0_PKTCTRL0     			EQU	08H        ;Packet automation control
TI_CCxxx0_ADDR         			EQU	09H        ;Device address
TI_CCxxx0_CHANNR       			EQU	0AH        ;Channel number
TI_CCxxx0_FSCTRL1      			EQU	0BH        ;Frequency synthesizer control
TI_CCxxx0_FSCTRL0      			EQU	0CH        ;Frequency synthesizer control
TI_CCxxx0_FREQ2        			EQU	0DH        ;Frequency control word, high byte
TI_CCxxx0_FREQ1        			EQU	0EH        ;Frequency control word, middle byte
TI_CCxxx0_FREQ0        			EQU	0FH        ;Frequency control word, low byte
TI_CCxxx0_MDMCFG4      			EQU	10H        ;Modem configuration
TI_CCxxx0_MDMCFG3      			EQU	11H        ;Modem configuration
TI_CCxxx0_MDMCFG2      			EQU	12H        ;Modem configuration
TI_CCxxx0_MDMCFG1      			EQU	13H        ;Modem configuration
TI_CCxxx0_MDMCFG0      			EQU	14H        ;Modem configuration
TI_CCxxx0_DEVIATN      			EQU	15H        ;Modem deviation setting
TI_CCxxx0_MCSM2        	EQU	16H        ;Main Radio Cntrl State Machine config
TI_CCxxx0_MCSM1        	EQU	17H        ;Main Radio Cntrl State Machine config
TI_CCxxx0_MCSM0        	EQU	18H        ;Main Radio Cntrl State Machine config
TI_CCxxx0_FOCCFG       	EQU	19H        ;Frequency Offset Compensation config
TI_CCxxx0_BSCFG        	EQU	1AH        ;Bit Synchronization configuration
TI_CCxxx0_AGCCTRL2     	EQU	1BH        ;AGC control
TI_CCxxx0_AGCCTRL1     	EQU	1CH        ;AGC control
TI_CCxxx0_AGCCTRL0     	EQU	1DH        ;AGC control
TI_CCxxx0_WOREVT1      	EQU	1EH        ;High byte Event 0 timeout
TI_CCxxx0_WOREVT0      	EQU	1FH        ;Low byte Event 0 timeout
TI_CCxxx0_WORCTRL      	EQU	20H        ;Wake On Radio control
TI_CCxxx0_FREND1       	EQU	21H        ;Front end RX configuration
TI_CCxxx0_FREND0       	EQU	22H        ;Front end TX configuration
TI_CCxxx0_FSCAL3       	EQU	23H        ;Frequency synthesizer calibration
TI_CCxxx0_FSCAL2       	EQU	24H        ;Frequency synthesizer calibration
TI_CCxxx0_FSCAL1       	EQU	25H        ;Frequency synthesizer calibration
TI_CCxxx0_FSCAL0       	EQU	26H        ;Frequency synthesizer calibration
TI_CCxxx0_RCCTRL1      	EQU	27H        ;RC oscillator configuration
TI_CCxxx0_RCCTRL0      	EQU	28H        ;RC oscillator configuration
TI_CCxxx0_FSTEST       	EQU	29H        ;Frequency synthesizer cal control
TI_CCxxx0_PTEST        	EQU	2AH        ;Production test
TI_CCxxx0_AGCTEST      	EQU	2BH        ;AGC test
TI_CCxxx0_TEST2        	EQU	2CH        ;Various test settings	
TI_CCxxx0_TEST1        	EQU	2DH        ;Various test settings
TI_CCxxx0_TEST0        	EQU	2EH        ;Various test settings

;Strobe commands
TI_CCxxx0_SRES         	EQU	30H        ;Reset chip.
TI_CCxxx0_SXOFF        	EQU	32H        ;Turn off crystal oscillator.
TI_CCxxx0_SCAL         	EQU	33H        ;Calibrate freq synthesizer & disable
TI_CCxxx0_SRX          	EQU	34H        ;Enable RX.
TI_CCxxx0_STX          	EQU	35H        ;Enable TX.
TI_CCxxx0_SIDLE        	EQU	36H        ;Exit RX / TX
TI_CCxxx0_SAFC         	EQU	37H        ;AFC adjustment of freq synthesizer
TI_CCxxx0_SWOR         	EQU	38H        ;Start automatic RX polling sequence
TI_CCxxx0_SPWD         	EQU	39H        ;Enter pwr down mode when CSn goes hi
TI_CCxxx0_SFRX         	EQU	3AH        ;Flush the RX FIFO buffer.
TI_CCxxx0_SFTX         	EQU	3BH        ;Flush the TX FIFO buffer.
TI_CCxxx0_SWORRST      	EQU	3CH        ;Reset real time clock.
TI_CCxxx0_SNOP         	EQU	3DH        ;No operation.
	
;Status_registers
TI_CCxxx0_PARTNUM      			EQU	30H        ;Part number
TI_CCxxx0_VERSION      			EQU	31H        ;Current version number
TI_CCxxx0_FREQEST      			EQU	32H        ;Frequency offset estimate
TI_CCxxx0_LQI          			EQU	33H        ;Demodulator estimate for link quality
TI_CCxxx0_RSSI         			EQU	34H        ;Received signal strength indication
TI_CCxxx0_MARCSTATE    			EQU	35H        ;Control state machine state
TI_CCxxx0_WORTIME1     			EQU	36H        ;High byte of WOR timer
TI_CCxxx0_WORTIME0     			EQU	37H        ;Low byte of WOR timer
TI_CCxxx0_PKTSTATUS    			EQU	38H        ;Current GDOx status and packet status
TI_CCxxx0_VCO_VC_DAC   			EQU	39H        ;Current setting from PLL cal module
TI_CCxxx0_TXBYTES      			EQU	3AH        ;Underflow and # of bytes in TXFIFO
TI_CCxxx0_RXBYTES      			EQU	3BH        ;Overflow and # of bytes in RXFIFO
TI_CCxxx0_NUM_RXBYTES  			EQU	7FH        ;Mask "# of bytes" field in _RXBYTES
	
;Other memory locations
TI_CCxxx0_PATABLE      			EQU	3EH
TI_CCxxx0_TXFIFO       			EQU	3FH
TI_CCxxx0_RXFIFO       			EQU	3FH
	
PIN_WAVE_RX				BIT	p0.2;P2.0;p0.1;p1.0
PIN_OUTPUT_CLK				BIT	P3.4;P1.0
REG_WAKE_CLK0				EQU	08FH
CONST_DATA_VALUE1			EQU	15;20;20;20
CONST_DATA_VALUE2			EQU	208+14;14;255;208+14;14
;-----------------------------------------------------------------------------------------------
;电源控制
PIN_PWRDWN_LCD				BIT	p1.5;p1.3	 
Pin_pwrdwn				BIT 	p2.4;P2.7	 
PIN_PWR_GSM				BIT	p2.3;P2.4	 
	
;--- Active ---
Pin_unfix				BIT 	P3.5	 
PIN_card_exist				BIT	p3.3	
WKO_BK					BIT	P3.2	 
PIN_PWR_LOWIO				BIT	p1.5;P2.1	 
	
;--- ESAM ---
PIN_ESAM_TX				BIT	p0.3;P2.6	 
PIN_ESAM_RX				BIT	p0.3;P2.6	 
PIN_ESAM_RST				BIT	p0.5;P2.5	 
	
;--- 声光控制 ---
Pin_Red					BIT 	p4.5;P4.1	 
Pin_Gre 				BIT	p4.4;P4.5

PIN_BELL_01				BIT	p1.5;P0.3	 
PIN_BELL_02				BIT	p1.5;P0.2	 
	
;--- CC1101 ---
;Pin_CC1101_SS				BIT	p3.6	 
;PIN_CC1101_SCLK				BIT	P2.2	 
;PIN_CC1101_MOSI				BIT	P2.3	 
;PIN_CC1101_MISO				BIT	p3.7	 
;PIN_CC1101_GDO2				BIT	P1.6	 
	
;--- 液晶引脚 ---
Pin_LCD_CS				BIT	p1.5;p1.4	 
Pin_LCD_RST				BIT	P1.5; 	 
Pin_LCD_DC				BIT	p1.5;p1.7	
Pin_LCD_SCL				BIT	p1.5;p3.4	
Pin_LCD_SDA				BIT	p1.5;p4.3	
	
;--- 522 ---
PIN_522_SCLK				BIT	P0.7;P0.7	 
PIN_522_MOSI				BIT	p4.6;P0.5	 
PIN_522_MISO				BIT	p4.1;P0.4	 
Pin_522_SS				BIT	P0.6;P0.6	 
Pin_522_RST				BIT	p0.4;P4.6	 
	
PIN_SOFTSERIALRX			BIT	P3.0	 
PIN_SOFTSERIALTXH			BIT	P3.1	 
	
PIN_PWR_SE				BIT	p1.5	;p2.2	; P2.4	;	[ GSM ]	
Pin_SW					BIT	p1.5	
	
	
;fu dand wei
Pin_ES_Rst 				BIT	p2.6;P2.3	;p4.0;P4.4	; P4.4	
PIN_SE_IO1				BIT	p3.4;p2.4	;P4.4;p2.3;p4.4;P2.2	; P0.5
	
	
;--- CC1101 ---
PIN_UART2_TX				BIT	p1.7	;p3.6	; P3.7
PIN_UART2_RX				BIT	P1.6	; 
	
BUSY					BIT	20H.0
;////////////////////////////////////////////////引脚定义/////////////////////////////////////////////////
;设为高
PIN_BK_CE				BIT	p1.1	 
Pin_5823BK_CS				BIT     P1.0
;设成输入为高				
Pin_5823BK_MISO				BIT	p0.0	 
Pin_5823BK_IRQ				BIT	p1.2	  
;   设 成 低
Pin_5823BK_MOSI				BIT	p0.1	 
Pin_5823BK_SCLK				BIT	p4.2	 
 
PIN_WAVE_CHANNEL1			BIT	p0.2;P2.0	 
 
;=====================================================================================
Reg_WakeClk0				EQU	08fH
Reg_WakeClk_04 				BIT 	CCON.4	;P3.4
Reg_WakeClk_05 				BIT 	CCON.5	;P3.5
;声明STC12C5628AD 系列 MCU 特殊功能寄存器地址
IPH EQU 0B7H ;中断优先级高位寄存器
EPCA_LVD EQU IE.6 ;PCA 中断和 LVD(低压检测)中断共享的总中断控制位
CH EQU 0F9H ;PCA 计数器高8 位。
CL EQU 0E9H ;PCA 计数器低8 位。

;------------------------
CCON EQU 0D8H ;PCA 控制寄存器。
CCF0 EQU CCON.0 ;PCA 模块0 中断标志, 由硬件置位, 必须由软件清0。
CCF1 EQU CCON.1 ;PCA 模块1 中断标志, 由硬件置位, 必须由软件清0。
CCF2 EQU CCON.2 ;PCA 模块2 中断标志, 由硬件置位, 必须由软件清0。
CCF3 EQU CCON.3 ;PCA 模块3 中断标志, 由硬件置位, 必须由软件清0。
CCF4 EQU CCON.4 ;PCA 模块4 中断标志, 由硬件置位, 必须由软件清0。
CCF5 EQU CCON.5 ;PCA 模块5 中断标志, 由硬件置位, 必须由软件清0。
CR EQU CCON.6 ;1:允许 PCA 计数器计数, 必须由软件清0。
CF EQU CCON.7 ;PCA 计数器溢出(CH,CL 由 FFFFH 变为 0000H)标志,
;PCA 计数器溢出后由硬件置位,必须由软件清0。
;------------------------
CMOD EQU 0D9H ;PCA 工作模式寄存器。

;CMOD.7 CIDL: idle 状态时 PCA 计数器是否继续计数, 0: 继续计数, 1: 停止计数。
;CMOD.2 CPS1: PCA 计数器计数脉冲源选择位 1。
;CMOD.1 CPS0: PCA 计数器计数脉冲源选择位 0。
; CPS1 CPS0
; 0 0 外部晶体频率/12。
; 0 1 外部晶体频率/2。
; 1 0 Timer 0 溢出脉冲，
; Timer 0 还可通过 AUXR 寄存器设置成工作在 12T 或 1T 模式。
; 1 1 从 ECI/P3.4 脚输入的外部时钟。
;CMOD.0 ECF: PCA 计数器溢出中断允许位, 1-- 允许 CF(CCON.7) 产生中断。
;------------------------
CCAP0H EQU 0FAH ;PCA 模块0 的捕捉/ 比较寄存器高 8 位。
CCAP1H EQU 0FBH ;PCA 模块1 的捕捉/ 比较寄存器高 8 位。
CCAP2H EQU 0FCH ;PCA 模块2 的捕捉/ 比较寄存器高 8 位。
CCAP3H EQU 0FDH ;PCA 模块3 的捕捉/ 比较寄存器高 8 位。
CCAP4H EQU 0FEH ;PCA 模块4 的捕捉/ 比较寄存器高 8 位。
CCAP5H EQU 0FFH ;PCA 模块5 的捕捉/ 比较寄存器高 8 位。
CCAP0L EQU 0EAH ;PCA 模块0 的捕捉/ 比较寄存器低 8 位。
CCAP1L EQU 0EBH ;PCA 模块1 的捕捉/ 比较寄存器低 8 位。
CCAP2L EQU 0ECH ;PCA 模块2 的捕捉/ 比较寄存器低 8 位。
CCAP3L EQU 0EDH ;PCA 模块3 的捕捉/ 比较寄存器低 8 位。
CCAP4L EQU 0EEH ;PCA 模块4 的捕捉/ 比较寄存器低 8 位。
CCAP5L EQU 0EFH ;PCA 模块5 的捕捉/ 比较寄存器低 8 位。
;------------------------
PCA_PWM0 EQU 0F2H ;PCA 模块0 PWM 寄存器。
PCA_PWM1 EQU 0F3H ;PCA 模块1 PWM 寄存器。
PCA_PWM2 EQU 0F4H ;PCA 模块2 PWM 寄存器。
PCA_PWM3 EQU 0F5H ;PCA 模块3 PWM 寄存器。
PCA_PWM4 EQU 0F6H ;PCA 模块4 PWM 寄存器。
PCA_PWM5 EQU 0F7H ;PCA 模块5 PWM 寄存器。
;PCA_PWMn: 7 6 5 4 3 2 1 0
; - - - - - - EPCnH EPCnL
;B7-B2: 保留
;B1(EPCnH): 在 PWM 模式下，与 CCAPnH 组成 9 位数。
;B0(EPCnL): 在 PWM 模式下，与 CCAPnL 组成 9 位数。
;------------------------
CCAPM0 EQU 0DAH ;PCA 模块0 的工作模式寄存器。
CCAPM1 EQU 0DBH ;PCA 模块1 的工作模式寄存器。
CCAPM2 EQU 0DCH ;PCA 模块2 的工作模式寄存器。
CCAPM3 EQU 0DDH ;PCA 模块3 的工作模式寄存器。
CCAPM4 EQU 0DEH ;PCA 模块4 的工作模式寄存器。
CCAPM5 EQU 0DFH ;PCA 模块5 的工作模式寄存器。
;CCAPMn: 7 6 5 4 3 2 1 0
; - ECOMn CAPPn CAPNn MATn TOGn PWMn ECCFn
;
;ECOMn = 1:允许比较功能。
;CAPPn = 1:允许上升沿触发捕捉功能。
;CAPNn = 1:允许下降沿触发捕捉功能。
;MATn = 1:当匹配情况发生时, 允许 CCON 中的 CCFn 置位。
;TOGn = 1:当匹配情况发生时, CEXn 将翻转。
;PWMn = 1:将 CEXn 设置为 PWM 输出。
;ECCFn = 1:允许 CCON 中的 CCFn 触发中断。
;ECOMn CAPPn CAPNn MATn TOGn PWMn ECCFn
; 0 0 0 0 0 0 0 00H 未启用任何功能。
; x 1 0 0 0 0 x 21H 16 位CEXn 上升沿触发捕捉功能。
; x 0 1 0 0 0 x 11H 16 位CEXn 下降沿触发捕捉功能。
; x 1 1 0 0 0 x 31H 16 位CEXn 边沿(上、下沿)触发捕捉功能。
; 1 0 0 1 0 0 x 49H 16 位软件定时器。
; 1 0 0 1 1 0 x 4DH 16 位高速脉冲输出。
; 1 0 0 0 0 1 0 42H 8 位 PWM。
;------------------------------------------------------------------------------
;==============================================================================
;//////////////////////////////////////////////公共寄存器 ///////////////////////////////////////////
ISP_CONTR				EQU	0C7h
WAKE_CLKO				EQU	08fh
;附加的 SFR WAKE_CLKO (地址：0x8F)
;b7 - PCAWAKEUP :1, 允许 PCA 上升沿 / 下降沿中断 唤醒 powerdown。
;b6 - RXD_PIN_IE:1, 允许 P3.0(RXD) 下降沿置 RI，也能使 RXD 唤醒 powerdown。
;b5 - T1_PIN_IE :1, 允许 T1/P3.5 脚下降沿置 T1 中断标志，也能使 T1 脚唤醒 powerdown。
;b4 - T0_PIN_IE :1, 允许 T0/P3.4 脚下降沿置 T0 中断标志，也能使 T0 脚唤醒 powerdown。
;b3 - N/A
;b2 - N/A
;b1 - T1CLKO : 允许 T1 的溢出在P1.1 脚输出时钟，输出时钟频率 = 1/2 T1 溢出率
;	T1 工作在1T 模式时的输出频率CLKOUT1 =( Fosc / 2 ) / ( 256 - TH1 )
;	T1 工作在12T 模式时的输出频率CLKOUT1 =( Fosc / 2 ) / 12 / ( 256 - TH1 )
;b0 -	T0CLKO : 允许 T0 的溢出在P1.0 脚输出时钟，输出时钟频率 = 1/2 T0 溢出率
;	T0 工作在1T 模式时的输出频率CLKOUT0 =( Fosc / 2 ) / ( 256 - TH0)
;	T0 工作在12T 模式时的输出频率CLKOUT0 =( Fosc / 2 ) / 12 / ( 256 - TH0 )
;--------------------------------------------------------
;--------------------------------------------------------
REG_5412AD_P0M0				EQU 	094h;093h
REG_5412AD_P0M1				EQU 	093h;094h

REG_5412AD_P1M0				EQU 	092h;091h
REG_5412AD_P1M1				EQU 	091h;092h

REG_5412AD_P2M0				EQU 	096h;095h
REG_5412AD_P2M1				EQU 	095h;096h

REG_5412AD_P3M0				EQU 	0b2h;0b1h
REG_5412AD_P3M1				EQU 	0b1h;0b2h

REG_5412AD_P4M0				EQU 	0b4h;0b3h
REG_5412AD_P4M1				EQU 	0b3h;0b4h
;-------------------------------------------------------------
REG_5412AD_AUXR				EQU	08EH		;辅助寄存器
REG_5412AD_spctl			EQU	085H
REG_5412AD_spstat			EQU	084H
REG_5412AD_spdat			EQU	086H
REG_WDT_CONTR				EQU	0C1H		;0E1H;0C1H
REG_5412AD_P4SW				EQU	0BBH
REG_MCU_WKCTH				EQU	0ABH
REG_MCU_WKCTL				EQU	0AAH	
;//////////////////////////////////////////////RC522寄存器 ///////////////////////////////////////////////////
REG_RC522_RC522PAGE			EQU	00H
REG_RC522_CommandReg 			EQU	01H
REG_RC522_ComIEnReg 			EQU	02H
REG_RC522_DivIEnReg			EQU	03H
REG_RC522_ComIrqReg 			EQU	04H
REG_RC522_DivIrqReg			EQU	05H
REG_RC522_ErrorReg			EQU	06h
REG_RC522_Status1Reg			EQU	07h
REG_RC522_Status2Reg			EQU	08h
REG_RC522_FIFODataReg			EQU	09h
REG_RC522_FIFOLevelReg			EQU	0ah
REG_RC522_WaterLevelReg			EQU	0bh
REG_RC522_ControlReg 			EQU	0ch
REG_RC522_BitFramingReg			EQU	0dh
REG_RC522_CollReg			EQU	0eh
REG_RC522_RFU				EQU	0fh
REG_RC522_ModeReg			EQU	11h
REG_RC522_TxModeReg			EQU	12h
REG_RC522_RxModeReg			EQU	13h
REG_RC522_TxControlReg			EQU	14h
REG_RC522_TxAutoReg			EQU	15h
REG_RC522_TxSelReg			EQU	16h
REG_RC522_RxSelReg			EQU	17h
REG_RC522_RxThresholdReg		EQU	18h
REG_RC522_DemodReg			EQU	19h
REG_RC522_MifareReg			EQU	1ch
REG_RC522_SerialSpeedReg		EQU	1fh
REG_RC522_CRCResultRegH 		EQU	21h
REG_RC522_CRCResultRegL 		EQU	22h
REG_RC522_ModWidthReg 			EQU	24h
REG_RC522_RFCfgReg			EQU	26h
REG_RC522_GsNReg			EQU	27h
REG_RC522_CWGsPReg 			EQU	28h
REG_RC522_ModGsPReg 			EQU	29h
REG_RC522_TModeReg			EQU	2ah
REG_RC522_TPrescalerReg 		EQU	2bh
REG_RC522_TReloadRegH 			EQU	2ch
REG_RC522_TReloadRegL			EQU	2dh
REG_RC522_TCounterValueRegH		EQU	2eh
REG_RC522_TCounterValueRegL		EQU	2fh
	
;/////////////////////////////////////////////////一般系统常量表/////////////////////////////////////////////////
CONST_HOLD_5823TX			EQU	1
CONST_HOLD_5823RX			EQU	0
	
	
CONST_SYS_TradeConfine			EQU	255				;交易时间限制
CONST_SYS_PowerONTimer			EQU	10				;上电定时器	
CONST_SYS_PREFlag			EQU	088H				;
CONST_SYS_AA				EQU	0AAH
CONST_SYS_55				EQU	55H
CONST_SYS_OBUIDLEN			EQU	4				;obuid 长度
CONST_BSTLIMIT				EQU	8;20;10			;极限BST个数
CONST_BSTLIMIT02			EQU	100

CONST_VSTLIMIT				EQU	255	;100			;极限VST个数
CONST_Pro_OverTime2S			EQU	250				;超时限时，196-246*30=1200MS 
;/////////////////////////////////////////////////出入口常量表/////////////////////////////////////////////////
CONST_ETC_INPUT				EQU	3	;ETC 入口
CONST_MTC_INPUT				EQU	1	;MTC 入口
CONST_INPUT_ISEnable			EQU	1;=1不启用 =0启用
;/////////////////////////////////////////////////状态常量表/////////////////////////////////////////////////
CONST_STATE_TRUE			EQU	000H				;执行成功
CONST_STATE_FALSE			EQU	0FFH				;程序执行出错
;一般性错误	01	导入失败	STR_InputFail
;合同号不同	02	非法导入卡	STR_IllegalInputCard
;使用次数=FFH	03	导入卡失效	STR_InputCardInvalid
CONST_STATE_InputFail			EQU	01
CONST_STATE_IllegalInputCard		EQU	02
CONST_STATE_InputCardInvalid		EQU	03
;一般性错误	04	激活失败	STR_ActiveFail
;合同号不同	05	非法激活卡	STR_IllegalACTCard
;使用次数=FFH	06	激活卡失效	STR_ACTCardInvalid
CONST_STATE_ActiveFail			EQU	04
CONST_STATE_IllegalACTCard		EQU	05
CONST_STATE_ACTCardInvalid		EQU	06
	
CONST_STATE_5823INIER			EQU	07	;5823初始化出错
CONST_STATE_5823SleepEr			EQU	08	;5823休眠出错
CONST_STATE_GetSecureSelFileEr		EQU	09	;getsecure选卡目录出错

CONST_STATE_BaseNinit			EQU	10	;Baseinit02函数，初始化卡片失败
CONST_STATE_BaseESAMDF01		EQU	11	;Baseinit02函数，选ESAM卡DF01失败
	
CONST_STATE_CARDPreDeal1001		EQU	12	;预读1001失败
CONST_STATE_CARDPreDeal0002		EQU	13	;预读0002失败
CONST_STATE_CARDPreDeal0012		EQU	14	;预读0012失败
CONST_STATE_CARDPreDeal0015		EQU	15	;预读0015失败
CONST_STATE_CARDPreDeal0019		EQU	16	;预读0019失败
CONST_STATE_CARDPreDeal3f00		EQU	17	;预读3f00失败
CONST_STATE_CARDPreDeal81		EQU	18	;预读81失败
	
CONST_STATE_BaseN01init			EQU	19	;Baseinit函数，初始化卡片失败
CONST_STATE_Base01ESAMDF01		EQU	20	;Baseinit函数，选ESAM卡DF01失败
	
CONST_STATE_Base01Contact		EQU	21	;Baseinit函数，跳到接触
CONST_STATE_Base02Contact		EQU	22	;Baseinit02函数，跳到接触	
	
CONST_STATE_test			EQU	23	;Baseinit02函数，跳到接触	
	
CONST_STATE_Base02Re			EQU	24
CONST_STATE_Base02AntiColl		EQU	25
CONST_STATE_Base02Sel			EQU	26
CONST_STATE_Base02Rats			EQU	27
	
CONST_STATE_Base01Re			EQU	28
CONST_STATE_Base01AntiColl		EQU	29
CONST_STATE_Base01Sel			EQU	30
CONST_STATE_Base01Rats			EQU	31	
	
CONST_STATE_MemoryEr			EQU	32	
CONST_STATE_ExMemoryEr			EQU	33	
CONST_STATE_ExMemoryEr02		EQU	34	
	
CONST_STATE_SERIALACCPET		EQU	001H				;串口接收错误
CONST_STATE_SERIALOVERTIME		EQU	CONST_STATE_SERIALACCPET + 1	;串口接收超时
CONST_STATE_ACCEPTOVER			EQU	CONST_STATE_SERIALOVERTIME + 1	;串口接收完毕，没有后续字节 
CONST_STATE_ACCEPTOVERLEN		EQU	CONST_STATE_ACCEPTOVER + 1	;串口接收超长
CONST_STATE_RSTCPUER			EQU	CONST_STATE_ACCEPTOVERLEN + 1	;复位串口错误
CONST_STATE_AUTHER			EQU	CONST_STATE_RSTCPUER + 1	;认证失败
	
;--- 工作区常量定义 ---
CONST_WORKSTAION_0			EQU	00H	;工作区0
CONST_WORKSTAION_1			EQU	01H	;工作区1
CONST_WORKSTAION_2			EQU	02H	;工作区2	
CONST_WORKSTAION_3			EQU	03H	;工作区3

;//////////////////////////////////////卡片逻辑常量定义////////////////////////////////////////////
CONST_CARD_PASS				EQU	23
CONST_CARD_CONSUME			EQU	22
;//////////////////////////////////////GSM常量定义//////////////////////////////////////////////////
CONST_LHX_FLAG				EQU	2 ;0-国标OBU  1-GSM OBU  2-433 OBU

;RTC 大窗时间				;6分钟，平均两秒一次cellID
;CONST_RTCOverFlow			EQU	144;180;180
;CONST_RTCUartRX			EQU	24;4;8,12,16,20,24;142;

CONST_RTCOverFlow			EQU	144;20;144;6;144;6;12;144
;CONST_RTCUartRX				EQU	12
;CONST_RTCUartRX02			EQU	142
CONST_Flag_INPUT			EQU	0
CONST_Flag_OutPUT			EQU	1

;GSM CellID 记录数据所在的文件名
CONST_Cellfile_H			EQU	000H
CONST_Cellfile_L			EQU	09h;030H

CONST_ESAMCellfile_H			EQU	0EFH;000H
CONST_ESAMCellfile_L			EQU	07H;03h;030H
;CONST_Cellfile_H			EQU	000H
;CONST_Cellfile_L			EQU	008h

CONST_GSM_MaxNum			EQU	240
;CONST_GSM_MaxNum			EQU	5

CONST_GSM_PJNum				EQU	20
;CONST_GSM_PJNum			EQU	1

;RTC 小窗时间;
CONST_MCU_WKCTH				EQU	008H;0fh;00fH;00fH;00fH
CONST_MCU_WKCTL				EQU	0FFH

;RTC 是否开启，标记值
;=CONST_RTC_ON 表示开启
;= 其它 没有开启
CONST_RTC_ON				EQU	55H
CONST_RTC_off				EQU	0ffH
CONST_SYS_RTCOverTime			EQU	100

;插卡将obu中Cellid记录导入到卡片中，一次写入到卡片中 cellID 的字节数
CONST_GSM_NUM				EQU	8		;40
;//////////////////////////////////////MF常量定义//////////////////////////////////////////////////
CONST_MF_READ				EQU	00H	;指令类型 读块
CONST_MF_WRITE				EQU	01H	;指令类型 写块
CONST_MF_DECREMENT			EQU	02H	;指令类型 扣款
CONST_MF_INCREMENT			EQU	03H	;指令类型 充值
CONST_MF_RESTOR				EQU	04H	;指令类型 备份块

CONST_MF_RC500DECREMENT			EQU	0C0H	;RC500 扣款
CONST_MF_RC500INCREMENT			EQU	0C1H	;RC500 充值
;//////////////////////////////////////DSRC常量定义//////////////////////////////////////////////////
CONST_DSRC_MACCTRL			EQU	4	;MAC控制域
CONST_DSRC_LLCCTRL			EQU	5	;LLC控制域
CONST_DSRC_HEAD				EQU	6	;字段字头
CONST_DSRC_ACTION			EQU	7	;Action
CONST_DSRC_DID				EQU	8	;DSRC-DID
CONST_DSRC_ACTIONTYPE			EQU	9	;ActionType
CONST_DSRC_CONTAIN			EQU	10	;Contain
CONST_DSRC_Fill				EQU	11	;Fill
CONST_SSRC_FID				EQU	12	;文件标识（FID）

CONST_DSRC_FildIDAPPKey			EQU	0	;0――ETC 应用密钥文件
CONST_DSRC_FildIDVehicle		EQU	1	;1――ETC 应用车辆信息文件
CONST_DSRC_FildIDConsume		EQU	2	;2-ETC 应用交易记录文件
CONST_DSRC_FildIDHold			EQU	3	;3-ETC 应用保留文件

CONST_DSRC_ChannelIDICC			EQU	1
CONST_DSRC_ChannelIDSAM			EQU	2
;//////////////////////////////////////AcionType常量定义///////////////////////////////////////////////
Const_ActionType_GetSecure		EQU	0	;getSecure
Const_ActionType_SetSecure		EQU	1	;setSecure
Const_ActionType_GetRand		EQU	2	;getRand
Const_ActionType_TransferChannel	EQU	3	;transferChannel
Const_ActionType_SetMMI			EQU	4	;SetMMI
;//////////////////////////////////////Flash常量定义//////////////////////////////////////////////////
CONST_Flash_SysinfoLen			EQU	88;39;38+12	; ESAM系统信息文件长度
CONST_Flash_0002Len			EQU	4	; 0002系统信息文件长度	
CONST_Flash_0012Len			EQU	40	; 0012系统信息文件长度
;CONST_Flash_0015Len			EQU	33	; 0015系统信息文件长度
CONST_Flash_0015Len			EQU	43	; 0015系统信息文件长度
CONST_Flash_0019Len			EQU	60;43	; 0019系统信息文件长度
CONST_Flash_0019GBLen			EQU	43;43	; 0019系统信息文件长度
CONST_Flash_CardTypeLEN			EQU	1	; 上次插卡是接触，还是非接触
;CONST_Flash_SYSPARAMLEN		EQU	1	; 系统参数
CONST_Flash_BeaconIDUnixTimeLen		EQU	8	; 天线ID及unixtime
CONST_FALSH_PREFlagLen			EQU	1	; 预处理标记=88,表示上回预处理成功

;************************************************************************************
;特别备注: 由于在预读0015/0012/0019时暂存在外存的长度超过128个字节，所以，外存变量的起启位置，要在Const_Flash_FileLen
;长度之后，Const_Flash_FileLen = 8F，如果以后Const_Flash_FileLen长度改了，那外存的启始位置也要改
;外存的启始位置定义在OBUmain.inc中XDATA_VARSTART的值
;************************************************************************************
Const_Flash_FileLen			EQU	CONST_Flash_SysinfoLen + CONST_Flash_0015Len + CONST_Flash_0019Len + CONST_Flash_0012Len + CONST_Flash_0002Len + CONST_Flash_CardTypeLEN 

CONST_FLASH_Block01			EQU	72H

CONST_FLASH_STARTHIGH			EQU	CONST_FLASH_Block01;2EH						; FLASH存储区起启地址
CONST_FLASH_STARTLOW			EQU	00H						; FLASH存储区起启地址

CONST_FLASH_SYSINFOH			EQU	CONST_FLASH_Block01;2EH						; ESAM系统信息文件,LEN = 38 BYTE
CONST_FLASH_SYSINFOL			EQU	00H

CONST_FLASH_0002H			EQU	CONST_FLASH_Block01;2EH						; 用户卡0002,LEN = 4 BYTE
CONST_FLASH_0002L			EQU	CONST_FLASH_SYSINFOL + CONST_Flash_SysinfoLen

CONST_FLASH_0012H			EQU	CONST_FLASH_Block01;2EH						; 用户卡0012,LEN = 24 BYTE
CONST_FLASH_0012L			EQU	CONST_FLASH_0002L + CONST_Flash_0002Len

CONST_FLASH_0015H			EQU	CONST_FLASH_Block01;2EH						; 用户卡0015,LEN = 33 BYTE
CONST_FLASH_0015L			EQU	CONST_FLASH_0012L + CONST_Flash_0012Len

CONST_FLASH_0019H			EQU	CONST_FLASH_Block01;2EH						; 用户卡0019,LEN = 43 BYTE	
CONST_FLASH_0019L			EQU	CONST_FLASH_0015L + CONST_Flash_0015Len
	
;CONST_FLASH_01BlockH			EQU	6EH;2EH						; MF卡第1块数据
;CONST_FLASH_01BlockL			EQU	CONST_FLASH_0019L + CONST_Flash_0019Len
	
;CONST_FLASH_04BlockH			EQU	6EH;2EH
;CONST_FLASH_04BlockL			EQU	CONST_FLASH_01BlockL + 16			;MF卡第4块数据
	
;CONST_FLASH_10BlockH			EQU	6EH;2EH
;CONST_FLASH_10BlockL			EQU	CONST_FLASH_04BlockL + 16			;MF卡第16块数据
	
CONST_FLASH_LASTCARDH			EQU	CONST_FLASH_Block01;2EH						;上一次插卡类型
CONST_FLASH_LASTCARDL			EQU	CONST_FLASH_0019L + CONST_Flash_0019Len		;CONST_FLASH_10BlockL + 16
	
;CONST_FLASH_SYSPARAMH			EQU	6EH;2EH				;系统参数
;CONST_FLASH_SYSPARAML			EQU	CONST_FLASH_LASTCARDL + 1
	
CONST_Flash_BeaconIDUnixTimeH		EQU	CONST_FLASH_Block01;2EH
CONST_Flash_BeaconIDUnixTimeL		EQU	CONST_FLASH_LASTCARDL + 1	; 8 byte 天线ID和unixtime时间
	
CONST_FALSH_PREFlagH			EQU	CONST_FLASH_Block01;2EH
CONST_FALSH_PREFlagL			EQU	CONST_Flash_BeaconIDUnixTimeL + CONST_Flash_BeaconIDUnixTimeLen;1 Byte
	
CONST_FALSH_PREFlag02H			EQU	CONST_FLASH_Block01;2EH
CONST_FALSH_PREFlag02L			EQU	CONST_FALSH_PREFlagL + 1	;1	;3 Byte
	 
CONST_FALSH_PREFlag03H			EQU	CONST_FLASH_Block01;2EH
CONST_FALSH_PREFlag03L			EQU	CONST_FALSH_PREFlag02L + 1	;1	;3 Byte
	
CONST_FALSH_PowerH			EQU	CONST_FLASH_Block01;2EH
CONST_FALSH_PowerL			EQU	CONST_FALSH_PREFlag03L + 1	;1	;3 Byte
	
;CONST_FLASH_SysRstH			EQU	06CH
;CONST_FLASH_SysRstL			EQU	000H
	
CONST_FLASH_Sys0020H			EQU	6ch;064H
CONST_FLASH_Sys0020L			EQU	000H
	
CONST_FLASH_Sys0020numH			EQU	6ah;062H
CONST_FLASH_Sys0020numL			EQU	000H
	
;CONST_FLASH_SysHVH			EQU	6CH;68h;062H
;CONST_FLASH_SysHVL			EQU	000H
	
const_black_h				EQU	0ffH
const_black_l				EQU	0ffH
	
const_white_h				EQU	000H;40h				; 00h
const_white_l				EQU	031H;80h				; 00h
;/////////////////////////////////////////////////////////////////////////////////////////////////////
;(晶振*2)/(32*12*波特率)		
;CONST_SOF				EQU	22118400			; 24576000
CONST_SOF				EQU	24576000			; 当前主频晶体频率
;//////////////////////////////////////// PPS 常量 定义 ///////////////////////////////////////////////
CONST_PPS_9600				EQU	10H				
CONST_PPS_38400				EQU	13H
CONST_PPS_115200			EQU	18H
CONST_PPS_230000			EQU	96H
;//////////////////////////////////////// 串口 常量 定义 ///////////////////////////////////////////////
	
CONST_BAUD_9600				EQU	00				; 波特率编码
CONST_BAUD_38400			EQU	01
CONST_BAUD_115200			EQU	02
CONST_BAUD_115200PC			EQU	03
CONST_BAUD_230000			EQU	04
CONST_BAUD_38400PC			EQU	5
CONST_BAUD_9600PC			EQU	06				; 波特率编码
	
;在24.576M下串口第一个字节设定为要检索100MS = CONST_SOF/(10*(FF*FF) = 38 = 26H
CONST_SOFTFIRSTSCANTIME			EQU	16;8;32;16;8;10H	; 10h	;10h	;10H;0dH;10H	;  26H
CONST_SOFTFIRSTSCANTIMEXX		EQU	0FFH	; ESAM卡非常规指令，加大搜索时间限制[如80 E4指令]
CONST_SOFTSECOND			EQU	070H	; 10H	;  软接收第二个字节接收时间限长 CONST_SOFTSECOND*255个周期
CONST_HANDSECOND			EQU	15H	; 01AH[在9600波特下，要放宽到1AH];硬接收第二个字节接收时间限长 CONST_HANDSECOND*255个周期
						
CONST_SOFTBYTESP			EQU	20;50;4	;软串口发送程序字节间距控制与_FUN_LIB_DELAYSIMPLAY函数配合使用
;//////////////////////////////////////// 软串口 常量 定义 ///////////////////////////////////////////////
;CONST_BAUD_FULL9600			EQU	637	;2560
;CONST_BAUD_HALF9600			EQU	317	;2560
;CONST_BAUD_FULL9600			EQU	576	;2304
;CONST_BAUD_HALF9600			EQU	285	;1152
;CONST_BAUD_FULL9600			EQU	76	;2304
;CONST_BAUD_HALF9600			EQU	85	;1152
;CONST_BAUD_FULL38400			EQU	157	;640
;CONST_BAUD_HALF38400			EQU	77	;213
;CONST_BAUD_FULL38400			EQU	141	;576
;CONST_BAUD_HALF38400			EQU	69	;288
;CONST_BAUD_FULL115200			EQU	50	;213 每位差一到2个脉冲，如果不行，就直接换了延时函数
;CONST_BAUD_HALF115200			EQU	21	;213 每位差一到2个脉冲，如果不行，就直接换了延时函数
;CONST_BAUD_FULL115200			EQU	45 	;192 每位差一到2个脉冲，如果不行，就直接换了延时函数
;CONST_BAUD_HALF115200			EQU	21 	;96  每位差一到2个脉冲，如果不行，就直接换了延时函数
	
CONST_BAUD_FULL9600			EQU	179	;[(24576000/9600)*(3.58/6)-12]/4-200=[2560*(3.59/6)-12]/4-250=(1527-12)/4-200=378.75=379-200=179
CONST_BAUD_HALF9600			EQU	88	;[(24576000/9600/2)*(3.58/6)-12]/4-100=[2560*(3.59/6)-12]/4=(763-12)/4-100=187.75=188-100=88

CONST_BAUD_FULL38400			EQU	93	;[(24576000/38400)*(3.58/6)-12]/4= [640 * (3.59/6)-12]/4 = (382-12)/4=92.5=93
CONST_BAUD_HALF38400			EQU	45	;[(24576000/38400/2)*(3.58/6)-12]/4= [320 * (3.59/6)-12]/4 = (191-12)/4=44.75=45

CONST_BAUD_FULL115200			EQU	29	;[(24576000/115200)*(3.58/6)-12]/4=[213*(3.58/6)-12]/4=(127-12)/4=28.75=29
CONST_BAUD_HALF115200			EQU	13;	;[(24576000/115200/2)*(3.58/6)-12]/4=[115.5*(3.58/6)-12]/4=(64-12)/4=13

CONST_BAUD_FULL230000			EQU	15;13	;[(24576000/230000/2)*(3.58/6)]/4 = 64/4 = 16
CONST_BAUD_HALF230000			EQU	8;5 	;[(24576000/230000/2)*(3.58/6)]/4=[115.5*(3.58/6)]/4=32/4=8
	
CONST_BAUD_CURRENTBITFULL		EQU	CONST_BAUD_FULL9600
CONST_BAUD_CURRENTBITHALF		EQU	CONST_BAUD_HALF9600
;CONST_BAUD_BITHALF12			EQU	CONST_BAUD_CURRENTBITHALF - 3
;CONST_BAUD_BITFULL8			EQU	CONST_BAUD_CURRENTBITFULL - 2
;CONST_BAUD_BITFULL12			EQU	CONST_BAUD_CURRENTBITFULL - 3
;CONST_BAUD_BITFULL20			EQU	CONST_BAUD_CURRENTBITFULL - 5
;CONST_BAUD_BITFULL28			EQU	CONST_BAUD_CURRENTBITFULL - 7
	
CONST_BAUD_BITHALF12			EQU	3 + 9
CONST_BAUD_BITFULL8			EQU	2 + 9
CONST_BAUD_BITFULL12			EQU	3 + 9
CONST_BAUD_BITFULL20			EQU	5 + 9
CONST_BAUD_BITFULL28			EQU	7 + 9
	
;////////////////////////////////////////  硬串口 常量 定义 ///////////////////////////////////////////////
;CONST_BAUD_HAND115200			EQU	0FFH;(256 - CONST_SOF/(192*115200))	;
;CONST_BAUD_HAND38400			EQU	0FDH;(256 - (CONST_SOF/(192*38400)))	;
;CONST_BAUD_HAND9600			EQU	0F4H;(256 - CONST_SOF/(192*9600))	;

CONST_BAUD_HAND230000			EQU	252	;0FCH	24.576x1000000/(230000x6/3.58=)/16 = 4 = F8H
CONST_BAUD_HAND115200PC			EQU	243	;243	;24.576 / 0F3H	;24576000 / 32179 = 764 / 16 = 47.7 = 48 = D0H
CONST_BAUD_HAND115200			EQU	248	;0F8H	;24.576x1000000/(115200x6/3.58=193073)/16 = 8 = F8H		
CONST_BAUD_HAND38400pc			EQU	216	;0E8H	;24.576x1000000/(38400x6/3.58=64358)/16 = 24 = E8H
CONST_BAUD_HAND38400			EQU	233	;0E8H	;24.576x1000000/(38400x6/3.58=64358)/16 = 24 = E8H
CONST_BAUD_HAND9600pc			EQU	96	;0A1H	;24.576x1000000/(9600x6/3.58=16089)/16 = 95 = A1H		

CONST_BAUD_HAND9600			EQU	163	;0A1H	;24.576x1000000/(9600x6/3.58=16089)/16 = 95 = A1H		

;24.576x1000000/(38400x9.6/3.58=102972)/16=15 = f1
;24.576x1000000/(9600x9.6/3.58=25743)/16=60 = c4h
;24.576x1000000/(230000x6/3.58=385475)/16=4 = fch

;////////////////////////////////////////  指令集 ///////////////////////////////////////////////
;LL C2H LH 32H
;ML 62H MH 12H
;HL 32H HH 12H
	
CONST_ACT_L				EQU	1
CONST_ACT_M				EQU	2
CONST_ACT_H				EQU	3
	
CONST_ACT_V				EQU	CONST_ACT_M
	
CONST_ACT_L_L				EQU	0ah;0C2H
CONST_ACT_L_H				EQU	06h;032H
	
CONST_ACT_M_L				EQU	06h;062H
CONST_ACT_M_H				EQU	00h;012H
	
CONST_ACT_H_L				EQU	00h;032H
CONST_ACT_H_H				EQU	01h;012H

