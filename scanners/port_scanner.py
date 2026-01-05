
import socket
print("started")


ports=[80,443,8080,22,21,25,110,995,143,993,3306,5432,6379,27017,33128,8081,8888,9000,9200,9300,11211]
for port in ports:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1)
    result = s.connect_ex(("142.250.190.14", port))
    print(f"Port {port}: {'OPEN' if result == 0 else 'CLOSED'}")
    s.close()
