
spec2def(ksecdd.sys ksecdd.spec ADD_IMPORTLIB)

include_directories(
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/drivers/ksecdd
    ${LIBRENT_SOURCE_DIR}/sdk/lib/cryptlib
    ${LIBRENT_SOURCE_DIR}/sdk/lib/3rdparty/symcrypt/lib)

list(APPEND SOURCE
    ksecdd.c
    dispatch.c
    crypt.c
    bcrypt.c
    random.c
    sid.c
    stubs.c
    ksecdd.rc
    ${CMAKE_CURRENT_BINARY_DIR}/ksecdd.def)

add_library(ksecdd MODULE ${SOURCE})
target_compile_definitions(ksecdd PRIVATE
    __WINE_PE_BUILD
    SYMCRYPT_PLATFORM_WINE=1)
target_link_libraries(ksecdd cryptlib pseh symcrypt_km)
set_module_type(ksecdd kernelmodedriver)
add_importlibs(ksecdd ntoskrnl hal)
add_cd_file(TARGET ksecdd DESTINATION librent/system32/drivers NO_CAB FOR all)
add_registry_inf(ksecdd_reg.inf)
