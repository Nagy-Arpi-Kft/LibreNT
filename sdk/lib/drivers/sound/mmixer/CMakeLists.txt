
add_definitions(
    -DUNICODE -D_UNICODE)

remove_definitions(-D_WIN32_WINNT=${LIBRENT_TARGET_NT})
add_definitions(-D_WIN32_WINNT=0x600)

if(DBG)
    add_compile_definitions(NDEBUG)
endif()

include_directories(${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/sound)

list(APPEND SOURCE
    controls.c
    filter.c
    midi.c
    mixer.c
    sup.c
    wave.c
    topology.c
    rtstreaming.c
    precomp.h)

add_library(mmixer ${SOURCE})
add_pch(mmixer precomp.h SOURCE)
add_dependencies(mmixer bugcodes xdk)
