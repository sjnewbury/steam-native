# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit multilib toolchain-funcs multilib-minimal flag-o-matic

DESCRIPTION="RTMP client, librtmp library intended to stream audio or video flash content"
HOMEPAGE="https://rtmpdump.mplayerhq.hu/"

# the library is LGPL-2.1, the command is GPL-2
LICENSE="LGPL-2.1"
SLOT="0"

DEPEND="
	>=net-libs/gnutls-2.12.23-r6[${MULTILIB_USEDEP},nettle(+)]
	dev-libs/nettle:0=[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${PN/-compat}-swf_vertification_type_2.patch"
	"${FILESDIR}/${PN/-compat}-swf_vertification_type_2_part_2.patch"
	"${FILESDIR}/${PN/-compat}-gnutls.patch"
)

if [[ ${PV} == *9999 ]] ; then
	SRC_URI=""
	EGIT_REPO_URI="https://git.ffmpeg.org/rtmpdump.git"
	inherit git-r3
else
	KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~mips ~ppc ~ppc64 ~riscv ~x86 ~amd64-linux ~x86-linux"
	SRC_URI="https://git.ffmpeg.org/gitweb/rtmpdump.git/snapshot/0fb1d9936fb25f0755bb8b4afc95db048efe4526.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN/-compat}-0fb1d99"
fi

src_prepare() {
	# fix #571106 by restoring pre-GCC5 inline semantics
	append-cflags -std=gnu89
	# fix Makefile ( bug #298535 , bug #318353 and bug #324513 )
	sed -i 's/\$(MAKEFLAGS)//g' Makefile \
		|| die "failed to fix Makefile"
	sed -i -e 's:OPT=:&-fPIC :' \
		-e 's:OPT:OPTS:' \
		-e 's:CFLAGS=.*:& $(OPT):' librtmp/Makefile \
		|| die "failed to fix Makefile"
	default
	multilib_copy_sources
}

multilib_src_compile() {
	crypto="GNUTLS"
	cd librtmp || die
	emake CC="$(tc-getCC)" LD="$(tc-getLD)" AR="$(tc-getAR)" \
		OPT="${CFLAGS}" XLDFLAGS="${LDFLAGS}" CRYPTO="${crypto}" SYS=posix
}

multilib_src_install() {
	dolib.so librtmp/librtmp.so.0
}
