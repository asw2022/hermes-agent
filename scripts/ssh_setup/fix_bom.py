import os

key_file = 'C:\\Users\\asw\\.ssh\\authorized_keys'

# Read and strip BOM
with open(key_file, 'r', encoding='utf-8-sig') as f:
    content = f.read().strip()

# Write back as plain UTF-8 without BOM
with open(key_file, 'w', encoding='utf-8', newline='') as f:
    f.write(content + '\n')

print("Fixed! Content:")
print(content)
