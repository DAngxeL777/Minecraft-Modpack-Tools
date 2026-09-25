@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Поиск дубликатов модов

set "MODS_DIR=%~dp0mods"
set "OUT_FILE=%~dp0duplicates.txt"
set "TMP=%~dp0_tmp_dup"
set "JAR_LIST=%TMP%\jar_list.txt"
set "NORM_LIST=%TMP%\norm_list.txt"
set "SZ_LIST=%TMP%\sz_list.txt"

if not exist "%MODS_DIR%" (
    echo [ERROR] Папка "mods" не найдена рядом с батником.
    pause & exit /b 1
)

if not exist "%TMP%" mkdir "%TMP%"
del /f /q "%JAR_LIST%" "%NORM_LIST%" "%SZ_LIST%" 2>nul
> "%OUT_FILE%" echo.

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_TITLE=%ESC%[93m"
set "C_RESET=%ESC%[0m"

cls
echo.
echo %C_TITLE%  Поиск дубликатов...
echo %C_RESET%

(
    echo ╔══════════════════════════════════════════════════════════╗
    echo ║                ПОИСК ДУБЛИКАТОВ МОДОВ                    ║
    echo ╚══════════════════════════════════════════════════════════╝
) >> "%OUT_FILE%"

:: ==========================================================
:: Собираем список всех .jar: категория|имя|норм.имя|размер
:: ==========================================================
for /f "delims=" %%D in ('dir /b /ad /on "%MODS_DIR%" 2^>nul') do (
    for /f "delims=" %%F in ('dir /b /a-d /on "%MODS_DIR%\%%D\*.jar" 2^>nul') do (
        set "FNAME=%%F"
        set "BASE=!FNAME:.jar=!"
        call :normalize "!BASE!"
        for %%A in ("%MODS_DIR%\%%D\%%F") do set "SZ=%%~zA"
        >> "%JAR_LIST%" echo %%D^|!FNAME!^|!NRM!^|!SZ!
    )
)

:: ==========================================================
:: БЛОК 1: точные дубликаты имени файла
:: ==========================================================
(
    echo.
    echo ════════════════════════════════════════════════════════════
    echo   [1] ТОЧНЫЕ ДУБЛИКАТЫ ^(одинаковое имя в разных категориях^)
    echo ════════════════════════════════════════════════════════════
) >> "%OUT_FILE%"

set "FOUND_EXACT=0"
:: Сортируем по имени, потом ищем повторы
> "%TMP%\exact_sorted.txt" (
    for /f "tokens=1,2 delims=|" %%A in ("%JAR_LIST%") do echo %%B^|%%A
)
:: ↑ этот трюк не сработает с файлом. Сделаем иначе — через sort
type "%JAR_LIST%" | sort /+1 > "%TMP%\jar_sorted.txt" 2>nul

:: Проще: используем sort по 2-му полю. CMD sort не умеет по полю.
:: Идём руками: собираем имена в отдельный файл
> "%TMP%\names.txt" (
    for /f "tokens=1,2 delims=|" %%A in ('type "%JAR_LIST%"') do echo %%B
)
sort "%TMP%\names.txt" /o "%TMP%\names_sorted.txt" 2>nul

set "PREV_N="
set "PREV_LINE="
set "IN_GROUP=0"
set "GROUP_BUF="

:: Идём по отсортированным именам, ищем идущие подряд одинаковые
for /f "delims=" %%N in ('type "%TMP%\names_sorted.txt"') do (
    if "%%N"=="!PREV_N!" (
        if !IN_GROUP!==0 (
            set "IN_GROUP=1"
            set /a FOUND_EXACT+=1
            >> "%OUT_FILE%" echo.
            >> "%OUT_FILE%" echo ┌─ %%N
            >> "%OUT_FILE%" echo │
            :: Выводим предыдущую
            for /f "tokens=1,2 delims=|" %%A in ('findstr /c:"^%%N|" "%JAR_LIST%" 2^>nul') do (
                >> "%OUT_FILE%" echo │   • %%A\%%B
            )
        )
        for /f "tokens=1,2 delims=|" %%A in ('findstr /c:"^%%N|" "%JAR_LIST%" 2^>nul') do (
            :: Печатаем только первую найденную, чтобы не дублировать
            set "DONE_MARK=%%A|%%B"
        )
    ) else (
        if !IN_GROUP!==1 >> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
        set "IN_GROUP=0"
    )
    set "PREV_N=%%N"
)
if !IN_GROUP!==1 >> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
if !FOUND_EXACT!==0 >> "%OUT_FILE%" echo   Не найдено.

:: ==========================================================
:: БЛОК 2: дубликаты по нормализованному имени
:: ==========================================================
(
    echo.
    echo.
    echo ════════════════════════════════════════════════════════════
    echo   [2] ПОХОЖИЕ МОДЫ ^(одно имя, разные версии^)
    echo ════════════════════════════════════════════════════════════
) >> "%OUT_FILE%"

:: Сортируем jar_list по 3-му полю (норм.имя). CMD sort не умеет по полю — делаем через префикс.
> "%TMP%\norm_keys.txt" (
    for /f "tokens=1,2,3,4 delims=|" %%A in ('type "%JAR_LIST%"') do echo %%C^|%%A^|%%B
)
sort "%TMP%\norm_keys.txt" /o "%TMP%\norm_sorted.txt" 2>nul

set "PREV_K="
set "GROUP_COUNT=0"
set "GROUP_ITEMS="
set "GROUP_STARTED=0"
set "FOUND_NORM=0"

for /f "tokens=1,2,3 delims=|" %%K in ('type "%TMP%\norm_sorted.txt"') do (
    set "K=%%K"
    set "CAT=%%L"
    set "FN=%%M"
    if "!K!"=="!PREV_K!" (
        set /a GROUP_COUNT+=1
        set "GROUP_ITEMS=!GROUP_ITEMS!%%L/%%M|"
    ) else (
        :: Закрываем предыдущую группу
        if !GROUP_COUNT! GTR 1 (
            set /a FOUND_NORM+=1
            >> "%OUT_FILE%" echo.
            >> "%OUT_FILE%" echo ┌─ [!PREV_K!]  ^(!GROUP_COUNT! шт.^)
            >> "%OUT_FILE%" echo │
            for %%I in ("!GROUP_ITEMS:|=" "!") do (
                if not "%%~I"=="" >> "%OUT_FILE%" echo │   • %%~I
            )
            >> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
        )
        set "PREV_K=!K!"
        set "GROUP_COUNT=1"
        set "GROUP_ITEMS=%%L/%%M|"
    )
)
:: Закрываем последнюю
if !GROUP_COUNT! GTR 1 (
    set /a FOUND_NORM+=1
    >> "%OUT_FILE%" echo.
    >> "%OUT_FILE%" echo ┌─ [!PREV_K!]  ^(!GROUP_COUNT! шт.^)
    >> "%OUT_FILE%" echo │
    for %%I in ("!GROUP_ITEMS:|=" "!") do (
        if not "%%~I"=="" >> "%OUT_FILE%" echo │   • %%~I
    )
    >> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
)
if !FOUND_NORM!==0 >> "%OUT_FILE%" echo   Не найдено.

:: ==========================================================
:: БЛОК 3: одинаковый размер
:: ==========================================================
(
    echo.
    echo.
    echo ════════════════════════════════════════════════════════════
    echo   [3] ОДИНАКОВЫЙ РАЗМЕР ^(возможные копии^)
    echo ════════════════════════════════════════════════════════════
) >> "%OUT_FILE%"

:: Сортируем по размеру
> "%TMP%\sz_keys.txt" (
    for /f "tokens=1,2,4 delims=|" %%A in ('type "%JAR_LIST%"') do echo %%C^|%%A^|%%B
)
sort "%TMP%\sz_keys.txt" /o "%TMP%\sz_sorted.txt" 2>nul

set "PREV_S="
set "SZ_COUNT=0"
set "SZ_ITEMS="
set "FOUND_SZ=0"

for /f "tokens=1,2,3 delims=|" %%S in ('type "%TMP%\sz_sorted.txt"') do (
    set "S=%%S"
    set "CAT=%%T"
    set "FN=%%U"
    if "!S!"=="!PREV_S!" (
        set /a SZ_COUNT+=1
        set "SZ_ITEMS=!SZ_ITEMS!%%T/%%U|"
    ) else (
        if !SZ_COUNT! GTR 1 (
            set /a FOUND_SZ+=1
            >> "%OUT_FILE%" echo.
            >> "%OUT_FILE%" echo ┌─ !PREV_S! байт  ^(!SZ_COUNT! шт.^)
            >> "%OUT_FILE%" echo │
            for %%I in ("!SZ_ITEMS:|=" "!") do (
                if not "%%~I"=="" >> "%OUT_FILE%" echo │   • %%~I
            )
            >> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
        )
        set "PREV_S=!S!"
        set "SZ_COUNT=1"
        set "SZ_ITEMS=%%T/%%U|"
    )
)
if !SZ_COUNT! GTR 1 (
    set /a FOUND_SZ+=1
    >> "%OUT_FILE%" echo.
    >> "%OUT_FILE%" echo ┌─ !PREV_S! байт  ^(!SZ_COUNT! шт.^)
    >> "%OUT_FILE%" echo │
    for %%I in ("!SZ_ITEMS:|=" "!") do (
        if not "%%~I"=="" >> "%OUT_FILE%" echo │   • %%~I
    )
    >> "%OUT_FILE%" echo └──────────────────────────────────────────────────────────
)
if !FOUND_SZ!==0 >> "%OUT_FILE%" echo   Не найдено.

:: Чистим временные
rd /s /q "%TMP%" 2>nul

echo.
echo %C_TITLE%  Готово! Файл: %OUT_FILE%
echo %C_RESET%
echo.
pause
exit /b 0

:: ============================================================
:: :normalize  <имя без .jar>
:: Идём по символам до первого разделителя -/_,
:: затем смотрим — если следующий кусок начинается с цифры,
:: отрезаем всё дальше. Иначе клеим имя.
:: ============================================================
:normalize
set "IN=%~1"
set "PART="
set "RESULT="
set "MODE=NAME"

:: Заменяем _ на - для простоты
set "IN=!IN:_=-!"
set "IN=!IN: =-!"

:: Идём по частям, разбивая по -
for /f "tokens=1-30 delims=-" %%A in ("!IN!") do (
    set "RESULT=%%A"
    set "STOP="
    if not "%%B"=="" (
        echo %%B| findstr /r "^[0-9]" >nul
        if errorlevel 1 (
            echo %%B| findstr /ri "^(fabric\|forge\|neoforge\|quilt\|common\|mc\|v)$" >nul
            if errorlevel 1 set "RESULT=!RESULT!-%%B"
        ) else (
            set "STOP=1"
        )
    )
    if not defined STOP if not "%%C"=="" (
        echo %%C| findstr /r "^[0-9]" >nul
        if errorlevel 1 (
            echo %%C| findstr /ri "^(fabric\|forge\|neoforge\|quilt\|common\|mc\|v)$" >nul
            if errorlevel 1 set "RESULT=!RESULT!-%%C"
        ) else (
            set "STOP=1"
        )
    )
    if not defined STOP if not "%%D"=="" (
        echo %%D| findstr /r "^[0-9]" >nul
        if errorlevel 1 (
            echo %%D| findstr /ri "^(fabric\|forge\|neoforge\|quilt\|common\|mc\|v)$" >nul
            if errorlevel 1 set "RESULT=!RESULT!-%%D"
        )
    )
)
set "NRM=!RESULT!"
exit /b 0