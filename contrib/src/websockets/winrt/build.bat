:: ---------------------------------------------------------------------------
:: WinRT Build Script for websockets
:: ---------------------------------------------------------------------------

@echo off
setlocal

set SHA=15c92b1bf6a4562733b52e03b9e2f21421d180c6
set URL=https://github.com/warmcat/libwebsockets/archive/%SHA%.tar.gz
set STARTDIR=%cd%
set LOGFILE=%~dp0\build.log
SET PATCH=%~dp0\patch\winrt.patch

call :DO_LOG "Starting libwebsockets-%SHA% build..."

goto:install

:: ---------------------------------------------------------------------------
:: Clean previous build
:: ---------------------------------------------------------------------------

if exist %LOGFILE% (
	rm -f %LOGFILE%
)

if exist install (
	rm -rf install
)

mkdir install
rem goto:install

if exist temp (
	rm -rf temp
)
mkdir temp

:: ---------------------------------------------------------------------------
:: Download code if necessary
:: ---------------------------------------------------------------------------

pushd ..\..\..\tarballs
	sha512sum --check ..\src\websockets\winrt\SHA512SUMS

	if %ERRORLEVEL% NEQ 0 (

		if exist libwebsockets-winrt-15c92b1.tar.xz (
			rm libwebsockets-winrt-15c92b1.tar.xz
		)
		
		if exist %SHA%.tar.gz (
			rm %SHA%.tar.gz
		)
		
		call :DO_LOG "Downloading libwebsockets 15c92b1..."
		curl -O -L %URL%
		mv %SHA%.tar.gz libwebsockets-winrt-15c92b1.tar.xz
	)	
popd

:: ---------------------------------------------------------------------------
:: Decompress code
:: ---------------------------------------------------------------------------

call :DO_LOG "Decompressing libwebsockets-winrt-15c92b1.tar.xz..."
tar -xzf ../../../tarballs/libwebsockets-winrt-15c92b1.tar.xz -C temp	
	
:: ---------------------------------------------------------------------------
:: Patch code
:: ---------------------------------------------------------------------------

pushd temp
	pushd libwebsockets-%SHA%
		call :DO_LOG "Applying patch..."
		patch -p1 < %PATCH%"
		if %ERRORLEVEL% NEQ 0 (
			call :DO_LOG "ERROR: applying patch %PATCH%"
			goto:error_exit
		) 
	popd
popd

:: ---------------------------------------------------------------------------
:: Create Windows 10.0 and 8.1 project files using CMake
:: ---------------------------------------------------------------------------
	
pushd temp
	pushd libwebsockets-%SHA%
		set SRC=%cd%
	popd
	
	call :DO_LOG "Generating project files with CMake..."
	
	call :DO_CMAKE win10
	if %ERRORLEVEL% NEQ 0 goto:error_exit
	
	call :DO_CMAKE wp_8.1
	if %ERRORLEVEL% NEQ 0 goto:error_exit

	call :DO_CMAKE winrt_8.1
	if %ERRORLEVEL% NEQ 0 goto:error_exit
popd

:: ---------------------------------------------------------------------------
:: Build Windows 10.0 and 8.1 project files using CMake
:: ---------------------------------------------------------------------------

:build
pushd temp
	call "%VS140COMNTOOLS%vsvars32.bat"
	
	:: ---------------------------------------------------------------------------
	:: build for Windows 10 Universal 
	:: ---------------------------------------------------------------------------
	call :DO_BUILD win10 Win32 MinSizeRel
	if %ERRORLEVEL% NEQ 0 goto:error_exit

	call :DO_BUILD win10 arm MinSizeRel
	if %ERRORLEVEL% NEQ 0 goto:error_exit

	call :DO_BUILD win10 x64 MinSizeRel
	if %ERRORLEVEL% NEQ 0 goto:error_exit
	
	:: ---------------------------------------------------------------------------
	:: build for Windows Phone 8.1
	:: ---------------------------------------------------------------------------
	if %ERRORLEVEL% NEQ 0 goto:error_exit
	call :DO_BUILD wp_8.1 Win32 MinSizeRel
	
	call :DO_BUILD wp_8.1 arm MinSizeRel
	if %ERRORLEVEL% NEQ 0 goto:error_exit

	:: ---------------------------------------------------------------------------
	:: build for Windows Store 8.1
	:: ---------------------------------------------------------------------------
	call :DO_BUILD winrt_8.1 Win32 MinSizeRel
	if %ERRORLEVEL% NEQ 0 goto:error_exit

	call :DO_BUILD winrt_8.1 arm MinSizeRel
	if %ERRORLEVEL% NEQ 0 goto:error_exit

