#ifndef COMPAT_UNDOC_H
#define COMPAT_UNDOC_H


typedef struct _LibreNT_ShimData
{
    DWORD dwReserved1[130];
    DWORD dwSize;
    DWORD dwMagic;
    DWORD dwReserved2[242];
    DWORD dwRosProcessCompatVersion;

#ifdef _M_AMD64
    PVOID RtlGetCurrentDirectory_U_RtlpMsysDecoy;
#endif
} LibreNT_ShimData;


#define LIBRENT_SHIMDATA_MAGIC  0xAC0DEDAB
#define LIBRENT_COMPATVERSION_UNINITIALIZED 0xfffffffe
#define LIBRENT_COMPATVERSION_IGNOREMANIFEST 0xffffffff

// Returns values in the form of _WIN32_WINNT_VISTA, _WIN32_WINNT_WIN7 etc
static
inline
DWORD RosGetProcessCompatVersion(VOID)
{
    static DWORD g_CompatVersion = LIBRENT_COMPATVERSION_UNINITIALIZED;
    if (g_CompatVersion == LIBRENT_COMPATVERSION_UNINITIALIZED)
    {
        LibreNT_ShimData* pShimData = (LibreNT_ShimData*)NtCurrentPeb()->pShimData;
        if (pShimData && pShimData->dwMagic == LIBRENT_SHIMDATA_MAGIC &&
            pShimData->dwSize == sizeof(LibreNT_ShimData))
        {
            g_CompatVersion = pShimData->dwRosProcessCompatVersion;
        }
    }
    return g_CompatVersion < LIBRENT_COMPATVERSION_UNINITIALIZED ? g_CompatVersion : 0;
}

static
inline
UINT RosGetProcessEffectiveVersion(VOID)
{
    PPEB peb = NtCurrentPeb();
    UINT shimVer = RosGetProcessCompatVersion();
    if (shimVer)
        return shimVer;
    else
        return (peb->OSMajorVersion << 8) | (peb->OSMinorVersion);
}

BOOL
WINAPI
BaseCheckAppcompatCache(
    _In_ PCWSTR ApplicationName,
    _In_ HANDLE FileHandle,
    _In_opt_ PCWSTR Environment,
    _Out_opt_ PULONG pdwReason);

#endif // COMPAT_UNDOC_H
