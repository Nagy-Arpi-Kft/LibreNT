##
## PROJECT:     LibreNT Boot Loader
## LICENSE:     GPL-3.0-or-later (https://spdx.org/licenses/GPL-3.0-or-later)
## PURPOSE:     Build definitions
## COPYRIGHT:   Copyright 2026 Ahmed ARIF <arif.ing@outlook.com>
##

if(ARCH STREQUAL "i386" AND (SARCH STREQUAL "pc98" OR SARCH STREQUAL "xbox"))
    return()
endif()

include_directories(BEFORE include)
include_directories(
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/include
    ${LIBRENT_SOURCE_DIR}/sdk/lib/cmlib
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/edk2)

add_definitions(-D_NTHAL_ -D_BLDR_ -D_NTSYSTEM_ -DNTDDI_VERSION=${LIBRENT_TARGET_NTDDI})

function(bootloader_efi_application _target _entry)
    set_target_properties(${_target} PROPERTIES SUFFIX ".efi")

    if(NOT MSVC)
        target_link_options(${_target} PRIVATE -Wl,--exclude-all-symbols,--file-alignment,0x200,--section-alignment,0x1000)
    endif()

    if(MSVC)
        set_subsystem(${_target} EFI_APPLICATION)
    elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
        target_link_options(${_target} PRIVATE -Wl,/driver)
        if(ARCH STREQUAL "arm64")
            target_link_options(${_target} PRIVATE
                -Wl,--subsystem,efi_application:6.00
                -Wl,--major-os-version,6
                -Wl,--minor-os-version,0
                -Wl,--major-subsystem-version,6
                -Wl,--minor-subsystem-version,0)
        else()
            set_subsystem(${_target} efi_application)
        endif()
    else()
        set_subsystem(${_target} 10)
    endif()

    set_entrypoint(${_target} ${_entry})
    target_link_libraries(${_target} bootlib blcmlib blrtl libcntpr)
    if(RUNTIME_CHECKS)
        target_link_libraries(${_target} runtmchk)
    endif()
    if(ARCH STREQUAL "i386")
        target_link_libraries(${_target} mini_hal)
    endif()
    if(ARCH STREQUAL "arm64")
        set_target_properties(${_target} PROPERTIES LIBRENT_LSE_ATOMICS lse_atomics_boot)
        if(MSVC)
            add_asm_files(${_target}_chkstk_asm ${LIBRENT_SOURCE_DIR}/bootloader/arch/arm64/chkstk.S)
            target_sources(${_target} PRIVATE ${${_target}_chkstk_asm})
        endif()
    endif()
    add_dependencies(${_target} xdk)
endfunction()

list(APPEND BOOTLIB_SOURCE
    lib/bcd.c
    lib/disk.c
    lib/entries.c
    lib/exfat.c
    lib/fs.c
    lib/gpt.c
    lib/libsupp.c
    lib/ntfs.c)

list(APPEND BOOTLIB_SOURCE
    uefi/platform.c
    uefi/serial.c
    uefi/uefi.c)
list(APPEND BOOTGUI_FIRMWARE_SOURCE
    uefi/console.c
    uefi/uefiinput.c
    uefi/uefireboot.c)

if(ARCH STREQUAL "arm64")
    list(APPEND BOOTLIB_SOURCE arch/arm64/stubs.c)
endif()

add_library(bootlib ${BOOTLIB_SOURCE})
target_link_libraries(bootlib fatfs)
add_dependencies(bootlib bugcodes asm xdk)

foreach(_asset font mono icons logo)
    if(_asset STREQUAL "font")
        set(_asset_source ${LIBRENT_SOURCE_DIR}/media/fonts/selawk.ttf)
    elseif(_asset STREQUAL "mono")
        set(_asset_source ${LIBRENT_SOURCE_DIR}/media/fonts/lucon.ttf)
    elseif(_asset STREQUAL "icons")
        set(_asset_source ${CMAKE_CURRENT_SOURCE_DIR}/gui/assets/icons.alpha)
    else()
        set(_asset_source ${CMAKE_CURRENT_SOURCE_DIR}/gui/assets/logo.rgba)
    endif()
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/bootui_${_asset}.c ${CMAKE_CURRENT_BINARY_DIR}/bootui_${_asset}.h
        COMMAND native-bin2c ${_asset_source}
                ${CMAKE_CURRENT_BINARY_DIR}/bootui_${_asset}.c
                ${CMAKE_CURRENT_BINARY_DIR}/bootui_${_asset}.h BIN bootui_${_asset}
        DEPENDS native-bin2c ${_asset_source})
    list(APPEND BOOTGUI_SOURCE ${CMAKE_CURRENT_BINARY_DIR}/bootui_${_asset}.c)
