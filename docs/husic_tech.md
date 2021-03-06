# HuSIC Technical Document

## このドキュメントについて

このドキュメントは基本情報を記述することを目的としています。  
内容に不備や誤記がある場合があります。

## トラック

行頭にトラック記号を記述することで、ノートやコマンドが使用可能になります。

| トラック記号 | 内容                                           |
| :----------- | :--------------------------------------------- |
| A            | HuC6280 Ch.0 FMLFO(\*1)                        |
| B            | HuC6280 Ch.1 FMLFOコントロール(\*1)            |
| C            | HuC6280 Ch.2                                   |
| D            | HuC6280 Ch.3                                   |
| E            | HuC6280 Ch.4 ノイズ使用可(\*2) XPCM使用可(\*3) |
| F            | HuC6280 Ch.5 ノイズ使用可(\*2) XPCM使用可(\*3) |

(\*1): FMLFO使用時はCh.0とCh.1を合わせて1チャンネルとして扱います。  
(\*2): ノイズ使用時はノートは発音できません。  
(\*3): XPCM使用時はノートやノイズは発音できません。

## 使用可能ヘッダ一覧

行頭に以下のいずれかの文字列があった場合、
ヘッダ行として扱います。

| 文字列                                       | 効果                 | 備考                                                  |
| :------------------------------------------- | :------------------- | :---------------------------------------------------- |
| #TITLE &lt;str&gt;                           | タイトル             |                                                       |
| #COMPOSER &lt;str&gt;                        | 作曲者名             |                                                       |
| #MAKER &lt;str&gt;                           | メーカー             | カバー用                                              |
| #PROGRAMER &lt;str&gt;                       | プログラマ           |                                                       |
| #OCTAVE-REV                                  | オクターブ記号反転   |                                                       |
| #GATE-DENOM &lt;num&gt;                      | ゲートタイム分母     | qコマンドの分母                                       |
| #INCLUDE &lt;file&gt;                        | インクルード         | ファイルを挿入する                                    |
| #OCTAVE-OFS &lt;num&gt;                      | オクターブオフセット |                                                       |
| @XPCM&lt;num&gt; = { "ファイル",再生周波数 } | PCMデータ            | 再生周波数は0-15                                      |
| @WT&lt;num&gt; = { ... }                     | 波形メモリデータ     | 32サンプル分の値を書く                                |
| @MP&lt;num&gt; = { ... }                     | ソフトウェアLFO      |                                                       |
| @EN&lt;num&gt; = { ... }                     | ノートエンベロープ   |                                                       |
| @EP&lt;num&gt; = { ... }                     | ピッチエンベロープ   |                                                       |
| @V&lt;num&gt; = { ... }                      | 音量エンベロープ     |                                                       |
| @&lt;num&gt; = { ... }                       | トーンエンベロープ   | HuSICではハードウェア仕様により音色変更時にノイズあり |
| @ME&lt;num&gt; = { ... }                     | マルチエンベロープ   |                                                       |

@系コマンドではnumは定義番号として機能します。
エンベロープに関しては"&#124;"がループ開始記号として機能します。  
また、x&lt;num&gt;で直前の値*num回の繰り返しが可能です。  

例:

```mml
@V0 = { 31 x4 0 x4 }
```

は、

```mml
@V0 = { 31 31 31 31 0 0 0 0 }
```

と等価です。

## 使用可能コマンド一覧

行頭にトラック記号がある行では、以下のコマンドを使用することができます。

