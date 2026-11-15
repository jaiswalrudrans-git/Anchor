import os
import subprocess

desktop = os.path.expanduser('~/Desktop')
broken_exe = os.path.join(desktop, 'anchor.exe')
if os.path.exists(broken_exe):
    os.remove(broken_exe)
    print("Removed broken solitary anchor.exe from Desktop")

lnk_path = os.path.join(desktop, "Anchor.lnk")
target_exe = r"D:\Anchor\dist\Anchor-Windows-x64\anchor.exe"
work_dir = r"D:\Anchor\dist\Anchor-Windows-x64"

ps_code = f"""
$ws = New-Object -ComObject WScript.Shell
$s = $ws.CreateShortcut('{lnk_path}')
$s.TargetPath = '{target_exe}'
$s.WorkingDirectory = '{work_dir}'
$s.IconLocation = '{target_exe},0'
$s.Description = 'Anchor'
$s.Save()
"""

p = subprocess.run(["powershell", "-NoProfile", "-Command", ps_code], capture_output=True, text=True)
if p.returncode == 0:
    print(f"Successfully created working shortcut at: {lnk_path}")
else:
    print(f"Error: {p.stderr}")
