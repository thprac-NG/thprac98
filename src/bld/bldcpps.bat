:: Build multiple .CPP files to .OBJ files seperately
:: Input: Multiple file basenames. e.g. to build src\menu.cpp, input `menu`.
::        You can also input `tui\tui` to build src\tui\tui.cpp.
:: Returns: The process will break immediately after one of the build processes
::          fails.
:: Note: This file requires %shell% and file cppargs.tmp to be set in build.bat,
::       so don't call it manually!
@echo off

:loop_start
if %1.==. goto :loop_end
%shell% tcc -c @cppargs.tmp ..\src\%1.cpp
if errorlevel 1 goto :bldcpp_return
shift
goto :loop_start
:loop_end

:bldcpp_return
