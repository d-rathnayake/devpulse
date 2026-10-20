#!/usr/bin/env bash
# DevPulse - terminal toolkit for Termux and Linux - by d-rathnayake
set -u

VERSION="V1"
OWNER="d-rathnayake"
API="https://api.github.com"
PROFILE_URL="https://github.com/$OWNER"

# ---------- colours (only when writing to a terminal) ----------
if [ -t 1 ]; then
  RST=$'\e[0m'; BOLD=$'\e[1m'; DIM=$'\e[2m'
  CYAN=$'\e[38;5;51m'; VIOLET=$'\e[38;5;135m'; PINK=$'\e[38;5;213m'
  GREEN=$'\e[38;5;84m'; AMBER=$'\e[38;5;220m'; RED=$'\e[38;5;203m'
  GREY=$'\e[38;5;245m'; WHITE=$'\e[38;5;255m'
  BG_V=$'\e[48;5;92m'; BG_C=$'\e[48;5;31m'; BG_G=$'\e[48;5;29m'
else
  RST=""; BOLD=""; DIM=""; CYAN=""; VIOLET=""; PINK=""; GREEN=""; AMBER=""; RED=""
  GREY=""; WHITE=""; BG_V=""; BG_C=""; BG_G=""
fi

# ---------- layout: measured from the terminal on every draw (auto-scales) ----------
refresh_layout() {
  local size r c
  size=$(stty size 2>/dev/null) || size=""
  read -r r c <<<"$size" || true
  if [ -z "${c:-}" ]; then c=$(tput cols 2>/dev/null) || c=""; fi
  if [ -z "${c:-}" ]; then c=50; fi
  ROWS=${r:-24}
  COLS=$c
  W=$(( COLS - 2 ))
  if [ "$W" -gt 68 ]; then W=68; fi
  if [ "$W" -lt 28 ]; then W=28; fi
  NARROW=0
  if [ "$W" -lt 50 ]; then NARROW=1; fi
  BIG=0
  if [ "$COLS" -ge 52 ] && [ "$ROWS" -ge 24 ]; then BIG=1; fi
}
refresh_layout

# ---------- GitHub token: use the gh login when no token is set ----------
if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN=$(gh auth token 2>/dev/null || true)
  export GITHUB_TOKEN
fi

# ---------- text helpers ----------
vlen() {
  local s="$1" re=$'\e\\[[0-9;]*m'
  while [[ $s =~ $re ]]; do
    s=${s/"${BASH_REMATCH[0]}"/}
  done
  printf '%s' "$s" | LC_ALL=C tr -d '\200-\277' | LC_ALL=C wc -c | tr -d ' '
}

trunc() {
  local s="$1" max="$2"
  if [ "${#s}" -gt "$max" ] && [ "$max" -gt 3 ]; then
    s="${s:0:$((max-3))}..."
  fi
  echo "$s"
}

fmt() {
  local n
  n=$(tr -cd '0-9' <<<"${1:-}")
  if [ -z "$n" ]; then echo "-"; return; fi
  sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' <<<"$n"
}

plural() {
  if [ "$1" = "1" ]; then echo "$2"; else echo "$3"; fi
}

badge() {
  printf "%s%s%s %s %s" "$1" "$BOLD" "$WHITE" "$2" "$RST"
}

bar() {
  local v="${1:-0}" m="${2:-1}" n="${3:-10}" c="${4:-$GREEN}" f i on="" off=""
  v=$(tr -cd '0-9' <<<"$v"); m=$(tr -cd '0-9' <<<"$m")
  if [ -z "$v" ]; then v=0; fi
  if [ -z "$m" ] || [ "$m" -eq 0 ]; then m=1; fi
  f=$(( v * n / m ))
  if [ "$f" -gt "$n" ]; then f=$n; fi
  for ((i = 0; i < f; i++)); do on+="█"; done
  for ((i = f; i < n; i++)); do off+="░"; done
  printf "%s%s%s%s%s" "$c" "$on" "$GREY" "$off" "$RST"
}

