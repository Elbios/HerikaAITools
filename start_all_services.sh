#!/bin/bash

# Redirecting stdout and stderr to separate log files for koboldcpp
koboldcpp --usecublas --gpulayers 99 --threads 7 --contextsize 2048 --noshift --skiplauncher --multiuser 5 --model /models/dolphin-2_6-phi-2.Q2_K.gguf > koboldcpp_log.txt 2>&1 &

# Redirecting stdout and stderr to separate log files for whispercpp
cd /whispercpp/whisper.cpp && ./server -m models/${WHISPERCPP_MODEL_FILENAME} --host 0.0.0.0 --port 8070 > whispercpp_log.txt 2>&1 &

# Run XTTS server
cd /xtts_app

# Checking if INCLUDE_TTS is set to true and starting xTTS server
if [ "${INCLUDE_TTS}" = "true" ]; then
    uvicorn main:app --host 0.0.0.0 --port 80 > tts_log.txt 2>&1 &
fi

# Keep the container running since background processes won't do it
wait