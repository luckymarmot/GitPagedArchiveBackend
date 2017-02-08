PROJECT(LIBGIT2-archive C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

SET(CMAKE_SKIP_BUILD_RPATH  TRUE)

INCLUDE(../CMAKE/Findlibgit2.cmake)

# Build options
OPTION (BUILD_SHARED_LIBS "Build Shared Library (OFF for Static)" ON)
OPTION (BUILD_TESTS "Build Tests" ON)

# Build Release by default
IF (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
ENDIF ()

# Compile and link LIBGIT2
INCLUDE_DIRECTORIES(${LIBGIT2_INCLUDE_DIRS} ArchiveLib/archive)
add_subdirectory(ArchiveLib/archive)
add_executable(git2-archive gitbackend.c)
TARGET_LINK_LIBRARIES(git2-archive ${LIBGIT2_LIBRARIES} Archive)