| 文字列                        | 効果                          | 備考                                |
| :---------------------------- | :---------------------------- | :---------------------------------- |
| w[len]                        | ウェイト                      |                                     |
| @t&lt;num,num2&gt;            | テンポ2                       | num * num2 / 192.0                  |
| t&lt;num&gt;                  | テンポ                        |                                     |
| o&lt;num&gt;                  | オクターブ                    |                                     |
| >                             | オクターブアップ              |                                     |
| <                             | オクターブダウン              |                                     |
| l&lt;len&gt;                  | 音長                          |                                     |
| v+                            | 音量プラス                    |                                     |
| v-                            | 音量マイナス                  |                                     |
| v&lt;num&gt;                  | 音量                          | 0:最小 31:最大                      |
| NB                            | バンク切り替え                |                                     |
| EPOF                          | ピッチエンベロープ オフ       |                                     |
| EP&lt;num&gt;                 | ピッチエンベロープ            |                                     |
| ENOF                          | ノートエンベロープ オフ       |                                     |
| EN&lt;num&gt;                 | ノートエンベロープ            |                                     |
| MPOF                          | ソフトウェアLFO オフ          |                                     |
| MP&lt;num&gt;                 | ソフトウェアLFO               |                                     |
| FSOF                          | FMLFO　オフ                   |                                     |
| FS&lt;num&gt;                 | FMLFO 有効/コントロール       | num=0～3                            |
| FF&lt;num&gt;                 | FMLFO 周波数                  |                                     |
| FR                            | FMLFO　リセット               |                                     |
| FM                            | FMLFO　モジュレータ周波数     | num=(oct<<4) &#x7c; (note%12)       |
| MV&lt;num&gt;                 | マスターボリューム            | 左右4bit、16段階。MV$ccなどと設定。 |
| N&lt;num&gt;                  | ノイズスイッチ                | num=1でオン                         |
| PL&lt;num&gt;                 | パンL　音量                   |                                     |
| PR&lt;num&gt;                 | パンR　音量                   |                                     |
| PC&lt;num&gt;                 | パンセンター　音量            |                                     |
| P&lt;num&gt;                  | パン　音量                    |                                     |
| RI&lt;num&gt;                 | リセット無視                  | RIフラグの項目を参照                |
| W&lt;num&gt;                  | 波形メモリ変更                |                                     |
| M&lt;num&gt;                  | モード変更                    | num=1でXPCM                         |
| SDQR                          | セルフディレイ キューリセット |                                     |
| SDOF                          | セルフディレイ オフ           |                                     |
| SD&lt;num&gt;                 | セルフディレイ                |                                     |
| D&lt;num&gt;                  | デチューン                    |                                     |
| K&lt;num&gt;                  | トランスポーズ                |                                     |
| @q&lt;num&gt;                 | クオンタイズ2                 | num=フレーム指定のクオンタイズ      |
| @pe&lt;num&gt;                | パンエンベロープ              | @MEの定義を使用                     |
| @vr&lt;num&gt;                | リリース音量エンベロープ      | @vと同じ定義を使用                  |
| @v&lt;num&gt;                 | 音量エンベロープ              |                                     |
| @@r&lt;num&gt;                | リリーストーンエンベロープ    | @@と同じ定義を使用                  |
| @@&lt;num&gt;                 | トーンエンベロープ            |                                     |
| &lt;ノート&gt;_&lt;ノート&gt; | ポルタメント                  | 例:c_g                              |
| &lt;ノート&gt;&&lt;ノート&gt; | スラー                        | 例:c&g                              |
| x                             | データ直接出力(デバッグ用)    |                                     |
| k&lt;num&gt;                  | キーオフ                      |                                     |
| L                             | 曲ループ記号                  |                                     |
| &#124;:                       | リピート2開始                 |                                     |
| &#x3a; &#124;                       | リピート2終了                 |                                     |
| \\                            | リピート2エスケープ           |                                     |
| [                             | リピート開始                  |                                     |
| ]                             | リピート終了                  |                                     |
| &#124;                        | リピートエスケープ            |                                     |
| {                             | 連符開始                      |                                     |
| }                             | 連符終了                      |                                     |
| q&lt;num&gt;                  | クオンタイズ                  | 音長のn/8以降でキーオフ             |
| ^                             | タイ                          | 例:c4^2                             |
| !                             | トラック強制終了              | この記号以降を無視する              |

## FMLFOについて

FMLFO有効時はCh.1の波形データを周波数変調として利用します。  
FMLFOはFSコマンド使用時に有効になります。  
FMLFOモードを無効化するにはFSOFコマンドを使用します。 

### FSコマンドの数値と機能

| 数値 | 機能                                                           |
| :--- | :------------------------------------------------------------- |
| 0    | 変調されない。Ch.0の波形は変化せず。                           |
| 1    | 波形データはCh.0の周波数に直接加算される。                     |
| 2    | 波形データは左に4回シフト(16倍)されてCh.0の周波数に加算される  |
| 3    | 波形データは左に8回シフト(256倍)されてCh.0の周波数に加算される |

## RIフラグ

エンベロープのキーオン時のリセットを無視するフラグです(各ビットが1で無視します)

| 機能   | ビット | 値 |
| :----- | :----- | :- |
| トーン | 0      | 1  |
| ノート | 1      | 2  |
| ピッチ | 2      | 4  |
| LFO    | 3      | 8  |
| パン   | 4      | 16 |

## ノート表記

行頭にトラック記号がある行では、ノート(音符)を使用することができる。

| ド | レ | ミ | ファ | ソ | ラ | シ | 休符 |
| :- | -- | -- | ---- | -- | -- | -- | ---- |
| c  | d  | e  | f    | g  | a  | b  | r    |
"ノート[音長]"となり、音長を付加しない場合はlコマンドの設定値が音長になる。

| 文字列         | 内容               |
| :------------- | :----------------- |
| n<数値>[,音長] | ノート番号直接入力 |
