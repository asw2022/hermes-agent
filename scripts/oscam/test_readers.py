import requests
r = requests.get('http://192.168.0.3:8888/readers.html')
print(r.status_code)
print(r.text[:1000])
