@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Очистка временных файлов

set "ROOT=%~dp0"

:: ANSI-цвета
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_OK=%ESC%[92m"
set "C_WARN=%ESC%[91m"
set "C_DIM=%ESC%[90m"
set "C_RESET=%ESC%[0m"

cls
echo.
echo %C_TITLE%  ╔══════════════════════════════════════════════════════════╗
echo %C_TITLE%  ║                    ОЧИСТКА ПАПОК                         ║
echo %C_TITLE%  ╚══════════════════════════════════════════════════════════╝
echo %C_RESET%
echo.
echo   Будут очищены:
echo     %C_DIM%•%C_RESET% logs\
echo     %C_DIM%•%C_RESET% crash-reports\
echo     %C_DIM%•%C_RESET% .mixin.out\
echo     %C_DIM%•%C_RESET% config\*.bak, *.tmp
echo     %C_DIM%•%C_RESET% *.log в корне и подпапках
echo.

set /p "CONFIRM=  Продолжить? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo.
    echo %C_WARN%  Отменено.%C_RESET%
    echo.
    pause
    exit /b 0
)

set /a DELETED=0
set /a DIRS=0

:: ---- logs ----
call :clean_dir "%ROOT%logs" "logs"
:: ---- crash-reports ----
call :clean_dir "%ROOT%crash-reports" "crash-reports"
:: ---- .mixin.out ----
call :clean_dir "%ROOT%.mixin.out" ".mixin.out"
:: ---- local ----
call :clean_dir "%ROOT%local" "local"

:: ---- config *.bak / *.tmp (рекурсивно) ----
call :clean_files "%ROOT%config" "*.bak" "config\*.bak"
call :clean_files "%ROOT%config" "*.tmp" "config\*.tmp"

:: ---- config внутри Сделать и Готовые ----
call :clean_files "%ROOT%Сделать" "*.bak" "Сделать\*\*.bak"
call :clean_files "%ROOT%Сделать" "*.tmp" "Сделать\*\*.tmp"
call :clean_files "%ROOT%Готовые"  "*.bak" "Готовые\*\*.bak"
call :clean_files "%ROOT%Готовые"  "*.tmp" "Готовые\*\*.tmp"

:: ---- *.log в корне ----
call :clean_files "%ROOT%" "*.log" "*.log"

echo.
echo %C_TITLE%  ────────────────────────────────────────────────────────────
echo %C_TITLE%   Удалено файлов: %DELETED%
echo %C_TITLE%  ────────────────────────────────────────────────────────────
echo %C_RESET%
echo.
pause
exit /b 0

:: ============================================================
:: :clean_dir  <путь>  <отображаемое имя>
:: Полностью чистит содержимое папки (саму папку оставляет)
:: ============================================================
:clean_dir
set "P=%~1"
set "NAME=%~2"
if not exist "%P%" (
    echo %C_DIM%  [--] %NAME% ^(нет папки^)%C_RESET%
    exit /b 0
)
set /a CNT=0
for /f "delims=" %%F in ('dir /b /a-d "%P%" 2^>nul') do (
    del /f /q "%P%\%%F" >nul 2>&1
    if not exist "%P%\%%F" set /a CNT+=1
)
for /f "delims=" %%D in ('dir /b /ad "%P%" 2^>nul') do (
    rd /s /q "%P%\%%D" >nul 2>&1
)
set /a DELETED+=CNT
set /a DIRS+=1
echo %C_OK%  [OK] %NAME%  ^(удалено: !CNT!^)%C_RESET%
exit /b 0

:: ============================================================
:: :clean_files  <базовая папка>  <маска>  <отображаемый путь>
:: Ищет файлы по маске рекурсивно и удаляет
:: ============================================================
:clean_files
set "BASE=%~1"
set "MASK=%~2"
set "LABEL=%~3"
if not exist "%BASE%" (
    echo %C_DIM%  [--] %LABEL% ^(нет папки^)%C_RESET%
    exit /b 0
)
set /a CNT=0
for /r "%BASE%" %%F in ("%MASK%") do (
    if exist "%%F" (
        del /f /q "%%F" >nul 2>&1
        if not exist "%%F" set /a CNT+=1
    )
)
set /a DELETED+=CNT
if !CNT! GTR 0 (
    echo %C_OK%  [OK] %LABEL%  ^(удалено: !CNT!^)%C_RESET%
) else (
    echo %C_DIM%  [--] %LABEL%  ^(нечего чистить^)%C_RESET%
)
exit /b 0