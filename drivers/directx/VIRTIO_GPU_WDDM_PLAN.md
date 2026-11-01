# VirtIO-GPU WDDM KMD Port — Staged Implementation Plan

**Status:** Planning only, as of 2026-11-01. No driver code has been written yet; this
document exists so Stage 1 can start in a future session without re-deriving the survey
below. See `WINDOWS11_COMPAT_GAPS.md` section 3 ("GPU driver availability") for why this
is the current top priority: the only WDDM adapter under plain QEMU is `softgpu`
(display-only; no 3D), and the one real 3D-capable virtio-gpu/virgl driver that exists
in this tree (`win32ss/drivers/miniport/virtgpu`) is built against the legacy XPDM
model and is inert on WDDM builds.

**Legal/sourcing constraint (binding on all of this work):** per `AGENTS.md`'s "Sources
of truth" policy, hardware driving must be based on the public VirtIO-GPU OASIS
specification plus *studying* (never copying) Linux's virtio-gpu/virgl driver and
Mesa's virgl Gallium driver for technique. `drivers/directx/wddm_cleanroom_gate.h`'s
5 quarantined items (autonomous GPU run lists, multi-app priority scheduling, WDDM 3.2
submission, private TDR ABI, native VidMm/VidSch export tables) are undocumented
Microsoft-private kernel ABI, not GPU driver IP — this plan does not touch any of them;
ordinary WDDM 2.x adapter/engine bring-up is unrestricted.

**Project floor:** must work on any UEFI-capable system generally, but virtio-gpu
itself is inherently QEMU/KVM-only paravirtualized hardware — this KMD is scoped to
virtio-gpu-equipped VMs specifically; `softgpu` remains the fallback elsewhere. Software
compat floor is Windows 7, so the `DXGKDDI_INTERFACE_VERSION`/`LIBRENT_WDDM_TARGET_LEVEL`
this KMD targets must not silently assume a newer WDDM level than the project allows.

---

## 0. Survey findings

### 0.1 What's in the existing XPDM `virtgpu` tree, reusable vs. not

`win32ss/drivers/miniport/virtgpu/` builds three binaries: `virtgpu` (VideoPort
miniport, `virtgpu.c`/`.h`, 4526/593 lines, XPDM-only per its `CMakeLists.txt:16-20`),
`virtgpu_disp` (GDI DDI display driver, `display.c`/`.h`, 2901/381 lines), `virtgpuogl`
(user-mode OpenGL ICD, `virtgpuogl.c`, 23286 lines).

**Reusable near-verbatim (public-spec wire structures, no legal issue):**
- `virtgpu.h:85-417` — `VIRTGPU_CTRL_TYPE`, `VIRTGPU_CTRL_HDR`, `VIRTGPU_RESOURCE_CREATE_2D/3D`,
  `VIRTGPU_SET_SCANOUT`, `VIRTGPU_TRANSFER_TO_HOST_2D`, `VIRTGPU_RESOURCE_CREATE_BLOB`,
  `VIRTGPU_CTX_CREATE`, capset/EDID structs — 1:1 transcriptions of the OASIS spec's wire
  format, directly liftable into a new header.
- `sdk/lib/drivers/virtio/*` (`VirtIOPCIModern.c`, `VirtIOPCILegacy.c`, `VirtIORing*.c`,
  `VirtIO.h`) — the virtio PCI transport, already a standalone static lib decoupled from
  VideoPort via a caller-supplied `VirtIOSystemOps` vtable (`virtgpu.c:273`). Reusable
  unchanged; only a new WDM-based ops implementation is needed.
- The command-building *technique* in `VirtGpuSendCommand`/`SendCommandWithPayload`
  (`virtgpu.c:692,771`), `Create2DResource`/`SetScanout`/`Flush` (`:2463,2438,2715`),
  `Create3DResource`/`Submit3D`/`Execute3DBatch` (`:1551,2069,2298`), capset probing
  (`VirtGpuQuery3DCapsets`, `:1017`) — portable as *understood technique*, reimplemented
  (not copied) against WDM/dxgkrnl primitives instead of `VideoPortXxx` calls.

**Not reusable, tied to the legacy contract:**
- `virtgpu.c:3257-4526` (`DriverEntry`→`VideoPortInitialize`, `FindAdapter`, `StartIO`'s
  giant `IOCTL_VIDEO_*` switch at `:3462-4373`) — the StartIO/IOCTL dispatch model has no
  WDDM equivalent; dxgkrnl calls KMD DDI function pointers directly.
