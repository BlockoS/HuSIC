#include <stdio.h>
#include <stdlib.h>

const int freq[]={
    4068 ,/* 0 : o1 :   A : 27.500000 */
    3839 ,/* 1 : o1 :  A# : 29.135235 */
    3624 ,/* 2 : o1 :   B : 30.867706 */
    3420 ,/* 3 : o2 :   C : 32.703197 */
    3228 ,/* 4 : o2 :  C# : 34.647827 */
    3047 ,/* 5 : o2 :   D : 36.708096 */
    2876 ,/* 6 : o2 :  D# : 38.890873 */
    2715 ,/* 7 : o2 :   E : 41.203445 */
    2562 ,/* 8 : o2 :   F : 43.653530 */
    2419 ,/* 9 : o2 :  F# : 46.249302 */
    2283 ,/* 10 : o2 :   G : 48.999428 */
    2155 ,/* 11 : o2 :  G# : 51.913086 */
    2034 ,/* 12 : o2 :   A : 55.000000 */
    1920 ,/* 13 : o2 :  A# : 58.270470 */
    1812 ,/* 14 : o2 :   B : 61.735413 */
    1710  /* 15 : o3 :   C : 65.406395 */
};


int main() {
    int i, j, octave, tone;
    unsigned int table[256];
    for(i=0; i<256; i++) {
        table[i] = 0;
    }
    for(octave=0; octave<12; octave++) {
        for(tone = 0; tone<12; tone++) {
            j = tone + (octave*12);
            i = (tone + 3) & 0x0f;
            table[j] = freq[i] >> octave;
        }
    }

    printf("freq_lo:\n");
    for(j=0; j<16; j++) {
        printf("    .dwl $%03x", table[j*16]);
        for(i=1; i<16; i++) {
            printf(",$%03x",table[i+j*16]);
        }
        printf("\n");
    }
    printf("freq_hi:\n");
    for(j=0; j<16; j++) {
        printf("    .dwh $%03x", table[j*16]);
        for(i=1; i<16; i++) {
            printf(",$%03x",table[i+j*16]);
        }
        printf("\n");
    }

    return EXIT_SUCCESS;
}
