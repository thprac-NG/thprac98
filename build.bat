@echo off

set ReC98_DOS=msdos -e -x
set include_path_arg=-I3rdparty\master.lib\include -I3rdparty\ReC98
set other_arg=-ms -wall -DANCIENT_CXX=1 -v

@rem Building thprac98.exe using command `build.bat` (without args)
if not %1.==. goto end_build
  echo [build.bat] Building thprac98.exe...
  if exist thprac98.exe del thprac98.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\thprac98.cpp @srcfiles ^
    || goto :error

  @rem Modify the header of thprac98.exe
  echo [build.bat] Building stub_hdr.exe...
  if not exist stub_hdr.exe %ReC98_DOS% tcc %include_path_arg% %other_arg% ^
    codegen\stub_hdr.cpp @srcfiles || goto :error
  echo [build.bat] Modifying thprac98.exe...
  %ReC98_DOS% stub_hdr.exe thprac98.exe thp98tmp.exe || goto :error
  copy thp98tmp.exe thprac98.exe
  del thp98tmp.exe
  echo [build.bat] Successfully built thprac.exe.
:end_build

@rem Building test suite using command `build.bat test`
if not %1.==test. goto end_test
  echo [build.bat] Building test.exe...
  if exist test.exe del test.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\test.cpp @srcfiles ^
    || goto :error
  echo [build.bat] Building tuitest.exe...
  if exist tuitest.exe del tuitest.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\tuitest.cpp @srcfiles ^
    || goto :error
  echo [build.bat] Successfully built all test suites.
:end_test

@rem Cleaning build stuffs using command `build.bat clean`
if not %1.==clean. goto end_clean
  echo [build.bat] Cleaning .map, .exe, .obj files...
  del /s *.map
  del /s *.obj
  del /s *.exe
  echo [build.bat] Successfully cleaned all the build-related stuffs.
:end_clean

goto :end_of_file
:error
echo Failed with error code %errorlevel%.
exit /b %errorlevel%
:end_of_file