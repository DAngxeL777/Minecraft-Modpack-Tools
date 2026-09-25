@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Генерация mod_list.txt

set "MODS_DIR=%~dp0mods"
set "OUT_FILE=%~dp0mod_list.txt"

if not exist "%MODS_DIR%" (
    echo [ERROR] Папка "mods" не найдена рядом с батником.
    pause
    exit /b 1
)

:: Очистка / создание файла
> "%OUT_FILE%" echo.

:: ANSI-цвета (Win10+)
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_CAT=%ESC%[96m"
set "C_MOD=%ESC%[97m"
set "C_NUM=%ESC%[90m"
set "C_RESET=%ESC%[0m"

set /a TOTAL=0
set /a CATS=0

cls
echo.
echo %C_TITLE%  Генерация списка модов... 
echo %C_RESET%

:: Шапка в файл
(
    echo ╔══════════════════════════════════════════════════════════╗
    echo ║              СПИСОК МОДОВ ПО КАТЕГОРИЯМ                  ║
    echo ╚══════════════════════════════════════════════════════════╝
    echo.
) >> "%OUT_FILE%"

for /f "delims=" %%D in ('dir /b /ad /on "%MODS_DIR%" 2^>nul') do (
    set /a CATS+=1
    call :write_category "%%D"
)

:: Итог
(
    echo.
    echo ────────────────────────────────────────────────────────────
    echo  Категорий: %CATS%   ^|   Всего модов: %TOTAL%
    echo ────────────────────────────────────────────────────────────
) >> "%OUT_FILE%"

echo.
echo %C_TITLE%  Готово! Файл: %OUT_FILE%
echo %C_RESET%
echo.
pause
exit /b 0

:write_category
set "CATNAME=%~1"
set "COUNT=0"
set "LIST="

for /f "delims=" %%F in ('dir /b /a-d /on "%MODS_DIR%\%CATNAME%\*.jar" 2^>nul') do (
    set /a COUNT+=1
    set "LIST=!LIST!%%F|"
)

(
    echo.
    echo ┌─ [!CATNAME!]  ^(!COUNT! шт.^)
    echo │
) >> "%OUT_FILE%"

for %%I in ("!LIST:|=" "!") do (
    if not "%%~I"=="" (
        set /a TOTAL+=1
        >> "%OUT_FILE%" echo │   • %%~I
    )
)

>> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
exit /b 0