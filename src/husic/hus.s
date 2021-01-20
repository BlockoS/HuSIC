HUSIC_MPR = 2

MAX_CH = 6

; Envelope reset flags
RI_TE  =  1 ; TONE
RI_NE  =  2 ; NOTE
RI_PE  =  4 ; PITCH
RI_LFO =  8 ; LFO
RI_PAN = 16 ; PAN

SND_SEL = $800 ; Channel Selector
SND_VOL = $801 ; Global Volume
SND_FIN = $802 ; Fine Freq(FREQ LOW)
SND_ROU = $803 ; Rough Freq(FREQ HI)
SND_MIX = $804 ; Mixer
SND_PAN = $805 ; Pan Volume
SND_WAV = $806 ; Wave Buffer
SND_NOI = $807 ; Noise Mode
SND_LFO = $808 ; LFO freq
SND_LTR = $809 ; LFO trig/control

; Effect flag
EFX_SLAR  = 1
EFX_PORT  = 2
EFX_PORT_ST = 4

    .zp
_drv_ax .ds 2
_drv_bx .ds 2
_drv_cx .ds 2
_drv_dx .ds 2
_drv_di .ds 2
_drv_si .ds 2

_reg_ch .ds 1

_seq_ptr .ds 2

_ch_topbank .ds 1
_ch_nowbank .ds 1

_snd_update .ds 1

    .bss
_ch_lastcmd .ds MAX_CH
_ch_cnt     .ds MAX_CH
_ch_vol     .ds MAX_CH
_ch_bank    .ds MAX_CH

_ch_lastvol  .ds MAX_CH
_ch_lasttone .ds MAX_CH

_ch_efx .ds MAX_CH
_ch_rst .ds MAX_CH

_ch_porthi  .ds MAX_CH
_ch_portlo  .ds MAX_CH
_ch_portcnt .ds MAX_CH

_note_data .ds MAX_CH

_multienv_sw .ds MAX_CH
_tone_sw     .ds MAX_CH
_pitch_sw    .ds MAX_CH
_note_sw     .ds MAX_CH

_detune   .ds MAX_CH
_panpod   .ds MAX_CH
_loop_cnt .ds MAX_CH

_seq_pos_lo  .ds MAX_CH
_seq_pos_hi  .ds MAX_CH
_seq_freq_lo .ds MAX_CH
_seq_freq_hi .ds MAX_CH

_tone_envadr_lo   .ds MAX_CH
_tone_envadr_hi   .ds MAX_CH
_pitch_envadr_lo  .ds MAX_CH
_pitch_envadr_hi  .ds MAX_CH
_volume_envadr_lo .ds MAX_CH
_volume_envadr_hi .ds MAX_CH
_note_envadr_lo   .ds MAX_CH
_note_envadr_hi   .ds MAX_CH

_multi_envadr_lo .ds MAX_CH
_multi_envadr_hi .ds MAX_CH
_multi_envcnt_lo .ds MAX_CH
_multi_envcnt_hi .ds MAX_CH

_lfo_sw   .ds MAX_CH ; 0xff = no_effect
_lfo_cnt  .ds MAX_CH ; speed cnt
_lfo_ct2  .ds MAX_CH ; step cnt
_lfo_stp  .ds MAX_CH ; step of 1level
_lfo_lev  .ds MAX_CH ; up/down level of 1step
_lfo_step .ds MAX_CH

_noise_freq .ds 2
_noise_sw .ds 2

_song_track_table   .ds 2       ; [todo] move to zp
_song_bank_table    .ds 2
_song_loop_table    .ds 2
_song_loop_bank     .ds 2

    .code

;;----------------------------------------------------------------------------------
;; function: snd_saw
;; Initalizes wavebuffer to a saw waveform.
;;
;;----------------------------------------------------------------------------------
snd_saw:
    stz    SND_MIX

    clx
@l0:
    stx    SND_WAV
    inx
    cpx    #32
    bne    @l0


    ldx    <_reg_ch
    lda    _panpod, X
    sta    SND_PAN

    ; enable channel
    lda    #$80
    sta    SND_MIX
    rts

;;----------------------------------------------------------------------------------
;; function: drv_init
;; Initialize HuSIC sound driver
;;
;; Parameters:
;;    A - Song index
;;----------------------------------------------------------------------------------
drv_init:
    jsr    drv_init_song
; [todo]    jsr    init_pcmdrv  ; from xpcmdrv.s
    jsr    drv_setintr
    rts

;;----------------------------------------------------------------------------------
;; function: drv_init_song
;; Initialize song replay
;;
;; Parameters:
;;    A - Song index
;;----------------------------------------------------------------------------------
drv_init_song:
    sei

    asl    A
    tay
    lda    song_addr_table, Y
    sec
    sbc    song_addr_table
    sta    <_drv_ax
    iny
    lda    song_addr_table, Y
    sec
    sbc    song_addr_table+1
    sta    <_drv_ax+1


    ; song_000_track_table
    lda    #low(song_000_track_table)
    clc
    adc    <_drv_ax
    sta    _song_track_table
    lda    #high(song_000_track_table)
    adc    <_drv_ax+1
    sta    _song_track_table+1
    
    ; song_000_loop_table
    lda    #low(song_000_loop_table)
    clc
    adc    <_drv_ax
    sta    _song_loop_table        
    lda    #high(song_000_loop_table)
    adc    <_drv_ax+1
    sta    _song_loop_table+1

    ; song_000_bank_table
    lda    #low(song_000_bank_table)
    clc
    adc    <_drv_ax
    sta    _song_bank_table
    lda    #high(song_000_bank_table)
    adc    <_drv_ax+1
    sta    _song_bank_table+1

    ; song_000_loop_bank
    lda    #low(song_000_loop_bank)
    clc
    adc    <_drv_ax
    sta    _song_loop_bank
    lda    #high(song_000_loop_bank)
    adc    <_drv_ax+1
    sta    _song_loop_bank+1

    tma    #HUSIC_MPR
    sta    <_ch_topbank

    stw    #$1234, <_seq_ptr

    clx