# colour for a score (higher is better)
good_col() {
  if [ "$1" -ge 70 ]; then echo "$GREEN"; elif [ "$1" -ge 40 ]; then echo "$AMBER"; else echo "$RED"; fi
}
# colour for a usage level (higher is worse)
load_col() {
  if [ "$1" -ge 85 ]; then echo "$RED"; elif [ "$1" -ge 60 ]; then echo "$AMBER"; else echo "$GREEN"; fi
}

# ---------- box drawing (fits the phone width) ----------
hline() {
  printf "  %s╠%s╣%s\n" "$VIOLET" "$(rep $((W-2)) '═')" "$RST"
}

frow() {
  local t="$1" vl pad
  vl=$(vlen "$t")
  pad=$(( W - 4 - vl ))
  if [ "$pad" -lt 0 ]; then pad=0; fi
  printf "  %s║%s %s%*s %s║%s\n" "$VIOLET" "$RST" "$t" "$pad" "" "$VIOLET" "$RST"
}

bottom() {
  printf "  %s╚%s╝%s\n" "$VIOLET" "$(rep $((W-2)) '═')" "$RST"
}

# section TITLE -> double-line title box with an icon, sized to the screen
section() {
  local t="$1" icon="+" inner label vl pad left right
  inner=$(( W - 2 ))
  case "$t" in
    "DEVELOPER PROFILE") icon="@" ;;
    "RECENT COMMITS") icon=">" ;;
    "TOP REPOSITORIES") icon="*" ;;
    "DEVICE REPORT"|"SYSTEM"|"MEMORY"|"STORAGE  (HOME)"|"POWER") icon="#" ;;
    "PROFILE LINK") icon="~" ;;
    "MENU") icon="=" ;;
  esac
  label=" $icon  $(trunc "$t" $(( inner - 8 ))) "
  vl=${#label}
  pad=$(( inner - vl ))
  if [ "$pad" -lt 0 ]; then pad=0; fi
  left=$(( pad / 2 ))
  right=$(( pad - left ))
  printf "  %s╔%s╗%s\n" "$VIOLET" "$(rep "$inner" '═')" "$RST"
  printf "  %s║%s%*s%s%s%s%s%*s%s║%s\n" "$VIOLET" "$RST" "$left" "" "$BOLD" "$CYAN" "$label" "$RST" "$right" "" "$VIOLET" "$RST"
  printf "  %s╠%s╣%s\n" "$VIOLET" "$(rep "$inner" '═')" "$RST"
}

menu_item() {
  local n="$1" bg="$2" name="$3" hint="$4"
  if [ "$NARROW" -eq 1 ]; then
    frow "$(badge "$bg" "$n") ${BOLD}${name}${RST}"
  else
    frow "$(badge "$bg" "$n") ${BOLD}${name}${RST}  ${GREY}${hint}${RST}"
  fi
}

menu() {
  home_header
  section "MENU"
  menu_item 1 "$BG_V" "Developer profile" "profile and top repos"
  menu_item 2 "$BG_C" "Repository health scan" "score out of 100"
  menu_item 3 "$BG_G" "Top repositories" "ranked by stars"
  menu_item 4 "$BG_V" "Recent commits" "latest changes"
  menu_item 5 "$BG_C" "Device report" "system and storage"
  menu_item 6 "$BG_G" "Profile link" "open on GitHub"
  menu_item 0 "$GREY" "Exit" "close DevPulse"
  bottom
  printf "\n  %s>%s " "$PINK$BOLD" "$RST"
}


kv() {
  local label="$1" value="$2" lab max
  if [ "$NARROW" -eq 1 ]; then
    frow "${GREY}${label}${RST}"
    frow "  ${value}"
  else
    lab=$(printf '%-12s' "$label")
    frow "${GREY}${lab}${RST} ${value}"
  fi
}

