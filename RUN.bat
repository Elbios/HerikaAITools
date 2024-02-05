@echo off
setlocal

echo Starting Docker daemon...
wsl -d DwemerAI4Skyrim2 -e sudo nohup dockerd > docker.log 2>&1 &
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to start Docker daemon. Please check the log above for details.
    exit /b %ERRORLEVEL%
)
timeout /t 5 /nobreak > NUL

echo Building Docker image...
wsl -d DwemerAI4Skyrim2 -e bash -c "cd /home/dwemer/HerikaAITools && docker build . --build-arg INCLUDE_TTS=true -t herikadocker"
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to build Docker image. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Running Docker container...
wsl -d DwemerAI4Skyrim2 -e bash -c "cd /home/dwemer/HerikaAITools && docker run --gpus all -d -e SERVICE_OPTION=koboldcpp -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -v \$(pwd):/home/ubuntu --name herikadocker herikadocker"
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to run Docker container. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo AI servers running - press CTRL+C here when done playing Skyrim to close this window.
pause > NUL

echo Cleaning up WSL state...
wsl -t DwemerAI4Skyrim2
if NOT %ERRORLEVEL% == 0 (
    echo ERROR: Failed to terminate WSL instance. Please check the log above for details.
    exit /b %ERRORLEVEL%
)

echo Cleanup completed successfully.
endlocal