ifneq (,${GREP_OPTIONS})
  $(info GREP_OPTIONS is defined in your environment.)
  $(info )
  $(info This variable interfers with the proper operation of this script.)
  $(info )
  $(info The GREP_OPTIONS environment variable feature of grep is deprecated)
  $(info for exactly this reason and will be removed from future versions of)
  $(info grep.  The grep man page suggests that you use an alias or a script)
  $(info to invoke grep with your preferred options.)
  $(info )
  $(info unset the GREP_OPTIONS environment variable to use this makefile)
  $(error 1)
endif
ifeq (old,$(shell gmake --version /dev/null 2>&1 | grep 'GNU Make' | awk '{ if ($$3 < "3.81") {print "old"} }'))
  GMAKE_VERSION = $(shell gmake --version /dev/null 2>&1 | grep 'GNU Make' | awk '{ print $$3 }')
  $(warning *** Warning *** GNU Make Version $(GMAKE_VERSION) is too old to)
  $(warning *** Warning *** fully process this makefile)
endif
SIM_MAJOR=$(shell grep SIM_MAJOR src/scp/sim_rev.h | awk '{ print $$3 }')
BUILD_SINGLE := ${MAKECMDGOALS} $(BLANK_SUFFIX)
BUILD_MULTIPLE_VERB = is
ifneq (,$(findstring 3b2,${MAKECMDGOALS})$(findstring all,${MAKECMDGOALS}))
  NETWORK_USEFUL = true
  ifneq (,$(findstring all,${MAKECMDGOALS}))
    BUILD_MULTIPLE = s
    BUILD_MULTIPLE_VERB = are
  endif
  ifneq (,$(word 2,${MAKECMDGOALS}))
    BUILD_MULTIPLE = s
    BUILD_MULTIPLE_VERB = are
  endif
else
  ifeq (${MAKECMDGOALS},)
    # default target is all
    NETWORK_USEFUL = true
    BUILD_MULTIPLE = s
    BUILD_MULTIPLE_VERB = are
    BUILD_SINGLE := all $(BUILD_SINGLE)
  endif
endif
# someone may want to explicitly build simulators without network support
ifneq ($(NONETWORK),)
  NETWORK_USEFUL =
endif
ifneq ($(findstring Windows,${OS}),)
  ifeq ($(findstring .exe,${SHELL}),.exe)
    # MinGW
    WIN32 := 1
    # Tests don't run under MinGW
    TESTS := 0
  else # Msys or cygwin
    ifeq (MINGW,$(findstring MINGW,$(shell uname)))
      $(info *** This makefile can not be used with the Msys bash shell)
      $(error Use build_mingw.bat ${MAKECMDGOALS} from a Windows command prompt)
    endif
  endif
endif

find_exe = $(abspath $(strip $(firstword $(foreach dir,$(strip $(subst :, ,${PATH})),$(wildcard $(dir)/$(1))))))
find_lib = $(firstword $(abspath $(strip $(firstword $(foreach dir,$(strip ${LIBPATH}),$(foreach ext,$(strip ${LIBEXT}),$(wildcard $(dir)/lib$(1).$(ext))))))))
find_include = $(abspath $(strip $(firstword $(foreach dir,$(strip ${INCPATH}),$(wildcard $(dir)/$(1).h)))))
ifneq (3,${SIM_MAJOR})
  ifneq (0,$(TESTS))
    find_test = RegisterSanityCheck $(abspath $(wildcard $(1)/tests/$(2)_test.ini)) </dev/null
    ifneq (,${TEST_ARG})
      TESTING_FEATURES = - Per simulator tests will be run with argument: ${TEST_ARG}
    else
      TESTING_FEATURES = - Per simulator tests will be run
    endif
  else
    TESTING_FEATURES = - Per simulator tests will be skipped
  endif
