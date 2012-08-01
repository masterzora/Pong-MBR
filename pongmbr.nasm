BITS 16
org 7c00h

jmp short start

ballx:
  dw 320		; start at half point

bally:
  dw 240		; start at half point

ballxvel:
  dw 1			; start moving toward right

ballyvel:
  dw -1			; start moving up

bat1y:
  dw 240		; start at half point

bat2y:
  dw 240		; start at half point

bat1dir:		; bat1 direction choices: -1, 0, 1. up, none, down, respectively
  db 0x0		; initialise to immobile

bat2dir:		; bat2 direction choices: -1, 0, 1. up, none, down respectively
  db 0x0		; initialise to immobile

score1:
  db 0x0		; start at no score

score2:
  db 0x0		; start at no score

throttle:
  dw 0x2222		; throttle the game to manageable speeds
			; adjust as necessary for a given cpu

start:
  mov ax,0x12
  int 0x10
    
  mov ax,0xa000
  mov es,ax		; ES points to video memory
  mov dx,0x3c4		; dx = index register
  mov ax,0xF02		; INDEX = MASK MAP
  out dx,ax		; write all the bitplanes

			; draw a line across the screen to section off scores
  mov al, 0xff
  mov di,(80 * 455)
  mov cx, 80
  .lineloop:
    stosb
    loop .lineloop, cx

  .gameloop:		; main game loop
    dec word [throttle]
    cmp word [throttle],0
    jne .gameloop
    mov [throttle],word 0x2222	; reset throttle counter
    
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
    mov di,4		; left bat is 4 columns from the side
    mov ax,[bat1y]
    call drawbat
    mov di,76		; right bat is 4 columns from the side
    mov ax,[bat2y]
    call drawbat

    .moveball:
      call cleanball	; clear out where the ball currently is
      mov ax,[ballxvel]
      add [ballx],ax	; move ball horizontal
      mov ax,[ballyvel]
      add [bally],ax	; move ball vertical
      mov bl, 0xff
      call drawball	; redraw ball in new position

    .checkycollision:
      cmp [bally], word 0		; ball position counts from top left of ball
      jle .y_collide
      cmp [bally], word 447		; ball is 8 high
      jl .checkxcollision
      .y_collide:
        neg word [ballyvel]		; bounce y

    .checkxcollision:
      cmp [ballx], word 39		; ball position counts from top left of ball
      jg .check_right_x
      mov ax,[bat1y]
      mov bx,score1
      jmp short .checkbaty

      .check_right_x:
        cmp [ballx], word 599		; ball position counts from top left of ball
        jl .printscores
        mov ax,[bat2y]
        mov bx,score2

      .checkbaty:
        mov cx,[bally]
        add cx,24
        sub cx,ax
        cmp cx,40
        jna .bounce
        inc byte [bx]
        call cleanball
        mov [ballx], word 320
        mov [bally], word 240
        jmp short .printscores

      .bounce:
        neg word [ballxvel]		; reverse

    .printscores:
      mov dl, 30
      mov al, [score1]
      call printscore
      mov dl, 0
      mov al, [score2]
      call printscore

    .checkscore1:
      cmp [score1], byte 9
      jl .checkscore2
      jmp short end

    .checkscore2:
      cmp [score2], byte 9
      jl .gameloop
      jmp short end

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
  mov cx,8		; ball is 8 tall
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
  sub ax,18		; stored positions are midpoints, advance back two further to clear above
  mov cx,80
  mul cx
  add di,ax
  mov cx, 33
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
      cmp [bx],word 19		; bat is counted from the middle
      jle .batup_end
      sub [bx],word 2
      .batup_end:
        ret
  .batdown:
    cmp al, byte 0x01
    jne .donemove
    .movebatdown:
      cmp [bx],word 436		; bat is counted from the middle
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