- `VirtGpuFindPciDevice`/`CaptureBars`/`EnablePciDevice` (`:378,310,471`) — manual PCI scan
  via VideoPort's `ConfigInfo`. A WDDM KMD gets pre-translated resources via
  `DxgkDdiStartDevice`'s `DXGK_START_INFO`/`CM_RESOURCE_LIST` instead (see
  `drivers/directx/softgpu/platform_root.c:965-980` for the pattern in this tree).
- All of `display.c`/`display.h` (GDI DDI `DrvEnableDriver`/`DrvEnablePDEV`/etc.) — zero
  carry-over; WDDM has no legacy GDI DDI surface.
- `virtgpuogl.c`/`.spec` — reusable as architectural *concept* for a future UMD, not code
  (its transport is private IOCTLs to `virtgpu.sys`, which won't exist).
- `virtgpu.h:458-529` `VIRTGPU_DEVICE_EXTENSION` — a VideoPort `HwDeviceExtension` blob;
  field-level inspiration only for the new device extension shape.

### 0.2 WDDM KMD shape in this tree — two concrete templates

**`drivers/directx/rpi5vc4`** (real hardware, full WDDM 2.x KMD — most instructive
template for "talks to a real external GPU command queue with fencing"):
- `rpi5vc4.c:329-402` assembles the full `DRIVER_INITIALIZATION_DATA` table: adapter
  lifecycle (`:329-342`), allocation/memory (`:345-351`), execution (`:354-361`,
  implemented in `rpi5vc4_wddm.c` — `CreateContext` `:2258`, `Render` `:2705`,
  `SubmitCommand` `:3126`, `GetNodeMetadata` `:3560-3588`), context/process (`:367-375`),
  VidPN/display (`:382-390`).
- `rpi5vc4_v3d_exec.c` (9289 lines) is the best in-tree template for a render node whose
  submissions go to an external GPU command queue with fencing/preemption, even though
  the wire protocol (V3D ISA vs. virgl/TGSI) is completely different — study the
  validate-before-submit pattern, not the protocol specifics.

**`sdk/lib/drivers/softgpu`** (generic shared engine + swappable "platform" backend):
- A *library*, not a leaf driver — `softgpu.c:337-472` assembles the DDI table
  generically; `softgpu.h:182-432` defines the `PSOFTGPU_PLATFORM_SET_MODE` callback and
  `SOFTGPU_PLATFORM_CONFIG`/`SOFTGPU_DEVICE` contract a "platform" must fill in.
- **Caveat:** `SOFTGPU_SUBMIT`'s `NullRendering` flag (`softgpu.h:218`) and its single
  node (`SOFTGPU_NODE_3D`, `:228`) are a *software* rasterizer/null-render path, not a
  path that forwards opaque command buffers to an external GPU queue — the shared
  engine's 3D node is NOT a drop-in fit for virtio-gpu 3D as-is.
- The **2D/display path is a good fit**: `SOFTGPU_PLATFORM_CONFIG`, `PlatformQueryStart`,
  `PlatformSetMode`, `PlatformPresentDisplayOnly`, `PlatformScanoutWritten`
  (`platform_root.c:877-1289`) already assumes "CPU writes land in a backing buffer, then
  a platform-specific step pushes pixels to the real scanout" (the VBE "root shadow"
  path, `:465-552,1092-1181`) — maps directly onto virtio-gpu's
  backing-pages→`TRANSFER_TO_HOST_2D`→`RESOURCE_FLUSH` sequence.
- `drivers/directx/softgpu/platform_root.c` has zero `DxgkDdi*` symbols of its own — it's
  purely a platform plugin (`CMakeLists.txt:29-38`), confirming the "simplest WDDM
  adapter, display-only" shape.

### 0.3 dxgkrnl scaffolding — unmodified by this work

`drivers/directx/dxgkrnl/` (108,693 total lines: `vidmm.c` 18084, `adapter.c` 17677,
`d3dkmt.c` 14543, `vidpn.c` 8816, `present.c` 6427, `gpuva.c` 6600, `vidsch.c` 5446,
`display.c` 5465, `context.c` 3252, `sync.c` 2967, `pnp.c` 2474) is the mature core glue
between a KMD's DDI table and the OS, separate from `dxgmms2` (the scheduler). A new
virtio-gpu WDDM KMD is a *client* of all this, exactly like `rpi5vc4`/`softgpu` — it
registers DDI function pointers and receives `DXGK_INTERFACE` callbacks
(`DxgkCbGetDeviceInformation`, `DxgkCbNotifyInterrupt`/`QueueDpc`) at `StartDevice`.
**No changes to dxgkrnl/dxgmms2 are needed or planned.**

