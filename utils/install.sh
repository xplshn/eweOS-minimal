#!/bin/sh

mkdir -p tmpdir/rootfs

_logtxt "#### bootstrapping base system"

mount_overlay base

$RUNAS pacstrap -G -M -c -C ./pacman.ewe.conf ./tmpdir/rootfs linux linux-firmware musl filesystem dinit dinit-services tinyramfs limine pciutils ca-certs

export DBIN_TRACKERFILE=/tmp/dbin.tracker.json

# Install dbin and other tools
mkdir -p ./tmpdir/rootfs/bin ./tmpdir/rootfs/usr/bin ./tmpdir/rootfs/lib ./tmpdir/rootfs/usr/lib ./tmpdir/rootfs/usr/local/bin/
export DBIN_INSTALL_DIR=$PWD/tmpdir/rootfs/bin
$RUNAS curl -o ./tmpdir/rootfs/bin/dbin https://bin.ajam.dev/x86_64_Linux/dbin && $RUNAS chmod +x ./tmpdir/rootfs/bin/dbin
$RUNAS sh -c "./tmpdir/rootfs/bin/dbin https://bin.ajam.dev/x86_64_Linux/dbin add busybox/busybox fuse/fusermount bash"

# Install symlinks for BusyBox
$RUNAS "$DBIN_INSTALL_DIR/busybox" --install ./tmpdir/rootfs

# Clone and prepare pelf
$RUNAS ./tmpdir/rootfs/bin/dbin run gix clone https://github.com/xplshn/pelf && cd pelf

$RUNAS mkdir -p pacman.AppDir/usr/bin pacman.AppDir/usr/lib

# Copy pacman binaries and get their required libraries
$RUNAS cp ./assets/AppRun.multiBinary ./pacman.AppDir/AppRun
$RUNAS cp /usr/bin/pacman* ./pacman.AppDir/usr/bin
$RUNAS cp /bin/bash ./pacman.AppDir/usr/bin # DBIN installed this binary earlier, which means that it is static.
$RUNAS ./cmd/misc/getlibs /usr/bin/pacman ./pacman.AppDir/usr/lib
$RUNAS ./cmd/misc/getlibs /usr/bin/pacman-conf ./pacman.AppDir/usr/lib
$RUNAS ./cmd/misc/getlibs /usr/bin/pacman-db-upgrade ./pacman.AppDir/usr/lib
$RUNAS ./cmd/misc/getlibs /usr/bin/pacman-key ./pacman.AppDir/usr/lib

# Install dwarfs-tools and fuse in the rootfs
$RUNAS sh -c "DBIN_INSTALL_DIR=/usr/local/bin ../tmpdir/rootfs/bin/dbin add dwarfs-tools fuse/fusermount" && {
    $RUNAS ln -sfT /usr/local/bin/dwarfs-tools /usr/local/bin/dwarfs
    $RUNAS ln -sfT /usr/local/bin/dwarfs-tools /usr/local/bin/mkdwarfs
}

# Build AppBundle and link binaries
$RUNAS ./pelf-dwfs --add-appdir ./pacman.AppDir "pacman-$(date +"%d-%m-%Y")-xplshn" --output-to ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle && {
    $RUNAS ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman
    $RUNAS ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman-conf
    $RUNAS ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman-db-upgrade
    $RUNAS ln -sfT ../tmpdir/rootfs/usr/local/bin/pacman.AppBundle ../tmpdir/rootfs/usr/bin/pacman-key
    $RUNAS cp /etc/pacman.conf ../tmpdir/rootfs/etc
    $RUNAS mkdir -p ../tmpdir/rootfs/etc/pacman.d && $RUNAS curl -o ../tmpdir/rootfs/etc/pacman.d/mirrorlist https://raw.githubusercontent.com/eweOS/packages/refs/heads/pacman-mirrorlist/mirrorlist
}

cd ..

# Install additional packages from profile
#$RUNAS pacstrap -G -M -c -C ./pacman.ewe.conf ./tmpdir/rootfs $(xargs < profiles/$PROFILE/packages.txt)

# Check for target architecture-specific packages
#if [ -f profiles/$PROFILE/packages.$TARGET_ARCH.txt ]; then
#  $RUNAS pacstrap -G -M -c -C ./pacman.ewe.conf ./tmpdir/rootfs $(xargs < profiles/$PROFILE/packages.$TARGET_ARCH.txt)
#fi

umount_overlay
