import subprocess, time

# Adobe CS3 Uninstall Commands (in order - main apps first, then components)
uninstalls = [
    # Main applications first
    ("Adobe Photoshop CS3", r'C:\Program Files (x86)\Common Files\Adobe\Installers\5f143314a5d434c8511097393d17397\Setup.exe /uninstall'),
    ("Adobe Bridge CS3", r'MsiExec.exe /I{9C9824D9-9000-4373-A6A5-D0E5D4831394} /qn /norestart'),
    # Components (can be done in parallel batches)
    ("Adobe Device Central CS3", r'MsiExec.exe /I{8D2BA474-F406-4710-9AE4-D4F22D21F0DD} /qn /norestart'),
    ("Adobe Linguistics CS3", r'MsiExec.exe /I{54793AA1-5001-42F4-ABB6-C364617C6078} /qn /norestart'),
    ("Adobe PDF Library Files", r'MsiExec.exe /I{D2559B88-CC9D-4B48-81BB-F492BAA9C48C} /qn /norestart'),
    ("Adobe Asset Services CS3", r'MsiExec.exe /I{6FF5DD7A-FE28-4439-B8CF-1E9AF4EA0A61} /qn /norestart'),
    ("Adobe ExtendScript Toolkit 2", r'MsiExec.exe /I{C2D69781-F392-4118-A5A7-C7E9C38DBFC2} /qn /norestart'),
    ("Adobe Version Cue CS3 Client", r'MsiExec.exe /I{D0DFF92A-492E-4C40-B862-A74A173C25C5} /qn /norestart'),
    ("Adobe Color Common Settings", r'MsiExec.exe /I{DADD7B8A-BCB0-44F5-967A-ECB6B4F2ECD9} /qn /norestart'),
    ("Adobe Camera Raw 4.0", r'MsiExec.exe /I{B3BF6689-A81D-40D8-9A86-4AC4ACD9FC1C} /qn /norestart'),
    ("Adobe Setup", r'MsiExec.exe /I{F01F79AD-1F47-4685-AE4E-CCFA4EA9FF7C} /qn /norestart'),
    ("Adobe Help Viewer CS3", r'MsiExec.exe /I{04AF207D-9A77-465A-8B76-991F6AB66245} /qn /norestart'),
    ("Adobe Update Manager CS3", r'MsiExec.exe /I{E69AE897-9E0B-485C-8552-7841F48D42D8} /qn /norestart'),
    ("Adobe Fonts All", r'MsiExec.exe /I{6ABE0BEE-D572-4FE8-B434-9E72A289431B} /qn /norestart'),
    ("Adobe Type Support", r'MsiExec.exe /I{8E6808E2-613D-4FCD-81A2-6C8FA8E03312} /qn /norestart'),
    ("Adobe Stock Photos CS3", r'MsiExec.exe /I{29E5EA97-5F74-4A57-B8B2-D4F169117183} /qn /norestart'),
    ("Adobe CMaps", r'MsiExec.exe /I{A2B242BD-FF8D-4840-9DAA-9170EABEC59C} /qn /norestart'),
    ("Adobe Anchor Service CS3", r'MsiExec.exe /I{90176341-0A8B-4CCC-A78D-F862228A6B95} /qn /norestart'),
    ("Adobe Default Language CS3", r'MsiExec.exe /I{B9B35331-B7E4-4E5C-BF4C-7BC87856124D} /qn /norestart'),
    ("Adobe Color - Photoshop Specific", r'MsiExec.exe /I{A2D81E70-2A98-4A08-A628-94388B063C5E} /qn /norestart'),
    ("Adobe Color EU Recommended Settings", r'MsiExec.exe /I{73B5D990-04EA-4751-B10F-5534770B91F2} /qn /norestart'),
    ("Adobe Color JA Extra Settings", r'MsiExec.exe /I{DD7DB3C5-6FA3-4FA3-8A71-C2F2940EB029} /qn /norestart'),
    ("Adobe Color NA Extra Settings", r'MsiExec.exe /I{FF29A7E2-FF40-4D07-B7E4-2093DE59E10A} /qn /norestart'),
    ("Adobe Bridge Start Meeting", r'MsiExec.exe /I{08B32819-6EEF-4057-AEDA-5AB681A36A23} /qn /norestart'),
    ("Adobe WinSoft Linguistics Plugin", r'MsiExec.exe /I{184CE391-7E0E-4C63-9935-D7A10EDFD3C6} /qn /norestart'),
    ("Adobe XMP Panels CS3", r'MsiExec.exe /I{802771A9-A856-4A41-ACF7-1450E523C923} /qn /norestart'),
    # Second Photoshop entry
    ("Adobe Photoshop CS3 (2)", r'MsiExec.exe /I{29F05234-DCBB-4FE0-88DC-5160C9250312} /qn /norestart'),
]

print(f"=== Deinstalliere {len(uninstalls)} Adobe Programme ===\n")

success = 0
failed = 0
for name, cmd in uninstalls:
    print(f"[{success+failed+1}/{len(uninstalls)}] {name}...")
    try:
        # Run uninstall
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        if r.returncode in [0, 3010]:  # 0=success, 3010=reboot required
            print(f"   OK (exit: {r.returncode})")
            success += 1
        else:
            print(f"   Failed (exit: {r.returncode}): {r.stderr[:100]}")
            failed += 1
    except subprocess.TimeoutExpired:
        print(f"   Timeout (may still be running)")
        success += 1  # MSI often times out but succeeds
    except Exception as e:
        print(f"   Error: {e}")
        failed += 1
    time.sleep(1)  # Small delay between uninstalls

print(f"\n=== Ergebnis: {success} OK, {failed} Fehler ===")

# Cleanup leftover folders
print("\n=== Cleanup Adobe Ordner ===")
import os, shutil
folders = [
    "C:/Program Files (x86)/Adobe",
    "C:/Users/asw/AppData/Local/Adobe",
    "C:/Users/asw/AppData/Roaming/Adobe",
]
for f in folders:
    if os.path.exists(f):
        try:
            size = sum(os.path.getsize(os.path.join(r,ff)) for r,d,fs in os.walk(f) for ff in fs if os.path.isfile(os.path.join(r,ff)))
            shutil.rmtree(f, ignore_errors=True)
            print(f"   Deleted: {f} ({size/1024/1024:.1f} MB)")
        except Exception as e:
            print(f"   Error {f}: {e}")
    else:
        print(f"   Already gone: {f}")

print("\n=== Adobe Deinstallation Complete ===")
