
spec2def(ucrtbase.dll ucrtbase.spec NO_DBG ADD_IMPORTLIB)

# Hack to replace the old CRT include directory with the UCRT include directory
get_property(INCLUDE_DIRS DIRECTORY . PROPERTY INCLUDE_DIRECTORIES)
list(REMOVE_ITEM INCLUDE_DIRS "${LIBRENT_SOURCE_DIR}/sdk/include/crt")
set_property(DIRECTORY . PROPERTY INCLUDE_DIRECTORIES ${INCLUDE_DIRS})
include_directories(${LIBRENT_SOURCE_DIR}/sdk/include/ucrt)

add_compile_definitions(
    _UCRT
    _CORECRT_BUILD
    CRTDLL
)

add_library(ucrtbase SHARED
    printf.c
    stubs.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/acosh.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/acoshf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/asinh.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/asinhf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/atanh.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/atanhf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/cbrt.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/cbrtf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/copysign.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/copysignf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/fdim.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/fmax.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/fmin.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/erf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/erff.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/expm1.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/expm1f.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/log1p.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/log1pf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/nearbyint.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/nearbyintf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/remainder.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/remainderf.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/rint.c
    ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/math/rintf.c
    ucrtbase_stubs.c
    ucrtbase.def
    ucrtbase.rc
)

if(NOT ARCH STREQUAL "amd64" AND NOT ARCH STREQUAL "i386")
    target_sources(ucrtbase PRIVATE fma3_unavailable.c)
endif()

if(ARCH STREQUAL "arm64" AND ARM64EC_RUNTIME)
    target_sources(ucrtbase PRIVATE arm64ec_memory.c)
    set_source_files_properties(arm64ec_memory.c PROPERTIES COMPILE_OPTIONS "-fno-builtin")
elseif(ARCH STREQUAL "arm64")
    set_target_properties(ucrtbase PROPERTIES LIBRENT_LSE_ATOMICS lse_atomics_um)
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_compile_options(ucrtbase PRIVATE -Wno-builtin-declaration-mismatch)
endif()

set_entrypoint(ucrtbase __acrt_DllMain 12)

target_link_libraries(ucrtbase
    ucrt
    msvcrt_undname_ucrt
    msvcrt_shared
    crtmath
    vcruntime
    vcstartup
    chkstk
    wine
)

# Implicitly link executable consumers to vcstartup. DLLs provide their own
# entry points and must not receive the executable startup objects.
target_link_libraries(libucrtbase INTERFACE
    $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:vcstartup>)

if(MSVC)
    target_link_libraries(ucrtbase runtmchk)
else()
    # For __cxa_guard_acquire / __cxa_guard_release
    target_link_libraries(ucrtbase libsupc++)
endif()

add_importlibs(ucrtbase kernel32 ntdll)

add_cd_file(TARGET ucrtbase DESTINATION librent/system32 FOR all)
