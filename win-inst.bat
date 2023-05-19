@echo off

goto main

:exit
echo exiting...
pause
exit

:main
net session >nul 2>&1
if not %errorLevel% == 0 (
	echo requires elevated privileges
	pause
	exit
)

setlocal EnableDelayedExpansion
if "%~1" == "" (
	echo Folder: 
	set /p folder=
) else (
	set folder=%~1
)
echo installing %folder%


rem check if 7-Zip exists and find path
set "key=HKEY_CURRENT_USER\Software\7-Zip"
set "valueName=Path"
for /f "tokens=2*" %%A in ('reg query "%key%" /v "%valueName%" ^| findstr /i "%valueName%"') do (
    set "p7z=%%B"
)

if defined p7z ( rem 7-Zip is faster than Expand-Archive
	echo found 7-Zip at %p7z%
	"%p7z%\7z.exe" x -bso0 -o"java-inst-tmp0" %folder%
) else (
	echo extracting with powershell...
	powershell -c Expand-Archive %folder%
)

if not %errorLevel% == 0 goto exit

powershell -c ls java-inst-tmp0 -Name > java-inst-tmp1

if not %errorLevel% == 0 goto exit

set /p outfolder= < java-inst-tmp1
echo outfolder: %outfolder%
del java-inst-tmp1

set home=C:\Program Files\Java\%outfolder%
set bin=%home%\bin

echo moving to %home%...
move java-inst-tmp0\%outfolder% "%home%" > nul
setx /m JAVA_HOME "%home%" > nul
rd /s /q java-inst-tmp0

if not %errorLevel% == 0 goto exit

echo updating environment...
powershell -c "$oldpath = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $bin = '%bin%'; [Environment]::SetEnvironmentVariable('Path', $bin + ';' + $oldpath, 'Machine')"

if not %errorLevel% == 0 goto exit

echo generating jarfile(.jar) support...
assoc .jar=jarfile > nul
ftype jarfile=%bin%\javaw.exe -jar %1 %* > nul

echo:
echo done
pause > nul