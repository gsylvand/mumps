cmake_minimum_required(VERSION 3.20...3.24)
# at least 3.24 to suppress CMP0135 warning

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "please use out of source build
    cmake -Bbuild")
endif()

project(MumpsPrereqs LANGUAGES C Fortran)

include(ExternalProject)

get_filename_component(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX} ABSOLUTE)

file(MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX})
message(STATUS "Installing MUMPS prerequisites to ${CMAKE_INSTALL_PREFIX}")

option(BUILD_SINGLE "Build single precision real" ON)
option(BUILD_DOUBLE "Build double precision real" ON)
option(BUILD_COMPLEX "Build single precision complex")
option(BUILD_COMPLEX16 "Build double precision complex")
option(MUMPS_intsize64 "use 64-bit integers in C and Fortran--Scotch must be consistent with MUMPS")

set_property(DIRECTORY PROPERTY EP_UPDATE_DISCONNECTED true)

file(READ ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/libraries.json json)

# default args
set(cmake_args
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=Release
)

# Scalapack
set(scalapack_cmake_args ${cmake_args}
-DBUILD_SINGLE:BOOL=${BUILD_SINGLE}
-DBUILD_DOUBLE:BOOL=${BUILD_DOUBLE}
-DBUILD_COMPLEX:BOOL=${BUILD_COMPLEX}
-DBUILD_COMPLEX16:BOOL=${BUILD_COMPLEX16}
-DSCALAPACK_BUILD_TESTING:BOOL=false
)

string(JSON scalapack_url GET ${json} scalapack git)
string(JSON scalapack_tag GET ${json} scalapack tag)

ExternalProject_Add(scalapack
GIT_REPOSITORY ${scalapack_url}
GIT_TAG ${scalapack_tag}
GIT_SHALLOW true
CMAKE_ARGS ${scalapack_cmake_args}
CONFIGURE_HANDLED_BY_BUILD true
)

# METIS

set(metis_cmake_args ${cmake_args}
-Dintsize=$<IF:$<BOOL:${MUMPS_intsize64}>,64,32>
-DBUILD_TESTING:BOOL=false
)

string(JSON metis_url GET ${json} metis git)
string(JSON metis_tag GET ${json} metis tag)

ExternalProject_Add(metis
GIT_REPOSITORY ${metis_url}
GIT_TAG ${metis_tag}
GIT_SHALLOW true
CMAKE_ARGS ${metis_cmake_args}
CONFIGURE_HANDLED_BY_BUILD true
)

# Scotch

function(bison_homebrew)

find_program(brew NAMES brew)
if(NOT brew)
  return()
endif()

execute_process(COMMAND ${brew} --prefix
RESULT_VARIABLE ret
OUTPUT_VARIABLE out OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(NOT ret EQUAL 0)
  return()
endif()

find_program(bison NAMES bison HINTS ${out} PATH_SUFFIXES opt/bison/bin)
if(NOT bison)
  return()
endif()

message(STATUS "Bison found: ${bison}")
cmake_path(GET bison PARENT_PATH bison_root)

set(BISON_ROOT ${bison_root} PARENT_SCOPE)

endfunction()

bison_homebrew()

# https://gitlab.inria.fr/scotch/scotch/-/blob/master/CMakeLists.txt
set(scotch_cmake_args ${cmake_args}
-DBUILD_TESTING:BOOL=false
-DINSTALL_METIS_HEADERS:BOOL=false
-DBUILD_LIBSCOTCHMETIS:BOOL=false
-DBUILD_LIBESMUMPS:BOOL=true
-DINTSIZE=$<IF:$<BOOL:${MUMPS_intsize64}>,64,32>
)
#https://gitlab.inria.fr/scotch/scotch/-/blob/master/src/CMakeLists.txt#L84

if(BISON_ROOT)
  list(APPEND scotch_cmake_args -DCMAKE_PREFIX_PATH:PATH=${BISON_ROOT})
endif()

string(JSON scotch_url GET ${json} scotch git)
string(JSON scotch_tag GET ${json} scotch tag)

ExternalProject_Add(scotch
GIT_REPOSITORY ${scotch_url}
GIT_TAG ${scotch_tag}
GIT_SHALLOW true
CMAKE_ARGS ${scotch_cmake_args}
CONFIGURE_HANDLED_BY_BUILD true
)

file(GENERATE OUTPUT .gitignore CONTENT "*")
