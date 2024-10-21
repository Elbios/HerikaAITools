@echo off
setlocal

REM =============================================================================
REM Run the GPT-SoVITS API server in WSL
REM =============================================================================

REM Define variables
SET WSL_DISTRO=DwemerAI4Skyrim3
SET WSL_USER=dwemer

REM =============================================================================
REM Step 1: Ask user if they want to use GPU mode or CPU mode
REM =============================================================================

set /p MODE=Do you want to run in GPU mode or CPU mode? (gpu/cpu): 

if /i "%MODE%"=="gpu" (
    set CONFIG_FILE=GPT_SoVITS/configs/tts_infer.yaml
) else if /i "%MODE%"=="cpu" (
    set CONFIG_FILE=GPT_SoVITS/configs/tts_infer_cpu.yaml
) else (
    echo ERROR: Invalid option. Please enter either 'gpu' or 'cpu'.
    pause
    exit /b 1
)

REM =============================================================================
REM Step 2: Activate Conda environment and run the API server
REM =============================================================================

echo Starting GPT-SoVITS API server in %MODE% mode...

REM Navigate to project directory and run the server
wsl -d %WSL_DISTRO% -e bash -c "source /home/dwemer/miniconda3/bin/activate && conda activate GPTSoVits && cd /home/dwemer/GPT-SoVITS && python api_v2.py -a 0.0.0.0 -p 9880 -c %CONFIG_FILE%"

if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to start the GPT-SoVITS API server. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo GPT-SoVITS API server is running successfully!

endlocal
pause
