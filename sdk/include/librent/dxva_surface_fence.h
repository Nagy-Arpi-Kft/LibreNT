/*
 * PROJECT:     LibreNT DirectX video support
 * LICENSE:     GPL-3.0-or-later (https://spdx.org/licenses/GPL-3.0-or-later)
 * PURPOSE:     Private D3D9 surface contract for asynchronous DXVA output
 * COPYRIGHT:   Copyright 2026 Ahmed Arif <arif193@gmail.com>
 */

#pragma once

#include <windef.h>
#include <unknwn.h>

#define LIBRENT_DXVA_SURFACE_FENCE_GUID_INIT \
    {0x0f57f428, 0x6532, 0x4f35, {0xa6, 0x8d, 0x51, 0xd0, 0x97, 0xec, 0x43, 0x6f}}

#define LIBRENT_DXVA_SURFACE_FENCE_DONOTWAIT 0x00000001u

#define LIBRENT_DXVA_SURFACE_PRESENT_LIMITED_RGB 0x00000001u
#define LIBRENT_DXVA_SURFACE_PRESENT_BT709       0x00000002u
#define LIBRENT_DXVA_SURFACE_PRESENT_ALLOWED \
    (LIBRENT_DXVA_SURFACE_PRESENT_LIMITED_RGB | \
     LIBRENT_DXVA_SURFACE_PRESENT_BT709)

#define LIBRENT_DXVA_SURFACE_MAX_PLANES 3u

#define LIBRENT_DXVA_SURFACE_MEMORY_DEFERRED_UPLOAD 0x00000001u

typedef struct LIBRENT_DXVA_SURFACE_MEMORY
{
    void *Data;
    SIZE_T Size;
    UINT Width;
    UINT Height;
    UINT Pitch;
    UINT StorageHeight;
    UINT PlaneCount;
    UINT PlaneOffsets[LIBRENT_DXVA_SURFACE_MAX_PLANES];
    UINT PlanePitches[LIBRENT_DXVA_SURFACE_MAX_PLANES];
    ULONG Generation;
    DWORD Flags;
} LIBRENT_DXVA_SURFACE_MEMORY;

typedef struct ILibreNTDxvaSurfaceFence ILibreNTDxvaSurfaceFence;

typedef struct ILibreNTDxvaSurfaceFenceVtbl
{
    HRESULT (WINAPI *QueryInterface)(ILibreNTDxvaSurfaceFence *iface,
                                     REFIID iid,
                                     void **object);
    ULONG (WINAPI *AddRef)(ILibreNTDxvaSurfaceFence *iface);
    ULONG (WINAPI *Release)(ILibreNTDxvaSurfaceFence *iface);
    HRESULT (WINAPI *GetPresentationFlags)(ILibreNTDxvaSurfaceFence *iface,
                                           DWORD *flags);
    HRESULT (WINAPI *Wait)(ILibreNTDxvaSurfaceFence *iface, DWORD flags);
    HRESULT (WINAPI *GetSharedMemory)(ILibreNTDxvaSurfaceFence *iface,
                                     DWORD flags,
                                     LIBRENT_DXVA_SURFACE_MEMORY *memory);
    HRESULT (WINAPI *PrepareFallback)(ILibreNTDxvaSurfaceFence *iface,
                                      DWORD flags);
    HRESULT (WINAPI *MarkConsumed)(ILibreNTDxvaSurfaceFence *iface,
                                   DWORD flags);
    HRESULT (WINAPI *Present)(ILibreNTDxvaSurfaceFence *iface,
                              const RECT *source,
                              const RECT *destination,
                              DWORD flags);
    HRESULT (WINAPI *Hide)(ILibreNTDxvaSurfaceFence *iface);
} ILibreNTDxvaSurfaceFenceVtbl;

struct ILibreNTDxvaSurfaceFence
{
    const ILibreNTDxvaSurfaceFenceVtbl *lpVtbl;
};

#define ILibreNTDxvaSurfaceFence_AddRef(iface) \
    ((iface)->lpVtbl->AddRef((iface)))
#define ILibreNTDxvaSurfaceFence_Release(iface) \
    ((iface)->lpVtbl->Release((iface)))
#define ILibreNTDxvaSurfaceFence_GetPresentationFlags(iface, flags) \
    ((iface)->lpVtbl->GetPresentationFlags((iface), (flags)))
#define ILibreNTDxvaSurfaceFence_Wait(iface, flags) \
    ((iface)->lpVtbl->Wait((iface), (flags)))
#define ILibreNTDxvaSurfaceFence_GetSharedMemory(iface, flags, memory) \
    ((iface)->lpVtbl->GetSharedMemory((iface), (flags), (memory)))
#define ILibreNTDxvaSurfaceFence_PrepareFallback(iface, flags) \
    ((iface)->lpVtbl->PrepareFallback((iface), (flags)))
#define ILibreNTDxvaSurfaceFence_MarkConsumed(iface, flags) \
    ((iface)->lpVtbl->MarkConsumed((iface), (flags)))
#define ILibreNTDxvaSurfaceFence_Present(iface, source, destination, flags) \
    ((iface)->lpVtbl->Present((iface), (source), (destination), (flags)))
#define ILibreNTDxvaSurfaceFence_Hide(iface) \
    ((iface)->lpVtbl->Hide((iface)))
