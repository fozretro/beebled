; OS Routines
OSWRCH=&FFEE
OSRDCH=&FFE0
OSBYTE=&FFF4
OSARGS=&FFDA
OSFILE=&FFDD
KEYCODE=&EC
; various constants
LED_WIDTH = 44
LED_HEIGHT = 11
LED_BUFFER_END_TOKEN = $FF
LED_BUFFER_PAGE_SIZE = 255 ; Page size enough for 85 pixels (4bpp)
LED_SIZE_BYTES = LED_WIDTH * LED_HEIGHT / 2; Number of bytes used to store display (4bpp)
COLOR_BLACK = 0
COLOR_RED = 1
COLOR_GREEN = 2
COLOR_YELLOW = 3
COLOR_BLUE = 4
COLOR_MEGENTA = 5
COLOR_CYAN =6
COLOR_WHITE = 7
; idx into sprite file header
SPRITE_FILE_HEADER_FILESIZE = 0 ; 2 bytes
SPRITE_FILE_HEADER_NUMBER_OF_SPRITES = 2 ; 1 byte
SPRITE_FILE_HEADER_SPRITES_DATA = 3 ; sprites data
SPRITE_FILE_HEADER_HEADER_SIZE = 3; Size in bytes (not zero basedO of above header)
; idx into sprite entry header
SPRITE_HEADER_WIDTH = 0 ; zero based - 1 byte
SPRITE_HEADER_HEIGHT =1 ; zero based - 1 byte
SPRITE_HEADER_SIZE = 2; 2 bytes
SPRITE_HEADER_MODE = 4; 1 byte
SPRITE_HEADER_ID = 5; 1 byte
SPRITE_HEADER_DATA = 6; Start of sprite data (length per above)
SPRITE_HEADER_HEADER_SIZE = 6; Size in bytes (not zero based) of above sprite header 
; zero page usage - during init
sprite_data_addr = $0070; 2 bytes
sprite_data_size = $0072; 2 bytes
; zero page usage - during main execution
pixel_bytes = $0070; represents the start of the following 3-bytes
red = $0070 ; used by sendPixel
green= $0071 ; used by sendPixel
blue = $0072 ; used by sendPixel
left_pixel_color = $0073 ; output of decodePixel
right_pixel_color = $0074 ; output of decodePixel
led_screen_offset = $0075 ; 1 byte
led_screen_row_number = $0076 ; 1 byte
led_screen_row_offset = $0077 ; 1 byte
led_screen_base = $0078; 2 bytes
led_output_buffer_addr = $007A ; 2 bytes
temp1 = $007C; 1 byte
display_address_map_addr = $007D ; 2 bytes
scroll_message_text_left_pixel = $007F ; 1 byte
scroll_message_idx = $0080 ; 1 byte
scroll_message_subidx = $0081 ; 1 byte - points to column from char def or sprite being scorlled
scroll_char_addr = $0082  ; 2 bytes point to char def structure
scroll_sprite_addr= $0082 ; 2 bytes point to spride def structure, see SPRITE_HEADER_
scroll_char_def = $0084  ; 8 bytes
scroll_sprite_width = $0084 ; 1 byte
scroll_sprite_height = $0085 ; 1 byte
scroll_message_text_right_pixel = $008C; 1 byte
scroll_new_buffer = $008D; 11 bytes representing new pixels to scroll into view
temp2 = $0099 ; 1 byte

ORG &1900

.start
include "src/ledsend.asm"
include "src/leddisplay.asm"
include "src/beebledscroller.asm"

.messageFile
  EQUS "Message",&0D
.spritesFile
  EQUS "Sprites",&0D

.osfileBlk
  EQUW 0 ; Address of file
  EQUD 0 ; Load address of file	
  EQUD 0 ; Execution address of file.	
  EQUD 0 ; Start address of data for write operations, or length of file for read operations	
  EQUD 0 ; End address of data, that is byte after last byte to be written or file attributes.	

.exec
    jsr init

.mainloop
    LDA #2
    jsr ezwait
    jsr scroll_led
    lda KEYCODE 
    beq mainloop
    lda #&15 ; clear keyboard buffer
    ldx #0
    jsr OSBYTE
    rts

.scroll_led
    ; scroll message text
    jsr scroll_message
    ; take pixels from scroll_new_buffer and insert into right most pixel
    jsr update_led_rightmost_pixels;
    ; horizontal scroll 2 pixels (since we are 4bpp)
    inc led_screen_offset
    lda led_screen_offset
    ; have we overflowed screen memory?
    cmp #LED_SIZE_BYTES
    bcc scroll_led_no_screen_overflow 
    lda #0
    sta led_screen_offset
.scroll_led_no_screen_overflow
    ; update display based on current offset
    jsr update_led_display
    rts

