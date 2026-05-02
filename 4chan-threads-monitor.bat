@echo off
setlocal EnableDelayedExpansion
title 4chan Thread Monitor v2.0

rem ===============================================================================
rem  FILE CONFIGURATION
rem ===============================================================================
set LIST=threads_4chan.txt
set LOG=log_4chan.txt
set NEW_BOX=new_4chan.txt
set PRIORITY_BOX=priority_4chan.txt
set PAUSE_FILE=pause_4chan.txt
set STATS_FILE=stats_4chan.txt
set FAIL_LOG=failures_4chan.txt
set MAX_RETRIES=3
set DRY_RUN=0

rem ===============================================================================
rem  PARSE COMMAND LINE FLAGS
rem ===============================================================================
:parse_args
if "%~1"=="--dry-run" ( set DRY_RUN=1 & shift & goto parse_args )
if "%~1"=="--help" goto show_help
if not "%~1"=="" ( shift & goto parse_args )

rem ===============================================================================
rem  STARTUP BANNER
rem ===============================================================================
cls
powershell -Command "Write-Host '===============================================================================' -ForegroundColor Cyan; Write-Host '             4CHAN THREAD MONITOR v2.0' -ForegroundColor Cyan; Write-Host '===============================================================================' -ForegroundColor Cyan"
echo.
if "!DRY_RUN!"=="1" (
    powershell -Command "Write-Host '  [DRY-RUN MODE] No files will be downloaded.' -ForegroundColor Yellow"
    echo.
)

rem ===============================================================================
rem  GALLERY-DL VERSION CHECK + UPDATE CHECK
rem  FIX: Uses -EncodedCommand (base64 UTF-16LE) — avoids all paren/quote issues
rem  FIX: Strip "gallery-dl " prefix from version string before comparing to PyPI
rem ===============================================================================
powershell -Command "Write-Host '[STARTUP] Checking gallery-dl...' -ForegroundColor White"
for /f "tokens=*" %%V in ('gallery-dl --version 2^>nul') do set GDL_INSTALLED=%%V
if "!GDL_INSTALLED!"=="" (
    powershell -Command "Write-Host '[FATAL] gallery-dl not found. Install from https://github.com/mikf/gallery-dl' -ForegroundColor Red"
    pause & exit /b 1
)
powershell -Command "Write-Host '[STARTUP] Installed: !GDL_INSTALLED!' -ForegroundColor Green"
powershell -ExecutionPolicy Bypass -EncodedCommand JAByAGEAdwAgAD0AIAAkAGUAbgB2ADoARwBEAEwAXwBJAE4AUwBUAEEATABMAEUARAAuAFQAcgBpAG0AKAApAAoAJABpAG4AcwB0AGEAbABsAGUAZAAgAD0AIAAkAHIAYQB3ACAALQByAGUAcABsAGEAYwBlACAAJwBeAGcAYQBsAGwAZQByAHkALQBkAGwAXABzACoAJwAsACcAJwAKAHQAcgB5ACAAewAKACAAIAAgACAAJAByACAAPQAgAEkAbgB2AG8AawBlAC0AUgBlAHMAdABNAGUAdABoAG8AZAAgAC0AVQByAGkAIAAnAGgAdAB0AHAAcwA6AC8ALwBwAHkAcABpAC4AbwByAGcALwBwAHkAcABpAC8AZwBhAGwAbABlAHIAeQAtAGQAbAAvAGoAcwBvAG4AJwAgAC0AVABpAG0AZQBvAHUAdABTAGUAYwAgADUAIAAtAEUAQQAgAFMAdABvAHAACgAgACAAIAAgACQAbABhAHQAZQBzAHQAIAA9ACAAJAByAC4AaQBuAGYAbwAuAHYAZQByAHMAaQBvAG4ACgAgACAAIAAgAGkAZgAgACgAJABsAGEAdABlAHMAdAAgAC0AZQBxACAAJABpAG4AcwB0AGEAbABsAGUAZAApACAAewAKACAAIAAgACAAIAAgACAAIABXAHIAaQB0AGUALQBIAG8AcwB0ACAAIgBbAFMAVABBAFIAVABVAFAAXQAgAGcAYQBsAGwAZQByAHkALQBkAGwAIABpAHMAIAB1AHAAIAB0AG8AIABkAGEAdABlACAAKAAkAGkAbgBzAHQAYQBsAGwAZQBkACkALgAiACAALQBGAG8AcgBlAGcAcgBvAHUAbgBkAEMAbwBsAG8AcgAgAEcAcgBlAGUAbgAKACAAIAAgACAAfQAgAGUAbABzAGUAIAB7AAoAIAAgACAAIAAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAiAFsAVQBQAEQAQQBUAEUAXQAgACAATgBlAHcAIAB2AGUAcgBzAGkAbwBuACAAYQB2AGEAaQBsAGEAYgBsAGUAOgAgACQAbABhAHQAZQBzAHQAIAAoAHkAbwB1ACAAaABhAHYAZQAgACQAaQBuAHMAdABhAGwAbABlAGQAKQAiACAALQBGAG8AcgBlAGcAcgBvAHUAbgBkAEMAbwBsAG8AcgAgAFkAZQBsAGwAbwB3AAoAIAAgACAAIAAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAiACAAIAAgACAAIAAgACAAIAAgAFIAdQBuADoAIABwAGkAcAAgAGkAbgBzAHQAYQBsAGwAIAAtAFUAIABnAGEAbABsAGUAcgB5AC0AZABsACIAIAAtAEYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACAAWQBlAGwAbABvAHcACgAgACAAIAAgAH0ACgB9ACAAYwBhAHQAYwBoACAAewAKACAAIAAgACAAVwByAGkAdABlAC0ASABvAHMAdAAgACcAWwBTAFQAQQBSAFQAVQBQAF0AIABDAG8AdQBsAGQAIABuAG8AdAAgAGMAaABlAGMAawAgAGYAbwByACAAdQBwAGQAYQB0AGUAcwAgACgAbgBvACAAaQBuAHQAZQByAG4AZQB0ACAAbwByACAAdABpAG0AZQBvAHUAdAApAC4AJwAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABHAHIAYQB5AAoAfQAKAA==
echo.

