@echo off
setlocal

echo HERIKA: Starting the GPT-SoVITS installation

set WSL_NAME=DwemerAI4Skyrim3
set WSL_USER=dwemer

echo HERIKA: Updating and installing packages...
wsl -d %WSL_NAME% -u %WSL_USER% -e sudo apt-get update
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to update package lists. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

wsl -d %WSL_NAME% -u %WSL_USER% -e sudo apt-get install -y gcc g++ ffmpeg cmake
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to install required packages. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installing Miniconda...
wsl -d %WSL_NAME% -u %WSL_USER% -e bash -c "mkdir -p /home/dwemer/miniconda3 && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/dwemer/miniconda3/miniconda.sh && bash /home/dwemer/miniconda3/miniconda.sh -b -u -p /home/dwemer/miniconda3"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to install Miniconda. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Cloning GPT-SoVITS repository...
wsl -d %WSL_NAME% -u %WSL_USER% -e bash -c "cd /home/dwemer && git clone https://github.com/RVC-Boss/GPT-SoVITS.git"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to clone GPT-SoVITS repository. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Setting up Conda environment...
wsl -d %WSL_NAME% -u %WSL_USER% -e bash -c "source /home/dwemer/miniconda3/bin/activate && cd /home/dwemer/GPT-SoVITS && conda create -n GPTSoVits python=3.9 -y && conda activate GPTSoVits && bash install.sh"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to set up Conda environment or run install script. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installing 7zip...
wsl -d %WSL_NAME% -u %WSL_USER% -e sudo apt-get install -y p7zip-full
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to install 7zip. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Downloading and extracting pretrained models...
wsl -d %WSL_NAME% -u %WSL_USER% -e bash -c "cd /home/dwemer && wget https://huggingface.co/lj1995/GPT-SoVITS-windows-package/resolve/main/GPT-SoVITS-v2-240821.7z && 7z x GPT-SoVITS-v2-240821.7z GPT-SoVITS-v2-240821/GPT_SoVITS/pretrained_models/ && mv /home/dwemer/GPT-SoVITS-v2-240821/GPT_SoVITS/pretrained_models /home/dwemer/GPT-SoVITS/GPT_SoVITS/ && rm -rf /home/dwemer/GPT-SoVITS-v2-240821.7z /home/dwemer/GPT-SoVITS-v2-240821"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to download or extract pretrained models. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Adding optional CPU inference config...
wsl -d %WSL_NAME% -u %WSL_USER% -e bash -c "cd /home/dwemer/GPT-SoVITS/GPT_SoVITS/configs && cp tts_infer.yaml tts_infer_cpu.yaml && sed -i 's/device: cuda/device: cpu/g; s/is_half: true/is_half: false/g' tts_infer_cpu.yaml"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to configure YAML for CPU inference. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Installation completed successfully!
endlocal
pause