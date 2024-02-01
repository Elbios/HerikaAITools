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

Build Docker container:

`docker build . --build-arg INCLUDE_TTS=true -t herikadocker`

Run Docker container:

 `docker run --gpus all -d -e INCLUDE_TTS=true -v $(pwd):/home/ubuntu --name herikadocker herikadocker`

 (if on Windows, replace $(pwd) with your current directory where the Dockerfile is)

 If you make any changes to Dockerfile:
 Rebuild:
 `docker build . --build-arg INCLUDE_TTS=true -t herikadocker`
 Rerun:
 `docker rm -f herikadocker`
 `docker run --gpus all -d -e INCLUDE_TTS=true -v $(pwd):/home/ubuntu --name herikadocker herikadocker`
 
That's all!

If you want to get a shell into the container to debug stuff:

 `docker exec -it herikadocker bash`

If you want to change configurational variables, either use --build-arg when building or edit ARG lines in Dockerfile