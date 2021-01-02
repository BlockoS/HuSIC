XPCM_CH  = 5
XPCM2_CH = 4
XPCM_MPR = 3

; [todo] comments
; [todo] huc interface

XPCM_FLAG  .equ $01
XPCM2_FLAG .equ $02

    .zp
_xpcm_bank          .ds 2
_xpcm_addr          .ds 4
_xpcm_len           .ds 4
_xpcm_shift         .ds 2
_xpcm_buf           .ds 2
_xpcm_nextbuf       .ds 2

_xpcm_bank_save     .ds 1

_xpcm_flags         .ds 1
_xpcm_play_flags    .ds 1 

    .code

xpcm_ch:
    .db 5,4

pcm_play_data: 
    phx

    lda    <_bl
    sta    <_xpcm_bank, X
    lda    <_al
    sta    <_xpcm_len, X
    lda    <_ah
    sta    <_xpcm_len+2, X
    stz    <_xpcm_shift, X
    stz    <_xpcm_nextbuf, X

    txa
    asl    A
    tax

    lda    <_si
    sta    <_xpcm_addr, X
    lda    <_si+1
    sta    <_xpcm_addr+1, X
    
_pcm_on:
    lda    <_xpcm_play_flags
    bne    @l0
        smb    #2, <irq_m
@l0:
    pla
    inc    A
    tsb    <_xpcm_play_flags
    rts

; ch: X
_pcm_stop:
_pcm_off:
    inc    A
    trb    <_xpcm_play_flags
    bne    @l0
        rmb    #2, <irq_m
@l0:
    rts

; ch: X
; mode: A
_pcm_switch:
    cmp    #$00
    beq    @disable
@enable:
    lda    xpcm_ch, X
    sta    psg_chn
    
    lda    #$df
    sta    psg_ctrl

    lda    <_reg_ch
    sta    psg_chn

    txa
    inc    A
    tsb    <_xpcm_flags
    rts
@disable:
    txa
    inc    A
    trb    <_xpcm_flags
    bne    @l0
        trb    <_xpcm_play_flags
        bne    @l0
            rmb    #2, <irq_m
@l0:
    rts

    ;_pcm_proc < ch , index >
    ;
    ; in : ch = 物理チャンネル
    ;    : index = 変数の相対位置
  .macro _pcm_proc
    ; チャンネル選択
    lda    #\1
    sta    psg_chn

    ; バンク切り替え
    tma    #XPCM_MPR
    pha

    lda     <_xpcm_bank + \2
    tam     #XPCM_MPR

    ; 4bitシフト
    lda    <_xpcm_shift + \2
    beq    .high_\2
.low_\2:
        lda    [_xpcm_addr + (\2 * 2)]
        asl    A
        and    #$1e
        pha

        inc    <_xpcm_addr + (\2 * 2)
        bne    .l0_\@
            inc    <_xpcm_addr + (\2 * 2) + 1
            lda    <_xpcm_addr + (\2 * 2) + 1
            cmp    #((XPCM_MPR+1) << 5)
            bcc    .l0_\@
                and    #%000_11111
                ora    #(XPCM_MPR << 5)
                sta    <_xpcm_addr + (\2 * 2) + 1
                inc    <_xpcm_bank + \2
.l0_\@:
        sec
        lda    <_xpcm_len + \2
        sbc    #$01
        sta    <_xpcm_len + \2
        bcs    .l1_\@
            dec    <_xpcm_len + 2 + \2
.l1_\@:
        pla

        bra    .store_\2
.high_\2:
    lda    [_xpcm_addr + (\2 * 2)]
    lsr    A
    lsr    A
    lsr    A
    and    #$1e
.store_\2:
    ; DACへ出力
    sta    psg_wavebuf

    ; バンク切り替えを戻す
    pla
    tam    #XPCM_MPR

    ; シフトフラグを反転
    lda    <_xpcm_shift + \2
    eor    #1
    sta    <_xpcm_shift + \2

    lda    <_xpcm_len + \2
    ora    <_xpcm_len + 2 + \2
    bne    .end_\2
        ; PCMをオフにする
        lda    #(\2+1)
        trb    <_xpcm_play_flags
        bne    .end_\2
            rmb    #2, <irq_m
