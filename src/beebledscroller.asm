; code for the main scroll routine and command parsing

.scroll_message_buffer;
  SKIP 256; 256-byte -  max 255 chars

.scroll_message_pixels_handler_addr
  EQUD $0000

.left_pixel_color_value
       ;--4-2-1-
  EQUB %00000000 ; black   0
  EQUB %00000010 ; red     1
  EQUB %00001000 ; green   2
  EQUB %00001010 ; yellow  3
  EQUB %00100000 ; blue    4
  EQUB %00100010 ; magenta 5
  EQUB %00101000 ; cyan    6
  EQUB %00101010 ; white   7

.right_pixel_color_value
       ;---4-2-1
  EQUB %00000000 ; black   0
  EQUB %00000001 ; red     1
  EQUB %00000100 ; green   2
  EQUB %00000101 ; yellow  3
  EQUB %00010000 ; blue    4
  EQUB %00010001 ; magenta 5
  EQUB %00010100 ; cyan    6
  EQUB %00010101 ; white   7

.chardef
  INCBIN "./resources/fonts/BBC" ; 8x8 pixel font, 8 bytes per char (1bpp), starting at ASCII 32 (space)

.charmap
  FOR n, 0, 128
    EQUB (chardef + (n * 8)) MOD 256 
    EQUB (chardef + (n * 8)) DIV 256 
  NEXT

.scroll_message
    lda scroll_message_subidx
    cmp #0 ; still scrolling current char pixels?
    beq scroll_message_process_next_char
.scroll_message_scroll_handler
    jmp (scroll_message_pixels_handler_addr) ; scroll_message_scroll_char_pixels or scroll_message_scroll_sprite_pixels
.scroll_message_process_next_char
    ldx scroll_message_idx  
    lda scroll_message_buffer,x ; get the char ASCII value
    cmp #&0D
    bne scroll_message_process_char ; end of string?
    ldx #0 ; reset back to start of mesage
    lda scroll_message_buffer,x ; get the char ASCII value of the first character
.scroll_message_process_char
    inx ; increment for next character
    stx scroll_message_idx ; and store
    cmp #'#' ; special command?
    beq scroll_message_command
    sec
    sbc #' ' ; use ascii code for space char as zero base index into chardef
    asl a ; multiple by 2 to get index into charmap
    tax
    lda charmap,x ; address to the chardef address for this character
    sta scroll_char_addr ; low order byte of this characters memory location
    inx 
    lda charmap,x
    sta scroll_char_addr+1 ; high order byte of this characters memory location
    ldx #0
    ldy #0
.scroll_message_process_char_byte ; grab all 8 bytes representing the character into scroll_char_def
    lda (scroll_char_addr),y
    sta scroll_char_def,x
    inx
    iny
    cpx #8
    bne scroll_message_process_char_byte    
    lda #<scroll_message_scroll_char_pixels ; set pixel scroller callback handler to scroll the character pixels
    sta scroll_message_pixels_handler_addr
    lda #>scroll_message_scroll_char_pixels
    sta scroll_message_pixels_handler_addr+1

.scroll_message_scroll_char_pixels
    ldx #0
    ldy #0
    lda #3 ; red line at the top
    sta scroll_new_buffer,y ; store it
    iny 
    lda #0 ; blank line
    sta scroll_new_buffer,y ; store it
    iny 
.scroll_message_scroll_char_rows ; process each charater row
    lda scroll_char_def,x
    clc
    rol a ; roate bits left
    sta scroll_char_def,x
    lda #0
    adc #0 ; includes carry flag
    beq scroll_message_scroll_char_no_pixel1 ; pixel?
    lda scroll_message_text_left_pixel ; set pixel on left
.scroll_message_scroll_char_no_pixel1
    sta scroll_new_buffer,y ; store it
    lda scroll_char_def,x 
    clc
    rol a ; rotate bits left (again, since we are 4bpp)
    sta scroll_char_def,x 
    lda #0
    adc #0 ; includes carry flag
    beq scroll_message_scroll_char_no_pixel2 ; pixel?
    clc
    lda scroll_new_buffer,y
    ora scroll_message_text_right_pixel; set pixel on right
    sta scroll_new_buffer,y ; store it
.scroll_message_scroll_char_no_pixel2
    inx
    iny
    cpx #8
    bne scroll_message_scroll_char_rows ; processed all 8 chardef rows?
    lda #3 ; red line at the bottom
    sta scroll_new_buffer,y ; store it
    inc scroll_message_subidx ; increment for next 2 bits
    lda scroll_message_subidx
    cmp #4 ; all 8 bits proessed? 
    bne scroll_message_scroll_end
    lda #0
    sta scroll_message_subidx ; reset to grab next character
.scroll_message_scroll_end
    lda #0
    rts

