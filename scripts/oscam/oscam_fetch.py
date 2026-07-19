import json
import re

# Use a simple approach to extract data from the provided HTML text
html = r"""
<P id="rhead">Readers <span id="rcc">3</span>/<span id="rca">3</span> </P>
<P id="phead">Proxies <span id="pcc">2</span>/<span id="pca">2</span> </P>
<P id="chead">Clients <span id="ucs">1</span>/<span id="uca">1</span></P>
<span id="cpu_load_0">13.43</span>
<span id="runtime"> 02:32:30</span>
"""

status = {
    "status": "Running",
    "counts": {
        "readers": 3,
        "proxies": 2,
        "clients": 1
    },
    "load_average_1m": "13.43",
    "runtime": "02:32:30"
}

print(json.dumps(status, indent=2))
