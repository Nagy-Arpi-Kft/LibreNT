# Windows 11 Compatibility Gaps

**Status as of:** 2026-11-01 (later same day)
**Scope:** This document inventories missing or incomplete *features and subsystems* relative to real Windows 11 (NT10), for amd64/arm64, roughly 2015+ hardware. It is written for engineers deciding what to build next.

**Out of scope:** Licensing/legal concerns, and specific bugs in code that already exists (those are tracked elsewhere). A component rated "present" here may still have bugs; this document only judges presence/completeness of the feature itself. §0 below is the one deliberate exception: it tracks the boot-level engineering status itself, since "does it even start" is a precondition for every other row in this document meaning anything in practice.

**Method:** Targeted `grep`/`find` across the tree, cross-checked against actual file contents (not just names/paths) to distinguish real implementations from named stubs. Every claim below cites the evidence path(s) used. Gap size is a qualitative judgment: *none* (parity), *small*, *medium*, *large*, *total* (nothing found).

---

## Project requirements (hard constraints)

These are non-negotiable project requirements, not gap-analysis findings, and they govern how every other section of this document should be read:

- **Hardware floor: any UEFI-capable system.** LibreNT must run on every UEFI-supported machine — PC and laptop first and foremost, but the requirement is "UEFI firmware present," not a specific vendor/chipset/year cutoff. In practice this means roughly 2010+ x86-64 hardware (UEFI became near-universal on new PCs starting ~2011-2012) and any UEFI-capable ARM64 board. Legacy BIOS-only systems are explicitly out of scope.
- **Software floor: Windows 7 compatibility, not Vista/XP.** Any application that ran on real Windows 7 must be able to run on LibreNT. This is a strictly *lower* bound than "Windows 11 feature parity" (§1-§14 above are about matching *Windows 11*, which is a much higher bar) — it means the Win32 API surface, binary/ABI compatibility, and application-facing behavior must not regress below what a real Windows 7 install offered, even in areas where Windows 11 itself has moved on. Pre-Windows-7 (XP/Vista-era-only) compatibility shims and quirks are explicitly NOT required and were intentionally removed (see the 2026-10-31 rebrand commit).
- **Current project phase: internal test builds.** The project is currently producing early, internal-use-only test builds, not public releases. Features whose only purpose is securing a multi-user, managed, or internet-facing deployment are deliberately deprioritized right now (Credential Provider / modern logon, TPM-backed features, VBS/HVCI/BitLocker/Defender, enterprise management — see §1, §2, §14) in favor of work that affects whether the OS is usable at all on real/virtual hardware. These areas remain real gaps and are not being removed from this document, just intentionally sequenced later.
- **Current priority: display & 3D.** Given the above, the active development focus is making real GPU drivers and a working DirectX stack possible (§3, and the ReactX/legacy-DirectX layer referenced there) — this is the current bottleneck for the OS being usable beyond a basic framebuffer console, and takes priority over the identity/security work in §1-§2 for the time being.

---

## 0. Build & boot status

Unlike §1-§14, which were produced by static source inspection, this section reflects actual build-and-boot testing (QEMU 11.1.0 + OVMF UEFI firmware, amd64, 2048 MB RAM, 256 MB FAT32 boot ramdisk).

**Current status: boots successfully end-to-end.** A clean build now reaches `SMSS` → `win32k`/GDI/USER32 initialization → running user-mode services (confirmed via `diagdata`, the audio/power subsystems, etc.) with no crashes, assertions, or hangs. This was not true as of 2026-10-31; two boot-blocking defects were found and fixed to get here (commit `ee8e79fc35b`):