rem ===============================================================================
rem  SANITIZE THREAD LIST — strip BOM and invisible chars on startup
rem ===============================================================================
if exist "%LIST%" (
    powershell -Command "$f='%LIST%'; $raw=@(Get-Content $f -Encoding UTF8 -EA SilentlyContinue); if($raw){$raw[0]=$raw[0] -replace '^\xef\xbb\xbf',''; $clean=@($raw|ForEach-Object{($_ -replace '[^\x20-\x7E]','').Trim()}|Where-Object{$_ -match '^https?://'}); $enc=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllLines($f,$clean,$enc)}"
    powershell -Command "Write-Host '[STARTUP] Thread list sanitized.' -ForegroundColor Green"
    echo.
)

rem ===============================================================================
rem  INITIALIZE STATS
rem ===============================================================================
if not exist "%STATS_FILE%" (
    (
        echo TOTAL_SESSIONS=0
        echo TOTAL_SUCCESS=0
        echo TOTAL_404=0
        echo TOTAL_BLOCKED=0
        echo TOTAL_FAILED=0
        echo TOTAL_UNSUPPORTED=0
    ) > "%STATS_FILE%"
)
set TOTAL_SESSIONS=0 & set TOTAL_SUCCESS=0 & set TOTAL_404=0
set TOTAL_BLOCKED=0  & set TOTAL_FAILED=0 & set TOTAL_UNSUPPORTED=0
for /f "usebackq tokens=1,2 delims==" %%K in ("%STATS_FILE%") do set %%K=%%L

rem ===============================================================================
rem  LOOP COUNT INPUT
rem ===============================================================================
powershell -Command "Write-Host 'How many monitor cycles to run? (0 = infinite)' -ForegroundColor White"
set "INPUT=0"
set /p INPUT="Loop Count: "
set /a MAX_LOOPS=0 >nul 2>&1
if defined INPUT set /a MAX_LOOPS=INPUT >nul 2>&1
set /a CURRENT_LOOP=0 >nul 2>&1

rem ===============================================================================
rem  ADAPTIVE SLEEP DEFAULTS
rem ===============================================================================
set BASE_THREAD_SLEEP=8
set BASE_CYCLE_SLEEP=30
set MIN_THREAD_SLEEP=3
set MAX_THREAD_SLEEP=15

cls

rem ===============================================================================
rem  MAIN LOOP
rem ===============================================================================
:loop

rem --- Pause/Resume ---
if exist "%PAUSE_FILE%" goto do_pause
goto after_pause
:do_pause
powershell -Command "Write-Host '[PAUSED] Delete pause_4chan.txt to resume...' -ForegroundColor Yellow"
:pause_wait
timeout /t 10 >nul
if exist "%PAUSE_FILE%" goto pause_wait
powershell -Command "Write-Host '[RESUMED]' -ForegroundColor Green"
echo.
:after_pause

