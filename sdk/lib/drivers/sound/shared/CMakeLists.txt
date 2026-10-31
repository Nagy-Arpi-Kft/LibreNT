
include_directories(
    ${LIBRENT_SOURCE_DIR}/sdk/lib/drivers/sound/soundblaster
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/sound)

add_library(audio time.c)
add_dependencies(audio bugcodes xdk)
