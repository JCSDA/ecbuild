# (C) Copyright 2011- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.

##############################################################################
#.rst:
#
# ecbuild_declare_project
# =======================
#
# Initialise an ecBuild project. A CMake project must have previously been
# declared with ``project( <name> ... )``. ::
#
#   ecbuild_declare_project()
#
# Sets the following CMake variables
#
# :<PROJECT_NAME>_GIT_SHA1:       Git revision (if project is a Git repo)
# :<PROJECT_NAME>_GIT_SHA1_SHORT: short Git revision (if project is a Git repo)
# :<PROJECT_NAME>_VERSION:        version as given in project( VERSION )
# :<PROJECT_NAME>_VERSION_MAJOR:  major version number
# :<PROJECT_NAME>_VERSION_MINOR:  minor version number
# :<PROJECT_NAME>_VERSION_PATCH:  patch version number
# :INSTALL_BIN_DIR:        relative install directory for executables
# :INSTALL_LIB_DIR:        relative install directory for libraries
# :INSTALL_INCLUDE_DIR:    relative install directory for include files
# :INSTALL_DATA_DIR:       relative install directory for data
# :INSTALL_CMAKE_DIR:      relative install directory for CMake files
#
# Customising install locations
# -----------------------------
#
# The relative installation directories of components can be customised by
# setting the following CMake variables on the command line or in cache:
#
# :INSTALL_BIN_DIR:        directory for installing executables
#                          (default: ``bin``)
# :INSTALL_LIB_DIR:        directory for installing libraries
#                          (default: ``lib``)
# :INSTALL_INCLUDE_DIR:    directory for installing include files
#                          (default: ``include``)
# :INSTALL_DATA_DIR:       directory for installing data
#                          (default: ``share/<project_name>``)
# :INSTALL_CMAKE_DIR:      directory for installing CMake files
#                          (default: ``share/<project_name>/cmake``)
#
# Using *relative* paths is recommended, which are interpreted relative to the
# ``CMAKE_INSTALL_PREFIX``. Using absolute paths makes the build
# non-relocatable and may break the generation of relocatable binary packages.
#
##############################################################################

