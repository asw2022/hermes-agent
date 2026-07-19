import urllib.request, json, sys

# Read token from stdin
token_line = sys.stdin.readline().strip()
TOKEN = token_line.split("=", 1)[1] if "=" in token_line else token_line

url = "http://localhost:8123"
h = {"Authorization": "Bearer " + TOKEN, "Content-Type": "application/json"}

try:
    d = json.loads(urllib.request.urlopen(urllib.request.Request(url+"/api/", headers=h), timeout=10).read())
    print("HA OK:", d.get("message","?"))
    c = json.loads(urllib.request.urlopen(urllib.request.Request(url+"/api/config", headers=h), timeout=10).read())
    print("Ver:", c.get("version"), "State:", c.get("state"))
    s = json.loads(urllib.request.urlopen(urllib.request.Request(url+"/api/states", headers=h), timeout=10).read())
    print("Entities:", len(s))
    for x in s[:15]:
        e = x["entity_id"]
        if any(k in e for k in ["device_tracker","person","sensor","switch","light","media","binary"]):
            print(" ", e, "=", x.get("state","?"))
except Exception as e:
    print("Err:", e)
