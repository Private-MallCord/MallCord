@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

:: ================================================
:: Private MallCord - Official Installer
:: ================================================

set "REPO_URL=https://github.com/Sonnyasd/MallCord"
set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"

echo.
echo +---------------------------------+
echo ^|   Private MallCord Setup        ^|
echo +---------------------------------+
echo.
echo What would you like to do?
echo [1] Install / Update
echo [2] Check for Updates
echo [3] Uninstall
echo.
choice /C 123 /M " Choose an option"
set "MODE_CHOICE=!errorlevel!"
echo.

if !MODE_CHOICE! equ 3 goto :uninstall
if !MODE_CHOICE! equ 2 goto :check_update

:: ===================== INSTALL / UPDATE =====================
net session >nul 2>&1
if !errorlevel! equ 0 (
    echo WARNING: You are running as Administrator.
    echo This can break Discord. Run as normal user instead.
    echo.
    choice /C YN /M " Continue anyway"
    if !errorlevel! equ 2 goto :end
)

echo Closing Discord...
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: git not found.
    echo Install it from https://git-scm.com/download/win
    goto :fail
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found.
    echo Install LTS from https://nodejs.org
    goto :fail
)

node -e "if(parseInt(process.version.slice(1))<18)process.exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js v18+ required.
    goto :fail
)

where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing pnpm...
    call npm install -g pnpm
)

echo.
if exist "%INSTALL_DIR%\.git" (
    echo Private MallCord already found.
    echo Updating to latest version...
    cd /d "%INSTALL_DIR%"
    git fetch origin main
    git reset --hard origin/main
) else (
    echo Cloning Private MallCord...
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    cd /d "%INSTALL_DIR%"
)

echo Installing dependencies...
call pnpm install --no-frozen-lockfile

echo Building...
call pnpm build

echo Injecting into Discord...
call node scripts\runInstaller.mjs -- --install

echo.
echo ============================================
echo Private MallCord installed successfully!
echo Start Discord to load it.
echo ============================================
goto :end

:: ===================== CHECK FOR UPDATES =====================
:check_update
if not exist "%INSTALL_DIR%\.git" (
    echo Private MallCord not found.
    goto :fail
)
cd /d "%INSTALL_DIR%"
echo Checking for updates...
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
goto :end

:: ===================== UNINSTALL =====================
:uninstall
if not exist "%INSTALL_DIR%\.git" (
    echo Private MallCord not found.
    goto :fail
)
echo Found at %INSTALL_DIR%.
cd /d "%INSTALL_DIR%"
call node scripts\runInstaller.mjs -- --uninstall

echo.
choice /C YN /M "Also delete folder?"
if !errorlevel! equ 1 (
    cd /d "%USERPROFILE%"
    rmdir /s /q "%INSTALL_DIR%"
    echo Folder deleted.
)
echo Private MallCord uninstalled. Restart Discord.
goto :end

:fail
echo Failed. See errors above.
:end
pause
endlocal
