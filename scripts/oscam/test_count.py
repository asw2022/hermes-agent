import requests
r = requests.get('http://192.168.0.3:8888/status.html')
# Suche nach Tabellenzeilen mit Readern
print(r.text.count("statuscol4"))
