org 0x7c00

    ;--- 割り込み無効
    cli
    ;--- スタート地点へジャンプ
    jmp _start

    ;--- データ領域
boot_drive dw 0    ;--- ブートドライブ
msg01      db " *** MyOS Start ***"


    ;--- スタート地点
_start:
    xor dh, dh
    mov [boot_drive], dx
    ;--- ビデオモード設定
    push ax
    mov ah, 0
    mov al, 0x12   ;640*480(80*30)*16
    int 0x10
    pop ax
    ;--- 文字列出力
    push ax
    push bx
    push cx
    push dx
    push bp
    push es
    xor ax, ax
    mov es, ax
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0b  ;文字色(b0000,lrgb)
    mov cx, 19
    mov dh, 1     ;y座標
    mov dl, 1     ;x座標
    mov bp, msg01
    int 0x10
    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    hlt           ;CPU停止（これがないと、以降の不確定領域を実行してしまう。）

TIMES 510 - ($ - $$) db 0
    dw 0xaa55