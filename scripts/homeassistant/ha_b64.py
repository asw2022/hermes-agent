import base64, urllib.request, json

# Token via Base64 (keine Escape-Probleme)
token_b64 = "ZXlKaG...XZk"
TOKEN=base64...nurl = "http://localhost:8123"
h = {"Authorization": "Bearer " + TOKEN, "Content-Type": "application/json"}

def api(path):
    r = urllib.request.urlopen(urllib.request.Request(url+path, headers=h), timeout=10)
    return json.loads(r.read())

try:
    d = api("/api/")
    print("HA OK:", d.get("message","?"))
    c = api("/api/config")
    print("Version:", c.get("version"), "State:", c.get("state"))
    s = api("/api/states")
    print("Entities:", len(s))
    for x in s:
        eid = x["entity_id"]
        if any(k in eid for k in ["device_tracker","person","mobile","phone","sensor","battery"]):
            print(" ", eid, "=", x.get("state","?"))
except Exception as e:
    print("Error:", e)
