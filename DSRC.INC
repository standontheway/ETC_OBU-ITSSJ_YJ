;---段定义---
?pr?DSRC?Mater		SEGMENT CODE
?co?DSRC?COMMLIB	SEGMENT	CODE
;////////////////////////////////////////////////////////////////////////////////////////
;--- 输出 ---
PUBLIC	_FUN_DSRC_VST
;PUBLIC	_FUN_DSRC_GetSecure
;PUBLIC	_FUN_DSRC_SetSecure
;PUBLIC	_FUN_DSRC_GetRand
;PUBLIC	_FUN_DSRC_TransferChannel
;PUBLIC	_FUN_DSRC_SetMMI
PUBLIC	_FUN_DSRC_NSpecial
;////////////////////////////////////////////////////////////////////////////////////////
;--- 输入 ---
EXTRN	BIT(BIT_Cellinfo)
EXTRN	BIT(BIT_INSERTCARD)
EXTRN	BIT(BIT_CHANNELFLAG)
EXTRN	BIT(BIT_ESAMICC)
EXTRN	BIT(BIT_T0T1)
EXTRN	BIT(BIT_ACCESS)
EXTRN	BIT(BIT_KEY)
EXTRN	BIT(BIT_N)
EXTRN	BIT(BIT_SETMMI)
EXTRN	BIT(BIT_GETRESULT)
EXTRN	BIT(BIT_ISContact)
EXTRN	BIT(BIT_PROMF)
EXTRN	BIT(BIT_BUFADDR)
EXTRN	BIT(BIT_SERIALOVERTIMERX)
EXTRN	BIT(BIT_VERIFY)
EXTRN	BIT(BIT_privateInfo)
EXTRN	BIT(BIT_gbICCInfo)
EXTRN	BIT(BIT_CD)
EXTRN	BIT(BIT_BJ1219)
EXTRN	BIT(BIT_ESAMErr)
EXTRN	BIT(BIT_ESAMOK)
;extrn	bit(BIT_8054_flag)

EXTRN	XDATA(XDATA_HOLD)
EXTRN	XDATA(XDATA_TXBUF)
EXTRN	XDATA(XDATA_BeaconID)
EXTRN	XDATA(XDATA_UnixTime)
EXTRN	XDATA(XDATA_SOFTFIRSTSCANTIME)
EXTRN	XDATA(XDATA_FIX)
EXTRN	XDATA(XDATA_Power)
EXTRN	XDATA(XDATA_CELLID)
;EXTRN	XDATA(XDATA_SysParam)

EXTRN	DATA(DATA_RXBUF)
EXTRN	DATA(DATA_DSRCTXLEN)
EXTRN	DATA(DATA_DSRCRXLEN)
EXTRN	DATA(DATA_CardNO)
;EXTRN	DATA(DATA_VARTMP1)

extrn	code(_eraseflash)
extrn	code(_wrflashxr)
EXTRN	CODE(STR_SYS_OBUID)
EXTRN	CODE(_FUN_LIB_FLASHTOXDATA)
EXTRN	CODE(_rdflashxr)
EXTRN	CODE(_FUN_Contact_Channel)
EXTRN	CODE(_FUN_CARDAPP_CardChannel)
EXTRN	CODE(_FUN_LIB_FLASHTODATAEX)
EXTRN	CODE(_FUN_SERIAL_RXSOFT)
EXTRN	CODE(_FUN_CARDAPP_SelectFile)
EXTRN	CODE(_FUN_HDLC_CHANGECHANNEL)
;--- Library ---
EXTRN	CODE(_FUN_LIB_FLASHTODATA)
EXTRN	CODE(_getnewcrc_xr)
EXTRN	CODE(_getnewcrc)

EXTRN	CODE(_FUN_LIB_ESAMErr)


;--- TEST ---
;EXTRN	CODE(STR_READVEHICLE)
;EXTRN	CODE(_FUN_TESTContact_OPRET0)
EXTRN	CODE(_FUN_CARDAPP_UpdateBinary)
EXTRN	CODE(_FUN_GSM_RTCDis)
EXTRN	CODE(_FUN_CARDAPP_ReadRecord)
EXTRN	CODE(_FUN_LIB_XDATATOXDATA)
;EXTRN	CODE(_wrflashxr)
EXTRN	CODE(_FUN_LIB_XDATATODATA)
;EXTRN	CODE(_FUN_CARDAPP_UpdateBinary)
EXTRN	CODE(_FUN_GSM_RTCEn)
EXTRN	CODE(_FUN_TEST_BEEP)
EXTRN	CODE(_FUN_TEST_DISPLAY)
EXTRN	CODE(_FUN_TEST_UARTDISPLAY)
extrn	xdata(XDATA_54)
;////////////////////////////////////////////////////////////////////////////////////////
	RSEG	?co?DSRC?COMMLIB
STR_DSRC_GETRND:
	DB	05H
	DB	00,84H,00,00,04H
;////////////////////////////////////////////////////////////////////////////////////////
STR_DSRC_VST:		;VST基本组成
	DB	00AH			;长度
	;DB	0FFH,0FFH,0FFH,0FFH	;MAC地址
	DB	0C0H			;MAC控制域
	DB	003H			;LLC控制域
	DB	091H			;字段字头
	DB	0D0H
	DB	000H
	DB	001H
	DB	0C1H
	DB	001H
	DB	0FFH
	DB	027H
STR_DSRC_VST02:		;VST基本组成
	DB	00AH			;长度
	;DB	0FFH,0FFH,0FFH,0FFH	;MAC地址
	DB	0C0H			;MAC控制域
	DB	003H			;LLC控制域
	DB	091H			;字段字头
	DB	0D0H
	DB	000H
	DB	001H
	DB	0C1H
	DB	002H
	DB	0FFH
	DB	027H
	; xx||26 Byte Sysinfo
	; 28h
	; 61 Byte IC Data
	; 4 Byte OBUID
	; 1 Byte equipmentClass & Version
	; 1 Byte ObuStatus
	; 1 Byte ESAM第27字节 "拆卸状态"
;////////////////////////////////////////////////////////////////////////////////////////
;STR_DSRC_GetSecure:	;GetSecure基本组成	
;	DB	000H		;长度
;	DB	0E0H		;MAC控制域
;	DB	0F7H		;LLC控制域(抄)
;	DB	000H		;LLC状态域
;	DB	091H		;字段字头
;	DB	018H		;ACTION.response
;	DB	001H		;Dsrc-Did，ETC应用对应1(抄)
;	DB	015H		;GetSecure.response
;	DB	001H		;文件标识（FID）(抄)
;////////////////////////////////////////////////////////////////////////////////////////
