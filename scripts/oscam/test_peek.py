import requests
r = requests.get('http://192.168.0.3:8888/status.html')
start = r.text.find("Reader")
print(r.text[start:start+500])
