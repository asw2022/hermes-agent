import http.server, json, os, subprocess, sys

ADB = r"C:\tools\platform-tools\adb.exe"
FT = "192.168.0.136:5555"
GB = "http://192.168.0.3"

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        p = self.path
        if p.startswith("/api/gb/"):
            import urllib.request as u
            try:
                d = u.urlopen(GB + p[7:], timeout=5).read()
                self.send_response(200)
                self.send_header("Content-Type","application/json")
                self.end_headers()
                self.wfile.write(d)
            except Exception as e:
                self.send_response(502)
                self.end_headers()
                self.wfile.write(json.dumps({"error":str(e)}).encode())
        elif p.startswith("/api/ft/"):
            cmd = p[8:]
            try:
                if cmd == "vol/up":
                    # Use service call for HDMI CEC volume
                    subprocess.run([ADB, "-s", FT, "shell", "service", "call", "audio", "3", "i32", "1", "i32", "0", "i32", "1"],
                                   capture_output=True, timeout=10)
                    r = {"ok":True}
                elif cmd == "vol/down":
                    subprocess.run([ADB, "-s", FT, "shell", "service", "call", "audio", "3", "i32", "1", "i32", "0", "i32", "0"],
                                   capture_output=True, timeout=10)
                    r = {"ok":True}
                elif cmd == "vol/mute":
                    subprocess.run([ADB, "-s", FT, "shell", "input", "keyevent", "164"],
                                   capture_output=True, timeout=10)
                    r = {"ok":True}
                elif cmd.startswith("keycode/"):
                    kc = cmd[8:]
                    subprocess.run([ADB, "-s", FT, "shell", "input", "keyevent", kc],
                                   capture_output=True, timeout=10)
                    r = {"ok":True}
                elif cmd.startswith("app/"):
                    pkg = cmd[4:]
                    subprocess.run([ADB, "-s", FT, "shell", "monkey", "-p", pkg, "-c", "android.intent.category.LAUNCHER", "1"],
                                   capture_output=True, timeout=10)
                    r = {"ok":True}
                else:
                    r = {"ok":False,"error":"unknown"}
                self.send_response(200)
                self.send_header("Content-Type","application/json")
                self.end_headers()
                self.wfile.write(json.dumps(r).encode())
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(json.dumps({"error":str(e)}).encode())
        else:
            super().do_GET()
    def log_message(self,*a): pass

print("Dashboard :8090")
sys.stdout.flush()
http.server.HTTPServer(("127.0.0.1",8090),H).serve_forever()
