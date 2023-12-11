# Patch OpenBSD bsd.rd with auto_install.conf & rc.firsttime

This is a very simple script that is used to create custom installation cd's and bsd.rd images for OpenBSD to be used with online provides (such as Vultr) to deploy fully configured instances.

The script does the following:
* Downloads a bsd.rd image from an openbsd mirror
* Extracts the filesystem portion of the ramdisk
* Mount the filesystem
* Patch the filesystem with auto_install
* Put the filesystem back into bsd.rd
* Create a `siteXX.tgz` with `rc.firsttime`
* Create a bootable ISO with the modified `bsd.rd` and `siteXX.tgz`

In order to preserve size the auto install configuration uses the 1st http
mirror and then uses the `siteXX.tgz` from the created CD. This way our CD and
`bsd.rd` are almost the same size.

NOTE: The script is really at its infantry and there is no error checking implemented currently.

## Using
* Clone the repo
* Change into the cloned repo and create a folder `fs/`
* Update `auto_install.conf` with a desired information about your specific install
* Place any files you want included into your images (usually `install.site` and `rc.firsttime`)
```sh
cp install.site fs/
mkdir fs/etc
cp rc.firsttime fs/etc
```

## Refs
* https://www.openbsd.org/faq/faq4.html#site
* https://github.com/ajacoutot/aws-openbsd
* https://github.com/joyent/openbsd-kvm-image-builder
* https://eradman.com/posts/openbsd-vps-installation.html
