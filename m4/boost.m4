# boost.m4: Locate Boost headers and libraries for autoconf-based projects.
# Copyright (C) 2007, 2008, 2009  Benoit Sigoure <tsuna@lrde.epita.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Additional permission under section 7 of the GNU General Public
# License, version 3 ("GPLv3"):
#
# If you convey this file as part of a work that contains a
# configuration script generated by Autoconf, you may do so under
# terms of your choice.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

m4_define([_BOOST_SERIAL], [m4_translit([
# serial 12
], [#
], [])])

# Original sources can be found at http://github.com/tsuna/boost.m4
# You can fetch the latest version of the script by doing:
#   wget http://github.com/tsuna/boost.m4/raw/master/build-aux/boost.m4

# ------ #
# README #
# ------ #

# This file provides several macros to use the various Boost libraries.
# The first macro is BOOST_REQUIRE.  It will simply check if it's possible to
# find the Boost headers of a given (optional) minimum version and it will
# define BOOST_CPPFLAGS accordingly.  It will add an option --with-boost to
# your configure so that users can specify non standard locations.
# If the user's environment contains BOOST_ROOT and --with-boost was not
# specified, --with-boost=$BOOST_ROOT is implicitly used.
# For more README and documentation, go to http://github.com/tsuna/boost.m4
# Note: THESE MACROS ASSUME THAT YOU USE LIBTOOL.  If you don't, don't worry,
# simply read the README, it will show you what to do step by step.

m4_pattern_forbid([^_?BOOST_])


# _BOOST_SED_CPP(SED-PROGRAM, PROGRAM,
#                [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# --------------------------------------------------------
# Same as AC_EGREP_CPP, but leave the result in conftest.i.
# PATTERN is *not* overquoted, as in AC_EGREP_CPP.  It could be useful
# to turn this into a macro which extracts the value of any macro.
m4_define([_BOOST_SED_CPP],
[AC_LANG_PREPROC_REQUIRE()dnl
AC_REQUIRE([AC_PROG_SED])dnl
AC_LANG_CONFTEST([AC_LANG_SOURCE([[$2]])])
AS_IF([dnl eval is necessary to expand ac_cpp.
dnl Ultrix and Pyramid sh refuse to redirect output of eval, so use subshell.
dnl Beware of Windows end-of-lines, for instance if we are running
dnl some Windows programs under Wine.  In that case, boost/version.hpp
dnl is certainly using "\r\n", but the regular Unix shell will only
dnl strip `\n' with backquotes, not the `\r'.  This results in
dnl boost_cv_lib_version='1_37\r' for instance, which breaks
dnl everything else.
dnl Cannot use 'dnl' after [$4] because a trailing dnl may break AC_CACHE_CHECK
(eval "$ac_cpp conftest.$ac_ext") 2>&AS_MESSAGE_LOG_FD |
  tr -d '\r' |
  $SED -n -e "$1" >conftest.i 2>&1],
  [$3],
  [$4])
rm -rf conftest*
])# AC_EGREP_CPP



