# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

inherit autotools flag-o-matic toolchain-funcs

DESCRIPTION="Wrapper library around TRE that provides POSIX API"
HOMEPAGE="http://mingw-w64.sourceforge.net/"
SRC_URI="https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-libsystre/systre-${PV}.tar.xz?raw=true -> mingw64-libsystre.tar.xz"
#mirror://sourceforge/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v${PV}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="strip"

DEPEND="dev-util/mingw64-libtre"

S="${WORKDIR}/${PN/mingw64-lib}-${PV}"

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}
alt_prefix() {
	is_crosscompile && echo /usr/${CTARGET}
}

pkg_setup() {
	if [[ ${CBUILD} == ${CHOST} ]] && [[ ${CHOST} == ${CTARGET} ]] ; then
		die "Invalid configuration"
	fi
}

src_configure() {
	CHOST=${CTARGET} strip-unsupported-flags
	# Normally mingw-64 does not use dynamic linker.
	# But at configure time it uses $LDFLAGS.
	# When default -Wl,--hash-style=gnu is passed
	# __CTORS_LIST__ / __DTORS_LIST__ is mis-detected
	# for target ld and binaries crash at shutdown.
	filter-ldflags '-Wl,--hash-style=*'

	# By default configure tries to set --sysroot=${prefix}. We disable
	# this behaviour with --with-sysroot=no to use gcc's sysroot default.
	# That way we can cross-build mingw64-libsystre with cross-emerge.
	local prefix="${EPREFIX}"$(alt_prefix)/usr
	CHOST=${CTARGET} econf \
		--with-sysroot=no \
		--prefix="${prefix}" \
		--libdir="${prefix}"/lib
}

src_install() {
	default

	if is_crosscompile ; then
		# gcc is configured to look at specific hard-coded paths for mingw #419601
		dosym usr /usr/${CTARGET}/mingw
		dosym usr /usr/${CTARGET}/${CTARGET}
		dosym usr/include /usr/${CTARGET}/sys-include
	fi

	#rm -rf "${ED}/usr/share"
}
