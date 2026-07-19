
import re
import json
import sys

def parse_html(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Readers status
    readers = re.findall(r'<TD CLASS="statuscol4" TITLE="(.*?)">.*?<TD CLASS="statuscol16">(.*?)(?:<BR>)?', html, re.DOTALL)
    
    # Client status
    client_status = re.search(r'id="id_0x52c928" CLASS="c".*?<TD CLASS="statuscol16">(.*?)</TD>', html, re.DOTALL)
    
    # Load
    load = re.search(r'id="cpu_load_0">(.*?)</span>', html)
    
    return {
        "readers": [{"name": r[0], "status": r[1].replace('<BR>', ' ')} for r in readers],
        "client": client_status.group(1) if client_status else "unknown",
        "load": load.group(1) if load else "unknown"
    }

print(json.dumps(parse_html(sys.argv[1])))
