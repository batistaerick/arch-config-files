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
import sys
import tempfile

STATE = Path("/var/lib/eitr")
PAM = Path("/etc/pam.d")
SERVICES = ("hyprlock", "sddm", "sudo")
MARKER = " # eitr-managed-auth"
U2F_KEYS = Path("/etc/security/eitr/u2f_keys")
BOOT_ARCHIVE_LIMIT = 10


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def output(args):
    return subprocess.check_output(args, text=True).strip()


def atomic(path, content, mode=0o600, directory_mode=0o700):
    path.parent.mkdir(parents=True, exist_ok=True, mode=directory_mode)
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


def is_mountpoint(path):
    return subprocess.run(["findmnt", "-n", "-M", path], stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode == 0


def separate_boot_mounts():
    # /boot inside the Btrfs root is already covered by the root snapshot.
    return [mount for mount in ("/boot", "/efi") if Path(mount).is_dir() and is_mountpoint(mount)]


def prune_boot_archives(keep=BOOT_ARCHIVE_LIMIT):
    """Keep only the newest numbered boot archives, like Snapper's number cleanup."""
    root = STATE / "boot-backups"
    if not root.is_dir():
        return
    archives = sorted((path for path in root.iterdir() if path.is_dir() and path.name.isdigit()),
                      key=lambda path: int(path.name))
    for path in archives[:-keep] if keep else archives:
        shutil.rmtree(path)


def snapshot_pre():
    snapshot_supported()
    run(["snapper", "-c", "root", "get-config"], stdout=subprocess.DEVNULL)
    if (STATE / "pending-upgrade.json").exists():
        # A previous update was interrupted before its post snapshot; pair it
        # now so the old pre snapshot is not left orphaned.
        print("Closing the recovery point of an interrupted earlier update.")
        snapshot_post("interrupted")
    root = STATE / "boot-backups"
    root.mkdir(parents=True, mode=0o700, exist_ok=True)
    # Archive boot files before creating the snapshot so a failure here never
    # leaves a pre snapshot without a pending record.
    staging = Path(tempfile.mkdtemp(prefix=".staging-", dir=root))
    try:
        mounts = separate_boot_mounts()
        for mount in mounts:
            run(["tar", "-C", mount, "-cpf", str(staging / (mount[1:] + ".tar")), "."])
        identifier = output(["snapper", "-c", "root", "create", "--type", "pre", "--print-number",
                             "--description", "Eitr before package upgrade", "--cleanup-algorithm", "number"])
        if not identifier.isdigit():
            raise RuntimeError("Snapper returned an invalid snapshot number")
        archive = ""
        if mounts:
            target = root / identifier
            if target.exists():
                shutil.rmtree(target)  # Left over from a deleted snapshot with the same number.
            staging.rename(target)
            archive = str(target)
        atomic(STATE / "pending-upgrade.json", json.dumps({"snapshot": identifier, "boot": archive}) + "\n")
    finally:
        shutil.rmtree(staging, ignore_errors=True)
    prune_boot_archives()
    extra = " and boot archives" if mounts else ""
    print(f"Recovery snapshot {identifier}{extra} created.")


POST_DESCRIPTIONS = {
    "success": "Eitr after package upgrade",
    "failed": "Eitr after failed package upgrade",
    "interrupted": "Eitr after interrupted package upgrade",
}


def snapshot_post(outcome="success"):
    path = STATE / "pending-upgrade.json"
    if not path.exists():
        return
    pending = json.loads(path.read_text())
    identifier = str(pending["snapshot"])
    if not identifier.isdigit():
        raise RuntimeError("Invalid pending snapshot")
    run(["snapper", "-c", "root", "create", "--type", "post", "--pre-number", identifier,
         "--description", POST_DESCRIPTIONS[outcome], "--cleanup-algorithm", "number"])
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


def write_u2f_keys(user, content):
    current = U2F_KEYS.read_text().splitlines() if U2F_KEYS.exists() else []
    current = [line for line in current if not line.startswith(user + ":")]
    # hyprlock runs PAM as the desktop user, so pam_u2f must be able to read
    # the authfile. It holds only public key handles, never secrets.
    atomic(U2F_KEYS, "\n".join([*current, content.strip()]) + "\n", mode=0o644, directory_mode=0o755)
    os.chmod(U2F_KEYS.parent, 0o755)


def read_user_u2f_keys(user, account):
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
    return content


def check_pam_files():
    for service in SERVICES:
        path = PAM / service
        if not path.is_file() or path.is_symlink():
            raise RuntimeError(f"Unsupported PAM file: {path}")


def restore_pam(backup, services=SERVICES):
    for service in services:
        source = backup / service
        if source.is_file():
            atomic(PAM / service, source.read_text(), mode=0o644, directory_mode=0o755)


def write_pam(method):
    """Rewrite each PAM file, restoring all of them if any write fails."""
    check_pam_files()
    backup = STATE / "pam-backups" / datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True, mode=0o700)
    for service in SERVICES:
        shutil.copy2(PAM / service, backup / service)
    enabled = SERVICES
    written = []
    try:
        for service in SERVICES:
            path = PAM / service
            written.append(service)
            atomic(path, pam_with_method(path.read_text(), method if service in enabled else "password"), mode=0o644)
    except BaseException:
        restore_pam(backup, written)
        raise
    return backup, enabled


