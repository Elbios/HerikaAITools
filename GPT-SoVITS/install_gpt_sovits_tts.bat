@echo off
setlocal

echo HERIKA: Starting the GPT-SoVITS installation process

REM Define WSL parameters
set "WSL_NAME=DwemerAI4Skyrim3"
set "WSL_USER=dwemer"
set "INSTALL_SCRIPT_URL=https://raw.githubusercontent.com/Elbios/HerikaAITools/main/GPT-SoVITS/install_gpt_sovits_tts.sh"
set "INSTALL_SCRIPT_PATH=/home/%WSL_USER%/install_gpt_sovits_tts.sh"

REM Execute commands within WSL
echo HERIKA: Downloading the installation script from GitHub...
wsl -d %WSL_NAME% -u %WSL_USER% -- bash -c "wget -q -O %INSTALL_SCRIPT_PATH% %INSTALL_SCRIPT_URL%"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to download the installation script from GitHub.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Making the installation script executable...
wsl -d %WSL_NAME% -u %WSL_USER% -- chmod +x %INSTALL_SCRIPT_PATH%
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to make the installation script executable.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Executing the installation script in WSL...
wsl -d %WSL_NAME% -u %WSL_USER% -- bash %INSTALL_SCRIPT_PATH%
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Installation script encountered an error.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installation process completed successfully!
endlocal
pause