rem --- Absorb new_4chan.txt with dedup (EncodedCommand, HashSet O(1)) ---
if exist "%NEW_BOX%" (
    set GDL_LIST=%LIST%
    set GDL_BOX=%NEW_BOX%
    powershell -ExecutionPolicy Bypass -EncodedCommand JABlAG4AYwAgACAAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAFMAeQBzAHQAZQBtAC4AVABlAHgAdAAuAFUAVABGADgARQBuAGMAbwBkAGkAbgBnACgAJABmAGEAbABzAGUAKQAKACQAbABpAHMAdAAgACAAPQAgACQAZQBuAHYAOgBHAEQATABfAEwASQBTAFQACgAkAGIAbwB4ACAAIAAgAD0AIAAkAGUAbgB2ADoARwBEAEwAXwBCAE8AWAAKACQAZQB4AGkAcwB0AGkAbgBnACAAPQAgAFsAUwB5AHMAdABlAG0ALgBDAG8AbABsAGUAYwB0AGkAbwBuAHMALgBHAGUAbgBlAHIAaQBjAC4ASABhAHMAaABTAGUAdABbAHMAdAByAGkAbgBnAF0AXQAoAFsAUwB5AHMAdABlAG0ALgBTAHQAcgBpAG4AZwBDAG8AbQBwAGEAcgBlAHIAXQA6ADoATwByAGQAaQBuAGEAbABJAGcAbgBvAHIAZQBDAGEAcwBlACkACgBpAGYAIAAoAFQAZQBzAHQALQBQAGEAdABoACAAJABsAGkAcwB0ACkAIAB7AAoAIAAgACAAIABmAG8AcgBlAGEAYwBoACAAKAAkAGwAIABpAG4AIAAoAEcAZQB0AC0AQwBvAG4AdABlAG4AdAAgACQAbABpAHMAdAAgAC0ARQBuAGMAbwBkAGkAbgBnACAAVQBUAEYAOAAgAC0ARQBBACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQApACkAIAB7AAoAIAAgACAAIAAgACAAIAAgACQAZQB4AGkAcwB0AGkAbgBnAC4AQQBkAGQAKAAkAGwALgBUAHIAaQBtACgAKQApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAAKACAAIAAgACAAfQAKAH0ACgAkAHQAbwBBAGQAZAAgAD0AIABbAFMAeQBzAHQAZQBtAC4AQwBvAGwAbABlAGMAdABpAG8AbgBzAC4ARwBlAG4AZQByAGkAYwAuAEwAaQBzAHQAWwBzAHQAcgBpAG4AZwBdAF0AOgA6AG4AZQB3ACgAKQAKACQAZAB1AHAAZQBzACAAPQAgADAACgBmAG8AcgBlAGEAYwBoACAAKAAkAHIAYQB3ACAAaQBuACAAKABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAkAGIAbwB4ACAALQBFAG4AYwBvAGQAaQBuAGcAIABVAFQARgA4ACAALQBFAEEAIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlACkAKQAgAHsACgAgACAAIAAgACQAdQAgAD0AIAAoACQAcgBhAHcAIAAtAHIAZQBwAGwAYQBjAGUAIAAnAFsAXgBcAHgAMgAwAC0AXAB4ADcARQBdACcALAAnACcAKQAuAFQAcgBpAG0AKAApAAoAIAAgACAAIABpAGYAIAAoACQAdQAgAC0AbQBhAHQAYwBoACAAJwBeAGgAdAB0AHAAcwA/ADoALwAvACcAIAAtAGEAbgBkACAAJABlAHgAaQBzAHQAaQBuAGcALgBBAGQAZAAoACQAdQApACkAIAB7AAoAIAAgACAAIAAgACAAIAAgACQAdABvAEEAZABkAC4AQQBkAGQAKAAkAHUAKQAKACAAIAAgACAAIAAgACAAIABXAHIAaQB0AGUALQBIAG8AcwB0ACAAIgAgACAAWwBBAEQARABFAEQAXQAgACQAdQAiACAALQBGAG8AcgBlAGcAcgBvAHUAbgBkAEMAbwBsAG8AcgAgAEcAcgBlAGUAbgAKACAAIAAgACAAfQAgAGUAbABzAGUAaQBmACAAKAAkAHUAIAAtAG0AYQB0AGMAaAAgACcAXgBoAHQAdABwAHMAPwA6AC8ALwAnACkAIAB7AAoAIAAgACAAIAAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAiACAAIABbAEQAVQBQAEwASQBDAEEAVABFAF0AIAAkAHUAIgAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABZAGUAbABsAG8AdwAKACAAIAAgACAAIAAgACAAIAAkAGQAdQBwAGUAcwArACsACgAgACAAIAAgAH0ACgB9AAoAaQBmACAAKAAkAHQAbwBBAGQAZAAuAEMAbwB1AG4AdAAgAC0AZwB0ACAAMAApACAAewAKACAAIAAgACAAJABiAGEAdABjAGgAIAA9ACAAKAAkAHQAbwBBAGQAZAAgAC0AagBvAGkAbgAgAFsARQBuAHYAaQByAG8AbgBtAGUAbgB0AF0AOgA6AE4AZQB3AEwAaQBuAGUAKQAgACsAIABbAEUAbgB2AGkAcgBvAG4AbQBlAG4AdABdADoAOgBOAGUAdwBMAGkAbgBlAAoAIAAgACAAIABbAEkATwAuAEYAaQBsAGUAXQA6ADoAQQBwAHAAZQBuAGQAQQBsAGwAVABlAHgAdAAoACQAbABpAHMAdAAsACAAJABiAGEAdABjAGgALAAgACQAZQBuAGMAKQAKAH0ACgBpAGYAIAAoACQAdABvAEEAZABkAC4AQwBvAHUAbgB0ACAALQBnAHQAIAAwACAALQBvAHIAIAAkAGQAdQBwAGUAcwAgAC0AZwB0ACAAMAApACAAewAKACAAIAAgACAAVwByAGkAdABlAC0ASABvAHMAdAAgACIAWwBJAE4ARgBPAF0AIABNAGUAcgBnAGUAIABjAG8AbQBwAGwAZQB0AGUAOgAgACQAKAAkAHQAbwBBAGQAZAAuAEMAbwB1AG4AdAApACAAYQBkAGQAZQBkACwAIAAkAGQAdQBwAGUAcwAgAGQAdQBwAGwAaQBjAGEAdABlACgAcwApAC4AIgAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABDAHkAYQBuAAoAfQAKAFIAZQBtAG8AdgBlAC0ASQB0AGUAbQAgACQAYgBvAHgAIAAtAEYAbwByAGMAZQAgAC0ARQBBACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQAKAA==
    echo.
)

