#!/usr/bin/env bash
# DevPulse installer - by d-rathnayake
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${PREFIX:-$HOME/.local}/bin"
TOTAL=4
STEP=0

if [ -t 1 ]; then
  CYAN=$'\e[1;38;5;51m'; PINK=$'\e[1;38;5;213m'; GREEN=$'\e[1;38;5;84m'
  AMBER=$'\e[1;38;5;220m'; GREY=$'\e[38;5;245m'; RST=$'\e[0m'
else
  CYAN=""; PINK=""; GREEN=""; AMBER=""; GREY=""; RST=""
fi

step() {
  STEP=$((STEP + 1))
  printf "  %s[%d/%d]%s %s " "$CYAN" "$STEP" "$TOTAL" "$RST" "$1"
}
done_ok() { printf "%s[ OK ]%s\n" "$GREEN" "$RST"; }
done_warn() { printf "%s[WARN]%s %s\n" "$AMBER" "$RST" "$1"; }

printf "\n  %sDEVPULSE%s  %sinstaller  |  dev: d-rathnayake%s\n" "$CYAN" "$RST" "$GREY" "$RST"
printf "  %s--------------------------------------%s\n\n" "$GREY" "$RST"

step "Checking tools (git, curl)"
need=()
for dep in git curl; do
  if ! command -v "$dep" >/dev/null 2>&1; then need+=("$dep"); fi
done
if [ ${#need[@]} -eq 0 ]; then
  done_ok
elif command -v pkg >/dev/null 2>&1; then
  printf "\n"
  step "Installing ${need[*]}"
  if pkg install -y "${need[@]}" >/dev/null 2>&1; then done_ok; else done_warn "run: pkg install ${need[*]}"; fi
elif command -v apt-get >/dev/null 2>&1; then
  printf "\n"
  step "Installing ${need[*]}"
  if sudo apt-get install -y "${need[@]}" >/dev/null 2>&1; then done_ok; else done_warn "run: sudo apt-get install ${need[*]}"; fi
else
  done_warn "missing: ${need[*]}"
fi

step "Linking the devpulse command"
mkdir -p "$BIN"
chmod +x "$ROOT/devpulse.sh"
ln -sf "$ROOT/devpulse.sh" "$BIN/devpulse"
done_ok

step "Verifying"
if "$ROOT/devpulse.sh" --version >/dev/null 2>&1; then done_ok; else done_warn "try: bash $ROOT/devpulse.sh"; fi

printf "\n  %sReady.%s Start the tool with:  %sdevpulse%s\n" "$GREEN" "$RST" "$PINK" "$RST"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) printf "  %sAdd to ~/.bashrc:%s export PATH=\"%s:\$PATH\"\n" "$AMBER" "$RST" "$BIN" ;;
esac
printf "\n"
