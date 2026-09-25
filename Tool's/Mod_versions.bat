@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Список версий модов

set "MODS_DIR=%~dp0mods"
set "OUT_FILE=%~dp0mod_versions.txt"

if not exist "%MODS_DIR%" (
    echo [ERROR] Папка "mods" не найдена рядом с батником.
    pause & exit /b 1
)

> "%OUT_FILE%" echo.

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_RESET=%ESC%[0m"

set /a TOTAL=0
set /a CATS=0

cls
echo.
echo %C_TITLE%  Сбор версий модов...
echo %C_RESET%

(
    echo ╔══════════════════════════════════════════════════════════╗
    echo ║                  ВЕРСИИ МОДОВ ПО КАТЕГОРИЯМ               ║
    echo ╚══════════════════════════════════════════════════════════╝
) >> "%OUT_FILE%"

for /f "delims=" %%D in ('dir /b /ad /on "%MODS_DIR%" 2^>nul') do (
    call :write_category "%%D"
)

(
    echo.
    echo ────────────────────────────────────────────────────────────
    echo  Категорий: %CATS%   ^|   Модов: %TOTAL%
    echo ────────────────────────────────────────────────────────────
) >> "%OUT_FILE%"

echo.
echo %C_TITLE%  Готово! Файл: %OUT_FILE%
echo %C_RESET%
echo.
pause
exit /b 0

:write_category
set "CAT=%~1"
set "COUNT=0"

:: Сначала проверим, есть ли вообще jar в категории
for /f "delims=" %%F in ('dir /b /a-d /on "%MODS_DIR%\%CAT%\*.jar" 2^>nul') do set "HAS=1"
if not defined HAS exit /b 0
set "HAS="

set /a CATS+=1

(
    echo.
    echo ┌─ [!CAT!]
    echo │
) >> "%OUT_FILE%"

:: Сортируем по имени, выводим таблицей
for /f "delims=" %%F in ('dir /b /a-d /on "%MODS_DIR%\%CAT%\*.jar" 2^>nul') do (
    set "FNAME=%%F"
    set "BASE=!FNAME:.jar=!"
    call :parse "!BASE!"
    set /a COUNT+=1
    set /a TOTAL+=1

    :: Форматируем: мод (30 символов) | версия (15) | файл
    set "MOD_PAD=!MOD!                         "
    set "MOD_PAD=!MOD_PAD:~0,24!"
    set "VER_PAD=!VER!               "
    set "VER_PAD=!VER_PAD:~0,14!"

    >> "%OUT_FILE%" echo │   !MOD_PAD! !VER_PAD! !FNAME!
)

(
    echo │
    echo └─ Всего: !COUNT! шт.
    echo ───────────────────────────────────────────────────────────
) >> "%OUT_FILE%"
exit /b 0

:: ============================================================
:: :parse <имя без .jar>
:: Заполняет MOD (имя мода) и VER (версия)
:: ============================================================
:parse
set "IN=%~1"
set "IN=!IN:_=-!"
set "IN=!IN: =-!"

set "MOD="
set "VER="
set "FOUND_VER="

:: Разбиваем по - и идём по токенам
set "TOK_IDX=0"
for /f "tokens=1-30 delims=-" %%A in ("!IN!") do (
    call :handle_token "%%A"
    if not "%%B"=="" call :handle_token "%%B"
    if not "%%C"=="" call :handle_token "%%C"
    if not "%%D"=="" call :handle_token "%%D"
    if not "%%E"=="" call :handle_token "%%E"
    if not "%%F"=="" call :handle_token "%%F"
    if not "%%G"=="" call :handle_token "%%G"
    if not "%%H"=="" call :handle_token "%%H"
    if not "%%I"=="" call :handle_token "%%I"
    if not "%%J"=="" call :handle_token "%%J"
)

if not defined VER set "VER=?"
if not defined MOD set "MOD=!IN!"
exit /b 0

:handle_token
set "T=%~1"
if "!T!"=="" exit /b 0

:: Если уже нашли версию — дальше игнорим
if defined FOUND_VER (
    :: Но если версия однобуквенная (a/b/c/f/g) и следом идёт что-то — приклеим
    exit /b 0
)

:: Проверяем — токен начинается с цифры? Тогда это версия
echo !T!| findstr /r "^[0-9]" >nul
if not errorlevel 1 (
    set "VER=!T!"
    set "FOUND_VER=1"
    exit /b 0
)

:: Загрузчики и MC-метки — игнорим при формировании имени мода
echo !T!| findstr /ri "^(fabric\|forge\|neoforge\|quilt\|common\|mc\|v)$" >nul
if not errorlevel 1 (
    :: если это mc1.20.1 — тоже версия
    echo !T!| findstr /ri "^mc[0-9]" >nul
    if not errorlevel 1 (
        set "VER=!T!"
        set "FOUND_VER=1"
    )
    exit /b 0
)

:: Обычный токен — приклеиваем к имени мода
if not defined MOD (
    set "MOD=!T!"
) else (
    set "MOD=!MOD!-!T!"
)
exit /b 0