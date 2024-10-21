<?php

/*
 * Clone voice 
 * 
 * Original XTTS API usage:
 * 
 * curl -X 'POST' \
 *   'https://k-looked-appointments-ordered.trycloudflare.com/clone_speaker' \
 *   -H 'accept: application/json' \
 *   -H 'Content-Type: multipart/form-data' \
 *   -F 'wav_file=@bella.wav;type=audio/wav'
 * 
 */

/*
 Supported Languages:
 "en", "de", "fr", "es", "it", "pl", "pt", "tr", "ru", "nl", "cs", "ar", "zh", "ja", "hu", "ko",
*/

function set_weights($server_url, $gpt_weights_path, $sovits_weights_path) {
    // Function to set GPT and Sovits weights

    // Set GPT Weights
    $gpt_url = $server_url . '/set_gpt_weights';
    $gpt_params = array('weights_path' => $gpt_weights_path);
    $gpt_response = send_get_request($gpt_url, $gpt_params);
    if ($gpt_response === false || $gpt_response['message'] !== 'success') {
        error_log("Error setting GPT weights: " . json_encode($gpt_response));
        return false;
    }

    // Set Sovits Weights
    $sovits_url = $server_url . '/set_sovits_weights';
    $sovits_params = array('weights_path' => $sovits_weights_path);
    $sovits_response = send_get_request($sovits_url, $sovits_params);
    if ($sovits_response === false || $sovits_response['message'] !== 'success') {
        error_log("Error setting Sovits weights: " . json_encode($sovits_response));
        return false;
    }

    return true;
}

function set_reference_audio($server_url, $refer_audio_path) {
    // Function to set reference audio

    $refer_url = $server_url . '/set_refer_audio';
    $refer_params = array('refer_audio_path' => $refer_audio_path);
    $refer_response = send_get_request($refer_url, $refer_params);
    if ($refer_response === false || $refer_response['message'] !== 'success') {
        error_log("Error setting reference audio: " . json_encode($refer_response));
        return false;
    }
    return true;
}

function send_get_request($url, $params) {
    // Helper function to send GET requests and return JSON response
    $query = http_build_query($params);
    $full_url = $url . '?' . $query;

    $options = array(
        'http' => array(
            'header' => "Accept: application/json\r\n",
            'method' => 'GET',
        )
    );
    $context = stream_context_create($options);
    $result = file_get_contents($full_url, false, $context);

    if ($result === FALSE) {
        return false;
    }

    return json_decode($result, true);
}

// Load voiceid to transcript mapping
$mappingFile = '/home/dwemer/speakers-GPT-SoVITS/voiceid_to_transcript.json'; // **Update this path to your JSON file**
if (!file_exists($mappingFile)) {
    die("Mapping file not found at '$mappingFile'. Please check the path.");
}
$voiceidToTranscript = json_decode(file_get_contents($mappingFile), true);
if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error decoding JSON mapping: " . json_last_error_msg());
}

