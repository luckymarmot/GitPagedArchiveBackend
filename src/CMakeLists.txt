PROJECT(LIBGIT2-archive C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

INCLUDE(../CMAKE/Findlibgit2.cmake)



# Compile and link LIBGIT2
INCLUDE_DIRECTORIES(${LIBGIT2_INCLUDE_DIRS} ./ArchiveLib/archive)
add_subdirectory(ArchiveLib/archive)
add_executable(git2-archive gitbackend.c)
target_link_libraries(git2-archive ${LIBGIT2_LIBRARIES} Archive)
