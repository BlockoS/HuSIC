add_compile_options("$<$<C_COMPILER_ID:MSVC>:/source-charset:utf-8;/execucution-charset=cp932>")
add_compile_options("$<$<C_COMPILER_ID:GNU>:--input-charset=utf-8;--exec-charset=cp932>")

include("huc.cmake")

set(hmckc_SRCS 
    hmckc/src/mckc.c
    hmckc/src/datamake.c
    hmckc/src/strings.c
    hmckc/src/file.c
    hmckc/src/version.c
)
set(hmckc_HDRS hmckc/src/mckc.h)
add_executable(hmckc ${hmckc_SRCS} ${hmckc_HDRS})

add_executable(xpcm wav2pd4/xpcm.c)

install(TARGETS hmckc xpcm)