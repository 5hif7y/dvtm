@echo off
setlocal
rem Build dvtm.exe with MSVC + CMake. Output: win32\build\bin\Release\
cd /d "%~dp0"

where cl >nul 2>nul && goto :env_ok
if defined DEVMODE (
    call "%DEVMODE%"
    goto :env_ok
)
rem Not inside an if ( ... ) block: the ")" of "%ProgramFiles(x86)%" would
rem close it; and for /f runs through "cmd /c", which strips quotes around a
rem path with ( ). Run vswhere.exe from its own directory instead.
set "VSWHERE_DIR=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
if not exist "%VSWHERE_DIR%\vswhere.exe" goto :env_ok
pushd "%VSWHERE_DIR%"
for /f "usebackq tokens=*" %%i in (`vswhere.exe -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
popd
if defined VSDIR if exist "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul
:env_ok

cmake -B build -S . -A x64 %*
if errorlevel 1 exit /b 1
cmake --build build --config Release --parallel
if errorlevel 1 exit /b 1
echo.
echo Binaries in win32\build\bin\Release\
