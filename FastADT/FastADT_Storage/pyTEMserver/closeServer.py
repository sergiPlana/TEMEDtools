import socket
HOST = '127.0.0.1'
PORT = 65432
def shutdown_server():
    # Connect to the server
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        # Send the shutdown command
        s.sendall("shutdown".encode())

if __name__ == "__main__":
    shutdown_server()