@l0:
        stx    <_reg_ch
        stx    SND_SEL

        lda    #$ff
        sta    _tone_sw, X
        sta    _lfo_sw, X
        sta    _note_sw, X
        sta    _panpod, X
        sta    _pitch_sw, X
        sta    _multienv_sw, X
        sta    _ch_lasttone, X

        stz    _loop_cnt, X
        stz    _detune, X

        stz    _ch_cnt, X
        stz    _ch_efx, X
        stz    _ch_rst, X
        stz    _ch_lastvol, X

        stz    _tone_envadr_lo, X
        stz    _tone_envadr_hi, X
        stz    _note_envadr_lo, X
        stz    _note_envadr_hi, X
        stz    _pitch_envadr_lo, X
        stz    _pitch_envadr_hi, X
        stz    _volume_envadr_lo, X
        stz    _volume_envadr_hi, X
        stz    _multi_envadr_lo, X
        stz    _multi_envadr_hi, X

        txa
        asl    A
        tay
        stw    _song_track_table, <_drv_si
        
        lda    [_drv_si], Y
        sta    _seq_pos_lo, X
        iny
        lda    [_drv_si], Y
        sta    _seq_pos_hi, X

        ldy    <_reg_ch
        stw    _song_bank_table, <_drv_si
        lda    [_drv_si], Y
        sta    _ch_bank, X

        jsr    snd_saw

        inx
        cpx    #MAX_CH
        bne    @l0

    stz    _noise_freq
    stz    _noise_freq+1
    stz    _noise_sw
    stz    _noise_sw+1

    ; set volume to maximum
    stb    #$ff, SND_VOL

    cli

    rts

;;----------------------------------------------------------------------------------
;; function: drv_setintr
;; Set VSYNC interrupt hook.
;;
;;----------------------------------------------------------------------------------
drv_setintr:
    sei
    irq_set_vec #VSYNC, #_vsync_drv      ; from main/husic
    irq_enable_vec #VSYNC
    cli
    rts

;;----------------------------------------------------------------------------------
;; function: drv_intr
;; HuSIC driver update.
;;
;;----------------------------------------------------------------------------------
drv_intr:
    stw    #$fffe, <_seq_ptr

    clx
@loop:
        stx    <_reg_ch
        stx    SND_SEL

        ; if the counter is 0, process sequence
        lda    _ch_cnt, X
        bne    @l0
            lda    _seq_pos_lo, X
            sta    <_seq_ptr
            lda    _seq_pos_hi, X
            sta    <_seq_ptr+1

            lda    _ch_bank, X
            sta    <_ch_nowbank

            jsr    do_seq

            lda    <_seq_ptr
            sta    _seq_pos_lo, X
            lda    <_seq_ptr+1
            sta    _seq_pos_hi, X

            lda    <_ch_nowbank
            sta    _ch_bank, X

            lda    <_ch_topbank
            tam    #HUSIC_MPR
@l0:
        dec    _ch_cnt, X

        ; volume envelope
        lda    _volume_envadr_lo, X
        ora    _volume_envadr_hi, X
        beq    @l1
            lda    _volume_envadr_lo, X
            sta    <_drv_si
            lda    _volume_envadr_hi, X
            sta    <_drv_si+1
            lda    [_drv_si]

            inc    _volume_envadr_lo, X
            bne    @l00
                inc    _volume_envadr_hi, X
@l00:

            cmp    #$ff
            bne    @l01
                lda   _ch_vol, X
                and    #$7f
                tay
                lda    softenve_lp_table_lo, Y
                sta    _volume_envadr_lo, X
                sta    <_drv_di
                lda    softenve_lp_table_hi, Y
                sta    _volume_envadr_hi, X
                sta    <_drv_di+1
                lda    [_drv_di]

                inc    _volume_envadr_lo, X
                bne    @l01
                    inc    _volume_envadr_hi, X
@l01:
            and    #$1f
            jsr    mixvol
@l1:
        stz    <_snd_update

        ; note envelope
        lda    _note_envadr_lo, X
        ora    _note_envadr_hi, X
        beq    @l2
            smb0   <_snd_update
            jsr    drv_noteenv
@l2:
        ; tone envelope
        lda    _tone_envadr_lo, X
        ora    _tone_envadr_hi, X
        beq    @l3
            smb0   <_snd_update
            jsr    drv_toneenv
@l3:
        ; pitch envelope
        lda    _pitch_envadr_lo, X
        ora    _pitch_envadr_hi, X
        beq    @l4
            smb0   <_snd_update
            jsr    drv_pitchenv
@l4:
        ; pan envelope
        lda    _multi_envadr_lo, X
        ora    _multi_envadr_hi, X
        beq    @l5
            jsr    drv_panenv
@l5:
        ; lfo sequence
        lda    _lfo_sw, X
        cmp    #$ff
        beq    @l6
            smb0   <_snd_update
            jsr    drv_lfoseq
