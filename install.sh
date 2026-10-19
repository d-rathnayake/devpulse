#!/usr/bin/env bash
# DevPulse installer · by d-rathnayake
set -euo pipefail

R=$'\033[1;31m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; B=$'\033[1;34m'
M=$'\033[1;35m'; C=$'\033[1;36m'; W=$'\033[1;37m'; D=$'\033[2m'; N=$'\033[0m'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${PREFIX:-$HOME/.local}/bin"

step() { printf "  %s[*]%s %s\n" "$B" "$N" "$1"; }
ok()   { printf "  %s[✔]%s %s\n" "$G" "$N" "$1"; }
warn() { printf "  %s[!]%s %s\n" "$Y" "$N" "$1"; }

banner() {
  clear 2>/dev/null || true
  printf "%s" "$M"
  cat <<'EOF'
  ____             ____        _
 |  _ \  _____   _|  _ \ _   _| |___  ___
 | | | |/ _ \ \ / / |_) | | | | / __|/ _ \
 | |_| |  __/\ V /|  __/| |_| | \__ \  __/
 |____/ \___| \_/ |_|    \__,_|_|___/\___|
EOF
  printf "%s" "$N"
  printf "  %s◆%s %sDevPulse%s %sv1.0.0%s   %s✦ by d-rathnayake%s\n" "$C" "$N" "$W" "$N" "$D" "$N" "$Y" "$N"
  printf "  %s────────────────────────────────────────────%s\n\n" "$D" "$N"
}

install_deps() {
  step "Checking dependencies (git, curl)"
  local need=()
  for dep in git curl; do
    command -v "$dep" >/dev/null 2>&1 || need+=("$dep")
  done
  if [ ${#need[@]} -eq 0 ]; then
    ok "Already installed"
    return
  fi
  if command -v pkg >/dev/null 2>&1; then
    pkg install -y "${need[@]}" >/dev/null
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y "${need[@]}" >/dev/null
  else
    warn "Install manually: ${need[*]}"
    return
  fi
  ok "Installed: ${need[*]}"
}

link_tool() {
  step "Linking 'devpulse' command"
  mkdir -p "$BIN"
  chmod +x "$ROOT/devpulse.sh"
  ln -sf "$ROOT/devpulse.sh" "$BIN/devpulse"
  case ":$PATH:" in
    *":$BIN:"*) ;;
    *) warn "PATH එකට add කරන්න: export PATH=\"$BIN:\$PATH\"" ;;
  esac
  ok "Run anywhere with: devpulse"
}

open_page() {
  if command -v termux-open-url >/dev/null 2>&1; then
    step "Opening banner page in your browser"
    if termux-open-url "file://$ROOT/assets/banner.svg"; then
      ok "Page opened"
    else
      warn "Browser open කරන්න බැරි වුණා"
    fi
  else
    warn "termux-open-url නැහැ, banner: $ROOT/assets/banner.svg"
  fi
}

banner
install_deps
link_tool
open_page
printf "\n  %s✦ Setup complete!%s DevPulse launch වෙනවා...\n" "$G" "$N"
sleep 1
exec "$ROOT/devpulse.sh"
