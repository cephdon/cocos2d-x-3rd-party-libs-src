@echo off
setlocal

set VERSION=2.1.8
set URL=http://api.nuget.org/packages/angle.windowsstore.%VERSION%.nupkg
set STARTDIR=%cd%
set LOGFILE=%~dp0\build.log

:: ---------------------------------------------------------------------------
:: Clean previous build
:: ---------------------------------------------------------------------------

if exist %LOGFILE% (
	rm -f %LOGFILE%
)
	
if exist temp (
	rm -rf temp
)

if exist install (
	rm -rf install
)

mkdir temp
mkdir install

:: ---------------------------------------------------------------------------
:: Download code if necessary
:: ---------------------------------------------------------------------------

pushd ..\..\..\tarballs
	sha512sum --check ..\src\angle\winrt\SHA512SUMS

	if %ERRORLEVEL% NEQ 0 (

		if exist angle.windowsstore.%VERSION%.nupkg (
			rm angle.windowsstore.%VERSION%.nupkg
		)
		
		call :DO_LOG "Downloading angle.windowsstore.%VERSION%.nupkg..."
		curl -O -L %URL%
	)	
popd

:: ---------------------------------------------------------------------------
:: Decompress code
:: ---------------------------------------------------------------------------

pushd temp
	call:DO_LOG "Decompressing angle.windowsstore.%VERSION%.nupkg..."
	unzip ../../../../tarballs/angle.windowsstore.%VERSION%.nupkg -d angle
popd

:: ---------------------------------------------------------------------------
:: Install Windows 10.0 and 8.1 libs in cocos2d-x v3 folder format
:: ---------------------------------------------------------------------------

call:DO_LOG "Installing ANGLE..."

set INDIR=temp\angle\

set OUTDIR=install\win10-specific\angle\include
xcopy "%INDIR%\Include" "%OUTDIR%" /iycqs
set OUTDIR=install\win10-specific\angle\prebuilt
xcopy "%INDIR%\bin\UAP\Win32" "%OUTDIR%\win32" /iycqs
xcopy "%INDIR%\bin\UAP\ARM" "%OUTDIR%\arm" /iycqs
xcopy "%INDIR%\bin\UAP\x64" "%OUTDIR%\x64" /iycqs

set OUTDIR=install\winrt_8.1-specific\angle\include
xcopy "%INDIR%\Include" "%OUTDIR%" /iycqs
set OUTDIR=install\winrt_8.1-specific\angle\prebuilt
xcopy "%INDIR%\bin\Windows\Win32" "%OUTDIR%\win32" /iycqs
xcopy "%INDIR%\bin\Windows\ARM" "%OUTDIR%\arm" /iycqs

set OUTDIR=install\wp_8.1-specific\angle\include
xcopy "%INDIR%\Include" "%OUTDIR%" /iycqs
set OUTDIR=install\wp_8.1-specific\angle\prebuilt
xcopy "%INDIR%\bin\Phone\Win32" "%OUTDIR%\win32" /iycqs
xcopy "%INDIR%\bin\Phone\ARM" "%OUTDIR%\arm" /iycqs

call:DO_LOG "ANGLE build complete."

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
	