rem --- No list yet ---
if not exist "%LIST%" (
    powershell -Command "Write-Host '[WAIT] No thread list found. Waiting 60s...' -ForegroundColor Yellow"
    timeout /t 60 >nul & cls & goto loop
)

rem --- Max loop pre-check ---
if !MAX_LOOPS! GTR 0 (
    if !CURRENT_LOOP! GEQ !MAX_LOOPS! (
        powershell -Command "Write-Host '[SYSTEM] Max cycles reached. Exiting.' -ForegroundColor Cyan"
        goto end
    )
)

set /a CURRENT_LOOP+=1 >nul 2>&1
set /a TOTAL_SESSIONS+=1 >nul 2>&1

rem --- Count queue for adaptive sleep ---
set QUEUE_SIZE=0
for /f "usebackq tokens=*" %%C in ("%LIST%") do (
    if not "%%C"=="" set /a QUEUE_SIZE+=1 >nul 2>&1
)

rem --- Adaptive thread sleep ---
set THREAD_SLEEP=%BASE_THREAD_SLEEP%
if !QUEUE_SIZE! LEQ 2  set THREAD_SLEEP=%MAX_THREAD_SLEEP%
if !QUEUE_SIZE! GEQ 10 set THREAD_SLEEP=%MIN_THREAD_SLEEP%

rem --- Cycle header ---
powershell -Command "Write-Host '===============================================================================' -ForegroundColor Cyan; Write-Host ' CYCLE: !CURRENT_LOOP!  |  TIME: !TIME:~0,8!  |  QUEUE: !QUEUE_SIZE!  |  SLEEP: !THREAD_SLEEP!s' -ForegroundColor Cyan"
if "!DRY_RUN!"=="1" powershell -Command "Write-Host ' MODE: DRY-RUN' -ForegroundColor Yellow"
powershell -Command "Write-Host '===============================================================================' -ForegroundColor Cyan"
echo.

rem --- Reset cycle counters ---
set CYCLE_SUCCESS=0 & set CYCLE_404=0     & set CYCLE_BLOCKED=0
set CYCLE_FAILED=0  & set CYCLE_SKIPPED=0 & set CYCLE_UNSUPPORTED=0

rem --- Per-cycle dead URL file ---
set DEAD_THIS_CYCLE=dead_cycle_4chan.tmp
if exist "%DEAD_THIS_CYCLE%" del "%DEAD_THIS_CYCLE%"

rem ===============================================================================
rem  PRIORITY QUEUE
rem ===============================================================================
if exist "%PRIORITY_BOX%" (
    powershell -Command "Write-Host '[PRIORITY] Processing priority threads...' -ForegroundColor Yellow"
    echo.
    for /f "usebackq tokens=*" %%P in ("%PRIORITY_BOX%") do (
        if not "%%P"=="" call :process_thread "%%P" "PRIORITY"
    )
    echo.
)

rem ===============================================================================
rem  MAIN QUEUE
rem ===============================================================================
for /f "usebackq tokens=*" %%A in ("%LIST%") do (
    if not "%%A"=="" call :process_thread "%%A" "NORMAL"
)

