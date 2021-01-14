if(HUSIC_BUILD_HUC)

set(pngread_SRCS
    huc/src/mkit/as/pngread/adler32.c   huc/src/mkit/as/pngread/pngmem.c
    huc/src/mkit/as/pngread/crc32.c     huc/src/mkit/as/pngread/pngread.c
    huc/src/mkit/as/pngread/inffast.c   huc/src/mkit/as/pngread/pngrio.c
    huc/src/mkit/as/pngread/inflate.c   huc/src/mkit/as/pngread/pngrtran.c
    huc/src/mkit/as/pngread/inftrees.c  huc/src/mkit/as/pngread/pngrutil.c
    huc/src/mkit/as/pngread/png.c       huc/src/mkit/as/pngread/pngset.c
    huc/src/mkit/as/pngread/pngerror.c  huc/src/mkit/as/pngread/pngtrans.c
    huc/src/mkit/as/pngread/pngget.c    huc/src/mkit/as/pngread/zutil.c
)
set(pngread_HDRS
    huc/src/mkit/as/pngread/crc32.h     huc/src/mkit/as/pngread/pnginfo.h
    huc/src/mkit/as/pngread/inffast.h   huc/src/mkit/as/pngread/pnglibconf.h
    huc/src/mkit/as/pngread/inffixed.h  huc/src/mkit/as/pngread/pngpriv.h
    huc/src/mkit/as/pngread/inflate.h   huc/src/mkit/as/pngread/pngstruct.h
    huc/src/mkit/as/pngread/inftrees.h  huc/src/mkit/as/pngread/pngusr.h
    huc/src/mkit/as/pngread/pngconf.h   huc/src/mkit/as/pngread/zconf.h
    huc/src/mkit/as/pngread/pngdebug.h  huc/src/mkit/as/pngread/zlib.h
    huc/src/mkit/as/pngread/png.h       huc/src/mkit/as/pngread/zutil.h
)
add_library(pngread STATIC ${pngread_SRCS} ${pngread_HDRS})
target_compile_definitions(pngread PUBLIC PNG_USER_CONFIG NO_GZCOMPRESS Z_SOLO NO_GZIP)

find_package(Git)
if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --long --tags --dirty --always
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE huc_GIT_VERSION
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} log -1 --date=format:"%Y/%m/%d %T" --format=%ad
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE huc_GIT_DATE
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
else()
    set(huc_GIT_VERSION "Unknown")
    set(huc_GIT_DATE "__DATE__")
endif()

set(pceas_SRCS
    huc/src/mkit/as/assemble.c  huc/src/mkit/as/func.c   huc/src/mkit/as/nes.c
    huc/src/mkit/as/atari.c     huc/src/mkit/as/input.c  huc/src/mkit/as/output.c
    huc/src/mkit/as/code.c      huc/src/mkit/as/macro.c  huc/src/mkit/as/pce.c
    huc/src/mkit/as/command.c   huc/src/mkit/as/main.c   huc/src/mkit/as/pcx.c
    huc/src/mkit/as/crc.c       huc/src/mkit/as/map.c    huc/src/mkit/as/proc.c
    huc/src/mkit/as/expr.c      huc/src/mkit/as/mml.c    huc/src/mkit/as/symbol.c
)
set( pceas_HDRS
    huc/src/mkit/as/atari.h  huc/src/mkit/as/externs.h  huc/src/mkit/as/pce.h
    huc/src/mkit/as/defs.h   huc/src/mkit/as/inst.h     huc/src/mkit/as/protos.h
    huc/src/mkit/as/expr.h   huc/src/mkit/as/nes.h      huc/src/mkit/as/vars.h
)
add_executable(pceas ${pceas_SRCS} ${pceas_HDRS})
target_link_libraries(pceas PRIVATE pngread)
target_compile_definitions(pceas PUBLIC GIT_VERSION="${huc_GIT_VERSION}" GIT_DATE="${huc_GIT_DATA}")
target_compile_definitions(pceas PRIVATE "$<$<C_COMPILER_ID:MSVC>:_CRT_SECURE_NO_WARNINGS>")

set(huc_SRCS
    huc/src/huc/code.c   huc/src/huc/expr.c      huc/src/huc/lex.c       huc/src/huc/primary.c  huc/src/huc/while.c
    huc/src/huc/const.c  huc/src/huc/function.c  huc/src/huc/main.c      huc/src/huc/pseudo.c
    huc/src/huc/data.c   huc/src/huc/gen.c       huc/src/huc/optimize.c  huc/src/huc/stmt.c
    huc/src/huc/enum.c   huc/src/huc/initials.c  huc/src/huc/pragma.c    huc/src/huc/struct.c
    huc/src/huc/error.c  huc/src/huc/io.c        huc/src/huc/preproc.c   huc/src/huc/sym.c
)
set(huc_HDRS
    huc/src/huc/code.h   huc/src/huc/error.h     huc/src/huc/initials.h  huc/src/huc/pragma.h   huc/src/huc/struct.h
    huc/src/huc/const.h  huc/src/huc/expr.h      huc/src/huc/io.h        huc/src/huc/preproc.h  huc/src/huc/sym.h
    huc/src/huc/data.h   huc/src/huc/fastcall.h  huc/src/huc/lex.h       huc/src/huc/primary.h  huc/src/huc/while.h
    huc/src/huc/defs.h   huc/src/huc/function.h  huc/src/huc/main.h      huc/src/huc/pseudo.h
    huc/src/huc/enum.h   huc/src/huc/gen.h       huc/src/huc/optimize.h  huc/src/huc/stmt.h
)
add_executable(huc ${huc_SRCS} ${huc_HDRS})
target_compile_definitions(huc PUBLIC GIT_VERSION="${huc_GIT_VERSION}" GIT_DATE="${huc_GIT_DATA}")
target_compile_definitions(huc PRIVATE "$<$<C_COMPILER_ID:MSVC>:_CRT_SECURE_NO_WARNINGS>")

install(TARGETS pceas huc)

set(PCEAS_PATH $<TARGET_FILE:pceas>)
set(HUC_PATH $<TARGET_FILE:huc>)
get_filename_component(HUC_INCLUDE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../include/pce REALPATH)

endif(HUSIC_BUILD_HUC)