macro( ecbuild_declare_project )

  string( TOUPPER ${PROJECT_NAME} PNAME )

  # reset the lists of targets (executables, libs, tests & resources)

  set( ${PROJECT_NAME}_ALL_EXES "" CACHE INTERNAL "" )
  set( ${PROJECT_NAME}_ALL_LIBS "" CACHE INTERNAL "" )

  # if git project get its HEAD SHA1
  # leave it here so we may use ${PROJECT_NAME}_GIT_SHA1 on the version file

  if( EXISTS ${PROJECT_SOURCE_DIR}/.git )
    get_git_head_revision( GIT_REFSPEC ${PROJECT_NAME}_GIT_SHA1 )
    if( ${PROJECT_NAME}_GIT_SHA1 )
      string( SUBSTRING "${${PROJECT_NAME}_GIT_SHA1}" 0 7 ${PROJECT_NAME}_GIT_SHA1_SHORT )
      #     ecbuild_debug_var( ${PROJECT_NAME}_GIT_SHA1 )
      #     ecbuild_debug_var( ${PROJECT_NAME}_GIT_SHA1_SHORT )
    else()
      ecbuild_debug( "Could not get git-sha1 for project ${PROJECT_NAME}")
    endif()

    ecbuild_declare_compat( ${PNAME}_GIT_SHA1 ${PROJECT_NAME}_GIT_SHA1 )
    ecbuild_declare_compat( ${PNAME}_GIT_SHA1_SHORT ${PROJECT_NAME}_GIT_SHA1_SHORT)
  endif()

  if(NOT (DEFINED ${PROJECT_NAME}_VERSION
      AND DEFINED ${PROJECT_NAME}_VERSION_MAJOR
      AND DEFINED ${PROJECT_NAME}_VERSION_MINOR
      AND DEFINED ${PROJECT_NAME}_VERSION_PATCH)
    )
    if(ECBUILD_2_COMPAT)
      if(ECBUILD_2_COMPAT_DEPRECATE)
        ecbuild_deprecate("Please set a project version in the project() rather than using VERSION.cmake")
      endif()

      ecbuild_compat_setversion()

    else()

      ecbuild_critical("Please define a version for ${PROJECT_NAME}\n\tproject( ${PROJECT_NAME} VERSION 1.1.0 LANGUAGES C CXX )")

    endif()
  endif()

  if(ECBUILD_2_COMPAT)
    ecbuild_declare_compat( ${PNAME}_MAJOR_VERSION ${PROJECT_NAME}_VERSION_MAJOR )
    ecbuild_declare_compat( ${PNAME}_MINOR_VERSION ${PROJECT_NAME}_VERSION_MINOR )
    ecbuild_declare_compat( ${PNAME}_PATCH_VERSION ${PROJECT_NAME}_VERSION_PATCH )
    ecbuild_declare_compat( ${PNAME}_VERSION_STR ${PROJECT_NAME}_VERSION )
    ecbuild_declare_compat( ${PNAME}_VERSION ${PROJECT_NAME}_VERSION )
  endif()

  #    ecbuild_debug_var( ${PROJECT_NAME}_VERSION )
  #    ecbuild_debug_var( ${PROJECT_NAME}_VERSION_STR )
  #    ecbuild_debug_var( ${PROJECT_NAME}_MAJOR_VERSION )
  #    ecbuild_debug_var( ${PROJECT_NAME}_MINOR_VERSION )
  #    ecbuild_debug_var( ${PROJECT_NAME}_PATCH_VERSION )

  # install dirs for this project

  # Use defaults unless values are already present in cache
  if( NOT INSTALL_BIN_DIR )
    set( INSTALL_BIN_DIR bin )
  endif()
  if( NOT INSTALL_LIB_DIR )
    set( INSTALL_LIB_DIR lib )
  endif()
  if( NOT INSTALL_INCLUDE_DIR )
    set( INSTALL_INCLUDE_DIR include )
  endif()
  # INSTALL_DATA_DIR is package specific and needs to be reset for subpackages
  # in a bundle. Users *cannot* override this directory (ECBUILD-315)
  set( INSTALL_DATA_DIR share/${PROJECT_NAME} )
  # share/${PROJECT_NAME}/cmake is a convention - it makes no sense to override it
  set( INSTALL_CMAKE_DIR share/${PROJECT_NAME}/cmake )

  mark_as_advanced( INSTALL_BIN_DIR )
  mark_as_advanced( INSTALL_LIB_DIR )
  mark_as_advanced( INSTALL_INCLUDE_DIR )
  mark_as_advanced( INSTALL_DATA_DIR )
  mark_as_advanced( INSTALL_CMAKE_DIR )

  # warnings for non-relocatable projects

  foreach( p LIB BIN INCLUDE DATA CMAKE )
    if( IS_ABSOLUTE ${INSTALL_${p}_DIR} )
      ecbuild_warn( "Defining INSTALL_${p}_DIR as absolute path '${INSTALL_${p}_DIR}' makes this build non-relocatable, possibly breaking the installation of RPMS and DEB packages" )
    endif()
  endforeach()

  # make relative paths absolute ( needed later on ) and cache them ...
  foreach( p LIB BIN INCLUDE DATA CMAKE )

    set( var INSTALL_${p}_DIR )

    if( NOT IS_ABSOLUTE "${${var}}" )
      set( ${PROJECT_NAME}_FULL_INSTALL_${p}_DIR "${CMAKE_INSTALL_PREFIX}/${${var}}"
           CACHE INTERNAL "${PROJECT_NAME} ${p} full install path" )
    else()
      ecbuild_warn( "Setting an absolute path for ${VAR} in project ${PNAME}, breakes generation of relocatable binary packages (rpm,deb,...)" )
      set( ${PROJECT_NAME}_FULL_INSTALL_${p}_DIR "${${var}}"
           CACHE INTERNAL "${PROJECT_NAME} ${p} full install path" )
    endif()
    ecbuild_declare_compat( ${PNAME}_FULL_INSTALL_${p}_DIR ${PROJECT_NAME}_FULL_INSTALL_${p}_DIR )

    #        ecbuild_debug_var( ${PROJECT_NAME}_FULL_INSTALL_${p}_DIR )

  endforeach()

  # correctly set CMAKE_INSTALL_RPATH

  if( ENABLE_RPATHS )

    if( ENABLE_RELATIVE_RPATHS )

      file( RELATIVE_PATH relative_rpath ${${PROJECT_NAME}_FULL_INSTALL_BIN_DIR} ${${PROJECT_NAME}_FULL_INSTALL_LIB_DIR} )
      # ecbuild_debug_var( relative_rpath )

      ecbuild_append_to_rpath( ${relative_rpath} )

    else() # make rpaths absolute

      if( IS_ABSOLUTE ${INSTALL_LIB_DIR} )
        ecbuild_append_to_rpath( "${INSTALL_LIB_DIR}" )
      else()
        ecbuild_append_to_rpath( "${CMAKE_INSTALL_PREFIX}/${INSTALL_LIB_DIR}" )
      endif()

    endif()

  endif()

  # ecbuild_debug_var( CMAKE_INSTALL_RPATH )

  # print project header

  ecbuild_info( "---------------------------------------------------------" )

  if( ${PROJECT_NAME}_GIT_SHA1_SHORT )
    ecbuild_info( "${Green}[${PROJECT_NAME}] (${${PROJECT_NAME}_VERSION}) [${${PROJECT_NAME}_GIT_SHA1_SHORT}]${ColourReset}" )
  else()
    ecbuild_info( "[${PROJECT_NAME}] (${${PROJECT_NAME}_VERSION})" )
  endif()

endmacro( ecbuild_declare_project )
