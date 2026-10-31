
add_definitions(-DSDBWRITE_HOSTTOOL=1)

list(APPEND SOURCE
    main.cpp
    tinyxml2.cpp
    xml2sdb.cpp
    xml2sdb.h
    ${LIBRENT_SOURCE_DIR}/dll/appcompat/apphelp/sdbwrite.c
    ${LIBRENT_SOURCE_DIR}/dll/appcompat/apphelp/sdbstringtable.c)

include_directories(
    ${LIBRENT_SOURCE_DIR}/dll/appcompat/apphelp
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/appcompat)
add_host_tool(xml2sdb ${SOURCE})
target_link_libraries(xml2sdb PRIVATE host_includes)

if(MSVC)
    # Disable warning "'=': conversion from 'a' to 'b', possible loss of data"
    target_compile_options(xml2sdb PRIVATE "/wd4244")
else()
    target_compile_options(xml2sdb PRIVATE "-fshort-wchar")
endif()
