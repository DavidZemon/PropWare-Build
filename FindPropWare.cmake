#.rst:
# FindPropWare
# ------------
#
# Find PropWare
#
# This module finds the required libraries and headers for the PropWare, Simple and libpropeller
# HALs for the Parallax Propeller. Configuration files that aid in Parallax Propeller development
# (including a toolchain file) will also be loaded.
#
# This module sets the following result variables:
#
# ::
#
#   PropWare_FOUND
#   PropWare_VERSION
#   PropWare_<Memory model>_LIBRARIES       A variable is created which includes libraries for all
#                                           of the HALs for a given memory model.
#                                           Ex: PropWare_LMM_LIBRARIES
#   PropWare_<HAL>_<Memory model>_LIBRARY   A variable is created for each HAL and for each memory
#                                           model. Ex: PropWare_PropWare_LMM_LIBRARY or
#                                           PropWare_librpropeller_XMMC_LIBRARY
#
# Example Usages:
#
# ::
#
#   find_package(PropWare REQUIRED)
#   project(Hello)
#   create_simple_executable(${PROJECT_NAME} main.c)
#
#==============================================================================
# The MIT License (MIT)
#
# Copyright (c) 2013 David Zemon
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#==============================================================================

set(CMAKE_CONFIGURATION_TYPES None
    CACHE STRING INTERNAL FORCE)

# Allow using `if (VAR IN_LIST MY_LIST)`. Requires CMake 3.3
cmake_policy(SET CMP0057 NEW)

