import urllib.request, json

with open("/home/Babel/ha_token.txt") as f:
    TOKEN = f.read().strip()

url = "http://localhost:8123"
h = {"Authorization": "Bearer " + TOKEN}

def api(path):
    r = urllib.request.urlopen(urllib.request.Request(url+path, headers=h), timeout=10)
    return json.loads(r.read())

print("=== HA Status ===")
d = api("/api/")
print("API:", d.get("message","?"))

print("\n=== Config ===")
c = api("/config" if False else "/api/config")
print("Version:", c.get("version"), "State:", c.get("state"))

print("\n=== All States ===")
s = api("/api/states")
print(f"Total: {len(s)} entities")

print("\n--- Device Trackers ---")
for x in s:
    if "device_tracker" in x["entity_id"]:
        attrs = x.get("attributes", {})
        print(f"  {x['entity_id']}: {x.get('state','?')}")
        print(f"    GPS: {attrs.get('latitude','?')}, {attrs.get('longitude','?')}")
        print(f"    Battery: {attrs.get('battery_level','?')}%")
        print(f"    Source: {attrs.get('source_type','?')}")

print("\n--- Persons ---")
for x in s:
    if "person" in x["entity_id"]:
        print(f"  {x['entity_id']}: {x.get('state','?')}")

print("\n--- Mobile/Phone Sensors ---")
for x in s:
    eid = x["entity_id"]
    if any(k in eid for k in ["mobile","phone","redmi","sensor","binary_sensor","battery"]):
        print(f"  {eid}: {x.get('state','?')}")

print("\n--- Person/Tracker count ---")
dt = len([x for x in s if "device_tracker" in x["entity_id"]])
p = len([x for x in s if "person" in x["entity_id"]])
print(f"Device Trackers: {dt}, Persons: {p}")
