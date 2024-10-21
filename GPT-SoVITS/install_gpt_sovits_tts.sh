#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Prevent errors in a pipeline from being masked

echo "HERIKA: Starting the GPT-SoVITS installation"

WSL_USER="dwemer"
HOME_DIR="/home/$WSL_USER"

# Update and install required packages
echo "HERIKA: Updating and installing packages..."
sudo apt-get update
sudo apt-get install -y gcc g++ ffmpeg cmake p7zip-full git wget

# Install Miniconda if not already installed
echo "HERIKA: Installing Miniconda..."
if [ ! -d "$HOME_DIR/miniconda3" ]; then
    echo "Miniconda not found. Installing..."
    mkdir -p "$HOME_DIR/miniconda3"
    wget -nc https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$HOME_DIR/miniconda3/miniconda.sh"
    bash "$HOME_DIR/miniconda3/miniconda.sh" -b -u -p "$HOME_DIR/miniconda3"
else
    echo "Miniconda is already installed. Skipping installation."
fi

# Initialize Conda
export PATH="$HOME_DIR/miniconda3/bin:$PATH"
source "$HOME_DIR/miniconda3/etc/profile.d/conda.sh"

# Clone or update GPT-SoVITS repository
echo "HERIKA: Cloning or Updating GPT-SoVITS repository..."
cd "$HOME_DIR"
if [ -d "GPT-SoVITS" ]; then
    echo "GPT-SoVITS repository already exists. Pulling latest changes..."
    cd GPT-SoVITS
    git pull
else
    echo "Cloning GPT-SoVITS repository..."
    git clone https://github.com/RVC-Boss/GPT-SoVITS.git
    cd GPT-SoVITS
fi

# Set up Conda environment
echo "HERIKA: Setting up Conda environment..."
if ! conda env list | grep -q "^GPTSoVits\s"; then
    echo "Creating Conda environment GPTSoVits..."
    conda create -n GPTSoVits python=3.9 -y
else
    echo "Conda environment GPTSoVits already exists. Skipping creation."
fi

echo "Activating Conda environment GPTSoVits..."
conda activate GPTSoVits

echo "Running install.sh..."
bash install.sh

# Download and extract pretrained models
echo "HERIKA: Downloading and extracting pretrained models..."
PRETRAINED_MODELS_DIR="$HOME_DIR/GPT-SoVITS/GPT_SoVITS/pretrained_models"
if [ ! -d "$PRETRAINED_MODELS_DIR" ]; then
    echo "Pretrained models not found. Downloading and extracting..."
    cd "$HOME_DIR"
    wget -nc https://huggingface.co/lj1995/GPT-SoVITS-windows-package/resolve/main/GPT-SoVITS-v2-240821.7z -O GPT-SoVITS-v2-240821.7z
    if [ -f GPT-SoVITS-v2-240821.7z ]; then
        7z x GPT-SoVITS-v2-240821.7z GPT-SoVITS-v2-240821/GPT_SoVITS/pretrained_models/
        mv GPT-SoVITS-v2-240821/GPT_SoVITS/pretrained_models "$HOME_DIR/GPT-SoVITS/GPT_SoVITS/"
        rm -rf GPT-SoVITS-v2-240821.7z GPT-SoVITS-v2-240821
    else
        echo "ERROR: Pretrained models archive not found after download."
        exit 1
    fi
else
    echo "Pretrained models already exist. Skipping download and extraction."
fi

# Add optional CPU inference config
echo "HERIKA: Adding optional CPU inference config..."
CONFIG_FILE="$HOME_DIR/GPT-SoVITS/GPT_SoVITS/configs/tts_infer_cpu.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating CPU inference configuration..."
    cp "$HOME_DIR/GPT-SoVITS/GPT_SoVITS/configs/tts_infer.yaml" "$CONFIG_FILE"
    sed -i 's/device: cuda/device: cpu/g; s/is_half: true/is_half: false/g' "$CONFIG_FILE"
else
    echo "CPU inference configuration already exists. Skipping."
fi

echo "HERIKA: Installation completed successfully!"
