#!/bin/env sh

mkdir -p tmpdir/rootfs

_logtxt "#### bootstrapping base system"

mount_overlay base

$RUNAS pacstrap -G -M -c -C ./pacman.ewe.conf ./tmpdir/rootfs linux linux-firmware musl filesystem busybox dinit dinit-services tinyramfs limine ca-certificates
$RUNAS sh -c "DBIN_INSTALL_DIR=$PWD/tmpdir/rootfs/bin curl -qsfSL "https://raw.githubusercontent.com/xplshn/dbin/master/stubdl" | sh -s -- add busybox/busybox dbin dwarfs-tools fuse/fusermount bash"
./tmpdir/rootfs/bin/dbin run gix clone https://github.com/xplshn/pelf && cd pelf {
  mkdir -p pacman.AppDir/usr/bin pacman.AppDir/usr/lib
  cp /usr/bin/pacman* ./pacman.AppDir/usr/bin
  ./cmd/misc/getlibs /usr/bin/pacman ./pacman.AppDir/usr/lib
  ./cmd/misc/getlibs /usr/bin/pacman-conf ./pacman.AppDir/usr/lib
  ./cmd/misc/getlibs /usr/bin/pacman-db-upgrade ./pacman.AppDir/usr/lib
  ./cmd/misc/getlibs /usr/bin/pacman-key ./pacman.AppDir/usr/lib
  DBIN_INSTALL_DIR=/usr/local/bin ../tmpdir/rootfs/bin/dbin add dwarfs-tools fuse/fusermount && {
    ln -sfT /usr/local/bin/dwarfs-tools /usr/local/bin/dwarfs
    ln -sfT /usr/local/bin/dwarfs-tools /usr/local/bin/mkdwarfs
  }
  ./pelf-dwfs --add-appdir ./pacman.AppDir "pacman-$(date +"%d-%m-%Y")-xplshn" --output-to ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle --embed-static-tools && {
    ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman
    ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman-conf
    ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman-db-upgrade
    ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman-key
    cp /etc/pacman.conf ../tmpdir/rootfs/etc
  }
}

umount_overlay

_logtxt "#### bootstrapping packages"

mount_overlay packages base

$RUNAS pacstrap -G -M -c -C ./pacman.ewe.conf ./tmpdir/rootfs `cat profiles/$PROFILE/packages.txt | xargs`

if [ -f profiles/$PROFILE/packages.$TARGET_ARCH.txt ]; then
  $RUNAS pacstrap -G -M -c -C ./pacman.ewe.conf ./tmpdir/rootfs `cat profiles/$PROFILE/packages.$TARGET_ARCH.txt | xargs`
fi

umount_overlay
