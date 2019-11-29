org 0x7c00

    ;--- 割り込み無効
    cli
    ;--- スタート地点へジャンプ
    jmp _start

    ;--- データ領域
boot_drive dw 0    ;--- ブートドライブ
line_cnt   db 1
msg01      dw 0x000b, 19
           db " *** MyOS Start ***"
msg021     dw 0x000f, 19
           db " A20 mode is ACTIVE"
msg022     dw 0x000f, 21
           db " A20 mode is INACTIVE"
msg031     dw 0x000f, 23
           db " Change to Protect mode"
msg032     dw 0x000f, 20
           db " Change to Real mode"


;****************************************
;* ビデオモード設定
;****************************************
_init_video:
    mov ah, 0
    mov al, 0x12   ;640*480(80*30)*16
    int 0x10
    ret

;****************************************
;* 文字列出力 bp=属性＋文字列アドレス
;****************************************
_print_string:
    ;--- レジスタ退避
    pushf
    push dx
    push cx
    push bx

    xor ax, ax
    mov dh, byte[line_cnt] ;dh=y座標取得
    mov dl, 1
    mov bx, [bp]  ;bh=ページ数, bl=色
    add bp, 2
    mov cx, [bp]  ;cx=文字数
    add bp, 2     ;出力文字列アドレス
    mov ah, 0x13
    mov al, 0x01
    int 0x10

    ;--- カウンタインクリメント
    cmp dh, 20
    je _print_string001
    inc dh
    mov byte[line_cnt], dh
_print_string001:

    ;--- レジスタ復帰
    pop bx
    pop cx
    pop dx
    popf
    ret

;****************************************
;* a20が有効になっているかチェック
;* retrn ax=0(有効), ax==-1(無効)
;****************************************
_is_a20:
    ;--- レジスタ退避
    pushf
    push ds
    push es
    push di
    push si

    ;--- 割込禁止
    cli

    ;--- [ds:di] => 0x0000, 0x0500
    mov ax, 0
    mov ds, ax
    mov di, 0x0500

    ;--- [es:si] => 0xffff, 0x0510
    not ax
    mov es, ax
    mov si, 0x0510

    ;--- [ds:di] & [es:si]のデータ退避
    mov al, byte[ds:di]
    mov ah, byte[es:si]
    push ax

    ;---
    mov byte[ds:di], 0x00
    mov byte[es:si], 0xff
    cmp byte[ds:di], 0xff

    ;--- [ds:di] & [es:si]のデータ退避
    pop ax
    mov byte[ds:di], al
    mov byte[es:si], ah

    ;--- a20有効時ならax=0,無効時ならax=-1
    mov ax, 0xffff
    je _is_a20_exit
    not ax
_is_a20_exit:

    ;--- レジスタ復帰
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

;****************************************
;* プロテクトモードに変更
;****************************************
_active2a20
    in al, 0x92
    or al, 0x02
    out 0x92, al
    ret

;****************************************
;* リアルモードに変更
;****************************************
_inactive2a20
    in al, 0x92
    and al, 0xfd
    out 0x92, al
    ret

;****************************************
;* メインルーチン
;****************************************
_start:
    ;--- ビデオモード設定
    call _init_video

    ;--- スタートメッセージ出力
    mov bp, msg01
    call _print_string

    ;--- プロテクトモードへ
    mov bp, msg031
    call _print_string
    call _active2a20

    ;--- a20有効か確認してメッセージ出力
    call _is_a20
    cmp ax, 0
    je _a20_check_br01
    mov bp, msg022
    call _print_string
    jmp _a20_check_br02
_a20_check_br01:
    mov bp, msg021
    call _print_string
_a20_check_br02:

    ;--- リアルモードへ
    mov bp, msg032
    call _print_string
    call _inactive2a20

    ;--- a20有効か確認してメッセージ出力
    call _is_a20
    cmp ax, 0
    je _a20_check_br03
    mov bp, msg022
    call _print_string
    jmp _a20_check_br04
_a20_check_br03:
    mov bp, msg021
    call _print_string
_a20_check_br04:

    hlt           ;CPU停止（これがないと、以降の不確定領域を実行してしまう。）

TIMES 510 - ($ - $$) db 0
    dw 0xaa55