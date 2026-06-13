@echo off
setlocal enabledelayedexpansion

:: ================================================
::       Private MallCord Setup
:: ================================================
title Private MallCord Setup vBETA
set "VERSION=vBETA"
set "REPO_URL=https://github.com/Sonnyasd/MallCord"
set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"
set "BRANCH=main"
set "LOGFILE=%INSTALL_DIR%\PrivateMallCord_Install.log"
set "DISCORD_PATH="

cls
echo.
echo   +---------------------------------------------+
echo   ^|        Private MallCord Setup %VERSION%     ^|
echo   +---------------------------------------------+
echo.

:: ── Main Menu ───────────────────────────────────────────────────────────────
echo   What would you like to do?
echo.
echo   [1] Install / Update
echo   [2] Check for Updates
echo   [3] Force Clean Reinstall
echo   [4] Repair Installation
echo   [5] Discord Client Selector + Start
echo   [6] Set Manual Discord Path
echo   [7] Open GitHub Repository
echo   [8] View Log File
echo   [9] Uninstall
echo.
choice /C 123456789 /M "   Select option" /N
set "MODE_CHOICE=!errorlevel!"

echo.

:: Admin warning
net session >nul 2>&1
if !errorlevel! equ 0 (
    echo   [91mWARNING: Running as Administrator is not recommended![0m
    choice /C YN /M "   Continue anyway?" /N
    if !errorlevel! equ 2 goto :end
)

if !MODE_CHOICE! equ 9 goto :uninstall
if !MODE_CHOICE! equ 8 goto :viewlog
if !MODE_CHOICE! equ 7 goto :openrepo
if !MODE_CHOICE! equ 6 goto :manualdiscordpath
if !MODE_CHOICE! equ 5 goto :discordselector
if !MODE_CHOICE! equ 2 goto :checkupdates
if !MODE_CHOICE! equ 3 goto :forcereinstall
if !MODE_CHOICE! equ 4 goto :repair

:: ════════════════════════════════════════════════════════════
::              INSTALL / UPDATE
:: ════════════════════════════════════════════════════════════
:install
call :log "=== Starting Install/Update %VERSION% ==="

echo   Closing Discord processes...
taskkill /f /im discord.exe >nul 2>&1
taskkill /f /im Discord.exe >nul 2>&1
taskkill /f /im ptb.exe >nul 2>&1
taskkill /f /im canary.exe >nul 2>&1

echo   Checking prerequisites...
where git >nul 2>&1 || (echo   [91mERROR: git not found![0m & goto :fail)
where node >nul 2>&1 || (echo   [91mERROR: Node.js not found![0m & goto :fail)

if not defined DISCORD_PATH call :autodetectdiscord

if exist "%INSTALL_DIR%\.git" (
    echo   Creating backup...
    set "BACKUP_DIR=%INSTALL_DIR%_backup_%DATE:~-4%%DATE:~-7,2%%DATE:~-10,2%"
    xcopy "%INSTALL_DIR%" "!BACKUP_DIR!" /s /e /i /y >nul 2>&1

    cd /d "%INSTALL_DIR%"
    git fetch origin %BRANCH% --quiet
    for /f %%a in ('git rev-list HEAD..origin/%BRANCH% --count') do set "BEHIND=%%a"

    if !BEHIND! gtr 0 (
        echo   [92mUpdate available[0m (!BEHIND! commits)
        choice /C YN /M "   Update now?" /N
        if !errorlevel! equ 2 goto :end
        git pull origin %BRANCH% --ff-only || goto :fail
    ) else (
        echo   You are already up to date.
    )
) else (
    echo   Cloning Private MallCord...
    git clone "%REPO_URL%" "%INSTALL_DIR%" || goto :fail
    cd /d "%INSTALL_DIR%"
)

:build
echo   Installing dependencies...
call pnpm install --frozen-lockfile || goto :fail

echo   Building...
call pnpm build || goto :fail

echo   Injecting into Discord...
call node scripts\runInstaller.mjs -- --install

echo.
echo   =====================================================
echo     Private MallCord %VERSION% installed/updated successfully!
echo   =====================================================

choice /C YN /M "   Start Discord now?" /N
if !errorlevel! equ 1 call :startdiscord
goto :end

:: Manual Discord Path
:manualdiscordpath
echo.
echo   Enter the full path to your Discord installation folder:
echo   Example: C:\Users\YourName\AppData\Local\Discord
echo.
set /p "DISCORD_PATH=Path: "
if exist "%DISCORD_PATH%" (
    echo   [92mPath saved successfully![0m
) else (
    echo   [93mWarning:[0m The path does not exist, but it was saved.
)
pause
goto :end

:: Improved Auto Detect
:autodetectdiscord
    echo   Auto-detecting Discord...
    for %%d in (Discord DiscordPTB DiscordCanary) do (
        if exist "%LOCALAPPDATA%\%%d\Update.exe" (
            set "DISCORD_PATH=%LOCALAPPDATA%\%%d"
            echo   Detected: %%d
            goto :eof
        )
    )
    echo   [93mCould not auto-detect Discord.[0m
    echo   Please use option [6] to set path manually.
    set "DISCORD_PATH="
    goto :eof

:: Check for Updates
:checkupdates
if not exist "%INSTALL_DIR%\.git" (echo   Private MallCord is not installed yet. & goto :fail)
cd /d "%INSTALL_DIR%"
echo   Checking for updates...
git fetch origin %BRANCH% --quiet
for /f %%a in ('git rev-list HEAD..origin/%BRANCH% --count') do set "BEHIND=%%a"
if !BEHIND! gtr 0 (
    echo   [92mUpdate available![0m (!BEHIND! commits behind)
) else (
    echo   [92mYou are up to date![0m
)
pause
goto :end

:: Force Reinstall
:forcereinstall
echo   [93mForce Clean Reinstall[0m
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
goto :install

:: Repair
:repair
if not exist "%INSTALL_DIR%\.git" (echo   Not installed. & goto :fail)
cd /d "%INSTALL_DIR%"
echo   Repairing installation...
call pnpm install --frozen-lockfile
call pnpm build
call node scripts\runInstaller.mjs -- --install
echo   Repair completed.
pause
goto :end

:: Discord Selector
:discordselector
echo   [1] Stable   [2] PTB   [3] Canary
choice /C 123 /M "   Choose client"
if !errorlevel! equ 1 start "" "%LOCALAPPDATA%\Discord\Update.exe" --processStart Discord.exe
if !errorlevel! equ 2 start "" "%LOCALAPPDATA%\DiscordPTB\Update.exe" --processStart DiscordPTB.exe
if !errorlevel! equ 3 start "" "%LOCALAPPDATA%\DiscordCanary\Update.exe" --processStart DiscordCanary.exe
goto :end

:: Open Repository
:openrepo
start "" "%REPO_URL%"
echo   GitHub repository opened.
goto :end

:: View Log
:viewlog
if exist "%LOGFILE%" (
    notepad "%LOGFILE%"
) else (
    echo   No log file found yet.
)
goto :end

:: Uninstall
:uninstall
taskkill /f /im discord.exe >nul 2>&1
if not exist "%INSTALL_DIR%\.git" (echo   Private MallCord not found. & goto :fail)
cd /d "%INSTALL_DIR%"
call node scripts\runInstaller.mjs -- --uninstall

choice /C YN /M "   Delete the PrivateMallCord folder and backups?" /N
if !errorlevel! equ 1 (
    cd ..
    rmdir /s /q "%INSTALL_DIR%"
    echo   Folder deleted.
)
echo   Private MallCord uninstalled successfully.
goto :end

:fail
echo   [91mOperation failed.[0m Check the log file for details.
:end
echo.
call :log "Script finished"
pause
endlocal
exit /b

:: Helper Functions
:startdiscord
    if exist "%LOCALAPPDATA%\Discord\Update.exe" start "" "%LOCALAPPDATA%\Discord\Update.exe" --processStart Discord.exe
    if exist "%LOCALAPPDATA%\DiscordPTB\Update.exe" start "" "%LOCALAPPDATA%\DiscordPTB\Update.exe" --processStart DiscordPTB.exe
    if exist "%LOCALAPPDATA%\DiscordCanary\Update.exe" start "" "%LOCALAPPDATA%\DiscordCanary\Update.exe" --processStart DiscordCanary.exe
    goto :eof

:log
    if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" 2>nul
    echo [%DATE% %TIME%] %* >> "%LOGFILE%" 2>nul
    goto :eof
