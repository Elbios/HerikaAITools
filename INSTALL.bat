@echo off
setlocal

echo HERIKA: Starting the installation

set /p HERIKA_VERSION=Are you using OG Herika or AIFF? (Herika/AIFF): 

if /i "%HERIKA_VERSION%"=="Herika" (
    set WSL_NAME=DwemerAI4Skyrim2
) else if /i "%HERIKA_VERSION%"=="AIFF" (
    set WSL_NAME=DwemerAI4Skyrim3
) else (
    echo Error: Invalid input. Please enter either Herika or AIFF.
    pause
    exit /b 1
)

echo HERIKA: Cloning HerikaAITools repository...
wsl -d %WSL_NAME% -e bash -c "cd /home/dwemer && rm -rf HerikaAITools && git clone https://github.com/Elbios/HerikaAITools.git"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to clone repository. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Checking if Docker is installed...
wsl -d %WSL_NAME% -e bash -c "command -v docker"
if %ERRORLEVEL% == 0 (
    echo HERIKA: Docker command exists, assuming all dependencies already installed. Exiting script.
    pause
    exit /b 0
)

echo HERIKA: Updating package lists...
wsl -d %WSL_NAME% -e sudo apt update
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to update package lists. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installing curl...
wsl -d %WSL_NAME% -e sudo apt install -y curl
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to install curl. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Downloading Docker install script...
wsl -d %WSL_NAME% -e bash -c "cd /home/dwemer && curl -fsSL https://get.docker.com -o get-docker.sh"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to download Docker install script. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installing Docker...
wsl -d %WSL_NAME% -e bash -c "cd /home/dwemer && sudo sh get-docker.sh"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to install Docker. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Setting up NVIDIA Container Toolkit...
wsl -d %WSL_NAME% -e bash -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to setup NVIDIA Container Toolkit. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Updating package lists again...
wsl -d %WSL_NAME% -e sudo apt-get update
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to update package lists again. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installing NVIDIA Container Toolkit...
wsl -d %WSL_NAME% -e sudo apt-get install -y nvidia-container-toolkit
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to install NVIDIA Container Toolkit. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

::echo HERIKA: Enabling systemd in /etc/wsl.conf...
:::: Check if /etc/wsl.conf exists
::wsl -d %WSL_NAME% -e test -f /etc/wsl.conf
::if NOT %ERRORLEVEL% == 0 (
::    :: Append the necessary lines to /etc/wsl.conf
::    wsl -d %WSL_NAME% echo "[boot]" | sudo tee -a /etc/wsl.conf >nul
::    wsl -d %WSL_NAME% echo "systemd=true" | sudo tee -a /etc/wsl.conf >nul
::
::    if NOT %ERRORLEVEL% == 0 (
::        echo ERROR: Failed to modify /etc/wsl.conf. Please check your permissions.
::        pause
::        exit /b %ERRORLEVEL%
::    )
::)
wsl -t %WSL_NAME%

echo HERIKA: Installation completed successfully!
endlocal
pause