ASSUME 286
ASSUME ES = 0xB800
ASSUME DI = cursor
ASSUME CS = DS = SS

clrscr(void):
	BFA000	mov DI,0x00A0
	B98007	mov CX,0x0780
	B80700	mov AX,0x0007
	F3AB	rep stosw
	BFA000	mov DI,0x00A0

puts(src, cnt):
	BExxxx	mov SI,src
	B9xxxx  mov CX,cnt
	F3A5    rep movsw

getCR0(void):
	0F20C0	mov EAX,CR0

F - white
E - yellow
D - magenta
C - red
B - aqua
A - lime
9 - blue
8 - dark grey
7 - grey
6 - brown
5 - purple
4 - brick red 
3 - turquoise
2 - green
1 - dark blue
0 - black

100:
	EB16	jmp MAIN
OS_STR(+102):
	4E0F	DS "NedOS 0.0.0"
	650F
	640F
	4F0F
	530F
	200F
	300F
	2E0F
	300F
	2E0F
	300F
; byte main(void)
MAIN(+0):
	B800B8	mov AX,0xB800
	8EC0	mov ES,AX
	BFA000	mov DI,0x00A0
; call clrscr()
	B98007	mov CX,0x0780
	B80007	mov AX,0x0700
	F3AB	rep stosw
	BFA000	mov DI,0x00A0
; call puts(OS_STR, strlen(OS_STR))
	BE0201	mov SI,0x0102
	B90B00  mov CX,0xB
	F3A5    rep movsw
; printf(CR0)
	B82007	mov AX,0x0720
	AB	stosw
	0F20C0	mov EAX,CR0
	8BD8	mov BX,AX
	66C1E810 shr EAX,16
	8BD0	mov DX,AX
	B403	mov AH,0x03
	E81400	call printNibble
 	8AF2	mov DH,DL
+2	E80F00	call printNibble
+5	8AF7	mov DH,BH
+2	E80A00	call printNibble
+5	8AF3	mov DH,BL
+2	E80500	call printNibble
; return(0)
+5	B8004C	mov AX,0x4C00
+3	CD21	int 0x21
+2

; void printNibble(DH) // destroys AX,DI
PRINTNIBBLE:
	8AC6	mov AL,DH
	C0E804	shr AL,0x04
	240F	and AL,0x0F
	0430	add AL,0x30
	AB	stosw
	8AC6	mov AL,DH
	240F	and AL,0x0F
	0430	add AL,0x30
	AB	stosw
	C3	ret


