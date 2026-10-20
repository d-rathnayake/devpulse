#!/usr/bin/env bash
# DevPulse installer - by d-rathnayake
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${PREFIX:-$HOME/.local}/bin"
TOTAL=4
STEP=0

if [ -t 1 ]; then
  HI=$'\033[1;36m'; OK=$'\033[1;32m'; WARN=$'\033[1;33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
else
  HI=""; OK=""; WARN=""; DIM=""; OFF=""
fi

step() { STEP=$((STEP+1)); printf "  %s[%d/%d]%s %s" "$HI" "$STEP" "$TOTAL" "$OFF" "$1"; }
done_ok() { printf " %s[ OK ]%s\n" "$OK" "$OFF"; }
done_warn() { printf " %s[WARN]%s %s\n" "$WARN" "$OFF" "$1"; }

printf "\n  %sDEVPULSE INSTALLER%s  v1.1.0\n" "$HI" "$OFF"
printf "  %s------------------------------------------------%s\n\n" "$DIM" "$OFF"

step "Checking required tools (git, curl)"
need=()
for dep in git curl; do
  if ! command -v "$dep" >/dev/null 2>&1; then need+=("$dep"); fi
done
if [ ${#need[@]} -eq 0 ]; then
  done_ok
else
  printf "\n"
  if command -v pkg >/dev/null 2>&1; then
    step "Installing: ${need[*]}"; pkg install -y "${need[@]}" >/dev/null 2>&1 && done_ok || done_warn "install manually"
  elif command -v apt-get >/dev/null 2>&1; then
    step "Installing: ${need[*]}"; sudo apt-get install -y "${need[@]}" >/dev/null 2>&1 && done_ok || done_warn "install manually"
  else
    done_warn "missing: ${need[*]}"
  fi
fi

step "Linking the devpulse command"
mkdir -p "$BIN"
chmod +x "$ROOT/devpulse.sh"
ln -sf "$ROOT/devpulse.sh" "$BIN/devpulse"
done_ok

step "Verifying the install"
if "$ROOT/devpulse.sh" --version >/dev/null 2>&1; then done_ok; else done_warn "run: bash $ROOT/devpulse.sh"; fi

printf "\n  %sSetup complete.%s Run it with:  devpulse\n" "$OK" "$OFF"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) printf "  %sAdd this to ~/.bashrc:%s  export PATH=\"%s:\$PATH\"\n" "$WARN" "$OFF" "$BIN" ;;
esac
printf "\n"
