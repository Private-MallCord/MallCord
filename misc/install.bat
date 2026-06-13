@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

:: ================================================
:: Private MallCord Setup
:: ================================================

set "REPO_URL=https://github.com/Sonnyasd/MallCord"
set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"
set "BACKUP_DIR=%USERPROFILE%\PrivateMallCord_Backup"
set "LOG_FILE=%TEMP%\PrivateMallCord_Install.log"

echo.
echo ================================================
echo         Private MallCord Setup
echo ================================================
echo.

echo What would you like to do?
echo [1] Install / Update
echo [2] Check for Updates
echo [3] Uninstall
echo [4] Rollback to Backup
echo.
choice /C 1234 /M "Choose an option"

set "MODE=!errorlevel!"

if !MODE! equ 4 goto rollback
if !MODE! equ 3 goto uninstall
if !MODE! equ 2 goto checkupdate

:: ===================== INSTALL / UPDATE =====================
echo.
net session >nul 2>&1
if !errorlevel! equ 0 (
    echo WARNING: You are running as Administrator. This can break Discord.
    choice /C YN /M "Continue anyway?"
    if !errorlevel! equ 2 goto end
)

echo Closing Discord processes...
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git not found. Please install from https://git-scm.com/download/win
    pause
    goto end
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Install LTS from https://nodejs.org
    pause
    goto end
)

node -e "if(parseInt(process.version.slice(1))<18)process.exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js v18 or higher is required.
    pause
    goto end
)

where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing pnpm...
    call npm install -g pnpm
)

:: Backup current installation
if exist "%INSTALL_DIR%" (
    echo Creating backup...
    if exist "%BACKUP_DIR%" rmdir /s /q "%BACKUP_DIR%"
    xcopy "%INSTALL_DIR%" "%BACKUP_DIR%" /E /I /H /Y >nul
)

echo.
echo Installing / Updating Private MallCord...

if exist "%INSTALL_DIR%\.git" (
    cd /d "%INSTALL_DIR%"
    git fetch origin main
    git reset --hard origin/main
    echo [OK] Repository updated from GitHub.
) else (
    if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    cd /d "%INSTALL_DIR%"
    echo [OK] Successfully cloned.
)

echo Installing dependencies...
call pnpm install --no-frozen-lockfile

echo Building...
call pnpm build

echo Injecting into Discord...
call node scripts\runInstaller.mjs -- --install

echo.
echo ================================================
echo   Private MallCord installed successfully!
echo   Start Discord to load it.
echo ================================================
pause
goto end

:: ===================== CHECK FOR UPDATES =====================
:checkupdate
if not exist "%INSTALL_DIR%\.git" (
    echo Private MallCord is not installed yet.
    pause
    goto end
)
cd /d "%INSTALL_DIR%"
echo Checking for updates from GitHub...
git fetch origin main
git log HEAD..origin/main --oneline
echo.
choice /C YN /M "Update now?"
if !errorlevel! equ 1 (
    taskkill /F /IM Discord* >nul 2>&1
    git reset --hard origin/main
    call pnpm install --no-frozen-lockfile
    call pnpm build
    call node scripts\runInstaller.mjs -- --install
    echo Update completed successfully!
)
pause
goto end

:: ===================== UNINSTALL =====================
:uninstall
if not exist "%INSTALL_DIR%" (
    echo Private MallCord not found.
    pause
    goto end
)
cd /d "%INSTALL_DIR%"
echo Removing from Discord...
call node scripts\runInstaller.mjs -- --uninstall

echo.
choice /C YN /M "Also delete the PrivateMallCord folder?"
if !errorlevel! equ 1 (
    cd /d "%USERPROFILE%"
    rmdir /s /q "%INSTALL_DIR%"
    echo Folder deleted.
)
echo Private MallCord has been uninstalled. Restart Discord.
pause
goto end

:: ===================== ROLLBACK =====================
:rollback
if not exist "%BACKUP_DIR%" (
    echo No backup found.
    pause
    goto end
)
echo Restoring from backup...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
xcopy "%BACKUP_DIR%" "%INSTALL_DIR%" /E /I /H /Y >nul
echo Rollback completed successfully!
pause
goto end

:end
endlocal
