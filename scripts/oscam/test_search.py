import requests
r = requests.get('http://192.168.0.3:8888/status.html')
print(r.text.find("READERS"))
print(r.text.find("Reader"))
