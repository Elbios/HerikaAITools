from flask import Flask, request, jsonify
import base64
from PIL import Image
import io
import os
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

# Initialize the Flask application
app = Flask(__name__)

# Load the Qwen LLM Model
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen-VL-Chat-Int4", trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen-VL-Chat-Int4", device_map="cuda", trust_remote_code=True).eval()

@app.route('/completion', methods=['POST'])
def process_image():
    try:
        print('Got request\n')
        data = request.get_json()
        prompt = data['prompt']
        print('prompt: ' + prompt)
        image_data = data['image_data'][0]['data']
        
        # Decode the image
        image_bytes = base64.b64decode(image_data)
        image = Image.open(io.BytesIO(image_bytes))
        image.save("temp_image.jpg")
        
        # Process with LLM
        query = tokenizer.from_list_format([ {'image': 'temp_image.jpg'}, {'text': prompt}, ])
        response, history = model.chat(tokenizer, query=query, history=None)
        
        # Remove the temp image
        os.remove("temp_image.jpg")
        
        print('\nresponse: ' + response + '\n')
        return jsonify({"content": response})
    except Exception as e:
        print('\nexception: ' + str(e))
        return jsonify({"error": str(e)})

# Start the Flask server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8007)
