# net-thru

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/demo-dark.gif">
    <img src="docs/demo-light.gif" width="546" alt="net-thru in the macOS menu bar: a small mirrored bar graph with the live upload and download rates next to it">
  </picture>
</p>

A tiny macOS menu bar app that shows how fast you're uploading and downloading, plus a small
graph of the last 14 seconds. Upload is red, above the midline; download is blue, below it.
Units adapt (KB/s, MB/s, GB/s).

Clicking it shows how much you've transferred since launch, which interfaces are being
measured, a **Launch at Login** toggle and **Quit**.

## Install

Needs macOS 14 or later, on an Apple Silicon or Intel Mac.

```sh
brew install --cask loorik/tap/net-thru
```

net-thru isn't notarized by Apple, which needs a paid developer account. So macOS blocks it the
first time you open it. Go to **System Settings → Privacy & Security**, scroll down and click
**Open Anyway**. You only need to do this once.

## Usage

To start it automatically, click the menu bar item and enable **Launch at Login**. Turn that
off again before uninstalling.

net-thru places itself next to the system icons (Wi-Fi, battery, ...), so it stays visible
when the menu bar gets crowded. ⌘-drag it to move it; macOS remembers where you put it.

## Build from source

Needs the Xcode Command Line Tools (`xcode-select --install`). Xcode itself isn't required.

```sh
make install     # builds build/net-thru.app, copies it to /Applications and starts it
make run         # builds and runs from build/ without installing
make uninstall   # quits it and removes it from /Applications
make test        # runs the test suite
```

## What gets counted

All `en*` interfaces: Wi-Fi, Ethernet, USB/Thunderbolt adapters and iPhone tethering. Loopback,
VPN tunnels (`utun*`), bridges, AirDrop (`awdl*`) and other virtual interfaces are left out.
VPN traffic still shows up, because it also crosses the physical interface, and leaving the
tunnels out keeps it from being counted twice. To change this, edit
`TrafficMonitor.countedInterfacePrefix`.

Rates are sampled once a second and use decimal units (1 KB = 1000 bytes), like Activity
Monitor.

macOS only gives ordinary apps coarse interface counters, rounded to 1 KB and wrapping at
4 GB. net-thru handles the wraparound. The rounding means the smallest visible step is about
1 KB/s.

## Layout

| Folder | Purpose |
| --- | --- |
| `Sources/NetThruKit/Monitoring` | Reads the kernel's per-interface byte counters (`sysctl NET_RT_IFLIST2`) and turns them into rates, history and totals |
| `Sources/NetThruKit/Drawing` | Draws the graph and the numbers in the menu bar |
| `Sources/NetThruKit/Formatting` | "12 KB/s" / "1.2 MB/s" formatting |
| `Sources/NetThru` | The app: menu bar item, its menu, the 1-second ticker, launch at login |
| `Sources/MakeDemo` | Renders the animation above from the app's own drawing code (`make demo`) |
| `Tests` | Swift Testing suites for each of the above (`make test`) |
| `scripts/make-icon.swift` | Regenerates `Resources/AppIcon.icns` (`make icon`) |

## Releasing

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. `make release` builds `build/net-thru-<version>.zip` and prints its SHA-256.
3. `gh release create v<version> build/net-thru-<version>.zip`
4. Update `version` and `sha256` in `Casks/net-thru.rb` in
   [Loorik/homebrew-tap](https://github.com/Loorik/homebrew-tap).
