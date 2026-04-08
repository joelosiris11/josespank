# Spank

macOS dashboard for [spank](https://github.com/charmbracelet/spank) — plays audio when it detects a slap on your Apple Silicon laptop via the built-in accelerometer.

## Requirements

- macOS 14+ (Apple Silicon)
- Xcode Command Line Tools: `xcode-select --install`

## Install (from release)

1. Download `SpankApp.dmg` from [Releases](../../releases)
2. Open the DMG and drag `SpankApp` to Applications
3. Right-click → **Open** (to bypass Gatekeeper the first time)
4. Click **Setup** in the app — enters your password once, never again

## Build from source

```bash
git clone https://github.com/joelosiris11/josespank.git
cd josespank
make app        # builds SpankApp.app
make dmg        # builds SpankApp.dmg (for distribution)
```

## Modes

| Mode | Description |
|------|-------------|
| Normal | Default spank sounds |
| Sexy | Escalating intensity |
| Halo | Halo soundtrack clips |
| Lizard | Like Sexy but lizard-themed |
| Custom | Your own MP3s (yamete-kudasai included) |

## Settings

- **Sensitivity** — how hard you need to slap (lower = more sensitive)
- **Cooldown** — minimum time between sounds (ms)
- **Speed** — playback rate
- **Volume Scaling** — harder slap = louder sound
- **Fast Mode** — shorter cooldown, higher sensitivity

## How Setup works

Setup installs `spank` to `/usr/local/bin/spank` and adds a sudoers entry so the app can run it as root (required for IOKit accelerometer access) without asking for your password every time.