check() {
  local name="$1" ok="$2" msg="$3"
  if [ "$ok" -eq 1 ]; then
    frow "$(badge "$BG_G" PASS) ${name}  ${GREY}${msg}${RST}"
  else
    frow "$(badge "$BG_V" WARN) ${name}  ${GREY}${msg}${RST}"
  fi
}

info() { printf "  %s>>%s %s\n" "$CYAN" "$RST" "$1"; }
fail() { printf "  %s!!%s %s\n" "$RED" "$RST" "$1"; }
pause() {
  bottom
  printf "\n  %sPress Enter to go back%s " "$DIM" "$RST"
  read -r _ || true
}
clr() { clear 2>/dev/null || printf '\e[2J\e[H'; }

# ---------- banner: framed block letters with a colour gradient ----------
glyph() {
  case "$1" in
    D) GLYPH=('██████╗ ' '██╔══██╗' '██║  ██║' '██║  ██║' '██████╔╝' '╚═════╝ ') ;;
    E) GLYPH=('███████╗' '██╔════╝' '█████╗  ' '██╔══╝  ' '███████╗' '╚══════╝') ;;
    V) GLYPH=('██╗   ██╗' '██║   ██║' '██║   ██║' '╚██╗ ██╔╝' ' ╚████╔╝ ' '  ╚═══╝  ') ;;
    P) GLYPH=('██████╗ ' '██╔══██╗' '██████╔╝' '██╔═══╝ ' '██║     ' '╚═╝     ') ;;
    U) GLYPH=('██╗   ██╗' '██║   ██║' '██║   ██║' '██║   ██║' '╚██████╔╝' ' ╚═════╝ ') ;;
    L) GLYPH=('██╗     ' '██║     ' '██║     ' '██║     ' '███████╗' '╚══════╝') ;;
    S) GLYPH=('███████╗' '██╔════╝' '███████╗' '╚════██║' '███████║' '╚══════╝') ;;
    *) GLYPH=('        ' '        ' '        ' '        ' '        ' '        ') ;;
  esac
}

# rep N CHAR -> prints CHAR N times
rep() {
  local n="$1" ch="$2" out="" i
  for ((i = 0; i < n; i++)); do out+="$ch"; done
  printf "%s" "$out"
}

# word_rows WORD START_INDEX -> fills ART[0..5] with coloured block letters
word_rows() {
  local word="$1" k="${2:-0}" r i col
  local -a pal=(51 45 39 75 111 141 177 213)
  ART=("" "" "" "" "" "")
  for ((i = 0; i < ${#word}; i++)); do
    glyph "${word:i:1}"
    col=""
    if [ -n "$RST" ]; then col=$'\e[1;38;5;'"${pal[$(( (k + i) % ${#pal[@]} ))]}"'m'; fi
    for r in 0 1 2 3 4 5; do
      ART[r]+="${col}${GLYPH[r]} "
    done
  done
}

# frame_row TEXT -> one centred row inside the 50-column banner frame
frame_row() {
  local t="$1" vl pad left right
  vl=$(vlen "$t")
  pad=$(( 50 - vl ))
  if [ "$pad" -lt 0 ]; then pad=0; fi
  left=$(( pad / 2 ))
  right=$(( pad - left ))
  printf "  %s║%s%*s%s%*s%s║%s\n" "$VIOLET" "$RST" "$left" "" "$t$RST" "$right" "" "$VIOLET" "$RST"
}

banner_frame() {
  local pulse
  printf "  %s╔%s╗%s\n" "$VIOLET" "$(rep 50 '═')" "$RST"
  frame_row ""
  word_rows DEV 0
  for r in 0 1 2 3 4 5; do frame_row "${ART[r]}"; done
  frame_row ""
  word_rows PULSE 3
  for r in 0 1 2 3 4 5; do frame_row "${ART[r]}"; done
  frame_row ""
  pulse="_/\\_/\\__/\\_/\\__/\\_/\\__/\\_/\\__/\\_/\\__"
  frame_row "${VIOLET}${pulse}"
  frame_row "${BOLD}${WHITE}V1${RST}  ${GREY}|${RST}  ${GREY}dev:${RST} ${BOLD}${PINK}${OWNER}"
  frame_row "${GREY}[ repo health * devices * profile ]${RST}"
  printf "  %s╚%s╝%s\n" "$VIOLET" "$(rep 50 '═')" "$RST"
}

# compact one-line brand for small screens and sub-pages
brand_line() {
  printf "\n  %s%sDEV%s%s%sPULSE%s  %s%sV1%s\n" "$BOLD" "$CYAN" "$RST" "$BOLD" "$PINK" "$RST" "$BOLD" "$WHITE" "$RST"
  printf "  %s%s%s\n" "$VIOLET" "$(rep $((W-2)) '=')" "$RST"
  printf "  %sdev:%s %s%s%s\n\n" "$GREY" "$RST" "$BOLD$PINK" "$OWNER" "$RST"
}

# header for sub-pages
header() {
  refresh_layout
  clr
  brand_line
}

# home screen: the full framed banner on large screens
home_header() {
  refresh_layout
  clr
  printf "\n"
  if [ "$BIG" -eq 1 ]; then
    banner_frame
    printf "\n"
  else
    brand_line
  fi
}

# ---------- GitHub data ----------
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
  local t now
  t=$(date -d "$1" +%s 2>/dev/null) || return 1
  now=$(date +%s)
  echo $(( (now - t) / 86400 ))
}

valid_repo() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]
}

