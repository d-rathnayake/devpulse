#!/usr/bin/env bash
# DevPulse - terminal toolkit for Termux and Linux - by d-rathnayake
set -u

VERSION="1.1.0"
OWNER="d-rathnayake"
API="https://api.github.com"
PROFILE_URL="https://github.com/$OWNER"

if [ -t 1 ]; then
  HI=$'\033[1;36m'; OK=$'\033[1;32m'; WARN=$'\033[1;33m'; ERR=$'\033[1;31m'
  DIM=$'\033[2m'; KEY=$'\033[1;35m'; OFF=$'\033[0m'
else
  HI=""; OK=""; WARN=""; ERR=""; DIM=""; KEY=""; OFF=""
fi

COLS=$(tput cols 2>/dev/null || echo 80)
W=$(( COLS >= 72 ? 68 : COLS - 4 ))
[ "$W" -lt 30 ] && W=30

# Use the GitHub CLI login if no token was given (higher API rate limit)
if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN=$(gh auth token 2>/dev/null || true)
  export GITHUB_TOKEN
fi

# ---------- drawing helpers (ASCII only) ----------
line() { printf "  +%s+\n" "$(printf -- '-%.0s' $(seq 1 $((W-2))))"; }
top() {
  line
  printf "  | %s%-*s%s |\n" "$HI" $((W-4)) "$1" "$OFF"
  line
}
row() {
  local lw=16 v="${2:-}" max
  max=$((W-4-lw))
  if [ "${#v}" -gt "$max" ]; then v="${v:0:$((max-3))}..."; fi
  printf "  | %s%-*s%s%-*s |\n" "$DIM" "$lw" "$1" "$OFF" "$max" "$v"
}
info() { printf "  %s[ .. ]%s %s\n" "$HI" "$OFF" "$1"; }
ok()   { printf "  %s[ OK ]%s %s\n" "$OK" "$OFF" "$1"; }
fail() { printf "  %s[FAIL]%s %s\n" "$ERR" "$OFF" "$1"; }
pause() { printf "\n  %sPress Enter to return to the menu%s " "$DIM" "$OFF"; read -r _ || true; }
clr() { clear 2>/dev/null || printf '\033[2J\033[H'; }

mkbar() {
  local v="${1:-0}" m="${2:-1}" n="${3:-10}" f i out=""
  v=$(tr -cd '0-9' <<<"$v"); m=$(tr -cd '0-9' <<<"$m")
  [ -z "$v" ] && v=0
  if [ -z "$m" ] || [ "$m" -eq 0 ]; then m=1; fi
  f=$(( v * n / m ))
  if [ "$f" -gt "$n" ]; then f=$n; fi
  for ((i = 0; i < n; i++)); do
    if [ "$i" -lt "$f" ]; then out+="#"; else out+="."; fi
  done
  printf "[%s]" "$out"
}

fmt() {
  local n
  n=$(tr -cd '0-9' <<<"${1:-}")
  if [ -z "$n" ]; then printf -- "-"; return; fi
  sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' <<<"$n"
}

header() {
  clr
  top "DEVPULSE   v$VERSION   repo health and device toolkit"
  printf "  %s%s%s\n" "$HI" '_/\_/\__/\_/\__/\_/\__/\_/\__/\_' "$OFF"
  printf "  %sby %s%s\n\n" "$DIM" "$OWNER" "$OFF"
}

# ---------- data helpers ----------
net() {
  local args=(-fsS -m 12 -H "Accept: application/vnd.github+json" -H "User-Agent: devpulse")
  if [ -n "${GITHUB_TOKEN:-}" ]; then args+=(-H "Authorization: Bearer $GITHUB_TOKEN"); fi
  curl "${args[@]}" "$1" 2>/dev/null
}

# Reads "key": value from pretty JSON on stdin (no jq needed)
jget() {
  grep -o "\"$1\": *\(\"[^\"]*\"\|[^,}]*\)" | head -n1 | sed -E 's/^"[^"]*": *//; s/^"//; s/"$//'
}

days_since() {
  local t
  t=$(date -d "$1" +%s 2>/dev/null) || return 1
  echo $(( ( $(date +%s) - t ) / 86400 ))
}