### 0.4 The clean-room gate does not apply here

`wddm_cleanroom_gate.h:17-21`'s 5 quarantined items are unrelated to ordinary adapter/
engine bring-up. Neither Stage 1 (display-only) nor Stage 2 (single-context ordinary
WDDM 2.x render/execution DDI, standard interrupt-driven fencing) touches any of them.

---

## Stage 1 — Minimal Display-Only VirtIO-GPU WDDM KMD

**Goal:** a WDDM adapter backed by a real virtio-gpu PCI device under QEMU that reaches
"has a suitable PDEV" via virtio-gpu's 2D commands — functional parity with `softgpu`
today, but over the virtio-gpu protocol.

### 1.1 OPEN DECISION — needs human sign-off before coding starts

- **(A) Standalone leaf KMD**, modeled on `rpi5vc4`: new `drivers/directx/virtgpu/` with
  its own full `DRIVER_INITIALIZATION_DATA`, device extension, hand-rolled 2D-only
  VidPN/present logic. More code up front; zero risk of fighting softgpu's
  software-rasterizer assumptions.
- **(B) New "platform" plugged into `sdk/lib/drivers/softgpu`'s shared engine**, modeled
  on `platform_root.c`: reuses the debugged VidPN/present/pointer/paging machinery
  wholesale; new code is just `platform_virtgpu.c`. Much smaller Stage 1 diff, but
  constrains Stage 2's 3D story (the shared engine's single 3D node assumes software
  rendering — see 0.2's caveat) unless that node is replaced or a second node is added,
  which erodes the reuse benefit.

**Recommendation: (B) for Stage 1**, explicitly deferring the Stage 1→2 node question
(replace vs. extend vs. fall back to (A)) to a checkpoint decision after Stage 1 ships,
rather than guessing now. Before committing, read `sdk/lib/drivers/softgpu/platform_common.c`
(167 lines, not yet read in depth) and `dma.c`'s `DxgkDdiRender`/`SubmitCommand` to see
exactly how "null rendering" is gated.

### 1.2 New/modified files (assuming option B)

- New: `drivers/directx/virtgpu/platform_virtgpu.c` — PCI device discovery via
  `DXGK_START_INFO`/`CM_RESOURCE_LIST` (not manual PCI scan), virtio feature negotiation,
  control-virtqueue setup, 2D resource/scanout/flush command building.
- New: `drivers/directx/virtgpu/{virtgpu.inf,virtgpu_reg.inf,virtgpu.rc,CMakeLists.txt}` —
  PCI hardware-ID match for vendor 0x1AF4, modern device 0x1050 and/or legacy transitional
  range 0x1000-0x103F (ID constants already at `virtgpu.h:26-29`, directly reusable;
  **decide upfront** whether to target modern-only or also legacy-transitional — changes
  both the `.inf` and how much of `VirtIOPCILegacy.c` vs `VirtIOPCIModern.c` gets used).
- Confirm exact leaf-driver/shared-lib boundary by reading
  `sdk/lib/drivers/softgpu/CMakeLists.txt` and `softgpu.cmake` before coding (not yet
  done in this planning pass).
- Carried in near-unchanged: `virtgpu.h`'s wire structs, `sdk/lib/drivers/virtio/*`
  linked as-is, plus a new ~150-250 line `VirtIOSystemOps` implementation replacing
  `virtgpu.c:12-273`'s VideoPort-based one (WDM primitives: `MmMapIoSpace`/resources from
  `TranslatedResourceList` instead of `VideoPortMapMemory`, `ExAllocatePoolWithTag`/
  `MmAllocateContiguousMemory` instead of `VideoPortAllocateContiguousMemory`,
  `KeStallExecutionProcessor` instead of `VideoPortStallExecution`).
- Not created at this stage: anything like `display.c`/`virtgpuogl.c` — no user-mode ICD
  needed yet; GDI/DWM use the existing generic WDDM display-only path.

### 1.3 Key DDI functions (via softgpu engine's platform hooks, option B)

- `DxgkDdiStartDevice`/`StopDevice`/`RemoveDevice` — generic in `softgpu.c`; platform
  supplies `SoftGpuPlatformQueryStart`/`QueryDescriptor` (EDID).
- `DxgkDdiQueryAdapterInfo` — generic, declares no 3D caps for Stage 1.
- `DxgkDdiIsSupportedVidPn`/`RecommendFunctionalVidPn`/`EnumVidPnCofuncModality`/
  `CommitVidPn`/`RecommendMonitorModes` — generic in the softgpu lib's `vidpn.c`, driven
  off `Config->Modes[]` populated via `VIRTGPU_CMD_GET_DISPLAY_INFO`/`GET_EDID`
  (reimplementing `VirtGpuGetDisplayInfo`/`QueryEdid`, `virtgpu.c:902,959`).
