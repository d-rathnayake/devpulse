#!/usr/bin/env bash
# DevPulse · terminal toolkit · by d-rathnayake
set -u

VERSION="1.0.0"
OWNER="d-rathnayake"
API="https://api.github.com"
PROFILE_URL="https://github.com/$OWNER"

R=$'\033[1;31m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; B=$'\033[1;34m'
M=$'\033[1;35m'; C=$'\033[1;36m'; W=$'\033[1;37m'; D=$'\033[2m'; N=$'\033[0m'

COLS=$(tput cols 2>/dev/null || echo 80)
WIDTH=$(( COLS < 64 ? COLS - 4 : 60 ))

rule()  { printf "  %s%s%s\n" "$D" "$(printf '─%.0s' $(seq 1 "$WIDTH"))" "$N"; }
err()   { printf "  %s✖%s %s\n" "$R" "$N" "$1"; }
pause() { printf "\n  %sEnter ඔබන්න…%s" "$D" "$N"; read -r _ || true; }

title() { printf "\n  %s▌ %s%s\n" "$M" "$1" "$N"; rule; }

kv() {
  local v="${2:-}"
  if [ -z "$v" ] || [ "$v" = "null" ]; then v="—"; fi
  printf "  %s%-12s%s %s\n" "$C" "$1" "$N" "$v"
}

header() {
  clear 2>/dev/null || true
  if [ "$COLS" -ge 64 ]; then
    printf "  %s◆━━ DEVPULSE ━━◆%s  %sv%s%s\n" "$C" "$N" "$D" "$VERSION" "$N"
  else
    printf "  %s◆ DevPulse%s v%s\n" "$C" "$N" "$VERSION"
  fi
  printf "  %s✦ by %s%s%s\n" "$Y" "$W" "$OWNER" "$N"
  rule
}

# JSON value එකක් grep/sed වලින් ගන්නවා (jq ඕනේ නැහැ). String values වල commas තියෙනවා නම් ඒවත් ගන්නවා.
jget() {
  grep -o "\"$1\": *\(\"[^\"]*\"\|[^,}]*\)" | head -n1 | sed -E 's/^"[^"]*": *//; s/^"//; s/"$//'
}

net() { curl -fsS -m 10 "$1" 2>/dev/null; }

cmd_profile() {
  header; title "Developer profile"
  local j
  j=$(net "$API/users/$OWNER") || { err "GitHub වෙත යන්න බැරි වුණා"; pause; return; }
  kv "Name"         "$(echo "$j" | jget name)"
  kv "Login"        "$(echo "$j" | jget login)"
  kv "Bio"          "$(echo "$j" | jget bio)"
  kv "Public repos" "$(echo "$j" | jget public_repos)"
  kv "Followers"    "$(echo "$j" | jget followers)"
  kv "Joined"       "$(echo "$j" | jget created_at | cut -c1-10)"
  kv "Profile"      "$PROFILE_URL"
  pause
}

cmd_scan() {
  header; title "Repository scan"
  printf "  %srepo (owner/name)%s › " "$C" "$N"
  read -r repo || return
  if ! [[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    err "Format වැරදියි (උදා: d-rathnayake/devpulse)"; pause; return
  fi
  local j
  j=$(net "$API/repos/$repo") || { err "Repo එක නැහැ හෝ private"; pause; return; }
  printf "\n"
  kv "Repo"        "$repo"
  kv "Stars"       "$(echo "$j" | jget stargazers_count)"
  kv "Forks"       "$(echo "$j" | jget forks_count)"
  kv "Open issues" "$(echo "$j" | jget open_issues_count)"
  kv "Language"    "$(echo "$j" | jget language)"
  kv "Branch"      "$(echo "$j" | jget default_branch)"
  kv "Last push"   "$(echo "$j" | jget pushed_at | cut -c1-10)"
  kv "Archived"    "$(echo "$j" | jget archived)"
  pause
}

cmd_sys() {
  header; title "Device"
  kv "OS"     "$(uname -sr)"
  kv "Arch"   "$(uname -m)"
  kv "Shell"  "bash ${BASH_VERSION%%(*}"
  kv "Git"    "$(git --version 2>/dev/null | awk '{print $3}')"
  kv "Disk"   "$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4" free / "$2}')"
  kv "Uptime" "$(uptime -p 2>/dev/null || uptime | sed 's/.*up //; s/,.*//')"
  kv "Term"   "${COLS} columns"
  pause
}

menu() {
  header
  printf "\n  %s1%s  %sDeveloper profile%s\n" "$C" "$N" "$W" "$N"
  printf "  %s2%s  %sScan a repository%s\n"   "$C" "$N" "$W" "$N"
  printf "  %s3%s  %sDevice info%s\n"         "$C" "$N" "$W" "$N"
  printf "  %s4%s  %sOpen GitHub profile%s\n" "$C" "$N" "$W" "$N"
  printf "  %s0%s  %sExit%s\n\n"              "$C" "$N" "$W" "$N"
  printf "  %s❯%s " "$M" "$N"
}

trap 'printf "\n"; exit 0' INT TERM

while true; do
  menu
  read -r choice || exit 0
  case "$choice" in
    1) cmd_profile ;;
    2) cmd_scan ;;
    3) cmd_sys ;;
    4)
      termux-open-url "$PROFILE_URL" 2>/dev/null || printf "  %s\n" "$PROFILE_URL"
      pause ;;
    0|q|Q) printf "  %sBye 👋%s\n" "$M" "$N"; exit 0 ;;
    *) ;;
  esac
done