# ---------- features ----------
cmd_profile() {
  header; top "DEVELOPER PROFILE"
  info "fetching profile"
  local j
  j=$(net "$API/users/$OWNER") || { fail "GitHub is not reachable right now"; pause; return; }
  row "Name"         "$(echo "$j" | jget name)"
  row "Login"        "$(echo "$j" | jget login)"
  row "Bio"          "$(echo "$j" | jget bio)"
  row "Public repos" "$(fmt "$(echo "$j" | jget public_repos)")"
  row "Followers"    "$(fmt "$(echo "$j" | jget followers)")"
  row "Following"    "$(fmt "$(echo "$j" | jget following)")"
  row "Member since" "$(echo "$j" | jget created_at | cut -c1-10)"
  row "Profile"      "$PROFILE_URL"
  line
  printf "\n"
  cmd_top_repos_body
  pause
}

cmd_top_repos_body() {
  local repos pairs top1
  repos=$(net "$API/users/$OWNER/repos?per_page=100&sort=updated") || { fail "could not load repos"; return; }
  pairs=$(paste <(echo "$repos" | grep -o '"stargazers_count": *[0-9]*' | sed -E 's/.*: *//') \
                <(echo "$repos" | grep -o '"full_name": *"[^"]*"' | sed -E 's/.*: *"//; s/"$//') \
          | sort -k1,1nr | head -n 5)
  top1=$(head -n1 <<<"$pairs" | cut -f1)
  top "TOP REPOSITORIES BY STARS"
  if [ -z "$pairs" ]; then row "Repos" "none found"; line; return; fi
  while IFS=$'\t' read -r s n; do
    row "$n" "$(fmt "$s") $(mkbar "$s" "$top1" 12)"
  done <<<"$pairs"
  line
}

