NEW README:

Run Install.bat.
Run RUN.bat.
May take a very long time depending on network speed. 


OLD README BELOW:

Install Docker on Linux:
```
sudo apt update
sudo apt install curl
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
(takes a few minutes to complete)
sudo usermod -aG docker $USER
newgrp docker

(the following is one big multiline command, copy and press enter)

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

sudo nohup dockerd > docker.log 2>&1 &
```

(last line not necessary when you have systemd)

----------------------------------------------------------------------------------------------------------
Clone this repository:

`git clone https://github.com/Elbios/HerikaAITools.git && cd HerikaAITools`

Build Docker container:

`docker build . --build-arg INCLUDE_TTS=true --build-arg SERVICE_OPTION=koboldcpp --build-arg VISION_MODEL=qwen -t herikadocker`

or, if you want to just build XTTS without kobold or Qwen:

`docker build . --build-arg INCLUDE_TTS=true -t herikadocker`

Run Docker container (use same flags as when you built, just with -e this time):

 `docker run --gpus all -d -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -p 8007:8007 -v $(pwd):/home/ubuntu --name herikadocker herikadocker`

 (if on Windows, replace $(pwd) with your current directory where the Dockerfile is)

-----------------------------------------------------------------------------------------------------------
 If you make any changes to Dockerfile:
 Rebuild (adjust flags):

 `docker build . --build-arg INCLUDE_TTS=true -t herikadocker`

 Rerun (adjust flags):

 `docker rm -f herikadocker`

 `docker run --gpus all -d -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -p 8007:8007 -v $(pwd):/home/ubuntu --name herikadocker herikadocker`
 
That's all!

If you want to get a shell into the container to debug stuff:

 `docker exec -it herikadocker bash`

And look at *.log files.

If you want to change configurational variables, either use --build-arg when building or edit ARG lines in Dockerfile

--------------------------------------------------------------------------------------------------------
MISCELLANEOUS:

Assign specific GPU to koboldcpp (e.g. GPU0) - use KOBOLD_GPU_IDS env var:
`docker run --gpus all -d -e KOBOLD_GPU_IDS="0" -e SERVICE_OPTION=koboldcpp -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -v $(pwd):/home/ubuntu --name herikadocker herikadocker`
(can also use "0 1" to use two GPUs for koboldcpp)

Assign specific GPU to XTTS (e.g GPU1) - use CUDA_VISIBLE_DEVICES env var:
`docker run --gpus all -d -e CUDA_VISIBLE_DEVICES=1 -e KOBOLD_GPU_IDS="0 1" -e SERVICE_OPTION=koboldcpp -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -v $(pwd):/home/ubuntu --name herikadocker herikadocker`
