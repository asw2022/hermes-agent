import urllib.request, json, os

# Token from environment
TOKEN = os.environ.get("HA_TOKEN", "")
HA_URL = "http://localhost:8123"
headers = {
    "Authorization": "Bearer " + TOKEN,
    "Content-Type": "application/json"
}

def ha_get(path):
    req = urllib.request.Request(HA_URL + path, headers=headers)
    resp = urllib.request.urlopen(req, timeout=10)
    return json.loads(resp.read())

try:
    d = ha_get("/api/")
    print("HA OK:", d.get('message','?'))
    c = ha_get("/api/config")
    print("Version:", c.get('version'), "State:", c.get('state'))
    states = ha_get("/api/states")
    print("Entities:", len(states))
    for s in states[:15]:
        eid = s['entity_id']
        if any(x in eid for x in ['device_tracker','person','sensor','binary_sensor','switch','light','media_player']):
            print(" ", eid, "=", s.get('state','?'))
except Exception as e:
    print("Error:", e)
