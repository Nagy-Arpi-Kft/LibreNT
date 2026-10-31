/*
 * PROJECT:     LibreNT Printing Include files
 * LICENSE:     GPL-2.0+ (https://spdx.org/licenses/GPL-2.0+)
 * PURPOSE:     Provide a constant for the current Printing Processor Environment based on the architecture
 * COPYRIGHT:   Copyright 2016 Colin Finck (colin@reactos.org)
 */

#ifndef _LIBRENT_PRTPROCENV_H
#define _LIBRENT_PRTPROCENV_H

const WCHAR wszCurrentEnvironment[] =
#if defined(_X86_)
    L"Windows NT x86";
#elif defined(_AMD64_)
    L"Windows x64";
#elif defined(_ARM_)
    L"Windows ARM";
#elif defined(_M_ARM64) || defined(__aarch64__)
    L"Windows ARM64";
#elif defined(_M_RISCV64) || (defined(__riscv) && (__riscv_xlen == 64))
    L"LibreNT RISC-V64";
#elif defined(_M_PPC)
    L"Windows NT PowerPC";
#else
    #error Unsupported architecture
#endif

const DWORD cbCurrentEnvironment = sizeof(wszCurrentEnvironment);

#endif
