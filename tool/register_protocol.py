import os
import sys
import winreg

def register_protocol():
    exe_path = os.path.abspath(r"build\windows\x64\runner\Release\anchor.exe")
    cmd_val = f'"{exe_path}" "%1"'
    print("Setting command to:", cmd_val)

    for scheme in ['io.anchor.app', 'io.execute.app']:
        key_path = f"Software\\Classes\\{scheme}"
        with winreg.CreateKey(winreg.HKEY_CURRENT_USER, key_path) as k:
            winreg.SetValue(k, '', winreg.REG_SZ, 'URL:Anchor Protocol')
            winreg.SetValueEx(k, 'URL Protocol', 0, winreg.REG_SZ, '')

        cmd_path = f"Software\\Classes\\{scheme}\\shell\\open\\command"
        with winreg.CreateKey(winreg.HKEY_CURRENT_USER, cmd_path) as k:
            winreg.SetValue(k, '', winreg.REG_SZ, cmd_val)

    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Classes\io.anchor.app\shell\open\command") as k:
        print("Verified command:", winreg.QueryValue(k, ''))

if __name__ == "__main__":
    register_protocol()