def enable_auth(method):
    user = os.environ.get("SUDO_USER", "")
    if not user or user == "root":
        raise RuntimeError("Use sudo from your normal desktop user")
    account = pwd.getpwnam(user)
    if method == "fingerprint":
        run(["fprintd-list", user])
    elif method == "fido2":
        write_u2f_keys(user, read_user_u2f_keys(user, account))
    backup, enabled = write_pam(method)
    print(f"Authentication updated for {', '.join(enabled)}. Password fallback retained. Backup: {backup}")
    print(f"Undo with: sudo {sys.argv[0]} auth-restore {backup.name}")


def restore_auth(name):
    root = (STATE / "pam-backups").resolve()
    backup = (root / name).resolve()
    if backup.parent != root or not backup.is_dir():
        raise RuntimeError(f"No PAM backup named {name!r} in {root}")
    missing = [service for service in SERVICES if not (backup / service).is_file()]
    if missing:
        raise RuntimeError(f"Backup {name} is incomplete: missing {', '.join(missing)}")
    check_pam_files()
    restore_pam(backup)
    print(f"Restored {', '.join(SERVICES)} PAM files from {backup}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["snapshots-check", "snapshots-setup", "snapshot-pre", "snapshot-post",
                                           "auth-enable", "auth-restore"])
    parser.add_argument("argument", nargs="?",
                        help="auth-enable: fingerprint|fido2|password; auth-restore: backup name; "
                             "snapshot-post: success|failed")
    args = parser.parse_args()
    # The layout check is read-only, so the installer's --check can run it unprivileged.
    if args.action != "snapshots-check" and os.geteuid() != 0:
        parser.error("This root-owned helper must run through sudo or a pacman hook")
    try:
        if args.action == "snapshots-check":
            snapshot_supported()
        elif args.action == "snapshots-setup":
            setup_snapshots()
        elif args.action == "snapshot-pre":
            snapshot_pre()
        elif args.action == "snapshot-post":
            if args.argument not in (None, "success", "failed"):
                parser.error("snapshot-post outcome must be success or failed")
            snapshot_post(args.argument or "success")
        elif args.action == "auth-enable":
            if args.argument not in ("fingerprint", "fido2", "password"):
                parser.error("Authentication method required: fingerprint, fido2 or password")
            enable_auth(args.argument)
        elif args.action == "auth-restore":
            if not args.argument:
                parser.error("PAM backup name required")
            restore_auth(args.argument)
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + "\n")
