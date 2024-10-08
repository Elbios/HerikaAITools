# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive
# Argument to control the inclusion of TTS
ARG INCLUDE_TTS=false
# Use SERVICE_OPTION=none to disable
ARG SERVICE_OPTION=none
# Use VISION_MODEL=none to disable
ARG VISION_MODEL=none
# New ARG for whispercpp model option
ARG WHISPER_MODE=cpu
ARG WHISPERCPP_MODEL=base.en
ENV WHISPERCPP_MODEL_FILENAME=ggml-base.en.bin
# Filename of LLM, like: dolphin-2_6-phi-2.Q2_K.gguf (fill in both)
#ARG LLM_FILENAME=dolphin-2_6-phi-2.Q2_K.gguf
#ENV LLM_FILENAME=dolphin-2_6-phi-2.Q2_K.gguf
ARG LLM_FILENAME=toppy-m-7b.Q4_K_S.gguf
ENV LLM_FILENAME=toppy-m-7b.Q4_K_S.gguf
# Huggingface link to LLM, like: https://huggingface.co/TheBloke/dolphin-2_6-phi-2-GGUF/resolve/main/dolphin-2_6-phi-2.Q2_K.gguf?download=true
#ARG LLM_DOWNLOAD_LINK=https://huggingface.co/TheBloke/dolphin-2_6-phi-2-GGUF/resolve/main/dolphin-2_6-phi-2.Q2_K.gguf?download=true
ARG LLM_DOWNLOAD_LINK=https://huggingface.co/TheBloke/Toppy-M-7B-GGUF/resolve/main/toppy-m-7b.Q4_K_S.gguf?download=true

RUN useradd -m ubuntu

# Common dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y sox libsox-fmt-all curl wget gcc git git-lfs build-essential libaio-dev libsndfile1 ssh ffmpeg && \
    apt-get clean && apt-get -y autoremove


# Set work directory for XTTS
WORKDIR /xtts_app

# Copy main script for TTS
COPY main.py .
# Copy requirements for Python packages for TTS
COPY requirements.txt .

# Conditional TTS setup
RUN if [ "${INCLUDE_TTS}" = "true" ]; then \
		python -m pip install --use-deprecated=legacy-resolver -r requirements.txt \
		&& python -m pip cache purge && \
        python -m unidic download; \
        mkdir -p /xtts_app/tts_models; \
    fi
	
# Environment variables for TTS
ENV NVIDIA_DISABLE_REQUIRE=0
ENV NUM_THREADS=2
ENV COQUI_TOS_AGREED=1
# XTTS exported on port 80 within Docker
EXPOSE 80

RUN if [ "${SERVICE_OPTION}" = "koboldcpp" ]; then \
        curl -fLo /usr/bin/koboldcpp https://koboldai.org/cpplinux && chmod +x /usr/bin/koboldcpp && \
		mkdir -p /models && \
        wget -q -O /models/${LLM_FILENAME} ${LLM_DOWNLOAD_LINK} \
    ; fi

WORKDIR /whispercpp

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/opt/cuda/lib64:/usr/lib/x86_64-linux-gnu:/usr/local/cuda-12.1/compat:$LD_LIBRARY_PATH
# Installation of whispercpp and downloading the specified model
RUN if [ "${WHISPER_MODE}" != "none" ]; then \
    git clone https://github.com/ggerganov/whisper.cpp.git && \
    cd whisper.cpp && \
    export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH && \
    if [ "${WHISPER_MODE}" = "cuda" ]; then \
        GGML_CUDA=1 make -j; \
    else \
        GGML_CUDA=0 make -j; \
    fi && \
    bash ./models/download-ggml-model.sh ${WHISPERCPP_MODEL}; \
fi

WORKDIR /llava
COPY llava_server_cpu .
COPY llava_server_cuda .

WORKDIR /qwen
COPY qwen_requirements.txt .

# Install dependencies for Qwen vision model (for Herika Soulgaze) if selected
RUN if [ "${VISION_MODEL}" = "qwen" ]; then \
        pip install -r qwen_requirements.txt && \
        pip install flask optimum gekko auto-gptq tiktoken transformers_stream_generator accelerate einops olefile; \
    elif [ "${VISION_MODEL}" = "llava_cpu" ] || [ "${VISION_MODEL}" = "llava_gpu" ]; then \
        mkdir -p /models && \
        curl -L https://huggingface.co/cmp-nct/llava-1.6-gguf/resolve/main/mistral-7b-q_5_k.gguf?download=true -o /models/mistral-7b-q_5_k.gguf && \
        curl -L https://huggingface.co/cmp-nct/llava-1.6-gguf/blob/main/mmproj-mistral7b-f16.gguf -o /models/mmproj-mistral7b-f16.gguf; \
    elif [ "${VISION_MODEL}" = "minicpm" ]; then \
        if [ ! -f /usr/bin/koboldcpp ]; then \
            curl -fLo /usr/bin/koboldcpp https://koboldai.org/cpplinux && chmod +x /usr/bin/koboldcpp; \
        fi && \
        mkdir -p /models && \
        curl -L https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf/resolve/main/ggml-model-Q4_K_M.gguf?download=true -o /models/ggml-model-Q4_K_M.gguf && \
        curl -L https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf/resolve/main/mmproj-model-f16.gguf?download=true -o /models/mmproj-model-f16.gguf; \
    fi

WORKDIR /home/ubuntu

CMD ["bash", "start_all_services.sh"]
