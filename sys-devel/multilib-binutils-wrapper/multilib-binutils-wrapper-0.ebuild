# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib

DESCRIPTION="Wrappers for binutils to be used on non-native CHOSTs"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"
SRC_URI=""
S=${WORKDIR}

LICENSE="public-domain"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RDEPEND="sys-devel/binutils:="

src_install() {
	local host_prefix=${CHOST}
	# stolen from sys-devel/gcc-config
	local linkers=(
		ld.bfd ld.gold ld
	)

	local assemblers=(
		as
	)

	local target_tools=(
		addr2line ar nm objcopy objdump
		ranlib dwp gdb size strings strip gprof
	)

	cd "${ESYSROOT}"/usr/bin || die
	shopt -s nullglob

	# same as toolchain.eclass
	: ${TARGET_DEFAULT_ABI:=${DEFAULT_ABI}}
	: ${TARGET_MULTILIB_ABIS:=${MULTILIB_ABIS}}
	local ABI t e
	for ABI in $(get_all_abis TARGET); do
		[[ ${ABI} == ${TARGET_DEFAULT_ABI} ]] && continue

		einfo "Creating linker wrappers for ${ABI} ..."
		for t in "${linkers[@]}"; do
			for e in ${host_prefix}[-]${t}{,-[0-9]*}; do
				local newname=$(get_abi_CHOST)-${e#${host_prefix}-}

				einfo "	${newname}"

				newbin - "${newname}" <<-_EOF_
					#!${EPREFIX}/bin/sh
					exec ${e} $(get_abi_LDFLAGS) "\${@}"
				_EOF_
			done
		done
		einfo "Creating assembler wrapper for ${ABI} ..."
		for t in "${assemblers[@]}"; do
			# Just uses a simple '--' switch for selecting ABI
			# without a '-m'
			for e in ${host_prefix}[-]${t}{,-[0-9]*}; do
				local newname=$(get_abi_CHOST)-${e#${host_prefix}-}

				einfo "	${newname}"

				newbin - "${newname}" <<-_EOF_
					#!${EPREFIX}/bin/sh
					exec ${e} \
					    $(get_abi_CFLAGS | \sed -ne 's/-m\(.*\)/--\1/p') \
					    "\${@}"
				_EOF_
			done
		done
		einfo "Creating other tool wrappers for ${ABI} ..."
		for t in "${target_tools[@]}"; do
			# A little more complicated since the BFD target
			# is in a slightly different format to the linker
			# switch: 32-bit and 64-bit are always appended
			# to elf and "-" is used instead of "_"
			# TODO: Is there a better way of getting ABi bits?
			for e in ${host_prefix}[-]${t}{,-[0-9]*}; do
				local newname=$(get_abi_CHOST)-${e#${host_prefix}-}
				local abi_bits=$(get_abi_CFLAGS | sed -ne 's/-m.*\([3,6][2,4]\)/\1/p')

				einfo "	${newname}"

				newbin - "${newname}" <<-_EOF_
					#!${EPREFIX}/bin/sh
					exec ${e} \
					    $(get_abi_LDFLAGS | \
					        sed -ne "s/-m.*\(elf\)_\(.*\)/--target=\1${abi_bits}-\2/p") \
					    "\${@}"
				_EOF_
			done
		done
	done

	shopt -u nullglob
}
