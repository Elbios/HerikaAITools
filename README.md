# Local AI services for Herika

## Requirements
- NVIDIA GPU

- Herika DwemerDistro from Nexus installed (with name DwemerAI4Skyrim2)

- Potentially a lot of disk space (tens of GB) and RAM depending on selected options
### What is included
- Pytorch Docker with CUDA ready to go

- localwhisper STT (whispercpp, CPU or GPU mode, base.en by default)

- koboldcpp loaded with a small model for testing (Toppy-7B-q4_k_s)

- XTTSv2 for TTS (official Coqui version of API server)

- vision model (Qwen or Llava 1.6 or MiniCPM-V-2_6)

All parts are optional, .bat scripts ask you what to include, otherwise you can modify top part of Dockerfile (the ARG and ENV arguments)

### NEW README:

Run Install.bat, wait until it completes.

Run RUN.bat.

May take a very long time depending on network speed. 

TIP: RAM usage can be high. To mitigate that, update WSL to latest:

`wsl --update --pre-release`

and optionally, create `C:/Users/<USER>/.wslconfig` text file with:
```
[wsl2]
memory=12GB
```
That will limit maximum RAM use for all WSL to 12GB.

TIP: best way to refresh WSL/fix random WSL issues is restarting Windows, second best is `wsl --shutdown` and waiting at least 10 seconds

TIP: use `wsl hostname -I` to find out your WSL IP - use that to access backend services in browser on host


### DEBUGGING:
`wsl -d DwemerAI4Skyrim2`

then

`cd /home/ubuntu`

you'll find koboldcpp, qwen, llava, xtts and whispercpp logs. You can also get a shell into Docker and poke around:

`docker exec -it herikadocker bash`

Also this:

`docker ps`

`docker logs herikadocker`

### USING XTTS WITH HERIKA:

Check if Coqui XTTS server is running by going to http://localhost:80 on your Windows host (if it fails, check also http://WSL_IP:80 where WSL_IP is result of `wsl hostname -I`)

On the XTTS webpage:

- go to clone_speaker -> Try it

- choose .wav file with your reference voice audio sample (5-10seconds maximum, best to have it converted to 22050Hz and Mono, you can use Audacity for that)

- wait for it to clone and you should get an output JSON file, name it 'my_voice.json' and save it in:

`\\wsl.localhost\DwemerAI4Skyrim2\var\www\html\HerikaServer\tts\data`
folder

Then in conf.php for Herika set:

```
$TTSFUNCTION='xtts';
$TTS["XTTS"]["endpoint"]='http://localhost:80/';	//End point
$TTS["XTTS"]["language"]='en';	//
$TTS["XTTS"]["voiceid"]='my_voice';	//Voice json file
```

That's it!

You can also try female_young_eager.json in this repo as an example voice, without having to go through the cloning process. In conf.php, voiceid will be 'female_young_eager'.


### OLD README BELOW (ignore):

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
#### MISCELLANEOUS:

Assign specific GPU to koboldcpp (e.g. GPU0) - use KOBOLD_GPU_IDS env var:
`docker run --gpus all -d -e KOBOLD_GPU_IDS="0" -e SERVICE_OPTION=koboldcpp -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -v $(pwd):/home/ubuntu --name herikadocker herikadocker`
(can also use "0 1" to use two GPUs for koboldcpp)

Assign specific GPU to XTTS (e.g GPU1) - use CUDA_VISIBLE_DEVICES env var:
`docker run --gpus all -d -e CUDA_VISIBLE_DEVICES=1 -e KOBOLD_GPU_IDS="0 1" -e SERVICE_OPTION=koboldcpp -e INCLUDE_TTS=true -p 5001:5001 -p 8070:8070 -p 80:80 -v $(pwd):/home/ubuntu --name herikadocker herikadocker`
