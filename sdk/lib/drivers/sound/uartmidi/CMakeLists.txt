
include_directories(
    ${LIBRENT_SOURCE_DIR}/sdk/lib/drivers/sound/soundblaster
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/sound)

add_library(uartmidi midiuart.c)
add_dependencies(uartmidi bugcodes xdk)
