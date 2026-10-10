#!/usr/bin/env python3
"""Root-owned, narrow Eitr snapshot/authentication operations; never run at login."""
import argparse
import datetime
import json
import os
from pathlib import Path
import pwd
import shutil
import stat
import subprocess
import tempfile

STATE = Path("/var/lib/eitr")
PAM = Path("/etc/pam.d")
SERVICES = ("hyprlock", "sddm", "sudo")
MARKER = " # eitr-managed-auth"


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def output(args):
    return subprocess.check_output(args, text=True).strip()


def atomic(path, content, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".eitr-")
    try:
        with os.fdopen(fd, "w") as file:
            file.write(content)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def mount_source(path):
    return output(["findmnt", "-n", "-o", "SOURCE", "-T", path])


def snapshot_supported():
    if output(["findmnt", "-n", "-o", "FSTYPE", "/"]) != "btrfs":
        raise RuntimeError("Snapshot-protected updates require a Btrfs root. No update was started.")
    source = mount_source("/")
    for path in ("/usr", "/etc", "/var/lib/pacman"):
        if mount_source(path) != source:
            raise RuntimeError(f"{path} is outside the root snapshot. Configure a coordinated snapshot backend first.")


def setup_snapshots():
    snapshot_supported()
    result = subprocess.run(["snapper", "-c", "root", "get-config"], capture_output=True)
    if result.returncode:
        run(["snapper", "-c", "root", "create-config", "/"])
        run(["snapper", "-c", "root", "set-config", "NUMBER_CLEANUP=yes",
             "NUMBER_LIMIT=10", "NUMBER_LIMIT_IMPORTANT=5", "TIMELINE_CREATE=no"])
    run(["systemctl", "enable", "snapper-cleanup.timer"])
    print("Root snapshots configured. Existing Snapper policy is preserved.")


def snapshot_pre():
    snapshot_supported()
    run(["snapper", "-c", "root", "get-config"], stdout=subprocess.DEVNULL)
    identifier = output(["snapper", "-c", "root", "create", "--type", "pre", "--print-number",
                         "--description", "Eitr before package upgrade", "--cleanup-algorithm", "number"])
    if not identifier.isdigit():
        raise RuntimeError("Snapper returned an invalid snapshot number")
    archive = STATE / "boot-backups" / identifier
    archive.mkdir(parents=True, mode=0o700, exist_ok=False)
    # Root snapshots do not include separate /boot or EFI partitions.
    for mount in ("/boot", "/efi"):
        if Path(mount).is_dir():
            run(["tar", "-C", mount, "-cpf", str(archive / (mount[1:] + ".tar")), "."])
    atomic(STATE / "pending-upgrade.json", json.dumps({"snapshot": identifier, "boot": str(archive)}) + "\n")
    print(f"Recovery snapshot {identifier} and boot archives created.")


def snapshot_post():
    path = STATE / "pending-upgrade.json"
    if not path.exists():
        return
    pending = json.loads(path.read_text())
    identifier = str(pending["snapshot"])
    if not identifier.isdigit():
        raise RuntimeError("Invalid pending snapshot")
    run(["snapper", "-c", "root", "create", "--type", "post", "--pre-number", identifier,
         "--description", "Eitr after package upgrade", "--cleanup-algorithm", "number"])
    path.unlink()


def pam_with_method(content, method):
    remaining = [line for line in content.splitlines() if not line.endswith(MARKER)]
    modules = {
        "fingerprint": "auth sufficient pam_fprintd.so timeout=10 max-tries=1",
        "fido2": "auth sufficient pam_u2f.so authfile=/etc/security/eitr/u2f_keys origin=pam://eitr appid=pam://eitr cue userpresence=1",
    }
    if method == "password":
        return "\n".join(remaining) + "\n"
    # Preserve the original password/account/session stack; never replace it.
    return modules[method] + MARKER + "\n" + "\n".join(remaining) + "\n"


def enable_auth(method):
    user = os.environ.get("SUDO_USER", "")
    if not user or user == "root":
        raise RuntimeError("Use sudo from your normal desktop user")
    account = pwd.getpwnam(user)
    if method == "fingerprint":
        run(["fprintd-list", user])
    elif method == "fido2":
        source = Path(account.pw_dir) / ".config/Yubico/u2f_keys"
        # Do not let a root helper follow an arbitrary user symlink.
        descriptor = os.open(source, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(descriptor) as registration:
            metadata = os.fstat(registration.fileno())
            if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != account.pw_uid or metadata.st_size > 65536:
                raise RuntimeError("FIDO2 registration must be a regular file owned by the desktop user")
            content = registration.read(65537)
        if not content.startswith(user + ":") or "\n" in content.rstrip("\n"):
            raise RuntimeError("Invalid FIDO2 registration")
        target = Path("/etc/security/eitr/u2f_keys")
        current = target.read_text().splitlines() if target.exists() else []
        current = [line for line in current if not line.startswith(user + ":")]
        atomic(target, "\n".join([*current, content.strip()]) + "\n")
    backup = STATE / "pam-backups" / datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True, mode=0o700)
    for service in SERVICES:
        path = PAM / service
        if not path.is_file() or path.is_symlink():
            raise RuntimeError(f"Unsupported PAM file: {path}")
    for service in SERVICES:
        path = PAM / service
        shutil.copy2(path, backup / service)
        atomic(path, pam_with_method(path.read_text(), method), mode=0o644)
    print(f"Authentication updated for {', '.join(SERVICES)}. Password fallback retained. Backup: {backup}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["snapshots-setup", "snapshot-pre", "snapshot-post", "auth-enable"])
    parser.add_argument("method", nargs="?", choices=["fingerprint", "fido2", "password"])
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("This root-owned helper must run through sudo or a pacman hook")
    try:
        if args.action == "snapshots-setup": setup_snapshots()
        elif args.action == "snapshot-pre": snapshot_pre()
        elif args.action == "snapshot-post": snapshot_post()
        elif args.action == "auth-enable" and args.method: enable_auth(args.method)
        else: parser.error("Authentication method required")
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + "\n")
