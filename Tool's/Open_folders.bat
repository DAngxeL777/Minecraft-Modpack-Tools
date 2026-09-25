@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Открытие папок разработки

set "CFG=%~dp0open_folders.cfg"

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_OK=%ESC%[92m"
set "C_WARN=%ESC%[91m"
set "C_DIM=%ESC%[90m"
set "C_RESET=%ESC%[0m"

cls
echo.
echo %C_TITLE%  ╔══════════════════════════════════════════════════════════╗
echo %C_TITLE%  ║                ОТКРЫТИЕ ПАПОК РАЗРАБОТКИ                 ║
echo %C_TITLE%  ╚══════════════════════════════════════════════════════════╝
echo %C_RESET%
echo.

:: ==========================================================
:: 1) Корень разработки (где лежат mods и config)
:: ==========================================================
set "ROOT="

if exist "%CFG%" (
    for /f "usebackq delims=" %%L in ("%CFG%") do (
        if not defined ROOT set "ROOT=%%L"
    )
)

if defined ROOT if not exist "!ROOT!" (
    echo %C_WARN%  Сохранённый путь не найден: !ROOT!%C_RESET%
    set "ROOT="
)

if not defined ROOT (
    echo   Введите путь к корню разработки ^(где лежат mods и config^):
    echo   %C_DIM%  Пример: D:\Minecraft\MyModpack%C_RESET%
    echo.
    set /p "ROOT=  Путь: "
    set "ROOT=!ROOT:"=!"
    if "!ROOT:~-1!"=="\" set "ROOT=!ROOT:~0,-1!"

    if not exist "!ROOT!" (
        echo.
        echo %C_WARN%  Путь не существует. Выход.%C_RESET%
        echo.
        pause
        exit /b 1
    )

    > "%CFG%" echo !ROOT!
    echo.
    echo %C_OK%  Путь сохранён в: %CFG%%C_RESET%
    echo.
)

echo %C_DIM%  Корень разработки: %ROOT%%C_RESET%
echo.

:: ==========================================================
:: 2) Открываем mods и config
:: ==========================================================
set "OPENED=0"

if exist "%ROOT%\mods" (
    start "" "%ROOT%\mods"
    echo %C_OK%  [OK] mods%C_RESET%
    set /a OPENED+=1
) else (
    echo %C_WARN%  [!!] mods не найдена%C_RESET%
)

if exist "%ROOT%\config" (
    start "" "%ROOT%\config"
    echo %C_OK%  [OK] config%C_RESET%
    set /a OPENED+=1
) else (
    echo %C_WARN%  [!!] config не найдена%C_RESET%
)

echo.
if %OPENED%==0 (
    echo %C_WARN%  Ничего не открыто.%C_RESET%
    echo.
    pause
    exit /b 1
)

echo %C_TITLE%  Готово.%C_RESET%

:: Закрываемся без паузы
exit /b 0