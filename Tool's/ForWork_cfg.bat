@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Сравнение конфигов: Сделать vs Готовые

set "DONE_DIR=%~dp0Готовые"
set "TODO_DIR=%~dp0Сделать"
set "OUT_FILE=%~dp0config_diff.txt"

if not exist "%DONE_DIR%" (
    echo [ERROR] Папка "Готовые" не найдена рядом с батником.
    pause & exit /b 1
)
if not exist "%TODO_DIR%" (
    echo [ERROR] Папка "Сделать" не найдена рядом с батником.
    pause & exit /b 1
)

> "%OUT_FILE%" echo.

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_RESET=%ESC%[0m"

set /a CATS=0
set /a ONLY_TODO=0
set /a ONLY_DONE=0
set /a DIFF=0
set /a SAME=0

cls
echo.
echo %C_TITLE%  Сравнение конфигов...
echo %C_RESET%

(
    echo ╔══════════════════════════════════════════════════════════╗
    echo ║           DIFF КОНФИГОВ: Сделать  vs  Готовые            ║
    echo ╚══════════════════════════════════════════════════════════╝
) >> "%OUT_FILE%"

:: Собираем список категорий из обеих папок (уникальные)
set "CATS_LIST="
for /f "delims=" %%D in ('dir /b /ad /on "%TODO_DIR%" 2^>nul') do set "CATS_LIST=!CATS_LIST!%%D|"
for /f "delims=" %%D in ('dir /b /ad /on "%DONE_DIR%" 2^>nul') do (
    echo !CATS_LIST! | findstr /c:"%%D|" >nul || set "CATS_LIST=!CATS_LIST!%%D|"
)

:: Идём по категориям в алфавитном порядке через временный файл
> "%TEMP%\cats.tmp" (
    for %%C in ("!CATS_LIST:|=" "!") do (
        if not "%%~C"=="" echo %%~C
    )
)
sort "%TEMP%\cats.tmp" /o "%TEMP%\cats_sorted.tmp"

for /f "delims=" %%C in ('type "%TEMP%\cats_sorted.tmp"') do (
    call :diff_category "%%C"
)

:: Итог
(
    echo.
    echo ────────────────────────────────────────────────────────────
    echo  Категорий:              %CATS%
    echo  Только в Сделать:       %ONLY_TODO%
    echo  Только в Готовые:       %ONLY_DONE%
    echo  Отличаются:             %DIFF%
    echo  Идентичных:             %SAME%
    echo ────────────────────────────────────────────────────────────
) >> "%OUT_FILE%"

del "%TEMP%\cats.tmp" 2>nul
del "%TEMP%\cats_sorted.tmp" 2>nul

echo.
echo %C_TITLE%  Готово! Файл: %OUT_FILE%
echo %C_RESET%
echo.
pause
exit /b 0

:diff_category
set "CAT=%~1"
set /a CATS+=1

set "ONLY_T="
set "ONLY_D="
set "DIFF_L="

:: Собираем список всех файлов-конфигов в обеих папках (объединение)
set "FILES="
for %%E in (toml json json5 cfg txt) do (
    for /f "delims=" %%F in ('dir /b /a-d /on "%TODO_DIR%\%CAT%\*.%%E" 2^>nul') do (
        echo !FILES! | findstr /c:"%%F|" >nul || set "FILES=!FILES!%%F|"
    )
    for /f "delims=" %%F in ('dir /b /a-d /on "%DONE_DIR%\%CAT%\*.%%E" 2^>nul') do (
        echo !FILES! | findstr /c:"%%F|" >nul || set "FILES=!FILES!%%F|"
    )
)

:: Проходим по каждому файлу
for %%F in ("!FILES:|=" "!") do (
    if not "%%~F"=="" (
        set "FN=%%~F"
        set "IN_T="
        set "IN_D="
        if exist "%TODO_DIR%\%CAT%\!FN!" set "IN_T=1"
        if exist "%DONE_DIR%\%CAT%\!FN!" set "IN_D=1"

        if defined IN_T if not defined IN_D (
            set /a ONLY_TODO+=1
            set "ONLY_T=!ONLY_T!!FN!|"
        )
        if not defined IN_T if defined IN_D (
            set /a ONLY_DONE+=1
            set "ONLY_D=!ONLY_D!!FN!|"
        )
        if defined IN_T if defined IN_D (
            :: Сравниваем размер + дату
            for %%A in ("%TODO_DIR%\%CAT%\!FN!") do set "SZ_T=%%~zA" & set "DT_T=%%~tA"
            for %%A in ("%DONE_DIR%\%CAT%\!FN!") do set "SZ_D=%%~zA" & set "DT_D=%%~tA"
            if not "!SZ_T!"=="!SZ_D!" (
                set /a DIFF+=1
                set "DIFF_L=!DIFF_L!!FN! [!SZ_T! ^-^> !SZ_D! байт]|"
            ) else if not "!DT_T!"=="!DT_D!" (
                set /a DIFF+=1
                set "DIFF_L=!DIFF_L!!FN! [дата: !DT_T! ^-^> !DT_D!]|"
            ) else (
                set /a SAME+=1
            )
        )
    )
)

:: Если в категории ничего нет — пропускаем
set "HAS=0"
if defined ONLY_T set "HAS=1"
if defined ONLY_D set "HAS=1"
if defined DIFF_L set "HAS=1"
if "%HAS%"=="0" exit /b 0

(
    echo.
    echo ┌─ [!CAT!]
) >> "%OUT_FILE%"

if defined ONLY_T (
    >> "%OUT_FILE%" echo │
    >> "%OUT_FILE%" echo │  [ТОЛЬКО В СДЕЛАТЬ]
    for %%I in ("!ONLY_T:|=" "!") do (
        if not "%%~I"=="" >> "%OUT_FILE%" echo │    + %%~I
    )
)
if defined ONLY_D (
    >> "%OUT_FILE%" echo │
    >> "%OUT_FILE%" echo │  [ТОЛЬКО В ГОТОВЫЕ]
    for %%I in ("!ONLY_D:|=" "!") do (
        if not "%%~I"=="" >> "%OUT_FILE%" echo │    - %%~I
    )
)
if defined DIFF_L (
    >> "%OUT_FILE%" echo │
    >> "%OUT_FILE%" echo │  [ОТЛИЧАЮТСЯ]
    for %%I in ("!DIFF_L:|=" "!") do (
        if not "%%~I"=="" >> "%OUT_FILE%" echo │    ~ %%~I
    )
)

>> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
exit /b 0