popd

:: ---------------------------------------------------------------------------
:: Install Windows 10.0 and 8.1 libs in cocos2d-x v3 folder format
:: ---------------------------------------------------------------------------

:install
call :DO_LOG "Installing libwebsockets..."

set INDIR=temp\winrt_8.1\win32\install
xcopy "%INDIR%\include" "install\websockets\include\winrt_8.1\*" /iycqs

set INDIR=temp\wp_8.1\win32\install
xcopy "%INDIR%\include" "install\websockets\include\wp_8.1\*" /iycqs

set INDIR=temp\win10\win32\install
xcopy "%INDIR%\include" "install\websockets\include\win10\*" /iycqs
xcopy "%SRC%\lib\private-libwebsockets.h" "install\websockets\include\winrt_8.1\*" /iycq
xcopy "%SRC%\lib\private-libwebsockets.h" "install\websockets\include\wp_8.1\*" /iycq
xcopy "%SRC%\lib\private-libwebsockets.h" "install\websockets\include\win10\*" /iycq

xcopy "temp\wp_8.1\win32\lws_config.h" "install\websockets\include\winrt_8.1\*" /iycq
xcopy "temp\winrt_8.1\win32\lws_config.h" "install\websockets\include\wp_8.1\*" /iycq
xcopy "temp\win10\win32\lws_config.h" "install\websockets\include\win10\*" /iycq

call:DO_INSTALL win10 win32
call:DO_INSTALL win10 x64
call:DO_INSTALL win10 arm
call:DO_INSTALL wp_8.1 win32
call:DO_INSTALL wp_8.1 arm
call:DO_INSTALL winrt_8.1 win32
call:DO_INSTALL winrt_8.1 arm

call :DO_LOG "libwebsockets build complete."
endlocal
goto:eof

::--------------------------------------------------------
::-- error_exit
::		Note: Don't call anything that will change %ERRORLEVEL%
::--------------------------------------------------------
:error_exit
endlocal
exit \b %ERRORLEVEL%
goto:eof

::--------------------------------------------------------
::-- DO_LOG
::		%~1 message to log
::--------------------------------------------------------
:DO_LOG
	echo %~1
	echo %~1 >> %LOGFILE%
	goto:eof
	
::--------------------------------------------------------
::-- DO_INSTALL
::		%~1 Target (win10, wp8.1, winrt-8.1)
::		%~2 Platform (win32, x64, arm)
::--------------------------------------------------------
:DO_INSTALL
	setlocal
	set TARGET=%~1
	set PLATFORM=%~2
	set INDIR=temp\%TARGET%\%PLATFORM%\install
	set OUTDIR=install\websockets\prebuilt\%TARGET%\%PLATFORM%
	
	call :DO_LOG "Installing websockets %TARGET%/%PLATFORM%..."

	xcopy "%INDIR%\lib\websockets_static.lib" "%OUTDIR%\*" /iycq
	mv "%OUTDIR%\websockets_static.lib" "%OUTDIR%\libwebsockets.lib"
	endlocal
	goto:eof


