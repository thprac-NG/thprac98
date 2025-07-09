@echo off

set ReC98_DOS=msdos -e -x
set include_path_arg=-I3rd-party\master.lib\include
set other_arg=-ms -wall

%ReC98_DOS% tcc @build.tcc