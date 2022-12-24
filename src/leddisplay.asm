; Code that emits contents of "led_display" (mode 2 4bpp) when "update_led_display" is called
; to the user port and connected led matrix

; 6522 User Port (page 399 of Advanced User Guide)
SR1 = $FE6A
ACR = $FE6B

ALIGN &100

.display_address_map ; use in conjunction with a base offset and then byte offset to resolve actual address
  FOR n, 0, LED_SIZE_BYTES -1 
    EQUB n 
  NEXT
  FOR n, 0, LED_SIZE_BYTES -1
    EQUB n 
  NEXT

.colormap ; map first 7 colors to led green, red blue values
  ;    red blu grn
  EQUB $00,$00,$00,$00 ;black    #0
  EQUB $15,$00,$00,$00 ;red      #1
  EQUB $00,$15,$00,$00 ;green    #2
  EQUB $40,$15,$00,$00 ;yellow   #3
  EQUB $00,$00,$15,$00 ;blue     #4
  EQUB $40,$00,$15,$00 ;magenta  #5
  EQUB $00,$15,$15,$00 ;cyan     #6
  EQUB $15,$15,$15,$00 ;white    #7 (using $FF as end of stream indicator)

.update_led_display ; decode from display memory to buffer, then send from buffer to keep timing
    lda #0; row zero
    sta led_screen_row_number
    lda #<led_output_buffer ; reset ptr to output buffer
    sta led_output_buffer_addr
    lda #>led_output_buffer
    sta led_output_buffer_addr+1
    ldy led_screen_offset
    lda #0
    sta left_pixel_color
    sta right_pixel_color
.read_display_row ; read display memory and push grb bytes to led byte stream buffer
    lda led_screen_row_number 
    cmp #LED_HEIGHT
    beq read_display_ready_to_send
    ; setup mode2 screen location for current row
    asl a
    tax 
    lda mode2screenrows,x 
    sta write_to_mode2_output_addr
    inx
    lda mode2screenrows,x 
    sta write_to_mode2_output_addr+1
    ; different processing for odd vs even rows
    lda led_screen_row_number 
    lsr a
    bcc read_even_row_pixel_start ;first bit set even row
    bcs read_odd_row_pixel_start ;first bit unset odd row
.read_even_row_pixel_start
    ldx #0
.read_even_row_pixels
    lda (led_screen_base),y
    jsr write_to_mode2_output
    jsr decode_pixels
    lda left_pixel_color
    jsr write_to_led_output_buffer
    lda right_pixel_color
    jsr write_to_led_output_buffer
    lda #0
    sta left_pixel_color
    sta right_pixel_color
    iny
    cpy #LED_SIZE_BYTES
    bne read_even_row_pixels_no_overflow
    ldy #0
.read_even_row_pixels_no_overflow
    inx
    cpx #(LED_WIDTH/2) ; end of even row
    bne read_even_row_pixels
    jmp read_next_row
.read_odd_row_pixel_start
    ldx #0
.read_odd_row_pixels_push
    lda (led_screen_base),y
    jsr write_to_mode2_output
    pha 
    iny
    cpy #LED_SIZE_BYTES
    bne read_odd_row_pixels_push_no_overflow
    ldy #0
.read_odd_row_pixels_push_no_overflow
    inx
    cpx #(LED_WIDTH/2) ; end of odd row
    bne read_odd_row_pixels_push
    ldx #0
.read_odd_row_pixels_pull
    pla
    jsr decode_pixels
    lda right_pixel_color
    jsr write_to_led_output_buffer
    lda left_pixel_color
    jsr write_to_led_output_buffer
    lda #0
    sta left_pixel_color
    sta right_pixel_color
    inx
    cpx #(LED_WIDTH/2) ; end of odd row
    bne read_odd_row_pixels_pull
.read_next_row
    ; increment row number
    inc led_screen_row_number
    jmp read_display_row
.read_display_ready_to_send
    lda #LED_BUFFER_END_TOKEN ; store at end of buffer reserved value to signal end of led stream
    ldy #0 
    sta (led_output_buffer_addr),y
    lda #<led_output_buffer ; reset ptr to output buffer
    sta led_output_buffer_addr
    lda #>led_output_buffer
    sta led_output_buffer_addr+1
    sei ; switch off interupts - sending is timing sensitive