# BOOST_REQUIRE([VERSION], [ACTION-IF-NOT-FOUND])
# -----------------------------------------------
# Look for Boost.  If version is given, it must either be a literal of the form
# "X.Y.Z" where X, Y and Z are integers (the ".Z" part being optional) or a
# variable "$var".
# Defines the value BOOST_CPPFLAGS.  This macro only checks for headers with
# the required version, it does not check for any of the Boost libraries.
# On # success, defines HAVE_BOOST.  On failure, calls the optional
# ACTION-IF-NOT-FOUND action if one was supplied.
# Otherwise aborts with an error message.
AC_DEFUN([BOOST_REQUIRE],
[AC_REQUIRE([AC_PROG_CXX])dnl
AC_REQUIRE([AC_PROG_GREP])dnl
echo "$as_me: this is boost.m4[]_BOOST_SERIAL" >&AS_MESSAGE_LOG_FD
boost_save_IFS=$IFS
boost_version_req=$1
IFS=.
set x $boost_version_req 0 0 0
IFS=$boost_save_IFS
shift
boost_version_req=`expr "$[1]" '*' 100000 + "$[2]" '*' 100 + "$[3]"`
AC_ARG_WITH([boost],
   [AS_HELP_STRING([--with-boost=DIR],
                   [prefix of Boost $1 @<:@guess@:>@])])dnl
AC_ARG_VAR([BOOST_ROOT],[Location of Boost installation])dnl
# If BOOST_ROOT is set and the user has not provided a value to
# --with-boost, then treat BOOST_ROOT as if it the user supplied it.
if test x"$BOOST_ROOT" != x; then
  if test x"$with_boost" = x; then
    AC_MSG_NOTICE([Detected BOOST_ROOT; continuing with --with-boost=$BOOST_ROOT])
    with_boost=$BOOST_ROOT
  else
    AC_MSG_NOTICE([Detected BOOST_ROOT=$BOOST_ROOT, but overridden by --with-boost=$with_boost])
  fi
fi
AC_SUBST([DISTCHECK_CONFIGURE_FLAGS],
         ["$DISTCHECK_CONFIGURE_FLAGS '--with-boost=$with_boost'"])
boost_save_CPPFLAGS=$CPPFLAGS
  AC_CACHE_CHECK([for Boost headers version >= $boost_version_req],
    [boost_cv_inc_path],
    [boost_cv_inc_path=no
AC_LANG_PUSH([C++])dnl
m4_pattern_allow([^BOOST_VERSION$])dnl
    AC_LANG_CONFTEST([AC_LANG_PROGRAM([[#include <boost/version.hpp>
#if !defined BOOST_VERSION
# error BOOST_VERSION is not defined
#elif BOOST_VERSION < $boost_version_req
# error Boost headers version < $boost_version_req
#endif
]])])
    # If the user provided a value to --with-boost, use it and only it.
    case $with_boost in #(
      ''|yes) set x '' /opt/local/include /usr/local/include /opt/include \
                 /usr/include C:/Boost/include;; #(
      *)      set x "$with_boost/include" "$with_boost";;
    esac
    shift
    for boost_dir
    do
    # Without --layout=system, Boost (or at least some versions) installs
    # itself in <prefix>/include/boost-<version>.  This inner loop helps to
    # find headers in such directories.
    #
    # Any ${boost_dir}/boost-x_xx directories are searched in reverse version
    # order followed by ${boost_dir}.  The final '.' is a sentinel for
    # searching $boost_dir" itself.  Entries are whitespace separated.
    #
    # I didn't indent this loop on purpose (to avoid over-indented code)
    boost_layout_system_search_list=`cd "$boost_dir" 2>/dev/null \
        && ls -1 | "${GREP}" '^boost-' | sort -rn -t- -k2 \
        && echo .`
    for boost_inc in $boost_layout_system_search_list
    do
      if test x"$boost_inc" != x.; then
        boost_inc="$boost_dir/$boost_inc"
      else
        boost_inc="$boost_dir" # Uses sentinel in boost_layout_system_search_list
      fi
      if test x"$boost_inc" != x; then
        # We are going to check whether the version of Boost installed
        # in $boost_inc is usable by running a compilation that
        # #includes it.  But if we pass a -I/some/path in which Boost
        # is not installed, the compiler will just skip this -I and
        # use other locations (either from CPPFLAGS, or from its list
        # of system include directories).  As a result we would use
        # header installed on the machine instead of the /some/path
        # specified by the user.  So in that precise case (trying
        # $boost_inc), make sure the version.hpp exists.
        #
        # Use test -e as there can be symlinks.
        test -e "$boost_inc/boost/version.hpp" || continue
        CPPFLAGS="$CPPFLAGS -I$boost_inc"
      fi
      AC_COMPILE_IFELSE([], [boost_cv_inc_path=yes], [boost_cv_version=no])
      if test x"$boost_cv_inc_path" = xyes; then
        if test x"$boost_inc" != x; then
          boost_cv_inc_path=$boost_inc
        fi
        break 2
      fi
    done
    done
AC_LANG_POP([C++])dnl
    ])
    case $boost_cv_inc_path in #(
      no)
        boost_errmsg="cannot find Boost headers version >= $boost_version_req"
        m4_if([$2], [],  [AC_MSG_ERROR([$boost_errmsg])],
                        [AC_MSG_NOTICE([$boost_errmsg])])
        $2
        ;;#(
      yes)
        BOOST_CPPFLAGS=
        ;;#(
      *)
        AC_SUBST([BOOST_CPPFLAGS], ["-I$boost_cv_inc_path"])
        ;;
    esac
  if test x"$boost_cv_inc_path" != xno; then
  AC_DEFINE([HAVE_BOOST], [1],
            [Defined if the requested minimum BOOST version is satisfied])
  AC_CACHE_CHECK([for Boost's header version],
    [boost_cv_lib_version],
    [m4_pattern_allow([^BOOST_LIB_VERSION$])dnl
     _BOOST_SED_CPP([/^boost-lib-version = /{s///;s/\"//g;p;g;}],
                    [#include <boost/version.hpp>
boost-lib-version = BOOST_LIB_VERSION],
    [boost_cv_lib_version=`cat conftest.i`])])
    # e.g. "134" for 1_34_1 or "135" for 1_35
    boost_major_version=`echo "$boost_cv_lib_version" | sed 's/_//;s/_.*//'`
    case $boost_major_version in #(
      '' | *[[!0-9]]*)
        AC_MSG_ERROR([invalid value: boost_major_version=$boost_major_version])
        ;;
    esac
fi
CPPFLAGS=$boost_save_CPPFLAGS
])# BOOST_REQUIRE

# BOOST_STATIC()
# --------------
# Add the "--enable-static-boost" configure argument. If this argument is given
# on the command line, static versions of the libraries will be looked up.
AC_DEFUN([BOOST_STATIC],
  [AC_ARG_ENABLE([static-boost],
     [AC_HELP_STRING([--enable-static-boost],
               [Prefer the static boost libraries over the shared ones [no]])],
     [enable_static_boost=yes],
     [enable_static_boost=no])])# BOOST_STATIC

# BOOST_FIND_HEADER([HEADER-NAME], [ACTION-IF-NOT-FOUND], [ACTION-IF-FOUND])
# --------------------------------------------------------------------------
# Wrapper around AC_CHECK_HEADER for Boost headers.  Useful to check for
# some parts of the Boost library which are only made of headers and don't
# require linking (such as Boost.Foreach).
#
# Default ACTION-IF-NOT-FOUND: Fail with a fatal error unless Boost couldn't be
# found in the first place, in which case by default a notice is issued to the
# user.  Presumably if we haven't died already it's because it's OK to not have
# Boost, which is why only a notice is issued instead of a hard error.
#
# Default ACTION-IF-FOUND: define the preprocessor symbol HAVE_<HEADER-NAME> in
# case of success # (where HEADER-NAME is written LIKE_THIS, e.g.,
# HAVE_BOOST_FOREACH_HPP).
AC_DEFUN([BOOST_FIND_HEADER],
[AC_REQUIRE([BOOST_REQUIRE])dnl
if test x"$boost_cv_inc_path" = xno; then
  m4_default([$2], [AC_MSG_NOTICE([Boost not available, not searching for $1])])
else
AC_LANG_PUSH([C++])dnl
boost_save_CPPFLAGS=$CPPFLAGS
CPPFLAGS="$CPPFLAGS $BOOST_CPPFLAGS"
AC_CHECK_HEADER([$1],
  [m4_default([$3], [AC_DEFINE(AS_TR_CPP([HAVE_$1]), [1],
                               [Define to 1 if you have <$1>])])],
  [m4_default([$2], [AC_MSG_ERROR([cannot find $1])])])
CPPFLAGS=$boost_save_CPPFLAGS
AC_LANG_POP([C++])dnl
fi
])# BOOST_FIND_HEADER


