import base64
import requests
import json
import os
import sys

# Check if the correct number of arguments are provided
if len(sys.argv) != 3:
    print("Usage: script.py <'qwen'/'llava'> <path_to_image>")
    sys.exit(1)

# Extract arguments
command, file_path = sys.argv[1], sys.argv[2]

# Check if the command is valid
if command not in ['qwen', 'llava']:
    print("First argument must be either 'qwen' or 'llava'")
    sys.exit(1)

# Check if the file path exists
if not os.path.exists(file_path):
    print(f"The file at {file_path} does not exist.")
    sys.exit(1)

url = 'http://localhost:8007/completion'  # The URL to send the request to

# Encode the image file in base64
with open(file_path, "rb") as image_file:
    base64_encoded = base64.b64encode(image_file.read()).decode('utf-8')

# Define the POST data based on the command
if command == 'qwen':
    post_data = {
        'prompt': f"Describe the image in detail. ",
        'image_data': [{"data": base64_encoded, "id": 1}],
    }
elif command == 'llava':
    post_data = {
        'prompt': f"<image>\nUSER:\nDescribe this image in detail.\nASSISTANT:\n",
        'n_predict': 256,
        'image_data': [{"data": base64_encoded, "id": 1}],
        'temperature': 0.0
    }

# Encode the data as JSON
json_data = json.dumps(post_data)

# Set the request headers
headers = {
    'Content-Type': 'application/json',
}

# Perform the HTTP POST request
response = requests.post(url, headers=headers, data=json_data)

# Parse the JSON response
response_data = response.json()
# Example of handling the response data
print(response_data["content"])