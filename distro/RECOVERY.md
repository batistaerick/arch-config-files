# Eitr recovery snapshots

Snapshots are recovery points, **not off-machine backups**. A failed disk can
destroy the system and its snapshots together. Keep independent backups.

Eitr currently supports Snapper on a Btrfs root with `/usr`, `/etc` and
`/var/lib/pacman` in the same root subvolume. `/home` may be separate: it is not
covered by a root snapshot. Unsupported layouts fail closed before upgrades.
The installer does not format disks or rearrange existing subvolumes.

## Before updates

The installer enables `/etc/eitr/system-update-policy.conf`. Before
System → Update → System Update upgrades official and AUR packages, it:

1. Verifies the supported layout and Snapper root configuration.
2. Archives `/boot` and `/efi` only when they are separate mounts (a `/boot`
   directory inside the Btrfs root is already in the root snapshot). Archives
   are stored under `/var/lib/eitr/boot-backups/<snapshot-number>/` with
   root-only access.
3. Creates a pre-upgrade root snapshot.
4. Aborts the upgrade if boot backup or snapshot creation fails.

When the upgrade finishes, fails or is declined, the workflow creates the
corresponding post snapshot; its description records the outcome ("after
package upgrade", "after failed package upgrade"). If the workflow was killed
before that, the next System Update first closes the leftover pre snapshot
with an "after interrupted package upgrade" post snapshot. A failed upgrade
retains its pre snapshot and boot archives either way.
Updates to Flatpaks, SDKMAN/NVM runtimes and files on separate home subvolumes are
not protected by these snapshots. Advanced updates and direct pacman/yay commands
intentionally do not create automatic snapshots. Older Eitr snapshot hooks, if
manually installed, must be removed to adopt this policy.

New Snapper configurations keep up to 10 ordinary and 5 important numbered
snapshots through the cleanup timer. Existing policies are preserved. Boot
archives are pruned on each System Update to the newest 10, matching the
default snapshot limit; an archive may outlive its snapshot if Snapper removes
it first, so check the snapshot exists before restoring one. A full disk
prevents updates rather than skipping protection.

## Authentication changes

Security → Enable Fingerprint/FIDO2 backs up `/etc/pam.d/hyprlock`, `sddm` and
`sudo` under `/var/lib/eitr/pam-backups/<timestamp>/` before editing them, and
restores all three if any write fails. Fingerprint is added to all three, so
"password only" applies to the lockscreen too; pam_fprintd may delay the
password prompt for up to 10 seconds. To return to an earlier policy from a working root
shell or TTY:

```sh
sudo ls /var/lib/eitr/pam-backups
sudo /usr/lib/eitr/eitr-system auth-restore <timestamp>
# Without the eitr-desktop package, the helper is /usr/local/lib/eitr/eitr-system.
```

## TPM disk unlock

Security → TPM Disk Unlock can add a TPM2 key slot to a LUKS2 root so the disk
unlocks at boot without typing the passphrase. Nothing here runs from the
installer. The root helper (`luks-tpm-check`, `luks-recovery-key`,
`luks-tpm-enroll`, `luks-tpm-remove`) refuses unless the device is LUKS2, a TPM2
device is listed by `systemd-cryptenroll --tpm2-device=list`, and a passphrase
or recovery slot already exists. It only **adds** a slot; the passphrase stays.

- **Recovery key first.** The Walker flow offers
  `systemd-cryptenroll --recovery-key`; the key is printed once to the terminal
  and never stored. Write it down offline. It works at the normal passphrase prompt.
- **PCR choice.** Eitr binds to PCR 7 (Secure Boot state and keys). Firmware
  updates rarely change it, while a Secure Boot key change does. PCR 7 only
  protects much when Secure Boot is enabled with your own keys (see
  [SECURE-BOOT.md](SECURE-BOOT.md)); otherwise anyone can boot this machine
  with an edited kernel command line and get an unlocked disk. For stronger
  protection, enroll manually with a PIN:
  `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes <device>`.
- **Initramfs.** The busybox `encrypt` hook cannot use TPM2 tokens, so
  enrollment refuses while it is configured. Switching to `systemd` and
  `sd-encrypt` in `HOOKS` (with `rd.luks.name=<LUKS-UUID>=root` replacing
  `cryptdevice=` on the kernel command line, or `/etc/crypttab.initramfs`) is a
  boot-critical change Eitr leaves to you. Make it, run `sudo mkinitcpio -P`,
  update the boot entry, and confirm one passphrase boot works **before**
  enrolling the TPM.

If the TPM stops unlocking (firmware or Secure Boot change, TPM reset), the
passphrase prompt appears as before. Enter it, then remove and re-enroll. To
roll back completely, use Remove TPM Unlock, or from any working shell:

```sh
sudo systemd-cryptenroll /dev/<luks-partition>            # list slots
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/<luks-partition>
```

## Inspect recovery points

Use Walker → System → Snapshots, or run these read-only checks:

```sh
sudo snapper -c root list
findmnt -o TARGET,SOURCE,FSTYPE / /boot /efi
sudo du -sh /var/lib/eitr/boot-backups
```

If the desktop fails but the system still boots, switch to a text console or use
an SSH connection you configured yourself. If it does not boot, use the official
Arch installer ISO and mount the system's Btrfs filesystem. Identify the correct
disk, encryption mapping, root subvolume, snapshot number and EFI mount before
making any changes. Do not copy commands from another machine blindly.

## Boot an older snapshot

With GRUB or Limine, the boot menu can list read-only Snapper snapshots, so a
broken update can be inspected and rolled back without live media. The
installer offers this only after you type `yes`; on an existing installation run
`bash distro/bootloader/setup.sh` (`--check` only reports). Check the result with
Walker → System → Snapshots → Bootable Snapshot Status, or
`sudo /usr/local/lib/eitr/eitr-system snapshots-boot-status`.

| Boot loader | Integration | Packages (`distro/bootloader/`) |
|---|---|---|
| GRUB | `grub-btrfsd.service` rebuilds the "Arch Linux snapshots" submenu whenever Snapper adds or removes a snapshot | `grub-btrfs`, `inotify-tools` (official) |
| Limine | `limine-snapper-sync.service` adds snapshot entries to `limine.conf` | `limine-snapper-sync`, `limine-mkinitcpio-hook` (AUR) |
| systemd-boot | **Not supported.** It only loads kernels from the EFI/XBOOTLDR partition and cannot open Btrfs snapshots | Use the live-media procedure below |

Detection reads the GRUB, Limine and systemd-boot files under `/boot`, `/efi`
and `/boot/efi`. If more than one loader is configured (for example leftover
systemd-boot files next to GRUB), setup refuses rather than guessing; remove the
stale files or configure entries manually. Setup copies the current
`grub.cfg`/`limine.conf` to `/var/lib/eitr/boot-config-backups/<timestamp>/`
first, and enables the service for the next boot:

- **GRUB:** setup runs `grub-mkconfig -o /boot/grub/grub.cfg` once. If `/boot`
  is a separate partition, snapshot entries boot the *current* kernel; after a
  kernel update, restore the matching boot archive (see below) as well.
- **Limine:** `limine-snapper-sync` manages entries created by
  `limine-entry-tool` (from `limine-mkinitcpio-hook`) and keeps copies of each
  snapshot's kernel on the EFI partition, so that partition needs room (upstream
  recommends 4 GiB). Review `/etc/default/limine` (`SNAPPER_CONFIG_NAME="root"`,
  `ESP_PATH` if not detected), run `sudo limine-update`, check the menu, then
  `sudo systemctl start limine-snapper-sync.service`. Eitr does not run
  `limine-update` for you because it rewrites the boot menu.

