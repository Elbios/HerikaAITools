# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive
# Argument to control the inclusion of TTS
ARG INCLUDE_TTS=false
ARG SERVICE_OPTION=koboldcpp
# New ARG for whispercpp model option
ARG WHISPERCPP_MODEL=base.en
ENV WHISPERCPP_MODEL_FILENAME=ggml-base.en.bin

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

# Install Python packages
RUN python -m pip install --use-deprecated=legacy-resolver -r requirements.txt \
    && python -m pip cache purge

# Conditional TTS setup
RUN if [ "${INCLUDE_TTS}" = "true" ]; then \
        python -m unidic download; \
        mkdir -p /xtts_app/tts_models; \
        # Additional TTS setup steps here (remove this line if no additional steps are required)
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
        wget -q -O /models/dolphin-2_6-phi-2.Q2_K.gguf https://huggingface.co/TheBloke/dolphin-2_6-phi-2-GGUF/resolve/main/dolphin-2_6-phi-2.Q2_K.gguf?download=true \
    ; fi

WORKDIR /whispercpp

# Installation of whispercpp and downloading the specified model
RUN git clone https://github.com/ggerganov/whisper.cpp.git && \
    cd whisper.cpp && \
    make -j && \
    bash ./models/download-ggml-model.sh ${WHISPERCPP_MODEL}

WORKDIR /home/ubuntu

## Copy the start_all_services.sh script into the container
#COPY start_all_services.sh /app
## Make sure the script is executable
#RUN chmod +x /app/start_all_services.sh

# Replace the final CMD with the new entry point script
CMD ["bash start_all_services.sh"]