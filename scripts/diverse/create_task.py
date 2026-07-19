import subprocess

def ps(cmd, timeout=30):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Create scheduled task for Babel-PC monitoring
print("=== Erstelle Scheduled Task ===")
task_xml = '''<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT5M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>2026-06-01T00:00:00</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>G:\\Users\\asw\\AppData\\Local\\Programs\\Python\\Python312\\python.exe</Command>
      <Arguments>C:\\Users\\asw\\babel_monitor.py</Arguments>
    </Exec>
  </Actions>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Enabled>true</Enabled>
  </Settings>
</Task>'''

xml_path = 'C:/Users/asw/babel_monitor_task.xml'
with open(xml_path, 'w', encoding='utf-16') as f:
    f.write(task_xml)

result = ps(f"Register-ScheduledTask -TaskName 'Babel-PC Monitor' -Xml (Get-Content '{xml_path}' -Raw) -Force 2>&1")
print(result if result else "Task created successfully")

# Cleanup
import os
os.remove(xml_path)

print("\n=== Verify ===")
print(ps("Get-ScheduledTask -TaskName 'Babel PC Monitor' -ErrorAction SilentlyContinue | Select-Object State | Format-List"))
