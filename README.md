# 📱 Mobile Pentest Environment Builder

An automated, all-in-one Bash script designed to rapidly deploy and manage a high-performance Android mobile penetration testing laboratory on Debian/Ubuntu/Kali Linux systems. 

This tool handles everything from dependency resolution and tool installation to automated creation of highly optimized, KVM-accelerated clean and rooted Android emulators.

---

## ✨ Features

* **Hardware Virtualization Audit:** Automatically detects and verifies VT-x/AMD-V and KVM support, preventing deployment failures.
* **Automated Toolchain Deployment:** Installs the Android SDK, Android Studio (Koala), reverse engineering tools (JADX, Apktool, dex2jar), and Python-based dynamic analysis tools via `pipx`.
* **1-Click Emulator Creation:** Builds hardware-optimized Pixel 6 Pro emulators (8GB RAM, 6 CPU cores, Host GPU acceleration) running Android 12 (API 31).
* **Automated Rooting (rootAVD):** Seamlessly patches the emulator ramdisk to deploy Magisk on a fresh Google APIs image.
* **Unified Management Dashboard:** Start, stop, and purge your lab emulators from a single interactive CLI menu.
* **Shell Integration:** Automatically patches your `~/.zshrc` to ensure all SDK and RE tools are immediately accessible in your PATH.

---

## 🛠️ Included Tools

The `DEPLOY` module installs and configures the following toolkit:

**Dynamic & Network Analysis:**
* [Frida](https://frida.re/) (Tools & Server)
* [Objection](https://github.com/sensepost/objection)
* [Mitmproxy](https://mitmproxy.org/)
* [Drozer](https://github.com/WithSecureLabs/drozer)

**Static Analysis & Reverse Engineering:**
* [JADX & JADX-GUI](https://github.com/skylot/jadx)
* [Apktool](https://ibotpeaches.github.io/Apktool/)
* [dex2jar](https://github.com/pxb1988/dex2jar)
* [Quark-Engine](https://quark-engine.readthedocs.io/)
* [Androguard](https://github.com/androguard/androguard)
* [Pyxamstore](https://github.com/jakev/pyxamstore) (Automated source build)

**Development & SDK:**
* Android Studio (Koala 2024.1.2)
* Android SDK (platform-tools, build-tools, sdkmanager)

---

## 📋 Prerequisites

* **OS:** Kali Linux, Parrot OS, Ubuntu, or any Debian-based distribution.
* **Hardware:** A CPU that supports Virtualization (VT-x for Intel, AMD-V for AMD).
* **BIOS/UEFI:** Virtualization must be **enabled** in your BIOS. If running inside a VM (like VMware/VirtualBox), "Nested Virtualization" must be enabled.
* **Privileges:** `sudo` access is required for installing system-level dependencies.

---

## 🚀 Quick Start

1. **Clone the repository:**
```bash
   git clone https://github.com/nnrnull/mob_env.git
   cd mob_env
```
2. **Make the script executable:**
```bash
chmod +x mob_env.sh
```
3. **Launch the interactive builder:**
```bash
./mob_env.sh
```

---

## 🕹️ Menu Options

Upon launching the script, you will be greeted with the main dashboard.  
**Note:** Options 1–5 will be locked if the hardware virtualization audit fails.

### DEPLOY :: Audit & Install Core Tools
Checks for missing apt packages, installs pipx Python modules, sets up Pyxamstore, downloads Android Studio, configures the SDK, and patches `.zshrc`. **Run this first.**

### LAUNCH :: Start an Emulator
Lists all available AVDs and boots your selection with performance flags (no-snapshot, host GPU).

### CREATE :: New Clean Emulator
Downloads the Google Play API 31 system image and builds a standard Pixel 6 Pro lab environment.

### ROOT :: New Rooted Emulator
Downloads the Google APIs API 31 image, builds the AVD, and uses `rootAVD` to patch the ramdisk.

> **Note:** After creation, you must open the Magisk app inside the emulator and click **OK** to finish the setup.

### PURGE :: Remove Emulator(s)
Safely delete a specific emulator or wipe all existing emulators to free up disk space.

---

## ⚙️ Emulator Specifications

To ensure a smooth testing experience, the script forcefully overrides default Android Studio hardware profiles with the following performance specifications:

| Component | Specification |
|-----------|---------------|
| Device | Pixel 6 Pro |
| RAM | 8192 MB (8 GB) |
| CPU Cores | 6 |
| VM Heap | 1024 MB |
| Data Partition | 16 GB |
| GPU Rendering | Host-side (uses native/dedicated GPU) |

---

## ⚠️ Troubleshooting

### OPTIONS 1–5 ARE LOCKED DUE TO HARDWARE LIMITATIONS

Your system does not support KVM acceleration.

### Resolution

* **On bare-metal:** Enable virtualization in BIOS/UEFI.
* **On VMware:**
  * VM Settings → Processors  
  * Enable **Virtualize Intel VT-x/EPT or AMD-V/RVI**

---

### Commands like `adb` or `frida` are not found after DEPLOY

The script modifies your `~/.zshrc`. Reload your shell environment:

```bash
source ~/.zshrc
```

---

## 📄 Disclaimer

This project is intended for educational purposes, security research, and authorized penetration testing only. The author is not responsible for any misuse of this tool or the lab environments it creates.
