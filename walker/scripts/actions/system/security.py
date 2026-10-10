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


def require_helper():
    if not Path(ROOT_HELPER).exists():
        raise RuntimeError("The root-owned Eitr helper is not installed. See distro/README.md; never sudo a user-writable helper.")


def luks_devices():
    result = subprocess.run(["lsblk", "-rpno", "PATH,FSTYPE"], capture_output=True, text=True, check=True)
    rows = (line.split() for line in result.stdout.splitlines())
    return [row[0] for row in rows if len(row) == 2 and row[1] == "crypto_LUKS"]


def choose_luks_device():
    devices = luks_devices()
    if not devices:
        raise RuntimeError("No LUKS-encrypted partition was found.")
    if len(devices) == 1:
        return devices[0]
    for number, device in enumerate(devices, 1):
        print(f"{number}. {device}")
    choice = input("Encrypted partition number: ").strip()
    if not choice.isdigit() or not 1 <= int(choice) <= len(devices):
        raise ValueError("No encrypted partition selected; nothing was changed.")
    return devices[int(choice) - 1]


TPM_EXPLANATION = """
TPM unlock lets this computer open the encrypted disk at boot without the
passphrase while its firmware and Secure Boot state (TPM PCR 7) are unchanged.
Anyone who boots this computer unmodified reaches the login screen with the disk
unlocked; your login password still protects the session.
The existing passphrase stays enrolled. It is needed after firmware updates,
Secure Boot key changes or a TPM reset, then TPM unlock must be re-enrolled.
Undo at any time with Security > TPM Disk Unlock > Remove TPM Unlock.
"""


def tpm_action(action):
    require_helper()
    device = choose_luks_device()
    if action == "tpm-status":
        subprocess.run(["sudo", ROOT_HELPER, "luks-tpm-check", device], check=True)
        return
    if action == "tpm-remove":
        print(f"This removes TPM unlock from {device}; the passphrase is required at every boot again.")
        if input("Type REMOVE TPM to confirm (anything else cancels): ") == "REMOVE TPM":
            subprocess.run(["sudo", ROOT_HELPER, "luks-tpm-remove", device], check=True)
        return
    subprocess.run(["sudo", ROOT_HELPER, "luks-tpm-check", device], check=True)
    print(TPM_EXPLANATION)
    if input("Create a recovery key first? Strongly recommended. [Y/n]: ").strip().lower() not in ("n", "no"):
        subprocess.run(["sudo", ROOT_HELPER, "luks-recovery-key", device], check=True)
        input("Write the recovery key down and store it offline, then press Enter. ")
    if input("Type ENROLL TPM to enroll TPM unlock (anything else cancels): ") != "ENROLL TPM":
        return
    subprocess.run(["sudo", ROOT_HELPER, "luks-tpm-enroll", device], check=True)


def main(action):
    if action in ("tpm-enroll", "tpm-remove", "tpm-status"):
        tpm_action(action)
    elif action == "password":
        subprocess.run(["passwd"], check=True)
    elif action == "fingerprint":
        subprocess.run(["fprintd-enroll"], check=True)
        print("Fingerprint enrolled. Enable fingerprint authentication separately.")
    elif action == "fido2":
        fido_enroll()
    elif action in ("enable-fingerprint", "enable-fido2", "password-only"):
        require_helper()
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