@l6:
        ; portamento
        lda    _ch_efx, X
        bit    #EFX_PORT
        beq    @l7
            smb0   <_snd_update
     
            stz    <_drv_ax+1
            ; porthi is signed
            lda    _ch_porthi, X
            sta    <_drv_ax
            bpl    @l60
                dec    <_drv_ax+1
@l60:
            ; portlo is 1/128th of the counter value
            lda    _ch_portlo, X
            and    #$7f
            clc
            adc    _ch_portcnt, X
            sta    _ch_portcnt, X
            bpl    @l61
                lda    _ch_portlo, X
                bpl    @l62
                    sec
                    lda    <_drv_ax
                    sbc    #$01
                    sta    <_drv_ax
                    lda    <_drv_ax+1
                    sbc    #$01
                    sta    <_drv_ax+1
                    bra    @l63
@l62:
                    inc    <_drv_ax
                    bne    @l63
                        inc    <_drv_ax+1
@l63:
                lda    _ch_portcnt, X
                and    #$7f
                sta    _ch_portcnt, X
@l61:
            lda    _seq_freq_lo, X
            clc
            adc    <_drv_ax
            sta    _seq_freq_lo, X
            lda    _seq_freq_hi, X
            adc    <_drv_ax+1
            sta    _seq_freq_hi, X
@l7:
        ; update frequency
        bbr0    <_snd_update, @l8
            lda    _seq_freq_lo, X
            sta    SND_FIN
            lda    _seq_freq_hi, X
            sta    SND_ROU
@l8:

    inx
    cpx    #MAX_CH
    beq    @end
        jmp    @loop
@end:
    rts

;;----------------------------------------------------------------------------------
;; function: mixvol
;; Set VSYNC interrupt hook.
;;
;; Parameters:
;;      A - Volume
;;----------------------------------------------------------------------------------
mixvol:
    ; PCM are processed differently
    jsr    _pcm_check
    bcs    @l0
        ora    #$C0
        sta    SND_MIX
        rts
@l0:

    cmp    #$00
    beq    @l1
        ora    #$80
@l1:
    sta    SND_MIX
    sta    _ch_lastvol, X
    rts

;;----------------------------------------------------------------------------------
;; function: drv_noteenv
;;
;;
;;----------------------------------------------------------------------------------
drv_noteenv:
    lda    _note_envadr_lo, X
    sta    <_drv_si
    lda    _note_envadr_hi, X
    sta    <_drv_si+1

    lda    [_drv_si]

    inc    _note_envadr_lo, X
    bne    @l0
        inc    _note_envadr_hi, X
@l0:
    ; end of envelope
    cmp    #$ff
    bne    @l1
        ldy    _note_sw, X
        lda    arpeggio_lp_table_lo, Y
        sta    <_drv_si
        lda    arpeggio_lp_table_hi, Y
        sta    <_drv_si+1

        lda    [_drv_si]
        sta    _note_envadr_lo, X
        sta    <_drv_di
        ldy    #1
        lda    [_drv_si], Y
        sta    _note_envadr_hi, X
        sta    <_drv_di+1

        lda    [_drv_di]

        inc    _note_envadr_lo, X
        bne    @l1
            inc    _note_envadr_hi, X
@l1:

    clc
    adc    _note_data, X
    sta    _note_data, X

    tay
    lda    drv_freq_lo, Y
    sta    _seq_freq_lo, X
    lda    drv_freq_hi, Y
    sta    _seq_freq_hi, X
    rts

;;----------------------------------------------------------------------------------
;; function: drv_toneenv
;;
;;
;;----------------------------------------------------------------------------------
drv_toneenv:
    lda    _tone_envadr_lo, X
    sta    <_drv_si
    lda    _tone_envadr_hi, X
    sta    <_drv_si+1

    lda    [_drv_si]
    ; end of envelope
    cmp    #$ff
    bne    @l1
        ldy    _tone_sw, X
        lda    dutyenve_lp_table_lo, Y
        sta    <_drv_si
        lda    dutyenve_lp_table_lo, Y
        sta    <_drv_si+1
      
        lda    [_drv_si]
        sta    _tone_envadr_lo, X
        sta    <_drv_si
        ldy    #1
        lda    [_drv_si], Y
        sta    _tone_envadr_hi, X
        sta    <_drv_si+1

        lda    [_drv_si]
@l1:

    inc    _tone_envadr_lo, X
    bne    @l0
        inc    _tone_envadr_hi, X
@l0:

    ; update waveform
    jsr    snd_chg
    rts

;;----------------------------------------------------------------------------------
;; function: snd_chg
;;
;;
;;----------------------------------------------------------------------------------
snd_chg:
    cmp    _ch_lasttone, X
    bne    @l0
        rts
@l0:
    sta    _ch_lasttone, X

    tay
    lda    pce_data_table_lo, Y
    sta    <_drv_si
    lda    pce_data_table_hi, Y
    adc    <_drv_si+1

    ; copy waveform
    stz    SND_MIX
    cly
@l1:
        lda    [_drv_si], Y
        sta    SND_WAV
        iny
        cpy    #$20
        bne    @l1

    lda    _ch_lastvol, X
    sta    SND_MIX

    rts

;;----------------------------------------------------------------------------------
;; function: drv_pitchenv
;;
;;
;;----------------------------------------------------------------------------------
drv_pitchenv:
    lda    _pitch_envadr_lo, X
    sta    <_drv_si
    lda    _pitch_envadr_hi, X
    sta    <_drv_si+1

    lda    [_drv_si]

    inc    _pitch_envadr_lo, X
    bne    @l0
        inc    _pitch_envadr_hi, X