rem ===============================================================================
rem  SAFE DEAD URL REMOVAL
rem  FIX: Trigger on CYCLE_404 OR CYCLE_UNSUPPORTED — both write to DEAD_THIS_CYCLE
rem ===============================================================================
set /a CYCLE_DEAD=CYCLE_404+CYCLE_UNSUPPORTED >nul 2>&1
if !CYCLE_DEAD! GTR 0 (
    powershell -Command "$lf='%LIST%'; $df='%DEAD_THIS_CYCLE%'; $dead=@(Get-Content $df -EA SilentlyContinue|Where-Object{$_ -match '^https?://'}|ForEach-Object{$_.Trim()}); if($dead.Count -gt 0){$lines=Get-Content $lf -Encoding UTF8 -EA SilentlyContinue; $kept=@($lines|Where-Object{$u=$_.Trim(); $u -ne '' -and $dead -notcontains $u}); $enc=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllLines($lf,$kept,$enc)}" 2>nul
    powershell -Command "Write-Host '[CLEANUP] Removed !CYCLE_DEAD! dead thread(s).' -ForegroundColor Yellow"
    if exist "%DEAD_THIS_CYCLE%" del "%DEAD_THIS_CYCLE%"
)

rem --- Commit stats ---
set /a TOTAL_SUCCESS+=CYCLE_SUCCESS >nul 2>&1
set /a TOTAL_404+=CYCLE_404         >nul 2>&1
set /a TOTAL_BLOCKED+=CYCLE_BLOCKED >nul 2>&1
set /a TOTAL_FAILED+=CYCLE_FAILED       >nul 2>&1
set /a TOTAL_UNSUPPORTED+=CYCLE_UNSUPPORTED >nul 2>&1
(
    echo TOTAL_SESSIONS=!TOTAL_SESSIONS!
    echo TOTAL_SUCCESS=!TOTAL_SUCCESS!
    echo TOTAL_404=!TOTAL_404!
    echo TOTAL_BLOCKED=!TOTAL_BLOCKED!
    echo TOTAL_FAILED=!TOTAL_FAILED!
    echo TOTAL_UNSUPPORTED=!TOTAL_UNSUPPORTED!
) > "%STATS_FILE%"

rem ===============================================================================
rem  CYCLE SUMMARY
rem ===============================================================================
echo.
powershell -Command "Write-Host '-----------------------------------------------------------------------' -ForegroundColor Cyan; Write-Host ' CYCLE !CURRENT_LOOP! SUMMARY' -ForegroundColor Cyan; Write-Host '-----------------------------------------------------------------------' -ForegroundColor Cyan; Write-Host '  Success     : !CYCLE_SUCCESS!'     -ForegroundColor Green; Write-Host '  404d        : !CYCLE_404!'         -ForegroundColor Yellow; Write-Host '  Blocked     : !CYCLE_BLOCKED!'     -ForegroundColor Yellow; Write-Host '  Unsupported : !CYCLE_UNSUPPORTED!' -ForegroundColor Yellow; Write-Host '  Failed      : !CYCLE_FAILED!'      -ForegroundColor Red; Write-Host '  Skipped     : !CYCLE_SKIPPED!'     -ForegroundColor Gray; Write-Host '-----------------------------------------------------------------------' -ForegroundColor Cyan; Write-Host ' ALL-TIME  Sessions:!TOTAL_SESSIONS!  OK:!TOTAL_SUCCESS!  404:!TOTAL_404!  Blocked:!TOTAL_BLOCKED!  Failed:!TOTAL_FAILED!  Unsupported:!TOTAL_UNSUPPORTED!' -ForegroundColor White; Write-Host '-----------------------------------------------------------------------' -ForegroundColor Cyan"
echo.

rem --- Max loop post-check ---
if !MAX_LOOPS! GTR 0 (
    if !CURRENT_LOOP! GEQ !MAX_LOOPS! (
        powershell -Command "Write-Host '[SYSTEM] Final cycle complete.' -ForegroundColor Cyan"
        goto end
    )
)

rem --- Adaptive cycle rest ---
set CYCLE_SLEEP=%BASE_CYCLE_SLEEP%
if !QUEUE_SIZE! LEQ 2  set CYCLE_SLEEP=60
if !QUEUE_SIZE! GEQ 10 set CYCLE_SLEEP=15
powershell -Command "Write-Host '[SYSTEM] Resting !CYCLE_SLEEP!s...' -ForegroundColor White"
timeout /t !CYCLE_SLEEP! >nul
cls
goto loop

rem ===============================================================================
rem  SUBROUTINE: PROCESS_THREAD
rem ===============================================================================
:process_thread
setlocal
set "T_URL=%~1"
set "T_TYPE=%~2"
set T_URL=!T_URL:"=!

powershell -Command "Write-Host '[!T_TYPE!] Scraping: !T_URL!' -ForegroundColor White"

