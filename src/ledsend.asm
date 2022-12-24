; Code to emit 3 bytes per LED pixel and some simple pause routines
; caller must disable interupts to send more pixel timing is important

.sendPixel
    ; send pixel
    lda green
    sta SR1 ; shift green pixel byte out
    jsr eznop
    jsr eznop
    nop
    nop
    nop
    nop
    nop
    lda red
    sta SR1 ; shift red pixel byte out
    jsr eznop
    jsr eznop
    nop
    nop
    nop
    nop
    nop
    lda blue
    sta SR1 ; shift blue pixel byte out
    jsr eznop
    jsr eznop
    nop
    nop
    nop
    nop
    nop
    rts

.eznop
    rts

.ezwait
    sta temp1
    txa 
    pha
    tya
    pha
.ezwait_loop
    lda #19
    jsr OSBYTE
    dec temp1
    lda temp1 
    cmp #0
    bne ezwait_loop
    pla
    tay
    pla
    tax
    rts