- `DxgkDdiSetVidPnSourceAddress`/`SetVidPnSourceVisibility` — generic, calls
  `PlatformSetMode`.
- `DxgkDdiPresent` (display-only) — generic in `dma.c`, calls
  `PlatformPresentDisplayOnly`/`PlatformScanoutWritten`: write backing pages, then
  `VIRTGPU_CMD_TRANSFER_TO_HOST_2D` + `RESOURCE_FLUSH` over the control virtqueue
  (reimplementing `virtgpu.c:2494,2573-2715`).
- `DxgkDdiGetScanLine` — report "not supported" (virtio-gpu 2D has no real
  scanline/vblank register); DWM already accepts a no-vsync fallback.

### 1.4 Exit criteria

- No "suitable PDEV" error for the virtio-gpu adapter; Device Manager shows a working
  WDDM driver.
- Display enumeration shows one VidPN source/target at a real negotiated mode (not a
  640x480 fallback), sourced from virtio-gpu's `GET_DISPLAY_INFO`/`GET_EDID`.
- Desktop renders and updates visibly via the `TRANSFER_TO_HOST_2D`+`RESOURCE_FLUSH`
  present path.
- No 3D/render-node claims yet (`DxgkDdiCreateContext` absent or "not supported").
- **Recommended automated check** (see risk 4 below): trigger a solid-color fill and
  verify it via QEMU QMP `screendump`, rather than requiring a human to eyeball a VM.

---

## Stage 2 — 3D Acceleration via virgl

**Goal:** extend the Stage 1 KMD with a render/execution DDI node forwarding virgl 3D
protocol over virtio-gpu's control virtqueue (same ring as 2D in this tree's precedent —
`virtgpu.h:466`'s single `ControlQueue`; confirm against the spec whether a separate ring
is conventionally used before assuming single-ring is required).

### 2.1 API path decision — recommendation made, confirm before coding

**OpenGL path, not D3D12/vkd3d.** virgl speaks TGSI/Gallium natively; a D3D12-to-TGSI
translator would be a much larger, riskier project than wiring an OpenGL ICD directly to
virgl. (`VIRTGPU_CAPSET_VENUS` exists at `virtgpu.h:69` but was never negotiated by the
old driver — Venus/Vulkan-over-virtio-gpu is a separate, newer context type and explicitly
out of scope here.) Mesa/Lavapipe (already enabled, see compat-gaps doc) is a *parallel,
software* Vulkan/D3D12-via-vkd3d path and does not need to integrate with this — they
coexist as different ICDs for different APIs.

### 2.2 New/modified files and key DDI functions

- Device extension gains a context table and 3D resource table (reference shapes:
  `VIRTGPU_3D_CONTEXT_STATE`/`VIRTGPU_3D_RESOURCE_STATE`, `virtgpu.h:433-456`).
- `DxgkDdiCreateContext`/`DestroyContext` — issue `VIRTGPU_CMD_CTX_CREATE`/`CTX_DESTROY`
  (reimplementing `virtgpu.c:1212,1265`), negotiating `VIRTGPU_CAPSET_VIRGL`/`VIRGL2`
  (reimplementing `VirtGpuQuery3DCapsets`, `:1017`).
- `DxgkDdiRender`/`Patch`/`SubmitCommand` on the new 3D node — translate UMD command-
  buffer patch locations into `TRANSFER_TO_HOST_3D`+`SUBMIT_3D` sequences (reimplementing
  `:2298,2069`), following `rpi5vc4_v3d_exec.c`'s validate-before-submit pattern (studied,
  not copied — wire format is unrelated).
- `DxgkDdiGetNodeMetadata` — report `DXGK_ENGINE_TYPE_3D` (pattern at
  `rpi5vc4_wddm.c:3576-3588`).
- Fencing: virtio-gpu 3D commands carry a `FenceId` in `VIRTGPU_CTRL_HDR` (`:141-149`)
  with host completion via the used-ring/interrupt; map to `DxgkCbNotifyInterrupt`,
  following the fence-bookkeeping pattern already generalized in `softgpu.h:238-256`'s
  `CurrentFence`/`CompletedFence`/`NotifiedFence`.
- Separate, later sub-stage (2b): a new user-mode OpenGL ICD, architecturally similar in
  *role* to `virtgpuogl.c` but written against the real D3DKMT/OpenGL-ICD contract and
  the new KMD's command-buffer surface, not private IOCTLs. Large, independent piece of
  work — not gated by the KMD's own completion.
