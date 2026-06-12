@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Private MallCord Setup
:: ============================================================================

:: Define ANSI Color Codes
set "ESC="
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "CLR_RESET=%ESC%[0m"
set "CLR_HEADER=%ESC%[95m"
set "CLR_SUCCESS=%ESC%[92m"
set "CLR_WARN=%ESC%[93m"
set "CLR_FAIL=%ESC%[91m"
set "CLR_INFO=%ESC%[96m"
set "CLR_TEXT=%ESC%[37m"

:: Global Settings
set "REPO_URL=https://github.com/Sonnyasd/MallCord.git"
set "INSTALL_DIR=%USERPROFILE%\MallCord"
set "BACKUP_DIR=%USERPROFILE%\MallCord_Backup"
set "LOG_FILE=%USERPROFILE%\mallcord_install.log"

echo %DATE% %TIME% -- Script started -- > "%LOG_FILE%"

:main_menu
cls
echo.
echo   %CLR_HEADER%Private MallCord Setup%CLR_RESET%
echo   -------------------------------------------------------
echo.
echo   %CLR_TEXT%[1]%CLR_RESET% Install / Update MallCord (Recommended)
echo   %CLR_TEXT%[2]%CLR_RESET% Completely Uninstall MallCord
echo   %CLR_TEXT%[3]%CLR_RESET% Check and Terminate Discord Clients
echo   %CLR_TEXT%[4]%CLR_RESET% Manually Check and Fix Dependencies
echo   %CLR_TEXT%[5]%CLR_RESET% Create Backup / Rollback
echo   %CLR_TEXT%[6]%CLR_RESET% Exit
echo.
choice /C 123456 /M "  Choose an option"
set "MENU_CHOICE=!errorlevel!"

if "!MENU_CHOICE!" equ "1" goto install_flow
if "!MENU_CHOICE!" equ "2" goto uninstall_flow
if "!MENU_CHOICE!" equ "3" goto discord_kill_flow
if "!MENU_CHOICE!" equ "4" goto dependency_flow
if "!MENU_CHOICE!" equ "5" goto backup_flow
if "!MENU_CHOICE!" equ "6" goto end
goto main_menu

:: ============================================================================
:: FLOWS
:: ============================================================================

:install_flow
cls
echo %CLR_HEADER%=== MallCord Installation and Update Process ===%CLR_RESET%
echo.
call :check_admin
call :check_dependencies
call :kill_discord
call :git_operations
call :build_and_inject
goto success_end

:uninstall_flow
cls
echo %CLR_HEADER%=== MallCord Uninstallation Process ===%CLR_RESET%
echo.
call :check_admin
call :kill_discord
call :uninject_and_clean
goto success_end

:discord_kill_flow
cls
echo %CLR_HEADER%=== Analyzing Discord Clients ===%CLR_RESET%
echo.
call :kill_discord
echo   %CLR_SUCCESS%[SUCCESS] Discord process management completed.%CLR_RESET%
pause
goto main_menu

:dependency_flow
cls
echo %CLR_HEADER%=== Detailed Dependency Check ===%CLR_RESET%
echo.
call :check_dependencies
echo   %CLR_SUCCESS%[SUCCESS] All environment variables and software are correct!%CLR_RESET%
pause
goto main_menu

:backup_flow
cls
echo %CLR_HEADER%=== Backup and Restore ===%CLR_RESET%
echo.
echo   [1] Backup current MallCord folder
echo   [2] Restore last backup (Rollback)
echo   [3] Back to Main Menu
echo.
choice /C 123 /M "  Choose an option"
set "BK_CHOICE=!errorlevel!"
if "!BK_CHOICE!" equ "1" call :create_backup
if "!BK_CHOICE!" equ "2" call :restore_backup
if "!BK_CHOICE!" equ "3" goto main_menu
pause
goto main_menu


:: ============================================================================
:: SUBROUTINES / FUNCTIONS
:: ============================================================================

:check_admin
net session >nul 2>&1
if "!errorlevel!" equ "0" (
    echo %CLR_WARN%  [!] WARNING: You are running this script as Administrator!%CLR_RESET%
    echo       This may cause issues during Discord injection (wrong user profile).
    echo.
    choice /C YN /M "  Are you sure you want to continue anyway?"
    if "!errorlevel!" equ "2" (
        goto main_menu
    )
)
exit /b

