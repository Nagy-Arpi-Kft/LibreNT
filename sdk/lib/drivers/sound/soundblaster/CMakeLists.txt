
include_directories(BEFORE ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/sound)

list(APPEND SOURCE
    dsp_io.c
    version.c
    speaker.c
    rate.c
    mixer.c)

add_library(soundblaster ${SOURCE})
add_pch(soundblaster precomp.h)
add_dependencies(soundblaster bugcodes xdk)