::--------------------------------------------------------
::-- DO_BUILD
::		%~1 Target (win10, wp8.1, winrt-8.1)
::		%~2 Platform (win32, x64, arm)
::		%~3 Config (debug, release, MinSizeRel, etc.)
::--------------------------------------------------------
:DO_BUILD
	setlocal
	set TARGET=%~1
	set PLATFORM=%~2
	set CONFIG=%~3
	call :DO_LOG "Building libwebsockets %TARGET% %CONFIG%/%PLATFORM%..."
	msbuild %CD%\%TARGET%\%PLATFORM%\INSTALL.vcxproj /p:Configuration="%CONFIG%" /p:Platform="%PLATFORM%" /m
	if %ERRORLEVEL% NEQ 0 (
		call:DO_LOG "ERROR:DO_BUILD: msbuild %CD%\%TARGET%\%PLATFORM%\INSTALL.vcxproj /p:Configuration="%CONFIG%" /p:Platform="%PLATFORM%" /m"
		goto end_build
	)
:end_build		
	endlocal
	goto:eof
	
::--------------------------------------------------------
::-- DO_CMAKE
::		%~1 Target (win10, wp_8.1, winrt_8.1)
::--------------------------------------------------------
:DO_CMAKE
	setlocal
	set CMAKE_ARGS=-DLWS_WITHOUT_TEST_SERVER:BOOL="1" -DLWS_IPV6:BOOL="0" -DLWS_WITHOUT_TEST_SERVER_EXTPOLL:BOOL="1" -DLWS_WITHOUT_TEST_FRAGGLE:BOOL="1" -DLWS_WITH_SSL:BOOL="0" -DLWS_WITHOUT_TEST_CLIENT:BOOL="1" -DCMAKE_CONFIGURATION_TYPES:STRING="Debug;Release;MinSizeRel;RelWithDebInfo" -DLWS_WITHOUT_TEST_PING:BOOL="1" -DLWS_WITHOUT_TESTAPPS:BOOL="1" 
	set TARGET=%~1
	
	if %TARGET% == wp_8.1  (
		set CMAKE_PLATFORM=WindowsPhone
		set CMAKE_VERSION=8.1
	)
	if %TARGET% == winrt_8.1 (
		set CMAKE_PLATFORM=WindowsStore
		set CMAKE_VERSION=8.1	
	)
	if %TARGET% == win10 (
		set CMAKE_PLATFORM=WindowsStore
		set CMAKE_VERSION=10.0		
	)
	
	mkdir %TARGET%
	pushd %TARGET%
		mkdir win32
		pushd win32
			set INSTALL=%CD%\install
			cmake -G"Visual Studio 14 2015" -DCMAKE_SYSTEM_NAME=%CMAKE_PLATFORM% -DCMAKE_SYSTEM_VERSION=%CMAKE_VERSION% -DCMAKE_INSTALL_PREFIX:PATH=%INSTALL% %CMAKE_ARGS% %SRC%
			if %ERRORLEVEL% NEQ 0 (
				call:DO_LOG "ERROR:DO_CMAKE: %TARGET%/win32"
				goto end_cmake
			) 
		popd
		
		mkdir arm
		pushd arm
			set INSTALL=%CD%\install
			cmake -G"Visual Studio 14 2015 ARM" -DCMAKE_SYSTEM_NAME=%CMAKE_PLATFORM% -DCMAKE_SYSTEM_VERSION=%CMAKE_VERSION% -DCMAKE_INSTALL_PREFIX:PATH=%INSTALL% %CMAKE_ARGS% %SRC%
			if %ERRORLEVEL% NEQ 0 (
				call:DO_LOG "ERROR:DO_CMAKE: %TARGET%/arm"
				goto end_cmake
			) 
		popd
		
		if %TARGET% NEQ win10 (
			goto:end_cmake
		)
		
		mkdir x64
		pushd x64
			set INSTALL=%CD%\install
			cmake -G"Visual Studio 14 2015 Win64" -DCMAKE_SYSTEM_NAME=%CMAKE_PLATFORM% -DCMAKE_SYSTEM_VERSION=%CMAKE_VERSION% -DCMAKE_INSTALL_PREFIX:PATH=%INSTALL% %CMAKE_ARGS% %SRC%
			if %ERRORLEVEL% NEQ 0 (
				call:DO_LOG "ERROR:DO_CMAKE: %TARGET%/x64"
				goto end_cmake
			) 
		popd
		
:end_cmake
	popd  
	endlocal
	goto:eof


