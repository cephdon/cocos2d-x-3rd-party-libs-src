@echo off

set FOUND_VC=0

if defined VS120COMNTOOLS (
    set VSTOOLS="%VS120COMNTOOLS%"
    set VC_VER=120
    set FOUND_VC=1
) 

set VSTOOLS=%VSTOOLS:"=%
set "VSTOOLS=%VSTOOLS:\=/%"

set VSVARS="%VSTOOLS%vsvars32.bat"

if not defined VSVARS (
    echo Can't find VC2013 installed!
    goto ERROR
)

echo msbuild  %1 /p:Configuration="%2"  /p:Platform="%3" /m

call %VSVARS%
if %FOUND_VC%==1 (
    msbuild  %1 /p:Configuration="%2"  /p:Platform="%3" /t:Clean
    msbuild  %1 /p:Configuration="%2"  /p:Platform="%3" /m
) else (
    echo Script error.
    goto ERROR
)

goto EOF

:ERROR

:EOF