# BOOST_FIND_LIB([LIB-NAME], [PREFERRED-RT-OPT], [HEADER-NAME], [CXX-TEST],
#                [CXX-PROLOGUE])
# -------------------------------------------------------------------------
# Look for the Boost library LIB-NAME (e.g., LIB-NAME = `thread', for
# libboost_thread).  Check that HEADER-NAME works and check that
# libboost_LIB-NAME can link with the code CXX-TEST.  The optional argument
# CXX-PROLOGUE can be used to include some C++ code before the `main'
# function.
#
# Invokes BOOST_FIND_HEADER([HEADER-NAME]) (see above).
#
# Boost libraries typically come compiled with several flavors (with different
# runtime options) so PREFERRED-RT-OPT is the preferred suffix.  A suffix is one
# or more of the following letters: sgdpn (in that order).  s = static
# runtime, d = debug build, g = debug/diagnostic runtime, p = STLPort build,
# n = (unsure) STLPort build without iostreams from STLPort (it looks like `n'
# must always be used along with `p').  Additionally, PREFERRED-RT-OPT can
# start with `mt-' to indicate that there is a preference for multi-thread
# builds.  Some sample values for PREFERRED-RT-OPT: (nothing), mt, d, mt-d, gdp
# ...  If you want to make sure you have a specific version of Boost
# (eg, >= 1.33) you *must* invoke BOOST_REQUIRE before this macro.
AC_DEFUN([BOOST_FIND_LIB],
[AC_REQUIRE([BOOST_REQUIRE])dnl
AC_REQUIRE([_BOOST_FIND_COMPILER_TAG])dnl
AC_REQUIRE([BOOST_STATIC])dnl
AC_REQUIRE([_BOOST_GUESS_WHETHER_TO_USE_MT])dnl
if test x"$boost_cv_inc_path" = xno; then
  AC_MSG_NOTICE([Boost not available, not searching for the Boost $1 library])
else
dnl The else branch is huge and wasn't intended on purpose.
AC_LANG_PUSH([C++])dnl
AS_VAR_PUSHDEF([Boost_lib], [boost_cv_lib_$1])dnl
AS_VAR_PUSHDEF([Boost_lib_LDFLAGS], [boost_cv_lib_$1_LDFLAGS])dnl
AS_VAR_PUSHDEF([Boost_lib_LIBS], [boost_cv_lib_$1_LIBS])dnl
BOOST_FIND_HEADER([$3])
boost_save_CPPFLAGS=$CPPFLAGS
CPPFLAGS="$CPPFLAGS $BOOST_CPPFLAGS"
# Now let's try to find the library.  The algorithm is as follows: first look
# for a given library name according to the user's PREFERRED-RT-OPT.  For each
# library name, we prefer to use the ones that carry the tag (toolset name).
# Each library is searched through the various standard paths were Boost is
# usually installed.  If we can't find the standard variants, we try to
# enforce -mt (for instance on MacOSX, libboost_threads.dylib doesn't exist
# but there's -obviously- libboost_threads-mt.dylib).
AC_CACHE_CHECK([for the Boost $1 library], [Boost_lib],
  [Boost_lib=no
  case "$2" in #(
    mt | mt-) boost_mt=-mt; boost_rtopt=;; #(
    mt* | mt-*) boost_mt=-mt; boost_rtopt=`expr "X$2" : 'Xmt-*\(.*\)'`;; #(
    *) boost_mt=; boost_rtopt=$2;;
  esac
  if test $enable_static_boost = yes; then
    boost_rtopt="s$boost_rtopt"
  fi
  # Find the proper debug variant depending on what we've been asked to find.
  case $boost_rtopt in #(
    *d*) boost_rt_d=$boost_rtopt;; #(
    *[[sgpn]]*) # Insert the `d' at the right place (in between `sg' and `pn')
      boost_rt_d=`echo "$boost_rtopt" | sed 's/\(s*g*\)\(p*n*\)/\1\2/'`;; #(
    *) boost_rt_d='-d';;
  esac
  # If the PREFERRED-RT-OPT are not empty, prepend a `-'.
  test -n "$boost_rtopt" && boost_rtopt="-$boost_rtopt"
  $boost_guess_use_mt && boost_mt=-mt
  # Look for the abs path the static archive.
  # $libext is computed by Libtool but let's make sure it's non empty.
  test -z "$libext" &&
    AC_MSG_ERROR([the libext variable is empty, did you invoke Libtool?])
  boost_save_ac_objext=$ac_objext
  # Generate the test file.
  AC_LANG_CONFTEST([AC_LANG_PROGRAM([#include <$3>
$5], [$4])])
dnl Optimization hacks: compiling C++ is slow, especially with Boost.  What
dnl we're trying to do here is guess the right combination of link flags
dnl (LIBS / LDFLAGS) to use a given library.  This can take several
dnl iterations before it succeeds and is thus *very* slow.  So what we do
dnl instead is that we compile the code first (and thus get an object file,
dnl typically conftest.o).  Then we try various combinations of link flags
dnl until we succeed to link conftest.o in an executable.  The problem is
dnl that the various TRY_LINK / COMPILE_IFELSE macros of Autoconf always
dnl remove all the temporary files including conftest.o.  So the trick here
dnl is to temporarily change the value of ac_objext so that conftest.o is
dnl preserved accross tests.  This is obviously fragile and I will burn in
dnl hell for not respecting Autoconf's documented interfaces, but in the
dnl mean time, it optimizes the macro by a factor of 5 to 30.
dnl Another small optimization: the first argument of AC_COMPILE_IFELSE left
dnl empty because the test file is generated only once above (before we
dnl start the for loops).
  AC_COMPILE_IFELSE([],
    [ac_objext=do_not_rm_me_plz],
    [AC_MSG_ERROR([cannot compile a test that uses Boost $1])])
  ac_objext=$boost_save_ac_objext
  boost_failed_libs=