endforeach()

if(ARCH STREQUAL "arm64")
    list(APPEND BOOTGUI_SOURCE arch/arm64/unwind.c)
endif()

add_library(bootgui
    ${BOOTGUI_SOURCE}
    ${BOOTGUI_FIRMWARE_SOURCE}
    gui/bmui.c
    gui/bootui.c
    gui/ftglue.c
    gui/guisupp.c)
target_include_directories(bootgui PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(bootgui setjmp freetype)
add_dependencies(bootgui bugcodes asm xdk)

add_library(bootwim
    ${LIBRENT_SOURCE_DIR}/sdk/lib/libwim/lzx.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/libwim/sha1.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/libwim/wimcore.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/libwim/xpress_huff.c)
set_property(TARGET bootwim PROPERTY C_STANDARD 11)
target_include_directories(bootwim PRIVATE ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/libwim)
target_compile_definitions(bootwim PRIVATE XPRESS_HUFF_DECOMPRESS_ONLY=1)
add_dependencies(bootwim xdk)

add_executable(bootmgfw
    bootmgr/app.c
    bootmgr/logo.c
    bootmgr/main.c
    bootmgr/startup.c)
bootloader_efi_application(bootmgfw EfiEntry)
target_link_libraries(bootmgfw bootgui bootwim)
if(MSVC)
    set_property(TARGET bootmgfw PROPERTY C_STANDARD 11)
endif()

add_custom_target(bootloader DEPENDS bootmgfw)

if(ARCH STREQUAL "arm64")
    list(APPEND WINLOAD_ASM_SOURCE
        arch/arm64/cache_v2.S
        arch/arm64/entry.S
        arch/arm64/except.S
        arch/arm64/kernel_jump.S
        arch/arm64/misc.S
        arch/arm64/uefiasm.S
        arch/arm64/uefitrap.S)

    list(APPEND WINLOAD_SOURCE
        arch/arm64/archmm.c
        arch/arm64/early_uart.c
        arch/arm64/gic.c
        arch/arm64/macharm64.c
        arch/arm64/mmu_v2.c
        arch/arm64/timer.c
        arch/arm64/trap.c
        arch/arm64/uefitrap.c
        arch/arm64/winldr.c)
elseif(ARCH STREQUAL "amd64")
    list(APPEND WINLOAD_ASM_SOURCE
        arch/amd64/resume.S
        arch/amd64/uefiasm.S)

    list(APPEND WINLOAD_SOURCE
        arch/amd64/archosl.c)
elseif(ARCH STREQUAL "i386")
    list(APPEND WINLOAD_ASM_SOURCE
        arch/i386/resume.S
        arch/i386/uefiasm.S)

    list(APPEND WINLOAD_SOURCE
        arch/i386/archosl.c)
endif()

list(APPEND WINLOAD_SOURCE
    net/uefidhcp.c
    net/uefihttp.c
    net/uefinet.c
    net/uefinet_hw.c
    net/snpnet.c
    uefi/memory.c)

if(WINLOAD_ASM_SOURCE)
    add_asm_files(winload_asm ${WINLOAD_ASM_SOURCE})

    add_executable(winload
        ${winload_asm}
        ${WINLOAD_SOURCE}
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmboot.c
        lib/mm.c
        lib/pe.c
        winload/hw.c
        winload/lpb.c
        winload/main.c
        winload/memory.c
        ramdisk/fatformat.c
        ramdisk/fatwrite.c
        ramdisk/wim.c
        winload/options.c
        winload/ramdisk.c
        winload/registry.c
        winload/resume.c
        winload/smbios.c
        winload/startup.c)
    bootloader_efi_application(winload EfiEntry)
    target_link_libraries(winload bootwim)
    if(MSVC)
        set_property(TARGET winload PROPERTY C_STANDARD 11)
    endif()
    add_dependencies(bootloader winload)
    add_cd_file(TARGET winload DESTINATION librent/system32 FOR all)
endif()

add_subdirectory(image)
