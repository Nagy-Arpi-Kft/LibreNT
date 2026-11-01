add_definitions(-D__WINESRC__)

spec2def(winegstreamer.dll winegstreamer.spec ADD_IMPORTLIB)

list(APPEND SOURCE
    librent/main.c
    librent/legacy/avisplit.c
    librent/legacy/enummedia.c
    librent/legacy/memallocator.c
    librent/legacy/mpegsplit.c
    librent/legacy/parser.c
    librent/legacy/pin.c
    librent/legacy/waveparser.c
    librent/legacy/strmbase/enumpins.c
    librent/legacy/strmbase/filter.c
    librent/legacy/strmbase/mediatype.c
    librent/legacy/strmbase/pin.c
    librent/legacy/strmbase/seeking.c)

add_library(winegstreamer MODULE
    ${SOURCE}
    librent/rsrc.rc
    version.rc
    ${CMAKE_CURRENT_BINARY_DIR}/winegstreamer.def)

target_include_directories(winegstreamer BEFORE PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/librent/legacy)
set_source_files_properties(librent/rsrc.rc PROPERTIES OBJECT_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/winegstreamer.rgs;${CMAKE_CURRENT_SOURCE_DIR}/librent/winegstreamer.rgs")
set_module_type(winegstreamer win32dll)
target_link_libraries(winegstreamer strmiids dxguid uuid wine wine_dll_register ${PSEH_LIB})
add_importlibs(winegstreamer advapi32 msvfw32 ole32 oleaut32 user32 winmm msvcrt kernel32 ntdll)
add_dependencies(winegstreamer dxsdk)
add_cd_file(TARGET winegstreamer DESTINATION librent/system32 FOR all)
set_wine_module_FIXME(winegstreamer)