top_repos_body() {
  local repos pairs top1 s n
  repos=$(net "$API/users/$OWNER/repos?per_page=100&sort=updated") || { fail "could not load repositories"; return; }
  pairs=$(paste <(grep -o '"stargazers_count": *[0-9]*' <<<"$repos" | sed -E 's/.*: *//') \
                <(grep -o '"full_name": *"[^"]*"' <<<"$repos" | sed -E 's/.*: *"//; s/"$//') \
          | sort -k1,1nr | head -n 5)
  if [ -z "$pairs" ]; then frow "${GREY}no repositories found${RST}"; return; fi
  top1=$(head -n1 <<<"$pairs" | cut -f1)
  while IFS=$'\t' read -r s n; do
    frow "${BOLD}$(trunc "$n" $((W-8)))${RST}"
    frow "  $(bar "$s" "$top1" $((W-22)) "$CYAN")  $(fmt "$s") $(plural "$s" star stars)"
  done <<<"$pairs"
}

# ---------- features ----------
cmd_profile() {
  local j name login bio repos followers following created
  header; section "DEVELOPER PROFILE"
  info "loading profile"
  j=$(net "$API/users/$OWNER") || { fail "GitHub is not reachable right now"; pause; return; }
  name=$(jget name <<<"$j"); login=$(jget login <<<"$j"); bio=$(jget bio <<<"$j")
  repos=$(jget public_repos <<<"$j"); followers=$(jget followers <<<"$j")
  following=$(jget following <<<"$j"); created=$(jget created_at <<<"$j" | cut -c1-10)
  frow "${BOLD}${WHITE}${name:-$OWNER}${RST}"
  frow "${PINK}@${login}${RST}"
  if [ -n "$bio" ] && [ "$bio" != "null" ]; then frow "${GREY}$(trunc "$bio" $((W-6)))${RST}"; fi
  hline
  frow "$(badge "$BG_V" "$(fmt "$repos") repos") $(badge "$BG_C" "$(fmt "$followers") $(plural "$followers" follower followers)") $(badge "$BG_G" "$(fmt "$following") $(plural "$following" following following)")"
  hline
  kv "Joined" "${created:--}"
  kv "Profile" "$PROFILE_URL"
  section "TOP REPOSITORIES"
  top_repos_body
  pause
}

