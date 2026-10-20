# DevPulse

DevPulse is a terminal toolkit for Termux and Linux. It shows your GitHub profile, scans any repository for health, lists recent commits, and prints a device report, all from one menu.

![DevPulse banner](assets/banner.svg)

## Features

| Feature | What it shows |
|---|---|
| Developer profile | Name, bio, public repos, followers, and your top repositories with star bars |
| Repository health scan | Health score out of 100, stars, forks, issues, license, and PASS/WARN checks |
| Top repositories | Your repositories ranked by stars, with proportional bars |
| Recent commits | The latest commit messages of any public repository |
| Device report | Kernel, architecture, CPU cores, RAM and storage usage, battery (with Termux:API) |
| Profile link | The GitHub profile URL |

## Health score

The score is out of 100 and every point is explained:

| Check | Points |
|---|---|
| Pushed within 30 days (20 to 180 days gives partial points) | 40 |
| Not archived | 20 |
| Open issues: 10 or fewer (50 or fewer and 200 or fewer give partial points) | 20 |
| Has a description | 10 |
| Has a license | 10 |

## Requirements

- Termux (or any Linux shell) with `bash`, `curl`, `git`, `grep`, `sed`, `awk`
- Internet access
- Optional: GitHub CLI (`gh`) for a higher API rate limit, and Termux:API for battery data

## Install on Termux

Run these commands one at a time.

```bash
pkg update -y
```

```bash
pkg install -y git curl
```

```bash
git clone https://github.com/d-rathnayake/devpulse
```

```bash
cd devpulse
```

```bash
bash install.sh
```

After installation, start the tool from anywhere:

```bash
devpulse
```

Show the version:

```bash
devpulse --version
```

## Authentication (recommended)

Without a token GitHub allows about 60 API requests per hour. Log in once with the GitHub CLI and DevPulse will use that token automatically:

```bash
pkg install -y gh
```

```bash
gh auth login
```

## Usage

| Key | Action |
|---|---|
| 1 | Developer profile overview |
| 2 | Repository health scan (enter owner/name) |
| 3 | Top repositories |
| 4 | Recent commits (enter owner/name) |
| 5 | Device report |
| 6 | Profile link |
| 0 | Exit |

## Project layout

```
devpulse/
  devpulse.sh          main program and menu
  install.sh           installer and command link
  assets/banner.svg    banner
  .github/workflows/   CI: syntax check and shellcheck
  LICENSE
  README.md
```

## Troubleshooting

- `devpulse: command not found`: add the install folder to your PATH, then open a new session:

  ```bash
  export PATH="$HOME/.local/bin:$PATH"
  ```

- `GitHub API error` or rate limit: run `gh auth login`, then try again.
- Battery shows as unknown: install Termux:API and the `termux-api` package.

## License

All rights reserved. See [LICENSE](LICENSE). You may clone and run DevPulse on your own device for personal use. Modifying, redistributing, or publishing it requires written permission from the author.

Author: d-rathnayake
