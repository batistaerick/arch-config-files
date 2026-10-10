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


# Bootable snapshots. Detection only reads files under SYSTEM_ROOT, so tests
# can point it at a fake tree. ESP contents may need root to read (vfat masks).
SYSTEM_ROOT = Path("/")
ESP_CANDIDATES = ("efi", "boot", "boot/efi")
GRUB_CONFIG = "boot/grub/grub.cfg"
LIMINE_CONFIGS = ("limine.conf", "limine/limine.conf", "EFI/limine/limine.conf", "EFI/BOOT/limine.conf")
BOOT_INTEGRATIONS = {
    # Files and commands supplied by distro/bootloader/<name>[-aur].txt packages.
    "grub": {"unit": "grub-btrfsd.service", "files": ("etc/grub.d/41_snapshots-btrfs",),
             "commands": ("inotifywait", "grub-mkconfig")},
    "limine": {"unit": "limine-snapper-sync.service",
               "files": ("usr/lib/systemd/system/limine-snapper-sync.service",),
               "commands": ("limine-snapper-sync", "limine-update")},
}
UNSUPPORTED_BOOT = {
    "systemd-boot": "systemd-boot only loads kernels from the EFI/XBOOTLDR partition and cannot boot "
                    "Btrfs snapshots. Use the live-media recovery in RECOVERY.md instead.",
    "unknown": "No GRUB, Limine or systemd-boot configuration was found (run as root so the EFI "
               "partition is readable).",
}


def bootloader_evidence(root=None):
    """Return {loader: [paths]} for every boot loader configuration found."""
    root = Path(root or SYSTEM_ROOT)
    evidence = {}

    def found(loader, path):
        evidence.setdefault(loader, []).append("/" + str(path.relative_to(root)))

    if (root / GRUB_CONFIG).is_file():
        found("grub", root / GRUB_CONFIG)
    for directory in ESP_CANDIDATES:
        for name in LIMINE_CONFIGS:
            if (root / directory / name).is_file():
                found("limine", root / directory / name)
    for esp in ESP_CANDIDATES:
        efi = root / esp / "EFI"
        if (root / esp / "loader/loader.conf").is_file():
            found("systemd-boot", root / esp / "loader/loader.conf")
        elif (efi / "systemd").is_dir() and any((efi / "systemd").glob("systemd-boot*.efi")):
            found("systemd-boot", next((efi / "systemd").glob("systemd-boot*.efi")))
        if efi.is_dir() and "grub" not in evidence:
            for image in sorted(efi.glob("*/grub*.efi")):
                found("grub", image)
                break
    return evidence


def detect_bootloader(root=None):
    """Return (name, evidence); name is grub, limine, systemd-boot, unknown or ambiguous."""
    evidence = bootloader_evidence(root)
    if not evidence:
        return "unknown", evidence
    if len(evidence) > 1:
        return "ambiguous", evidence
    return next(iter(evidence)), evidence


def boot_integration_missing(loader, root=None):
    root = Path(root or SYSTEM_ROOT)
    spec = BOOT_INTEGRATIONS[loader]
    missing = ["/" + name for name in spec["files"] if not (root / name).is_file()]
    return missing + [name for name in spec["commands"] if not shutil.which(name)]