# Don't bother to ident the 6 nested for loops, only the 2 innermost ones
# matter.
for boost_tag_ in -$boost_cv_lib_tag ''; do
for boost_ver_ in -$boost_cv_lib_version ''; do
for boost_mt_ in $boost_mt -mt ''; do
for boost_rtopt_ in $boost_rtopt '' -d; do
  for boost_lib in \
    boost_$1$boost_tag_$boost_mt_$boost_rtopt_$boost_ver_ \
    boost_$1$boost_tag_$boost_rtopt_$boost_ver_ \
    boost_$1$boost_tag_$boost_mt_$boost_ver_ \
    boost_$1$boost_tag_$boost_ver_
  do
    # Avoid testing twice the same lib
    case $boost_failed_libs in #(
      *@$boost_lib@*) continue;;
    esac
    # If with_boost is empty, we'll search in /lib first, which is not quite
    # right so instead we'll try to a location based on where the headers are.
    boost_tmp_lib=$with_boost
    test x"$with_boost" = x && boost_tmp_lib=${boost_cv_inc_path%/include}
    for boost_ldpath in "$boost_tmp_lib/lib" '' \
             /opt/local/lib /usr/local/lib /opt/lib /usr/lib \
             "$with_boost" C:/Boost/lib /lib /usr/lib64 /lib64
    do
      test -e "$boost_ldpath" || continue
      boost_save_LDFLAGS=$LDFLAGS
      # Are we looking for a static library?
      case $boost_ldpath:$boost_rtopt_ in #(
        *?*:*s*) # Yes (Non empty boost_ldpath + s in rt opt)
          Boost_lib_LIBS="$boost_ldpath/lib$boost_lib.$libext"
          test -e "$Boost_lib_LIBS" || continue;; #(
        *) # No: use -lboost_foo to find the shared library.
          Boost_lib_LIBS="-l$boost_lib";;
      esac
      boost_save_LIBS=$LIBS
      LIBS="$Boost_lib_LIBS $LIBS"
      test x"$boost_ldpath" != x && LDFLAGS="$LDFLAGS -L$boost_ldpath"
dnl First argument of AC_LINK_IFELSE left empty because the test file is
dnl generated only once above (before we start the for loops).
      _BOOST_AC_LINK_IFELSE([],
                            [Boost_lib=yes], [Boost_lib=no])
      ac_objext=$boost_save_ac_objext
      LDFLAGS=$boost_save_LDFLAGS
      LIBS=$boost_save_LIBS
      if test x"$Boost_lib" = xyes; then
        Boost_lib_LDFLAGS="-L$boost_ldpath -R$boost_ldpath"
        break 6
      else
        boost_failed_libs="$boost_failed_libs@$boost_lib@"
      fi
    done
  done
done
done
done
done
rm -f conftest.$ac_objext
])
case $Boost_lib in #(
  no) _AC_MSG_LOG_CONFTEST
    AC_MSG_ERROR([cannot not find the flags to link with Boost $1])
    ;;
esac
AC_SUBST(AS_TR_CPP([BOOST_$1_LDFLAGS]), [$Boost_lib_LDFLAGS])
AC_SUBST(AS_TR_CPP([BOOST_$1_LIBS]), [$Boost_lib_LIBS])
CPPFLAGS=$boost_save_CPPFLAGS
AS_VAR_POPDEF([Boost_lib])dnl
AS_VAR_POPDEF([Boost_lib_LDFLAGS])dnl
AS_VAR_POPDEF([Boost_lib_LIBS])dnl
AC_LANG_POP([C++])dnl
fi
])# BOOST_FIND_LIB


# --------------------------------------- #
# Checks for the various Boost libraries. #
# --------------------------------------- #

# List of boost libraries: http://www.boost.org/libs/libraries.htm
# The page http://beta.boost.org/doc/libs is useful: it gives the first release
# version of each library (among other things).

# BOOST_ARRAY()
# -------------
# Look for Boost.Array
AC_DEFUN([BOOST_ARRAY],
[BOOST_FIND_HEADER([boost/array.hpp])])


# BOOST_ASIO()
# ------------
# Look for Boost.Asio (new in Boost 1.35).
AC_DEFUN([BOOST_ASIO],
[AC_REQUIRE([BOOST_SYSTEM])dnl
BOOST_FIND_HEADER([boost/asio.hpp])])


# BOOST_BIND()
# ------------
# Look for Boost.Bind
AC_DEFUN([BOOST_BIND],
[BOOST_FIND_HEADER([boost/bind.hpp])])


# BOOST_CONVERSION()
# ------------------
# Look for Boost.Conversion (cast / lexical_cast)
AC_DEFUN([BOOST_CONVERSION],
[BOOST_FIND_HEADER([boost/cast.hpp])
BOOST_FIND_HEADER([boost/lexical_cast.hpp])
])# BOOST_CONVERSION


# BOOST_DATE_TIME([PREFERRED-RT-OPT])
# -----------------------------------
# Look for Boost.Date_Time.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_DATE_TIME],
[BOOST_FIND_LIB([date_time], [$1],
                [boost/date_time/posix_time/posix_time.hpp],
                [boost::posix_time::ptime t;])
])# BOOST_DATE_TIME


# BOOST_FILESYSTEM([PREFERRED-RT-OPT])
# ------------------------------------
# Look for Boost.Filesystem.  For the documentation of PREFERRED-RT-OPT, see
# the documentation of BOOST_FIND_LIB above.
# Do not check for boost/filesystem.hpp because this file was introduced in
# 1.34.
AC_DEFUN([BOOST_FILESYSTEM],
[# Do we have to check for Boost.System?  This link-time dependency was
# added as of 1.35.0.  If we have a version <1.35, we must not attempt to
# find Boost.System as it didn't exist by then.
if test $boost_major_version -ge 135; then
BOOST_SYSTEM([$1])
fi # end of the Boost.System check.
AC_REQUIRE([_BOOST_PTHREAD_FLAG])
boost_filesystem_save_LIBS=$LIBS
boost_filesystem_save_LDFLAGS=$LDFLAGS
m4_pattern_allow([^BOOST_SYSTEM_(LIBS|LDFLAGS)$])dnl
LIBS="$LIBS $BOOST_SYSTEM_LIBS $boost_cv_pthread_flag"
LDFLAGS="$LDFLAGS $BOOST_SYSTEM_LDFLAGS"
BOOST_FIND_LIB([filesystem], [$1],
                [boost/filesystem/path.hpp], [boost::filesystem::path p;])
BOOST_FILESYSTEM_LIBS="$BOOST_FILESYSTEM_LIBS $boost_cv_pthread_flag"
BOOST_CPPFLAGS="$BOOST_CPPFLAGS $boost_cv_pthread_flag"
LIBS=$boost_filesystem_save_LIBS
LDFLAGS=$boost_filesystem_save_LDFLAGS
])# BOOST_FILESYSTEM