cmd_scan() {
  local repo j stars forks issues pushed archived lang lic desc branch days score grade col
  header; section "REPOSITORY HEALTH SCAN"
  printf "  %sowner/name%s\n  %s>%s " "$GREY" "$RST" "$PINK" "$RST"
  read -r repo || return
  if ! valid_repo "$repo"; then fail "use the form owner/name, e.g. $OWNER/devpulse"; pause; return; fi
  info "scanning $repo"
  j=$(net "$API/repos/$repo") || { fail "repository not found, or it is private"; pause; return; }

  stars=$(jget stargazers_count <<<"$j"); forks=$(jget forks_count <<<"$j")
  issues=$(jget open_issues_count <<<"$j"); pushed=$(jget pushed_at <<<"$j" | cut -c1-10)
  archived=$(jget archived <<<"$j"); lang=$(jget language <<<"$j")
  desc=$(jget description <<<"$j"); branch=$(jget default_branch <<<"$j")
  if grep -q '"license": *null' <<<"$j"; then
    lic="none"
  else
    lic=$(grep -o '"spdx_id": *"[^"]*"' <<<"$j" | head -n1 | sed -E 's/.*: *"//; s/"$//')
  fi
  days=$(days_since "$pushed") || days=0
  issues=$(tr -cd '0-9' <<<"$issues"); if [ -z "$issues" ]; then issues=0; fi
  stars=$(tr -cd '0-9' <<<"$stars"); if [ -z "$stars" ]; then stars=0; fi

  # Transparent score out of 100
  score=0
  if [ "$days" -le 30 ]; then score=$((score+40)); elif [ "$days" -le 180 ]; then score=$((score+20)); elif [ "$days" -le 365 ]; then score=$((score+10)); fi
  if [ "$archived" != "true" ]; then score=$((score+20)); fi
  if [ "$issues" -le 10 ]; then score=$((score+20)); elif [ "$issues" -le 50 ]; then score=$((score+12)); elif [ "$issues" -le 200 ]; then score=$((score+5)); fi
  if [ -n "$desc" ] && [ "$desc" != "null" ]; then score=$((score+10)); fi
  if [ "$lic" != "none" ]; then score=$((score+10)); fi

  if [ "$score" -ge 80 ]; then grade="A"; elif [ "$score" -ge 65 ]; then grade="B"; elif [ "$score" -ge 50 ]; then grade="C"; else grade="D"; fi
  col=$(good_col "$score")

  printf "\n"
  section "REPORT  $repo"
  frow "${BOLD}${col}${score}${RST}${GREY} / 100${RST}   $(bar "$score" 100 $((W-26)) "$col")  ${BOLD}${col}${grade}${RST}"
  hline
  kv "Stars"    "$(fmt "$stars")"
  kv "Forks"    "$(fmt "$forks")"
  kv "Issues"   "$(fmt "$issues") open"
  kv "Language" "${lang:--}"
  kv "License"  "$lic"
  kv "Branch"   "${branch:--}"
  kv "Last push" "$pushed  (${days}d ago)"
  section "CHECKS"
  if [ "$days" -le 30 ]; then check "Freshness" 1 "pushed ${days}d ago"; else check "Freshness" 0 "no push for ${days}d"; fi
  if [ "$archived" != "true" ]; then check "Activity" 1 "not archived"; else check "Activity" 0 "archived"; fi
  if [ "$issues" -le 50 ]; then check "Issues" 1 "$issues open"; else check "Issues" 0 "$issues open"; fi
  if [ "$lic" != "none" ]; then check "License" 1 "$lic"; else check "License" 0 "missing"; fi
  if [ -n "$desc" ] && [ "$desc" != "null" ]; then check "Docs" 1 "description set"; else check "Docs" 0 "no description"; fi
  hline
  pause
}