@l0:

    cmp    #$ff
    bne    @l1
        ldy    _pitch_sw, X
        lda    pitchenve_lp_table_lo, Y
        sta    _pitch_envadr_lo, X 
        sta    <_drv_si
        lda    pitchenve_lp_table_hi, Y 
        sta    _pitch_envadr_hi, X
        sta    <_drv_si+1

        lda    [_drv_si]

        inc    _pitch_envadr_lo, X
        bne    @l1
            inc    _pitch_envadr_hi, X
@l1:

    cpx    #3
    bcs    @l2
    ldy    _noise_sw-4, X
    beq    @l2
        pha
        cmp    #$80
        bne    @l3
            eor    #$ff
            ; carry is set
@l3:
        adc    _noise_freq-4, X
        sta    _noise_freq-4, X

        and    #$1f
        ora    #$80
        sta    SND_NOI
        pla
@l2:

    cmp    #$80
    bne    @l4
        eor    #$ff
        adc    _seq_freq_lo, X
        sta    _seq_freq_lo, X
        lda    _seq_freq_hi, X
        adc    #$ff
        sta    _seq_freq_hi, X
        rts
@l4:
    adc    _seq_freq_lo, X
    sta    _seq_freq_lo, X
    lda    _seq_freq_hi, X
    adc    #$00
    sta    _seq_freq_hi, X
    rts

;;----------------------------------------------------------------------------------
;; function: drv_panenv
;;
;;
;;----------------------------------------------------------------------------------
drv_panenv:
    ; go to loop position if count is 0
    lda    _multi_envcnt_lo, X
    ora    _multi_envcnt_hi, X
    bne    @l1
        ldy    _multienv_sw, X
        lda    multienv_table_lo, Y
        sta    <_drv_si
        lda    multienv_table_hi, Y
        sta    <_drv_si+1

        ldy    #2
        lda    [_drv_si], Y
        sta    _multi_envcnt_lo, X
        iny
        lda    [_drv_si], Y
        sta    _multi_envcnt_hi, X

        ldy    _multienv_sw, X
        lda    multienv_lp_table_lo, Y
        sta    _multi_envadr_lo, X
        lda    multienv_lp_table_lo, Y
        sta    _multi_envadr_hi, X
@l1:
    ; read or write otherwise
    lda    _multi_envcnt_lo, X
    ora    _multi_envcnt_hi, X
    beq    @l2
        sec
        lda    _multi_envcnt_lo, X
        sbc    #$01
        sta    _multi_envcnt_lo, X
        lda    _multi_envcnt_hi, X
        sbc    #$00
        sta    _multi_envcnt_hi, X
        
        lda    _multi_envadr_lo, X
        sta    <_drv_si
        lda    _multi_envadr_hi, X
        sta    <_drv_si+1

        inc    _multi_envadr_lo, X
        bne    @l3
            inc    _multi_envadr_hi, X
@l3:

        lda    [_drv_si]
        sta    _panpod, X
        sta    SND_PAN
@l2:
    rts

;;----------------------------------------------------------------------------------
;; function: drv_lfoseq
;;
;;
;;----------------------------------------------------------------------------------
drv_lfoseq:
    stz    <_drv_si+1
    lda    _lfo_sw, X
    asl    A
    rol    <_drv_si+1
    asl    A
    rol    <_drv_si+1
    adc    #low(lfo_data) 
    sta    <_drv_si
    lda    #high(lfo_data)
    adc    <_drv_si+1
    sta    <_drv_si+1

    phx    
    lda    _lfo_step, X
    asl    A
    tax
    jmp    [drv_lfoseq_step, X]

drv_lfoseq_step:
    .dw    drv_lfoseq_0
    .dw    drv_lfoseq_1
    .dw    drv_lfoseq_2
    .dw    drv_lfoseq_3
    .dw    drv_lfoseq_4

drv_lfoseq_0:
    plx
    lda    _lfo_cnt, X
    beq    @l0
        dec    _lfo_cnt, X
        rts
@l0:
    ldy    #1
    tya
    sta    _lfo_step, X
    lda    [_drv_si], Y
    sta    _lfo_cnt, X

    iny
    lda    [_drv_si], Y
    sta    _lfo_ct2, X
    sta    _lfo_stp, X

    iny
    lda    [_drv_si], Y
    sta    _lfo_lev, X
    bne    @l1
        inc    _lfo_lev, X
@l1:
    rts

drv_lfoseq_1:
    plx
    lda    _lfo_cnt, X
    beq    @l0
        dec    _lfo_cnt, X
@l0:
    lda    _lfo_ct2, X
    beq    @l1
        dec    _lfo_ct2, X
        rts
@l1:
    lda    _seq_freq_lo, X
    sec
    sbc    _lfo_lev, X
    sta    _seq_freq_lo, X
    lda    _seq_freq_hi, X
    sbc    #$00
    sta    _seq_freq_hi, X

    lda    _lfo_stp, X
    sta    _lfo_ct2, X

    lda    _lfo_cnt, X
    bne    @l2
        ldy    #1
        lda    [_drv_si], Y
        sta    _lfo_cnt, X
        inc    _lfo_step, X
@l2:
    rts

drv_lfoseq_2:
    plx
    lda    _lfo_cnt, X
    beq    @l0
        dec    _lfo_cnt, X
@l0:
    lda    _lfo_ct2, X
    beq    @l1
        dec    _lfo_ct2, X
        rts
