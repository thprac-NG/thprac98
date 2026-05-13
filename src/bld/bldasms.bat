:: Build multiple .ASM files to .OBJ files seperately
:: Input: Multiple file basenames. e.g. to build src\foo.asm, input `foo`.
::        You can also input `foo\bar` to build src\foo\bar.asm.
:: Returns: The process will break immediately after one of the build processes
::          fails.
:: Note: This file requires %shell%, %tasm% and file asmargs.tmp to be set in
::       build.bat, so don't call it manually!
@echo off

:loop_start
if %1.==. goto :loop_end
%shell% %tasm% @asmargs.tmp ..\src\%1.asm
if errorlevel 1 goto :bldasm_return
shift
goto :loop_start
:loop_end

:bldasm_return
