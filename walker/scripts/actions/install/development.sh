#!/usr/bin/env bash
# Optional development tools, invoked only by an explicit menu selection.
set -euo pipefail
[[ ${EUID} -ne 0 ]] || { echo 'Run as your normal user.' >&2; exit 1; }
kind="${1:-}"
installer="$(mktemp)"
trap 'rm -f -- "$installer"' EXIT
installer_url() {
  python3 "$(dirname "${BASH_SOURCE[0]}")/software.py" installer "$1"
}
download_run() {
  curl --proto '=https' --tlsv1.2 -fsSL "$1" -o "$installer"
  shift
  bash "$installer" "$@"
}
node_setup() {
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    PROFILE=/dev/null download_run "$(installer_url nvm)"
  fi
  set +u
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use default
  set -u
}
case "$kind" in
  node) node_setup ;;
  java)
    export SDKMAN_DIR="$HOME/.sdkman"
    if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
      download_run "$(installer_url sdkman)"
    fi
    lts="$(curl -fsSL "$(installer_url java-releases)" | python3 -c 'import json,sys; n=json.load(sys.stdin)["most_recent_lts"]; assert isinstance(n,int) and 8<=n<=99; print(n)')"
    set +eu
    source "$SDKMAN_DIR/bin/sdkman-init.sh" || exit 1
    sdkman_auto_answer=true
    versions="$(sdk list java)" || exit 1
    version="$(printf '%s' "$versions" | python3 -c 'import re,sys; major=sys.argv[1]; candidates=set(re.findall(r"\b"+major+r"(?:\.\d+){1,3}-tem\b",sys.stdin.read())); assert candidates,"No supported Temurin LTS found"; print(max(candidates,key=lambda s:tuple(map(int,s.split("-")[0].split(".")))))' "$lts")" || exit 1
    sdk install java "$version" || exit 1
    sdk default java "$version" || exit 1
    sdk install maven || exit 1
    ;;
  python) download_run "$(installer_url uv)"; "$HOME/.local/bin/uv" python install ;;
  rust) rustup toolchain install stable; rustup default stable ;;
  rails)
    mise use --global ruby@latest
    mise exec ruby -- gem install rails
    ;;
  laravel) composer global require laravel/installer ;;
  yarn|pnpm) node_setup; npm install --global "$kind" ;;
  bun) download_run "$(installer_url bun)" ;;
  deno) download_run "$(installer_url deno)" ;;
  codex|gemini)
    node_setup
    if [[ "$kind" == codex ]]; then npm install --global @openai/codex;
    else npm install --global @google/gemini-cli; fi
    ;;
  claude) download_run "$(installer_url claude)" ;;
  grok) download_run "$(installer_url grok)" ;;
  *) printf 'Unknown optional development tool: %s\n' "$kind" >&2; exit 2 ;;
esac
printf '\nInstalled %s. Open a new terminal to load its environment.\n' "$kind"
