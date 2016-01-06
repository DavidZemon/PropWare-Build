set(CMAKE_MAJOR_VERSION 3)
set(CMAKE_MINOR_VERSION 4)
set(CMAKE_PATCH_VERSION 1)
set(CUSTOM_LINUX_CMAKE_INSTALL_DIR pwcmake)
set(CUSTOM_WIN32_CMAKE_INSTALL_DIR PWCMake)
set(CUSTOM_OSX_CMAKE_INSTALL_DIR   OSXCMake)
ExternalProject_Add(CMake
    PREFIX CMake-src
    URL http://www.cmake.org/files/v${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}/cmake-${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}-Linux-x86_64.tar.gz
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo_append
    BUILD_COMMAND ${CMAKE_COMMAND} -E echo_append
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${CMAKE_BINARY_DIR}/${CUSTOM_LINUX_CMAKE_INSTALL_DIR})
ExternalProject_Add(WinCMake
    PREFIX WinCMake-src
    URL http://www.cmake.org/files/v${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}/cmake-${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}-win32-x86.zip
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo_append
    BUILD_COMMAND ${CMAKE_COMMAND} -E echo_append
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${CMAKE_BINARY_DIR}/${CUSTOM_WIN32_CMAKE_INSTALL_DIR})
ExternalProject_Add(OSXCMake
    PREFIX OSXCMake-src
    URL http://www.cmake.org/files/v${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}/cmake-${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}-Darwin-x86_64.tar.gz
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo_append
    BUILD_COMMAND ${CMAKE_COMMAND} -E echo_append
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${CMAKE_BINARY_DIR}/${CUSTOM_OSX_CMAKE_INSTALL_DIR})