:check_dependencies
echo %CLR_INFO%[1/4] Checking system environment...%CLR_RESET%

:: GIT CHECK
where git >nul 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_WARN%[!] Git was not found on your system.%CLR_RESET%
    echo       Attempting automatic download and installation via Winget...
    where winget >nul 2>&1
    if "!errorlevel!" equ "0" (
        echo       Installing Git, please wait...
        winget install --id Git.Git -e --source winget >> "%LOG_FILE%" 2>&1
        echo       %CLR_WARN%[!] Git installed. Please restart the script to update PATH!%CLR_RESET%
        pause
        goto end
    ) else (
        echo   %CLR_FAIL%[ERROR] Winget is not available either. Please install Git manually:%CLR_RESET%
        echo          https://git-scm.com/download/win
        goto fail
    )
) else (
    for /f "tokens=3" %%v in ('git --version 2^>nul') do echo   %CLR_SUCCESS%[OK] Git detected: %%v%CLR_RESET%
)

:: NODE.JS CHECK
where node >nul 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_FAIL%[ERROR] Node.js was not found!%CLR_RESET%
    echo          Please install the LTS version from: https://nodejs.org
    goto fail
)

:: NODE.JS VERSION CONTROL (v18+)
node -e "if(parseInt(process.version.slice(1))<18)process.exit(1)" >nul 2>&1
if "!errorlevel!" neq "0" (
    for /f "tokens=*" %%v in ('node --version 2^>nul') do (
        echo   %CLR_FAIL%[ERROR] Node.js v18+ is required. Your version: %%v%CLR_RESET%
    )
    echo          Please update Node.js to the latest LTS version!
    goto fail
) else (
    for /f "tokens=*" %%v in ('node --version 2^>nul') do echo   %CLR_SUCCESS%[OK] Node.js detected: %%v%CLR_RESET%
)

:: PNPM CHECK
where pnpm >nul 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_WARN%[!] pnpm package manager not found. Installing globally via npm...%CLR_RESET%
    call npm install -g pnpm >> "%LOG_FILE%" 2>&1
    if "!errorlevel!" neq "0" (
        echo   %CLR_FAIL%[ERROR] Failed to install pnpm.%CLR_RESET%
        goto fail
    )
    for /f "tokens=*" %%p in ('npm config get prefix 2^>nul') do set "PATH=%%p;!PATH!"
    where pnpm >nul 2>&1
    if "!errorlevel!" neq "0" (
        echo   %CLR_FAIL%[ERROR] pnpm was installed, but PATH did not update.%CLR_RESET%
        echo          Close this window, open a new one, and re-run the script!
        goto fail
    )
)
for /f "tokens=*" %%v in ('pnpm --version 2^>nul') do echo   %CLR_SUCCESS%[OK] pnpm detected: v%%v%CLR_RESET%
echo.
exit /b

:kill_discord
echo %CLR_INFO%[2/4] Scanning and safely terminating Discord clients...%CLR_RESET%
set "DISCORD_FOUND=0"

for %%D in (Discord.exe DiscordPTB.exe DiscordCanary.exe DiscordDevelopment.exe) do (
    tasklist /FI "IMAGENAME eq %%D" 2>nul | find /I "%%D" >nul
    if "!errorlevel!" equ "0" (
        echo       %%D detected running. Terminating process...
        taskkill /F /IM %%D >> "%LOG_FILE%" 2>&1
        set "DISCORD_FOUND=1"
    )
)

if "!DISCORD_FOUND!" equ "1" (
    echo   %CLR_SUCCESS%[OK] Discord clients terminated.%CLR_RESET%
) else (
    echo   %CLR_TEXT%[INFO] No active Discord clients were running.%CLR_RESET%
)
echo.
exit /b

:git_operations
echo %CLR_INFO%[3/4] Downloading and updating source code (GitHub)...%CLR_RESET%