# BOOST_FOREACH()
# ---------------
# Look for Boost.Foreach
AC_DEFUN([BOOST_FOREACH],
[BOOST_FIND_HEADER([boost/foreach.hpp])])


# BOOST_FORMAT()
# --------------
# Look for Boost.Format
# Note: we can't check for boost/format/format_fwd.hpp because the header isn't
# standalone.  It can't be compiled because it triggers the following error:
# boost/format/detail/config_macros.hpp:88: error: 'locale' in namespace 'std'
#                                                  does not name a type
AC_DEFUN([BOOST_FORMAT],
[BOOST_FIND_HEADER([boost/format.hpp])])


# BOOST_FUNCTION()
# ----------------
# Look for Boost.Function
AC_DEFUN([BOOST_FUNCTION],
[BOOST_FIND_HEADER([boost/function.hpp])])


# BOOST_GRAPH([PREFERRED-RT-OPT])
# -------------------------------
# Look for Boost.Graphs.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_GRAPH],
[BOOST_FIND_LIB([graph], [$1],
                [boost/graph/adjacency_list.hpp], [boost::adjacency_list<> g;])
])# BOOST_GRAPH


# BOOST_IOSTREAMS([PREFERRED-RT-OPT])
# -------------------------------
# Look for Boost.IOStreams.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_IOSTREAMS],
[BOOST_FIND_LIB([iostreams], [$1],
                [boost/iostreams/device/file_descriptor.hpp],
                [boost::iostreams::file_descriptor fd(0); fd.close();])
])# BOOST_IOSTREAMS


# BOOST_HASH()
# ------------
# Look for Boost.Functional/Hash
AC_DEFUN([BOOST_HASH],
[BOOST_FIND_HEADER([boost/functional/hash.hpp])])


# BOOST_UNORDERED()
# ------------
# Look for Boost.Unordered
AC_DEFUN([BOOST_UNORDERED],
[BOOST_FIND_HEADER([boost/unordered_map.hpp])
BOOST_FIND_HEADER([boost/unordered_set.hpp])
])


# BOOST_LAMBDA()
# --------------
# Look for Boost.Lambda
AC_DEFUN([BOOST_LAMBDA],
[BOOST_FIND_HEADER([boost/lambda/lambda.hpp])])


# BOOST_MATH()
# ------------
# Look for Boost.Math
# TODO: This library isn't header-only but it comes in multiple different
# flavors that don't play well with BOOST_FIND_LIB (e.g, libboost_math_c99,
# libboost_math_c99f, libboost_math_c99l, libboost_math_tr1,
# libboost_math_tr1f, libboost_math_tr1l).  This macro must be fixed to do the
# right thing anyway.
AC_DEFUN([BOOST_MATH],
[BOOST_FIND_HEADER([boost/math/special_functions.hpp])])


# BOOST_MULTIARRAY()
# ------------------
# Look for Boost.MultiArray
AC_DEFUN([BOOST_MULTIARRAY],
[BOOST_FIND_HEADER([boost/multi_array.hpp])])


# BOOST_NUMERIC_CONVERSION()
# --------------------------
# Look for Boost.NumericConversion (policy-based numeric conversion)
AC_DEFUN([BOOST_NUMERIC_CONVERSION],
[BOOST_FIND_HEADER([boost/numeric/conversion/converter.hpp])
])# BOOST_NUMERIC_CONVERSION


# BOOST_OPTIONAL()
# ----------------
# Look for Boost.Optional
AC_DEFUN([BOOST_OPTIONAL],
[BOOST_FIND_HEADER([boost/optional.hpp])])


# BOOST_PREPROCESSOR()
# --------------------
# Look for Boost.Preprocessor
AC_DEFUN([BOOST_PREPROCESSOR],
[BOOST_FIND_HEADER([boost/preprocessor/repeat.hpp])])


# BOOST_PROGRAM_OPTIONS([PREFERRED-RT-OPT])
# -----------------------------------------
# Look for Boost.Program_options.  For the documentation of PREFERRED-RT-OPT, see
# the documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_PROGRAM_OPTIONS],
[BOOST_FIND_LIB([program_options], [$1],
                [boost/program_options.hpp],
                [boost::program_options::options_description d("test");])
])# BOOST_PROGRAM_OPTIONS


# BOOST_REF()
# -----------
# Look for Boost.Ref
AC_DEFUN([BOOST_REF],
[BOOST_FIND_HEADER([boost/ref.hpp])])


# BOOST_REGEX([PREFERRED-RT-OPT])
# -------------------------------
# Look for Boost.Regex.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_REGEX],
[BOOST_FIND_LIB([regex], [$1],
                [boost/regex.hpp],
                [boost::regex exp("*"); boost::regex_match("foo", exp);])
])# BOOST_REGEX


# BOOST_SERIALIZATION([PREFERRED-RT-OPT])
# ---------------------------------------
# Look for Boost.Serialization.  For the documentation of PREFERRED-RT-OPT, see
# the documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_SERIALIZATION],
[BOOST_FIND_LIB([serialization], [$1],
                [boost/archive/text_oarchive.hpp],
                [std::ostream* o = 0; // Cheap way to get an ostream...
                boost::archive::text_oarchive t(*o);])
])# BOOST_SIGNALS


# BOOST_SIGNALS([PREFERRED-RT-OPT])
# ---------------------------------
# Look for Boost.Signals.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_SIGNALS],
[BOOST_FIND_LIB([signals], [$1],
                [boost/signal.hpp],
                [boost::signal<void ()> s;])
])# BOOST_SIGNALS


