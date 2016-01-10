# (C) Copyright 1996-2015 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.

set( CMAKE_C_FLAGS_ALL            "-hlist=amid" CACHE STRING "Common flags for all build-types" FORCE )
set( CMAKE_C_FLAGS_RELEASE        "${CMAKE_C_FLAGS_ALL} -O3 -hfp3 -hscalar3 -hvector3 -DNDEBUG" CACHE STRING "Release C flags" FORCE )
set( CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_ALL} -O2 -hfp1 -Gfast -DNDEBUG" CACHE STRING "Release C flags" FORCE )
set( CMAKE_C_FLAGS_PRODUCTION     "${CMAKE_C_FLAGS_ALL} -O2 -hfp1 -G2" CACHE STRING "Production C flags" FORCE )
set( CMAKE_C_FLAGS_BIT            "${CMAKE_C_FLAGS_ALL} -O1 -hfp1 -hflex_mp=conservative -hadd_paren -DNDEBUG" CACHE STRING "Bit-reproducible C flags" FORCE )
set( CMAKE_C_FLAGS_DEBUG          "${CMAKE_C_FLAGS_ALL} -O0 -G0" CACHE STRING "Debug Cflags" FORCE )

set( CMAKE_C_LINK_FLAGS  "-Wl,-Map,loadmap -Wl,--as-needed -Ktrap=fp" CACHE STRING "" FORCE )