rem --- Dry-run ---
if "!DRY_RUN!"=="1" (
    powershell -Command "Write-Host '  [DRY-RUN] gallery-dl --sleep-request 2.0 \"!T_URL!\"' -ForegroundColor Yellow"
    echo.
    endlocal & set /a CYCLE_SKIPPED+=1 >nul 2>&1
    exit /b
)

rem --- Retry loop ---
set /a RETRY_COUNT=0 >nul 2>&1
:retry_inner
if !RETRY_COUNT! GTR 0 (
    powershell -Command "Write-Host '  [RETRY !RETRY_COUNT!/%MAX_RETRIES%] Waiting 10s...' -ForegroundColor Yellow"
    timeout /t 10 >nul
)

rem --- Run gallery-dl via EncodedCommand (no temp file, no paren issues) ---
set GDL_URL=!T_URL!
set GDL_LOG=!LOG!
powershell -ExecutionPolicy Bypass -EncodedCommand JABwAHIAbwBjACAAPQAgAFMAdABhAHIAdAAtAFAAcgBvAGMAZQBzAHMAIAAtAEYAaQBsAGUAUABhAHQAaAAgACcAZwBhAGwAbABlAHIAeQAtAGQAbAAnACAALQBBAHIAZwB1AG0AZQBuAHQATABpAHMAdAAgAEAAKAAnAC0ALQBzAGwAZQBlAHAALQByAGUAcQB1AGUAcwB0ACcALAAnADIALgAwACcALAAkAGUAbgB2ADoARwBEAEwAXwBVAFIATAApACAALQBSAGUAZABpAHIAZQBjAHQAUwB0AGEAbgBkAGEAcgBkAE8AdQB0AHAAdQB0ACAAJABlAG4AdgA6AEcARABMAF8ATABPAEcAIAAtAFIAZQBkAGkAcgBlAGMAdABTAHQAYQBuAGQAYQByAGQARQByAHIAbwByACAAKAAkAGUAbgB2ADoARwBEAEwAXwBMAE8ARwAgACsAIAAnAC4AZQByAHIAJwApACAALQBOAG8ATgBlAHcAVwBpAG4AZABvAHcAIAAtAFAAYQBzAHMAVABoAHIAdQAKAGkAZgAgACgALQBuAG8AdAAgACQAcAByAG8AYwApACAAewAgAGUAeABpAHQAIAAxACAAfQAKACQAbQBhAHgAVwBhAGkAdAAgAD0AIAA2ADAAMAA7ACAAJABzAHAAaQBuACAAPQAgADAAOwAgACQAcwB0AGEAcgB0AFQAaQBtAGUAIAA9ACAARwBlAHQALQBEAGEAdABlAAoAJABzAHAAaQBuAG4AZQByACAAPQAgAEAAKAAnAHwAJwAsACcALwAnACwAJwAtACcALAAnAFwAJwApAAoAdwBoAGkAbABlACAAKAAtAG4AbwB0ACAAJABwAHIAbwBjAC4ASABhAHMARQB4AGkAdABlAGQAKQAgAHsACgAgACAAIAAgACQAZQBsAGEAcABzAGUAZAAgAD0AIABbAGkAbgB0AF0AKABbAGQAYQB0AGUAdABpAG0AZQBdADoAOgBOAG8AdwAgAC0AIAAkAHMAdABhAHIAdABUAGkAbQBlACkALgBUAG8AdABhAGwAUwBlAGMAbwBuAGQAcwAKACAAIAAgACAAaQBmACAAKAAkAGUAbABhAHAAcwBlAGQAIAAtAGcAZQAgACQAbQBhAHgAVwBhAGkAdAApACAAewAgAGIAcgBlAGEAawAgAH0ACgAgACAAIAAgAFMAdABhAHIAdAAtAFMAbABlAGUAcAAgAC0ATQBpAGwAbABpAHMAZQBjAG8AbgBkAHMAIAAyADAAMAAKACAAIAAgACAAJAB0ACAAPQAgACcAewAwADoARAAyAH0AOgB7ADEAOgBEADIAfQAnACAALQBmACAAKABbAGkAbgB0AF0AKAAkAGUAbABhAHAAcwBlAGQALwA2ADAAKQApACwAKAAkAGUAbABhAHAAcwBlAGQAJQA2ADAAKQAKACAAIAAgACAAJABzACAAPQAgACQAcwBwAGkAbgBuAGUAcgBbACQAcwBwAGkAbgAgACUAIAA0AF0AOwAgACQAcwBwAGkAbgArACsACgAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAiAGAAcgAgACAAWwAkAHMAXQAgAFMAYwByAGEAcABpAG4AZwAuAC4ALgAgACAAWwAkAHQAXQAgACAAIgAgAC0ATgBvAE4AZQB3AGwAaQBuAGUAIAAtAEYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACAAQwB5AGEAbgAKAH0ACgBXAHIAaQB0AGUALQBIAG8AcwB0ACAAJwAnAAoAaQBmACAAKAAtAG4AbwB0ACAAJABwAHIAbwBjAC4ASABhAHMARQB4AGkAdABlAGQAKQAgAHsACgAgACAAIAAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAnACAAIABbAFQASQBNAEUATwBVAFQAXQAgAGcAYQBsAGwAZQByAHkALQBkAGwAIABlAHgAYwBlAGUAZABlAGQAIAA2ADAAMABzAC4AIABLAGkAbABsAGkAbgBnAC4AJwAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABSAGUAZAAKACAAIAAgACAAJABwAHIAbwBjAC4ASwBpAGwAbAAoACkAOwAgACQAcAByAG8AYwAuAFcAYQBpAHQARgBvAHIARQB4AGkAdAAoADUAMAAwADAAKQAgAHwAIABPAHUAdAAtAE4AdQBsAGwACgAgACAAIAAgAGkAZgAgACgAVABlAHMAdAAtAFAAYQB0AGgAIAAoACQAZQBuAHYAOgBHAEQATABfAEwATwBHACAAKwAgACcALgBlAHIAcgAnACkAKQAgAHsACgAgACAAIAAgACAAIAAgACAAJABlAHIAcgAgAD0AIABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAoACQAZQBuAHYAOgBHAEQATABfAEwATwBHACAAKwAgACcALgBlAHIAcgAnACkAIAAtAFIAYQB3AAoAIAAgACAAIAAgACAAIAAgAGkAZgAgACgAJABlAHIAcgApACAAewAgAEEAZABkAC0AQwBvAG4AdABlAG4AdAAgAC0AUABhAHQAaAAgACQAZQBuAHYAOgBHAEQATABfAEwATwBHACAALQBWAGEAbAB1AGUAIAAkAGUAcgByACAAfQAKACAAIAAgACAAIAAgACAAIABSAGUAbQBvAHYAZQAtAEkAdABlAG0AIAAoACQAZQBuAHYAOgBHAEQATABfAEwATwBHACAAKwAgACcALgBlAHIAcgAnACkAIAAtAEYAbwByAGMAZQAKACAAIAAgACAAfQAKACAAIAAgACAAZQB4AGkAdAAgADEACgB9AAoAaQBmACAAKABUAGUAcwB0AC0AUABhAHQAaAAgACgAJABlAG4AdgA6AEcARABMAF8ATABPAEcAIAArACAAJwAuAGUAcgByACcAKQApACAAewAKACAAIAAgACAAJABlAHIAcgAgAD0AIABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAoACQAZQBuAHYAOgBHAEQATABfAEwATwBHACAAKwAgACcALgBlAHIAcgAnACkAIAAtAFIAYQB3AAoAIAAgACAAIABpAGYAIAAoACQAZQByAHIAKQAgAHsAIABBAGQAZAAtAEMAbwBuAHQAZQBuAHQAIAAtAFAAYQB0AGgAIAAkAGUAbgB2ADoARwBEAEwAXwBMAE8ARwAgAC0AVgBhAGwAdQBlACAAJABlAHIAcgAgAH0ACgAgACAAIAAgAFIAZQBtAG8AdgBlAC0ASQB0AGUAbQAgACgAJABlAG4AdgA6AEcARABMAF8ATABPAEcAIAArACAAJwAuAGUAcgByACcAKQAgAC0ARgBvAHIAYwBlAAoAfQAKAGUAeABpAHQAIAAkAHAAcgBvAGMALgBFAHgAaQB0AEMAbwBkAGUACgA=
set DL_ERR=!errorlevel!
rem --- Success (exit 0) — but verify thread is not actually dead ---
if "!DL_ERR!"=="0" (
    set IS_DEAD_OK=0
    findstr /C:"Not Found"   "%LOG%" >nul 2>&1 & if "!errorlevel!"=="0" set IS_DEAD_OK=1
    findstr /C:"has expired" "%LOG%" >nul 2>&1 & if "!errorlevel!"=="0" set IS_DEAD_OK=1
    findstr /C:"is archived" "%LOG%" >nul 2>&1 & if "!errorlevel!"=="0" set IS_DEAD_OK=1
    if "!IS_DEAD_OK!"=="1" (
        echo [!DATE! !TIME!] 404 REMOVED: !T_URL! >> "%FAIL_LOG%"
        echo !T_URL! >> "%DEAD_THIS_CYCLE%"
        powershell -Command "Write-Host '  [404] Thread gone (exit 0). Removing after cycle.' -ForegroundColor Yellow"
        echo.
        endlocal & set /a CYCLE_404+=1 >nul 2>&1
        exit /b
    )
    powershell -Command "Write-Host '  [OK] Downloaded.' -ForegroundColor Green; Write-Host '  [PAUSE] Waiting !THREAD_SLEEP!s...' -ForegroundColor White"
    echo.
    endlocal & set /a CYCLE_SUCCESS+=1 >nul 2>&1 & set EXIT_WAIT_OUT=!THREAD_SLEEP!
    timeout /t !EXIT_WAIT_OUT! >nul
    exit /b
)