# BOOST_SMART_PTR()
# -----------------
# Look for Boost.SmartPtr
AC_DEFUN([BOOST_SMART_PTR],
[BOOST_FIND_HEADER([boost/scoped_ptr.hpp])
BOOST_FIND_HEADER([boost/shared_ptr.hpp])
])


# BOOST_STATICASSERT()
# --------------------
# Look for Boost.StaticAssert
AC_DEFUN([BOOST_STATICASSERT],
[BOOST_FIND_HEADER([boost/static_assert.hpp])])


# BOOST_STRING_ALGO()
# -------------------
# Look for Boost.StringAlgo
AC_DEFUN([BOOST_STRING_ALGO],
[BOOST_FIND_HEADER([boost/algorithm/string.hpp])
])


# BOOST_SYSTEM([PREFERRED-RT-OPT])
# --------------------------------
# Look for Boost.System.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.  This library was introduced in Boost
# 1.35.0.
AC_DEFUN([BOOST_SYSTEM],
[BOOST_FIND_LIB([system], [$1],
                [boost/system/error_code.hpp],
                [boost::system::error_code e; e.clear();])
])# BOOST_SYSTEM


# BOOST_TEST([PREFERRED-RT-OPT])
# ------------------------------
# Look for Boost.Test.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_TEST],
[m4_pattern_allow([^BOOST_CHECK$])dnl
BOOST_FIND_LIB([unit_test_framework], [$1],
               [boost/test/unit_test.hpp], [BOOST_CHECK(2 == 2);],
               [using boost::unit_test::test_suite;
               test_suite* init_unit_test_suite(int argc, char ** argv)
               { return NULL; }])
])# BOOST_TEST


# BOOST_THREADS([PREFERRED-RT-OPT])
# ---------------------------------
# Look for Boost.Thread.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
# FIXME: Provide an alias "BOOST_THREAD".
AC_DEFUN([BOOST_THREADS],
[dnl Having the pthread flag is required at least on GCC3 where
dnl boost/thread.hpp would complain if we try to compile without
dnl -pthread on GNU/Linux.
AC_REQUIRE([_BOOST_PTHREAD_FLAG])dnl
boost_threads_save_LIBS=$LIBS
boost_threads_save_CPPFLAGS=$CPPFLAGS
LIBS="$LIBS $boost_cv_pthread_flag"
# Yes, we *need* to put the -pthread thing in CPPFLAGS because with GCC3,
# boost/thread.hpp will trigger a #error if -pthread isn't used:
#   boost/config/requires_threads.hpp:47:5: #error "Compiler threading support
#   is not turned on. Please set the correct command line options for
#   threading: -pthread (Linux), -pthreads (Solaris) or -mthreads (Mingw32)"
CPPFLAGS="$CPPFLAGS $boost_cv_pthread_flag"
BOOST_FIND_LIB([thread], [$1],
                [boost/thread.hpp], [boost::thread t; boost::mutex m;])
BOOST_THREAD_LIBS="$BOOST_THREAD_LIBS $boost_cv_pthread_flag"
BOOST_CPPFLAGS="$BOOST_CPPFLAGS $boost_cv_pthread_flag"
LIBS=$boost_threads_save_LIBS
CPPFLAGS=$boost_threads_save_CPPFLAGS
])# BOOST_THREADS


# BOOST_TOKENIZER()
# -----------------
# Look for Boost.Tokenizer
AC_DEFUN([BOOST_TOKENIZER],
[BOOST_FIND_HEADER([boost/tokenizer.hpp])])


# BOOST_TRIBOOL()
# ---------------
# Look for Boost.Tribool
AC_DEFUN([BOOST_TRIBOOL],
[BOOST_FIND_HEADER([boost/logic/tribool_fwd.hpp])
BOOST_FIND_HEADER([boost/logic/tribool.hpp])
])


# BOOST_TUPLE()
# -------------
# Look for Boost.Tuple
AC_DEFUN([BOOST_TUPLE],
[BOOST_FIND_HEADER([boost/tuple/tuple.hpp])])


# BOOST_TYPETRAITS()
# --------------------
# Look for Boost.TypeTraits
AC_DEFUN([BOOST_TYPETRAITS],
[BOOST_FIND_HEADER([boost/type_traits.hpp])])


# BOOST_UTILITY()
# ---------------
# Look for Boost.Utility (noncopyable, result_of, base-from-member idiom,
# etc.)
AC_DEFUN([BOOST_UTILITY],
[BOOST_FIND_HEADER([boost/utility.hpp])])


# BOOST_VARIANT()
# ---------------
# Look for Boost.Variant.
AC_DEFUN([BOOST_VARIANT],
[BOOST_FIND_HEADER([boost/variant/variant_fwd.hpp])
BOOST_FIND_HEADER([boost/variant.hpp])])


# BOOST_WAVE([PREFERRED-RT-OPT])
# ------------------------------
# NOTE: If you intend to use Wave/Spirit with thread support, make sure you
# call BOOST_THREADS first.
# Look for Boost.Wave.  For the documentation of PREFERRED-RT-OPT, see the
# documentation of BOOST_FIND_LIB above.
AC_DEFUN([BOOST_WAVE],
[AC_REQUIRE([BOOST_FILESYSTEM])dnl
AC_REQUIRE([BOOST_DATE_TIME])dnl
boost_wave_save_LIBS=$LIBS
boost_wave_save_LDFLAGS=$LDFLAGS
m4_pattern_allow([^BOOST_((FILE)?SYSTEM|DATE_TIME|THREAD)_(LIBS|LDFLAGS)$])dnl
LIBS="$LIBS $BOOST_SYSTEM_LIBS $BOOST_FILESYSTEM_LIBS $BOOST_DATE_TIME_LIBS\
$BOOST_THREAD_LIBS"
LDFLAGS="$LDFLAGS $BOOST_SYSTEM_LDFLAGS $BOOST_FILESYSTEM_LDFLAGS\
$BOOST_DATE_TIME_LDFLAGS $BOOST_THREAD_LDFLAGS"
BOOST_FIND_LIB([wave], [$1],
                [boost/wave.hpp],
                [boost::wave::token_id id; get_token_name(id);])
LIBS=$boost_wave_save_LIBS
LDFLAGS=$boost_wave_save_LDFLAGS
])# BOOST_WAVE


