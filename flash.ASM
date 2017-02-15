NAME	Flash
	
PUBLIC	_rdflash,_rdflashxr
PUBLIC	_wrflash,_wrflashxr
PUBLIC	_eraseflash
	
ISP_DATA		EQU	0C2H	;0e2h
ISP_ADDRH		EQU	0C3H	;0e3h
ISP_ADDRL		EQU	0C4H	;0e4h
ISP_CMD			EQU	0C5H	;0e5h
ISP_TRIG		EQU	0C6H	;0e6h
ISP_CONTR		EQU	0C7H	;0e7h
	
Reg_value_ISPTrig01	EQU	05AH
Reg_value_ISPTrig02	EQU	0A5H
	
Reg_Value_LowAddr	EQU	72H;6eh;61H
Reg_Value_HighAddr	EQU	74H;70H	
	
ISP_byte_read		EQU	01h
ISP_byte_write		EQU	02h
ISP_sector_erase	EQU	03h
wait_time			EQU	00h
enable_isp			EQU	89H	;81h 80h 1000 0001
;flash_data_start_addr	EQU	02000h
extrn code(ap_start)

	
	flash	 	SEGMENT CODE
	RSEG		flash
	
;-------------------------------------------------
;描述:读Flash到内存
;外部参数:
;	dptr	---	falsh地址
;	r7	---	内存地址
;	r3	---	将要读取的长度
;-------------------------------------------------
_rdflash:
	MOV	A,R3
	JZ	_rdflash_OVER
	clr	ea
	mov	a,r7
	mov	r0,a
	mov	isp_contr,#enable_isp			;82h;enable_isp   &   1000 1001
	mov	isp_cmd,#ISP_byte_read
rdflash_1:
	call	byte_read
	mov	@r0,a
	inc	r0
	inc	dptr
	djnz	r3,rdflash_1
	call	iap_disable
_rdflash_OVER:
	ret
;-------------------------------------------------
;描述:读 Flash 到外存
;外部参数:
;	dptr	---	falsh 地址    
;	r7	---	外存地址
;	r3	---	将要读取的长度
;-------------------------------------------------
_rdflashxr:
	
	MOV	A,R3
	JZ	_rdflashxr_OVER
	clr 	ea
	mov 	a,r7
	mov 	r0,a
	mov 	isp_contr,#enable_isp
	mov 	isp_cmd,#ISP_byte_read
rdflashxr_1:	
	call 	byte_read
	;movx 	@r0,a
	push	dph
	push	dpl
	MOV 	DPH,#1 
	MOV 	DPL,R0 
	MOVX 	@DPTR,A	
	pop	dpl
	pop	dph
	inc 	r0
	

	inc 	dptr
	djnz 	r3,rdflashxr_1
	call 	iap_disable
_rdflashxr_OVER:
	
	ret
;-------------------------------------------------
;描述:写Flash到内存
;外部参数:
;	dptr	---	falsh地址    
;	r7	---	内存地址   
;	r3	---	将要写的长度
;-------------------------------------------------
_wrflash:
	
	mov	a,dph
	cjne	a,#Reg_Value_LowAddr,$+3		;cjne	a,#2EH,$+3
	jnc	_wrflashStart
_wrflashStart_err:
	;---orl	pcon,#02h
	jmp	ap_start
_wrflashStart:	
	cjne	a,#Reg_Value_HighAddr,$+3		;cjne	a,#30h,$+3
	jnc	_wrflashStart_err
	MOV	A,R3
	JZ	_wrflash_OVER
	clr 	ea
	mov 	a,r7
	mov 	r0,a
	mov 	isp_contr,#enable_isp
	mov 	isp_cmd,#ISP_byte_write
wrflash_1:
	mov 	a,@r0
	inc 	r0
	call 	byte_write
	inc 	dptr
	djnz 	r3,Wrflash_1
	call 	iap_disable
_wrflash_OVER:
	
	ret
;-------------------------------------------------
;描述:写Flash到外存
;外部参数:
;	dptr	---	falsh地址    
;	r7	---	外存地址   
;	r3	---	将要写的长度
;-------------------------------------------------
_wrflashxr:
	
	mov	a,dph
	cjne	a,#Reg_Value_LowAddr,$+3		;cjne	a,#2EH,$+3
	jnc	_wrflashxrStart
_wrflashxrStart_err:
	;orl	pcon,#02h
	jmp	ap_start
_wrflashxrStart:	
	cjne	a,#Reg_Value_HighAddr,$+3		;cjne	a,#30h,$+3
	jnc	_wrflashxrStart_err
	MOV	A,R3
	JZ	_wrflashxr_OVER
	clr 	ea
	mov 	a,r7
	mov 	r0,a
	mov 	isp_contr,#enable_isp
	mov 	isp_cmd,#ISP_byte_write
wrflashxr_1:
	;movx 	A,@r0
	push	dpl
	push	dph
	MOV	DPH,#1
	MOV	DPL,R0
	MOVX	A,@DPTR	
	pop	dph
	pop	dpl
	
	inc 	R0
	call 	byte_write
	inc 	dptr
	djnz 	r3,Wrflashxr_1
	call 	iap_disable
_wrflashxr_OVER:
	
	ret

;-------------------------------------------------
;描述:擦除Flash
;外部参数:
;	dptr	---	falsh地址    
;	r3	---	将要擦除的长度
;-------------------------------------------------
_eraseflash:
	MOV	A,R3
	JZ	_eraseflashStart2
	cjne	A,#3,$+3
	jc	_eraseflashStart1
_eraseflashStart2:	
	;---orl	pcon,#02h
	jmp	ap_start
_eraseflashStart1:	
	clr	ea
	mov	isp_contr,#enable_isp
	mov	isp_cmd,#ISP_sector_erase
	mov	a,dph
eraseflash_1:
	cjne	a,#Reg_Value_LowAddr,$+3		;cjne	a,#2EH,$+3
	jnc	_eraseflashStart
_eraseflashStart_err:
	;---orl	pcon,#02h
	jmp	ap_start
_eraseflashStart:	
	cjne	a,#Reg_Value_HighAddr,$+3		;cjne	a,#30h,$+3
	jnc	_eraseflashStart_err

	call	sector_erase
	mov	a,dph
	inc	a
	inc	a
	mov	dph,a
	djnz	r3,eraseflash_1
	call	iap_disable
_eraseflash_OVER:
	ret
;-------------------------------------------------
;读字节
;-------------------------------------------------
byte_read:
	mov isp_addrh,dph
	mov isp_addrl,dpl
	mov isp_trig,#Reg_value_ISPTrig01
	mov isp_trig,#Reg_value_ISPTrig02
	mov a,isp_data
	ret
;-------------------------------------------------
;写字节
;-------------------------------------------------
byte_write:
	mov isp_addrh,dph
	mov isp_addrl,dpl
	mov isp_data,a
	mov isp_trig,#Reg_value_ISPTrig01
	mov isp_trig,#Reg_value_ISPTrig02
	ret
	
sector_erase:
	mov isp_addrh,dph
	mov isp_addrl,dpl
	mov isp_trig,#Reg_value_ISPTrig01
	mov isp_trig,#Reg_value_ISPTrig02
	ret
	
iap_disable:
	mov isp_contr,#0
	mov isp_cmd,#0
	mov isp_trig,#0
	mov isp_addrh,#0
	mov isp_addrl,#0
	ret
		
	END
