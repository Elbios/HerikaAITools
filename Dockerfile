# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive
# Argument to control the inclusion of TTS
ARG INCLUDE_TTS=false
ARG SERVICE_OPTION=koboldcpp
# New ARG for whispercpp model option
ARG WHISPERCPP_MODEL=base.en

# Common dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y sox libsox-fmt-all curl wget gcc git git-lfs build-essential libaio-dev libsndfile1 ssh ffmpeg && \
    apt-get clean && apt-get -y autoremove


# Set work directory
WORKDIR /app

# Copy requirements for Python packages
COPY requirements.txt .

# Install Python packages
RUN python -m pip install --use-deprecated=legacy-resolver -r requirements.txt \
    && python -m pip cache purge

# Conditional TTS setup
RUN if [ "${INCLUDE_TTS}" = "true" ]; then \
        python -m unidic download && \
        mkdir -p /app/tts_models && \
        # Additional TTS setup steps here \
    ; fi

# Copy the start_all_services.sh script into the container
COPY start_all_services.sh /app
# Make sure the script is executable
RUN chmod +x /app/start_all_services.sh
# Copy main script for TTS
COPY main.py .

# Environment variables for TTS
ENV NVIDIA_DISABLE_REQUIRE=0
ENV NUM_THREADS=2

# Expose port 80 only if TTS is included
RUN if [ "${INCLUDE_TTS}" = "true" ]; then \
        EXPOSE 80 \
    ; fi

# Conditional CMD to run the TTS server in the background
# and pipe its stdout and stderr to a log file
#CMD if [ "${INCLUDE_TTS}" = "true" ]; then \
#        (uvicorn main:app --host 0.0.0.0 --port 80 > tts_log.txt 2>&1 &) \
#    ; fi

# Here you can add the setup for other AI tools and services
# For example:
# RUN python -m pip install some-other-ai-tool

RUN if [ "${SERVICE_OPTION}" = "koboldcpp" ]; then \
        curl -fLo /usr/bin/koboldcpp https://koboldai.org/cpplinux && chmod +x /usr/bin/koboldcpp && \
        wget -q -O /models/dolphin-2_6-phi-2.Q2_K.gguf https://huggingface.co/TheBloke/dolphin-2_6-phi-2-GGUF/resolve/main/dolphin-2_6-phi-2.Q2_K.gguf?download=true \
    ; fi

WORKDIR /whispercpp

# Installation of whispercpp and downloading the specified model
RUN git clone https://github.com/ggerganov/whisper.cpp.git && \
    cd whisper.cpp && \
    make && \
    bash ./models/download-ggml-model.sh ${WHISPERCPP_MODEL}

# Replace the final CMD with the new entry point script
CMD ["/app/start_all_services.sh"]