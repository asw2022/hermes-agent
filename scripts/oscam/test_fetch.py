import requests
try:
    r = requests.get('http://192.168.0.3:8888/status.html', timeout=5)
    print(f"Status: {r.status_code}")
    print(f"Content Length: {len(r.text)}")
    print(r.text[:500])
except Exception as e:
    print(f"Error: {e}")
