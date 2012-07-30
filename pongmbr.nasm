BITS 16
org 7c00h

jmp short start

ballx:
  dw 320		; start at half point

bally:
  dw 240		; start at half point

ballxvel:
  dw -1		; start not moving

ballyvel:
  dw 1		; start not moving

bat1y:
  dw 0xf0		; start at half point

bat2y:
  dw 0xf0		; start at half point

score1:
  db 0x0		; start at no score

score2:
  db 0x0		; start at no score

throttle:
  dw 0x2222		; throttle the game to manageable speeds

start:
  mov ax,0x12
  int 0x10
  mov ax,0xa000
  mov es,ax		; ES points to video memory
  mov dx,0x3c4		; dx = index register
  mov ax,0xF02		; INDEX = MASK MAP
  out dx,ax		; write all the bitplanes
  gameloop:
    dec word [throttle]
    cmp word [throttle],0
    jne gameloop
    mov [throttle],word 0x2222
    mov di,4		; left bat is 4 columns from the side
    mov ax,[bat1y]
    call drawbat
    mov di,76		; right bat is 4 columns from the side
    mov ax,[bat2y]
    call drawbat
    call moveball
    call checkxcollision
    call checkycollision
    jmp gameloop
  jmp end

drawball:
  xor dx,dx		; div needs dx zeroed out
  mov ax,[ballx]
  mov cx,8
  div cx		; convert bit count to byte count
  mov bx,dx
  mov di,ax
  mov ax,[bally]
  mov cx,80
  mul cx		; there are 80 columns per row
  add di,ax
  mov cx,bx
  mov al,0x80		; initialise al to 0b10000000
  sar al,cl		; and shift to set a 1 for every pixel in this byte
  mov cx,8		; ball is 8 tall
  .balltop:
    not al		; the left column needs lower bits
    stosb
    not al		; the right column needs upper bits
    stosb
    add di,78
    loop .balltop,cx
  ret

cleanball:
  xor dx,dx
  mov ax,[ballx]
  mov cx,8
  div cx
  mov bx,dx
  mov di,ax
  mov ax,[bally]
  mov cx,80
  mul cx
  add di,ax
  mov ax,0x0		; unset all pixels
  mov cx,8
  .cleanballtop:
    stosb
    stosb
    add di,78
    loop .cleanballtop,cx
  ret

drawbat:
  sub ax,17		; stored positions are midpoints, advance back one further to clear above
  mov cx,80
  mul cx
  add di,ax
  mov cx, 32
  mov ax, 0x00
  stosb
  add di,79
  .battop:
    mov ax, 0xff	; bats are byte-aligned and one byte wide so just set all pixels in the byte
    stosb
    add di, 79
    loop .battop, cx
  mov ax, 0x00		; clear the pixel below the bat as well
  stosb
  add di,79
  ret

checkycollision:
  cmp [bally], word 0		; ball position counts from top left of ball
  jle y_collide
  cmp [bally], word 472		; ball is 8 high
  jl end_y_collide
  y_collide:
    neg word [ballyvel]		; reverse
  end_y_collide:
    ret

checkxcollision:
  cmp [ballx], word 0		; ball position counts from top left of ball
  jle x_collide
  cmp [ballx], word 632		; ball is 8 wide
  jl end_x_collide
  x_collide:
    neg word [ballxvel]		; reverse
  end_x_collide:
    ret
  

moveball:
  call cleanball	; clear out where the ball currently is
  mov ax,[ballxvel]
  add [ballx],ax
  mov ax,[ballyvel]
  add [bally],ax
  call drawball		; redraw ball in new position
  ret
  


end:
  jmp short end

times 510-($-$$) DB 0
DW 0xAA55
