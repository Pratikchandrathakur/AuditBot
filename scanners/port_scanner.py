
import socket,errno
domain=input("Enter the domain to scan ")
print("Starting Port Scanner")
ip = socket.gethostbyname(domain)
print(f"Scanning {domain} ({ip})")


ports=[80,443,8080,22,21,25,110,995,143,993,3306,5432,6379,27017,33128,8081,8888,9000,9200,9300,11211]
for port in ports:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1)
    result = s.connect_ex((ip, port))
    if result==0:
        print(f"[OPEN] Port {port}")
    elif result==errno.ETIMEDOUT:
        print(f"[FILTERED] Port {port}")
    else:
        print(f"[CLOSED] Port {port}")
    s.close()
print("Scanning Completed")
