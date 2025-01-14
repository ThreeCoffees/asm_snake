.386
rozkazy SEGMENT use16
    ASSUME cs:rozkazy

print_pixel PROC
    ; prints pixel starting in bx with color in al
    push cx
    push dx
    push bx

    mov dx, 8
outer:
    mov cx, 8
inner:
    add bx, 1
    mov es:[bx], al
    loop inner

    add bx, 320
    sub bx, 8
    sub dx, 1
    ja outer

    pop bx
    pop dx
    pop cx
    ret
print_pixel ENDP

update_clock PROC
    push ax
    push bx
    push es
    push si

    mov ax, 0A000h
    mov es, ax

    cmp cs:game_over, 0
    jne zakoncz_update

; update positions
    sub byte PTR cs:food_move_chance, 1
    jnz no_move_food
    mov byte PTR cs:food_move_chance, 10
    ; erase prev food
    mov ax, cs:food_y
    mov bx, 320
    mul bx
    add ax, cs:food_x
    mov bx, 8
    mul bx
    mov bx, ax

    mov al, 0h
    call print_pixel
    
    ; move food
    mov ax, cs:food_dir_x
    add ax, cs:food_x 
    ; loop around x
    cmp ax, 0
    jge check_x_food
    add ax, 40
check_x_food:
    cmp ax, 40
    jl  x_loopcheck_food
    sub ax, 40
x_loopcheck_food:
    mov cs:food_x, ax
    
    ; y
    mov ax, cs:food_dir_y
    add ax, cs:food_y 
    ; loop around y
    cmp ax, 0
    jge check_y_food
    add ax, 25
check_y_food:
    cmp ax, 25
    jl  y_loopcheck_food
    sub ax, 25
y_loopcheck_food:
    mov cs:food_y, ax
no_move_food:
; wonsz
    ; shift all positions
    mov si, cs:len
    add si, si

    ; erase tail
    mov ax, cs:y[si]
    mov bx, 320
    mul bx
    add ax, cs:x[si]
    mov bx, 8
    mul bx
    mov bx, ax

    mov al, 0
    call print_pixel

    ; shift positions cont.

pos_loop:
    mov ax, cs:x[si-2]
    mov cs:x[si], ax
    mov ax, cs:y[si-2]
    mov cs:y[si], ax

    sub si, 2
    cmp si, 2
    jae pos_loop

    ; update head position
    ; x
    mov ax, cs:dir_x
    add ax, cs:x 
    ; loop around x
    cmp ax, 0
    jge check_x_overflow
    add ax, 40
check_x_overflow:
    cmp ax, 40
    jl  x_loopcheck_complete
    sub ax, 40
x_loopcheck_complete:
    mov cs:x, ax
    
    ; y
    mov ax, cs:dir_y
    add ax, cs:y 
    ; loop around y
    cmp ax, 0
    jge check_y_overflow
    add ax, 25
check_y_overflow:
    cmp ax, 25
    jl  y_loopcheck_complete
    sub ax, 25
y_loopcheck_complete:
    mov cs:y, ax

    ; check if collided with food
    mov ax, cs:food_x
    cmp cs:x, ax
    jne not_colliding
    mov ax, cs:food_y
    cmp cs:y, ax
    jne not_colliding
    ; collided -> finish program
    mov cs:game_over, 1
    jmp zakoncz_update   

not_colliding:


; draw
    mov si, 0
snake_draw_loop:
    ; get address of the pixel to draw in bx
    mov ax, cs:y[si]
    mov bx, 320
    mul bx
    add ax, cs:x[si]
    mov bx, 8
    mul bx
    mov bx, ax

    mov al, cs:kolor
    call print_pixel

    add si, 2
    mov ax, cs:len
    add ax, ax
    cmp si, ax 
    jb snake_draw_loop


; draw food
    ; get address of the pixel to draw in bx
    mov ax, cs:food_y
    mov bx, 320
    mul bx
    add ax, cs:food_x
    mov bx, 8
    mul bx
    mov bx, ax

    mov al, 4h
    call print_pixel
    
zakoncz_update:
    pop si
    pop es
    pop bx
    pop ax

    jmp dword PTR cs:wektor8


; zmienne
    kolor db 0Fh
    ; pixel_addres = 8(320y + x)
    x dw 3, 4, 5, 5, 6, 6
    y dw 3, 3, 3, 4, 4, 5
    len dw 6 
    food_x dw 10
    food_y dw 15
    food_dir_x dw 1
    food_dir_y dw 1
    food_move_chance dw 2 ; apple runs away half the speed
    wektor8 dd ?
    game_over db 0; T=1 F=0

update_clock ENDP
    
read_input PROC
    push bx
    push ax
    push es

    mov ax, 0A000h
    mov es, ax

    mov bx, 0
    in  al, 60h

    cmp al, 72
    je up
    cmp al, 80
    je down
    cmp al, 77
    je right
    cmp al, 75
    je left
    jmp finish_read_input

up:
    mov cs:dir_x, 0
    mov cs:dir_y, -1
    jmp finish_read_input
down:
    mov cs:dir_x, 0
    mov cs:dir_y, 1
    jmp finish_read_input
right:
    mov cs:dir_x, 1
    mov cs:dir_y, 0
    jmp finish_read_input
left:
    mov cs:dir_x, -1
    mov cs:dir_y, 0
    jmp finish_read_input

finish_read_input:
    pop es
    pop ax
    pop bx

    jmp dword PTR cs:wektor9

    ; zmienne
    dir_x dw 1 ; 1 left -1 right
    dir_y dw 0 ; 1 down -1 up
    wektor9 dd ?
read_input ENDP

zacznij:
    mov ah, 0
    mov al, 13h
    int 10h

    mov bx, 0
    mov es, bx

    ; wektor 8
    mov eax, es:[32]
    mov cs:wektor8, eax

    mov ax, SEG update_clock
    mov bx, OFFSET update_clock

    cli
    mov es:[32], bx
    mov es:[32+2], ax
    sti

    ; wektor 9
    mov eax, es:[36]
    mov cs:wektor9, eax

    mov ax, SEG read_input
    mov bx, OFFSET read_input

    cli
    mov es:[36], bx
    mov es:[36+2], ax
    sti
    
; zakoncz na 'x'
czekaj:
    mov ah, 1
    int 16h
    jz czekaj

    mov ah, 0
    int 16h
    cmp al, 'x'
    jne czekaj

; wroc do trybu tekstowego
    mov ah, 0
    mov al, 3h
    int 10h

; odtworz wektor 8
    mov eax, cs:wektor8
    mov es:[32], eax

; odtworz wektor 9
    mov eax, cs:wektor9
    mov es:[36], eax

; zakoncz program
    mov ax, 4C00h
    int 21h

rozkazy ENDS

stosik SEGMENT stack
    db 256 dup (?)
stosik ENDS

END zacznij