# BOOST_XPRESSIVE()
# -----------------
# Look for Boost.Xpressive (new since 1.36.0).
AC_DEFUN([BOOST_XPRESSIVE],
[BOOST_FIND_HEADER([boost/xpressive/xpressive.hpp])])


# ----------------- #
# Internal helpers. #
# ----------------- #


# _BOOST_PTHREAD_FLAG()
# ---------------------
# Internal helper for BOOST_THREADS.  Based on ACX_PTHREAD:
# http://autoconf-archive.cryp.to/acx_pthread.html
AC_DEFUN([_BOOST_PTHREAD_FLAG],
[AC_REQUIRE([AC_PROG_CXX])dnl
AC_REQUIRE([AC_CANONICAL_HOST])dnl
AC_LANG_PUSH([C++])dnl
AC_CACHE_CHECK([for the flags needed to use pthreads], [boost_cv_pthread_flag],
[ boost_cv_pthread_flag=
  # The ordering *is* (sometimes) important.  Some notes on the
  # individual items follow:
  # (none): in case threads are in libc; should be tried before -Kthread and
  #       other compiler flags to prevent continual compiler warnings
  # -lpthreads: AIX (must check this before -lpthread)
  # -Kthread: Sequent (threads in libc, but -Kthread needed for pthread.h)
  # -kthread: FreeBSD kernel threads (preferred to -pthread since SMP-able)
  # -llthread: LinuxThreads port on FreeBSD (also preferred to -pthread)
  # -pthread: GNU Linux/GCC (kernel threads), BSD/GCC (userland threads)
  # -pthreads: Solaris/GCC
  # -mthreads: MinGW32/GCC, Lynx/GCC
  # -mt: Sun Workshop C (may only link SunOS threads [-lthread], but it
  #      doesn't hurt to check since this sometimes defines pthreads too;
  #      also defines -D_REENTRANT)
  #      ... -mt is also the pthreads flag for HP/aCC
  # -lpthread: GNU Linux, etc.
  # --thread-safe: KAI C++
  case $host_os in #(
    *solaris*)
      # On Solaris (at least, for some versions), libc contains stubbed
      # (non-functional) versions of the pthreads routines, so link-based
      # tests will erroneously succeed.  (We need to link with -pthreads/-mt/
      # -lpthread.)  (The stubs are missing pthread_cleanup_push, or rather
      # a function called by this macro, so we could check for that, but
      # who knows whether they'll stub that too in a future libc.)  So,
      # we'll just look for -pthreads and -lpthread first:
      boost_pthread_flags="-pthreads -lpthread -mt -pthread";; #(
    *)
      boost_pthread_flags="-lpthreads -Kthread -kthread -llthread -pthread \
                           -pthreads -mthreads -lpthread --thread-safe -mt";;
  esac
  # Generate the test file.
  AC_LANG_CONFTEST([AC_LANG_PROGRAM([#include <pthread.h>],
    [pthread_t th; pthread_join(th, 0);
    pthread_attr_init(0); pthread_cleanup_push(0, 0);
    pthread_create(0,0,0,0); pthread_cleanup_pop(0);])])
  for boost_pthread_flag in '' $boost_pthread_flags; do
    boost_pthread_ok=false
dnl Re-use the test file already generated.
    boost_pthreads__save_LIBS=$LIBS
    LIBS="$LIBS $boost_pthread_flag"
    AC_LINK_IFELSE([],
      [if grep ".*$boost_pthread_flag" conftest.err; then
         echo "This flag seems to have triggered warnings" >&AS_MESSAGE_LOG_FD
       else
         boost_pthread_ok=:; boost_cv_pthread_flag=$boost_pthread_flag
       fi])
    LIBS=$boost_pthreads__save_LIBS
    $boost_pthread_ok && break
  done
])
AC_LANG_POP([C++])dnl
])# _BOOST_PTHREAD_FLAG


# _BOOST_gcc_test(MAJOR, MINOR)
# -----------------------------
# Internal helper for _BOOST_FIND_COMPILER_TAG.
m4_define([_BOOST_gcc_test],
["defined __GNUC__ && __GNUC__ == $1 && __GNUC_MINOR__ == $2 && !defined __ICC @ gcc$1$2"])dnl