@l1:
    lda    _seq_freq_lo, X
    clc
    adc    _lfo_lev, X
    sta    _seq_freq_lo, X
    lda    _seq_freq_hi, X
    adc    #$00
    sta    _seq_freq_hi, X

    lda    _lfo_stp, X
    sta    _lfo_ct2, X

    lda    _lfo_cnt, X
    bne    @l2
        ldy    #1
        lda    [_drv_si], Y
        sta    _lfo_cnt, X
        inc    _lfo_step, X
@l2:
    rts

drv_lfoseq_3:
    plx
    lda    _lfo_cnt, X
    beq    @l0
        dec    _lfo_cnt, X
@l0:
    lda    _lfo_ct2, X
    beq    @l1
        dec    _lfo_ct2, X
        rts
@l1:
    lda    _seq_freq_lo, X
    clc
    adc    _lfo_lev, X
    sta    _seq_freq_lo, X
    lda    _seq_freq_hi, X
    adc    #$00
    sta    _seq_freq_hi, X

    lda    _lfo_stp, X
    sta    _lfo_ct2, X

    lda    _lfo_cnt, X
    bne    @l2
        ldy    #1
        lda    [_drv_si], Y
        sta    _lfo_cnt, X
        inc    _lfo_step, X
@l2:
    rts

drv_lfoseq_4:
    plx
    lda    _lfo_cnt, X
    beq    @l0
        dec    _lfo_cnt, X
@l0:
    lda    _lfo_ct2, X
    beq    @l1
        dec    _lfo_ct2, X
        rts
@l1:
    lda    _seq_freq_lo, X
    sec
    sbc    _lfo_lev, X
    sta    _seq_freq_lo, X
    lda    _seq_freq_hi, X
    sbc    #$00
    sta    _seq_freq_hi, X

    lda    _lfo_stp, X
    sta    _lfo_ct2, X

    lda    _lfo_cnt, X
    bne    @l2
        ldy    #1
        lda    [_drv_si], Y
        sta    _lfo_cnt, X
        lda    #1
        sta    _lfo_step, X
@l2:
    rts

;;----------------------------------------------------------------------------------
;; function: do_seq
;;
;;
;;----------------------------------------------------------------------------------
do_seq:
    lda    <_ch_nowbank
    tam    #HUSIC_MPR

@loop:
    lda    _ch_cnt, X
    beq    @go
        rts
@go:
    ; Fetch command
    lda    [_seq_ptr]
    sta    _ch_lastcmd, X

    ; note key on
    cmp    #$90
    bcs    @l0
        jmp    @next
@l0:

    cmp    #$e6
    bcc    @l1
        ; use jump table if cmd is e6 or above.
        sec
        sbc    #$e6
        asl    A
        tax
        jsr    seq_proc
        ldx    <_reg_ch
        bra    @loop
@l1:
    ; repeat commands
    cmp    #$a1
    bne    @l2
        ; repeat2 command
        inc    <_seq_ptr                ; seq_ptr += 1
        bne    @l20
            inc    <_seq_ptr+1
@l20:
        lda    _loop_cnt, X
        cmp    #$1
        bne    @l22                     ; if loop_cnt[X] == 1
            stz    _loop_cnt, X         ;       loop_cnt[X] = 0
            ldy    #$01                 ;       seq_ptr = seq_ptr[0] | seq_ptr[1]
            lda    [_seq_ptr], Y
            tay
            lda    [_seq_ptr]
            sta    <_seq_ptr
            sty    <_seq_ptr+1
            bra    @loop
@l22:                                   ; else
            lda    <_seq_ptr            ;       seq_ptr += 2
            clc
            adc    #$02
            sta    <_seq_ptr
            bne    @loop
                inc    <_seq_ptr+1
                bra    @loop
@l2:
    cmp    #$a0
    bne    @loop
        ; repeat command
        ldy    #$01
        lda    [_seq_ptr], Y            ; count = seq_ptr[1]
        sta    <_drv_cx
        lda    <_seq_ptr                ; seq_ptr += 2
        adc    #$02
        sta    <_seq_ptr
        lda    <_seq_ptr+1
        adc    #$00
        sta    <_seq_ptr+1

        lda    [_seq_ptr]               ; bank
        sta    <_drv_bx
        ldy    #1
        lda    [_seq_ptr], Y            ; address
        sta    <_drv_si
        iny
        lda    [_seq_ptr], Y
        sta    <_drv_si+1

        clc                             ; seq_ptr += 3
        lda    <_seq_ptr
        adc    #$03
        sta    <_seq_ptr
        lda    <_seq_ptr+1
        adc    #$00
        sta    <_seq_ptr+1

        lda    _loop_cnt, X
        cmp    #$01
        bne    @l3
            stz    _loop_cnt, X
            jmp    @loop
@l3:
        bcc    @l4
            dec    _loop_cnt, X
            bra    @l5
@l4:
            lda    <_drv_cx
            dec    a
            sta    _loop_cnt, X
@l5:
        lda    <_drv_si
        sta    <_seq_ptr
        lda    <_drv_si+1
        sta    <_seq_ptr+1

        lda    <_drv_bx
        tam    #HUSIC_MPR
        sta    <_ch_nowbank
    jmp    @loop
@next:
    ; note number and count
    lda    _ch_lastcmd, X
    sta    _note_data, X

    inc    <_seq_ptr
    bne    @l6
        inc    <_seq_ptr+1
@l6:

    lda    [_seq_ptr]
    sta    _ch_cnt, X

    inc    <_seq_ptr
    bne    @l7
        inc    <_seq_ptr+1
