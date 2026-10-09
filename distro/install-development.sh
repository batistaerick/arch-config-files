#!/usr/bin/env bash
# Called by the fresh-target installer, never as a live-desktop migration.
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  printf 'Install development tools as the desktop user, not root.\n' >&2
  exit 1
fi
distro_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$distro_dir/development.env"
export NVM_DIR="$HOME/.nvm"
export SDKMAN_DIR="$HOME/.sdkman"
installer_file="$(mktemp)"
trap 'rm -f -- "$installer_file"' EXIT

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$DISTRO_NVM_VERSION/install.sh" -o "$installer_file"
  PROFILE=/dev/null bash "$installer_file"
fi
(
  # Upstream shell managers do not support nounset consistently.
  set +u
  source "$NVM_DIR/nvm.sh"
  nvm install "$DISTRO_NODE_VERSION"
  nvm alias default "$DISTRO_NODE_VERSION"
  nvm use "$DISTRO_NODE_VERSION"
  npm install --global "pnpm@$DISTRO_PNPM_VERSION" "yarn@$DISTRO_YARN_VERSION"
)

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  curl -fsSL 'https://get.sdkman.io?ci=true&rcupdate=false' -o "$installer_file"
  bash "$installer_file"
fi
(
  set +eu
  source "$SDKMAN_DIR/bin/sdkman-init.sh" || exit 1
  sdkman_auto_answer=true
  sdk install java "$DISTRO_JAVA_VERSION" || exit 1
  sdk default java "$DISTRO_JAVA_VERSION" || exit 1
  sdk install maven "$DISTRO_MAVEN_VERSION" || exit 1
  sdk default maven "$DISTRO_MAVEN_VERSION" || exit 1
)