- **Defer blob resources** (`RESOURCE_CREATE_BLOB`/`MAP_BLOB`, `virtgpu.h:364-395`) to a
  later increment within Stage 2 — a zero-copy optimization, not required for a first
  working virgl path, and the old driver's blob logic (`virtgpu.c:1651`, ~176 lines) is
  the single most complex piece to port. Sequencing it last reduces initial risk.

### 2.3 What carries from the old virgl/capset logic (technique, reimplemented)

Capset probing (`:1017-1105`), context creation with capset-ID encoding (`:1212`, using
the `VIRTGPU_CONTEXT_INIT_CAPSET_ID_MASK` bit layout at `virtgpu.h:64`), transfer/submit/
fence sequencing (`:1985-2401`), resource lifecycle state-machine shape (the
`BackingAttached`/`Blob`/`BlobMapped`/`UuidValid` flags at `virtgpu.h:439-456`).

Written fresh, no XPDM equivalent: the entire DDI-facing context/device/process
lifecycle (VideoPort miniports have no per-process GPU context concept), command-list
patch/validation (`DxgkDdiPatch` — the old ICD built virtio-gpu buffers via blocking
IOCTLs, no DDI-mediated command buffer existed), the GL-call-to-virgl-protocol encoding
itself (skim `virtgpuogl.c`'s 23,286 lines for architecture only).

### 2.4 Exit criteria

- A context on the 3D node can be created, a simple draw batch submitted and fenced, and
  the result visible via a `glClear`/triangle-level smoke test through the new ICD,
  running under QEMU with `-device virtio-gpu-gl`/virglrenderer.
- No reliance on any of the 5 `wddm_cleanroom_gate.h` items throughout.

---

## 3. Risks and open questions for human review

1. **Stage 1 architecture (1.1)** — (A) vs (B). Needs a decision before any code is
   written; (B) recommended but carries Stage 2 rework risk.
2. **DDI version targeting** — `drivers/directx/softgpu/CMakeLists.txt:26-27` pins
   `DXGKDDI_INTERFACE_VERSION` to `0x11007` (distinct from dxgkrnl's apparent default
   `0x1052`), with a comment that it must match dxgkrnl/dxgmms2's current target exactly.
   The new KMD must plug into the same `LIBRENT_WDDM_TARGET_LEVEL` gating (already used
   conditionally in `platform_root.c:897`) rather than choosing its own version
   independently. Also re-check this doesn't silently assume newer-than-Win7 WDDM.
3. **Host-side virgl requirement** — Stage 2 needs QEMU launched with
   `-device virtio-gpu-gl`/`virtio-vga-gl` and a host virglrenderer build (plus a working
   host GL/Vulkan stack underneath it). Not needed for Stage 1 (`-device virtio-gpu`/
   `virtio-vga` suffices for 2D). Document as a setup requirement; check whether this
   project's QEMU test harness already launches GL-capable virtio-gpu.
4. **Headless testing strategy** — decide whether to rely on serial/DPRINT tracing
   (already used throughout `softgpu`/`rpi5vc4`) and/or an automated QMP `screendump`
   check (e.g. trigger a solid-color fill, screendump, verify pixels) as part of Stage
   1's own exit criteria, rather than requiring a human to eyeball a VM each time.
5. **PCI device-ID matching breadth (1.2)** — modern-only (0x1050) vs. also legacy
   transitional (0x1000-0x103F). Changes the `.inf` and how much of
   `VirtIOPCILegacy.c` gets exercised.
6. **Scope confirmation** — this KMD is virtio-gpu/QEMU-KVM-specific; `softgpu` remains
   the UEFI-generic fallback for bare-metal/other-hypervisor systems. Confirm this
   matches intent before Stage 1 starts.
7. **Win7 floor interaction with risk 2** — verify the chosen DDI/WDDM-level constant
   doesn't assume a WDDM level incompatible with the project's Windows 7 software floor.

## Critical files for implementation

- `win32ss/drivers/miniport/virtgpu/virtgpu.h`
- `win32ss/drivers/miniport/virtgpu/virtgpu.c`
- `drivers/directx/rpi5vc4/rpi5vc4.c`
- `drivers/directx/rpi5vc4/rpi5vc4_wddm.c`
- `sdk/lib/drivers/softgpu/softgpu.h`
- `sdk/lib/drivers/softgpu/softgpu.c`
- `drivers/directx/softgpu/platform_root.c`
- `sdk/lib/drivers/virtio/VirtIO.h`
- `drivers/directx/wddm_cleanroom_gate.h`
