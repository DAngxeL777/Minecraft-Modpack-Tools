@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Генерация config_list.txt

set "DONE_DIR=%~dp0Готовые"
set "TODO_DIR=%~dp0Сделать"
set "OUT_FILE=%~dp0config_list.txt"

if not exist "%DONE_DIR%" (
    echo [ERROR] Папка "Готовые" не найдена рядом с батником.
    pause
    exit /b 1
)
if not exist "%TODO_DIR%" (
    echo [ERROR] Папка "Сделать" не найдена рядом с батником.
    pause
    exit /b 1
)

> "%OUT_FILE%" echo.

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_RESET=%ESC%[0m"

set /a TOTAL_DONE=0
set /a TOTAL_TODO=0
set /a CATS_DONE=0
set /a CATS_TODO=0

cls
echo.
echo %C_TITLE%  Генерация списка конфигов...
echo %C_RESET%

:: Шапка
(
    echo ╔══════════════════════════════════════════════════════════╗
    echo ║               СПИСОК КОНФИГОВ ПО КАТЕГОРИЯМ               ║
    echo ╚══════════════════════════════════════════════════════════╝
) >> "%OUT_FILE%"

:: ============ БЛОК "СДЕЛАТЬ" ============
(
    echo.
    echo ════════════════════════════════════════════════════════════
    echo   [ СДЕЛАТЬ ]
    echo ════════════════════════════════════════════════════════════
) >> "%OUT_FILE%"

for /f "delims=" %%D in ('dir /b /ad /on "%TODO_DIR%" 2^>nul') do (
    call :write_category "%TODO_DIR%" "%%D" "TODO"
)

:: ============ БЛОК "ГОТОВЫЕ" ============
(
    echo.
    echo.
    echo ════════════════════════════════════════════════════════════
    echo   [ ГОТОВЫЕ ]
    echo ════════════════════════════════════════════════════════════
) >> "%OUT_FILE%"

for /f "delims=" %%D in ('dir /b /ad /on "%DONE_DIR%" 2^>nul') do (
    call :write_category "%DONE_DIR%" "%%D" "DONE"
)

:: Итог
(
    echo.
    echo ────────────────────────────────────────────────────────────
    echo  СДЕЛАТЬ: категорий %CATS_TODO%  ^|  конфигов %TOTAL_TODO%
    echo  ГОТОВЫЕ: категорий %CATS_DONE%  ^|  конфигов %TOTAL_DONE%
    echo ────────────────────────────────────────────────────────────
) >> "%OUT_FILE%"

echo.
echo %C_TITLE%  Готово! Файл: %OUT_FILE%
echo %C_RESET%
echo.
pause
exit /b 0

:write_category
set "BASE=%~1"
set "CATNAME=%~2"
set "MODE=%~3"
set "COUNT=0"
set "LIST="

for /f "delims=" %%F in ('dir /b /a-d /on "%BASE%\%CATNAME%\*.toml" 2^>nul') do (
    set /a COUNT+=1
    set "LIST=!LIST!%%F|"
)
for /f "delims=" %%F in ('dir /b /a-d /on "%BASE%\%CATNAME%\*.json" 2^>nul') do (
    set /a COUNT+=1
    set "LIST=!LIST!%%F|"
)
for /f "delims=" %%F in ('dir /b /a-d /on "%BASE%\%CATNAME%\*.json5" 2^>nul') do (
    set /a COUNT+=1
    set "LIST=!LIST!%%F|"
)
for /f "delims=" %%F in ('dir /b /a-d /on "%BASE%\%CATNAME%\*.cfg" 2^>nul') do (
    set /a COUNT+=1
    set "LIST=!LIST!%%F|"
)
for /f "delims=" %%F in ('dir /b /a-d /on "%BASE%\%CATNAME%\*.txt" 2^>nul') do (
    set /a COUNT+=1
    set "LIST=!LIST!%%F|"
)

:: Пустую категорию не выводим
if %COUNT%==0 exit /b 0

if "%MODE%"=="TODO" set /a CATS_TODO+=1
if "%MODE%"=="DONE" set /a CATS_DONE+=1

(
    echo.
    echo ┌─ [!CATNAME!]  ^(!COUNT! шт.^)
    echo │
) >> "%OUT_FILE%"

for %%I in ("!LIST:|=" "!") do (
    if not "%%~I"=="" (
        if "%MODE%"=="TODO" set /a TOTAL_TODO+=1
        if "%MODE%"=="DONE" set /a TOTAL_DONE+=1
        >> "%OUT_FILE%" echo │   • %%~I
    )
)

>> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
exit /b 0