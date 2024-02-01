# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive
# Argument to control the inclusion of TTS
ARG INCLUDE_TTS=false

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
CMD if [ "${INCLUDE_TTS}" = "true" ]; then \
        (uvicorn main:app --host 0.0.0.0 --port 80 > tts_log.txt 2>&1 &) \
    ; fi

# Here you can add the setup for other AI tools and services
# For example:
# RUN python -m pip install some-other-ai-tool

# The final CMD should start all necessary services, including those conditionally started above
CMD ["bash", "start_all_services.sh"]