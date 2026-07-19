import requests
r = requests.get('http://192.168.0.3:8888/status.html')
# Suche den gesamten Tabellenabschnitt für Reader
start = r.text.find("statuscol4")
print(r.text[start-100:start+1000])
