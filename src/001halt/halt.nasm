org 0x7c00

    ;--- 割り込み無効
    cli
    ;--- CPU停止
    hlt

TIMES 510 - ($ - $$) db 0
    dw 0xaa55