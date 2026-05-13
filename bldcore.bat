:: @echo off

set shell=
if not %1.==dos. set shell=msdos -e -x
set tasm=tasm
if %1.==dos. set tasm=tasm32-d

echo [INFO] Starting the build with parameter %2...

:: Create directory build\ if it doesn't exist, and CD into it
md build
cd build

:: Set up the arguments for tcc and tasm
echo -I..\3rdparty\master.lib\include -I..\3rdparty\ReC98 > cppargs.tmp
echo -I..\3rdparty\printf -I.. >> cppargs.tmp
echo -ms -wall -v -3 -x-RT -DANCIENT_CXX=1 >> cppargs.tmp
echo -DPRINTF_INCLUDE_CONFIG_H=1 >> cppargs.tmp
echo /m5 /w2 > asmargs.tmp

: Test if tasm, tlink and tcc exists
%shell% %tasm% > NUL
if not errorlevel 1 goto :tasmExst
if errorlevel 2 goto :tasmExst
echo [ERROR] Cannot find tasm.
goto :return_1
:tasmExst
%shell% tlink > NUL
if not errorlevel 1 goto :tlnkExst
if errorlevel 2 goto :tlnkExst
echo [ERROR] Cannot find tlink.
goto :return_1
:tlnkExst
%shell% tcc > NUL
if not errorlevel 1 goto :tccExist
if errorlevel 2 goto :tccExist
echo [ERROR] Cannot find tcc.
goto :return_1
:tccExist

if %2.==fast. goto :fastBld
if %2.==com. goto :comBuild

:: Building thprac98.exe using command `build.bat` (without args)
if not %2.==. goto :endNoArg
:fastBld
:comBuild
  echo [INFO] Building th01.com...
  call ..\src\bld\bldasms.bat games\th01
  if errorlevel 1 goto :errRet
  %shell% tlink /tdc th01.obj
  if errorlevel 1 goto :errRet
  echo [INFO] Successfully built th01.com.
  if %2.==com. goto :cleanExt

  if exist comembed.exe goto :skipCmbd
    echo [INFO] Building comembed.exe...
    set build_ret=cmbdRet
    set build_src=..\codegen\comembed.cpp
    set build_base=comembed
    goto :bldExe
    :cmbdRet
  :skipCmbd

  echo [INFO] Generating tsrdata.hpp and tsrdata.cpp...
  %shell% comembed.exe 1 ..\src
  if errorlevel 1 goto :errRet

  echo [INFO] Building thprac98.exe...
  if exist thprac98.exe del thprac98.exe
  set build_ret=mainRet
  set build_src=..\src\main.cpp
  set build_base=main
  goto :bldExe
  :mainRet
  copy main.exe thprac98.exe

  if %2.==fast. goto :skpStHdr
    :: Modify the header of thprac98.exe
    if exist stub_hdr.exe goto :skpBldSH
      echo [INFO] Building stub_hdr.exe...
      set build_ret=shRet
      set build_src=..\codegen\stub_hdr.cpp
      set build_base=stub_hdr
      goto :bldExe
      :shRet
    :skpBldSH
    echo [INFO] Modifying thprac98.exe...
    %shell% stub_hdr.exe thprac98.exe thp98tmp.exe
    if errorlevel 1 goto :errRet
    copy thp98tmp.exe thprac98.exe
    del thp98tmp.exe
  :skpStHdr

  echo [INFO] Embedding .COM files...
  %shell% comembed.exe 2
  if errorlevel 1 goto :errRet

  echo [INFO] Successfully built thprac98.exe.
  goto :cleanExt
:endNoArg

:: Doing code-generation using command `build.bat codegen`
if not %2.==codegen. goto :endCdGen
  echo [INFO] Building licengen.exe...
  set build_ret=lcnGnRet
  set build_src=..\codegen\licengen.cpp
  set build_base=licengen
  goto :bldExe
  :lcnGnRet
  echo [INFO] Generating license.hpp and license.cpp...
  %shell% licengen.exe
  if errorlevel 1 goto :errRet
  echo [INFO] Successfully generated all the code.
  goto :cleanExt
:endCdGen

:: Unknown parameter.
echo [ERROR] Unknown parameter %2.
goto :return_1

:: Return with errorlevel
:errRet
for %%a in (hund ten one) do set %%a=

for %%a in (1 2) do if errorlevel %%a00 set hund=%%a

for %%a in (1 2 3 4 5) do if errorlevel %hund%%%a0 set ten=%%a
if not %hund%.==2. for %%a in (6 7 8 9) do if errorlevel %hund%%%a0 set ten=%%a
if not %hund%.==. if %ten%.==. set ten=0

for %%a in (0 1 2 3 4 5) do if errorlevel %hund%%ten%%%a set one=%%a
if %hund%.==2. if %ten%.==5. goto :skp69chk
for %%a in (6 7 8 9) do if errorlevel %hund%%ten%%%a set one=%%a
:skp69chk

echo [ERROR] Failed with error code %hund%%ten%%one%.
goto :cleanExt

:: Return 1
:return_1
echo [ERROR] Failed with error code 1.
goto :cleanExt

:: Argument 1 (via %build_src%): the .CPP source file containing main_wrapper.
:: Argument 2 (via %build_base%): its filename, without the extension.
:: Returns to %build_ret% when success, exit with errorlevel if failed.
:bldExe
%shell% tcc -c @cppargs.tmp %build_src%
if errorlevel 1 goto :errRet
call ..\src\bld\bldasms.bat entrance mystdlib\str_impl mystdlib\dos_impl
if errorlevel 1 goto :errRet
:: Not adding noexcept.cpp for now, since it requires the standard library
call ..\src\bld\bldcpps.bat menu utils texts textsdef version license
if errorlevel 1 goto :errRet
call ..\src\bld\bldcpps.bat launcher tsrdata mainwrpr
if errorlevel 1 goto :errRet
call ..\src\bld\bldcpps.bat tui\chars tui\tui
if errorlevel 1 goto :errRet
call ..\src\bld\bldcpps.bat mystdlib\stdio mystdlib\string mystdlib\errno
if errorlevel 1 goto :errRet
%shell% tcc -c -P @cppargs.tmp ..\3rdparty\printf\printf.c
if errorlevel 1 goto :errRet
copy ..\3rdparty\master.lib\include\masters.lib tmp.lib
%shell% tlink /m entrance.obj + %build_base%.obj + @..\objfiles ,,, tmp.lib
del tmp.lib
if errorlevel 1 goto :errRet
for %%a in (exe map) do copy entrance.%%a %build_base%.%%a
del entrance.exe
:: A simulated return
goto %build_ret%

:cleanExt
for %%a in (cpp asm) do del %%aargs.tmp
for %%a in (shell tasm) do set %%a=
cd ..