cmd_commits() {
  local repo j msgs n=0 m
  header; section "RECENT COMMITS"
  printf "  %sowner/name%s\n  %s>%s " "$GREY" "$RST" "$PINK" "$RST"
  read -r repo || return
  if ! valid_repo "$repo"; then fail "use the form owner/name"; pause; return; fi
  info "loading commits"
  j=$(net "$API/repos/$repo/commits?per_page=8") || { fail "could not load commits"; pause; return; }
  msgs=$(grep -o '"message": *"[^"]*"' <<<"$j" | sed -E 's/^"message": *"//; s/"$//; s/\\n.*//' | head -n 8)
  printf "\n"
  while IFS= read -r m; do
    n=$((n+1))
    frow "$(badge "$BG_C" "$n") $(trunc "$m" $((W-8)))"
  done <<<"$msgs"
  hline
  pause
}

cmd_device() {
  local cores ram_t ram_a ram_used ram_pct dsk d_tot d_used d_free d_pct batt status
  header; section "SYSTEM"
  cores=$(nproc 2>/dev/null || echo 1)
  kv "Kernel" "$(uname -sr)"
  kv "Arch" "$(uname -m)"
  kv "CPU cores" "$cores"
  kv "Shell" "bash ${BASH_VERSION%%(*}"
  kv "Git" "$(git --version 2>/dev/null | awk '{print $3}')"

  ram_t=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null); ram_t=${ram_t:-0}
  ram_a=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null); ram_a=${ram_a:-0}
  ram_used=$(( (ram_t - ram_a) / 1024 ))
  ram_pct=0
  if [ "$ram_t" -gt 0 ]; then ram_pct=$(( (ram_t - ram_a) * 100 / ram_t )); fi
  section "MEMORY"
  kv "RAM used" "$(fmt "$ram_used") / $(fmt $(( ram_t / 1024 ))) MB"
  frow "$(bar "$ram_pct" 100 $((W-12)) "$(load_col "$ram_pct")")  ${ram_pct}%"

  dsk=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print $2, $3, $4, $5}')
  d_tot=$(awk '{print $1}' <<<"$dsk"); d_used=$(awk '{print $2}' <<<"$dsk")
  d_free=$(awk '{print $3}' <<<"$dsk"); d_pct=$(awk '{print $4}' <<<"$dsk" | tr -d '%')
  d_tot=${d_tot:-0}; d_used=${d_used:-0}; d_free=${d_free:-0}; d_pct=${d_pct:-0}
  section "STORAGE  (HOME)"
  kv "Total" "$(fmt $(( d_tot / 1024 ))) MB"
  kv "Free" "$(fmt $(( d_free / 1024 ))) MB"
  frow "$(bar "$d_pct" 100 $((W-12)) "$(load_col "$d_pct")")  ${d_pct}%"

  if command -v termux-battery-status >/dev/null 2>&1; then
    batt=$(termux-battery-status 2>/dev/null | grep -o '"percentage": *[0-9]*' | sed -E 's/.*: *//')
    status=$(termux-battery-status 2>/dev/null | grep -o '"status": *"[^"]*"' | sed -E 's/.*: *"//; s/"$//')
    batt=${batt:-0}
    section "POWER"
    kv "Status" "${status:-unknown}"
    frow "$(bar "$batt" 100 $((W-12)) "$(good_col "$batt")")  ${batt}%"
  fi
  hline
  pause
}

cmd_link() {
  header; section "PROFILE LINK"
  kv "GitHub" "$PROFILE_URL"
  hline
  pause
}

cmd_top() {
  header; section "TOP REPOSITORIES"
  top_repos_body
  hline
  pause
}


trap 'printf "\n"; exit 0' INT TERM

if [ "${1:-}" = "--version" ]; then
  echo "devpulse $VERSION"
  exit 0
fi

while true; do
  menu
  read -r choice || exit 0
  case "$choice" in
    1) cmd_profile ;;
    2) cmd_scan ;;
    3) cmd_top ;;
    4) cmd_commits ;;
    5) cmd_device ;;
    6) cmd_link ;;
    0|q|Q) printf "  %sGoodbye.%s\n" "$PINK" "$RST"; exit 0 ;;
    *) ;;
  esac
done
