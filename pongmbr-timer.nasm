BITS 16
org 7c00h

; configurable constants
; This timer can be adjusted to increase or decrease game speed.
; Larger numbers (up to 65535) slow the game down, smaller numbers (down to 1)
; speed it up.  Game speed is theoretically platform independent.
%define TIMER 5500
%define SCREEN_TOP 0
%define BALL_HEIGHT 8
%define BAT_HEIGHT 32
; The code cannot handle a score past 9 so make sure GAME_POINT is between 1 and 9 inclusive
%define GAME_POINT 9
%define SCORE_1_POS 30
%define SCORE_2_POS 0

; semi-configurable constants
; these constants can be safely changed but may not have
; the changes one would expect
; SCREEN_LEFT and SCREEN_RIGHT are only useful for the ball start point
%define SCREEN_LEFT 0
%define SCREEN_RIGHT 640
; LINE_Y can be moved anywhere on the field and will still be the bottom
; of the field but changing this value may lead to poor aesthetics.
; If you must change the field height it is suggested you alter SCREEN_TOP
; instead.
%define LINE_Y 455

; non-configurable constants
; one way or another these each rely on something hardcoded
%define LEFT_BAT_COLUMN 4
%define RIGHT_BAT_COLUMN 76
%define LEFT_BAT_SURFACE 40
%define RIGHT_BAT_SURFACE 607
%define BALL_WIDTH 8

jmp short start

ballx:
  dw (SCREEN_RIGHT - SCREEN_LEFT) / 2 + SCREEN_LEFT		; start at half point

bally:
  dw (LINE_Y - SCREEN_TOP) / 2 + SCREEN_TOP		; start at half point

ballxvel:
  dw -1			; start moving toward left

ballyvel:
  dw 0			; start at no y velocity

bat1y:
  dw (LINE_Y - SCREEN_TOP) / 2 + SCREEN_TOP		; start at half point

bat2y:
  dw (LINE_Y - SCREEN_TOP) / 2 + SCREEN_TOP		; start at half point

bat1dir:		; bat1 direction choices: -1, 0, 1. up, none, down, respectively
  db 0x0		; initialise to immobile

bat2dir:		; bat2 direction choices: -1, 0, 1. up, none, down respectively
  db 0x0		; initialise to immobile

score1:
  db 0x0		; start at no score

score2:
  db 0x0		; start at no score

loopready:
  db 0x1

timer_isr:
  mov [loopready], byte 0x0
  iret

start:
  mov ax,0x12
  int 0x10

  ; set the timer
  mov al, 0x36
  out 0x43, al
  mov ax, TIMER
  out 0x40, al
  mov al, ah
  out 0x40, al

  ; hook our custom sub to the timer interrupt
  mov ax, 0
  mov es, ax
  pushf
  cli
  mov word [es:0x1c*4], timer_isr
  mov word [es:0x1c*4 + 2], cs
  popf
  
  mov ax,0xa000
  mov es,ax		; ES points to video memory
  mov dx,0x3c4		; dx = index register
  mov ax,0xF02		; INDEX = MASK MAP
  out dx,ax		; write all the bitplanes

			; draw a line across the screen to section off scores

  mov al, 0xff
  mov di,(80 * LINE_Y)
  mov cx, 80
  .lineloop:
    stosb
    loop .lineloop, cx

  .gameloop:		; main game loop
    cmp byte [loopready],0
    jne .gameloop
    
    in al, 0x60		; check for keyboard input and set bat directions accordingly
    mov bl, 0x11
    mov dl, 0x1f
    mov si, bat1dir
    push ax
    call testinput
    mov bl, 0x18
    mov dl, 0x26
    mov si, bat2dir
    pop ax
    call testinput
			; move and redraw bats
    mov al,[bat1dir]
    mov bx,bat1y
    call movebat
    mov al,[bat2dir]
    mov bx,bat2y
    call movebat
    mov di,LEFT_BAT_COLUMN
    mov ax,[bat1y]
    call drawbat
    mov di,RIGHT_BAT_COLUMN
    mov ax,[bat2y]
    call drawbat

    .moveball:
      call cleanball	; clear out where the ball currently is
      mov ax,[ballxvel]
      add [ballx],ax	; move ball horizontal
      mov ax,[ballyvel]
      add [bally],ax	; move ball vertical

    .checkycollision:
      .ballattop:
        cmp [bally], word SCREEN_TOP		; ball position counts from top left of ball
        jg .ballatbottom
        mov dx, SCREEN_TOP
        jmp short .y_collide
      .ballatbottom:
        cmp [bally], word LINE_Y - BALL_HEIGHT	; ball position counts from top left of ball
        jl .checkxcollision
        mov dx, LINE_Y - BALL_HEIGHT
      .y_collide:
        mov [bally], dx
        neg word [ballyvel]		; bounce y

    .checkxcollision:
      cmp [ballx], word LEFT_BAT_SURFACE	; ball position counts from top left of ball
      jg .check_right_x
      mov ax,[bat1y]
      mov bx,score2
      jmp short .checkbaty

      .check_right_x:
        cmp [ballx], word RIGHT_BAT_SURFACE - BALL_WIDTH		; ball position counts from top left of ball
        jl .redraw
        mov ax,[bat2y]
        mov bx,score1

      .checkbaty:
        mov cx,[bally]
        add cx,BAT_HEIGHT / 2 + BALL_HEIGHT	; if any part of the ball touches the bat it bounces
        sub cx,ax
        cmp cx,BAT_HEIGHT + BALL_HEIGHT
        jna .bounce
						; somebody scored! increment score and reset ball
        inc byte [bx]
        call cleanball
        mov [ballx], word (SCREEN_RIGHT - SCREEN_LEFT) / 2
        mov [bally], word (LINE_Y - SCREEN_TOP) / 2
        mov [ballyvel], word 0			; reset the y velocity. Don't touch the x so it will go
						; away from the player who just scored
        jmp short .redraw

      .bounce:
        mov ax,cx			; ax will be between 0 and 40
        sub ax,(BAT_HEIGHT + BALL_HEIGHT) / 2			; ax will be between -20 and 20
        mov cl,(BAT_HEIGHT + BALL_HEIGHT) / 8		; we want 8 segments on the bat
        idiv cl
        cbw
        mov [ballyvel],ax
        neg word [ballxvel]		; reverse

    .redraw:
      mov bl, 0xff
      call drawball	; redraw ball in new position

    .printscores:
      mov dl, SCORE_1_POS
      mov al, [score1]
      call printscore
      mov dl, SCORE_2_POS
      mov al, [score2]
      call printscore

    .checkscore1:
      cmp [score1], byte GAME_POINT
      jl .checkscore2
      jmp short end

    .checkscore2:
      cmp [score2], byte GAME_POINT
      jl .gamelooptail
      jmp short end

    .gamelooptail:
      mov [loopready], byte 0x1
      
      jmp .gameloop