.scroll_message_command
    lda scroll_message_buffer,x ; character following the # that has already been parsed
    inx 
    stx scroll_message_idx ; ready for next char
    cmp #'c' ; change text color
    beq scroll_message_command_color
    cmp #'p' ; pause for x seconds
    beq scroll_message_command_pause
    cmp #'s' ; scroll on sprite
    beq scroll_message_command_scroll_sprite
    cmp #'d' ; display a sprite
    beq scroll_message_command_display_sprite
    ; not a command...
    dec scroll_message_idx ; rollback one char - this is not command/droid we where looking for
    jmp scroll_message ; resume reading from message

.scroll_message_command_color ; e.g. #c
    jsr scroll_command_read_value ; returns in X
    lda left_pixel_color_value,x
    sta scroll_message_text_left_pixel
    lda right_pixel_color_value,x
    sta scroll_message_text_right_pixel
    jmp scroll_message ; resume reading from message

.scroll_message_command_pause ; e.g. #p
    jsr scroll_command_read_value ; returns in X
.scroll_message_command_pause_wait
    lda #50 ; wait for 50 vsync
    jsr ezwait
    dex
    cpx #0
    bne scroll_message_command_pause_wait
    jmp scroll_message ; resume reading from message

.scroll_message_command_scroll_sprite ; e.g. #s
    jsr scroll_command_read_value ; returns in X
    jsr scroll_command_sprite_def
    ldy scroll_sprite_width 
    sty scroll_message_subidx ; counts down as we scroll the sprite    
    lda #<scroll_message_scroll_sprite_pixels ; set pixel scroller callback handler to scroll the sprite pixels
    sta scroll_message_pixels_handler_addr
    lda #>scroll_message_scroll_sprite_pixels
    sta scroll_message_pixels_handler_addr+1

.scroll_message_scroll_sprite_pixels
    ldx #0
    lda #SPRITE_HEADER_HEADER_SIZE-1
    clc
    adc scroll_message_subidx
    tay
.scroll_message_scroll_sprite_pixels_loop
    lda (scroll_sprite_addr),y
    sta scroll_new_buffer+2,x ; assuming 8 pixel height 
    tya
    clc
    adc scroll_sprite_width
    tay
    inx
    cpx scroll_sprite_height
    bne scroll_message_scroll_sprite_pixels_loop
    ; red top and bottom border
    lda #3
    sta scroll_new_buffer
    sta scroll_new_buffer+10
    lda #0
    sta scroll_new_buffer+1
    ; process next pixels in sprite next time round
    dec scroll_message_subidx
    rts

.scroll_message_command_display_sprite ; e.g. #d
    jsr scroll_command_read_value ; returns in X
    jsr scroll_command_sprite_def
    ldy #SPRITE_HEADER_DATA ; y is the index into sprite data (limits sprite size to <256)
    lda scroll_sprite_width
    sta scroll_message_subidx
    tax
.scroll_message_command_display_sprite_copy
    lda (scroll_sprite_addr),y ; currently hard coded to sprite 0 11x44 pixels (242 bytes)
    iny ; move forward ready for next sprite byte
    dex ; work backwards storing in the led display memory (Acorn GFX sprites are stored horizontally mirrored)
    sta led_display,x
    dec scroll_message_subidx ; all row pixels processed?
    bne scroll_message_command_display_sprite_copy
    txa
    clc
    adc #(LED_WIDTH/2)
    adc scroll_sprite_width
    tax
    lda scroll_sprite_width
    sta scroll_message_subidx
    dec scroll_sprite_height
    bne scroll_message_command_display_sprite_copy
    lda #0 ; above code assumes screen is at scroll offset 0 
    sta led_screen_offset;
    sta scroll_message_subidx
    jsr update_led_display
    jmp scroll_message ; resume reading from message

.scroll_command_read_value: ; currently assumes only 1 digit (no validation at present)
    lda scroll_message_buffer,x
    inx 
    stx scroll_message_idx ; ready for next char
    clc
    sbc #'0' ;substract ASCII for '0' results in value 0-9
    tax
    inx
    rts

.scroll_command_sprite_def: ; X contains sprite id
    txa
    asl a ; multiply by 2 to arrive at index into sprite_map to get sprite addr
    tax
    lda sprite_map,x
    sta scroll_sprite_addr
    lda sprite_map+1,x
    sta scroll_sprite_addr+1 ; scroll_sprite_addr now points to applicable sprite def structure
    ldy #SPRITE_HEADER_HEIGHT ; in bytes (zero base)
    lda (scroll_sprite_addr),y
    tay
    iny ; scroll_sprite_height is 1 base
    sty scroll_sprite_height
    ldy #SPRITE_HEADER_WIDTH ; in bytes (zero base)
    lda (scroll_sprite_addr),y
    tay
    iny ; scroll_message_width is 1 base
    sty scroll_sprite_width
    rts    