import urllib.request, json, sys

# HA Connection
TOKEN = "eyJh..._URL = "http://localhost:8123"
headers = {
    "Authorization": "Bearer " + TOKEN,
    "Content-Type": "application/json"
}

def ha_get(path):
    req = urllib.request.Request(HA_URL + path, headers=headers)
    resp = urllib.request.urlopen(req, timeout=10)
    return json.loads(resp.read())

def ha_post(path, data=None):
    body = json.dumps(data or {}).encode()
    req = urllib.request.Request(HA_URL + path, data=body, headers=headers, method="POST")
    resp = urllib.request.urlopen(req, timeout=10)
    return json.loads(resp.read())

# 1. Test connection
print("=== HA Status ===")
d = ha_get("/api/")
print(f"Status: {d.get('message', '?')}")

# 2. Get config
print("\n=== Config ===")
c = ha_get("/api/config")
print(f"Version: {c.get('version')}")
print(f"State: {c.get('state')}")
print(f"Location: {c.get('location_name')}")

# 3. List all entities
print("\n=== Entities ===")
states = ha_get("/api/states")
print(f"Total: {len(states)}")

# Group by domain
domains = {}
for s in states:
    domain = s['entity_id'].split('.')[0]
    if domain not in domains:
        domains[domain] = []
    domains[domain].append(s['entity_id'])

for domain, entities in sorted(domains.items()):
    print(f"  [{domain}] {len(entities)}: {', '.join(entities[:3])}{'...' if len(entities) > 3 else ''}")

# 4. Check integrations
print("\n=== Integrations ===")
try:
    integ = ha_get("/api/config/integrations")
    items = integ.get('items', [])
    for i in items[:15]:
        print(f"  - {i.get('domain')}: {i.get('title', '?')}")
except:
    print("  Could not load integrations")

# 5. Check device_trackers
print("\n=== Device Trackers ===")
for s in states:
    if s['entity_id'].startswith('device_tracker.'):
        print(f"  {s['entity_id']}: {s.get('state','?')}")

# 6. Check persons
print("\n=== Persons ===")
for s in states:
    if s['entity_id'].startswith('person.'):
        print(f"  {s['entity_id']}: {s.get('state','?')}")

print("\n=== READY ===")
