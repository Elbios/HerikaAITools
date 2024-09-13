import paramiko
import socket
import select
import threading
import requests
import sys
import signal
import os
 
try:
    import SocketServer
except ImportError:
    import socketserver as SocketServer
 
# Global variables
ssh_client = None
tunnel_threads = []
pod_id = None
 
# Load configuration from file
def load_config():
    config = {}
    with open("config.txt") as f:
        for line in f:
            if '=' in line:
                key, value = line.strip().split('=', 1)
                config[key] = value
    return config
 
# Create the RunPod instance
def create_pod(api_key):
    global pod_id
    print("Spinning up RunPod instance...")
    headers = {"Authorization": f"Bearer {api_key}"}
    data = {
        "imageName": "your-dockerhub-repo/dwemerdistro:latest",
        "gpuType": "NVIDIA_TESLA_V100",
        "cpuCores": 4,
        "ramGB": 16
    }
    response = requests.post("https://api.runpod.io/v1/pods", json=data, headers=headers)
    pod_info = response.json()
    pod_id = pod_info['id']
    print(f"RunPod instance created: {pod_id}")
    return pod_info['ssh']['host'], pod_info['ssh']['port']
 
# Forwarding handler
class ForwardServer(SocketServer.ThreadingTCPServer):
    daemon_threads = True
    allow_reuse_address = True
 
class Handler(SocketServer.BaseRequestHandler):
    def handle(self):
        try:
            chan = self.ssh_transport.open_channel(
                'direct-tcpip',
                (self.chain_host, self.chain_port),
                self.request.getpeername(),
            )
        except Exception as e:
            print(f"Incoming request to {self.chain_host}:{self.chain_port} failed: {e}")
            return
        if chan is None:
            print(f"Incoming request to {self.chain_host}:{self.chain_port} was rejected by the SSH server.")
            return
 
        print(f"Tunnel open: {self.request.getpeername()} -> {chan.getpeername()} -> ({self.chain_host}, {self.chain_port})")
        while True:
            r, w, x = select.select([self.request, chan], [], [])
            if self.request in r:
                data = self.request.recv(1024)
                if len(data) == 0:
                    break
                chan.send(data)
            if chan in r:
                data = chan.recv(1024)
                if len(data) == 0:
                    break
                self.request.send(data)
 
        chan.close()
        self.request.close()
        print(f"Tunnel closed from {self.request.getpeername()}.")
 
# Set up local forwarding using Paramiko
def forward_tunnel(local_port, remote_host, remote_port, transport):
    class SubHandler(Handler):
        chain_host = remote_host
        chain_port = remote_port
        ssh_transport = transport
 
    ForwardServer(("", local_port), SubHandler).serve_forever()
 
def setup_tunnels(config, ssh_host, ssh_port, ssh_user, ssh_key):
    global ssh_client
 
    if ssh_client is None:
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(ssh_host, port=ssh_port, username=ssh_user, key_filename=ssh_key)
        print(f"Connected to {ssh_host} via SSH.")
 
    # Forward all configured local ports
    local_ports = [key for key in config if key.startswith("LOCAL_PORT")]
    remote_ports = [key for key in config if key.startswith("REMOTE_PORT")]
 
    for i in range(len(local_ports)):
        local_port = int(config[local_ports[i]])
        remote_port = int(config[remote_ports[i]])
        threading.Thread(target=forward_tunnel, args=(local_port, "localhost", remote_port, ssh_client.get_transport())).start()
 
# Clean up resources
def cleanup():
    global ssh_client, pod_id
    print("\nCleaning up resources...")
 
    if ssh_client:
        ssh_client.close()
        print("SSH connection closed.")
 
    if pod_id:
        api_key = config['RUNPOD_API_KEY']
        headers = {"Authorization": f"Bearer {api_key}"}
        response = requests.delete(f"https://api.runpod.io/v1/pods/{pod_id}", headers=headers)
        if response.status_code == 204:
            print(f"RunPod instance {pod_id} terminated successfully.")
        else:
            print(f"Failed to terminate RunPod instance {pod_id}.")
        pod_id = None
 
    sys.exit(0)
 
# Signal handler for cleanup
def signal_handler(sig, frame):
    cleanup()
 
if __name__ == "__main__":
    # Load config and set up signal handlers
    config = load_config()
    signal.signal(signal.SIGINT, signal_handler)
 
    # Spin up the RunPod instance and start forwarding tunnels
    ssh_host, ssh_port = create_pod(config['RUNPOD_API_KEY'])
    setup_tunnels(config, ssh_host, ssh_port, config['SSH_USER'], config['SSH_KEY_PATH'])
 
    print("\nDwemerDistro is running. Press Enter twice to quit.")
    input()
    input()
    cleanup()
 