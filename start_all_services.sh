#!/bin/bash

# Redirecting stdout and stderr to separate log files for koboldcpp
if [ "${SERVICE_OPTION}" = "koboldcpp" ]; then
    koboldcpp --usecublas ${KOBOLD_GPU_IDS} --gpulayers 99 --threads 7 --contextsize 2048 --skiplauncher --multiuser 5 --model /models/${LLM_FILENAME} > koboldcpp_log.txt 2>&1 &
fi

# Checking if VISION_MODEL is set to qwen and starting Qwen server (compatible with llamacpp/llava API)
if [ "${VISION_MODEL}" = "qwen" ]; then
    python run_qwen_server.py > qwen_vllm_log.txt 2>&1 &
elif [ "${VISION_MODEL}" = "llava_cpu" ]; then
    # Starting llava server with CPU support
    /llava/llava_server_cpu -m /models/mistral-7b-q_5_k.gguf --mmproj /models/mmproj-mistral7b-f16-q6_k.gguf -ngl 0 -c 4000 --host 0.0.0.0 --port 8007 > llava_cpu_log.txt 2>&1 &
elif [ "${VISION_MODEL}" = "llava_gpu" ]; then
    # Starting llava server with GPU CUDA support
    /llava/llava_server_gpu -m /models/mistral-7b-q_5_k.gguf --mmproj /models/mmproj-mistral7b-f16-q6_k.gguf -ngl 50 -c 4000 --host 0.0.0.0 --port 8007 > llava_gpu_log.txt 2>&1 &
fi

# Redirecting stdout and stderr to separate log files for whispercpp
cd /whispercpp/whisper.cpp && ./server -m models/${WHISPERCPP_MODEL_FILENAME} --host 0.0.0.0 --port 8070 --convert > whispercpp_log.txt 2>&1 &

# Run XTTS server
cd /xtts_app

# Checking if INCLUDE_TTS is set to true and starting xTTS server
if [ "${INCLUDE_TTS}" = "true" ]; then
    uvicorn main:app --host 0.0.0.0 --port 80 > tts_log.txt 2>&1 &
fi

# Keep the container running since background processes won't do it
wait
