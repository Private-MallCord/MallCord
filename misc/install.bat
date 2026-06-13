@echo off
setlocal enabledelayedexpansion

title Private MallCord Setup vBETA
set "VERSION=vBETA"
set "REPO_URL=https://github.com/Sonnyasd/MallCord"
set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"
set "BRANCH=main"
set "LOGFILE=%INSTALL_DIR%\PrivateMallCord_Install.log"

cls
echo.
echo ================================================
echo        Private MallCord Setup %VERSION%
echo ================================================
echo.

echo What would you like to do?
echo.
echo [1] Install / Update
echo [2] Check for Updates
echo [3] Force Clean Reinstall
echo [4] Repair Installation
echo [5] Discord Client Selector + Start
echo [6] Set Manual Discord Path
echo [7] Open GitHub Repository
echo [8] View Log File
echo [9] Uninstall
echo.
choice /C 123456789 /M "Select option" /N
set "MODE_CHOICE=!errorlevel!"

echo.

net session >nul 2>&1
if !errorlevel! equ 0 (
    echo WARNING: Running as Administrator is not recommended!
    choice /C YN /M "Continue anyway?"
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

:install
echo Closing Discord...
taskkill /f /im discord.exe >nul 2>&1
taskkill /f /im Discord.exe >nul 2>&1
taskkill /f /im ptb.exe >nul 2>&1
taskkill /f /im canary.exe >nul 2>&1

echo Checking prerequisites...
where git >nul 2>&1 || (echo ERROR: git not found! & goto :fail)
where node >nul 2>&1 || (echo ERROR: Node.js not found! & goto :fail)

if exist "%INSTALL_DIR%\.git" (
    echo Creating backup...
    set "BACKUP_DIR=%INSTALL_DIR%_backup_%DATE:~-4%%DATE:~-7,2%%DATE:~-10,2%"
    xcopy "%INSTALL_DIR%" "!BACKUP_DIR!" /s /e /i /y >nul 2>&1

    cd /d "%INSTALL_DIR%"
    git fetch origin %BRANCH% --quiet
    for /f %%a in ('git rev-list HEAD..origin/%BRANCH% --count') do set "BEHIND=%%a"

    if !BEHIND! gtr 0 (
        echo Update available (!BEHIND! commits)
        choice /C YN /M "Update now?"
        if !errorlevel! equ 1 git pull origin %BRANCH% --ff-only
    ) else (
        echo You are already up to date.
    )
) else (
    echo Cloning Private MallCord...
    git clone "%REPO_URL%" "%INSTALL_DIR%" || goto :fail
    cd /d "%INSTALL_DIR%"
)

echo Installing dependencies...
call pnpm install --frozen-lockfile || goto :fail

echo Building...
call pnpm build || goto :fail

echo Injecting into Discord...
call node scripts\runInstaller.mjs -- --install

echo.
echo =====================================================
echo   Private MallCord %VERSION% installed/updated successfully!
echo =====================================================

choice /C YN /M "Start Discord now?"
if !errorlevel! equ 1 call :startdiscord
goto :end

:manualdiscordpath
echo.
echo Enter the full path to your Discord folder:
echo Example: C:\Users\YourName\AppData\Local\Discord
echo.
set /p "DISCORD_PATH=Path: "
if exist "%DISCORD_PATH%" (echo Path saved successfully!) else (echo Warning: Path does not exist but saved.)
pause
goto :end

:checkupdates
if not exist "%INSTALL_DIR%\.git" (echo Private MallCord is not installed yet. & goto :fail)
cd /d "%INSTALL_DIR%"
echo Checking for updates...
git fetch origin %BRANCH% --quiet
for /f %%a in ('git rev-list HEAD..origin/%BRANCH% --count') do set "BEHIND=%%a"
if !BEHIND! gtr 0 (echo Update available (!BEHIND! commits)) else (echo You are up to date!)
pause
goto :end

:forcereinstall
echo Force Clean Reinstall...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
goto :install

:repair
if not exist "%INSTALL_DIR%\.git" (echo Not installed. & goto :fail)
cd /d "%INSTALL_DIR%"
echo Repairing...
call pnpm install --frozen-lockfile
call pnpm build
call node scripts\runInstaller.mjs -- --install
echo Repair completed.
pause
goto :end

:discordselector
echo [1] Stable  [2] PTB  [3] Canary
choice /C 123 /M "Choose client"
if !errorlevel! equ 1 start "" "%LOCALAPPDATA%\Discord\Update.exe" --processStart Discord.exe
if !errorlevel! equ 2 start "" "%LOCALAPPDATA%\DiscordPTB\Update.exe" --processStart DiscordPTB.exe
if !errorlevel! equ 3 start "" "%LOCALAPPDATA%\DiscordCanary\Update.exe" --processStart DiscordCanary.exe
goto :end

:openrepo
start "" "%REPO_URL%"
echo GitHub opened.
goto :end

:viewlog
if exist "%LOGFILE%" notepad "%LOGFILE%" else echo No log file yet.
goto :end

:uninstall
taskkill /f /im discord.exe >nul 2>&1
if not exist "%INSTALL_DIR%\.git" (echo Not found. & goto :fail)
cd /d "%INSTALL_DIR%"
call node scripts\runInstaller.mjs -- --uninstall
choice /C YN /M "Delete folder?"
if !errorlevel! equ 1 rmdir /s /q "%INSTALL_DIR%"
echo Uninstalled.
goto :end

:fail
echo Operation failed.
:end
echo.
echo Script finished.
pause
endlocal
exit /b

:startdiscord
    if exist "%LOCALAPPDATA%\Discord\Update.exe" start "" "%LOCALAPPDATA%\Discord\Update.exe" --processStart Discord.exe
    if exist "%LOCALAPPDATA%\DiscordPTB\Update.exe" start "" "%LOCALAPPDATA%\DiscordPTB\Update.exe" --processStart DiscordPTB.exe
    if exist "%LOCALAPPDATA%\DiscordCanary\Update.exe" start "" "%LOCALAPPDATA%\DiscordCanary\Update.exe" --processStart DiscordCanary.exe
    goto :eof