rem --- Classify error ---
set IS_BLOCKED=0 & set IS_404=0 & set IS_UNSUPPORTED=0

findstr /C:"429 Too Many"    "%LOG%" >nul & if "!errorlevel!"=="0" set IS_BLOCKED=1
findstr /C:"403 Client"      "%LOG%" >nul & if "!errorlevel!"=="0" set IS_BLOCKED=1
findstr /C:"404 Client"      "%LOG%" >nul & if "!errorlevel!"=="0" set IS_404=1
findstr /C:"Unsupported URL" "%LOG%" >nul & if "!errorlevel!"=="0" set IS_UNSUPPORTED=1

rem --- Unsupported URL ---
if "!IS_UNSUPPORTED!"=="1" (
    echo [!DATE! !TIME!] UNSUPPORTED: !T_URL! >> "%FAIL_LOG%"
    echo !T_URL! >> "%DEAD_THIS_CYCLE%"
    powershell -Command "Write-Host '  [UNSUPPORTED] Not a valid gallery-dl URL. Removing.' -ForegroundColor Yellow"
    echo.
    endlocal & set /a CYCLE_UNSUPPORTED+=1 >nul 2>&1
    exit /b
)

rem --- 404 ---
if "!IS_404!"=="1" (
    echo [!DATE! !TIME!] 404 REMOVED: !T_URL! >> "%FAIL_LOG%"
    echo !T_URL! >> "%DEAD_THIS_CYCLE%"
    powershell -Command "Write-Host '  [404] Thread gone. Removing after cycle.' -ForegroundColor Yellow"
    echo.
    endlocal & set /a CYCLE_404+=1 >nul 2>&1
    exit /b
)