To undo, disable the service and copy the backup back, for example
`sudo systemctl disable grub-btrfsd.service` and
`sudo cp /var/lib/eitr/boot-config-backups/<timestamp>/grub.cfg /boot/grub/grub.cfg`.

### Read-only snapshots

Snapper snapshots are read-only. A snapshot booted as-is cannot write `/var`, so
SDDM and other services may fail; log in on a text console (Ctrl+Alt+F3) if the
graphical login does not start. An initramfs overlay makes the booted snapshot
writable in RAM (changes vanish at reboot). Eitr does not edit `HOOKS`; add it
yourself, then regenerate, and note that only snapshots created afterwards
contain the hook:

- GRUB: append `grub-btrfs-overlayfs` to `HOOKS=(...)` in `/etc/mkinitcpio.conf`,
  then `sudo mkinitcpio -P`.
- Limine: add `btrfs-overlayfs` after `filesystems` (or `sd-btrfs-overlayfs`
  with the systemd hooks), then `sudo limine-update`.

### Roll back for good

1. Pick the newest "before package upgrade" snapshot in the boot menu's
   snapshot list and confirm the system works there.
2. **Limine:** run `sudo limine-snapper-restore` and choose the snapshot. It
   restores with the configured `RESTORE_METHOD` and adds a backup entry for the
   replaced system, so the restore itself can be reverted from the boot menu.
3. **GRUB:** `snapper rollback` only works when the root is mounted through the
   Btrfs default subvolume. Arch layouts usually boot `rootflags=subvol=@`
   (check `findmnt -no OPTIONS /` and `/etc/fstab`), so rollback would have no
   effect. Replace the root subvolume instead, from the booted snapshot or live
   media, adjusting names to `sudo btrfs subvolume list /`:

   ```sh
   sudo mount -o subvolid=5 /dev/<root-or-mapper> /mnt
   sudo mv /mnt/@ /mnt/@.broken
   sudo btrfs subvolume snapshot /mnt/@.snapshots/<number>/snapshot /mnt/@
   ```

   Restore the matching `/var/lib/eitr/boot-backups/<number>/` archive if `/boot`
   is separate, reboot into the normal entry, run
   `sudo grub-mkconfig -o /boot/grub/grub.cfg`, and delete `@.broken` with
   `sudo btrfs subvolume delete` only after the restored system is verified.

## Restore safely from live media

1. Back up any newer files you need. Mount the Btrfs top-level filesystem and
   inspect its subvolume list; locate the selected snapshot's `snapshot`
   subvolume. Paths depend on where `.snapshots` is mounted.
2. Preserve the failed root subvolume by renaming it. Create a **writable Btrfs
   snapshot** of the selected recovery snapshot at the original root-subvolume
   path, matching the installed bootloader's rootflags and fstab.
3. Mount that restored root and its actual boot/EFI partitions. Restore the
   matching boot archives if kernel/initramfs/bootloader files changed. Archives
   must match the chosen root snapshot; never mix a newer kernel with older modules.
4. Review fstab and bootloader configuration, then regenerate initramfs or repair
   boot entries from `arch-chroot` as needed for that machine. Reboot only after
   the root and boot files agree.

This is a layout-aware manual recovery procedure, **not a verified one-click
rollback implementation**. Snapper's `rollback` command alone is not sufficient
for arbitrary Arch subvolume/bootloader layouts. The GRUB and Limine snapshot
entries above still need validation on real hardware before claiming automatic
recovery.

References: [grub-btrfs](https://github.com/Antynea/grub-btrfs),
[limine-snapper-sync](https://gitlab.com/Zesko/limine-snapper-sync),
[Snapper recovery concepts](https://documentation.suse.com/sles/15-SP6/html/SLES-all/cha-snapper.html),
[Arch installation guide](https://wiki.archlinux.org/title/Installation_guide).
