@echo off

set platform_name=%1
set configuration=%2_%3
set angle_dir=..\..\%platform_name%-%3\angle
set indir=%angle_dir%\winrt\8.1
set outdir=%4
set myplatform=unknown

if %platform_name% == winrt_8.1 (
	set myplatform=windows
)
	
if %platform_name% == wp_8.1 (
	set myplatform=windowsphone
)

set inpath=%indir%\%myplatform%\src\%configuration%

echo platform_name = %platform_name%
echo configuration = %configuration%
echo indir = %indir%
echo outdir = %outdir%
echo inpath=%inpath%

xcopy "%inpath%\libEGL.dll" "%outdir%" /iycq
xcopy "%inpath%\lib\libEGL.lib" "%outdir%" /iycq
xcopy "%inpath%\libGLESv2.dll" "%outdir%" /iycq
xcopy "%inpath%\lib\libGLESv2.lib" "%outdir%" /iycq
xcopy "%angle_dir%\include" "%outdir%\..\include\" /iycqs