rem --- Blocked ---
if "!IS_BLOCKED!"=="1" (
    echo [!DATE! !TIME!] BLOCKED: !T_URL! >> "%FAIL_LOG%"
    powershell -Command "Write-Host '  [BLOCKED] Cloudflare/rate-limit. Pausing 5 min...' -ForegroundColor Red"
    echo.
    endlocal & set /a CYCLE_BLOCKED+=1 >nul 2>&1
    timeout /t 300 >nul
    exit /b
)

rem --- Unknown: retry ---
set /a RETRY_COUNT+=1 >nul 2>&1
if !RETRY_COUNT! LEQ %MAX_RETRIES% goto retry_inner

rem --- Retries exhausted ---
echo [!DATE! !TIME!] FAILED (max retries): !T_URL! >> "%FAIL_LOG%"
powershell -Command "Write-Host '  [FAILED] Exhausted retries. Keeping in queue.' -ForegroundColor Red"
echo.
endlocal & set /a CYCLE_FAILED+=1 >nul 2>&1
exit /b

rem ===============================================================================
rem  HELP
rem ===============================================================================
:show_help
cls
echo.
echo  4chan Thread Monitor v2.0
echo  -------------------------
echo  USAGE:  4chan_monitor.bat [--dry-run] [--help]
echo.
echo  FILES:
echo    threads_4chan.txt   Thread URLs (one per line)
echo    new_4chan.txt       Drop URLs here to add on next cycle
echo    priority_4chan.txt  Processed first every cycle
echo    pause_4chan.txt     Create to pause, delete to resume
echo    stats_4chan.txt     Persistent stats
echo    failures_4chan.txt  Log of all failures and removals
echo.
pause & exit /b

rem ===============================================================================
rem  END
rem ===============================================================================
:end
echo.
powershell -Command "Write-Host '===============================================================================' -ForegroundColor Cyan; Write-Host '  SESSION COMPLETE' -ForegroundColor Cyan; Write-Host '===============================================================================' -ForegroundColor Cyan; Write-Host '  Sessions : !TOTAL_SESSIONS!' -ForegroundColor White; Write-Host '  Success  : !TOTAL_SUCCESS!'  -ForegroundColor Green; Write-Host '  404d     : !TOTAL_404!'      -ForegroundColor Yellow; Write-Host '  Blocked  : !TOTAL_BLOCKED!'  -ForegroundColor Yellow; Write-Host '  Failed      : !TOTAL_FAILED!'       -ForegroundColor Red; Write-Host '  Unsupported : !TOTAL_UNSUPPORTED!'  -ForegroundColor Yellow; Write-Host '===============================================================================' -ForegroundColor Cyan"
powershell -Command "[console]::beep(900,200); Start-Sleep -Milliseconds 100; [console]::beep(900,200)"
echo.
pause >nul