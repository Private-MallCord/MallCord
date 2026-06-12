@echo off
setlocal enabledelayedexpansion

:: MallCord installer / uninstaller
:: Run as a normal user (NOT as Administrator).

set "REPO_URL=https://github.com/Sonnyasd/MallCord.git"
set "INSTALL_DIR=%USERPROFILE%\MallCord"

echo.
echo   +---------------------------------+
echo   ^|         MallCord Setup          ^|
echo   +---------------------------------+
echo.

echo   What would you like to do?
echo   [1] Install / Update MallCord
echo   [2] Uninstall MallCord
echo.
choice /C 12 /M "   Choose an option"
set "MODE_CHOICE=!errorlevel!"
echo.

net session >nul 2>&1
if !errorlevel! equ 0 (
    echo %CLR_WARN%  [!] WARNING: You are running this script as Administrator!%CLR_RESET%
    echo       This may cause issues during Discord injection (wrong user profile).
    echo.
    choice /C YN /M "   Continue anyway"
    set "ADMIN_CHOICE=!errorlevel!"
    echo.
    if !ADMIN_CHOICE! equ 2 (
        echo   Cancelled.
        goto :end
    )
)

if !MODE_CHOICE! equ 2 goto :uninstall

where git >nul 2>&1
if !errorlevel! neq 0 (
    echo   ERROR: git not found.
    echo          Install it from https://git-scm.com/download/win then re-run.
    goto :fail
)
for /f "tokens=3" %%v in ('git --version 2^>nul') do echo   [OK] git %%v

where node >nul 2>&1
if !errorlevel! neq 0 (
    echo   ERROR: Node.js not found.
    echo          Install LTS from https://nodejs.org then re-run.
    goto :fail
)

:: NODE.JS VERSION CONTROL (v18+)
node -e "if(parseInt(process.version.slice(1))<18)process.exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    for /f "tokens=*" %%v in ('node --version 2^>nul') do (
        echo   %CLR_FAIL%[ERROR] Node.js v18+ is required. Your version: %%v%CLR_RESET%
    )
    echo          Please update Node.js to the latest LTS version!
    goto :fail
) else (
    for /f "tokens=*" %%v in ('node --version 2^>nul') do echo   %CLR_SUCCESS%[OK] Node.js detected: %%v%CLR_RESET%
)

where pnpm >nul 2>&1
if !errorlevel! neq 0 (
    echo   ! pnpm not found. Installing globally via npm...
    call npm install -g pnpm
    if !errorlevel! neq 0 (
        echo   ERROR: Failed to install pnpm.
        goto :fail
    )

    for /f "tokens=*" %%p in ('npm config get prefix 2^>nul') do set "PATH=%%p;!PATH!"

    where pnpm >nul 2>&1
    if !errorlevel! neq 0 (
        echo   ERROR: pnpm was installed but is not in PATH.
        echo          Close this window, open a new Command Prompt, and re-run.
        goto :fail
    )
)
for /f "tokens=*" %%v in ('pnpm --version 2^>nul') do echo   [OK] pnpm %%v

echo.
exit /b

:git_operations
echo %CLR_INFO%[3/4] Downloading and updating source code (GitHub)...%CLR_RESET%

if exist "%INSTALL_DIR%\.git" (
    echo   MallCord already found at %INSTALL_DIR%
    echo   Updating to latest version...
    git -C "%INSTALL_DIR%" fetch origin main
    if !errorlevel! neq 0 (
        echo   ERROR: git fetch failed.
        goto :fail
    )

    git -C "%INSTALL_DIR%" reset --hard origin/main
    if !errorlevel! neq 0 (
        echo   ERROR: git reset failed.
        goto :fail
    )

    echo   [OK] Repository updated.
) else if exist "%INSTALL_DIR%" (
    echo   ERROR: %INSTALL_DIR% exists but is not a git repository.
    echo          Delete it and re-run:
    echo          rmdir /s /q "%INSTALL_DIR%"
    goto :fail
) else (
    echo   Cloning MallCord into %INSTALL_DIR%...
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    if !errorlevel! neq 0 (
        echo   ERROR: Clone failed. Check your internet connection.
        goto :fail
    )
    echo   %CLR_SUCCESS%[OK] Cloning completed successfully.%CLR_RESET%
)
echo.
exit /b

