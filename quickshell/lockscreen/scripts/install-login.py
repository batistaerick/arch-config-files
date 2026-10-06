#!/usr/bin/env python3
"""Install local designs and a narrowly scoped passwordless login selector."""
import json
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    if os.geteuid() != 0 or not os.environ.get('SUDO_UID'):
        raise SystemExit('Run with sudo python3 scripts/install-login.py')
    account = pwd.getpwuid(int(os.environ['SUDO_UID']))
    if not account.pw_name or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-' for c in account.pw_name):
        raise SystemExit('Unsupported account name for sudo policy')
    manifest = {}
    for main_qml in sorted((ROOT / 'themes').rglob('Main.qml')):
        source = main_qml.parent
        design = str(source.relative_to(ROOT / 'themes'))
        theme = 'desktop-lockscreen-' + design.replace('/', '-')
        if any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in theme):
            raise SystemExit('Invalid design ID: ' + design)
        if theme in manifest.values():
            raise SystemExit('Duplicate login theme name')
        for path in source.rglob('*'):
            if path.is_symlink():
                raise SystemExit('Symlinks are not allowed in login designs')
        destination = Path('/usr/share/sddm/themes') / theme
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, destination, dirs_exist_ok=True)
        for path in [destination, *destination.rglob('*')]:
            os.chown(path, 0, 0)
            path.chmod(0o755 if path.is_dir() else 0o644)
        shutil.copyfile(ROOT / 'LICENSE', destination / 'LICENSE')
        manifest[design] = theme
    directory = Path('/usr/local/share/desktop-lockscreen')
    directory.mkdir(parents=True, exist_ok=True)
    directory.chmod(0o755)
    manifest_path = directory / 'designs.json'
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    manifest_path.chmod(0o644)
    helper = Path('/usr/local/bin/desktop-login-select')
    shutil.copyfile(ROOT / 'scripts/sddm-select.py', helper)
    helper.chmod(0o755)
    policy = Path('/etc/sudoers.d/desktop-login-select')
    fd, temporary = tempfile.mkstemp(prefix='desktop-login-policy-')
    try:
        with os.fdopen(fd, 'w') as output:
            output.write(f'{account.pw_name} ALL=(root) NOPASSWD: /usr/local/bin/desktop-login-select *\n')
        subprocess.run(['/usr/bin/visudo', '-cf', temporary], check=True)
        shutil.copyfile(temporary, policy)
        policy.chmod(0o440)
    finally:
        os.unlink(temporary)
    state = Path(account.pw_dir) / '.config/lockscreen/selected'
    selected = state.read_text().strip() if state.exists() else ''
    if selected in manifest:
        subprocess.run([str(helper), selected], check=True)
    print(f'Installed {len(manifest)} login designs. Walker selections now update SDDM too.')
    print('SDDM was not restarted. Log out or reboot to see the login design.')


if __name__ == '__main__':
    main()
