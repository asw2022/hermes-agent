p = r'C:\Users\asw\hermes-agent-desktop\app.py'
with open(p, encoding='utf-8') as f:
    s = f.read()
target = "webview.start(gui='edgechromium', debug=False)"
wrong = r"webview.start(gui=\'edgechromium\', debug=False)"
if wrong in s:
    s = s.replace(wrong, target)
    print("removed escaped version")
elif "webview.start(debug=False)" in s:
    s = s.replace("webview.start(debug=False)", target)
    print("set edgechromium")
# ensure no leftover double-backslash
if wrong in s:
    s = s.replace(wrong, target)
with open(p, 'w', encoding='utf-8') as f:
    f.write(s)
print("OK" if target in s else "NOT SET")
