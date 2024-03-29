@echo off

goto main

:exit
echo exiting...
pause
exit

:main
net session >nul 2>&1
if not %errorLevel% == 0 (
	echo Please run as Administrator
	pause
	exit
)

mkdir "C:\Program Files\Java" >nul 2>&1
cd "C:\Program Files\Java"

setlocal EnableDelayedExpansion
if "%~1" == "" (
	echo Zip Folder:
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
	powershell -c Expand-Archive %folder% -DestinationPath java-inst-tmp0
)

echo [extract] ok
if not %errorLevel% == 0 goto exit

powershell -c ls java-inst-tmp0 -Name > java-inst-tmp1

echo [name] ok
if not %errorLevel% == 0 goto exit

set /p outfolder= < java-inst-tmp1
rem echo outfolder: %outfolder%
del java-inst-tmp1

set home=C:\Program Files\Java\%outfolder%
set bin=%home%\bin

echo moving to %home%...
move java-inst-tmp0\%outfolder% "%home%" > nul
setx /m JAVA_HOME "%home%" > nul
rd /s /q java-inst-tmp0

echo [home] ok
if not %errorLevel% == 0 goto exit

echo updating environment... (%bin%)

powershell -c "$oldpath = [Environment]::GetEnvironmentVariable('Path', 'Machine');($oldpath.split(';') | findstr /I 'jdk jre') + ';'| foreach-object {if ( $_ -ne ';') {echo ('removing ' + $_ + ' from PATH');$oldpath = $oldpath.Replace($_, '')}};$bin = '%bin%';[Environment]::SetEnvironmentVariable('Path', $bin + ';' + $oldpath, 'Machine');"

echo [path] ok
if not %errorLevel% == 0 goto exit

echo generating jarfile(.jar) support...
echo this will make changes in the registry! (enter to continue; Ctrl-C to quit)
pause > nul
assoc .jar=jarfile > nul
ftype jarfile=%bin%\javaw.exe -jar %%1 %%* > nul
reg add "HKCR\.jar\OpenWithProgids" /v jarfile /f

echo:
echo done
pause > nul