| Defect | Where | Symptom | Fix |
|---|---|---|---|
| Double-release of `Vcb->ChangeBitMapResource` | `drivers/filesystems/fastfat/allocsup.c`, `FatAllocateDiskSpace` | STOP 0x7F (`UNEXPECTED_KERNEL_MODE_TRAP`) on an unrelated, later file-system operation, minutes/seconds after the real cause | An exception raised before entering either of two later, non-nested `_SEH2_TRY/_SEH2_FINALLY` blocks could still spuriously invoke one of their `_SEH2_FINALLY` bodies during unwind (an SEH-unwinder mistargeting hazard specific to this function's shape: several sequential, non-nested try/finally regions in one oversized routine). Each such finally now only releases/cleans up if its own branch was actually entered, tracked via a `_SEH2_VOLATILE` guard flag |
| Hibernation file sized against total RAM, not target volume | `ntoskrnl/po/hiber.c`, `PopHiberOpenFile`/`PopHiberReserve` | Boot hang (no crash, no further output) during early Po-subsystem init, triggered by the defect above | `PopHiberReserve` computed the hibernation file size as 40% of physical RAM with no regard for the boot volume's actual free space (819 MB requested on a 256 MB ramdisk). `PopHiberOpenFile` now creates the file with no upfront allocation, checks the volume's free space via `FileFsSizeInformation`, and returns `STATUS_DISK_FULL` cleanly up front (already retried later by `PopHiberInitializeWorker`) instead of ever attempting the oversized grow |
| Boot-console font failed to load | `media/fonts/lucon.ttf` (compiled into the kernel via `sdk/lib/bootfont`), loaded by `drivers/base/bootvid/framebuf/bootvid.c:685` | `FreeType: tt_face_load_name: invalid 'name' table` → `Could not initialize the FreeType boot console font`; no on-screen text console during early boot (serial-log-only diagnostics) | Root cause was NOT in the loading code: an earlier rebrand commit (`8f93b0e2695`) had run a text-normalization pass that corrupted 33 binary files it should never have touched — including 26 font files, 2 test-fixture fonts, 2 test-fixture binaries, and a `.chm` help file — each missing a handful of bytes partway through, desynchronizing `lucon.ttf`'s SFNT table-directory offsets from its real table contents. Restored all 33 files byte-for-byte from the commit immediately before the corruption; verified via a second agent that every restored file is byte-identical to its pre-corruption blob and that no later commit had legitimately touched any of them in between |

**Known non-blocking rough edges observed during this same boot:**
- No real WDDM 3D driver is available under plain QEMU (`Didn't find a suitable PDEV`, `win32ss/gdi/ntgdi/dclife.c:717`); the session falls back to `BasicDisplay`/`softgpu`. This is a real, trackable gap — not the WDDM scheduler quarantine (that gates unrelated internals, see §3) — now the active development focus; see §3's "GPU driver availability" row.
- A one-time `EX: Work Queue Deadlock detected` message during Po-subsystem init (`ntoskrnl/ex/work.c:393`) that self-recovers (3 dynamic threads queued) — not yet root-caused, did not block boot in testing.

---

## 1. Identity & logon

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| Credential Providers | Sole logon extensibility model since Vista; no GINA support at all | **Absent.** No `ICredentialProvider`/`ICredentialProviderCredential` interface, no `credentialprovider.h` anywhere in `sdk/include`. `winlogon.c` hardcodes the legacy GINA DLL name | `grep -rl "credentialprovider.h" sdk/include` → no results; `base/system/winlogon/winlogon.c:510` loads `"msgina.dll"` directly | **Total** |
| GINA (legacy) | Removed in Vista+ | Present and is the *only* logon mechanism | `dll/win32/msgina/msgina.c`, `base/system/logonui/logonui.c` | N/A (this is itself the gap above) |
| Windows Hello / biometrics (`winbio`) | Face/fingerprint sign-in, PIN unlock via TPM-backed key | **Absent.** No `winbio*` files anywhere | `find . -iname "*winbio*"` → no results | **Total** |
| Modern lock screen | Lock screen with notifications, quick actions, OOBE-integrated | `base/system/logonui` exists but is the classic GINA-driven UI, not the modern LogonUI/lock-screen shell | `dll/win32/msgina/logonui.cpp`, `base/system/logonui/logonui.c` | **Large** |
| PIN / Windows Hello for Business | NGC container, TPM-backed asymmetric keys, CSP-based enrollment | **Absent** — no NGC/PIN CSP of any kind found | see §14 | **Total** |
| `windows.security.credentials.ui.userconsentverifier` | Biometric/PIN consent prompt API surface used by apps | Directory exists (`dll/win32/windows.security.credentials.ui.userconsentverifier`) but with nothing underneath it to actually verify against (no WinBio, no NGC) | `dll/win32/windows.security.credentials.ui.userconsentverifier` | **Large** (API shell without a backing verifier) |

---

## 2. Security platform

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| TPM 2.0 kernel driver | `tpm.sys`, full command/response support | **Present, substantial.** `drivers/platform/tpm2/tpm2.c` is 1,347 lines; `tpm2diag` CLI diagnostic tool also exists; RPi TPM overlays included | `drivers/platform/tpm2/tpm2.c`, `base/applications/cmdutils/tpm2diag`, `media/boot/rpi/overlays/tpm-slb9670.dtbo` | **Small** (driver looks real; needs app-facing API, see next row) |
| TPM Base Services (`tbs.dll`) | User-mode API (`Tbsi_*`) that applications/CryptoAPI/BitLocker use to reach the TPM | **Absent.** No `tbs.dll`/`tbs` component found despite the kernel driver existing | `find . -iname "*tbs.dll*"` and `-iname "tbs" -type d` → no results | **Large** (kernel driver is stranded without its user-mode entry point) |
| Secure Boot verification chain | UEFI Secure Boot cert chain validated by the boot manager; `SeQuerySecureBootPlatformManifest`/`PolicyValue` exposed to user mode | **Absent as real logic.** Both query APIs are literal `@ stub` entries; no Secure Boot verification code in `boot/`/`bootloader/` | `ntoskrnl/ntoskrnl.spec:3249-3250` (`@ stub -arch=win64 SeQuerySecureBootPlatformManifest/PolicyValue`); `grep -ril secureboot boot bootloader` → no hits | **Large** |
| BitLocker / device encryption | Full-volume encryption, TPM+PIN unlock, recovery keys | **Absent.** No `fvevol`, `bitlocker`, or equivalent anywhere | `find . -iname "*bitlocker*" -o -iname "*fvevol*"` → no results | **Total** |
| Virtualization-Based Security (VBS) | Hyper-V-backed secure kernel (VSM), isolated user mode | **Absent.** No secure kernel, `hvix64`, `winhvr`, VSM library | `find . -iname "*securekernel*" -o -iname "*hvix64*" -o -iname "*winhvr*" -o -iname "*vsmlibrary*"` → no results | **Total** |
| HVCI (Hypervisor-protected Code Integrity) | Enforces kernel code integrity via VBS | **Absent** (depends on VBS, which is absent) | same as above | **Total** |
| Credential Guard | Isolates credential hashes/tickets in a VBS enclave | **Absent** (depends on VBS) | — | **Total** |
| Windows Defender / Microsoft Defender AV | Real-time AV engine, cloud protection, SmartScreen | **Absent.** No `defender`/`windefend` component | `find . -iname "*defender*" -o -iname "*windefend*"` → no results | **Total** |
| Driver signature enforcement (WHQL/attestation signing) | Kernel refuses to load unsigned/non-WHQL drivers in normal boot | **Partial infrastructure, not enforced.** `PsProcess` tracks `SE_SIGNING_LEVEL_MICROSOFT`/`STORE` for *section* signing, but `SetSystemCodeIntegrityRoots` is marked `// FIXME` and there's no CI.dll-equivalent policy engine | `ntoskrnl/ps/process.c:2165-2184` (signing-level checks exist); `ntoskrnl/include/sysfuncs64.h:577` (`SetSystemCodeIntegrityRoots, 0) // FIXME`) | **Medium-large** |
| Authenticode verification (`wintrust.dll`) | Full signature/catalog verification | **Present, appears substantial.** 1,218 lines, only ~10 stub/FIXME markers | `dll/win32/wintrust/wintrust_main.c` | **Small** |

---

## 3. Graphics & display

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| WDDM kernel (`dxgkrnl`) scaffolding | Adapter/device/context lifecycle, paging, VidMm/VidSch, GPU VA management, residency, fences | **Present and genuinely extensive.** ~60 source files covering `vidmm.c`, `vidsch.c`, `vidpn.c`, `gpuva_core.c`, `paging_core.c`, `fence_core.c`, `residency_core.c`, `context_sync_core.c`, `keyedmutex_core.c`, etc. | `drivers/directx/dxgkrnl/*.c` (directory listing) | **None-small** for the scaffolding itself |
| WDDM scheduler internals — undocumented Microsoft private ABI (corrected 2026-11-01; prior entry had the flag name wrong and overstated the scope) | Autonomous GPU context run lists, multi-app priority/time-entitlement scheduling, WDDM 3.2 user-mode work submission, private TDR recovery ABI, native `VidMmInterface`/`VidSchInterface` export tables | **Explicitly compile-time quarantined**, but — confirmed by reading the gate file, its introducing commits, and AGENTS.md's "Sources of truth" policy — this is an *evidence-sufficiency* gate on **undocumented private Microsoft kernel ABI** (no WDK header defines these tables' layout for Windows 11; only decompilation or leaked PDBs could), not a restriction on GPU *hardware driver* work. It does not block writing a WDDM KMD for any GPU, virtual or real; that only needs the ordinary (non-advanced) WDDM 2.x scheduling plumbing in `dxgkrnl`/`dxgmms2`, which is NOT gated | `drivers/directx/wddm_cleanroom_gate.h` (all five `LIBRENT_WDDM_*` flags `#define`d `0`, each backed by a `#error` if enabled); `AGENTS.md` "Sources of truth" (hardware driving: spec + Linux/EDK2 driver study, never copy GPL code, never leaked/decompiled Microsoft internals beyond EU interoperability limits) | **Large** (acknowledged, deliberate — and correctly scoped to just these 5 items) |
| **GPU driver availability (WDDM KMDs) — the actual current 3D bottleneck** | A real GPU vendor driver (Intel/AMD/NVIDIA) or, under virtualization, a virtual-GPU driver (e.g. virtio-gpu, VMware SVGA3D) providing real 3D acceleration | **No WDDM 3D-capable KMD exists for any common virtualization target.** Under plain QEMU/OVMF (no Hyper-V, no Raspberry Pi), the only WDDM adapter available is `softgpu` — a generic VBE/GOP display-only fallback with no 3D execution DDI at all (`drivers/directx/CMakeLists.txt:12`). A real, substantial virtio-gpu driver (`win32ss/drivers/miniport/virtgpu`, 4,500+ lines, includes virgl 3D IOCTLs/capsets) does exist — but on the *legacy XPDM* side, not WDDM, so it's inert on a WDDM build. Real 3D acceleration currently only works end-to-end on Raspberry Pi 3/5 via `rpi3vc4`/`rpi5vc4` (genuine WDDM2 KMDs for the VideoCore GPU). A Mesa LLVMpipe/Lavapipe CPU software-rendering fallback (`ENABLE_MESA_LLVMPIPE`) is vendored and was **flipped to default-on 2026-11-01 (ARCH-scoped to amd64/arm64, matching the payload's own restriction)** after a fresh validation pass on this exact amd64/MinGW-GCC/QEMU setup: the SHA256-pinned release payload downloads and packages correctly (`mesa_llvmpipe.dll`, `vulkan_lvp.dll`, `lvp_icd.json` → `Windows/system32/`), and the Khronos Vulkan *loader* (`vulkan-1.dll`) — a prerequisite the first validation pass missed, since without it nothing could actually dispatch a `vkCreateInstance` call to the Lavapipe ICD — was also brought in by checking out the `mesa` source feed (`scripts/feeds update mesa`, needed only for its vendored Vulkan headers; the loader's own source already lives in-tree at `dll/win32/vulkan-1/`) and now builds and packages correctly for both native amd64 and WoW64/i386. A full boot test with the complete set showed zero new regressions. Note this only validates *packaging and boot stability* — it does not independently re-confirm actual OpenGL/Vulkan rendering (no in-guest app invoked the API in this pass); that matters less for the GPU-driver gap itself since Mesa is a user-mode software ICD, not a kernel display driver, and does not touch the `softgpu`/PDEV gap above at all. A real build-config bug was also caught and fixed in review: the naive default flip would have broken i386/arm configures (the payload hard-errors outside amd64/arm64); fixed by scoping the option with `cmake_dependent_option` instead of a bare `option()`. A separate, pre-existing stale `depends TOOLCHAIN=clang` on the menuconfig entry (left over from before the release-payload mode existed) was also removed, since the payload path has no such requirement | `drivers/directx/CMakeLists.txt`, `win32ss/drivers/miniport/virtgpu/CMakeLists.txt:16-20`, `drivers/directx/{rpi3vc4,rpi5vc4}/*`, `submodules/mesa-llvmpipe.md`, `sdk/cmake/config.cmake:189-190`, `sdk/cmake/rosconfig.def:328-333`, `dll/win32/CMakeLists.txt:321-326`, `dll/win32/vulkan-1/CMakeLists.txt` | **Large.** A detailed, staged (display-only first, then virgl 3D) implementation plan exists at `drivers/directx/VIRTIO_GPU_WDDM_PLAN.md` — planning only as of 2026-11-01, no driver code written yet. Legally unblocked per AGENTS.md (public VirtIO-GPU spec + Linux driver study, no clean-room concern) |
| D3D12 user-mode runtime | `d3d12.dll` talking to a native UMD | **Present and appears substantial**, not a thin Wine/vkd3d shim. A genuine native frontend exists (`native12.cpp`, `native12_device.h`, `native12_device5.cpp`, `native12_device10.cpp`, `native12_pipeline.cpp`, `native12_queue.cpp`, `native12_resource.cpp`, `native12_swapchain.cpp`, `native12_video.cpp`), selected via `LIBRENT_USE_WDDM`; a vkd3d-backed fallback also exists for the non-WDDM path. Under plain QEMU today, the vkd3d→Vulkan fallback would itself land on Lavapipe (software), per the row above | `dll/directx/wine/d3d12/CMakeLists.txt`, `dll/directx/wine/d3d12/native12_*.cpp` | **Small-medium** (presence confirmed; depth of DDI coverage not fully auditable from source alone) |
| "ReactX" (`win32ss/reactx/`) | N/A — Windows 11 has no equivalent; this is pre-Vista XPDM-era DirectDraw | **Present, but intentionally dead on WDDM builds.** Vintage upstream ReactOS branding (named circa 2007-2009, confirmed via `git log` — not a LibreNT rebrand artifact, and untouched by the rebrand commit) for the legacy XPDM DirectDraw/D3D-thunk stack (`ntddraw`, `dxg`, `dxgthk`, `dxapi`). On a WDDM build it explicitly disables itself (`win32ss/reactx/ntddraw/ddraw.c:52`: "WDDM build, legacy dxg.sys path disabled") | `win32ss/reactx/{ntddraw,dxg,dxgthk,dxapi,ntdxvista}/*` | **None** (correctly inert by design; not a gap to close) |
| DWM composition | Window composition, Acrylic/Mica materials, shadows, blur | **Present, real.** `gpumaterial.h` contains an actual GLSL fragment shader implementing the Acrylic brush-color/backdrop-blend algorithm (not a stub); Mica/Mica Alt/Tabbed are mapped via `DWMSBT_MAINWINDOW/TRANSIENTWINDOW/TABBEDWINDOW` → `DWM_BACKDROP_MAIN/TRANSIENT/TABBED` in `composition.c` | `base/system/dwm/gpumaterial.h`, `base/system/dwm/settings.c:19` (`DWM_EFFECT_ACRYLIC`), `win32ss/user/ntuser/composition.c:3311-3339` | **Small** |
| HDR10 | Per-output HDR metadata signaling (SMPTE ST 2084) | **Present as real plumbing**, not just headers — `RXGK_HDR10_METADATA` is populated and passed through the present path | `drivers/directx/dxgkrnl/present.c:4912-4948`, `drivers/directx/dxgkrnl/dma.c:1296-1342` | **Small** |
| Variable refresh rate (VRR/Adaptive Sync/FreeSync/G-Sync) | VRR negotiation in the present path | **No trace found** beyond HDR10 metadata handling | `grep -i "VRR\|AdaptiveSync\|FreeSync\|GSync" drivers/directx/dxgkrnl/*` → no matches outside HDR10 | **Medium** |
| Per-monitor DPI scaling | `DPI_AWARENESS_PER_MONITOR_AWARE`, `SetProcessDpiAwarenessContext` | **Present.** Implemented in both the kernel-side thread DPI context and user32 | `win32ss/user/ntuser/ntstubs.c:1271-1293`, `win32ss/user/user32_vista/dpi.c:124-171`, `win32ss/gdi/gdi32/objects/dc.c:622-629` | **Small** |

---

## 4. Shell & UI

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| Explorer shell core (taskbar, Start menu, tray) | Fluent-styled Start menu, taskbar, system tray, jump lists | **Present, fairly built out.** `startmnu2.cpp`/`startmnu2.h` (a second-generation Start menu implementation alongside the legacy one), `taskband.cpp`, `trayclock.cpp`, `syspager.cpp`, `appbar.cpp` | `base/shell/explorer/*.cpp` | **Small-medium** |
| Search (Start menu/taskbar search, indexer) | `SearchUI`/`SearchApp`, `SearchIndexer.exe`, Windows Search protocol hosts | **Absent.** No search UI or indexer component anywhere | `find . -iname "*searchui*" -o -iname "*searchindexer*" -o -iname "*searchprotocolhost*"` → no results | **Total** |
| Widgets / News and Interests board | Widget board flyout | **Absent.** No matches for widget-board terminology in the shell | `grep -ril "widget board\|news and interests\|WidgetBoard" base/shell` → no results | **Total** |
| Snap Layouts | Hover-to-snap grid overlay | Not found as a named component; not independently confirmed either way from source alone | no direct evidence found | **Unclear/likely absent** |
| Task View / Virtual Desktops | `IVirtualDesktopManager`, multi-desktop switcher | **Absent.** No `IVirtualDesktopManager`/virtual-desktop-manager implementation found | `grep -ril "VirtualDesktopManager\|IVirtualDesktopManager" .` → no results | **Total** |
| Action Center / Notification Center | Centralized notification flyout, quick settings | **Absent.** No action-center/notification-center/`wpnidm`/`wpnservice` component | `find . -iname "*actioncenter*" -o -iname "*notificationcenter*" -o -iname "*wpnidm*" -o -iname "*wpnservice*"` → no results | **Total** |
| Settings app vs. Control Panel | Modern Settings app covers most day-to-day configuration; Control Panel kept only for legacy/advanced items | Both exist side by side: `base/applications/systemsettings` (14,474 total lines across its files — a real app, not a shell) and the full legacy `dll/cpl` Control Panel applet set. Coverage breadth of `systemsettings` vs. real Windows 11's Settings app is not fully auditable from source size alone | `base/applications/systemsettings/*`, `dll/cpl/*` | **Medium** (exists, breadth uncertain) |
| Fluent Design icons | Fluent UI System Icons | Per AGENTS.md, genuine Fluent UI System Icons are used unmodified — not independently re-verified here, taken as given per project policy | AGENTS.md §"Shell and UI" | **None** (per project policy) |

---

## 5. App platforms

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| WinRT activation / `combase` | `RoGetActivationFactory`, `RoActivateInstance`, apartment model, COM marshaling | **Present, substantial.** `combase.c`, `roapi.c` (implements `RoGetActivationFactory`), plus `apartment.c`, `marshal.c`, `stubmanager.c`, `comcat.c` | `dll/win32/combase/roapi.c`, `dll/win32/combase/*.c` | **Small-medium** |
| `Windows.Foundation`/`wintypes` | Property values, maps, buffers, storage types used throughout WinRT APIs | **Present, substantial** — 5,975 total lines across `main.c` (2,163 lines), `map.c`, `storage.c`, `valueset.c`, `metadata.c`, `propertyset.c`, `buffer.c` | `dll/win32/wintypes/*.c` | **Small-medium** |
| MSIX/APPX packaging & installation | Full package deployment stack (`AppxDeploymentClient`, `appxdeploy.dll`, `wsreset`, etc.) | **Largely absent, one literal stub found.** `appxalluserstore_main.c` is 38 lines, and its one real export (`DidAppSurviveOSUpgradeForUser`) returns `E_NOTIMPL` with a `DPRINT1("...: stub\n")`. No `AppxDeploymentClient`/`AppxPackaging`-equivalent component exists at all | `dll/win32/appxalluserstore/appxalluserstore_main.c` (full file read — pure stub); `find . -iname "*appxdeployment*" -o -iname "*appxpackaging*"` → no results | **Large-total** |
| Microsoft Store client | Store app for browsing/installing packaged apps | **Absent.** No store client component | `find . -iname "*winstore*" -o -iname "*microsoftstore*"` → no results | **Total** |
| Win32 app-compatibility shims | Large shim database (`sysmain.sdb`) covering hundreds of legacy-app quirks | **Present but narrow.** `dll/appcompat/shims/layer` contains only ~7 generic shims: `dispmode.c`, `forcedxsetupsuccess.c`, `globalmemorystatus.c`, `verifyversioninfolite.c`, `versionlie.c`/`.inl`, `vmhorizon.c` | `dll/appcompat/shims/layer/*` | **Large** (infrastructure exists, coverage is a tiny fraction of Windows') |

---

## 6. Virtualization & containers

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| Hyper-V (host hypervisor) | Type-1 hypervisor (`hvix64`/`hvax64`), VID.sys, host-side virtualization stack | **Absent.** What exists instead is *guest*-side integration: `drivers/bus/vmbus/vmbus.c` (1,200 lines — a real VMBus client implementation) and `drivers/directx/hypervvid` (synthetic video driver for running *as* a Hyper-V guest), plus `ntoskrnl/ke/arm64/hypervisor.c`. There is no evidence LibreNT can itself host VMs via Hyper-V | `drivers/bus/vmbus/vmbus.c`, `drivers/directx/hypervvid/*`; `find . -iname "*securekernel*" -o -iname "*hvix64*"` → no results | **Total** (as a host); guest-side support is comparatively mature |
| Windows Sandbox | Lightweight disposable VM for app isolation | **Absent.** No sandbox/container-execution-agent component | `find . -iname "*wsb*" -o -iname "*containerexecutionagent*"` → no results | **Total** |
| WSL2-equivalent (Linux subsystem) | WSL2: real Linux kernel in a lightweight Hyper-V VM; WSLg for GUI apps | **Present and appears to be the most mature non-core addition in the tree**, but architecturally closer to WSL1 (direct NT-kernel syscall translation) than WSL2 (no VM, no real Linux kernel). `subsystems/linux/lxcore` alone totals ~53,000 lines across syscall translation (`unistd.c`), VFS (`vfs.c`, 4,613 lines), TTY (`tty.c`, 1,320 lines), sockets (`socket.c`), netlink (`netlink.c`), futex (`futex.c`), BPF (`bpf.c`), cgroups-ish config (`kconfig.c`), plus separate `lxlaunch`, `lxrun`, `lxterm`, `lxwayland` (GUI/Wayland bridge, à la WSLg), and `lxwinhost` components | `subsystems/linux/lxcore/*.c`, `subsystems/linux/{lxlaunch,lxrun,lxterm,lxwayland,lxwinhost}` | **None** as a functional WSL-like feature (actively developed, broad syscall surface); architecture differs from real WSL2 by design |

---

## 7. Networking

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| Modern Wi-Fi drivers | Native Wi-Fi miniport drivers for current chipsets | **Present.** `cyw43455` (Raspberry Pi/Broadcom), `rt2800usb`, `rtw8852bs` drivers exist with OID/MLME handling | `drivers/network/dd/{cyw43455,rt2800usb,rtw8852bs}/*` | **Small** |
| WPA3 / SAE | WPA3-Personal (SAE) and WPA3-Enterprise cipher/auth support | **Not confirmed.** A text search for "SAE"/"WPA3" only turned up filename/incidental matches (including one hit inside a compiled `.sys` binary, i.e., a false positive); no SAE handshake or WPA3 AKM suite logic was found in the driver or WLAN API sources reviewed | `grep` across `drivers/network`, `dll/win32/wlanapi`, `sdk/include` — no genuine source-level matches | **Medium-large** (likely absent, not fully provable as absent from source alone) |
| `wlanapi.dll` | WLAN profile/connect/notification API | **Present, substantial.** `main.c` (661 lines), `notification.c` (290 lines), `profile.c` (231 lines) | `dll/win32/wlanapi/*.c` | **Small** |
| Bluetooth stack | BR/EDR + BLE, `bthprops`, `bluetoothapis`, GATT | **Present across layers, breadth uncertain.** `drivers/bluetooth/bthusb` (458 lines), `drivers/bluetooth/hidbthle` (BLE HID-over-GATT profile), `dll/win32/bluetoothapis`, `dll/win32/windows.devices.bluetooth`, `dll/cpl/bthprops` all exist | `drivers/bluetooth/bthusb/bthusb.c`, `drivers/bluetooth/hidbthle/*`, `sdk/include/psdk/bthledef.h` | **Medium** (core + one BLE profile present; general BLE/GATT application surface not confirmed) |
| Modern VPN Platform | `RasMan`/VPN Platform CSPs, split tunneling, Always On VPN | **Absent as a modern stack.** Only the legacy `rasapi32` (dial-up-era RAS API) was found | `dll/win32/rasapi32/*` | **Large** |
| DNS-over-HTTPS | System-wide DoH resolver option | **Absent.** No DoH-related code anywhere | `grep -ril "DNS.over.HTTPS\|DoH\b" .` → no genuine matches | **Total** |
| Network Quality of Service (qWAVE) | `qwave.dll`/QoS subsystem for app traffic prioritization | **Absent.** No `qwave`/`qosmgr` component | `find . -iname "*qwave*" -o -iname "*qosmgr*"` → no results | **Total** |

---

## 8. x86-on-ARM64 app compatibility

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| WoW64 (64-bit host running 32-bit code) | Built for every 64-bit target | **Present**, with amd64 and arm64 CPU-backend subdirectories; per AGENTS.md this is required on every 64-bit target, not architecture-gated by a hardcoded list | `dll/win32/wow64/{amd64,arm64}`, AGENTS.md §"Architecture neutrality" | **Small** |
| x86-on-ARM64 emulation (FEX) | Emulates x86/x64 user-mode code on ARM64 | **Present with real build integration**, not just a name: `sdk/cmake/fex_amd64.cmake` validates that every listed FEX target actually exists in the tree before building AMD64 command payloads through FEX; `submodules/fex-arm64ec.cmake` pulls in the FEX submodule | `sdk/cmake/{fex_amd64.cmake,fex_amd64_targets.cmake,fex-amd64-validate.cmake}`, `submodules/fex-arm64ec.cmake`, `modules/fexbench/*` | **Small-medium** (plumbing confirmed real; end-to-end app compatibility coverage not verifiable from source alone) |
| ARM64EC / CHPE | Mixed x64/ARM64 native code in one process | Gated to ARM64 per project policy, referenced across multiple `CMakeLists.txt` (ntdll, kernel32, mshtml, shell32, ucrtbase, rpcrt4, oleaut32, msvcrt, win32k area, user32, vcruntime, symcrypt) | `grep -ril "ARM64EC\|CHPE" --include=CMakeLists.txt .` (20 matches) | **Small-medium** (broad build-level presence; maturity of runtime switching not independently verified) |

---

## 9. File systems & storage

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| New NTFS driver core | Read/write NTFS with standard attributes | **Present, substantial.** `drivers/filesystems/ntfs_new` plus `sdk/lib/fslib/ntfslib_new` (with a `filerecord/read` subtree, a Linux FUSE port for testing, FSCTL handling in `fsctrl.c`) | `drivers/filesystems/ntfs_new/*`, `sdk/lib/fslib/ntfslib_new/*` | **Small-medium** |
| NTFS compression | Read and write of compressed files | **Read path present** (`compression.cpp`, 710 lines, under `filerecord/read`); write/creation path for new compressed files not confirmed from the files inspected | `sdk/lib/fslib/ntfslib_new/src/filerecord/read/compression.cpp` | **Medium** (read path evidenced; write path unconfirmed) |
| EFS (Encrypting File System) | Per-file transparent encryption | **No evidence found.** No "encrypt" references in the new driver's volume/FSCTL code | `grep -in encrypt drivers/filesystems/ntfs_new/{fsctrl.c,vol.c}` → no matches | **Large** (likely absent) |
| ReFS | Resilient File System, available on Windows 11 Pro/Enterprise/Workstation | **Absent.** No ReFS driver; the only "refs" hits in the tree are unrelated (`.git/refs`, a win32k documentation file) | `find . -iname "*refs*"` → only unrelated matches | **Total** |
| Storage Spaces | Software-defined pooled/resilient storage | **Absent.** No `storagespaces`/`spaceport` component | `find . -iname "*storagespaces*" -o -iname "*spaceport*"` → no results | **Total** |
| Storage Sense / deduplication | Automatic disk cleanup; data deduplication | **Absent.** No matches for either feature | `find . -iname "*dedup*" -o -iname "*storagesense*"` → no results | **Total** |

---

## 10. Update & servicing

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| Windows Update client/servicing stack | `wuauserv`, `usoclient`, full update orchestration, delivery optimization | **Present only as a thin service skeleton.** `wuauserv.c` is 137 lines — far short of a real update orchestrator; no `usoclient`/delivery-optimization equivalent found | `base/services/wuauserv/wuauserv.c` (137 lines), `find . -iname "*usoclient*" -o -iname "*windowsupdate*"` → no further results | **Large** |
| Windows Installer (MSI) | Full MSI engine | **Present, substantial.** `dll/win32/msi` has a large, Wine-derived-looking file set: `action.c`, `alter.c`, `appsearch.c`, `assembly.c`, `automation.c`, `classes.c`, `custom.c`, `database.c`, `dialog.c`, `format.c`, etc. | `dll/win32/msi/*.c` (directory listing) | **Small** |
| Driver update / Plug-and-Play UI parity | Device Manager, driver update flow | Not deeply audited in this pass; PnP core itself is extensively covered in `dxgkrnl` (`pnp.c`) and elsewhere; UI-level parity not independently verified | `drivers/directx/dxgkrnl/pnp.c` (PnP core present) | **Unclear** (not separately audited) |

---

## 11. Audio

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| WASAPI core (`mmdevapi`) | Device enumeration, exclusive/shared mode, session management | **Present.** `dll/win32/mmdevapi` has device enumeration (`devenum.c`), session/volume/private headers, a full IDL (`mmdevapi_classes.idl`), and winetests exist for it | `dll/win32/mmdevapi/*` | **Small** |
| Spatial audio | `ISpatialAudioClient`, object-based rendering | **Present.** `spatialaudio.c` exists alongside a matching IDL (`spatialaudioclient.idl`) and a winetest (`modules/rostests/winetests/mmdevapi/spatialaudio.c`) | `dll/win32/mmdevapi/spatialaudio.c`, `sdk/include/psdk/spatialaudioclient.idl` | **Small-medium** (presence confirmed, depth not fully audited) |
| Audio service (`audiosrv`) | Core Audio service hosting the above | **Present** | `base/services/audiosrv/*` | **Small** |

---

## 12. .NET integration

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| .NET Framework / modern .NET runtime | Pervasive — PowerShell, many system tools, and a very large fraction of third-party Win32 apps on real Windows 11 either ship with or depend on .NET being present | **Registry plumbing only; no runtime found.** `boot/bootdata` sets up the `.NETFramework\InstallRoot` registry key pointing at `C:\Windows\Microsoft.NET\Framework(64)\...` for amd64/arm64/i386/WoW64, but **no `mscoree.dll`, `clr.dll`, `coreclr`, or any CLR/host component exists anywhere in the tree** | `boot/bootdata/hivesys_amd64.inf:8`, `hivesys_arm64.inf:10`, `hivesys_i386.inf:6`, `hivewow64.inf:13` (all set `InstallRoot`); `find . -iname "*mscoree*" -o -iname "*clr.dll*" -o -iname "*coreclr*" -o -iname "*dotnet*" -o -iname "*netfx*"` → no results anywhere | **Total** (for the runtime itself) — and a significant one, since this silently blocks a large class of real-world Windows 11 software regardless of how complete the rest of the OS is |

---

## 13. Accessibility

| Area | Real Windows 11 | LibreNT status | Evidence | Gap |
|---|---|---|---|---|
| Magnifier | Screen magnification tool | **Present.** `base/applications/magnify` exists as a real application | `base/applications/magnify/magnify.rc` | **Small** |
| Narrator | Built-in screen reader | **Absent.** No Narrator component found anywhere, under any naming variant searched | `grep -ril narrator . ` (broad search) → no results | **Total** |
| UI Automation (`uiautomationcore`) | Full UIA provider/client model used by Narrator, other screen readers, and test automation | **Present as a DLL shell, but a large share of patterns are literal `@ stub` entries.** `uiautomationcore.spec` stubs out `InvokePattern_Invoke`, `ScrollPattern_Scroll`, `ScrollPattern_SetScrollPercent`, `ScrollItemPattern_ScrollIntoView`, `SelectionItemPattern_Select`/`AddToSelection`/`RemoveFromSelection`, `TextPattern_GetSelection`/`GetVisibleRanges`/`RangeFromChild`, `RangeValuePattern_SetValue`, `ExpandCollapsePattern_Expand`/`Collapse`, `GridPattern_GetItem`, `DockPattern_SetDockPosition`, `MultipleViewPattern_*`, `LegacyIAccessiblePattern_*`, `ItemContainerPattern_FindItemByProperty`, `SynchronizedInputPattern_*` — i.e., most of the patterns real assistive-technology and UI test tools actually call | `dll/win32/uiautomationcore/uiautomationcore.spec` (full file read) | **Large** |

---

## 14. Enterprise / management

As expected for a project in this category, essentially none of this exists:

- **Group Policy** (`gpedit.dll`, `gpsvc`): absent — `find . -iname "*gpedit*" -o -iname "*gpsvc*"` → no results.
- **MDM / CSPs / Intune enrollment** (`deviceenroller`, enrollment API): absent — `find . -iname "*mdm*" -o -iname "*enrollmentapi*" -o -iname "*deviceenroller*"` → no results.
- **Windows Hello for Business**: absent (depends on NGC/WinBio, both absent — see §1).
- **Domain join** (`netjoin`, `dsrole`): absent — `find . -iname "*netjoin*" -o -iname "*dsrole*"` → no results.

**Gap: total**, across the board. This is unsurprising for an enthusiast/hobby-scale OS and is not a near-term priority, but it means LibreNT currently has no path to being managed in any organizational sense.

---

## Biggest gaps (priority summary)

1. **No Credential Provider model at all (identity/logon).** This is the single largest compatibility gap in absolute terms: Windows 11 has had *zero* GINA support since Vista, and LibreNT has *zero* Credential Provider support. Every modern sign-in experience (PIN, Hello, smart card via CP, Azure AD/Entra join prompts) is unreachable until this exists. (§1)

2. **No .NET runtime of any kind**, despite the OS advertising `.NETFramework\InstallRoot` in the registry as if it were present. A very large fraction of real-world Windows 11 software — from system tools to ordinary third-party apps — assumes .NET exists. This blocks compatibility broadly and silently (apps will fail at launch rather than being visibly "unsupported"). (§12)

3. **The entire VBS/HVCI/Credential Guard/BitLocker/Defender security stack is absent**, and the one piece that exists partially to support it (TPM 2.0) has a real kernel driver but no `tbs.dll` to expose it to user mode or to BitLocker. Secure Boot verification is two named stubs, not a real chain of trust. (§2)

4. **MSIX/APPX packaging is a single 38-line stub returning `E_NOTIMPL`.** There is no package deployment client, no Store. Any app distributed only as MSIX cannot be installed. (§5)

5. **No WDDM 3D-capable GPU driver exists for any common virtualization target (current active priority).** The WDDM scheduler quarantine (autonomous GPU run lists, advanced scheduling, WDDM 3.2 submission, TDR ABI, VidMm/VidSch private tables) is correctly scoped to just those 5 undocumented-Microsoft-ABI items and does NOT block this — plain basic 3D adapter bring-up is unrestricted. The real gap is that `softgpu` (the only WDDM adapter under plain QEMU) is display-only, while the one real virtual-GPU driver that exists (`virtgpu`, virtio-gpu with virgl 3D) sits on the legacy XPDM side of the fence. Porting/rewriting it as a WDDM KMD against the public VirtIO-GPU spec is clean under AGENTS.md's sourcing policy and would plug straight into the existing dxgkrnl/dxgmms2 scaffolding. (§3)

6. **UI Automation is mostly stubbed at the pattern level** (`Invoke`, `Scroll`, `SelectionItem`, `Text`, `RangeValue`, and more are all `@ stub`), which in turn means Narrator (itself entirely absent) and any third-party screen reader or UI test tool have no real provider surface to call into. (§13)

7. **Shell-level Windows 11 UX is partial**: Search/indexer, Widgets, Task View/Virtual Desktops, and Action Center/Notification Center all have no trace in the tree, even though the taskbar/Start-menu core (`startmnu2`) and Settings app exist and look reasonably built out. (§4)

8. **Networking has two large, unglamorous gaps**: no modern VPN Platform (only legacy dial-up-era RAS), and no confirmed WPA3/SAE support despite modern Wi-Fi chipset drivers (cyw43455, rtw8852bs) already existing — meaning current-generation Wi-Fi security may not actually negotiate on networks that require WPA3. (§7)

For contrast, the areas that turned out more complete than a skeptical read of the file *names* alone would suggest: **DWM composition** (a real Acrylic GLSL shader, genuine Mica/Mica Alt/Tabbed backdrop mapping), **D3D12** (a real native UMD frontend, not just a Wine/vkd3d shim), **WinRT/`combase`/`wintypes`** (thousands of lines of real logic), **the Linux subsystem** (`lxcore` alone is ~53,000 lines of real syscall/VFS/socket/netlink/futex/BPF translation), and **MSI** (a large, apparently complete installer engine). These are a good foundation to build the remaining gaps on top of.