def unit_enabled(unit):
    return subprocess.run(["systemctl", "is-enabled", "--quiet", unit],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def supported_bootloader():
    loader, evidence = detect_bootloader()
    if loader == "ambiguous":
        listing = "; ".join(f"{name}: {', '.join(paths)}" for name, paths in evidence.items())
        raise RuntimeError(f"Several boot loaders are configured ({listing}). Remove stale loader files "
                           "or configure snapshot boot entries manually. Nothing was changed.")
    if loader not in BOOT_INTEGRATIONS:
        raise RuntimeError(f"Bootable snapshots are not supported with {loader}. {UNSUPPORTED_BOOT[loader]} "
                           "Nothing was changed.")
    return loader, evidence


def boot_snapshot_status():
    loader, evidence = detect_bootloader()
    print(f"Boot loader: {loader}")
    for name, paths in evidence.items():
        print(f"  {name}: {', '.join(paths)}")
    if loader == "ambiguous":
        print("Snapshot boot entries: unsupported until only one boot loader remains configured.")
        return 1
    if loader not in BOOT_INTEGRATIONS:
        print(f"Snapshot boot entries: unsupported. {UNSUPPORTED_BOOT[loader]}")
        return 1
    missing = boot_integration_missing(loader)
    if missing:
        print(f"Snapshot boot entries: not installed (missing {', '.join(missing)}).")
        print("Install them and enable snapshot entries with: bash distro/bootloader/setup.sh")
        return 1
    unit = BOOT_INTEGRATIONS[loader]["unit"]
    if not unit_enabled(unit):
        print(f"Snapshot boot entries: installed, but {unit} is not enabled.")
        return 1
    print(f"Snapshot boot entries: enabled through {unit}.")
    return 0


def backup_boot_config(path):
    target = STATE / "boot-config-backups" / datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    target.mkdir(parents=True, mode=0o700)
    shutil.copy2(path, target / path.name)
    return target / path.name


def setup_boot_snapshots():
    """Add snapshot boot entries for GRUB or Limine; refuse everything else."""
    snapshot_supported()
    run(["snapper", "-c", "root", "get-config"], stdout=subprocess.DEVNULL)
    loader, evidence = supported_bootloader()
    missing = boot_integration_missing(loader)
    if missing:
        raise RuntimeError(f"Missing {', '.join(missing)}. Install the {loader} packages listed in "
                           "distro/bootloader/ first. Nothing was changed.")
    unit = BOOT_INTEGRATIONS[loader]["unit"]
    if loader == "grub":
        config = SYSTEM_ROOT / GRUB_CONFIG
        backup = backup_boot_config(config)
        # grub-mkconfig validates a .new file before replacing grub.cfg.
        run(["grub-mkconfig", "-o", "/" + GRUB_CONFIG])
        run(["systemctl", "enable", unit])
        print(f"GRUB now lists Snapper snapshots in its 'Arch Linux snapshots' submenu. Backup: {backup}")
        if separate_boot_mounts():
            print("/boot is a separate partition: snapshot entries boot the current kernel. After a kernel "
                  "update, restore the matching boot archive as RECOVERY.md describes.")
    else:
        config = SYSTEM_ROOT / evidence["limine"][0].lstrip("/")
        backup = backup_boot_config(config)
        run(["systemctl", "enable", unit])
        print(f"{unit} is enabled; snapshot entries are written to {evidence['limine'][0]} from the next boot.")
        print(f"Review /etc/default/limine first, then run: sudo systemctl start {unit}")
        print(f"Backup of the current Limine menu: {backup}")
    print("Snapshot entries boot read-only; see RECOVERY.md before relying on them.")


# Laptop battery charge limit. Only batteries whose firmware driver exposes
# charge_control_end_threshold are supported; desktops have none.
POWER_SUPPLY = Path("/sys/class/power_supply")
BATTERY_LIMIT_CONFIG = Path("/etc/eitr/battery-limit")
SYSTEMD_SYSTEM = Path("/etc/systemd/system")
BATTERY_UNIT = "eitr-battery-limit.service"
INSTALLED_HELPER = "/usr/local/lib/eitr/eitr-system"
SLEEP_TARGETS = "suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target"
BATTERY_UNIT_CONTENT = f"""[Unit]
Description=Apply the Eitr battery charge limit
After={SLEEP_TARGETS}

[Service]
Type=oneshot
ExecStart={INSTALLED_HELPER} battery-limit-apply

[Install]
# Some firmware resets the threshold on resume, so it is applied again then.
WantedBy=multi-user.target {SLEEP_TARGETS}
"""


def limit_batteries():
    batteries = []
    for battery in sorted(POWER_SUPPLY.glob("BAT*")):
        try:
            kind = (battery / "type").read_text().strip()
        except OSError:
            continue
        if kind == "Battery" and (battery / "charge_control_end_threshold").is_file():
            batteries.append(battery)
    return batteries


def parse_battery_limit(value):
    """Return the end threshold for 60-100, or None for off."""
    if value == "off":
        return None
    if not value or not value.isdigit() or not 60 <= int(value) <= 100:
        raise ValueError("Battery limit must be a whole number from 60 to 100, or off")
    return int(value)


def write_battery_thresholds(limit, batteries):
    # Validate every battery before writing any, so a refusal changes nothing.
    for battery in batteries:
        start = battery / "charge_control_start_threshold"
        if limit < 100 and start.is_file() and int(start.read_text()) >= limit:
            raise RuntimeError(f"{battery.name} starts charging at {start.read_text().strip()}%; "
                               f"choose a limit above that. Nothing was changed.")
    for battery in batteries:
        (battery / "charge_control_end_threshold").write_text(f"{limit}\n")


def battery_limit(value):
    limit = parse_battery_limit(value)
    batteries = limit_batteries()
    if not batteries:
        raise RuntimeError("No battery with a firmware charge limit (charge_control_end_threshold) was found.")
    unit = SYSTEMD_SYSTEM / BATTERY_UNIT
    if limit is None:
        write_battery_thresholds(100, batteries)
        if unit.exists():
            run(["systemctl", "disable", BATTERY_UNIT])
            unit.unlink()
            run(["systemctl", "daemon-reload"])
        BATTERY_LIMIT_CONFIG.unlink(missing_ok=True)
        print("Battery charge limit removed; batteries charge to 100%.")
        return
    write_battery_thresholds(limit, batteries)
    atomic(BATTERY_LIMIT_CONFIG, f"{limit}\n", mode=0o644, directory_mode=0o755)
    atomic(unit, BATTERY_UNIT_CONTENT, mode=0o644, directory_mode=0o755)
    run(["systemctl", "daemon-reload"])
    run(["systemctl", "enable", BATTERY_UNIT])
    names = ", ".join(battery.name for battery in batteries)
    print(f"{names} now stop charging at {limit}%. The limit is restored at boot and after resume.")
    print(f"Undo with: sudo {INSTALLED_HELPER} battery-limit off")


def battery_limit_apply():
    if not BATTERY_LIMIT_CONFIG.is_file():
        return
    limit = parse_battery_limit(BATTERY_LIMIT_CONFIG.read_text().strip())
    batteries = limit_batteries()
    if limit is not None and batteries:
        write_battery_thresholds(limit, batteries)


def battery_limit_status():
    batteries = limit_batteries()
    if not batteries:
        print("No battery charge limit control on this machine.")
        return 1
    for battery in batteries:
        print(f"{battery.name}: stops charging at {(battery / 'charge_control_end_threshold').read_text().strip()}%")
    saved = BATTERY_LIMIT_CONFIG.read_text().strip() if BATTERY_LIMIT_CONFIG.is_file() else "none"
    print(f"Saved limit: {saved}")
    return 0


# TPM2 unlock for LUKS2. Every operation keeps the existing passphrase slot;
# nothing here runs from the installer.
MKINITCPIO_CONFIGS = (Path("/etc/mkinitcpio.conf"), Path("/etc/mkinitcpio.conf.d"))
TPM_PCRS = "7"
KEEP_SLOT_TYPES = {"password", "recovery"}


def is_block_device(path):
    return stat.S_ISBLK(os.stat(path).st_mode)


def luks2_device(device):
    if not device or not device.startswith("/dev/"):
        raise ValueError("Give the encrypted partition as a /dev path, for example /dev/nvme0n1p2")
    if not is_block_device(device):
        raise RuntimeError(f"{device} is not a block device")
    if subprocess.run(["cryptsetup", "isLuks", "--type", "luks2", device]).returncode:
        raise RuntimeError(f"{device} is not a LUKS2 volume. TPM unlock needs LUKS2.")
    return device


def enrolled_slot_types(device):
    """Parse `systemd-cryptenroll DEVICE`: a SLOT TYPE header, then one slot per line."""
    lines = output(["systemd-cryptenroll", device]).splitlines()[1:]
    return [line.split()[1] for line in lines if len(line.split()) >= 2]


def tpm2_devices():
    result = subprocess.run(["systemd-cryptenroll", "--tpm2-device=list"], capture_output=True, text=True)
    if result.returncode:
        return []
    return [line.split()[0] for line in result.stdout.splitlines() if line.startswith("/dev/")]


def initramfs_hooks():
    """Return the effective mkinitcpio HOOKS list, or None without mkinitcpio."""
    main, drop_ins = MKINITCPIO_CONFIGS
    files = ([main] if main.is_file() else []) + (sorted(drop_ins.glob("*.conf")) if drop_ins.is_dir() else [])
    hooks = None
    for path in files:
        for line in path.read_text().splitlines():
            line = line.strip()
            if line.startswith("HOOKS=(") and line.endswith(")"):
                hooks = line[len("HOOKS=("):-1].split()
    return hooks


def luks_tpm_check(device):
    luks2_device(device)
    slots = enrolled_slot_types(device)
    devices = tpm2_devices()
    hooks = initramfs_hooks()
    print(f"{device}: LUKS2, enrolled slots: {', '.join(slots) or 'none'}")
    print(f"TPM2 devices: {', '.join(devices) or 'none found'}")
    if hooks is None:
        print("Initramfs: mkinitcpio not found; make sure your initramfs unlocks with systemd-cryptsetup.")
    elif "sd-encrypt" in hooks:
        print("Initramfs: systemd sd-encrypt hook present; it tries the TPM2 token at boot.")
    else:
        print("Initramfs: the busybox 'encrypt' hook cannot use TPM2 tokens. Switch to the systemd and "
              "sd-encrypt hooks first (see RECOVERY.md, TPM disk unlock).")
    print(f"PCR policy: {TPM_PCRS} (Secure Boot state). Firmware or Secure Boot key changes require the "
          "passphrase once, then re-enrollment.")
    return slots, devices, hooks


def luks_tpm_enroll(device):
    slots, devices, hooks = luks_tpm_check(device)
    if not devices:
        raise RuntimeError("No TPM2 device found. Nothing was changed.")
    if hooks is not None and "sd-encrypt" not in hooks:
        raise RuntimeError("The initramfs cannot use TPM2 unlock yet. Nothing was changed.")
    if "tpm2" in slots:
        raise RuntimeError(f"{device} already has a TPM2 slot. Remove it first to re-enroll.")
    if not KEEP_SLOT_TYPES & set(slots):
        raise RuntimeError("No passphrase or recovery key slot found; refusing to rely on the TPM alone.")
    # Adds a slot; existing passphrase and recovery slots are left untouched.
    run(["systemd-cryptenroll", "--tpm2-device=auto", f"--tpm2-pcrs={TPM_PCRS}", device])
    print(f"TPM2 unlock enrolled for {device} with PCR {TPM_PCRS}. Your passphrase still works.")
    print(f"Undo with: sudo {INSTALLED_HELPER} luks-tpm-remove {device}")


def luks_recovery_key(device):
    luks2_device(device)
    # The key is printed to this terminal only; it is never written to disk.
    run(["systemd-cryptenroll", "--recovery-key", device])


def luks_tpm_remove(device):
    luks2_device(device)
    slots = enrolled_slot_types(device)
    if "tpm2" not in slots:
        print(f"{device} has no TPM2 slot.")
        return
    if not KEEP_SLOT_TYPES & set(slots):
        raise RuntimeError("No passphrase or recovery key slot remains; add one before removing TPM2 unlock.")
    run(["systemd-cryptenroll", "--wipe-slot=tpm2", device])
    print(f"TPM2 unlock removed from {device}; the passphrase is required at boot again.")


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


READ_ONLY_ACTIONS = {"snapshots-check", "bootloader-detect", "snapshots-boot-status", "battery-limit-status"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["snapshots-check", "snapshots-setup", "snapshot-pre", "snapshot-post",
                                           "bootloader-detect", "snapshots-boot-status", "snapshots-boot-setup",
                                           "battery-limit", "battery-limit-apply", "battery-limit-status",
                                           "luks-tpm-check", "luks-tpm-enroll", "luks-recovery-key", "luks-tpm-remove",
                                           "auth-enable", "auth-restore"])
    parser.add_argument("argument", nargs="?",
                        help="auth-enable: fingerprint|fido2|password; auth-restore: backup name; "
                             "snapshot-post: success|failed; battery-limit: 60-100|off; luks-*: /dev path")
    args = parser.parse_args()
    # Read-only checks may run unprivileged (an unreadable EFI partition then
    # reports "unknown"), so the installer's --check can use them.
    if args.action not in READ_ONLY_ACTIONS and os.geteuid() != 0:
        parser.error("This root-owned helper must run through sudo or a pacman hook")
    try:
        if args.action == "snapshots-check":
            snapshot_supported()
        elif args.action == "snapshots-setup":
            setup_snapshots()
        elif args.action == "bootloader-detect":
            print(detect_bootloader()[0])
        elif args.action == "snapshots-boot-status":
            sys.exit(boot_snapshot_status())
        elif args.action == "snapshots-boot-setup":
            setup_boot_snapshots()
        elif args.action == "battery-limit":
            battery_limit(args.argument)
        elif args.action == "battery-limit-apply":
            battery_limit_apply()
        elif args.action == "battery-limit-status":
            sys.exit(battery_limit_status())
        elif args.action == "luks-tpm-check":
            luks_tpm_check(args.argument)
        elif args.action == "luks-tpm-enroll":
            luks_tpm_enroll(args.argument)
        elif args.action == "luks-recovery-key":
            luks_recovery_key(args.argument)
        elif args.action == "luks-tpm-remove":
            luks_tpm_remove(args.argument)
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