# _BOOST_FIND_COMPILER_TAG()
# --------------------------
# Internal.  When Boost is installed without --layout=system, each library
# filename will hold a suffix that encodes the compiler used during the
# build.  The Boost build system seems to call this a `tag'.
AC_DEFUN([_BOOST_FIND_COMPILER_TAG],
[AC_REQUIRE([AC_PROG_CXX])dnl
AC_REQUIRE([AC_CANONICAL_HOST])dnl
AC_CACHE_CHECK([for the toolset name used by Boost for $CXX], [boost_cv_lib_tag],
[boost_cv_lib_tag=unknown
if test x$boost_cv_inc_path != xno; then
  AC_LANG_PUSH([C++])dnl
  # The following tests are mostly inspired by boost/config/auto_link.hpp
  # The list is sorted to most recent/common to oldest compiler (in order
  # to increase the likelihood of finding the right compiler with the
  # least number of compilation attempt).
  # Beware that some tests are sensible to the order (for instance, we must
  # look for MinGW before looking for GCC3).
  # I used one compilation test per compiler with a #error to recognize
  # each compiler so that it works even when cross-compiling (let me know
  # if you know a better approach).
  # Known missing tags (known from Boost's tools/build/v2/tools/common.jam):
  #   como, edg, kcc, bck, mp, sw, tru, xlc
  # I'm not sure about my test for `il' (be careful: Intel's ICC pre-defines
  # the same defines as GCC's).
  for i in \
    _BOOST_gcc_test(4, 5) \
    _BOOST_gcc_test(4, 4) \
    _BOOST_gcc_test(4, 3) \
    _BOOST_gcc_test(4, 2) \
    _BOOST_gcc_test(4, 1) \
    _BOOST_gcc_test(4, 0) \
    "defined __GNUC__ && __GNUC__ == 3 && !defined __ICC \
     && (defined WIN32 || defined WINNT || defined _WIN32 || defined __WIN32 \
         || defined __WIN32__ || defined __WINNT || defined __WINNT__) @ mgw" \
    _BOOST_gcc_test(3, 4) \
    _BOOST_gcc_test(3, 3) \
    "defined _MSC_VER && _MSC_VER >= 1500 @ vc90" \
    "defined _MSC_VER && _MSC_VER == 1400 @ vc80" \
    _BOOST_gcc_test(3, 2) \
    "defined _MSC_VER && _MSC_VER == 1310 @ vc71" \
    _BOOST_gcc_test(3, 1) \
    _BOOST_gcc_test(3, 0) \
    "defined __BORLANDC__ @ bcb" \
    "defined __ICC && (defined __unix || defined __unix__) @ il" \
    "defined __ICL @ iw" \
    "defined _MSC_VER && _MSC_VER == 1300 @ vc7" \
    _BOOST_gcc_test(2, 95) \
    "defined __MWERKS__ && __MWERKS__ <= 0x32FF @ cw9" \
    "defined _MSC_VER && _MSC_VER < 1300 && !defined UNDER_CE @ vc6" \
    "defined _MSC_VER && _MSC_VER < 1300 && defined UNDER_CE @ evc4" \
    "defined __MWERKS__ && __MWERKS__ <= 0x31FF @ cw8"
  do
    boost_tag_test=`expr "X$i" : 'X\([[^@]]*\) @ '`
    boost_tag=`expr "X$i" : 'X[[^@]]* @ \(.*\)'`
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#if $boost_tag_test
/* OK */
#else
# error $boost_tag_test
#endif
]])], [boost_cv_lib_tag=$boost_tag; break], [])
  done
AC_LANG_POP([C++])dnl
  case $boost_cv_lib_tag in #(
    # Some newer (>= 1.35?) versions of Boost seem to only use "gcc" as opposed
    # to "gcc41" for instance.
    *-gcc | *'-gcc ') :;; #(  Don't re-add -gcc: it's already in there.
    gcc*)
      boost_tag_x=
      case $host_os in #(
        darwin*)
          if test $boost_major_version -ge 136; then
            # The `x' added in r46793 of Boost.
            boost_tag_x=x
          fi;;
      esac
      # We can specify multiple tags in this variable because it's used by
      # BOOST_FIND_LIB that does a `for tag in -$boost_cv_lib_tag' ...
      boost_cv_lib_tag="$boost_tag_x$boost_cv_lib_tag -${boost_tag_x}gcc"
      ;; #(
    unknown)
      AC_MSG_WARN([[could not figure out which toolset name to use for $CXX]])
      boost_cv_lib_tag=
      ;;
  esac
fi])dnl end of AC_CACHE_CHECK
])# _BOOST_FIND_COMPILER_TAG


# _BOOST_GUESS_WHETHER_TO_USE_MT()
# --------------------------------
# Compile a small test to try to guess whether we should favor MT (Multi
# Thread) flavors of Boost.  Sets boost_guess_use_mt accordingly.
AC_DEFUN([_BOOST_GUESS_WHETHER_TO_USE_MT],
[# Check whether we do better use `mt' even though we weren't ask to.
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#if defined _REENTRANT || defined _MT || defined __MT__
/* use -mt */
#else
# error MT not needed
#endif
]])], [boost_guess_use_mt=:], [boost_guess_use_mt=false])
])

# _BOOST_AC_LINK_IFELSE(PROGRAM, [ACTION-IF-TRUE], [ACTION-IF-FALSE])
# -------------------------------------------------------------------
# Fork of _AC_LINK_IFELSE that preserves conftest.o across calls.  Fragile,
# will break when Autoconf changes its internals.  Requires that you manually
# rm -f conftest.$ac_objext in between to really different tests, otherwise
# you will try to link a conftest.o left behind by a previous test.
# Used to aggressively optimize BOOST_FIND_LIB (see the big comment in this
# macro).
#
# Don't use "break" in the actions, as it would short-circuit some code
# this macro runs after the actions.
m4_define([_BOOST_AC_LINK_IFELSE],
[m4_ifvaln([$1], [AC_LANG_CONFTEST([$1])])dnl
rm -f conftest$ac_exeext
boost_save_ac_ext=$ac_ext
boost_use_source=:
# If we already have a .o, re-use it.  We change $ac_ext so that $ac_link
# tries to link the existing object file instead of compiling from source.
test -f conftest.$ac_objext && ac_ext=$ac_objext && boost_use_source=false &&
  _AS_ECHO_LOG([re-using the existing conftest.$ac_objext])
AS_IF([_AC_DO_STDERR($ac_link) && {
	 test -z "$ac_[]_AC_LANG_ABBREV[]_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest$ac_exeext && {
	 test "$cross_compiling" = yes ||
	 $as_executable_p conftest$ac_exeext
dnl FIXME: use AS_TEST_X instead when 2.61 is widespread enough.
       }],
      [$2],
      [if $boost_use_source; then
         _AC_MSG_LOG_CONFTEST
       fi
       $3])
ac_objext=$boost_save_ac_objext
ac_ext=$boost_save_ac_ext
dnl Delete also the IPA/IPO (Inter Procedural Analysis/Optimization)
dnl information created by the PGI compiler (conftest_ipa8_conftest.oo),
dnl as it would interfere with the next link command.
rm -f core conftest.err conftest_ipa8_conftest.oo \
      conftest$ac_exeext m4_ifval([$1], [conftest.$ac_ext])[]dnl
])# _BOOST_AC_LINK_IFELSE

# Local Variables:
# mode: autoconf
# End:
