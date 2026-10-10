# Before Publishing Eitr

This repository is still the owner's personal desktop backup. Work through this
checklist before making it public or distributing an ISO. Each item lists why it
matters and the recommended fix. Figures were measured on 2026-10-10.

## 1. Separate the distro from the personal backup

The product and the owner's machine still live in one repository.

- `AGENTS.md` names the owner, their personal and work Git identities, and the
  `github-personal` SSH alias. `.githooks/` and `distro/tests/test_git_hooks.py`
  enforce those identities. Useful privately, but not part of a distro.
- Machine-specific settings (monitor layout, mouse, primary display) should
  live only in machine-local files such as `~/.config/hypr/local.lua`.
- Work tooling (AWS/Grafana menus) is generic now, but decide whether it
  belongs in the distro at all or in a personal overlay.

Recommended: create a clean public `eitr` repository for the distro and keep a
private overlay repository (identity hooks, AGENTS rules, personal configs,
`local.lua`) that is applied on top of the owner's machine.

## 2. Repository size and history

- The packed history is about 1 GB; the tracked tree is about 960 MB.
- Lockscreen videos (`quickshell/lockscreen/themes/*/bg.mp4`) total about
  260 MB, and PNG wallpapers and references about 620 MB. None use Git LFS.
- Deleting files now does not shrink history; every clone downloads it all.

Recommended: start the public repository from a fresh history (a squashed
initial import) rather than rewriting this one, which would require force
pushes. Keep large media out of Git: use Git LFS, or publish wallpaper and
lockscreen packs as release assets downloaded by the installer or package.
Replacing the lockscreen designs, as already planned, is a good moment to do
this.

## 3. Licensing and artwork rights

- There is no top-level `LICENSE`. Pick one for Eitr's own code and configs.
- `themes/IMPORT-LICENSE` is the MIT license of imported upstream theme files
  (copyright David Heinemeier Hansson). Keep it with those files and credit
  the source in the README.
- `quickshell/lockscreen/LICENSE` is GPL-3.0 from the upstream lockscreen code.
  Distributing it means meeting GPL obligations, and it constrains how that
  directory can be relicensed.
- `nvim/`, `quickshell/emoji-picker/` and
  `quickshell/desktop-bar/scripts/LICENSE.token-records` carry their own
  licenses; list all third-party components in a NOTICE or README section.
- `themes/ARTWORK.md` states that retained reference images are not cleared
  for distribution. `themes/*/references/` should not ship.
- Several wallpapers and lockscreen designs depict commercial franchises
  (Witcher fan art, The Last of Us, Hollow Knight, NieR: Automata, Arknights:
  Endfield and others). Fan art and franchise assets are generally not
  redistributable. Ship only original or clearly licensed artwork, and record
  each asset's source and license next to it.
- Fonts bundled with lockscreen designs (for example Google Sans) need their
  license files included, or they should be removed.

## 4. Secrets and personal data

A spot check found no credentials in the current tree or in the deleted
`distro/development.env` (version numbers only). Before publishing, scan the
full history with a dedicated tool, for example:

```sh
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:latest detect --source /repo
```

Also review: names and emails in commit metadata (all commits use the personal
identity), clone URLs pointing at `batistaerick/eitr`, and anything under
`HOME_FILES/` (shell history, tokens and SSH config must never be included).

## 5. Support tooling for other users

Once other people run Eitr, add a Walker "Collect diagnostics" action that
bundles `hyprctl configerrors`, package and component versions, the bar and
lockscreen logs, and recent journal excerpts into one archive, redacting WiFi
names, IP addresses, usernames and tokens. It turns "it doesn't work" reports
into something debuggable.

## Checklist

- [ ] Public distro repository created with fresh history; personal overlay split out
- [ ] Large media moved to Git LFS or release assets
- [ ] Top-level LICENSE chosen; third-party licenses and NOTICE complete
- [ ] Franchise and reference artwork removed or replaced with cleared assets
- [ ] Full-history secret scan clean
- [ ] Owner identity, hooks and AGENTS identity rules moved to the private overlay
- [ ] Diagnostics action available for bug reports
