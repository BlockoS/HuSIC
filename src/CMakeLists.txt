set(HMCKC_SRCS 
    hmckc/src/mckc.c
    hmckc/src/datamake.c
    hmckc/src/strings.c
    hmckc/src/file.c
    hmckc/src/version.c
)
set(HMCKC_HDRS hmckc/src/mckc.h)
add_executable(hmckc ${HMCKC_SRCS} ${HMCKC_HDRS})
target_compile_options(hmckc PRIVATE "$<$<C_COMPILER_ID:MSVC>:/source-charset:utf-8;/execution-charset=cp932>")
target_compile_options(hmckc PRIVATE "$<$<C_COMPILER_ID:GNU>:--input-charset=utf-8;--exec-charset=cp932>")

add_executable(xpcm wav2pd4/xpcm.c)

install(TARGETS hmckc xpcm)