:build_and_inject
echo %CLR_INFO%[4/4] Compiling and injecting MallCord...%CLR_RESET%
cd /d "%INSTALL_DIR%"
if !errorlevel! neq 0 (
    echo   ERROR: Could not enter %INSTALL_DIR%.
    goto :fail
)

echo.
echo   Installing dependencies...
call pnpm install --no-frozen-lockfile
if !errorlevel! neq 0 (
    echo   ERROR: pnpm install failed. See output above.
    goto :fail
)
echo   %CLR_SUCCESS%[OK] Successfully built.%CLR_RESET%

echo.
echo   Building MallCord...
call pnpm build
if !errorlevel! neq 0 (
    echo   ERROR: Build failed. See output above.
    goto :fail
)
echo   [OK] Build complete.

echo.
echo   Injecting into Discord...
call pnpm inject
if !errorlevel! neq 0 (
    echo   ERROR: Injection failed. Make sure Discord is installed.
    goto :fail
)

echo.
echo   ============================================
echo     MallCord installed! Start Discord to load it.
echo   ============================================
echo.
goto :end

:uninstall

if not exist "%INSTALL_DIR%" (
    echo   ERROR: MallCord not found at %INSTALL_DIR%. Nothing to uninstall.
    goto :fail
)

echo   Found MallCord at %INSTALL_DIR%.
echo.

cd /d "%INSTALL_DIR%"
if !errorlevel! neq 0 (
    echo   ERROR: Could not enter %INSTALL_DIR%.
    goto :fail
)

echo   Removing MallCord from Discord...
call pnpm uninject
if !errorlevel! neq 0 (
    echo   WARNING: Uninject step reported an error. Discord may already be uninjected.
)
echo   [OK] MallCord removed from Discord.

echo.
choice /C YN /M "   Also delete the MallCord folder at %INSTALL_DIR%"
set "DEL_CHOICE=!errorlevel!"
echo.

if !DEL_CHOICE! equ 1 (
    echo   Deleting %INSTALL_DIR%...
    cd /d "%USERPROFILE%"
    rmdir /s /q "%INSTALL_DIR%"
    echo   %CLR_SUCCESS%[OK] MallCord folder completely deleted.%CLR_RESET%
) else (
    echo       Folder left untouched.
)
exit /b

:create_backup
if not exist "%INSTALL_DIR%" (
    echo   %CLR_FAIL%[ERROR] Nothing to backup, MallCord folder does not exist.%CLR_RESET%
    exit /b
)
if exist "%BACKUP_DIR%" rmdir /s /q "%BACKUP_DIR%"
xcopy "%INSTALL_DIR%" "%BACKUP_DIR%" /E /I /H /K /Y >nul
echo   %CLR_SUCCESS%[OK] Backup created at: %BACKUP_DIR%%CLR_RESET%
exit /b

:create_backup_silent
if exist "%INSTALL_DIR%" (
    if exist "%BACKUP_DIR%" rmdir /s /q "%BACKUP_DIR%"
    xcopy "%INSTALL_DIR%" "%BACKUP_DIR%" /E /I /H /K /Y >nul
)
exit /b

:restore_backup
if not exist "%BACKUP_DIR%" (
    echo   %CLR_FAIL%[ERROR] No previous backup found!%CLR_RESET%
    exit /b
)
echo       Restoring backup...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
xcopy "%BACKUP_DIR%" "%INSTALL_DIR%" /E /I /H /K /Y >nul
echo   %CLR_SUCCESS%[OK] Previous state successfully restored!%CLR_RESET%
exit /b

:: ============================================================================
::  ENDINGS
:: ============================================================================

:success_end
echo.
echo   ============================================
echo     MallCord uninstalled. Restart Discord.
echo   ============================================
echo.
goto :final_pause

:fail
echo.
echo   %CLR_FAIL%=======================================================%CLR_RESET%
echo   %CLR_FAIL%   AN ERROR OCCURRED DURING THE PROCESS!%CLR_RESET%
echo   %CLR_FAIL%   Check the detailed log: %LOG_FILE%%CLR_RESET%
echo   %CLR_FAIL%=======================================================%CLR_RESET%
echo.

:final_pause
pause
goto :main_menu

:end
echo %CLR_INFO%Thank you for using Private MallCord Setup! Have a great day!%CLR_RESET%
timeout /t 3 >nul
endlocal
