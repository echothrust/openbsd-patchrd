#!/bin/ksh
#
# Copyright (c) 2022 Pantelis Roditis <proditis@echothrust.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

if [ "$(uname)" != "OpenBSD" ]; then
	echo "ERROR: This script requires OpenBSD >=7.0"
	exit -1
fi

RELEASE=${1-"7.0"}
ARCH=${2-"amd64"}
FS=$(basename ${3-"fs"})
set -e
umask 022

_TS=$(date -u +%G%m%dT%H%M%SZ)
_WRKDIR=$(mktemp -d -p ${TMPDIR:=/tmp} bsd.rd-patch.XXXXXXXXXX)
_bsdrd=${_WRKDIR}/bsd.rd
_rdextract=${_WRKDIR}/bsd.rd.extract
_rdgz=false
_rdmnt=${_WRKDIR}/rdmnt
trap 'trap_handler' EXIT
trap exit HUP INT TERM
trap_handler()
{
	set +e
	echo "Leaving workdir: ${_WRKDIR}"
	#rm -f ${_WRKDIR}
  exit
}

_err()
{
	echo "$1"
	exit -1
}


type mkhybrid >/dev/null 2>&1 || _err "package \"cdrtools\" is not installed"

install -d "${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/"
ftp -o "${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/cdbr" https://cdn.openbsd.org/pub/OpenBSD/${RELEASE}/amd64/cdbr
ftp -o "${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/cdboot" https://cdn.openbsd.org/pub/OpenBSD/${RELEASE}/amd64/cdboot
ftp -o "${_WRKDIR}/bsd.rd" https://cdn.openbsd.org/pub/OpenBSD/${RELEASE}/amd64/bsd.rd
install auto_install.conf ${_WRKDIR}

# 6.9 onwards uses a compressed rd file
if [[ $(file -bi ${_bsdrd}) == "application/x-gzip" ]]; then
  mv ${_bsdrd} ${_bsdrd}.gz
  gunzip ${_bsdrd}.gz
  _rdgz=true
fi


rdsetroot -x ${_bsdrd} ${_rdextract}
_vndev=$(vnconfig ${_rdextract})
install -d ${_rdmnt}
mount /dev/${_vndev}a ${_rdmnt}
cp ${_WRKDIR}/*install* ${_rdmnt}
chmod +x ${_rdmnt}/install.sub
umount ${_rdmnt}
vnconfig -u ${_vndev}
rdsetroot ${_bsdrd} ${_rdextract}

if ${_rdgz}; then
  gzip ${_bsdrd}
  mv ${_bsdrd}.gz ${_bsdrd}
fi

cp "${_WRKDIR}/bsd.rd" "${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/"
if [ -d "${FS}" ]; then
	install -d ${_WRKDIR}/${FS}/etc
	rsync -a ${FS}/etc/ ${_WRKDIR}/${FS}/etc
	chown -R root.wheel ${_WRKDIR}/${FS}/etc
	chmod 0555 ${_WRKDIR}/${FS}/etc/rc.firsttime
	install -o root -g wheel -m 0555 ${FS}/install.site ${_WRKDIR}/${FS}
	(cd ${_WRKDIR}/${FS} && tar czphf ${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/site$(echo ${RELEASE}|sed 's/\.//').tgz .)
	(cd "${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/" && ls -T )|grep -v bsd.rd >${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/index.txt
fi

(cd ${_WRKDIR} && mkhybrid -a -R -T -L -l -d -D -N -o "OpenBSD-${RELEASE}-${FS}-${_TS}.iso" -v -v \
	-A "OpenBSD/${ARCH}	${RELEASE} echothrust Install CD" \
	-P "Copyright (c) $(date +%Y) Echothrust Solutions" \
	-p "Pantelis Roditis <proditis]at[echothrust.com>" \
	-V "OpenBSD/${ARCH}	${RELEASE} Install CD" \
	-b ${RELEASE}/${ARCH}/cdbr -c ${RELEASE}/${ARCH}/boot.catalog \
	"${_WRKDIR}/OpenBSD")

#(cd ${_WRKDIR} && mkisofs -J -R -no-emul-boot \
#    -V "OpenBSD/${ARCH} ${RELEASE} echothrust Install CD" \
#    -p "Pantelis Roditis <proditis]@[echothrust.com>" -b $RELEASE/${ARCH}/cdboot \
#    -o "OpenBSD-${RELEASE}-${_TS}.iso" "${_WRKDIR}/OpenBSD")

mv "${_WRKDIR}/OpenBSD-${RELEASE}-${FS}-${_TS}.iso" .
mv "${_WRKDIR}/bsd.rd" "bsd-${RELEASE}-${FS}-${_TS}.rd"
mv "${_WRKDIR}/OpenBSD/${RELEASE}/${ARCH}/site$(echo ${RELEASE}|sed 's/\.//').tgz" site$(echo ${RELEASE}|sed 's/\.//')-${_TS}.tgz

md5 "OpenBSD-${RELEASE}-${FS}-${_TS}.iso" "bsd-${RELEASE}-${FS}-${_TS}.rd" site$(echo ${RELEASE}|sed 's/\.//')-${_TS}.tgz |tee ${RELEASE}-${_TS}.md5
