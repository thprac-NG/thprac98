@echo off


set ReC98_DOS=msdos -e -x
set include_path_arg=-I3rdparty\master.lib\include -I3rdparty\ReC98
set other_arg=-ms -wall -DANCIENT_CXX=1 -v

@rem Building thprac98.exe using command `build.bat` (without args)
if %1.==test. goto end1
  if exist thprac98.exe del thprac98.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\thprac98.cpp @srcfiles

  @rem Modify the header of thprac98.exe
  if not exist stub_hdr.exe ^
    %ReC98_DOS% tcc %include_path_arg% %other_arg% ^
        codegen\stub_hdr.cpp @srcfiles
  %ReC98_DOS% stub_hdr.exe thprac98.exe thprac98.tmp
  copy thprac98.tmp thprac98.exe
  del thprac98.tmp
:end1

@rem Building test suite using command `build.bat test`
if not %1.==test. goto end2
  if exist test.exe del test.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\test.cpp @srcfiles
  if exist tuitest.exe del tuitest.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\tuitest.cpp @srcfiles
:end2