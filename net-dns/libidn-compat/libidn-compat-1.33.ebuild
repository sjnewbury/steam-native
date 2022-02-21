# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit elisp-common libtool multilib-minimal

DESCRIPTION="Internationalized Domain Names (IDN) implementation"
HOMEPAGE="https://www.gnu.org/software/libidn/"
SRC_URI="mirror://gnu/libidn/${P/-compat}.tar.gz"

LICENSE="GPL-2 GPL-3 LGPL-3 ( Apache-2.0 )"
SLOT="0/12"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="nls"

COMMON_DEPEND="
	nls? ( >=virtual/libintl-0-r1[${MULTILIB_USEDEP}] )
"
DEPEND="
	${COMMON_DEPEND}
"
RDEPEND="
	${COMMON_DEPEND}
"
BDEPEND="
	nls? ( >=sys-devel/gettext-0.17 )
"

S=${WORKDIR}/${P/-compat}

src_prepare() {
	default
	elibtoolize  # for Solaris shared objects
}

multilib_src_configure() {
	local args=(
		--disable-java
		--disable-csharp
		$(use_enable nls)
		--disable-static
		--disable-valgrind-tests
		--with-lispdir="${EPREFIX}${SITELISP}/${PN}"
		--with-packager-bug-reports="https://bugs.gentoo.org"
		--with-packager-version="r${PR}"
		--with-packager="Gentoo"
	)

	ECONF_SOURCE=${S} econf "${args[@]}"
}

multilib_src_test() {
	# only run libidn specific tests and not gnulib tests (bug #539356)
	emake -C tests check
}

multilib_src_install() {
	dolib.so lib/.libs/libidn.so.*
}
