cmake_minimum_required(VERSION 3.15)
project(ccpp-nuopc LANGUAGES Fortran)

# Add cmake directory to module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Find ESMF
find_package(ESMF REQUIRED)

# Find OpenMP
find_package(OpenMP REQUIRED)

# Check if CDEPS is already available (e.g. via Spack)
find_package(cdeps QUIET)

if(NOT cdeps_FOUND)
    # Fallback to FetchContent if not found in the environment
    include(FetchContent)
    FetchContent_Declare(
        cdeps
        GIT_REPOSITORY https://github.com/NOAA-EMC/CDEPS
        GIT_TAG        cdeps0.4.17
        GIT_SUBMODULES_RECURSIVE ON
        # Prevents attempts to update the repository if it's already there
        UPDATE_DISCONNECTED ON
    )

    # Use ESMFMKFILE to find PIO if available in the environment
        if(DEFINED ENV{ESMFMKFILE} AND NOT PIO_PATH)
            execute_process(COMMAND grep "^[ \t]*ESMF_PIO_INCLUDE[ \t]*=" $ENV{ESMFMKFILE}
                            COMMAND cut -d= -f2
                            OUTPUT_VARIABLE PIO_INC_DIR
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            if(PIO_INC_DIR)
                # Remove leading whitespace and possible -I prefix
                string(REGEX REPLACE "^[ \t\-I]+" "" PIO_INC_DIR "${PIO_INC_DIR}")
                string(STRIP "${PIO_INC_DIR}" PIO_INC_DIR)
                # Use only the first line if multiple matches found
                string(REGEX REPLACE "\n.*$" "" PIO_INC_DIR "${PIO_INC_DIR}")

                if(EXISTS "${PIO_INC_DIR}")
                    get_filename_component(PIO_ROOT "${PIO_INC_DIR}" DIRECTORY)
                    set(PIO_PATH "${PIO_ROOT}" CACHE PATH "PIO installation path" FORCE)
                    message(STATUS "Derived PIO_PATH from ESMFMKFILE: ${PIO_PATH}")
                endif()
            endif()
        endif()

    FetchContent_MakeAvailable(cdeps)

    # Ensure FindPIO.cmake from CDEPS is available
    list(APPEND CMAKE_MODULE_PATH "${cdeps_SOURCE_DIR}/cmake")
endif()

# Add internal state library
add_library(ccpp_internal_state src/ccpp_internal_state.F90)
target_link_libraries(ccpp_internal_state PUBLIC ESMF::ESMF)
target_include_directories(ccpp_internal_state PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

# Add NUOPC cap library
add_library(ccpp_nuopc_cap src/ccpp_nuopc_cap.F90 src/ccpp_inline_cdeps_mod.F90)
target_link_libraries(ccpp_nuopc_cap PUBLIC ccpp_internal_state ESMF::ESMF cdeps OpenMP::OpenMP_Fortran)

# Prepare for CCPP submodules
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/ccpp-framework/CMakeLists.txt")
    add_subdirectory(src/ccpp-framework)
    target_link_libraries(ccpp_nuopc_cap PUBLIC ccpp_framework)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/ccpp-physics/CMakeLists.txt")
    add_subdirectory(src/ccpp-physics)
    target_link_libraries(ccpp_nuopc_cap PUBLIC ccpp_physics)
endif()