cmd_scan() {
  header; top "REPOSITORY HEALTH SCAN"
  printf "  %sRepository (owner/name)%s\n  > " "$DIM" "$OFF"
  local repo j
  read -r repo || return
  if ! [[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    fail "use the form owner/name, e.g. $OWNER/devpulse"; pause; return
  fi
  info "scanning $repo"
  j=$(net "$API/repos/$repo") || { fail "repository not found, or it is private"; pause; return; }

  local stars forks issues pushed archived lang lic desc branch days score
  stars=$(echo "$j" | jget stargazers_count)
  forks=$(echo "$j" | jget forks_count)
  issues=$(echo "$j" | jget open_issues_count)
  pushed=$(echo "$j" | jget pushed_at | cut -c1-10)
  archived=$(echo "$j" | jget archived)
  lang=$(echo "$j" | jget language)
  desc=$(echo "$j" | jget description)
  branch=$(echo "$j" | jget default_branch)
  if grep -q '"license": *null' <<<"$j"; then lic="none"; else lic=$(echo "$j" | grep -o '"spdx_id": *"[^"]*"' | head -n1 | sed -E 's/.*: *"//; s/"$//'); fi
  days=$(days_since "$pushed") || days=0

  # Simple, transparent score (out of 100)
  score=0
  if [ "$days" -le 30 ]; then score=$((score+40)); elif [ "$days" -le 180 ]; then score=$((score+20)); elif [ "$days" -le 365 ]; then score=$((score+10)); fi
  if [ "$archived" != "true" ]; then score=$((score+20)); fi
  issues=$(tr -cd '0-9' <<<"$issues"); [ -z "$issues" ] && issues=0
  if [ "$issues" -le 10 ]; then score=$((score+20)); elif [ "$issues" -le 50 ]; then score=$((score+12)); elif [ "$issues" -le 200 ]; then score=$((score+5)); fi
  if [ -n "$desc" ] && [ "$desc" != "null" ]; then score=$((score+10)); fi
  if [ "$lic" != "none" ]; then score=$((score+10)); fi

  printf "\n"
  top "REPORT   $repo"
  row "Health score" "$score / 100 $(mkbar "$score" 100 24)"
  row "Stars"        "$(fmt "$stars")"
  row "Forks"        "$(fmt "$forks")"
  row "Open issues"  "$(fmt "$issues")"
  row "Language"     "${lang:--}"
  row "License"      "$lic"
  row "Branch"       "${branch:--}"
  row "Last push"    "$pushed ($days days ago)"
  row "Archived"     "${archived:--}"
  line
  top "CHECKS"
  if [ "$days" -le 30 ]; then row "Freshness" "PASS  pushed within 30 days"; else row "Freshness" "WARN  no push for $days days"; fi
  if [ "$archived" != "true" ]; then row "Maintenance" "PASS  repository is active"; else row "Maintenance" "WARN  archived"; fi
  if [ "$issues" -le 50 ]; then row "Issue load" "PASS  $issues open"; else row "Issue load" "WARN  $issues open"; fi
  if [ "$lic" != "none" ]; then row "License" "PASS  $lic"; else row "License" "WARN  no license file"; fi
  if [ -n "$desc" ] && [ "$desc" != "null" ]; then row "Description" "PASS  present"; else row "Description" "WARN  missing"; fi
  line
  pause
}

cmd_commits() {
  header; top "RECENT COMMITS"
  printf "  %sRepository (owner/name)%s\n  > " "$DIM" "$OFF"
  local repo j msgs n=0
  read -r repo || return
  if ! [[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    fail "use the form owner/name"; pause; return
  fi
  info "loading commits"
  j=$(net "$API/repos/$repo/commits?per_page=8") || { fail "could not load commits"; pause; return; }
  msgs=$(grep -o '"message": *"[^"]*"' <<<"$j" | sed -E 's/^"message": *"//; s/"$//; s/\\n.*//' | head -n 8)
  printf "\n"
  top "$repo"
  while IFS= read -r m; do
    n=$((n+1))
    row "#$n" "$m"
  done <<<"$msgs"
  line
  pause
}

cmd_device() {
  header; top "DEVICE REPORT"
  local kernel arch cores memt memav used pct dsk dtot dused dav dpct batt
  kernel="$(uname -sr)"; arch="$(uname -m)"; cores="$(nproc 2>/dev/null || echo 1)"
  memt=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null); memav=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null)
  memt=${memt:-0}; memav=${memav:-0}
  used=$(( (memt - memav) / 1024 ))
  pct=0; [ "$memt" -gt 0 ] && pct=$(( (memt - memav) * 100 / memt ))
  dsk=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print $2, $3, $4, $5}')
  dtot=$(awk '{print $1}' <<<"$dsk"); dused=$(awk '{print $2}' <<<"$dsk"); dav=$(awk '{print $3}' <<<"$dsk"); dpct=$(awk '{print $4}' <<<"$dsk" | tr -d '%')
  row "Kernel"  "$kernel"
  row "Arch"    "$arch"
  row "CPU cores" "$cores"
  row "Shell"   "bash ${BASH_VERSION%%(*}"
  row "Git"     "$(git --version 2>/dev/null | awk '{print $3}')"
  line
  top "MEMORY"
  row "RAM used" "$(fmt $((used))) MB  $(mkbar "$pct" 100 20) $pct%"
  line
  top "STORAGE  (HOME)"
  row "Total"   "$(fmt $(( ${dtot:-0} / 1024 ))) MB"
  row "Used"    "$(fmt $(( ${dused:-0} / 1024 ))) MB  $(mkbar "${dpct:-0}" 100 20) ${dpct:-0}%"
  row "Free"    "$(fmt $(( ${dav:-0} / 1024 ))) MB"
  line
  if command -v termux-battery-status >/dev/null 2>&1; then
    batt=$(termux-battery-status 2>/dev/null | grep -o '"percentage": *[0-9]*' | sed -E 's/.*: *//')
    top "POWER"
    row "Battery" "${batt:-unknown}%  $(mkbar "${batt:-0}" 100 20)"
    line
  fi
  pause
}

cmd_link() {
  header; top "PROFILE LINK"
  row "GitHub" "$PROFILE_URL"
  line
  pause
}

menu() {
  header
  top "MENU"
  row "[1]" "Developer profile overview"
  row "[2]" "Repository health scan"
  row "[3]" "Top repositories"
  row "[4]" "Recent commits"
  row "[5]" "Device report"
  row "[6]" "Profile link"
  row "[0]" "Exit"
  line
  printf "  %s>%s " "$KEY" "$OFF"
}

trap 'printf "\n"; exit 0' INT TERM

if [ "${1:-}" = "--version" ]; then echo "devpulse $VERSION"; exit 0; fi

while true; do
  menu
  read -r choice || exit 0
  case "$choice" in
    1) cmd_profile ;;
    2) cmd_scan ;;
    3) header; cmd_top_repos_body; pause ;;
    4) cmd_commits ;;
    5) cmd_device ;;
    6) cmd_link ;;
    0|q|Q) printf "  Bye.\n"; exit 0 ;;
    *) ;;
  esac
done
