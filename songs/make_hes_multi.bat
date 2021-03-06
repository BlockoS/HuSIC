@ECHO OFF

SET FILEDIR=%~p1
SET FILE=%~n1
SET FIN=%FILEDIR%%FILE%
SET FOUT=%FILE%

SET EXECDIR=%~p0

SET TOP_DIR=%EXECDIR%..
SET PCE_INCLUDE=%TOP_DIR%\;%TOP_DIR%\hescode\;%TOP_DIR%\include\pce

"%TOP_DIR%\bin\hmckc" -i -u %*

if not exist effect.h goto end

"%TOP_DIR%\bin\pceas" -raw makehes.s

copy makehes.pce "%FOUT%.hes"

del makehes.pce
del makehes.sym
del makehes.lst
del define.inc
del effect.h
del "%FIN%.h"

goto end

:debug_end
@echo DEBUG mode

:end
