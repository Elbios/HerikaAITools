@echo off
setlocal

echo Starting the installation of your App...

echo Updating package lists...
wsl -d DwemerAI4Skyrim2 -e sudo apt update
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to update package lists. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Installing curl...
wsl -d DwemerAI4Skyrim2 -e sudo apt install -y curl
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to install curl. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Downloading Docker install script...
wsl -d DwemerAI4Skyrim2 -e cd /home/dwemer && curl -fsSL https://get.docker.com -o get-docker.sh
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to download Docker install script. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Installing Docker...
wsl -d DwemerAI4Skyrim2 -e cd /home/dwemer && sudo sh get-docker.sh
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to install Docker. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Adding user to the Docker group...
wsl -d DwemerAI4Skyrim2 -e sudo usermod -aG docker $USER
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to add user to Docker group. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Setting up NVIDIA Container Toolkit...
wsl -d DwemerAI4Skyrim2 -e bash -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to setup NVIDIA Container Toolkit. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Updating package lists again...
wsl -d DwemerAI4Skyrim2 -e sudo apt-get update
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to update package lists again. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Installing NVIDIA Container Toolkit...
wsl -d DwemerAI4Skyrim2 -e sudo apt-get install -y nvidia-container-toolkit
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to install NVIDIA Container Toolkit. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Cloning HerikaAITools repository...
wsl -d DwemerAI4Skyrim2 -e cd /home/dwemer && git clone https://github.com/Elbios/HerikaAITools.git
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to clone repository. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Installation completed successfully!
endlocal
pause