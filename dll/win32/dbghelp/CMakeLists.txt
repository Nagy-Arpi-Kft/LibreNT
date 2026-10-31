
if(CMAKE_CROSSCOMPILING)
    add_definitions(
        -D_WINE
        -D__WINESRC__
        -DHAVE_ALLOCA_H
        -D_IMAGEHLP_SOURCE_)

    include_directories(
        BEFORE ${LIBRENT_SOURCE_DIR}/sdk/include/wine
        ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/zlib)

    spec2def(dbghelp.dll dbghelp.spec ADD_IMPORTLIB)

    list(APPEND SOURCE
        coff.c
        cpu_arm.c
        cpu_arm64.c
        cpu_i386.c
        cpu_x86_64.c
        dbghelp.c
        dwarf.c
#       elf_module.c
        image.c
#       macho_module.c
        minidump.c
        module.c
        msc.c
        path.c
        pdb.c
        pe_module.c
        source.c
        stabs.c
        stack.c
        storage.c
        symbol.c
        type.c)

    add_library(dbghelp MODULE
        ${SOURCE}
        version.rc
        ${CMAKE_CURRENT_BINARY_DIR}/dbghelp_stubs.c
        ${CMAKE_CURRENT_BINARY_DIR}/dbghelp.def)

    set_module_type(dbghelp win32dll)
    target_link_libraries(dbghelp wine ${PSEH_LIB} oldnames zlib symz)
    add_delay_importlibs(dbghelp version)
    add_importlibs(dbghelp psapi msvcrt kernel32_vista kernel32 ntdll)
    add_cd_file(TARGET dbghelp DESTINATION librent/system32 FOR all)
    set_wine_module(dbghelp)

    if(MSVC)
        # Disable warning C4146: unary minus operator applied to unsigned type, result still unsigned
        # Disable warning C4477 (printf format warnings)
        target_compile_options(dbghelp PRIVATE /wd4146 /wd4477)
    endif()
endif()
