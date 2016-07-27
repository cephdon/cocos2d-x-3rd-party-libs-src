@echo off
setlocal

set VERSION=3120200
set PHONE_URL=https://www.sqlite.org/2016/sqlite-wp81-winrt-%VERSION%.vsix
set WINRT_URL=https://www.sqlite.org/2016/sqlite-winrt81-%VERSION%.vsix
set WIN10_URL=https://www.sqlite.org/2016/sqlite-uwp-%VERSION%.vsix
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
	sha512sum --check ..\src\sqlite\winrt\SHA512SUMS.win10
	if %ERRORLEVEL% NEQ 0 (

		if exist sqlite-uwp-%VERSION%.vsix (
			rm sqlite-uwp-%VERSION%.vsix
		)
		
		call :DO_LOG "Downloading sqlite-uwp-%VERSION%.vsix..."
		curl -O -L %WIN10_URL%
	)	
	
	sha512sum --check ..\src\sqlite\winrt\SHA512SUMS.winrt_8.1
	if %ERRORLEVEL% NEQ 0 (

		if exist sqlite-winrt81-%VERSION%.vsix (
			rm sqlite-winrt81-%VERSION%.vsix
		)
		
		call :DO_LOG "Downloading sqlite-winrt81-%VERSION%.vsix..."
		curl -O -L %WINRT_URL%
	)
	
	sha512sum --check ..\src\sqlite\winrt\SHA512SUMS.wp_8.1
	if %ERRORLEVEL% NEQ 0 (

		if exist sqlite-wp81-winrt-%VERSION%.vsix (
			rm sqlite-wp81-winrt-%VERSION%.vsix
		)
		
		call :DO_LOG "Downloading sqlite-wp81-winrt-%VERSION%.vsix..."
		curl -O -L %PHONE_URL%
	)
popd


:: ---------------------------------------------------------------------------
:: Decompress code
:: ---------------------------------------------------------------------------

pushd temp
	call:DO_LOG "Decompressing sqlite packages..."
	unzip ../../../../tarballs/sqlite-winrt81-%VERSION%.vsix -d winrt_8.1
	unzip ../../../../tarballs/sqlite-wp81-winrt-%VERSION%.vsix	-d wp_8.1
	unzip ../../../../tarballs/sqlite-uwp-%VERSION%.vsix	-d win10
popd

call::DO_LOG "Installing sqlite..."

set INDIR=temp\wp_8.1\

set OUTDIR=install\sqlite3\libraries\wp_8.1\win32
xcopy "%INDIR%\DesignTime\Retail\x86\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\x86\sqlite3.dll" "%OUTDIR%\*" /iycq

set OUTDIR=install\sqlite3\libraries\wp_8.1\arm
xcopy "%INDIR%\DesignTime\Retail\ARM\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\ARM\sqlite3.dll" "%OUTDIR%\*" /iycq

set INDIR=temp\winrt_8.1\

set OUTDIR=install\sqlite3\libraries\winrt_8.1\win32
xcopy "%INDIR%\DesignTime\Retail\x86\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\x86\sqlite3.dll" "%OUTDIR%\*" /iycq

set OUTDIR=install\sqlite3\libraries\winrt_8.1\arm
xcopy "%INDIR%\DesignTime\Retail\ARM\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\ARM\sqlite3.dll" "%OUTDIR%\*" /iycq

set INDIR=temp\win10\

set OUTDIR=install\sqlite3\libraries\win10\win32
xcopy "%INDIR%\DesignTime\Retail\x86\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\x86\sqlite3.dll" "%OUTDIR%\*" /iycq

set OUTDIR=install\sqlite3\libraries\win10\x64
xcopy "%INDIR%\DesignTime\Retail\x64\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\x64\sqlite3.dll" "%OUTDIR%\*" /iycq

set OUTDIR=install\sqlite3\libraries\win10\arm
xcopy "%INDIR%\DesignTime\Retail\ARM\sqlite3.lib" "%OUTDIR%\*" /iycq
xcopy "%INDIR%\Redist\Retail\ARM\sqlite3.dll" "%OUTDIR%\*" /iycq

call::DO_LOG "sqlite build complete."

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



