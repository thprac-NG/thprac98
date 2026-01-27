@echo off

@rem /ml, /mx is used so that the symbols are all case-sensitive.
msdos tasm /m /ml /mx th01.asm || goto :error
@rem /t is for generating .COM files.
msdos tlink /t th01.obj || goto :error
echo th01.com has been successfully built.

goto :end_of_file
:error
echo Failed with error code %errorlevel%.
exit /b %errorlevel%
:end_of_file