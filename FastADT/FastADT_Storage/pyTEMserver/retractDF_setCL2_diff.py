import socket
SERVER_HOST = '127.0.0.1'
SERVER_PORT = 65432
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((SERVER_HOST, SERVER_PORT))
    print("Connected to "+SERVER_HOST+":"+str(SERVER_PORT))
    command = "lens.SetFLCAbs(1,CL2diff)"
    s.sendall(command.encode())
    response = s.recv(4096).decode()
    command = "positionDF = detector_module.GetPosition(10)"
    s.sendall(command.encode())
    response = s.recv(4096).decode()
    command = "detector_module.SetPosition(10,0)"
    s.sendall(command.encode())
    response = s.recv(4096).decode()
    command = "quit"
    s.sendall(command.encode())
    response = s.recv(4096).decode()