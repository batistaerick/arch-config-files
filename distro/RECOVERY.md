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
sudo /usr/local/lib/eitr/eitr-system auth-restore <timestamp>
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
for arbitrary Arch subvolume/bootloader layouts. Bootable snapshot integration
must be validated during distro testing before claiming automatic recovery.

References: [Snapper recovery concepts](https://documentation.suse.com/sles/15-SP6/html/SLES-all/cha-snapper.html),
[Arch installation guide](https://wiki.archlinux.org/title/Installation_guide).
