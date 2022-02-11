# Patch OpenBSD bsd.rd with auto_install.conf & rc.firsttime

The script does the following:
* Downloads a bsd.rd image from an openbsd mirror
* Extracts the filesystem portion of the ramdisk
* Mount the filesystem
* Patch the filesystem with auto_install
* Put the filesystem back into bsd.rd
* Create a `siteXX.tgz` with `rc.firsttime`
* Create a bootable cd with the modified `bsd.rd` and `siteXX.tgz`

In order to preserve size the auto install configuration uses the 1st http
mirror and then uses the siteXX.tgz from the created CD. This way our CD and
`bsd.rd` are almost the same size.

## Refs
* https://www.openbsd.org/faq/faq4.html#site
* https://github.com/ajacoutot/aws-openbsd
* https://github.com/joyent/openbsd-kvm-image-builder
* https://eradman.com/posts/openbsd-vps-installation.html