@l7:

    ; Is it PCM?
    jsr    _pcm_check
    bcs    @no_pcm
        lda    <_ch_topbank
        tam    #HUSIC_MPR

        lda    _ch_lastcmd, X
        stz    <_drv_si+1
        asl    a
        rol    <_drv_si+1
        asl    a
        rol    <_drv_si+1
        asl    a
        rol    <_drv_si+1
        clc
        adc    #low(xpcm_data)
        sta    <_drv_si
        lda    #high(xpcm_data)
        adc    <_drv_si+1
        sta    <_drv_si+1

        cly
        lda    [_drv_si], Y
        sta    <_si
        iny
        lda    [_drv_si], Y
        sta    <_si+1
        iny
        lda    [_drv_si], Y
        sta    <_al
        iny
        lda    [_drv_si], Y
        sta    <_ah
        iny
        lda    [_drv_si], Y
        sta    <_bl

        jsr    pcm_play_data

        lda    <_ch_nowbank
        tam    #HUSIC_MPR

        lda    _ch_vol, X
        jsr    set_vol

        rts
@no_pcm:

    ; envelope setting
    tst    #EFX_SLAR, _ch_efx, X
    bne    @no_reset
        lda    _ch_rst, X
        sta    <_drv_ax
@tone:
        bbs0   <_drv_ax, @note
            jsr    reset_te
@note:
        bbs1   <_drv_ax, @pitch
            jsr    reset_ne
@pitch:
        bbs2   <_drv_ax, @lfo
            jsr    reset_pe
@lfo:
        bbs3   <_drv_ax, @pan
            jsr    reset_lfo
@pan
        bbs4   <_drv_ax, @no_reset
            jsr    reset_multienv
@no_reset:

    lda    <_ch_topbank
    tam    #HUSIC_MPR
    
    ; noise
    cpx    #4
    bcc    @no_noise
    
    lda    _noise_sw-4, X
    beq    @no_noise
        lda    _ch_lastcmd, X
        and    #$1f
        sta    _noise_freq-4, X
        ora    #$80
        sta    SND_NOI

        lda    _ch_vol, X
        jsr    set_vol

        lda    <_ch_nowbank
        tam    #HUSIC_MPR
        rts
@no_noise:

    ; set pitch
    lda    _ch_lastcmd, X
    tay
    lda    drv_freq_lo, Y
    sta    _seq_freq_lo, X
    lda    drv_freq_hi, Y
    sta    _seq_freq_hi, X


    ; detune
    cly
    lda    _detune, X
    beq    @no_detune
    bpl    @detune
            eor    #$ff
            inc    A
            ldy    #$ff
@detune:
            clc
            adc    _seq_freq_lo, X
            sta    _seq_freq_lo, X
            tya
            adc    _seq_freq_hi, X
            sta    _seq_freq_hi, X
@no_detune:

    ; set frequency
    lda    _seq_freq_lo, X
    sta    SND_FIN
    lda    _seq_freq_hi, X
    and    #$0f
    sta    SND_ROU

    ; set volume
    tst    #EFX_SLAR, _ch_efx, X
    bne    @no_vol
        lda    _ch_vol, X
        jsr    set_vol
@no_vol:

    ; portamento
    lda    _ch_efx, X
    bit    #EFX_PORT_ST
    beq    @portamento_reset
        and    #~EFX_PORT_ST
        ora    #EFX_PORT
        sta    _ch_efx, X
        bra    @portamento_end
@portamento_reset:
        and    #~(EFX_PORT | EFX_PORT_ST);
        sta    _ch_efx, X
@portamento_end

    ; reset SLAR flag
    lda    _ch_efx, X
    and    #~EFX_SLAR
    sta    _ch_efx, X

    lda    _ch_nowbank
    tam    #HUSIC_MPR

    rts


seq_proc:
    jmp    [seq_proc_tbl, X]

seq_proc_tbl:
    .dw seq_e6
    .dw seq_e7
    .dw seq_e8
    .dw seq_e9
    .dw seq_ea
    .dw seq_eb
    .dw seq_ec
    .dw seq_ed
    .dw seq_ee
    .dw seq_ef
    .dw seq_f0
    .dw seq_f1
    .dw seq_f2
    .dw seq_f3
    .dw seq_f4
    .dw seq_f5
    .dw seq_f6
    .dw seq_f7
    .dw seq_f8
    .dw seq_f9
    .dw seq_fa
    .dw seq_fb
    .dw seq_fc
    .dw seq_fd
    .dw seq_fe
    .dw seq_ff

seq_f3:
seq_f5:
seq_f6:
unused:
    rts

; pan envelope.
seq_e6:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:
    lda    [_seq_ptr]
    ldx    <_reg_ch
    sta    _multienv_sw, X

    jsr    reset_multienv

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; reset arguments
seq_e7;
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:
    lda    [_seq_ptr]
    ldx    <_reg_ch
    sta    _ch_rst, X

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; set master volume
seq_e8:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:
    lda    [_seq_ptr]
    sta    SND_VOL

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    ldx    <_reg_ch
    rts

; slar
seq_e9:
    ldx    <_reg_ch
    lda    _ch_efx, X
    ora    #EFX_SLAR
    sta    _ch_efx, X

    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:
    rts

; HW LFO frequency set
seq_ea:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    #1
    sta    SND_SEL

    lda    [_seq_ptr]
    tay
    lda    drv_freq_lo, Y
    sta    _seq_freq_lo+1
    sta    SND_FIN
    lda    drv_freq_hi, Y
    sta    _seq_freq_hi+1
    and    #$0f
    sta    SND_ROU

    ; key on
    lda    #$80
    sta    SND_MIX

    ldx    <_reg_ch
    stx    SND_SEL
    rts

