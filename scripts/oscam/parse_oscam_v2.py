
import re
import json
import sys

def parse_html(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Improved extraction logic
    readers = []
    # Identify readers (rows with class="r")
    reader_rows = re.findall(r'<TR ID="id_0x.*?CLASS="r".*?</TR>', html, re.DOTALL)
    for row in reader_rows:
        name = re.search(r'TITLE="(.*?)">', row).group(1)
        status = re.search(r'<TD CLASS="statuscol16">(.*?)(?:<BR>)?', row, re.DOTALL).group(1)
        readers.append({"name": name, "status": status.strip()})

    # Identify proxy (rows with class="p")
    proxies = []
    proxy_rows = re.findall(r'<TR ID="id_0x.*?CLASS="p".*?</TR>', html, re.DOTALL)
    for row in proxy_rows:
        name = re.search(r'TITLE="(.*?)">', row).group(1)
        status = re.search(r'<TD CLASS="statuscol16">(.*?)(?:<BR>)?', row, re.DOTALL).group(1)
        proxies.append({"name": name, "status": status.strip()})

    # Identify user (rows with class="c")
    users = []
    user_rows = re.findall(r'<TR ID="id_0x.*?CLASS="c".*?</TR>', html, re.DOTALL)
    for row in user_rows:
        name = re.search(r'TITLE="(.*?)">', row).group(1)
        status = re.search(r'<TD CLASS="statuscol16">(.*?)(?:<BR>)?', row, re.DOTALL).group(1)
        users.append({"name": name, "status": status.strip()})
    
    # Load
    load = re.search(r'id="cpu_load_0">(.*?)</span>', html)
    
    return {
        "readers": readers,
        "proxies": proxies,
        "users": users,
        "load": load.group(1) if load else "unknown"
    }

print(json.dumps(parse_html(sys.argv[1]), indent=2))
