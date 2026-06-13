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

if !MODE! equ 3 goto uninstall
if !MODE! equ 2 goto checkupdate

:: Install / Update
echo.
echo Closing Discord...
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git not found!
    echo Please install from https://git-scm.com/download/win
    pause
    goto end
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found!
    echo Please install from https://nodejs.org
    pause
    goto end
)

echo.
echo Installing / Updating Private MallCord...

if exist "%INSTALL_DIR%\.git" (
    cd /d "%INSTALL_DIR%"
    git fetch origin main
    git reset --hard origin/main
    echo Repository updated.
) else (
    if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    cd /d "%INSTALL_DIR%"
)

echo Installing dependencies...
pnpm install --no-frozen-lockfile

echo Building...
pnpm build

echo Injecting into Discord...
node scripts\runInstaller.mjs -- --install

echo.
echo ================================================
echo   Private MallCord installed successfully!
echo   Start Discord to use it.
echo ================================================
pause
goto end

:checkupdate
cd /d "%INSTALL_DIR%"
git fetch origin main
git log HEAD..origin/main --oneline
echo.
choice /C YN /M "Update now?"
if !errorlevel! equ 1 (
    git reset --hard origin/main
    pnpm install --no-frozen-lockfile
    pnpm build
    node scripts\runInstaller.mjs -- --install
    echo Update successful!
)
pause
goto end

:uninstall
cd /d "%INSTALL_DIR%"
node scripts\runInstaller.mjs -- --uninstall
choice /C YN /M "Delete folder too?"
if !errorlevel! equ 1 rmdir /s /q "%INSTALL_DIR%"
echo Uninstalled.
pause

:end
endlocal
