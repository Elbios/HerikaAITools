# Quick Guide

1. **Download and Install**  
   - Download the `.BAT` install script and run it. Ensure it completes successfully and that you have sufficient disk space, as this may take a while.  
   - [Installation Script](https://github.com/Elbios/HerikaAITools/tree/main/GPT-SoVITS)

2. **Download and Run Script**  
   - Download the run script and execute it.  
   - [Run Script](https://github.com/Elbios/HerikaAITools/tree/main/GPT-SoVITS)

3. **Update TTS File**  
   - Download `SOVIET_TTS_AS_XTTS_FASTAPI.php` and replace the file located at:
     ```
     \\wsl.localhost\DwemerAI4Skyrim3\var\www\html\HerikaServer\tts\tts-xtts-fastapi.php
     ```

4. **Configure Dwemer TTS Settings**  
   - Set the TTS configuration page to use `xtts fastapi`.

5. **Prepare Dependencies**  
   - Place all 400 `.wav` files in the following folder:
     ```
     \\wsl.localhost\DwemerAI4Skyrim3\home\dwemer\speakers-GPT-SoVITS
     ```
   - Ensure files are loose within `speakers-GPT-SoVITS` (do not use an `en` folder).
   - Also, download and place the `.json` file in the same folder:
     - [Dependencies (.wav files)](https://mega.nz/file/gn9T1bgQ#XaYbFtPw9oG3zmsRN8lgRyynrmvDYw1y8me1BDG9zCM)
     - [JSON file](https://github.com/Elbios/HerikaAITools/blob/main/GPT-SoVITS/voiceid_to_transcript.json)

6. **Enable MinAI Force Voice Type**  
   - Enable MinAI's `force_voice_type` flag.