; portamento
seq_eb:
    ldx    <_reg_ch

    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:
    lda    [_seq_ptr]
    sta    _ch_porthi, X

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    lda    [_seq_ptr]
    sta    _ch_portlo, X

    stz    _ch_portcnt, X

    lda    _ch_efx, X
    ora    #EFX_PORT_ST
    sta    _ch_efx, X

    inc    <_seq_ptr
    bne    @l2
        inc    <_seq_ptr+1
@l2:
    rts

; HW LFO frequency
seq_ec:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    sta    SND_LFO

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; HW LFO mode
seq_ed:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    sta    SND_LTR

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; bank switching
seq_ee:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    sta    <_drv_bx
    ldx    <_reg_ch

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:

    lda    [_seq_ptr]
    pha
    ldy    #1
    lda    [_seq_ptr], Y
    sta    <_seq_ptr+1
    pla
    sta    <_seq_ptr

    lda    <_drv_bx
    tam    #HUSIC_MPR
    sta    <_ch_nowbank

    rts

; xpcm switch
seq_ef:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch
    jsr    _pcm_switch

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; pan
seq_f0:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch
    sta    _panpod, X
    sta    SND_PAN

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; waveform update
seq_f1
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:

    pha

    lda    <_ch_topbank
    tam    #HUSIC_MPR

    pla
    jsr    snd_chg

    lda    #$ff
    sta    _tone_sw, X

    lda    <_ch_nowbank
    tma    #HUSIC_MPR

    rts

; noise command
seq_f2:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:

    cpx    #4
    bcc    @l3
        cmp    #$00
        bne    @l30
            stz    _noise_sw-4, X
            stz    SND_NOI
            rts
@l30
        lda    #$01
        sta    _noise_sw-4, X
@l3:
    rts

; weight arg: count
seq_f4:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch
    sta    _ch_cnt, X

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    rts

; note envelope
seq_f7:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch
    sta    _note_sw, X

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    jsr    reset_ne
    rts

; pitch envelope
seq_f8:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    ldx    <_reg_ch
    sta    _pitch_sw, X

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:

    jsr    reset_pe
    rts

; hardware sweep (unused)
seq_f9:
    lda    <_seq_ptr
    clc
    adc    #2
    sta    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr
@l0:
    rts

; detune
seq_fa:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]
    cmp    #$ff
    bne    @l1
        cla
@l1:
    ldx    <_reg_ch
    sta    _detune, X

    inc    <_seq_ptr
    bne    @l2
        inc    <_seq_ptr+1
@l2:
    rts

; LFO switch
seq_fb:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:
    ldx    <_reg_ch
    sta    _lfo_sw, X
    jsr    reset_lfo
    rts

; rest
seq_fc:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    lda    [_seq_ptr]

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:

    ldx    <_reg_ch
    sta    _ch_cnt, X

    ; disable envelope
    stz    _volume_envadr_lo, X
    stz    _volume_envadr_hi, X

    cla
    jsr    mixvol

    jsr    _pcm_check
    bcs    @l2
        jsr    _pcm_stop
@l2:
    rts

; set volume
seq_fd:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:
    lda    [_seq_ptr]

    inc    <_seq_ptr
    bne    @l1
        inc    <_seq_ptr+1
@l1:

    ldx    <_reg_ch
    sta    _ch_vol, X

    jsr    set_vol
    rts

; set tone
seq_fe:
    inc    <_seq_ptr
    bne    @l0
        inc    <_seq_ptr+1
@l0:

    ldx    <_reg_ch
    ldy    #$01
    lda    [_seq_ptr], Y
    bpl    @l1
        lda    #$ff
@l1:
    sta    _tone_sw, X

    inc    <_seq_ptr
    bne    @l2
        inc    <_seq_ptr+1
@l2:

    jsr    reset_te
    rts

; end of track (currently unused)
seq_ff:
    lda    <_ch_topbank
    tam    #HUSIC_MPR

    lda    _song_loop_table
    sta    <_drv_si
    lda    _song_loop_table+1
    sta    <_drv_si+1

    lda    <_reg_ch
    tax
    asl    A
    tay
    lda    [_drv_si], Y
    sta    <_seq_ptr
    iny
    lda    [_drv_si], Y
    sta    <_seq_ptr+1
    
    lda    _song_loop_bank
    sta    <_drv_si
    lda    _song_loop_bank+1
    sta    <_drv_si+1
    sxy
    lda    [_drv_si], Y
    sta    <_ch_nowbank
    tam    #HUSIC_MPR
    rts


; Reset tone envelope.
reset_te:
    ldx    <_reg_ch
    lda    _tone_sw, X
    cmp    #$ff
    bne    @l0
        stz    _tone_envadr_lo, X
        stz    _tone_envadr_hi, X
        rts
@l0:
        lda    <_ch_topbank
        tam    #HUSIC_MPR

        lda    dutyenve_table_lo, X
        sta    _tone_envadr_lo, X
        lda    dutyenve_table_hi, X
        sta    _tone_envadr_hi, X

        lda    <_ch_nowbank
        tam    #HUSIC_MPR
    rts

; set volume
set_vol:
    ; set volume if > 0x80
    ; otherwise set envelope
    bit    #$80
    beq    @env
@vol:
        stz    _volume_envadr_hi, X
        stz    _volume_envadr_lo, X
        and    #$1f
        jsr    mixvol
        rts