function tts($textString, $mood, $stringforhash) {
    global $voiceidToTranscript; // Access the global mapping

    echo "Starting TTS function..." . PHP_EOL;
    // Define server URL and paths (These should be configured as per your setup)
    $server_url = 'http://127.0.0.1:9880'; // Update if different
    $gpt_weights_path = "GPT_SoVITS/pretrained_models/s1bert25hz-2kh-longer-epoch=68e-step=50232.ckpt";
    $sovits_weights_path = "GPT_SoVITS/pretrained_models/s2G488k.pth";

    // Step 1: Set Weights (This should ideally be done once, not per TTS call)
    // To minimize changes, we're including it here. For optimization, consider setting weights during initialization.
    if (!set_weights($server_url, $gpt_weights_path, $sovits_weights_path)) {
        error_log("Failed to set weights.");
        return false;
    }

    // Optional: Wait for weights to load if necessary
    sleep(1); // Adjust based on server's loading time

    // Step 2: Determine language and voice from globals
    // Restoring the commented code to fetch from globals
    $lang = isset($GLOBALS["TTS"]["FORCED_LANG_DEV"]) ? $GLOBALS["TTS"]["FORCED_LANG_DEV"] : (isset($GLOBALS["TTS"]["XTTSFASTAPI"]["language"]) ? $GLOBALS["TTS"]["XTTSFASTAPI"]["language"] : 'en');
    if (isset($GLOBALS["LLM_LANG"]) && isset($GLOBALS["LANG_LLM_XTTS"]) && $GLOBALS["LANG_LLM_XTTS"]) {
        $lang = $GLOBALS["LLM_LANG"];
    }
    if (empty($lang)) {
        $lang = isset($GLOBALS["TTS"]["XTTSFASTAPI"]["language"]) ? $GLOBALS["TTS"]["XTTSFASTAPI"]["language"] : 'en';
    }

    $voice = isset($GLOBALS["TTS"]["FORCED_VOICE_DEV"]) ? $GLOBALS["TTS"]["FORCED_VOICE_DEV"] : (isset($GLOBALS["TTS"]["XTTSFASTAPI"]["voiceid"]) ? $GLOBALS["TTS"]["XTTSFASTAPI"]["voiceid"] : '');
    if (empty($voice)) {
        $voice = isset($GLOBALS["TTS"]["XTTSFASTAPI"]["voiceid"]) ? $GLOBALS["TTS"]["XTTSFASTAPI"]["voiceid"] : '';
    }

    if (empty($voice)) {
        error_log("Voice ID is not set in globals.");
        return false;
    }

    // Step 3: Retrieve transcript from mapping
    if (!isset($voiceidToTranscript[$voice])) {
        error_log("Transcript for voiceid '$voice' not found in the mapping.");
        return false;
    }
    $transcript = $voiceidToTranscript[$voice];

    // Step 4: Set reference audio path based on voiceid
    $refer_audio_path = "/home/dwemer/speakers-GPT-SoVITS/" . $voice . ".wav"; // Adjust the path if necessary

    // Step 5: Set Reference Audio
    if (!set_reference_audio($server_url, $refer_audio_path)) {
        error_log("Failed to set reference audio for voiceid '$voice'.");
        return false;
    }

    $newString = $textString;

    $startTime = microtime(true);

    $tts_url = $server_url . "/tts";

    // Prepare TTS data payload
    $tts_data = array(
        "text" => $newString,
        "text_lang" => $lang,
        "ref_audio_path" => $refer_audio_path,
        "prompt_text" => $transcript, // Use the transcript from mapping
        "prompt_lang" => $lang, // Adjust if different
        "text_split_method" => "cut5", // Adjust based on your needs
        "batch_size" => 1,
        "media_type" => "wav",
        "streaming_mode" => false,
        "parallel_infer" => true,
        // Add other parameters as needed
    );

    // Convert TTS data to JSON
    $tts_json = json_encode($tts_data);

    // Setup HTTP context for POST request
    $options = array(
        'http' => array(
            'header'  => "Content-Type: application/json\r\n" .
                         "Accept: audio/wav\r\n",
            'method'  => 'POST',
            'content' => $tts_json,
            'timeout' => 60 // Set a timeout as needed
        )
    );
    $context  = stream_context_create($options);

    // Perform the POST request
    $response = @file_get_contents($tts_url, false, $context);

    if ($response === FALSE) {
        // Handle error
        error_log("Error occurred during TTS request for voiceid '$voice'.");
        return false;
    }

    // Save the audio response to a file
    $size = strlen($response);
    $oname = dirname(__FILE__) . "/../soundcache/" . md5(trim($stringforhash)) . "_o.wav";
    $fname = dirname(__FILE__) . "/../soundcache/" . md5(trim($stringforhash)) . ".wav";

    file_put_contents($oname, $response); // Save original audio

    // Optional: Post-processing with FFmpeg
    $startTimeTrans = microtime(true);
    // Example: Adjust as needed for your processing
    shell_exec("ffmpeg -y -i $oname -af \"adelay=150|150\" $fname 2>/dev/null >/dev/null");
    $endTimeTrans = microtime(true) - $startTimeTrans;

    // Logging
    file_put_contents(dirname(__FILE__) . "/../soundcache/" . md5(trim($stringforhash)) . ".txt", trim($textString) . "\n\rtotal call time:" . (microtime(true) - $startTime) . " ms\n\rffmpeg transcoding: $endTimeTrans secs\n\rsize of wav ($size)\n\rfunction tts($textString,$mood=\"cheerful\",$stringforhash)");
    $GLOBALS["DEBUG_DATA"][] = (microtime(true) - $startTime) . " secs in xtts-fast-api call";

    return "soundcache/" . md5(trim($stringforhash)) . ".wav";
}

/*
Example Usage:

$GLOBALS["TTS"]["XTTSFASTAPI"]["endpoint"] = 'http://127.0.0.1:9880';
$GLOBALS["TTS"]["XTTSFASTAPI"]["voiceid"] = 's1bert25hz';
$GLOBALS["TTS"]["XTTSFASTAPI"]["language"] = 'zh';

$textTosay = "先帝创业未半而中道崩殂，今天下三分，益州疲弊，此诚危急存亡之秋也。";

echo tts($textTosay, '', $textTosay) . PHP_EOL;
*/
/*
$GLOBALS["TTS"]["XTTSFASTAPI"]["endpoint"]='http://localhost:8020';
$GLOBALS["TTS"]["XTTSFASTAPI"]["voiceid"]='daegon';
$GLOBALS["TTS"]["XTTSFASTAPI"]["language"]='en';

$textTosay="Hello fellows, this is a new text to speech connector";

echo tts($textTosay,'',$textTosay).PHP_EOL;
 */
?>