.read_display_output_from_buffer ; start outputing the buffer to the led matrix
    lda (led_output_buffer_addr),y
    cmp #LED_BUFFER_END_TOKEN
    beq update_led_display_done
    sta red
    iny 
    lda (led_output_buffer_addr),y
    sta green
    iny 
    lda (led_output_buffer_addr),y
    sta blue
    jsr sendPixel
    iny 
    cpy #LED_BUFFER_PAGE_SIZE
    bne read_display_output_from_buffer
    ldy #0
    inc led_output_buffer_addr+1
    jmp read_display_output_from_buffer
.update_led_display_done
    cli ; re-enable interupts done sending!
    rts

.update_led_rightmost_pixels
    ; copy new right most pixels to display memory
    ldx #0 ; logical location of pixel to update
    ldy #0 ; logical index of new pixels
    lda led_screen_offset
    sta display_address_map_addr ; base of address map is determine by current screen offset
.update_led_rightmost_pixels_loop
    ; move to end of row and keep safe logical index for next iteration
    tya 
    clc
    adc #(LED_WIDTH/2)
    pha 
    ; convert logical index to physical index
    tay
    lda (display_address_map_addr),y 
    tay
    ; copy from scroll buffer to display
    lda scroll_new_buffer,x
    sta (led_screen_base),y
    ; increment to next row and restore original logical index for next iteration
    inx
    pla
    tay
    ; done?
    cpx #LED_HEIGHT 
    bne update_led_rightmost_pixels_loop
    rts

.write_to_mode2_output ; self modifying code to avoid impacting x and y regs
    pha
    EQUB $8D ; STA $3000
.write_to_mode2_output_addr
    EQUB $00 ; 
    EQUB $30 ;
    lda write_to_mode2_output_addr;
    clc
    adc #8
    sta write_to_mode2_output_addr;
    bcc write_to_mode2_output_end
    inc write_to_mode2_output_addr+1;
.write_to_mode2_output_end
    pla
    rts

.decode_pixels ; decodes a mode 2 byte into corresponding colors for left and right pixel
    asl a
    rol left_pixel_color
    asl a
    rol right_pixel_color
    asl a
    rol left_pixel_color
    asl a
    rol right_pixel_color
    asl a
    rol left_pixel_color
    asl a
    rol right_pixel_color
    asl a
    rol left_pixel_color
    asl a
    rol right_pixel_color
    rts

.write_to_led_output_buffer ; pixel color stored in A
    sta temp1
    tya ; protect y reg of caller
    pha
    txa ; protect x reg of caller
    pha
    lda temp1
    asl a ;multiple by 4 to get grb index for led
    asl a
    tax ; x becomes our index into colormap for this pixels grb color
    ldy #0
    ; red
    lda colormap, x ; read directly from the color map and sent to output buffer
    sta (led_output_buffer_addr),y  
    inc led_output_buffer_addr
    ; green
    inx
    lda colormap, x ; read directly from the color map and sent to output buffer
    sta (led_output_buffer_addr),y
    inc led_output_buffer_addr
    ; blue
    inx
    lda colormap, x ; read directly from the color map and sent to output buffer
    sta (led_output_buffer_addr),y
    inc led_output_buffer_addr
    ; end of buffer page boundary?
    ldy led_output_buffer_addr
    cpy #LED_BUFFER_PAGE_SIZE
    bne write_to_byte_buffer_not_next_page
    ; move to next page
    lda #0
    sta led_output_buffer_addr ; rest to first byte of next page
    inc led_output_buffer_addr+1 ; inc high byte of output buffer address aka next page
.write_to_byte_buffer_not_next_page
    pla
    tax
    pla
    tay
    rts

.mode2screenrows
  EQUW $7600
  EQUW $7601
  EQUW $7602
  EQUW $7603
  EQUW $7604
  EQUW $7605
  EQUW $7606
  EQUW $7607
  EQUW $7880
  EQUW $7881
  EQUW $7882
  EQUW $7883

ALIGN $100
.led_display    
  ; 242-byte total, 2 pixels per byte (4bpp) (15 colors), 22 bytes per row, 11 rows of 44 pixels
  SKIP 242

ALIGN $100
.led_output_buffer
  SKIP $600; 1.5k or $0600 