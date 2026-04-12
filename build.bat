@rem Unusable in PC-98 environment. # TODO: make a build98.bat.
@rem # TODO: rewrite this messy build.bat.
@rem # TODO: enter /bin/ folder to store the .obj/map files.
@echo off

set ReC98_DOS=msdos -e -x
set include_path_arg=-I3rdparty\master.lib\include -I3rdparty\ReC98 ^
  -I3rdparty\printf
set other_arg=-ms -wall -DANCIENT_CXX=1 -DPRINTF_INCLUDE_CONFIG_H=1 -v -3 -x-RT

@rem Building thprac98.exe using command `build.bat` (without args)
if not %1.==. goto :end_build
  echo [build.bat] Building thprac98.exe...
  echo %include_path_arg% %other_arg% > tmp\args
  if exist thprac98.exe del thprac98.exe
  %ReC98_DOS% tasm src\entrance.asm || goto :error
  %ReC98_DOS% tasm src\mystdlib\str_impl.asm || goto :error
  %ReC98_DOS% tasm src\mystdlib\dos_impl.asm || goto :error
  %ReC98_DOS% tcc -c @tmp\args src\main.cpp || goto :error
  @rem Not adding noexcept.cpp for now, since it requires the standard library
  for %%a in (src\menu.cpp src\utils.cpp src\texts.cpp src\textsdef.cpp
      src\version.cpp src\license.cpp src\tui\chars.cpp src\tui\tui.cpp
      src\mystdlib\stdio.cpp src\mystdlib\string.cpp) do (
    %ReC98_DOS% tcc -c @tmp\args %%a || goto :error
  )
  %ReC98_DOS% tcc -c -P @tmp\args 3rdparty\printf\printf.c || goto :error
  %ReC98_DOS% tlink entrance.obj + main.obj + @objfiles ,,, ^
    3rdparty\master.lib\include\masters.lib || goto :error
  copy entrance.exe thprac98.exe
  del entrance.exe

  @rem Modify the header of thprac98.exe
  echo [build.bat] Building stub_hdr.exe...
  if not exist stub_hdr.exe %ReC98_DOS% tcc @tmp\args codegen\stub_hdr.cpp ^
    @srcfiles || goto :error
  echo [build.bat] Modifying thprac98.exe...
  %ReC98_DOS% stub_hdr.exe thprac98.exe tmp\thp98tmp.exe || goto :error
  copy tmp\thp98tmp.exe thprac98.exe
  del tmp\thp98tmp.exe tmp\args
  echo [build.bat] Successfully built thprac98.exe.
:end_build

@rem Building test suite using command `build.bat test`
if not %1.==test. goto :end_test
  echo [build.bat] Building test.exe...
  if exist test.exe del test.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\test.cpp @srcfiles ^
    || goto :error
  @REM echo [build.bat] Building tuitest.exe...
  @REM if exist tuitest.exe del tuitest.exe
  @REM %ReC98_DOS% tcc %include_path_arg% %other_arg% src\tuitest.cpp @srcfiles ^
  @REM   || goto :error
  echo [build.bat] Successfully built all test suites.
:end_test

@rem Cleaning build stuffs using command `build.bat clean`
if not %1.==clean. goto :end_clean
  echo [build.bat] Cleaning .map, .exe, .obj files...
  @rem # TODO: Come up with a better solution than below.
  for %%i in (chars, license, menu, noexcept, stub_hdr, texts, textsdef,
      thprac98, tui, utils, version) do (
    del %%i.map %%i.obj %%i.exe
  )
  echo [build.bat] Successfully cleaned all the build-related stuffs.
:end_clean

@rem Doing code-generation using command `build.bat codegen`
if not %1.==codegen. goto :end_codegen
  @REM echo [build.bat] Building text_gen.exe...
  @REM c++ codegen/text_gen.cpp -o text_gen.exe -I. -I3rdparty/json/include ^
  @REM   -std=c++11 || goto :error
  @REM echo [build.bat] Generating textsdef.hpp and textsdef.cpp...
  @REM text_gen.exe || goto :error
  echo [build.bat] Building licengen.exe from licengen.cpp...

  echo %include_path_arg% %other_arg% > tmp\args
  %ReC98_DOS% tasm src\entrance.asm || goto :error
  %ReC98_DOS% tasm src\mystdlib\str_impl.asm || goto :error
  %ReC98_DOS% tasm src\mystdlib\dos_impl.asm || goto :error
  %ReC98_DOS% tcc -c @tmp\args codegen\licengen.cpp || goto :error
  @rem Not adding noexcept.cpp for now, since it requires the standard library
  for %%a in (src\menu.cpp src\utils.cpp src\texts.cpp src\textsdef.cpp
      src\version.cpp src\license.cpp src\tui\chars.cpp src\tui\tui.cpp
      src\mystdlib\stdio.cpp src\mystdlib\string.cpp) do (
    %ReC98_DOS% tcc -c @tmp\args %%a || goto :error
  )
  %ReC98_DOS% tcc -c -P @tmp\args 3rdparty\printf\printf.c || goto :error
  %ReC98_DOS% tlink entrance.obj + @objfiles ,,, ^
    3rdparty\master.lib\include\masters.lib || goto :error
  copy entrance.exe licengen.exe
  del entrance.exe tmp\args
  echo [build.bat] Generating license.hpp and license.cpp...
  %ReC98_DOS% licengen.exe || goto :error
  echo [build.bat] Successfully generated all the code.
:end_codegen

goto :end_of_file
:error
echo [build.bat] Failed with error code %errorlevel%.
exit /b %errorlevel%
:end_of_file