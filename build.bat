@echo off

set ReC98_DOS=msdos -e -x
set include_path_arg=-I3rd-party\master.lib\include -I3rd-party\ReC98
set other_arg=-ms -wall -DANCIENT_CXX=1 -v

if %1.==test. goto end1
  if exist thprac98.exe del thprac98.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\thprac98.cpp @srcfiles
:end1

if not %1.==test. goto end2
  if exist test.exe del test.exe
  %ReC98_DOS% tcc %include_path_arg% %other_arg% src\test.cpp @srcfiles
:end2