end:
  jmp short end

drawball:
  xor dx,dx		; div needs dx zeroed out
  mov ax,[ballx]
  mov cx,8
  div cx		; convert bit count to byte count
  push dx
  mov di,ax
  mov ax,[bally]
  mov cx,80
  mul cx		; there are 80 columns per row
  add di,ax
  pop cx
  mov al,0x80		; initialise al to 0b10000000
  sar al,cl		; and shift to set a 1 for every pixel in this byte
  mov cx,BALL_HEIGHT		; ball is 8 tall
  .balltop:
    not al		; the left column needs lower bits
    and al,bl
    stosb
    not al		; the right column needs upper bits
    and al, bl
    stosb
    add di,78
    loop .balltop,cx
  ret

cleanball:
  mov bl, 0x00
  call drawball
  ret

drawbat:
  sub ax,BAT_HEIGHT / 2 + 2		; stored positions are midpoints, advance back two further to clear above
  mov cx,80
  mul cx
  add di,ax
  mov cx, BAT_HEIGHT
  mov ax, 0x00
  stosb
  add di,79
  stosb
  add di,79
  mov al, 0xff	; bats are byte-aligned and one byte wide so just set all pixels in the byte
  .battop:
    stosb
    add di,79
    loop .battop, cx
  mov ax, 0x00		; clear the pixel below the bat as well
  stosb
  add di,79
  stosb
  ret

movebat:
  .batup:
    cmp al, byte 0xff
    jne .batdown
    .movebatup:
      cmp [bx],word (BAT_HEIGHT / 2) + 3 + SCREEN_TOP		; bat is counted from the middle
      jle .batup_end
      sub [bx],word 2
      .batup_end:
        ret
  .batdown:
    cmp al, byte 0x01
    jne .donemove
    .movebatdown:
      cmp [bx],word LINE_Y - (BAT_HEIGHT / 2 + 3)		; bat is counted from the middle
      jge .batdown_end
      add [bx],word 2
      .batdown_end:
  .donemove:
    ret

printscore:
  mov dh, 80
  mov bx, 0x10f
  mov ah, 0x2
  int 0x10
  mov cx, 0x1
  add ax, 0x0830
  int 0x10
  ret

testinput:
  mov cl, 0xff
  .checkloop:
    .check_up:
      cmp al, bl
      jne .check_down
      mov [si], cl
    .check_down:
      neg cl			; -1 -> 1; 0 -> 0
      cmp al, dl
      jne .donecheck
      mov [si], cl
    .donecheck:
      and cl, 0x0		; keyups set dir to 0
      xor al, 0x80		; key up = key down + 0x80
      test al, 0x80		; if the 0x80 bit was already unset there's no point in looping
      jz .checkloop

    ret

times 510-($-$$) DB 0
DW 0xAA55
