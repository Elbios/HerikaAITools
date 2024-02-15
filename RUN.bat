@echo off
setlocal

set /p IncludeTTS=Do you want to run XTTS? (y/n):
set /p ServiceOption=Do you want to run koboldcpp? (y/n):
set /p VisionModel=Which vision model do you want to run? (qwen/llava_cpu/llava_gpu/none):

echo HERIKA: Checking if Docker daemon is running...

REM Check if dockerd is running
wsl -d DwemerAI4Skyrim2 -- pgrep dockerd >nul 2>&1
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: Docker daemon not running.
    wsl -d DwemerAI4Skyrim2 -e nohup sh -c "dockerd &"
    echo HERIKA: Started Docker daemon.
) ELSE (
    echo HERIKA: Docker daemon already running.
)

echo HERIKA: Building Docker image...

if /i "%VisionModel%"=="qwen" (
    set VisionArg=--build-arg VISION_MODEL=qwen
    set VisionArg2=-e VISION_MODEL=qwen
) else if /i "%VisionModel%"=="llava_cpu" (
    set VisionArg=--build-arg VISION_MODEL=llava_cpu
    set VisionArg2=-e VISION_MODEL=llava_cpu
) else if /i "%VisionModel%"=="llava_gpu" (
    set VisionArg=--build-arg VISION_MODEL=llava_gpu
    set VisionArg2=-e VISION_MODEL=llava_gpu
) else if /i "%VisionModel%"=="none" (
    set VisionArg=
    set VisionArg2=
) else (
    echo Invalid option. Exiting script.
    exit /b 1
)

if /i "%IncludeTTS%"=="y" (
    set TTSArg=--build-arg INCLUDE_TTS=true
    set TTSArg2=-e INCLUDE_TTS=true
) else (
    set TTSArg=
    set TTSArg2=
)

if /i "%ServiceOption%"=="y" (
    set ServiceOptionArg=--build-arg SERVICE_OPTION=koboldcpp
    set ServiceOptionArg2=-e SERVICE_OPTION=koboldcpp
) else (
    set ServiceOptionArg=
    set ServiceOptionArg2=
)

wsl -d DwemerAI4Skyrim2 -e bash -c "cd /home/dwemer/HerikaAITools && docker build . %TTSArg% %ServiceOptionArg% %VisionArg% -t herikadocker"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to build Docker image. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Running Docker container...
wsl -d DwemerAI4Skyrim2 -e bash -c "cd /home/dwemer/HerikaAITools && docker rm -f herikadocker"
wsl -d DwemerAI4Skyrim2 -e bash -c "cd /home/dwemer/HerikaAITools && docker run --gpus all -d %TTSArg2% %ServiceOptionArg2% %VisionArg2% -p 5001:5001 -p 8070:8070 -p 80:80 -p 8007:8007 -v /home/dwemer/HerikaAITools:/home/ubuntu --name herikadocker herikadocker"
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to run Docker container. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: AI servers running - press CTRL+C here when done playing Skyrim to close this window.
pause > NUL

echo HERIKA: Cleaning up WSL state...
wsl -t DwemerAI4Skyrim2
if NOT %ERRORLEVEL% == 0 (
    echo HERIKA: ERROR: Failed to terminate WSL instance. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo HERIKA: Cleanup completed successfully.
endlocal