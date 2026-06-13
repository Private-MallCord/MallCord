@echo off
setlocal enabledelayedexpansion

set "REPO_URL=https://github.com/Sonnyasd/MallCord"
set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"

echo.
echo ================================================
echo         Private MallCord Setup
echo ================================================
echo.

echo What would you like to do?
echo [1] Install / Update
echo [2] Check for Updates
echo [3] Uninstall
echo.
choice /C 123 /M "Choose an option"

set "MODE=!errorlevel!"

if %MODE%==3 goto uninstall
if %MODE%==2 goto checkupdate

:: ==================== INSTALL / UPDATE ====================
echo.
echo Closing Discord...
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git not found. Install it from https://git-scm.com/download/win
    pause
    goto end
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Install from https://nodejs.org
    pause
    goto end
)

echo Updating / Installing...

if exist "%INSTALL_DIR%\.git" (
    cd /d "%INSTALL_DIR%"
    git fetch origin main
    git reset --hard origin/main
) else (
    if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
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
echo ================================================
echo   SUCCESS! Private MallCord installed.
echo   Start Discord now.
echo ================================================
pause
goto end

:checkupdate
if not exist "%INSTALL_DIR%\.git" (
    echo Not installed yet.
    pause
    goto end
)
cd /d "%INSTALL_DIR%"
git fetch origin main
git log HEAD..origin/main --oneline
echo.
choice /C YN /M "Update now?"
if !errorlevel! equ 1 (
    taskkill /F /IM Discord* >nul 2>&1
    git reset --hard origin/main
    pnpm install --no-frozen-lockfile
    pnpm build
    node scripts\runInstaller.mjs -- --install
    echo Update done!
)
pause
goto end

:uninstall
if not exist "%INSTALL_DIR%" (
    echo Not found.
    pause
    goto end
)
cd /d "%INSTALL_DIR%"
call node scripts\runInstaller.mjs -- --uninstall
echo.
choice /C YN /M "Delete folder too?"
if !errorlevel! equ 1 rmdir /s /q "%INSTALL_DIR%"
echo Uninstalled.
pause
goto end

:end
endlocal
