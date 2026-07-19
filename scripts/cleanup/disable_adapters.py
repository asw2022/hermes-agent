import subprocess

def ps(cmd, timeout=15):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Disable VirtualBox Host-Only adapters
vbox_adapters = ['Ethernet 11', 'Ethernet 12', 'Ethernet 13']
for adapter in vbox_adapters:
    print(f"Disabling: {adapter}")
    result = ps(f"Disable-NetAdapter -Name '{adapter}' -Confirm:$false 2>&1")
    if result:
        print(f"  {result}")
    else:
        print(f"  OK")

# Disable Hyper-V Emulator adapters (not the main Default Switch)
hyperv_adapters = [
    'vEthernet (Internal Ethernet Port Microsoft Emulator NAT Switch)',
    'vEthernet (Internal Ethernet Port Windows Phone Emulator Internal Switch)',
]
for adapter in hyperv_adapters:
    print(f"Disabling: {adapter}")
    result = ps(f"Disable-NetAdapter -Name '{adapter}' -Confirm:$false 2>&1")
    if result:
        print(f"  {result}")
    else:
        print(f"  OK")

# Disable VMware adapters
vmware_adapters = ['VMware Network Adapter VMnet1', 'VMware Network Adapter VMnet8']
for adapter in vmware_adapters:
    print(f"Disabling: {adapter}")
    result = ps(f"Disable-NetAdapter -Name '{adapter}' -Confirm:$false 2>&1")
    if result:
        print(f"  {result}")
    else:
        print(f"  OK")

print("\n=== Remaining active adapters ===")
print(ps("Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Format-Table Name,InterfaceDescription,LinkSpeed -AutoSize"))
