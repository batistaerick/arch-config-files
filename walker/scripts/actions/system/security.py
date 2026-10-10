#!/usr/bin/env python3
"""Interactive enrollment; policy changes only after separate confirmation."""
import getpass
import os
from pathlib import Path
import subprocess
import sys

ROOT_HELPER = "/usr/local/lib/eitr/eitr-system"


def fido_enroll():
    user = getpass.getuser()
    path = Path.home() / ".config/Yubico/u2f_keys"
    path.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    result = subprocess.run(["pamu2fcfg", "-u", user, "-o", "pam://eitr", "-i", "pam://eitr"],
                            capture_output=True, text=True, check=True)
    registration = result.stdout.strip()
    if not registration.startswith(user + ":") or "\n" in registration:
        raise ValueError("Unexpected FIDO2 registration")
    if path.exists():
        existing = path.read_text().strip()
        if not existing.startswith(user + ":") or "\n" in existing:
            raise ValueError("Existing FIDO2 registration needs manual review")
        # Credentials are "keyhandle,publickey,..." entries joined by ":".
        known = {credential.split(",", 1)[0] for credential in existing.split(":")[1:]}
        added = [credential for credential in registration.split(":")[1:]
                 if credential.split(",", 1)[0] not in known]
        if not added:
            print("This security key is already enrolled.")
            return
        registration = ":".join([existing, *added])
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, "w") as file:
        os.fchmod(file.fileno(), 0o600)
        file.write(registration + "\n")
    print("Security key enrolled. Enable FIDO2 authentication separately; keep your password available.")


def main(action):
    if action == "password":
        subprocess.run(["passwd"], check=True)
    elif action == "fingerprint":
        subprocess.run(["fprintd-enroll"], check=True)
        print("Fingerprint enrolled. Enable fingerprint authentication separately.")
    elif action == "fido2":
        fido_enroll()
    elif action in ("enable-fingerprint", "enable-fido2", "password-only"):
        if not Path(ROOT_HELPER).exists():
            raise RuntimeError("The root-owned Eitr helper is not installed. See distro/README.md; never sudo a user-writable helper.")
        method = "password" if action == "password-only" else action.removeprefix("enable-")
        print("This changes login, lockscreen and sudo authentication. Password fallback is retained.")
        if input("Type ENABLE to confirm (anything else cancels): ") != "ENABLE":
            return
        subprocess.run(["sudo", ROOT_HELPER, "auth-enable", method], check=True)
    else:
        raise ValueError("Unknown security action")


if __name__ == "__main__":
    try:
        main(sys.argv[1])
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
