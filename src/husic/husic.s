USE_5BITPCM = 0
    .include "startup.asm"
    .include "xpcmdrv.s"

; [todo] remove
SONG_MAX = 4

  .bss
menu_chn .ds 1
menu_x   .ds 1
menu_y   .ds 1
menu_idx .ds 1

song_no .ds 1

  .code
PRG_TITLE: .db "husic xxx", 0

;;----------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------
_timer_pcm:
    sei
    pha
    phx
    phy

    timer_ack

;    jsr    _pcm_intr

    ply
    plx
    pla

    cli
    rts

;;----------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------
_vsync_drv:
    pha
    phx
    phy

    jsr    drv_intr

    ply
    plx
    pla
    rts

    .code

;;----------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------
_main:
    ; [todo] set timer irq
    ; [todo] set vsync interrupt
    ; [todo] setup vdc interrupts
    
    ; [todo]
    lda    #1
    tam    #4

    lda    #2
    tam    #HUSIC_MPR

    ; clear irq config flag
    stz    <irq_m
    ; set vsync vec
    irq_on INT_IRQ1

    stb    #1, song_no

    jsr    select_song
    
    lda    song_no
    jsr    drv_init

    ; clear screen    
    stb    #32, <_al
    stb    #32, <_ah
    stb    #' ', <_bl
    ldx    #0
    lda    #0
    jsr    print_fill

@loop:
    vdc_wait_vsync

    ; sequence pointer
    stw    <_seq_ptr, <_ax
    stb    #4, <_cl
    ldx    #13
    lda    #3
    jsr    print_hex

    ; top bank
    stz    <_ax+1
    stb    <_ch_topbank, <_ax
    stb    #2, <_cl
    ldx    #20
    lda    #3
    jsr    print_hex

    ; current mapped song bank
    stz    <_ax+1
    stb    <_ch_nowbank, <_ax
    stb    #2, <_cl
    ldx    #23
    lda    #3
    jsr    print_hex

    ; print infos for each chan
    clx
@l0:
        phx
        stx    menu_chn

        txa
        clc
        adc    #5
        sta    menu_y

        stb    #2, menu_x
        
        ; chan number
        stz    <_ax+1
        stx    <_ax
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; command
        stz    <_ax+1
        ldx    menu_chn
        lda    _ch_lastcmd, X
        sta    <_ax
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; count
        stz    <_ax+1
        ldx    menu_chn
        lda    _ch_cnt, X
        sta    <_ax
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; note
        stz    <_ax+1
        ldx    menu_chn
        lda    _note_data, X
        sta    <_ax
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; bank
        stz    <_ax+1
        ldx    menu_chn
        lda    _ch_bank, X
        sta    <_ax
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; pointer
        ldx    menu_chn
        lda    _seq_pos_lo, X
        sta    <_ax
        lda    _seq_pos_hi, X
        stz    <_ax+1
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; pointer
        ldx    menu_chn
        lda    _seq_freq_lo, X
        sta    <_ax
        lda    _seq_freq_hi, X
        sta    <_ax+1
        stb    #2, <_cl
        ldx    menu_x
        lda    menu_y
        jsr    print_hex

        add    #3, menu_x

        ; XPCM
        clx
@xpcm:
        phx

        txa
        clc
        adc    #14
        sta    menu_y

        txa
        asl   A
        sta   menu_idx

        ; pcm data pointer
        ldx    menu_idx
        lda    _xpcm_addr, X 
        sta    <_ax
        lda    _xpcm_addr+1, X
        sta    <_ax+1
        stb    #4, <_cl
        ldx    #1
        lda    menu_y
        jsr    print_hex

        ; pcm data length
        ldx    menu_idx
        lda    _xpcm_len, X 
        sta    <_ax
        lda    _xpcm_len+1, X
        sta    <_ax+1
        stb    #4, <_cl
        ldx    #6
        lda    menu_y
        jsr    print_hex

        plx
        inx
        cpx    #2
        bne    @xpcm

    plx
    inx
    cpx    #PSG_CHAN_COUNT
    beq    @next
    jmp    @l0
@next:

    jmp    @loop

;;----------------------------------------------------------------------------------
; print song title
;;----------------------------------------------------------------------------------
display_title:
    stw    #PRG_TITLE, <_si
    stb    #16, <_al
    stb    #1, <_ah
    ldx    #5
    lda    #2
    jsr    print_string
    rts

;;----------------------------------------------------------------------------------
; song selection menu
;;----------------------------------------------------------------------------------
select_song:
    jsr    display_title

    stw    #@select_song_str, <_si
    stb    #16, <_al
    stb    #1, <_ah
    ldx    #5
    lda    #3
    jsr    print_string
    
    stz    song_no

@loop:
    vdc_wait_vsync

    stz    <_ax+1
    stb    song_no, <_ax
    stb    #2, <_cl
    ldx    #5
    lda    #4
    jsr    print_hex

    lda    joytrg
    bit    #JOYPAD_RIGHT
    beq    @l0
        inc    song_no
        ldx    song_no
        cpx    #SONG_MAX
        bcc    @l0
            stz    song_no
@l0:
    bit    #JOYPAD_LEFT
    beq    @l2
        ldx    song_no
        bne    @l1
            ldx    #SONG_MAX
@l1:
        dex
        stx    song_no
@l2:
    bit    #JOYPAD_RUN
    beq    @l3
        rts
@l3:
    bra    @loop
@select_song_str: .db "SELECT SONG",0

;;----------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------
    .code
    .bank 1
    .org (4<<13)
	.include "hus.s"

    .data
    .bank 2
    .org  (HUSIC_MPR<<13)
    .include "effect.h"
    .include "HesTest01.h"
    
