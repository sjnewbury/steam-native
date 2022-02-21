# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs multilib-minimal git-r3

DESCRIPTION="Open source implementation of the jpegxr image format standard"
HOMEPAGE="https://github.com/KDAB/jxrlib"
EGIT_REPO_URI="https://github.com/KDAB/jxrlib.git"
EGIT_BRANCH=cleanup
EGIT_COMMIT=75d4bb631143766f7dd80ad09dc1a8bc7db0a7c5

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="static-libs doc"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="app-arch/unzip"

S="${WORKDIR}/${P}"

src_prepare() {
	sed -i "s/-O/\$\{OPT\}/" Makefile || die # Respect custom CFLAGS
	sed -i "/install \$(DIR_BUILD)\/\$(ENCAPP)/d" Makefile || die # Don't always install applications (for multilib)
	sed -i "s/\$(DIR_INSTALL)\/lib/\$(DIR_INSTALL)\/\$(LIBDIR)/g" Makefile || die # LIBDIR setting for multilib
	sed -i "/install -m 644 doc/d" Makefile || die # Don't always install docs
	sed -i "s/\$(DIR_INSTALL)\/share\/doc\/jxr-\$(JXR_VERSION)//" Makefile || die # Don't install an empty doc directory
	sed -i "s/ranlib/$(tc-getRANLIB)/g" Makefile || die # Use correct ranlib when cross-compiling
	eapply_user
	multilib_copy_sources
}

multilib_src_compile() {
	endian=""
	if [ "$(tc-endian)" == "big" ]; then
		endian="1"
	fi
	emake SHARED=1 BIG_ENDIAN="${endian}" CC="$(tc-getCC)" OPT="${CFLAGS}"
	use static-libs && emake BIG_ENDIAN="${endian}" CC="$(tc-getCC)" OPT="${CFLAGS}"
}

multilib_src_install() {
	emake SHARED=1 DIR_INSTALL="${ED}/usr" LIBDIR="$(get_libdir)" install
	use static-libs && emake DIR_INSTALL="${ED}/usr" LIBDIR="$(get_libdir)" install
	multilib_is_native_abi && dobin build/JxrDecApp build/JxrEncApp
	sed -i "s|${ED}/usr|${ERROT}/usr|g" "${ED}/usr/$(get_libdir)/pkgconfig/libjxr.pc" || die
}

multilib_src_install_all() {
	use doc && dodoc "doc/JPEGXR_DPK_Spec_1.0.doc"
}
