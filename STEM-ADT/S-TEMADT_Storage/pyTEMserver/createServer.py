import socket
from PyJEM import TEM3
HOST = '127.0.0.1'
PORT = 65432
variables = {}

def run_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print("Server listening on "+HOST+":"+str(PORT))
        while True:
            conn, addr = s.accept()
            with conn:
                print('Connected by', addr)
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    command = data.decode()
                    try:
                        if command.lower() == 'quit':
                            break
                        elif command.lower() == 'shutdown':
                            print("Shutting down the server...")
                            return
                        if '=' in command:
                            exec(command)
                            variable_name, variable_value = command.split('=')
                            variables[variable_name.strip()] = eval(variable_value)
                            result = "Variable '{variable_name.strip()}' assigned successfully."
                        else:
                            result = str(eval(command, {}, variables))
                        conn.sendall(result.encode())
                    except Exception as e:
                        conn.sendall(str(e).encode())

if __name__ == "__main__":
    run_server()