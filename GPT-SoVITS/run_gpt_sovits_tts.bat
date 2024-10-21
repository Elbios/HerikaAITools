@echo off
setlocal

REM =============================================================================
REM Run the GPT-SoVITS API server in WSL
REM =============================================================================

REM Define variables
SET WSL_DISTRO=DwemerAI4Skyrim3
SET WSL_USER=dwemer

REM =============================================================================
REM Step 1: Activate Conda environment and run the API server
REM =============================================================================

echo Starting GPT-SoVITS API server...

REM Navigate to project directory and run the server
wsl -d %WSL_DISTRO% -e bash -c "source /home/dwemer/miniconda3/bin/activate && conda activate GPTSoVits && cd /home/dwemer/GPT-SoVITS && python api_v2.py -a 0.0.0.0 -p 9880 -c GPT_SoVITS/configs/tts_infer.yaml"

if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to start the GPT-SoVITS API server. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo GPT-SoVITS API server is running successfully!

endlocal
pause
