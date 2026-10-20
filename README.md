<p align="center">
  <img src="assets/banner.svg" alt="DevPulse banner" width="100%"/>
</p>

<h1 align="center">DevPulse</h1>

<p align="center">
  <b>Repo health, GitHub insights and device reports, right in your terminal.</b><br/>
  Built for Termux. Works on Linux too.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/shell-bash-1f425f?logo=gnubash&logoColor=white" alt="bash"/>
  <img src="https://img.shields.io/badge/platform-Termux%20%7C%20Linux-22d3ee" alt="platform"/>
  <img src="https://img.shields.io/badge/version-V1-a855f7" alt="version"/>
  <img src="https://img.shields.io/badge/license-All%20Rights%20Reserved-ef4444" alt="license"/>
</p>

---

## ✨ Why DevPulse?

📱 Designed for phones first. The layout adapts to your screen width.
🎨 Clean colour borders, gradient banner, and numbers you can read at a glance.
⚡ One menu, no setup beyond a single install command.

## 🚀 Features

🔍 **Repository health scan**: a score out of 100, grade A to D, and PASS or WARN checks.
👤 **Developer profile**: name, bio, follower counts, and your top repositories with star bars.
⭐ **Top repositories**: your projects ranked by stars.
📝 **Recent commits**: the latest commit messages of any public repository.
📱 **Device report**: kernel, CPU cores, RAM and storage usage, battery status.
🔗 **Profile link**: your GitHub profile, one tap away.

## 📊 Health score

Every point is explained, so you always know why a repository scored what it did.

🕒 **Freshness (40 points)**: pushed within 30 days earns full points.
🛡️ **Activity (20 points)**: the repository is not archived.
🐞 **Issues (20 points)**: 10 or fewer open issues earns full points.
📜 **License (10 points)**: a license file is present.
📘 **Docs (10 points)**: the repository has a description.

Grades: A is 80 and above, B is 65 and above, C is 50 and above, and D is below 50.

## 📦 Install on Termux

Run these commands one at a time:

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

Start the tool from anywhere:

```bash
devpulse
```

## 🔐 Connect GitHub (recommended)

Without a login, GitHub allows about 60 requests per hour. Log in once and DevPulse uses your login automatically:

```bash
pkg install -y gh
```

```bash
gh auth login
```

## 🧭 Menu

🔢 **1**: Developer profile
🔢 **2**: Repository health scan
🔢 **3**: Top repositories
🔢 **4**: Recent commits
🔢 **5**: Device report
🔢 **6**: Profile link
🔢 **0**: Exit

## 🛠️ Troubleshooting

❓ **Command not found**: add the install folder to your PATH, then open a new session:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

⏳ **Rate limit or GitHub error**: run `gh auth login` and try again.

🔋 **Battery shows unknown**: install the Termux:API app, then run `pkg install -y termux-api`.

## 👨‍💻 Developer

**d-rathnayake**: [github.com/d-rathnayake](https://github.com/d-rathnayake)

## 📜 License

All rights reserved. You may clone and run DevPulse on your own device for personal use. Modifying, redistributing, or publishing it requires written permission from the author. See [LICENSE](LICENSE).

---

<p align="center">Made with care by <b>d-rathnayake</b></p>