if (NOT PropWare_FOUND)
    # Ensure that the PropWare CMake modules will be picked up by CMake
    set(pw_in_mod_path FALSE)
    foreach (d IN LISTS CMAKE_MODULE_PATH)
        if (EXISTS "${d}/PropellerToolchain.cmake")
            set(pw_in_mod_path TRUE)
        endif ()
    endforeach ()
    if (NOT pw_in_mod_path)
        get_filename_component(REAL_FILEPATH "${CMAKE_CURRENT_LIST_FILE}" REALPATH)
        get_filename_component(PW_CMAKE_MODULE_PATH "${REAL_FILEPATH}" DIRECTORY)
        list(APPEND CMAKE_MODULE_PATH "${PW_CMAKE_MODULE_PATH}")
    endif ()

    # Gotta set the Toolchain. Aint nothing working without that.
    find_file(CMAKE_TOOLCHAIN_FILE PropellerToolchain.cmake
        PATHS
            ${CMAKE_MODULE_PATH}
            "${CMAKE_ROOT}/Modules"
    )
    if (NOT CMAKE_TOOLCHAIN_FILE)
        message(FATAL_ERROR "Unable to find PropWare's CMake toolchain file.")
    endif ()

    ###############################
    # Compile options
    ###############################
    # General options
    option(32_BIT_DOUBLES "Set all doubles to 32-bits (-m32bit-doubles)" ON)
    option(WARN_ALL "Turn on all compiler warnings (-Wall)" ON)
    option(AUTO_C_STD "Set C standard to gnu99 (-std=gnu99)" ON)
    option(AUTO_CXX_STD "Set C++ standard to the latest available by the compiler" ON)
    option(SAVE_TEMPS "Save preprocessed (.i/.ii) source and generated assembly (.s) files." ON)

    # Size optimizations
    option(AUTO_OPTIMIZATION "Set optimization level to \"size\" (-Os)" ON)
    option(AUTO_CUT_SECTIONS "Cut out unused code (Compile: -ffunction-sections -fdata-sections; Link: --gc-sections)" ON)

    # Language features
    option(EXCEPTIONS "Enable exceptions (requires hundreds of kilobytes of RAM) (-fexceptions/-fno-exceptions" OFF)
    option(RUNTIME_TYPE_INFORMATION "Enable runtime type information (-frtti/-fno-rtti)" OFF)
    option(THREADSAFE_STATICS "Enable threadsafe statics (-fthreadsafe-statics/-fno-threadsafe-statics)" OFF)

    ###############################
    # Libraries to link
    ###############################

    if (PROPWARE_MAIN_PACKAGE)
        set(PROPWARE_PATH "${CMAKE_CURRENT_LIST_DIR}/..")
    elseif (NOT DEFINED PROPWARE_PATH OR NOT EXISTS "${PROPWARE_PATH}/lib/PropWare-targets.cmake")
        foreach (d IN LISTS CMAKE_MODULE_PATH)
            if (EXISTS "${d}/PropellerToolchain.cmake")
                list(APPEND pw_path_guesses "${d}/..")
            endif ()
        endforeach ()
        find_path(PROPWARE_PATH
            NAMES
                lib/PropWare-targets.cmake
            PATHS
                "$ENV{PROPWARE_PATH}" # Check the environment first
                "${pw_path_guesses}" # Or go with the installed version next to this file
        )
    endif ()

    if (NOT PROPWARE_MAIN_PACKAGE)
        set(NAMESPACE PropWare::)
        if (PROPWARE_PATH)
            include("${PROPWARE_PATH}/lib/PropWare-targets.cmake")
        endif ()
    endif ()

    if (PROPWARE_PATH)
        if (PropWare_FIND_COMPONENTS)
            # If we're using componentized search, only grab the requested libraries
            foreach (component IN LISTS PropWare_FIND_COMPONENTS)
                foreach (model cog cmm lmm xmmc xmm-split xmm-single)
                    set(target_name ${NAMESPACE}${component}_${model})
                    string(TOUPPER ${model} upper_model)
                    if (TARGET ${target_name})
                        set(PropWare_${component}_FOUND 1)
                        set(PropWare_${component}_${upper_model}_LIBRARY ${target_name})
                    else ()
                        set(PropWare_${component}_FOUND 0)
                        if (PropWare_FIND_REQUIRED_${component})
                            message(FATAL_ERROR "PropWare's ${component} component not available due to missing ${component}_${model}")
                        endif ()
                    endif ()
                endforeach ()
            endforeach ()
        else ()
            # If we're not using componentized search, grab them all
            foreach (component PropWare Libpropeller Simple LibPropelleruino)
                foreach (model cog cmm lmm xmmc xmm-split xmm-single)
                    set(target_name ${NAMESPACE}${component}_${model})
                    string(TOUPPER ${model} upper_model)
                    set(PropWare_${component}_${upper_model}_LIBRARY ${target_name})
                endforeach()
            endforeach()
        endif ()
    else ()
        message("PROPWARE_PATH is undefined or could not be found. The PropWare build system will be available but none of the PropWare-built libraries or header files will be available.")
    endif ()

    if (PROPWARE_PATH)
        find_program(CMAKE_MAKE_PROGRAM make
            PATHS "${PROPWARE_PATH}")
        find_file(PropWare_DAT_SYMBOL_CONVERTER CMakeDatSymbolConverter.cmake
            PATHS
                "${PROPWARE_PATH}/CMakeModules"
                "${CMAKE_ROOT}/Modules")
        find_file(PROPWARE_RUN_OBJCOPY CMakeRunObjcopy.cmake
            PATHS
                "${PROPWARE_PATH}/CMakeModules"
                "${CMAKE_ROOT}/Modules")
        find_file(ELF_SIZER CMakeElfSizer.cmake
            PATHS
                "${PROPWARE_PATH}/CMakeModules"
                "${CMAKE_ROOT}/Modules")

        get_filename_component(PROPGCC_BIN_DIR "${CMAKE_C_COMPILER}" DIRECTORY)
        find_program(SPIN2CPP_COMMAND spin2cpp
            "${PROPWARE_PATH}"
            "${PROPGCC_BIN_DIR}"
            "$ENV{PROPGCC_PREFIX}/bin")

        set(PropWare_LIBRARIES
            # Built-ins
            m

            # HALs
            ${PropWare_PropWare_CMM_LIBRARY}
            ${PropWare_PropWare_LMM_LIBRARY}
            ${PropWare_PropWare_XMMC_LIBRARY}
            ${PropWare_PropWare_XMM-SPLIT_LIBRARY}
            ${PropWare_PropWare_XMM-SINGLE_LIBRARY}
            ${PropWare_Libpropeller_COG_LIBRARY}
            ${PropWare_Libpropeller_CMM_LIBRARY}
            ${PropWare_Libpropeller_LMM_LIBRARY}
            ${PropWare_Libpropeller_XMMC_LIBRARY}
            ${PropWare_Libpropeller_XMM-SPLIT_LIBRARY}
            ${PropWare_Libpropeller_XMM-SINGLE_LIBRARY}
            ${PropWare_LibPropelleruino_COG_LIBRARY}
            ${PropWare_LibPropelleruino_CMM_LIBRARY}
            ${PropWare_LibPropelleruino_LMM_LIBRARY}
            ${PropWare_LibPropelleruino_XMMC_LIBRARY}
            ${PropWare_LibPropelleruino_XMM-SPLIT_LIBRARY}
            ${PropWare_LibPropelleruino_XMM-SINGLE_LIBRARY}
            ${PropWare_Simple_COG_LIBRARY}
            ${PropWare_Simple_CMM_LIBRARY}
            ${PropWare_Simple_LMM_LIBRARY}
            ${PropWare_Simple_XMMC_LIBRARY}
            ${PropWare_Simple_XMM-SPLIT_LIBRARY}
            ${PropWare_Simple_XMM-SINGLE_LIBRARY})

        set(PropWare_COG_LIBRARIES
            ${PropWare_PropWare_COG_LIBRARY}
            ${PropWare_Libpropeller_COG_LIBRARY}
            ${PropWare_LibPropelleruino_COG_LIBRARY}
            ${PropWare_Simple_COG_LIBRARY})
        set(PropWare_CMM_LIBRARIES
            ${PropWare_PropWare_CMM_LIBRARY}
            ${PropWare_Libpropeller_CMM_LIBRARY}
            ${PropWare_LibPropelleruino_CMM_LIBRARY}
            ${PropWare_Simple_CMM_LIBRARY})
        set(PropWare_LMM_LIBRARIES
            ${PropWare_PropWare_LMM_LIBRARY}
            ${PropWare_Libpropeller_LMM_LIBRARY}
            ${PropWare_LibPropelleruino_LMM_LIBRARY}
            ${PropWare_Simple_LMM_LIBRARY})
        set(PropWare_XMMC_LIBRARIES
            ${PropWare_PropWare_XMMC_LIBRARY}
            ${PropWare_Libpropeller_XMMC_LIBRARY}
            ${PropWare_LibPropelleruino_XMMC_LIBRARY}
            ${PropWare_Simple_XMMC_LIBRARY})
        set(PropWare_XMM-SINGLE_LIBRARIES
            ${PropWare_PropWare_XMM-SINGLE_LIBRARY}
            ${PropWare_Libpropeller_XMM-SINGLE_LIBRARY}
            ${PropWare_LibPropelleruino_XMM-SINGLE_LIBRARY}
            ${PropWare_Simple_XMM-SINGLE_LIBRARY})
        set(PropWare_XMM-SPLIT_LIBRARIES
            ${PropWare_PropWare_XMM-SPLIT_LIBRARY}
            ${PropWare_Libpropeller_XMM-SPLIT_LIBRARY}
            ${PropWare_LibPropelleruino_XMM-SPLIT_LIBRARY}
            ${PropWare_Simple_XMM-SPLIT_LIBRARY})

        file(READ "${PROPWARE_PATH}/version.txt" PropWare_VERSION)
        string(STRIP ${PropWare_VERSION} PropWare_VERSION)
    endif ()

    ##########################################
    # PropWare helper functions & macros
    ##########################################
    function (set_linker target)
        # Set the correct linker language
        get_property(_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
        if (C IN_LIST _languages)
            set(linker_language C)
        else ()
            if (CXX IN_LIST _languages)
                set(linker_language CXX)
            else ()
                message(FATAL_ERROR
                    "PropWare requires linking with C or CXX. Please enable at least one of those languages")
            endif ()
        endif ()

        SET_TARGET_PROPERTIES("${target}" PROPERTIES LINKER_LANGUAGE ${linker_language})
    endfunction ()

    function (append_linker_flags target)
        foreach (flag IN LISTS ARGN)
            set(ALL_LINK_FLAGS ${flag})
            get_target_property(EXISTING_LINK_FLAGS "${target}" LINK_FLAGS)
            if (EXISTING_LINK_FLAGS)
                set(ALL_LINK_FLAGS "${EXISTING_LINK_FLAGS} ${ALL_LINK_FLAGS}")
            endif ()
            set_target_properties("${target}" PROPERTIES LINK_FLAGS "${ALL_LINK_FLAGS}")
        endforeach ()
    endfunction ()

    function (set_compile_flags target model)
        # Convert all of the user's flags into a list
        foreach (variable COMMON_FLAGS COMMON_COG_FLAGS ASM_FLAGS C_FLAGS CXX_FLAGS COGC_FLAGS COGCXX_FLAGS ECOGC_FLAGS ECOGCXX_FLAGS)
            separate_arguments(${variable} UNIX_COMMAND "${${variable}}")
        endforeach ()

        if (AUTO_OPTIMIZATION)
            list(APPEND COMMON_FLAGS -Os)
        endif ()

        # Handle user options
        if (32_BIT_DOUBLES)
            list(APPEND COMMON_FLAGS -m32bit-doubles)
        endif ()

        if (WARN_ALL)
            list(APPEND COMMON_FLAGS -Wall)
        endif ()

        if (AUTO_C_STD)
            # Cannot use CMake's built-in support for C standard because it will not affect COGC or ECOGC
            list(APPEND C_FLAGS --std=gnu99)
        endif ()

        if (AUTO_CXX_STD)
            # Cannot use CMake's built-in support for C++ standard because it will not affect COGCXX or ECOGCXX
            list(APPEND CXX_FLAGS --std=gnu++0x)
        endif ()

        if (SAVE_TEMPS)
            # Only save temps when explicitly requested - prevents highly parallel builds with duplicate file names
            list(APPEND COMMON_FLAGS -save-temps)
        endif ()

        # C++ Language features
        macro (add_language_feature_option option_name feature)
            if (${option_name})
                list(APPEND CXX_FLAGS -f${feature})
            else ()
                list(APPEND CXX_FLAGS -fno-${feature})
            endif ()
        endmacro ()
        add_language_feature_option(EXCEPTIONS exceptions)
        add_language_feature_option(RUNTIME_TYPE_INFORMATION rtti)
        add_language_feature_option(THREADSAFE_STATICS threadsafe-statics)

        # XMM model is retroactively renamed xmm-split
        if ("${model}" STREQUAL xmm)
            set(model xmm-split)
        endif ()

        # Linker pruning is broken when used with the cog memory model. See the
        # following thread for a workaround:
        # http://forums.parallax.com/showthread.php/157878-Simple-blinky-program-and-linker-pruning
        string(TOLOWER "${model}" MODEL_LOWERCASE)
        if (NOT((MODEL_LOWERCASE STREQUAL "cog")))
            if (AUTO_CUT_SECTIONS)
                list(APPEND COMMON_FLAGS -ffunction-sections)
                list(APPEND COMMON_FLAGS -fdata-sections)
                append_linker_flags(${target} -Wl,--gc-sections)
            endif ()
        endif ()

        # Check if a deprecated variable name is set
        if (DEFINED CFLAGS OR DEFINED CXXFLAGS)
            message(WARN ": The variables `CFLAGS` and `CXXFLAGS` have been replaced by `C_FLAGS` and `CXX_FLAGS`.")
            list(APPEND C_FLAGS ${CFLAGS})
            list(APPEND CXX_FLAGS ${CXXFLAGS})
            set(CFLAGS )
            set(CXXFLAGS )
        endif()

        get_property(_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

        foreach (language ASM C CXX)
            if (${language} IN_LIST _languages)
                set(flags
                    ${COMMON_FLAGS}
                    ${${language}_FLAGS}
                )
                target_compile_options("${target}" PRIVATE $<$<COMPILE_LANGUAGE:${language}>:${flags}>)
                target_compile_options("${target}" PUBLIC $<$<COMPILE_LANGUAGE:${language}>:-m${model}>)
            endif ()
        endforeach ()

        foreach (topLang C CXX)
            foreach (subLang COG ECOG)
                set(language ${subLang}${topLang})
                if (${language} IN_LIST _languages)
                    set(flags
                        ${COMMON_FLAGS}
                        ${${topLang}_FLAGS}
                        ${COMMON_COG_FLAGS}
                        ${${language}_FLAGS}
                    )
                    target_compile_options("${target}" PRIVATE $<$<COMPILE_LANGUAGE:${language}>:${flags}>)
                endif ()
            endforeach ()
        endforeach ()

        if (DAT IN_LIST _languages)
            target_compile_options("${target}" PUBLIC $<$<COMPILE_LANGUAGE:DAT>:${model}>)
        endif ()

        append_linker_flags(${target} -m${model})
    endfunction ()

    function (add_prop_targets name target-suffix)
        if (DEFINED BOARD)
            set(BOARDFLAG -b${BOARD})
        endif()

        if (DEFINED GDB_BAUD)
            set(BAUDFLAG -b ${GDB_BAUD})
        elseif (DEFINED ENV{GDB_BAUD})
            set(BAUDFLAG -b $ENV{GDB_BAUD})
        endif ()

        # Add target for debugging (load to RAM and start GDB)
        add_custom_target(gdb${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} $<TARGET_FILE:${name}> -r -g &&
            ${CMAKE_GDB} ${BAUDFLAG} $<TARGET_FILE:${name}>
            DEPENDS ${name})

        # Add target for debugging (load to RAM and start terminal)
        add_custom_target(debug${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} $<TARGET_FILE:${name}> -r -t
            DEPENDS ${name})

        # Add target for debugging in EEPROM (load to EEPROM and start terminal)
        add_custom_target(debug-eeprom${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} $<TARGET_FILE:${name}> -r -t -e
            DEPENDS ${name})

        # Add target for debugging from an SD card (load to SD card and start terminal)
        add_custom_target(debug-sd-cache${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} -z $<TARGET_FILE:${name}> -r -t -e
            DEPENDS ${name})

        # Add target for debugging from an SD card (load to SD card and start terminal)
        add_custom_target(debug-sd-loader${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} -l $<TARGET_FILE:${name}> -r -t -e
            DEPENDS ${name})

        # Add target for run (load to RAM, do not start terminal)
        add_custom_target(run-ram${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} $<TARGET_FILE:${name}> -r
            DEPENDS ${name})

        # Add target for run (load to EEPROM, do not start terminal)
        add_custom_target(run${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} $<TARGET_FILE:${name}> -r -e
            DEPENDS ${name})

        # Add target for debugging from an SD card (load to SD card and start terminal)
        add_custom_target(run-sd-cache${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} -z $<TARGET_FILE:${name}> -r -e
            DEPENDS ${name})

        # Add target for debugging from an SD card (load to SD card and start terminal)
        add_custom_target(run-sd-loader${target-suffix}
            ${CMAKE_ELF_LOADER} ${BOARDFLAG} -l $<TARGET_FILE:${name}> -r -e
            DEPENDS ${name})
    endfunction ()

    function (_pw_create_executable name suffix model src1)
        # Create the binary
        add_executable("${name}" "${src1}" ${ARGN})

        # Set flags
        set_compile_flags(${name} ${model})

        # Link it with the appropriate static libraries (and use C template for linking)
        string(TOUPPER ${MODEL} _PW_UPPER_MODEL)
        target_link_libraries(${name} ${PropWare_${_PW_UPPER_MODEL}_LIBRARIES})
        set_linker(${name})

        # Don't use `-isystem` when you're not supposed to
        set_target_properties(${name} PROPERTIES NO_SYSTEM_FROM_IMPORTED ON)

        # Create propeller-load targets
        add_prop_targets(${name} "${suffix}")
    endfunction ()

    function (create_executable name src1)
        # If no model is specified, we must choose a default so that the proper libraries can be linked
        if (NOT DEFINED MODEL)
            set(MODEL lmm)
        endif ()
        _pw_create_executable("${name}" "-${name}" ${MODEL} "${src1}" ${ARGN})
    endfunction ()

    function (create_simple_executable name src1)
        # If no model is specified, we must choose a default so that the proper libraries can be linked
        if (NOT DEFINED MODEL)
            set(MODEL lmm)
        endif ()
        if (PROPWARE_MAIN_PACKAGE)
            _pw_create_executable("${name}" "-${name}" ${MODEL} "${src1}" ${ARGN})
        else ()
            _pw_create_executable("${name}" "" ${MODEL} "${src1}" ${ARGN})
        endif ()
    endfunction ()

    function (create_library name src1)
        # If no model is specified, we must choose a default so that the proper libraries can be linked
        if (NOT DEFINED MODEL)
            set(MODEL lmm)
        endif ()
        add_library(${name} STATIC "${src1}" ${ARGN})
        set_compile_flags(${name} ${MODEL})
        set_linker(${name})
        # Don't use `-isystem` when you're not supposed to
        set_target_properties(${name} PROPERTIES NO_SYSTEM_FROM_IMPORTED ON)
    endfunction ()

    function(spin2cpp source output_var_name)
        if (NOT SPIN2CPP_COMMAND)
            message(FATAL_ERROR "Unable to use the `spin2cpp()` CMake function when spin2cpp can not be found on your system.")
        endif ()

        get_filename_component(SOURCE_PATH "${source}" ABSOLUTE)

        # Find output files
        execute_process(COMMAND "${SPIN2CPP_COMMAND}" --files "${SOURCE_PATH}"
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
            OUTPUT_VARIABLE FILES_STRING
            RESULT_VARIABLE SPIN2CPP_DEPENDS_CODE
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        if (SPIN2CPP_DEPENDS_CODE)
            message(FATAL_ERROR "Spin2cpp failed to report dependencies. Exit code ${SPIN2CPP_DEPENDS_CODE}")
        endif ()

        # Convert output files from newline-separated list to CMake list
        string(REPLACE "\r" "" OUTPUT_FILE_NAMES "${FILES_STRING}")
        string(REPLACE "\n" ";" OUTPUT_FILE_NAMES "${OUTPUT_FILE_NAMES}")
        foreach (file_name IN LISTS OUTPUT_FILE_NAMES)
            list(APPEND ALL_OUTPUT_FILES "${CMAKE_CURRENT_BINARY_DIR}/${file_name}")
        endforeach ()

        # Only save new files in the "output list" variable and add to the clean target
        foreach (file_path IN LISTS ALL_OUTPUT_FILES)
            list(FIND FILES_GENERATED_IN_DIRECTORY ${file_path} INDEX)
            if ("-1" STREQUAL INDEX)
                list(APPEND FILES_GENERATED_IN_DIRECTORY "${file_path}")
                list(APPEND UNIQUE_OUTPUT_FILES "${file_path}")
            endif ()
        endforeach ()
        set(FILES_GENERATED_IN_DIRECTORY ${FILES_GENERATED_IN_DIRECTORY} PARENT_SCOPE)
        set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${FILES_GENERATED_IN_DIRECTORY}")

        if (UNIQUE_OUTPUT_FILES)
            if (ARGN)
                set(MAIN_FLAG "--main")
            endif ()
            include_directories(${CMAKE_CURRENT_BINARY_DIR})
            add_custom_command(OUTPUT ${UNIQUE_OUTPUT_FILES}
                COMMAND "${SPIN2CPP_COMMAND}"
                ARGS --gas ${MAIN_FLAG} "${SOURCE_PATH}"
                MAIN_DEPENDENCY "${SOURCE_PATH}"
                WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
                COMMENT "Converting ${source} to C++")
        endif ()
        set(${output_var_name} ${UNIQUE_OUTPUT_FILES} PARENT_SCOPE)
    endfunction()

    enable_testing()
    add_custom_target(test-all COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure)
    function(create_test target src1)
        create_executable("${target}" "${src1}" ${ARGN})
        if (DEFINED BOARD)
            set(BOARDFLAG -b${BOARD})
        endif()
        add_test(NAME ${target}
            COMMAND ${CMAKE_ELF_LOADER} ${BOARDFLAG} $<TARGET_FILE:${target}> -r -t -q)
        add_dependencies(test-all ${target})
        add_custom_target(test-${target}
            COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -R ${target}
            DEPENDS ${target})
    endfunction()

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(PropWare
        REQUIRED_VARS CMAKE_TOOLCHAIN_FILE
        VERSION_VAR PropWare_VERSION
    )

    mark_as_advanced(
        CMAKE_TOOLCHAIN_FILE
        PropWare_VERSION

        PropWare_LIBRARIES
        PropWare_COG_LIBRARIES
        PropWare_CMM_LIBRARIES
        PropWare_LMM_LIBRARIES
        PropWare_XMMC_LIBRARIES
        PropWare_XMM-SPLIT_LIBRARIES
        PropWare_XMM-SINGLE_LIBRARIES
        PropWare_PropWare_COG_LIBRARY
        PropWare_PropWare_CMM_LIBRARY
        PropWare_PropWare_LMM_LIBRARY
        PropWare_PropWare_XMMC_LIBRARY
        PropWare_PropWare_XMM-SPLIT_LIBRARY
        PropWare_PropWare_XMM-SINGLE_LIBRARY
        PropWare_Libpropeller_COG_LIBRARY
        PropWare_Libpropeller_CMM_LIBRARY
        PropWare_Libpropeller_LMM_LIBRARY
        PropWare_Libpropeller_XMMC_LIBRARY
        PropWare_Libpropeller_XMM-SPLIT_LIBRARY
        PropWare_Libpropeller_XMM-SINGLE_LIBRARY
        PropWare_LibPropelleruino_COG_LIBRARY
        PropWare_LibPropelleruino_CMM_LIBRARY
        PropWare_LibPropelleruino_LMM_LIBRARY
        PropWare_LibPropelleruino_XMMC_LIBRARY
        PropWare_LibPropelleruino_XMM-SPLIT_LIBRARY
        PropWare_LibPropelleruino_XMM-SINGLE_LIBRARY
        PropWare_Simple_COG_LIBRARY
        PropWare_Simple_CMM_LIBRARY
        PropWare_Simple_LMM_LIBRARY
        PropWare_Simple_XMMC_LIBRARY
        PropWare_Simple_XMM-SPLIT_LIBRARY
        PropWare_Simple_XMM-SINGLE_LIBRARY
    )
endif()