.end_\2:
  .endm

  .if (USE_5BITPCM)
    ;_pcm_proc_8bit < ch , index >
    ;
    ; in : ch = 物理チャンネル
    ;    : index = メモリ相対位置
  .macro _pcm_proc_8bit
    ; チャンネル選択
    lda    #\1
    sta    psg_chn

    ; バンク切り替え
    tma    #XPCM_MPR
    pha
    lda    <_xpcm_bank + \2
    tam    #XPCM_MPR

    ; バッファに読み出し
    lda    [_xpcm_addr + (\2 * 2)]
    sta    psg_wavebuf

    pla
    tam    #XPCM_MPR

    ; アドレスポインタ加算
    inc    <_xpcm_addr + (\2 * 2)
    bne    .l0_\@
        inc    <_xpcm_addr + (\2 * 2) + 1
        lda    <_xpcm_addr + (\2 * 2) + 1
        cmp    #((XPCM_MPR+1) << 5)
        bcc    .l0_\@
            and    #%000_11111
            ora    #(XPCM_MPR << 5)
            sta    <_xpcm_addr + (\2 * 2) + 1
            inc    <_xpcm_bank + \2
.l0_\@:

    ; 残りサイズ減算
    sec
    lda    <_xpcm_len + \2
    sbc    #$01
    sta    <_xpcm_len + \2
    bcs    .l1_\@
        dec    <_xpcm_len + 2 + \2
.l1_\@:

    ; 残りサイズの確認
    lda    <_xpcm_len + \2
    ora    <_xpcm_len + 2 + \2
    ; まだサイズがあるのでスキップする
    bne    .end_\2
        ; PCMをオフにする
        lda    #(\2+1)
        trb    <_xpcm_play_flags
        bne    .end_\2
            rmb    #2, <irq_m
    ;　終了
.end_\2:
  .endm
  .endif

;
; pcm_intr
;
_pcm_intr:
    ; 再生フラグチェックで各PCM再生
    bbr0    <_xpcm_play_flags, .ch2
.ch1:
    ; PCM出力
  .if (USE_5BITPCM)
        ; 5ビット
        _pcm_proc_8bit 5, 0
  .else
        ; 4ビット
        _pcm_proc 5, 0
  .endif
.ch2:
    bbr1    <_xpcm_play_flags, .end
    ; PCM出力
  .if (USE_5BITPCM)
        ; 5ビット
        _pcm_proc_8bit 4, 1
  .else
        ; 4ビット
        _pcm_proc 4, 1
  .endif
.end:
    ; チャンネルを戻して終了
    lda    <_reg_ch
    sta    psg_chn
    rts

; PCMバンク
_chg_pcmbank:
    txa
    tam #XPCM_MPR
    rts

init_pcmdrv:
    stz    <_xpcm_addr
    stz    <_xpcm_addr+1
    stz    <_xpcm_addr+2
    stz    <_xpcm_addr+3
    stz    <_xpcm_len
    stz    <_xpcm_len+1
    stz    <_xpcm_len+2
    stz    <_xpcm_len+3

    stz    <_xpcm_shift
    stz    <_xpcm_shift+1
    stz    <_xpcm_bank
    stz    <_xpcm_bank+1

    stz    <_xpcm_play_flags
    stz    <_xpcm_flags;

    ; 割り込みタイマー設定
_set_pcmintr:
    ; タイマー割り込みを禁止にする
    rmb    #2, <irq_m
    stz    irq_status
    
    lda    #low(_pcm_intr)
    sta    timer_jmp
    lda    #high(_pcm_intr)
    sta    timer_jmp+1

    ; V = 1
    ; (7.159090 / 1024) / V = 6991.29Hz
    stz   timer_cnt

    lda   #$1
    sta   timer_ctrl

    cli

    rts

; X: channel
_pcm_check:
    cpx   #XPCM_CH
    bne   @l0
        bbr1    <_xpcm_flags, @end
            clc
            rts
@l0:
    cpx   #XPCM2_CH
    bne   @end
        bbr2    <_xpcm_flags, @end
            clc
            rts
@end:
    sec
    rts