.init
    ; init 6522
    ;     76543210              76             5      432               1      0
    LDA #%01011000 ; T1 control 01, T2 control 0, SRC 110 (Mode 6), PB1 0, PB2 0
    STA ACR ; 6522 ACR register, T1 continuous, PB7 disabled, Shift Out Ø2 (for the LED)
    ; look for "Sprites" file?
    lda #<spritesFile
    sta osfileBlk 
    lda #>spritesFile
    sta osfileBlk+1
    lda #5 ; just get file attrs, A=0 if not found
    ldx #<osfileBlk
    ldy #>osfileBlk
    jsr OSFILE
    cmp #0
    beq init_no_sprites_file
    lda #0
    sta osfileBlk+6 ; instruct OSFILE to load into a specific addr
    sta osfileBlk+7 ; instruct OSFILE to load into a specific addr
    lda #<sprite_data
    sta osfileBlk+2 
    lda #>sprite_data
    sta osfileBlk+3
    lda #&FF ; load "Sprites" file data (must be in Acorn GFX ROM format)
    ldx #<osfileBlk
    ldy #>osfileBlk
    jsr OSFILE
    jsr init_build_sprite_map
.init_no_sprites_file
    ; command line text to scroll message buffer?
    lda #1
    ldx #&70
    ldy #0
    jsr OSARGS
    ldy #0
.init_arg_loop
    lda (&70),Y
    sta scroll_message_buffer,y
    iny
    cmp #&0D 
    bne init_arg_loop
    ; look for "Message" file if no command line text given
    lda scroll_message_buffer
    cmp #&0D
    bne init_scroll_message_loaded
    ; look for "Message" file
    lda #<messageFile
    sta osfileBlk 
    lda #>messageFile
    sta osfileBlk+1
    lda #5 ; just get file attrs, A=0 if not found
    ldx #<osfileBlk
    ldy #>osfileBlk
    jsr OSFILE
    cmp #0
    beq init_scroll_message_loaded 
    lda #0
    sta osfileBlk+6 ; instruct OSFILE to load into a specific addr
    sta osfileBlk+7 ; instruct OSFILE to load into a specific addr
    lda #<scroll_message_buffer
    sta osfileBlk+2 
    lda #>scroll_message_buffer
    sta osfileBlk+3
    lda #&FF ; load the Message file data
    ldx #<osfileBlk
    ldy #>osfileBlk
    jsr OSFILE
.init_scroll_message_loaded
    ; initilize start of the display data and output to led matrix
    lda #0
    sta led_screen_offset;
    lda #<led_display ; low byte of led display memory
    sta led_screen_base;
    lda #>led_display ; high byte of led display memory
    sta led_screen_base+1;
    lda #<display_address_map; 
    sta display_address_map_addr ; low byte of display address map
    lda #>display_address_map; 
    sta display_address_map_addr+1 ; high byte of display address map
    jsr update_led_display
    ; init scroller routines
    lda #0
    sta scroll_message_idx
    sta scroll_message_subidx
    lda left_pixel_color_value+COLOR_MEGENTA
    sta scroll_message_text_left_pixel
    lda right_pixel_color_value+COLOR_MEGENTA
    sta scroll_message_text_right_pixel
    rts

.init_build_sprite_map
    ldx sprite_data+SPRITE_FILE_HEADER_NUMBER_OF_SPRITES ; number of sprites (not zero based)
    lda #<(sprite_data+SPRITE_FILE_HEADER_HEADER_SIZE) ; location of first sprite
    sta sprite_data_addr;
    lda #>(sprite_data+SPRITE_FILE_HEADER_HEADER_SIZE)
    sta sprite_data_addr+1
.init_build_sprite_map_loop
    ldy #SPRITE_HEADER_SIZE ; low size of sprite at current location
    lda (sprite_data_addr),y
    sta sprite_data_size
    ldy #SPRITE_HEADER_SIZE+1 ; high size of sprite at current location
    lda (sprite_data_addr),y
    sta sprite_data_size+1
    ldy #SPRITE_HEADER_ID ; sprite id
    lda (sprite_data_addr),y
    asl a ; multiply by two for location in map for this sprites entry (limits to sprite id's < 128)
    tay
    ; store sprite start address (that is start of sprite header then data)
    lda sprite_data_addr
    sta sprite_map,y
    lda sprite_data_addr+1
    sta sprite_map+1,y
    ; add size of sprite to current sprite data location
    clc
    lda sprite_data_addr
    adc sprite_data_size
    sta sprite_data_addr
    lda sprite_data_addr+1
    adc sprite_data_size+1
    sta sprite_data_addr+1
    ; add size of sprite header to current sprite data location
    clc
    lda sprite_data_addr
    adc #SPRITE_HEADER_HEADER_SIZE ; size of sprite header
    sta sprite_data_addr
    lda sprite_data_addr+1
    adc #0
    sta sprite_data_addr+1
    ; next sprite
    dex 
    cpx #0 ; processed all sprites?
    bne init_build_sprite_map_loop
    rts

.sprite_map ; sprite id forms index, each map entry is 2 bytes - max 16 sprites
    ; byte 1-2 - address of sprite (points to the sprite header followed by data)
    SKIP $20

ALIGN $100
.sprite_data
    EQUB 0

.end
 
PUTFILE "dev/beebled/Sprites", "Sprites",1000
PUTFILE "dev/beebled/Message", "Message",1000
SAVE "BeebLED", start, end, exec 