@env:
    tay

    lda    <_ch_topbank
    tam    #HUSIC_MPR

    lda    softenve_table_lo, Y
    sta    _volume_envadr_lo, X
    lda    softenve_table_hi, Y
    sta    _volume_envadr_hi, X
    
    lda    <_ch_nowbank
    tam    #HUSIC_MPR
    rts

; reset LFO
reset_lfo:
    lda    _lfo_sw, X
    cmp    #$ff
    bne    @l0
        stz    _lfo_cnt, X
        rts
@l0:
    lda    <_ch_topbank
    tam    #HUSIC_MPR

    stz    _lfo_step, X

    lda    _lfo_sw, X
    asl    A
    asl    A
    tay
    lda    lfo_data, Y
    sta    _lfo_cnt, X

    lda    <_ch_nowbank
    tam    #HUSIC_MPR
    rts

; reset pitch envelope.
reset_pe:
    lda    _pitch_sw, X
    cmp    #$ff
    bne    @l0
        stz    _pitch_envadr_lo, X
        stz    _pitch_envadr_hi, X
        rts
@l0:
    tay

    lda    <_ch_topbank
    tam    #HUSIC_MPR

    lda    pitchenve_table_lo, Y
    sta    _pitch_envadr_lo, X

    lda    pitchenve_table_hi, Y
    sta    _pitch_envadr_hi, X

    lda    <_ch_nowbank
    tam    #HUSIC_MPR
    rts

; reset note envelope.
reset_ne:
    lda    _note_sw, X
    cmp    #$ff
    bne    @l0
        stz    _note_envadr_lo, X
        stz    _note_envadr_hi, X
        rts
@l0:
    tay

    lda    <_ch_topbank
    tam    #HUSIC_MPR

    lda    arpeggio_table_lo, Y
    sta    _note_envadr_lo, X
    lda    arpeggio_table_hi, Y
    sta    _note_envadr_hi, X

    lda    <_ch_nowbank
    tam    #HUSIC_MPR
    rts

; multi envelope reset
reset_multienv:
    lda    _multienv_sw, X
    cmp    #$ff
    bne    @l0
        stz    multienv_table_lo, X
        stz    multienv_table_hi, X
        rts
@l0:
    lda    <_ch_topbank
    tam    #HUSIC_MPR

    ldy    _multienv_sw, X
    lda    multienv_table_lo, Y
    sta    <_drv_si
    lda    multienv_table_hi, Y
    sta    <_drv_si+1
    lda    [_drv_si]
    sta    _multi_envcnt_lo, X
    lda    <_drv_si
    clc
    adc    #$04
    sta    _multi_envadr_lo, X
    lda    <_drv_si+1
    adc    #$00
    sta    _multi_envadr_hi, X

    lda    <_ch_nowbank
    tam    #HUSIC_MPR
    rts

drv_freq_lo:
    .dwl $d5c,$c9c,$be7,$b3c,$a9b,$a02,$973,$8eb,$86b,$7f2,$780,$714,$6ae,$64e,$5f3,$59e
    .dwl $54d,$501,$4b9,$475,$435,$3f9,$3c0,$38a,$357,$327,$2f9,$2cf,$2a6,$280,$25c,$23a
    .dwl $21a,$1fc,$1e0,$1c5,$1ab,$193,$17c,$167,$153,$140,$12e,$11d,$10d,$0fe,$0f0,$0e2
    .dwl $0d5,$0c9,$0be,$0b3,$0a9,$0a0,$097,$08e,$086,$07f,$078,$071,$06a,$064,$05f,$059
    .dwl $054,$050,$04b,$047,$043,$03f,$03c,$038,$035,$032,$02f,$02c,$02a,$028,$025,$023
    .dwl $021,$01f,$01e,$01c,$01a,$019,$017,$016,$015,$014,$012,$011,$010,$00f,$00f,$00e
    .dwl $00d,$00c,$00b,$00b,$00a,$00a,$009,$008,$008,$007,$007,$007,$006,$006,$005,$005
    .dwl $005,$005,$004,$004,$004,$003,$003,$003,$003,$003,$002,$002,$002,$002,$002,$002
    .dwl $002,$001,$001,$001,$001,$001,$001,$001,$001,$001,$001,$001,$001,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwl $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
drv_freq_hi:
    .dwh $d5c,$c9c,$be7,$b3c,$a9b,$a02,$973,$8eb,$86b,$7f2,$780,$714,$6ae,$64e,$5f3,$59e
    .dwh $54d,$501,$4b9,$475,$435,$3f9,$3c0,$38a,$357,$327,$2f9,$2cf,$2a6,$280,$25c,$23a
    .dwh $21a,$1fc,$1e0,$1c5,$1ab,$193,$17c,$167,$153,$140,$12e,$11d,$10d,$0fe,$0f0,$0e2
    .dwh $0d5,$0c9,$0be,$0b3,$0a9,$0a0,$097,$08e,$086,$07f,$078,$071,$06a,$064,$05f,$059
    .dwh $054,$050,$04b,$047,$043,$03f,$03c,$038,$035,$032,$02f,$02c,$02a,$028,$025,$023
    .dwh $021,$01f,$01e,$01c,$01a,$019,$017,$016,$015,$014,$012,$011,$010,$00f,$00f,$00e
    .dwh $00d,$00c,$00b,$00b,$00a,$00a,$009,$008,$008,$007,$007,$007,$006,$006,$005,$005
    .dwh $005,$005,$004,$004,$004,$003,$003,$003,$003,$003,$002,$002,$002,$002,$002,$002
    .dwh $002,$001,$001,$001,$001,$001,$001,$001,$001,$001,$001,$001,$001,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
    .dwh $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
