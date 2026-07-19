import urllib.request, json

TOKEN = "eyJhbG...q5w"
HA_URL = "http://192.168.0.200:8123"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Test connection
req = urllib.request.Request(f"{HA_URL}/api/config", headers=headers)
resp = urllib.request.urlopen(req, timeout=10)
data = json.loads(resp.read())

print(f"HA Version: {data['version']}")
print(f"Location: {data['location_name']}")
print(f"State: {data['state']}")
print(f"Zeitzone: {data['time_zone']}")

# Check existing integrations
req2 = urllib.request.Request(f"{HA_URL}/api/config/integrations", headers=headers)
resp2 = urllib.request.urlopen(req2, timeout=10)
integrations = json.loads(resp2.read())
print(f"\nExisting integrations: {len(integrations.get('items', []))}")
for i in integrations.get('items', [])[:10]:
    print(f"  - {i.get('domain')}: {i.get('title', '?')}")