if exist "%INSTALL_DIR%\.git" (
    echo       MallCord found at %INSTALL_DIR%.
    echo       Creating automatic backup before updating...
    call :create_backup_silent

    echo       Downloading updates from GitHub (git fetch + reset)...
    git -C "%INSTALL_DIR%" fetch origin main >> "%LOG_FILE%" 2>&1
    if "!errorlevel!" neq "0" (
        echo   %CLR_FAIL%[ERROR] git fetch failed. Check your internet connection!%CLR_RESET%
        goto fail
    )
    git -C "%INSTALL_DIR%" reset --hard origin/main >> "%LOG_FILE%" 2>&1
    if "!errorlevel!" neq "0" (
        echo   %CLR_FAIL%[ERROR] git reset failed.%CLR_RESET%
        goto fail
    )
    echo   %CLR_SUCCESS%[OK] Local repository successfully synchronized with the latest version.%CLR_RESET%
) else if exist "%INSTALL_DIR%" (
    echo   %CLR_WARN%[!] The folder exists but is not a Git repository.%CLR_RESET%
    choice /C YN /M "  Can I delete the existing folder for a clean reinstallation?"
    if "!errorlevel!" equ "1" (
        rmdir /s /q "%INSTALL_DIR%"
        goto clone_repo
    ) else (
        echo   %CLR_FAIL%[OPERATION CANCELLED] Installation cannot proceed.%CLR_RESET%
        goto fail
    )
) else (
    :clone_repo
    echo       Clean install: Cloning MallCord from GitHub...
    git clone "%REPO_URL%" "%INSTALL_DIR%" >> "%LOG_FILE%" 2>&1
    if "!errorlevel!" neq "0" (
        echo   %CLR_FAIL%[ERROR] Cloning failed.%CLR_RESET%
        goto fail
    )
    echo   %CLR_SUCCESS%[OK] Cloning completed successfully.%CLR_RESET%
)
echo.
exit /b

:build_and_inject
echo %CLR_INFO%[4/4] Compiling and injecting MallCord...%CLR_RESET%
cd /d "%INSTALL_DIR%"

echo       Installing dependencies (pnpm install)...
call pnpm install --no-frozen-lockfile >> "%LOG_FILE%" 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_FAIL%[ERROR] pnpm install failed. Check the log file for details.%CLR_RESET%
    goto fail
)

echo       Building MallCord source code...
call pnpm build >> "%LOG_FILE%" 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_FAIL%[ERROR] Build process failed.%CLR_RESET%
    goto fail
)
echo   %CLR_SUCCESS%[OK] Successfully built.%CLR_RESET%

echo       Injecting into Discord clients...
call pnpm inject >> "%LOG_FILE%" 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_FAIL%[ERROR] Injection failed. Make sure Discord is installed!%CLR_RESET%
    goto fail
)
echo   %CLR_SUCCESS%[OK] MallCord successfully injected into Discord!%CLR_RESET%
echo.
exit /b

:uninject_and_clean
if not exist "%INSTALL_DIR%" (
    echo   %CLR_FAIL%[ERROR] MallCord installation not found at the specified location.%CLR_RESET%
    exit /b
)

cd /d "%INSTALL_DIR%"
echo       Removing MallCord from Discord clients (uninject)...
call pnpm uninject >> "%LOG_FILE%" 2>&1
if "!errorlevel!" neq "0" (
    echo   %CLR_WARN%[!] Uninject reported an error. It might have already been removed.%CLR_RESET%
) else (
    echo   %CLR_SUCCESS%[OK] Successfully removed from Discord.%CLR_RESET%
)

echo.
choice /C YN /M "  Would you like to delete the entire source code folder too (%INSTALL_DIR%)?"
if "!errorlevel!" equ "1" (
    echo       Deleting folder...
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
goto main_menu

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
goto main_menu

:: ============================================================================
:: ENDINGS
:: ============================================================================

:success_end
echo.
echo   %CLR_SUCCESS%=======================================================%CLR_RESET%
echo   %CLR_SUCCESS%   THE OPERATION COMPLETED SUCCESSFULLY!%CLR_RESET%
echo   %CLR_SUCCESS%   You can now start Discord.%CLR_RESET%
echo   %CLR_SUCCESS%=======================================================%CLR_RESET%
echo.
goto final_pause

:fail
echo.
echo   %CLR_FAIL%=======================================================%CLR_RESET%
echo   %CLR_FAIL%   AN ERROR OCCURRED DURING THE PROCESS!%CLR_RESET%
echo   %CLR_FAIL%   Check the detailed log: %LOG_FILE%%CLR_RESET%
echo   %CLR_FAIL%=======================================================%CLR_RESET%
echo.

:final_pause
pause
goto main_menu

:end
echo %CLR_INFO%Thank you for using Private MallCord Setup! Have a great day!%CLR_RESET%
timeout /t 3 >nul
endlocal
