> [!IMPORTANT]
> LibreNT is in active development. The builds on the [Releases](https://github.com/Nagy-Arpi-Kft/LibreNT/releases) page are Debug pre-releases for testing: run them in a virtual machine or on spare hardware.

<div align="center">

# [LibreNT]
### A free NT operating system

**Built out of love for the NT architecture. Windows® 11 compatible, for amd64, arm64.**

<br>

[![Download the latest build](https://img.shields.io/badge/Download-Latest_build-0161B6?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Nagy-Arpi-Kft/LibreNT/releases)

</div>

---

<p align="center">
  <img width="1000" alt="The LiberNT desktop on arm64" src="media/graphics/screenshots/libernt-desktop-arm64.png">
</p>

<p align="center"><sub>The LiberNT desktop on arm64, from build nt10.0-043-2555 in QEMU</sub></p>

---

LibreNT is a free NT operating system. It targets **Windows® 11 compatibility**, with room for freestyle and experimental features.

LibreNT brings extensive work on kernel-space components and drivers, aimed at stability and modern hardware, and it focuses on 64-bit platforms: **amd64, arm64**.

Our goal is a system that stays maintainable in the long run: **stable, reliable and efficient**, running on embedded devices too, and able to support every feature a modern operating system should have.

> [!NOTE]
> **NT** is the architecture behind every modern version of Windows: its kernel, driver model and system services. LibreNT is a free operating system built on that architecture, and Windows 11 is the reference it measures itself against.

---

## Table of Contents

---

## What LibreNT Includes

LibreNT brings modern hardware and platforms to the NT architecture.

| Feature | What it means for you |
| --- | --- |
| **64-bit first** | The kernel, HAL and FreeLoader run on amd64, arm64 and riscv64. |
| **UEFI boot** | Boots on UEFI firmware, with a GOP framebuffer and early display support. The preinstalled disk boots with UEFI or BIOS. |
| **Modern buses and storage** | PCIe, PCI, Plug and Play, USB with xHCI, SD/eMMC, and storage and bus drivers. |
| **Board support** | Real boards, including the Raspberry Pi and its RP1 I/O controller. |
| **The Windows 11 driver model** | Windows 11 (NT10) compatibility and driver-model work, checked against Windows 11 itself. |
| **Graphics and x86 apps on Arm** | The graphics driver model with Mesa, and WoW64 with FEX, are build options you can switch on. |
| **LiberNT Setup** | Lists drives the way Windows Setup does, creates, deletes, formats, shrinks and extends partitions, and installs LiberNT on NTFS with the EFI system partition it needs. |
| **Your own build** | `menuconfig` lets you choose the target, compiler and build type, and switch features on or off. |

---

## Supported Platforms

| Architecture | Prebuilt images | Build from source | Notes |
| --- | :---: | :---: | --- |
| **amd64** | ✓ | ✓ | Clang (default) or GCC |
| **arm64** | ✓ | ✓ | Includes Raspberry Pi support |
| **i386** | | ✓ | 32-bit x86 |

---

## Getting Started

### Step 1: Download a Build

Every build on the [Releases](https://github.com/Nagy-Arpi-Kft/LibreNT/releases) page comes as one ZIP file per image and architecture:

| File | What it is |
| --- | --- |
| `bootcd-iso-…-<arch>-…zip` | `bootcd.iso`, a CD image that runs LibreNT or starts LibreNT Setup |
| `LibreNT-img-…-<arch>-…zip` | `LiberNT.img`, a disk with LibreNT already installed |
| `LibreNT-vhd-…-<arch>-…zip` | `LiberNT.vhd`, the same preinstalled disk for VHD-based virtual machines |
| `LibreNT-vhdx-…-<arch>-…zip` | `LiberNT.vhdx`, the same preinstalled disk for Hyper-V Generation 2 |

### Step 2: Boot It

The quickest way to try LiberNT is the preinstalled disk:

1. Unzip `LiberNT.img` (or `LiberNT.vhd`)
2. Start it in a virtual machine such as **QEMU**, or use the VHD in **VirtualBox** or a **Hyper-V** Generation 1 virtual machine. Hyper-V Generation 2 takes only `LiberNT.vhdx`, with Secure Boot turned off
3. Or write `LiberNT.img` to a USB drive or an SD card and boot the machine from it. It boots with UEFI or BIOS

> [!CAUTION]
> Writing `LiberNT.img` to a USB drive or an SD card erases everything on it. Double-check the target device first.

### Step 3: Install LiberNT

Boot `bootcd.iso` in a virtual machine or on a PC, and follow the instructions of **LiberNT Setup**.

The preinstalled disk also carries LiberNT Setup. Run `C:\<architecture>\libernt.exe`, for example `C:\arm64\libernt.exe`, to install LiberNT on another disk from the running system.

> [!CAUTION]
> Setup can delete and format partitions. Back up anything important on the target disk before you install.

---

## Project Structure

```text
LibreNT/
├── base/            # Applications, services, setup and the shell
├── boot/            # FreeLoader, boot data and boot images
├── bootloader/      # Boot manager, Windows loader, UEFI and Open Firmware support
├── dll/             # User-mode DLLs, including ntdll and the Win32 libraries
├── drivers/         # Kernel-mode drivers: buses, storage, file systems, network, input and more
├── hal/             # Hardware abstraction layers for x86, Arm, Arm64, PowerPC and RISC-V
├── media/           # Fonts, themes, INF files, sounds and branding
├── modules/         # Optional applications, tests and wallpapers
├── ntoskrnl/        # The NT kernel and executive
├── sdk/             # Headers, libraries and build tools
├── submodules/      # Recipes and patches for external components
├── subsystems/      # CSRSS and the Windows subsystem
├── win32ss/         # win32k, USER, GDI and display drivers
├── configure.sh     # Sets up a build on Linux, macOS and WSL2
└── configure.cmd    # Sets up a build on Windows
```

---

## Contributing

Report bugs and suggest features in [Issues](https://github.com/LiberNT/LiberNT/issues), and find guides and notes in the [Wiki](https://github.com/LiberNT/LiberNT/wiki).

---

## Use of AI

We want to make it clear: AI is part of how LiberNT is built. It helps us review and write code, and everything it writes is then reviewed by a human. 
---

## License

LibreNT is an independent project. It is not affiliated with, endorsed by or sponsored by Microsoft. Windows® is a registered trademark of Microsoft Corporation.

---

## About

