@echo off

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
	echo extracting with 7zip...
	"%p7z%\7z.exe" x %folder% -o"java-inst-tmp0"
) else (
	echo extracting with powershell...
	powershell -c Expand-Archive %folder%
)

powershell -c ls java-inst-tmp0 -Name > java-inst-tmp1
set /p outfolder= < java-inst-tmp1
echo outfolder: %outfolder%
del java-inst-tmp1

set home=C:\Program Files\Java\%outfolder%
set bin=%home%\bin

echo moving to %home%...
move java-inst-tmp0\%outfolder% %home%
setx JAVA_HOME "%home%"
rd /s /q java-inst-tmp0

echo updating environment...
powershell -c "$oldpath = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $bin = '%bin%'; [Environment]::SetEnvironmentVariable('Path', $bin + ';' + $oldpath, 'Machine')"

echo generating jarfile(.jar) support...
assoc .jar=jarfile
ftype jarfile=%bin%\javaw.exe -jar %1 %*

echo done
pause > nul