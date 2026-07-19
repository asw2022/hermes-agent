import urllib.request, json, base64

# Token als Base64 umgehen der Shell/Parser-Probleme
TOKEN_BYTES = b"eyJh...="
TOKEN = TOKEN_BYTES.decode()

HA_URL = "http://192.168.0.200:8123"
headers = {"Authorization": "Bearer " + TOKEN, "Content-Type": "application/json"}

try:
    req = urllib.request.Request(HA_URL + "/api/", headers=headers)
    resp = urllib.request.urlopen(req, timeout=10)
    print("API Status:", resp.status)
except Exception as e:
    print("Error:", e)

try:
    req2 = urllib.request.Request(HA_URL + "/api/config", headers=headers)
    resp2 = urllib.request.urlopen(req2, timeout=10)
    config = json.loads(resp2.read())
    print("HA:", config.get('version'), config.get('state'))
except Exception as e:
    print("Config:", e)

try:
    req3 = urllib.request.Request(HA_URL + "/api/states", headers=headers)
    resp3 = urllib.request.urlopen(req3, timeout=10)
    states = json.loads(resp3.read())
    print("Entities:", len(states))
    for s in states[:15]:
        print(" ", s['entity_id'], s.get('state','?'))
except Exception as e:
    print("States:", e)
