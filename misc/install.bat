@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

echo ================================================
echo         Private MallCord Setup
echo ================================================
echo.

echo What would you like to do?
echo [1] Install / Update
echo [2] Check for Updates
echo [3] Uninstall
echo [4] Exit
echo.
choice /C 1234 /M "Choose an option"

set "CHOICE=!errorlevel!"

if !CHOICE! equ 4 goto end
if !CHOICE! equ 3 goto uninstall
if !CHOICE! equ 2 goto check_update

:: ==================== INSTALL / UPDATE ====================
echo.
net session >nul 2>&1
if !errorlevel! equ 0 (
    echo WARNING: Running as Administrator may break Discord.
    choice /C YN /M "Continue anyway?"
    if !errorlevel! equ 2 goto end
)

echo Closing Discord...
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: git not found. Install from https://git-scm.com/download/win
    pause
    goto end
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Install from https://nodejs.org
    pause
    goto end
)

node -e "if(parseInt(process.version.slice(1))<18)process.exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js v18+ required.
    pause
    goto end
)

where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing pnpm...
    call npm install -g pnpm
)

echo.
echo Updating / Installing Private MallCord...

set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"
set "REPO_URL=https://github.com/Sonnyasd/MallCord"

if exist "%INSTALL_DIR%\.git" (
    cd /d "%INSTALL_DIR%"
    git fetch origin main
    git reset --hard origin/main
    echo [OK] Repository updated.
) else (
    if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    cd /d "%INSTALL_DIR%"
    echo [OK] Cloned.
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

:check_update
if not exist "%INSTALL_DIR%\.git" (
    echo Private MallCord is not installed yet.
    pause
    goto end
)
cd /d "%INSTALL_DIR%"
echo Checking for updates...
git fetch origin main
git log HEAD..origin/main --oneline
echo.
choice /C YN /M "Update now?"
if !errorlevel! equ 1 (
    taskkill /F /IM Discord.exe >nul 2>&1
    taskkill /F /IM DiscordPTB.exe >nul 2>&1
    taskkill /F /IM DiscordCanary.exe >nul 2>&1
    git reset --hard origin/main
    call pnpm install --no-frozen-lockfile
    call pnpm build
    call node scripts\runInstaller.mjs -- --install
    echo Update completed successfully!
)
pause
goto end

:uninstall
if not exist "%INSTALL_DIR%" (
    echo Private MallCord not found.
    pause
    goto end
)
echo Found at %INSTALL_DIR%
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1

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
pause
goto end

:end
endlocal