endif
ifeq (${WIN32},)  #*nix Environments (&& cygwin)
  ifeq (${GCC},)
    ifeq (,$(shell which gcc 2>/dev/null))
      $(info *** Warning *** Using local cc since gcc isn't available locally.)
      $(info *** Warning *** You may need to install gcc to build working simulators.)
      GCC = cc
    else
      GCC = gcc
    endif
  endif
  OSTYPE = $(shell uname)
  # OSNAME is used in messages to indicate the source of libpcap components
  OSNAME = $(OSTYPE)
  ifeq (SunOS,$(OSTYPE))
    TEST = /bin/test
  else
    TEST = test
  endif
  ifeq (CYGWIN,$(findstring CYGWIN,$(OSTYPE))) # uname returns CYGWIN_NT-n.n-ver
    OSTYPE = cygwin
    OSNAME = windows-build
  endif
  ifeq (Darwin,$(OSTYPE))
    ifeq (,$(shell which port)$(shell which brew))
      $(info *** Info *** simh dependent packages on macOS must be provided by either the)
      $(info *** Info *** MacPorts package system or by the HomeBrew package system.)
      $(info *** Info *** Neither of these seem to be installed on the local system.)
      $(info *** Info ***)
      ifeq (,$(INCLUDES)$(LIBRARIES))
        $(info *** Info *** Users wanting to build simulators with locally built dependent)
        $(info *** Info *** packages or packages provided by an unsupported package)
        $(info *** Info *** management system may be able to override where this procedure)
        $(info *** Info *** looks for include files and/or libraries.  Overrides can be)
        $(info *** Info *** specified by defining exported environment variables or GNU make)
        $(info *** Info *** command line arguments which specify INCLUDES and/or LIBRARIES.)
        $(info *** Info *** If this works, that's great, if it doesn't you are on your own!)
      else
        $(info *** Warning *** Attempting to build on macOS with:)
        $(info *** Warning *** INCLUDES defined as $(INCLUDES))
        $(info *** Warning *** and)
        $(info *** Warning *** LIBRARIES defined as $(LIBRARIES))
      endif
    endif
  endif
  ifeq (,$(shell ${GCC} -v /dev/null 2>&1 | grep 'clang'))
    GCC_VERSION = $(shell ${GCC} -v /dev/null 2>&1 | grep 'gcc version' | awk '{ print $$3 }')
    COMPILER_NAME = GCC Version: $(GCC_VERSION)
    ifeq (,$(GCC_VERSION))
      ifeq (SunOS,$(OSTYPE))
        ifneq (,$(shell ${GCC} -V 2>&1 | grep 'Sun C'))
          SUNC_VERSION = $(shell ${GCC} -V 2>&1 | grep 'Sun C')
          COMPILER_NAME = $(wordlist 2,10,$(SUNC_VERSION))
          CC_STD = -std=c99
        endif
      endif
      ifeq (HP-UX,$(OSTYPE))
        ifneq (,$(shell what `which $(firstword ${GCC}) 2>&1`| grep -i compiler))
          COMPILER_NAME = $(strip $(shell what `which $(firstword ${GCC}) 2>&1` | grep -i compiler))
          CC_STD = -std=gnu99
        endif
      endif
    else
      ifeq (,$(findstring ++,${GCC}))
        CC_STD = -std=gnu99
      else
        CPP_BUILD = 1
      endif
    endif
  else
    ifeq (Apple,$(shell ${GCC} -v /dev/null 2>&1 | grep 'Apple' | awk '{ print $$1 }'))
      COMPILER_NAME = $(shell ${GCC} -v /dev/null 2>&1 | grep 'Apple' | awk '{ print $$1 " " $$2 " " $$3 " " $$4 }')
      CLANG_VERSION = $(word 4,$(COMPILER_NAME))
    else
      COMPILER_NAME = $(shell ${GCC} -v /dev/null 2>&1 | grep 'clang version' | awk '{ print $$1 " " $$2 " " $$3 }')
      CLANG_VERSION = $(word 3,$(COMPILER_NAME))
      ifeq (,$(findstring .,$(CLANG_VERSION)))
        COMPILER_NAME = $(shell ${GCC} -v /dev/null 2>&1 | grep 'clang version' | awk '{ print $$1 " " $$2 " " $$3 " " $$4 }')
        CLANG_VERSION = $(word 4,$(COMPILER_NAME))
      endif
    endif
    ifeq (,$(findstring ++,${GCC}))
      CC_STD = -std=c99
    else
      CPP_BUILD = 1
      OS_CCDEFS += -Wno-deprecated
    endif
  endif
  ifeq (git-repo,$(shell if ${TEST} -e ./.git; then echo git-repo; fi))
    GIT_PATH=$(strip $(shell which git))
    ifeq (,$(GIT_PATH))
      $(error building using a git repository, but git is not available)
    endif
    ifeq (commit-id-exists,$(shell if ${TEST} -e .git-commit-id; then echo commit-id-exists; fi))
      CURRENT_GIT_COMMIT_ID=$(strip $(shell grep 'SIM_GIT_COMMIT_ID' .git-commit-id | awk '{ print $$2 }'))
      ACTUAL_GIT_COMMIT_ID=$(strip $(shell git log -1 --pretty="%H"))
      ifneq ($(CURRENT_GIT_COMMIT_ID),$(ACTUAL_GIT_COMMIT_ID))
        NEED_COMMIT_ID = need-commit-id
        # make sure that the invalidly formatted .git-commit-id file wasn't generated
        # by legacy git hooks which need to be removed.
        $(shell rm -f .git/hooks/post-checkout .git/hooks/post-commit .git/hooks/post-merge)
      endif
    else
      NEED_COMMIT_ID = need-commit-id
    endif
    ifneq (,$(shell git update-index --refresh --))
      GIT_EXTRA_FILES=+uncommitted-changes
    endif
    ifneq (,$(or $(NEED_COMMIT_ID),$(GIT_EXTRA_FILES)))
      isodate=$(shell git log -1 --pretty="%ai"|sed -e 's/ /T/'|sed -e 's/ //')
      $(shell git log -1 --pretty="SIM_GIT_COMMIT_ID %H$(GIT_EXTRA_FILES)%nSIM_GIT_COMMIT_TIME $(isodate)" >.git-commit-id)
    endif
  endif
  LTO_EXCLUDE_VERSIONS = 
  PCAPLIB = pcap
  ifeq (agcc,$(findstring agcc,${GCC})) # Android target build?
    OS_CCDEFS += -D_GNU_SOURCE -DSIM_ASYNCH_IO 
    OS_LDFLAGS = -lm
  else # Non-Android (or Native Android) Builds
    ifeq (,$(INCLUDES)$(LIBRARIES))
      INCPATH:=$(shell LANG=C; ${GCC} -x c -v -E /dev/null 2>&1 | grep -A 10 '> search starts here' | grep '^ ' | tr -d '\n')
      ifeq (,${INCPATH})
        INCPATH:=/usr/include
      endif
      LIBPATH:=/usr/lib
    else
      $(info *** Warning ***)
      ifeq (,$(INCLUDES))
        INCPATH:=$(shell LANG=C; ${GCC} -x c -v -E /dev/null 2>&1 | grep -A 10 '> search starts here' | grep '^ ' | tr -d '\n')
      else
        $(info *** Warning *** Unsupported build with INCLUDES defined as: $(INCLUDES))
        INCPATH:=$(strip $(subst :, ,$(INCLUDES)))
        UNSUPPORTED_BUILD := include
      endif
      ifeq (,$(LIBRARIES))
        LIBPATH:=/usr/lib
      else
        $(info *** Warning *** Unsupported build with LIBRARIES defined as: $(LIBRARIES))
        LIBPATH:=$(strip $(subst :, ,$(LIBRARIES)))
        ifeq (include,$(UNSUPPORTED_BUILD))
          UNSUPPORTED_BUILD := include+lib
        else
          UNSUPPORTED_BUILD := lib
        endif
      endif
      $(info *** Warning ***)
    endif
    OS_CCDEFS += -D_GNU_SOURCE
    GCC_OPTIMIZERS_CMD = ${GCC} -v --help 2>&1
    GCC_WARNINGS_CMD = ${GCC} -v --help 2>&1
    LD_ELF = $(shell echo | ${GCC} -E -dM - | grep __ELF__)
    ifeq (Darwin,$(OSTYPE))
      OSNAME = OSX
      LIBEXT = dylib
      ifneq (include,$(findstring include,$(UNSUPPORTED_BUILD)))
        INCPATH:=$(shell LANG=C; ${GCC} -x c -v -E /dev/null 2>&1 | grep -A 10 '> search starts here' | grep '^ ' | grep -v 'framework directory' | tr -d '\n')
      endif
      ifeq (incopt,$(shell if ${TEST} -d /opt/local/include; then echo incopt; fi))
        INCPATH += /opt/local/include
        OS_CCDEFS += -I/opt/local/include
      endif
      ifeq (libopt,$(shell if ${TEST} -d /opt/local/lib; then echo libopt; fi))
        LIBPATH += /opt/local/lib
        OS_LDFLAGS += -L/opt/local/lib
      endif
      ifeq (HomeBrew,$(or $(shell if ${TEST} -d /usr/local/Cellar; then echo HomeBrew; fi),$(shell if ${TEST} -d /opt/homebrew/Cellar; then echo HomeBrew; fi)))
        ifeq (local,$(shell if $(TEST) -d /usr/local/Cellar; then echo local; fi))
          HBPATH = /usr/local
        else
          HBPATH = /opt/homebrew
        endif
        INCPATH += $(foreach dir,$(wildcard $(HBPATH)/Cellar/*/*),$(realpath $(dir)/include))
        LIBPATH += $(foreach dir,$(wildcard $(HBPATH)/Cellar/*/*),$(realpath $(dir)/lib))
      endif
    else
      ifeq (Linux,$(OSTYPE))
        ifeq (Android,$(shell uname -o))
          OS_CCDEFS += -D__ANDROID_API__=$(shell getprop ro.build.version.sdk) -DSIM_BUILD_OS=" On Android Version $(shell getprop ro.build.version.release)"
        endif
        ifneq (lib,$(findstring lib,$(UNSUPPORTED_BUILD)))
          ifeq (Android,$(shell uname -o))
            ifneq (,$(shell if ${TEST} -d ${PREFIX}/lib; then echo prefixlib; fi))
              LIBPATH += ${PREFIX}/lib
            endif
            ifneq (,$(shell if ${TEST} -d /system/lib; then echo systemlib; fi))
              LIBPATH += /system/lib
            endif
            LIBPATH += $(LD_LIBRARY_PATH)
          endif
          ifeq (ldconfig,$(shell if ${TEST} -e /sbin/ldconfig; then echo ldconfig; fi))
            LIBPATH := $(sort $(foreach lib,$(shell /sbin/ldconfig -p | grep ' => /' | sed 's/^.* => //'),$(dir $(lib))))
          endif
        endif
        LIBSOEXT = so
        LIBEXT = $(LIBSOEXT) a
      else
        ifeq (SunOS,$(OSTYPE))
          OSNAME = Solaris
          ifneq (lib,$(findstring lib,$(UNSUPPORTED_BUILD)))
            LIBPATH := $(shell LANG=C; crle | grep 'Default Library Path' | awk '{ print $$5 }' | sed 's/:/ /g')
          endif
          LIBEXT = so
          OS_LDFLAGS += -lsocket -lnsl
          ifeq (incsfw,$(shell if ${TEST} -d /opt/sfw/include; then echo incsfw; fi))
            INCPATH += /opt/sfw/include
            OS_CCDEFS += -I/opt/sfw/include
          endif
          ifeq (libsfw,$(shell if ${TEST} -d /opt/sfw/lib; then echo libsfw; fi))
            LIBPATH += /opt/sfw/lib
            OS_LDFLAGS += -L/opt/sfw/lib -R/opt/sfw/lib
          endif
          OS_CCDEFS += -D_LARGEFILE_SOURCE
        else
          ifeq (cygwin,$(OSTYPE))
            # use 0readme_ethernet.txt documented Windows pcap build components
            INCPATH += ../windows-build/winpcap/WpdPack/Include
            LIBPATH += ../windows-build/winpcap/WpdPack/Lib
            PCAPLIB = wpcap
            LIBEXT = a
          else
            ifneq (,$(findstring AIX,$(OSTYPE)))
              OS_LDFLAGS += -lm -lrt
              ifeq (incopt,$(shell if ${TEST} -d /opt/freeware/include; then echo incopt; fi))
                INCPATH += /opt/freeware/include
                OS_CCDEFS += -I/opt/freeware/include
              endif
              ifeq (libopt,$(shell if ${TEST} -d /opt/freeware/lib; then echo libopt; fi))
                LIBPATH += /opt/freeware/lib
                OS_LDFLAGS += -L/opt/freeware/lib
              endif
            else
              ifneq (,$(findstring Haiku,$(OSTYPE)))
                HAIKU_ARCH=$(shell getarch)
                ifeq ($(HAIKU_ARCH),)
                  $(error Missing getarch command, your Haiku release is probably too old)
                endif
                ifeq ($(HAIKU_ARCH),x86_gcc2)
                  $(error Unsupported arch x86_gcc2. Run setarch x86 and retry)
                endif
                INCPATH := $(shell findpaths -e -a $(HAIKU_ARCH) B_FIND_PATH_HEADERS_DIRECTORY)
                INCPATH += $(shell findpaths -e B_FIND_PATH_HEADERS_DIRECTORY posix)
                LIBPATH := $(shell findpaths -e -a $(HAIKU_ARCH) B_FIND_PATH_DEVELOP_LIB_DIRECTORY)
                OS_LDFLAGS += -lnetwork
              else
                ifeq (,$(findstring NetBSD,$(OSTYPE)))
                  ifneq (no ldconfig,$(findstring no ldconfig,$(shell which ldconfig 2>&1)))
                    LDSEARCH :=$(shell LANG=C; ldconfig -r | grep 'search directories' | awk '{print $$3}' | sed 's/:/ /g')
                  endif
                  ifneq (,$(LDSEARCH))
                    LIBPATH := $(LDSEARCH)
                  else
                    ifeq (,$(strip $(LPATH)))
                      $(info *** Warning ***)
                      $(info *** Warning *** The library search path on your $(OSTYPE) platform can not be)
                      $(info *** Warning *** determined.  This should be resolved before you can expect)
                      $(info *** Warning *** to have fully working simulators.)
                      $(info *** Warning ***)
                      $(info *** Warning *** You can specify your library paths via the LPATH environment)
                      $(info *** Warning *** variable.)
                      $(info *** Warning ***)
                    else
                      LIBPATH = $(subst :, ,$(LPATH))
                    endif
                  endif
                  OS_LDFLAGS += $(patsubst %,-L%,${LIBPATH})
                endif
              endif
            endif
            ifeq (usrpkglib,$(shell if ${TEST} -d /usr/pkg/lib; then echo usrpkglib; fi))
              LIBPATH += /usr/pkg/lib
              INCPATH += /usr/pkg/include
              OS_LDFLAGS += -L/usr/pkg/lib -R/usr/pkg/lib
              OS_CCDEFS += -I/usr/pkg/include
            endif
            ifeq (/usr/local/lib,$(findstring /usr/local/lib,${LIBPATH}))
              INCPATH += /usr/local/include
              OS_CCDEFS += -I/usr/local/include
            endif
            ifneq (,$(findstring NetBSD,$(OSTYPE))$(findstring FreeBSD,$(OSTYPE))$(findstring AIX,$(OSTYPE)))
              LIBEXT = so
            else
              ifeq (HP-UX,$(OSTYPE))
                ifeq (ia64,$(shell uname -m))
                  LIBEXT = so
                else
                  LIBEXT = sl
                endif
                OS_CCDEFS += -D_HPUX_SOURCE -D_LARGEFILE64_SOURCE
                OS_LDFLAGS += -Wl,+b:
                NO_LTO = 1
              else
                LIBEXT = a
              endif
            endif
          endif
        endif
      endif
    endif
    ifeq (,$(LIBSOEXT))
      LIBSOEXT = $(LIBEXT)
    endif
    ifeq (,$(filter /lib/,$(LIBPATH)))
      ifeq (existlib,$(shell if $(TEST) -d /lib/; then echo existlib; fi))
        LIBPATH += /lib/
      endif
    endif
    ifeq (,$(filter /usr/lib/,$(LIBPATH)))
      ifeq (existusrlib,$(shell if $(TEST) -d /usr/lib/; then echo existusrlib; fi))
        LIBPATH += /usr/lib/
      endif
    endif
    export CPATH = $(subst $() $(),:,$(INCPATH))
    export LIBRARY_PATH = $(subst $() $(),:,$(LIBPATH))
    # Some gcc versions don't support LTO, so only use LTO when the compiler is known to support it
    ifeq (,$(NO_LTO))
      ifneq (,$(GCC_VERSION))
        ifeq (,$(shell ${GCC} -v /dev/null 2>&1 | grep '\-\-enable-lto'))
          LTO_EXCLUDE_VERSIONS += $(GCC_VERSION)
        endif
      endif
    endif
  endif
  $(info lib paths are: ${LIBPATH})
  $(info include paths are: ${INCPATH})
  need_search = $(strip $(shell ld -l$(1) /dev/null 2>&1 | grep $(1) | sed s/$(1)//))
  LD_SEARCH_NEEDED := $(call need_search,ZzzzzzzZ)
  ifneq (,$(call find_lib,m))
    OS_LDFLAGS += -lm
    $(info using libm: $(call find_lib,m))
  endif
  ifneq (,$(call find_lib,rt))
    OS_LDFLAGS += -lrt
    $(info using librt: $(call find_lib,rt))
  endif
  ifneq (,$(call find_include,pthread))
    ifneq (,$(call find_lib,pthread))
      OS_CCDEFS += -DUSE_READER_THREAD -DSIM_ASYNCH_IO 
      OS_LDFLAGS += -lpthread
      $(info using libpthread: $(call find_lib,pthread) $(call find_include,pthread))
    else
      LIBEXTSAVE := ${LIBEXT}
      LIBEXT = a
      ifneq (,$(call find_lib,pthread))
        OS_CCDEFS += -DUSE_READER_THREAD -DSIM_ASYNCH_IO 
        OS_LDFLAGS += -lpthread
        $(info using libpthread: $(call find_lib,pthread) $(call find_include,pthread))
      else
        ifneq (,$(findstring Haiku,$(OSTYPE)))
          OS_CCDEFS += -DUSE_READER_THREAD -DSIM_ASYNCH_IO 
          $(info using libpthread: $(call find_include,pthread))
        else
          ifeq (Darwin,$(OSTYPE))
            OS_CCDEFS += -DUSE_READER_THREAD -DSIM_ASYNCH_IO 
            OS_LDFLAGS += -lpthread
            $(info using macOS libpthread: $(call find_include,pthread))
          endif
        endif
      endif
      LIBEXT = $(LIBEXTSAVE)
    endif
  endif
  # Find PCRE RegEx library.
  ifneq (,$(call find_include,pcre))
    ifneq (,$(call find_lib,pcre))
      OS_CCDEFS += -DHAVE_PCRE_H
      OS_LDFLAGS += -lpcre
      $(info using libpcre: $(call find_lib,pcre) $(call find_include,pcre))
      ifeq ($(LD_SEARCH_NEEDED),$(call need_search,pcre))
        OS_LDFLAGS += -L$(dir $(call find_lib,pcre))
      endif
    endif
  endif
  # Find available ncurses library.
  ifneq (,$(call find_include,ncurses))
    ifneq (,$(call find_lib,ncurses))
      OS_CURSES_DEFS += -DHAVE_NCURSES -lncurses
    endif
  endif
  ifneq (,$(call find_include,semaphore))
    ifneq (, $(shell grep sem_timedwait $(call find_include,semaphore)))
      OS_CCDEFS += -DHAVE_SEMAPHORE
      $(info using semaphore: $(call find_include,semaphore))
    endif
  endif
  ifneq (,$(call find_include,sys/ioctl))
    OS_CCDEFS += -DHAVE_SYS_IOCTL
  endif
  ifneq (,$(call find_include,linux/cdrom))
    OS_CCDEFS += -DHAVE_LINUX_CDROM
  endif
  ifneq (,$(call find_include,dlfcn))
    ifneq (,$(call find_lib,dl))
      OS_CCDEFS += -DSIM_HAVE_DLOPEN=$(LIBSOEXT)
      OS_LDFLAGS += -ldl
      $(info using libdl: $(call find_lib,dl) $(call find_include,dlfcn))
    else
      ifneq (,$(findstring BSD,$(OSTYPE))$(findstring AIX,$(OSTYPE))$(findstring Haiku,$(OSTYPE)))
        OS_CCDEFS += -DSIM_HAVE_DLOPEN=so
        $(info using libdl: $(call find_include,dlfcn))
      else
        ifneq (,$(call find_lib,dld))
          OS_CCDEFS += -DSIM_HAVE_DLOPEN=$(LIBSOEXT)
          OS_LDFLAGS += -ldld
          $(info using libdld: $(call find_lib,dld) $(call find_include,dlfcn))
        else
          ifeq (Darwin,$(OSTYPE))
            OS_CCDEFS += -DSIM_HAVE_DLOPEN=dylib
            $(info using macOS dlopen with .dylib)
          endif
        endif
      endif
    endif
  endif
  ifneq (,$(call find_include,utime))
    OS_CCDEFS += -DHAVE_UTIME
  endif
  ifneq (,$(call find_include,png))
    ifneq (,$(call find_lib,png))
      OS_CCDEFS += -DHAVE_LIBPNG
      OS_LDFLAGS += -lpng
      $(info using libpng: $(call find_lib,png) $(call find_include,png))
      ifneq (,$(call find_include,zlib))
        ifneq (,$(call find_lib,z))
          OS_CCDEFS += -DHAVE_ZLIB
          OS_LDFLAGS += -lz
          $(info using zlib: $(call find_lib,z) $(call find_include,zlib))
        endif
      endif
    endif
  endif
  ifneq (,$(call find_include,glob))
    OS_CCDEFS += -DHAVE_GLOB
  else
    ifneq (,$(call find_include,fnmatch))
      OS_CCDEFS += -DHAVE_FNMATCH    
    endif
  endif
  ifneq (,$(call find_include,sys/mman))
    ifneq (,$(shell grep shm_open $(call find_include,sys/mman)))
      # some Linux installs have been known to have the include, but are
      # missing librt (where the shm_ APIs are implemented on Linux)
      # other OSes seem have these APIs implemented elsewhere
      ifneq (,$(if $(findstring Linux,$(OSTYPE)),$(call find_lib,rt),OK))
        OS_CCDEFS += -DHAVE_SHM_OPEN
        $(info using mman: $(call find_include,sys/mman))
      endif
    endif
  endif
  ifneq (,$(NETWORK_USEFUL))
    ifneq (,$(call find_include,pcap))
      ifneq (,$(shell grep 'pcap/pcap.h' $(call find_include,pcap) | grep include))
        PCAP_H_PATH = $(dir $(call find_include,pcap))pcap/pcap.h
      else
        PCAP_H_PATH = $(call find_include,pcap)
      endif
      ifneq (,$(shell grep pcap_compile $(PCAP_H_PATH) | grep const))
        BPF_CONST_STRING = -DBPF_CONST_STRING
      endif
      NETWORK_CCDEFS += -DHAVE_PCAP_NETWORK -I$(dir $(call find_include,pcap)) $(BPF_CONST_STRING)
      NETWORK_LAN_FEATURES += PCAP
      ifneq (,$(call find_lib,$(PCAPLIB)))
        ifneq ($(USE_NETWORK),) # Network support specified on the GNU make command line
          NETWORK_CCDEFS += -DUSE_NETWORK
          ifeq (,$(findstring Linux,$(OSTYPE))$(findstring Darwin,$(OSTYPE)))
            $(info *** Warning ***)
            $(info *** Warning *** Statically linking against libpcap is provides no measurable)
            $(info *** Warning *** benefits over dynamically linking libpcap.)
            $(info *** Warning ***)
            $(info *** Warning *** Support for linking this way is currently deprecated and may be removed)
            $(info *** Warning *** in the future.)
            $(info *** Warning ***)
          else
            $(info *** Error ***)
            $(info *** Error *** Statically linking against libpcap is provides no measurable)
            $(info *** Error *** benefits over dynamically linking libpcap.)
            $(info *** Error ***)
            $(info *** Error *** Support for linking statically has been removed on the $(OSTYPE))
            $(info *** Error *** platform.)
            $(info *** Error ***)
            $(error Retry your build without specifying USE_NETWORK=1)
          endif
          ifeq (cygwin,$(OSTYPE))
            # cygwin has no ldconfig so explicitly specify pcap object library
            NETWORK_LDFLAGS = -L$(dir $(call find_lib,$(PCAPLIB))) -Wl,-R,$(dir $(call find_lib,$(PCAPLIB))) -l$(PCAPLIB)
          else
            NETWORK_LDFLAGS = -l$(PCAPLIB)
          endif
          $(info using libpcap: $(call find_lib,$(PCAPLIB)) $(call find_include,pcap))
          NETWORK_FEATURES = - static networking support using $(OSNAME) provided libpcap components
        else # default build uses dynamic libpcap
          NETWORK_CCDEFS += -DUSE_SHARED
          $(info using libpcap: $(call find_include,pcap))
          NETWORK_FEATURES = - dynamic networking support using $(OSNAME) provided libpcap components
        endif
      else
        LIBEXTSAVE := ${LIBEXT}
        LIBEXT = a
        ifneq (,$(call find_lib,$(PCAPLIB)))
          NETWORK_CCDEFS += -DUSE_NETWORK
          NETWORK_LDFLAGS := -L$(dir $(call find_lib,$(PCAPLIB))) -l$(PCAPLIB)
          NETWORK_FEATURES = - static networking support using $(OSNAME) provided libpcap components
          $(info using libpcap: $(call find_lib,$(PCAPLIB)) $(call find_include,pcap))
        endif
        LIBEXT = $(LIBEXTSAVE)
        ifeq (Darwin,$(OSTYPE)$(findstring USE_,$(NETWORK_CCDEFS)))
          NETWORK_CCDEFS += -DUSE_SHARED
          NETWORK_FEATURES = - dynamic networking support using $(OSNAME) provided libpcap components
          $(info using macOS dynamic libpcap: $(call find_include,pcap))
        endif
      endif
    else
      # On non-Linux platforms, we'll still try to provide deprecated support for libpcap in /usr/local
      INCPATHSAVE := ${INCPATH}
      ifeq (,$(findstring Linux,$(OSTYPE)))
        # Look for package built from tcpdump.org sources with default install target (or cygwin winpcap)
        INCPATH += /usr/local/include
        PCAP_H_FOUND = $(call find_include,pcap)
      endif
      ifneq (,$(strip $(PCAP_H_FOUND)))
        ifneq (,$(shell grep 'pcap/pcap.h' $(call find_include,pcap) | grep include))
          PCAP_H_PATH = $(dir $(call find_include,pcap))pcap/pcap.h
        else
          PCAP_H_PATH = $(call find_include,pcap)
        endif
        ifneq (,$(shell grep pcap_compile $(PCAP_H_PATH) | grep const))
          BPF_CONST_STRING = -DBPF_CONST_STRING
        endif
        LIBEXTSAVE := ${LIBEXT}
        # first check if binary - shared objects are available/installed in the linker known search paths
        ifneq (,$(call find_lib,$(PCAPLIB)))
          NETWORK_CCDEFS = -DUSE_SHARED -I$(dir $(call find_include,pcap)) $(BPF_CONST_STRING)
          NETWORK_FEATURES = - dynamic networking support using libpcap components from www.tcpdump.org and locally installed libpcap.${LIBEXT}
          $(info using libpcap: $(call find_include,pcap))
        else
          LIBPATH += /usr/local/lib
          LIBEXT = a
          ifneq (,$(call find_lib,$(PCAPLIB)))
            $(info using libpcap: $(call find_lib,$(PCAPLIB)) $(call find_include,pcap))
            ifeq (cygwin,$(OSTYPE))
              NETWORK_CCDEFS = -DUSE_NETWORK -DHAVE_PCAP_NETWORK -I$(dir $(call find_include,pcap)) $(BPF_CONST_STRING)
              NETWORK_LDFLAGS = -L$(dir $(call find_lib,$(PCAPLIB))) -Wl,-R,$(dir $(call find_lib,$(PCAPLIB))) -l$(PCAPLIB)
              NETWORK_FEATURES = - static networking support using libpcap components located in the cygwin directories
            else
              NETWORK_CCDEFS := -DUSE_NETWORK -DHAVE_PCAP_NETWORK -isystem -I$(dir $(call find_include,pcap)) $(BPF_CONST_STRING) $(call find_lib,$(PCAPLIB))
              NETWORK_FEATURES = - networking support using libpcap components from www.tcpdump.org
              $(info *** Warning ***)
              $(info *** Warning *** $(BUILD_SINGLE)Simulator$(BUILD_MULTIPLE) being built with networking support using)
              $(info *** Warning *** libpcap components from www.tcpdump.org.)
              $(info *** Warning *** Some users have had problems using the www.tcpdump.org libpcap)
              $(info *** Warning *** components for simh networking.  For best results, with)
              $(info *** Warning *** simh networking, it is recommended that you install the)
              $(info *** Warning *** libpcap-dev (or libpcap-devel) package from your $(OSNAME) distribution)
              $(info *** Warning ***)
              $(info *** Warning *** Building with the components manually installed from www.tcpdump.org)
              $(info *** Warning *** is officially deprecated.  Attempting to do so is unsupported.)
              $(info *** Warning ***)
            endif
          else
            $(error using libpcap: $(call find_include,pcap) missing $(PCAPLIB).${LIBEXT})
          endif
          NETWORK_LAN_FEATURES += PCAP
        endif
        LIBEXT = $(LIBEXTSAVE)
      else
        INCPATH = $(INCPATHSAVE)
        $(info *** Warning ***)
        $(info *** Warning *** $(BUILD_SINGLE)Simulator$(BUILD_MULTIPLE) $(BUILD_MULTIPLE_VERB) being built WITHOUT)
        $(info *** Warning *** libpcap networking support)
        $(info *** Warning ***)
        $(info *** Warning *** To build simulator(s) with libpcap networking support you)
        ifneq (,$(and $(findstring Linux,$(OSTYPE)),$(call find_exe,apt-get)))
          $(info *** Warning *** should install the libpcap development components for)
          $(info *** Warning *** for your Linux system:)
          $(info *** Warning ***        $$ sudo apt-get install libpcap-dev)
        else
          $(info *** Warning *** should read 0readme_ethernet.txt and follow the instructions)
          $(info *** Warning *** regarding the needed libpcap development components for your)
          $(info *** Warning *** $(OSTYPE) platform)
        endif
        $(info *** Warning ***)
      endif
    endif
    # Consider other network connections
    ifneq (,$(call find_lib,vdeplug))
      # libvdeplug requires the use of the OS provided libpcap
      ifeq (,$(findstring usr/local,$(NETWORK_CCDEFS)))
        ifneq (,$(call find_include,libvdeplug))
          # Provide support for vde networking
          NETWORK_CCDEFS += -DHAVE_VDE_NETWORK
          NETWORK_LAN_FEATURES += VDE
          ifeq (,$(findstring USE_NETWORK,$(NETWORK_CCDEFS))$(findstring USE_SHARED,$(NETWORK_CCDEFS)))
            NETWORK_CCDEFS += -DUSE_NETWORK
          endif
          ifeq (Darwin,$(OSTYPE))
            NETWORK_LDFLAGS += -lvdeplug -L$(dir $(call find_lib,vdeplug))
          else
            NETWORK_LDFLAGS += -lvdeplug -Wl,-R,$(dir $(call find_lib,vdeplug)) -L$(dir $(call find_lib,vdeplug))
          endif
          $(info using libvdeplug: $(call find_lib,vdeplug) $(call find_include,libvdeplug))
        endif
      endif
    endif
    ifeq (,$(findstring HAVE_VDE_NETWORK,$(NETWORK_CCDEFS)))
      # Support is available on Linux for libvdeplug.  Advise on its usage
      ifneq (,$(findstring Linux,$(OSTYPE))$(findstring Darwin,$(OSTYPE)))
        ifneq (,$(findstring USE_NETWORK,$(NETWORK_CCDEFS))$(findstring USE_SHARED,$(NETWORK_CCDEFS)))
          $(info *** Info ***)
          $(info *** Info *** $(BUILD_SINGLE)Simulator$(BUILD_MULTIPLE) $(BUILD_MULTIPLE_VERB) being built with)
          $(info *** Info *** minimal libpcap networking support)
          $(info *** Info ***)
        endif
        $(info *** Info ***)
        $(info *** Info *** Simulators on your $(OSNAME) platform can also be built with)
        $(info *** Info *** extended LAN Ethernet networking support by using VDE Ethernet.)
        $(info *** Info ***)
        $(info *** Info *** To build simulator(s) with extended networking support you)
        ifeq (Darwin,$(OSTYPE))
          ifeq (/opt/local/bin/port,$(shell which port))
            $(info *** Info *** should install the MacPorts vde2 package to provide this)
            $(info *** Info *** functionality for your OS X system:)
            $(info *** Info ***       # port install vde2)
          endif
          ifeq (/usr/local/bin/brew,$(shell which brew))
            ifeq (/opt/local/bin/port,$(shell which port))
              $(info *** Info ***)
              $(info *** Info *** OR)
              $(info *** Info ***)
            endif
            $(info *** Info *** should install the HomeBrew vde package to provide this)
            $(info *** Info *** functionality for your OS X system:)
            $(info *** Info ***       $$ brew install vde)
          else
            ifeq (,$(shell which port))
              $(info *** Info *** should install MacPorts or HomeBrew and rerun this make for)
              $(info *** Info *** specific advice)
            endif
          endif
        else
          ifneq (,$(and $(findstring Linux,$(OSTYPE)),$(call find_exe,apt-get)))
            $(info *** Info *** should install the vde2 package to provide this)
            $(info *** Info *** functionality for your $(OSNAME) system:)
            ifneq (,$(shell apt list 2>/dev/null| grep libvdeplug-dev))
              $(info *** Info ***        $$ sudo apt-get install libvdeplug-dev)
            else
              $(info *** Info ***        $$ sudo apt-get install vde2)
            endif
          else
            $(info *** Info *** should read 0readme_ethernet.txt and follow the instructions)
            $(info *** Info *** regarding the needed libvdeplug components for your $(OSNAME))
            $(info *** Info *** platform)
          endif
        endif
        $(info *** Info ***)
      endif
    endif
    ifneq (,$(call find_include,linux/if_tun))
      # Provide support for Tap networking on Linux
      NETWORK_CCDEFS += -DHAVE_TAP_NETWORK
      NETWORK_LAN_FEATURES += TAP
      ifeq (,$(findstring USE_NETWORK,$(NETWORK_CCDEFS))$(findstring USE_SHARED,$(NETWORK_CCDEFS)))
        NETWORK_CCDEFS += -DUSE_NETWORK
      endif
    endif
    ifeq (bsdtuntap,$(shell if ${TEST} -e /usr/include/net/if_tun.h -o -e /Library/Extensions/tap.kext -o -e /Applications/Tunnelblick.app/Contents/Resources/tap-notarized.kext; then echo bsdtuntap; fi))
      # Provide support for Tap networking on BSD platforms (including OS X)
      NETWORK_CCDEFS += -DHAVE_TAP_NETWORK -DHAVE_BSDTUNTAP
      NETWORK_LAN_FEATURES += TAP
      ifeq (,$(findstring USE_NETWORK,$(NETWORK_CCDEFS))$(findstring USE_SHARED,$(NETWORK_CCDEFS)))
        NETWORK_CCDEFS += -DUSE_NETWORK
      endif
    endif
    ifeq (,$(findstring USE_NETWORK,$(NETWORK_CCDEFS))$(findstring USE_SHARED,$(NETWORK_CCDEFS))$(findstring HAVE_VDE_NETWORK,$(NETWORK_CCDEFS)))
      NETWORK_CCDEFS += -DUSE_NETWORK
      NETWORK_FEATURES = - WITHOUT Local LAN networking support
      $(info *** Warning ***)
      $(info *** Warning *** $(BUILD_SINGLE)Simulator$(BUILD_MULTIPLE) $(BUILD_MULTIPLE_VERB) being built WITHOUT LAN networking support)
      $(info *** Warning ***)
      $(info *** Warning *** To build simulator(s) with networking support you should read)
      $(info *** Warning *** 0readme_ethernet.txt and follow the instructions regarding the)
      $(info *** Warning *** needed libpcap components for your $(OSTYPE) platform)
      $(info *** Warning ***)
    endif
    NETWORK_OPT = $(NETWORK_CCDEFS)
  endif
  ifneq (binexists,$(shell if ${TEST} -e BIN/buildtools; then echo binexists; fi))
    MKDIRBIN = @mkdir -p BIN/buildtools
  endif
  ifeq (commit-id-exists,$(shell if ${TEST} -e .git-commit-id; then echo commit-id-exists; fi))
    GIT_COMMIT_ID=$(shell grep 'SIM_GIT_COMMIT_ID' .git-commit-id | awk '{ print $$2 }')
    GIT_COMMIT_TIME=$(shell grep 'SIM_GIT_COMMIT_TIME' .git-commit-id | awk '{ print $$2 }')
  else
    ifeq (,$(shell grep 'define SIM_GIT_COMMIT_ID' src/scp/sim_rev.h | grep 'Format:'))
      GIT_COMMIT_ID=$(shell grep 'define SIM_GIT_COMMIT_ID' src/scp/sim_rev.h | awk '{ print $$3 }')
      GIT_COMMIT_TIME=$(shell grep 'define SIM_GIT_COMMIT_TIME' src/scp/sim_rev.h | awk '{ print $$3 }')
    else
      ifeq (git-submodule,$(if $(shell cd .. ; git rev-parse --git-dir 2>/dev/null),git-submodule))
        GIT_COMMIT_ID=$(shell cd .. ; git submodule status | grep " $(notdir $(realpath .)) " | awk '{ print $$1 }')
        GIT_COMMIT_TIME=$(shell git --git-dir=$(realpath .)/.git log $(GIT_COMMIT_ID) -1 --pretty="%aI")
      else
        $(info *** Error ***)
        $(info *** Error *** The simh git commit id can not be determined.)
        $(info *** Error ***)
        $(info *** Error *** There are ONLY two supported ways to acquire and build)
        $(info *** Error *** the simh source code:)
        $(info *** Error ***   1: directly with git via:)
        $(info *** Error ***      $$ git clone https://github.com/simh/simh)
        $(info *** Error ***      $$ cd simh)
        $(info *** Error ***      $$ make {simulator-name})
        $(info *** Error *** OR)
        $(info *** Error ***   2: download the source code zip archive from:)
        $(info *** Error ***      $$ wget(or via browser) https://github.com/simh/simh/archive/master.zip)
        $(info *** Error ***      $$ unzip master.zip)
        $(info *** Error ***      $$ cd simh-master)
        $(info *** Error ***      $$ make {simulator-name})
        $(info *** Error ***)
        $(error get simh source either with zip download or git clone)
      endif
    endif
  endif
else
  #Win32 Environments (via MinGW32)
  GCC := gcc
  GCC_Path := $(abspath $(dir $(word 1,$(wildcard $(addsuffix /${GCC}.exe,$(subst ;, ,${PATH}))))))
  ifeq (rename-build-support,$(shell if exist ..\windows-build-windows-build echo rename-build-support))
    REMOVE_OLD_BUILD := $(shell if exist ..\windows-build rmdir/s/q ..\windows-build)
    FIXED_BUILD := $(shell move ..\windows-build-windows-build ..\windows-build >NUL)
  endif
  GCC_VERSION = $(word 3,$(shell ${GCC} --version))
  COMPILER_NAME = GCC Version: $(GCC_VERSION)
  ifeq (,$(findstring ++,${GCC}))
    CC_STD = -std=gnu99
  else
    CPP_BUILD = 1
  endif
  LTO_EXCLUDE_VERSIONS = 4.5.2
  ifeq (,$(PATH_SEPARATOR))
    PATH_SEPARATOR := ;
  endif
  INCPATH = $(abspath $(wildcard $(GCC_Path)\..\include $(subst $(PATH_SEPARATOR), ,$(CPATH))  $(subst $(PATH_SEPARATOR), ,$(C_INCLUDE_PATH))))
  LIBPATH = $(abspath $(wildcard $(GCC_Path)\..\lib $(subst :, ,$(LIBRARY_PATH))))
  $(info lib paths are: ${LIBPATH})
  $(info include paths are: ${INCPATH})
  # Give preference to any MinGW provided threading (if available)
  ifneq (,$(call find_include,pthread))
    PTHREADS_CCDEFS = -DUSE_READER_THREAD -DSIM_ASYNCH_IO
    PTHREADS_LDFLAGS = -lpthread
  else
    ifeq (pthreads,$(shell if exist ..\windows-build\pthreads\Pre-built.2\include\pthread.h echo pthreads))
      PTHREADS_CCDEFS = -DUSE_READER_THREAD -DPTW32_STATIC_LIB -D_POSIX_C_SOURCE -I../windows-build/pthreads/Pre-built.2/include -DSIM_ASYNCH_IO
      PTHREADS_LDFLAGS = -lpthreadGC2 -L..\windows-build\pthreads\Pre-built.2\lib
    endif
  endif
  ifeq (pcap,$(shell if exist ..\windows-build\winpcap\Wpdpack\include\pcap.h echo pcap))
    NETWORK_LDFLAGS =
    NETWORK_OPT = -DUSE_SHARED -I../windows-build/winpcap/Wpdpack/include
    NETWORK_FEATURES = - dynamic networking support using windows-build provided libpcap components
    NETWORK_LAN_FEATURES += PCAP
  else
    ifneq (,$(call find_include,pcap))
      NETWORK_LDFLAGS =
      NETWORK_OPT = -DUSE_SHARED
      NETWORK_FEATURES = - dynamic networking support using libpcap components found in the MinGW directories
      NETWORK_LAN_FEATURES += PCAP
    endif
  endif
  OS_CCDEFS += -fms-extensions $(PTHREADS_CCDEFS)
  OS_LDFLAGS += -lm -lwsock32 -lwinmm $(PTHREADS_LDFLAGS)
  EXE = .exe
  ifneq (clean,${MAKECMDGOALS})
    ifneq (buildtoolsexists,$(shell if exist BIN\buildtools (echo buildtoolsexists) else (mkdir BIN\buildtools)))
      MKDIRBIN=
    endif
  endif
  ifneq ($(USE_NETWORK),)
    NETWORK_OPT += -DUSE_SHARED
  endif
  ifeq (git-repo,$(shell if exist .git echo git-repo))
    GIT_PATH := $(shell where git)
    ifeq (,$(GIT_PATH))
      $(error building using a git repository, but git is not available)
    endif
    ifeq (commit-id-exists,$(shell if exist .git-commit-id echo commit-id-exists))
      CURRENT_GIT_COMMIT_ID=$(shell for /F "tokens=2" %%i in ("$(shell findstr /C:"SIM_GIT_COMMIT_ID" .git-commit-id)") do echo %%i)
      ifneq (, $(shell git update-index --refresh --))
        ACTUAL_GIT_COMMIT_EXTRAS=+uncommitted-changes
      endif
      ACTUAL_GIT_COMMIT_ID=$(strip $(shell git log -1 --pretty=%H))$(ACTUAL_GIT_COMMIT_EXTRAS)
      ifneq ($(CURRENT_GIT_COMMIT_ID),$(ACTUAL_GIT_COMMIT_ID))
        NEED_COMMIT_ID = need-commit-id
        # make sure that the invalidly formatted .git-commit-id file wasn't generated
        # by legacy git hooks which need to be removed.
        $(shell if exist .git\hooks\post-checkout del .git\hooks\post-checkout)
        $(shell if exist .git\hooks\post-commit   del .git\hooks\post-commit)
        $(shell if exist .git\hooks\post-merge    del .git\hooks\post-merge)
      endif
    else
      NEED_COMMIT_ID = need-commit-id
    endif
    ifeq (need-commit-id,$(NEED_COMMIT_ID))
      ifneq (, $(shell git update-index --refresh --))
        ACTUAL_GIT_COMMIT_EXTRAS=+uncommitted-changes
      endif
      ACTUAL_GIT_COMMIT_ID=$(strip $(shell git log -1 --pretty=%H))$(ACTUAL_GIT_COMMIT_EXTRAS)
      isodate=$(shell git log -1 --pretty=%ai)
      commit_time=$(word 1,$(isodate))T$(word 2,$(isodate))$(word 3,$(isodate))
      $(shell echo SIM_GIT_COMMIT_ID $(ACTUAL_GIT_COMMIT_ID)>.git-commit-id)
      $(shell echo SIM_GIT_COMMIT_TIME $(commit_time)>>.git-commit-id)
    endif
  endif
  ifneq (,$(shell if exist .git-commit-id echo git-commit-id))
    GIT_COMMIT_ID=$(shell for /F "tokens=2" %%i in ("$(shell findstr /C:"SIM_GIT_COMMIT_ID" .git-commit-id)") do echo %%i)
    GIT_COMMIT_TIME=$(shell for /F "tokens=2" %%i in ("$(shell findstr /C:"SIM_GIT_COMMIT_TIME" .git-commit-id)") do echo %%i)
  else
    ifeq (,$(shell findstr /C:"define SIM_GIT_COMMIT_ID" src/scp/sim_rev.h | findstr Format))
      GIT_COMMIT_ID=$(shell for /F "tokens=3" %%i in ("$(shell findstr /C:"define SIM_GIT_COMMIT_ID" src/scp/sim_rev.h)") do echo %%i)
      GIT_COMMIT_TIME=$(shell for /F "tokens=3" %%i in ("$(shell findstr /C:"define SIM_GIT_COMMIT_TIME" src/scp/sim_rev.h)") do echo %%i)
    endif
  endif
  ifneq (windows-build,$(shell if exist ..\windows-build\README.md echo windows-build))
    ifneq (,$(GIT_PATH))
      $(info Cloning the windows-build dependencies into $(abspath ..)/windows-build)
      $(shell git clone https://github.com/simh/windows-build ../windows-build)
    else
      $(info ***********************************************************************)
      $(info ***********************************************************************)
      $(info **  This build is operating without the required windows-build       **)
      $(info **  components and therefore will produce less than optimal          **)
      $(info **  simulator operation and features.                                **)
      $(info **  Download the file:                                               **)
      $(info **  https://github.com/simh/windows-build/archive/windows-build.zip  **)
      $(info **  Extract the windows-build-windows-build folder it contains to    **)
      $(info **  $(abspath ..\)                                                   **)
      $(info ***********************************************************************)
      $(info ***********************************************************************)
      $(info .)
    endif
  else
    # Version check on windows-build
    WINDOWS_BUILD = $(word 2,$(shell findstr WINDOWS-BUILD ..\windows-build\Windows-Build_Versions.txt))
    ifeq (,$(WINDOWS_BUILD))
      WINDOWS_BUILD = 00000000
    endif
    ifneq (,$(or $(shell if 20190124 GTR $(WINDOWS_BUILD) echo old-windows-build),$(and $(shell if 20171112 GTR $(WINDOWS_BUILD) echo old-windows-build),$(findstring pthreadGC2,$(PTHREADS_LDFLAGS)))))
      $(info .)
      $(info windows-build components at: $(abspath ..\windows-build))
      $(info .)
      $(info ***********************************************************************)
      $(info ***********************************************************************)
      $(info **  This currently available windows-build components are out of     **)
      ifneq (,$(GIT_PATH))
        $(info **  date.  You need to update to the latest windows-build            **)
        $(info **  dependencies by executing these commands:                        **)
        $(info **                                                                   **)
        $(info **    > cd ..\windows-build                                          **)
        $(info **    > git pull                                                     **)
        $(info **                                                                   **)
        $(info ***********************************************************************)
        $(info ***********************************************************************)
        $(error .)
      else
        $(info **  date.  For the most functional and stable features you shoud     **)
        $(info **  Download the file:                                               **)
        $(info **  https://github.com/simh/windows-build/archive/windows-build.zip  **)
        $(info **  Extract the windows-build-windows-build folder it contains to    **)
        $(info **  $(abspath ..\)                                                   **)
        $(info ***********************************************************************)
        $(info ***********************************************************************)
        $(info .)
        $(error Update windows-build)
      endif
    endif
    ifeq (pcre,$(shell if exist ..\windows-build\PCRE\include\pcre.h echo pcre))
      OS_CCDEFS += -DHAVE_PCRE_H -DPCRE_STATIC -I$(abspath ../windows-build/PCRE/include)
      OS_LDFLAGS += -lpcre -L../windows-build/PCRE/lib/
      $(info using libpcre: $(abspath ../windows-build/PCRE/lib/pcre.a) $(abspath ../windows-build/PCRE/include/pcre.h))
    endif
  endif
  ifneq (,$(call find_include,ddk/ntdddisk))
    CFLAGS_I = -DHAVE_NTDDDISK_H
  endif
endif # Win32 (via MinGW)
ifneq (,$(GIT_COMMIT_ID))
  CFLAGS_GIT = -DSIM_GIT_COMMIT_ID=$(GIT_COMMIT_ID)
endif
ifneq (,$(GIT_COMMIT_TIME))
  CFLAGS_GIT += -DSIM_GIT_COMMIT_TIME=$(GIT_COMMIT_TIME)
endif
ifneq (,$(UNSUPPORTED_BUILD))
  CFLAGS_GIT += -DSIM_BUILD=Unsupported=$(UNSUPPORTED_BUILD)
endif
ifneq ($(DEBUG),)
  CFLAGS_G = -g -ggdb -g3
  CFLAGS_O = -O0
  BUILD_FEATURES = - debugging support
else
  ifneq (,$(findstring clang,$(COMPILER_NAME))$(findstring LLVM,$(COMPILER_NAME)))
    CFLAGS_O = -O2 -fno-strict-overflow
    GCC_OPTIMIZERS_CMD = ${GCC} --help
    NO_LTO = 1
  else
    NO_LTO = 1
    ifeq (Darwin,$(OSTYPE))
      CFLAGS_O += -O4 -flto -fwhole-program
    else
      CFLAGS_O := -O2
    endif
  endif
  LDFLAGS_O = 
  GCC_MAJOR_VERSION = $(firstword $(subst  ., ,$(GCC_VERSION)))
  ifneq (3,$(GCC_MAJOR_VERSION))
    ifeq (,$(GCC_OPTIMIZERS_CMD))
      GCC_OPTIMIZERS_CMD = ${GCC} --help=optimizers
      GCC_COMMON_CMD = ${GCC} --help=common
    endif
  endif
  ifneq (,$(GCC_OPTIMIZERS_CMD))
    GCC_OPTIMIZERS = $(shell $(GCC_OPTIMIZERS_CMD))
  endif
  ifneq (,$(GCC_COMMON_CMD))
    GCC_OPTIMIZERS += $(shell $(GCC_COMMON_CMD))
  endif
  ifneq (,$(findstring $(GCC_VERSION),$(LTO_EXCLUDE_VERSIONS)))
    NO_LTO = 1
  endif
  ifneq (,$(findstring -finline-functions,$(GCC_OPTIMIZERS)))
    CFLAGS_O += -finline-functions
  endif
  ifneq (,$(findstring -fgcse-after-reload,$(GCC_OPTIMIZERS)))
    CFLAGS_O += -fgcse-after-reload
  endif
  ifneq (,$(findstring -fpredictive-commoning,$(GCC_OPTIMIZERS)))
    CFLAGS_O += -fpredictive-commoning
  endif
  ifneq (,$(findstring -fipa-cp-clone,$(GCC_OPTIMIZERS)))
    CFLAGS_O += -fipa-cp-clone
  endif
  ifneq (,$(findstring -funsafe-loop-optimizations,$(GCC_OPTIMIZERS)))
    CFLAGS_O += -fno-unsafe-loop-optimizations
  endif
  ifneq (,$(findstring -fstrict-overflow,$(GCC_OPTIMIZERS)))
    CFLAGS_O += -fno-strict-overflow
  endif
  ifeq (,$(NO_LTO))
    ifneq (,$(findstring -flto,$(GCC_OPTIMIZERS)))
      CFLAGS_O += -flto -fwhole-program
      LDFLAGS_O += -flto -fwhole-program
    endif
  endif
  BUILD_FEATURES = - compiler optimizations and no debugging support
endif
ifneq (3,$(GCC_MAJOR_VERSION))
  ifeq (,$(GCC_WARNINGS_CMD))
    GCC_WARNINGS_CMD = ${GCC} --help=warnings
  endif
endif
ifneq (clean,${MAKECMDGOALS})
  BUILD_FEATURES := $(BUILD_FEATURES). $(COMPILER_NAME)
  $(info ***)
  $(info *** $(BUILD_SINGLE)Simulator$(BUILD_MULTIPLE) being built with:)
  $(info *** $(BUILD_FEATURES).)
  ifneq (,$(NETWORK_FEATURES))
    $(info *** $(NETWORK_FEATURES).)
  endif
  ifneq (,$(NETWORK_LAN_FEATURES))
    $(info *** - Local LAN packet transports: $(NETWORK_LAN_FEATURES))
  endif
  ifneq (,$(TESTING_FEATURES))
    $(info *** $(TESTING_FEATURES).)
  endif
  ifneq (,$(GIT_COMMIT_ID))
    $(info ***)
    $(info *** git commit id is $(GIT_COMMIT_ID).)
    $(info *** git commit time is $(GIT_COMMIT_TIME).)
  endif
  $(info ***)
endif
ifneq ($(DONT_USE_READER_THREAD),)
  NETWORK_OPT += -DDONT_USE_READER_THREAD
endif

CC_OUTSPEC = -o $@
CC := ${GCC} ${CC_STD} -U__STRICT_ANSI__ ${CFLAGS_G} ${CFLAGS_O} ${CFLAGS_GIT} ${CFLAGS_I} -DSIM_COMPILER="${COMPILER_NAME}" -DSIM_BUILD_TOOL=simh-makefile -I ./src/scp/ ${OS_CCDEFS} ${ROMS_OPT}
ifneq (,${SIM_VERSION_MODE})
  CC += -DSIM_VERSION_MODE="${SIM_VERSION_MODE}"
endif
LDFLAGS := ${OS_LDFLAGS} ${NETWORK_LDFLAGS} ${LDFLAGS_O}

SRCD = ./src

#
# Common Libraries
#
BIN = BIN/
SIMHD = ${SRCD}/scp
SIM = ${SIMHD}/scp.c ${SIMHD}/sim_console.c ${SIMHD}/sim_fio.c \
	${SIMHD}/sim_timer.c ${SIMHD}/sim_sock.c ${SIMHD}/sim_tmxr.c \
	${SIMHD}/sim_ether.c ${SIMHD}/sim_tape.c ${SIMHD}/sim_disk.c \
	${SIMHD}/sim_serial.c 

SCSI = ${SIMHD}/sim_scsi.c

#
# Emulator source files and compile time options
#
ATT3B2D = ${SRCD}/3B2

ATT3B2M400 = ${ATT3B2D}/3b2_cpu.c ${ATT3B2D}/3b2_sys.c \
	${ATT3B2D}/3b2_rev2_sys.c ${ATT3B2D}/3b2_rev2_mmu.c \
	${ATT3B2D}/3b2_mau.c ${ATT3B2D}/3b2_rev2_csr.c \
	${ATT3B2D}/3b2_timer.c ${ATT3B2D}/3b2_stddev.c \
	${ATT3B2D}/3b2_mem.c ${ATT3B2D}/3b2_iu.c \
	${ATT3B2D}/3b2_if.c ${ATT3B2D}/3b2_id.c \
	${ATT3B2D}/3b2_dmac.c ${ATT3B2D}/3b2_io.c \
	${ATT3B2D}/3b2_ports.c ${ATT3B2D}/3b2_ctc.c \
	${ATT3B2D}/3b2_ni.c
ATT3B2M400_OPT = -DUSE_INT64 -DUSE_ADDR64 -DREV2 -I ${ATT3B2D} ${NETWORK_OPT}

ATT3B2M600 = ${ATT3B2D}/3b2_cpu.c ${ATT3B2D}/3b2_sys.c \
	${ATT3B2D}/3b2_rev3_sys.c ${ATT3B2D}/3b2_rev3_mmu.c \
	${ATT3B2D}/3b2_mau.c ${ATT3B2D}/3b2_rev3_csr.c \
	${ATT3B2D}/3b2_timer.c ${ATT3B2D}/3b2_stddev.c \
	${ATT3B2D}/3b2_mem.c ${ATT3B2D}/3b2_iu.c \
	${ATT3B2D}/3b2_if.c ${ATT3B2D}/3b2_dmac.c \
	${ATT3B2D}/3b2_io.c ${ATT3B2D}/3b2_ports.c \
	${ATT3B2D}/3b2_scsi.c ${ATT3B2D}/3b2_ni.c
ATT3B2M600_OPT = -DUSE_INT64 -DUSE_ADDR64 -DREV3 -I ${ATT3B2D} ${NETWORK_OPT}

#
# Build everything (not the unsupported/incomplete or experimental simulators)
#
ALL = 3b2-400 3b2-700

all : ${ALL}

clean :
ifeq (${WIN32},)
	${RM} -rf ${BIN}
else
	if exist BIN rmdir /s /q BIN
endif

#
# Individual builds
#

3b2-400 : ${BIN}3b2-400${EXE}
 
${BIN}3b2-400${EXE} : ${ATT3B2M400} ${SIM}
	${MKDIRBIN}
	${CC} ${ATT3B2M400} ${SIM} ${ATT3B2M400_OPT} ${CC_OUTSPEC} ${LDFLAGS}
ifneq (,$(call find_test,${ATT3B2D},3b2-400))
	$@ $(call find_test,${ATT3B2D},3b2-400) ${TEST_ARG}
endif

3b2-700 : ${BIN}3b2-700${EXE}

${BIN}3b2-700${EXE} : ${ATT3B2M600} ${SIM}
	${MKDIRBIN}
	${CC} ${ATT3B2M600} ${SCSI} ${SIM} ${ATT3B2M600_OPT} ${CC_OUTSPEC} ${LDFLAGS}
ifneq (,$(call find_test,${ATT3B2D},3b2-700))
	$@ $(call find_test,${ATT3B2D},3b2-700) ${TEST_ARG}
endif
