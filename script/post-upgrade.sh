#!/bin/bash

PACKAGES_TO_REMOVE=(
    "app-admin/sudo"
    "x11-libs/gtk+:3"
    "x11-libs/gtk+:2"
    "dev-db/mariadb"
    "sys-fs/ntfs3g"
    "app-accessibility/at-spi2-core"
    "app-accessibility/at-spi2-atk"
    "sys-devel/base-gcc:4.7"
    "sys-devel/gcc:4.7"
    "net-print/cups"
    "dev-util/gtk-update-icon-cache"
    "dev-qt/qtscript"
    "dev-qt/qtchooser"
    "dev-qt/qtcore"
    "app-shells/zsh"
    "app-shells/zsh-pol-config"
    "dev-db/mysql-init-scripts"
    "dev-lang/ruby"
    "app-editors/vim"
    "dev-util/gtk-doc-am"
    "media-gfx/graphite2"
    "x11-apps/xset"
    "x11-themes/hicolor-icon-theme"
    "media-libs/tiff"
    "app-eselect/eselect-lcdfilter"
    "app-eselect/eselect-mesa"
    "app-eselect/eselect-opengl"
    "app-eselect/eselect-qtgraphicssystem"
    "x11-libs/pixman"
    "x11-libs/libvdpau"
    "x11-libs/libxshmfence"
    "x11-libs/libXxf86vm"
    "x11-libs/libXinerama"
    "x11-libs/libXdamage"
    "x11-libs/libXcursor"
    "x11-libs/libXfixes"
    "x11-libs/libXv"
    "x11-libs/libXcomposite"
    "x11-libs/libXrandr"
    "media-libs/jbig2dec"
    "dev-libs/libcroco"
    "app-text/qpdf"
    "media-fonts/urw-fonts"
    "app-text/libpaper"
    "dev-python/snakeoil"
    "dev-libs/atk"
    "dev-perl/DBI"
    "app-text/sgml-common"
    "sys-power/upower"
)

FILES_TO_REMOVE=(
   "/.viminfo"
   "/.history"
   "/.zcompdump"
   "/var/log/emerge.log"
   "/var/log/emerge-fetch.log"
)

PACKAGES_TO_ADD=(
    "app-eselect/eselect-bzimage"
    "app-text/pastebunz"
    "app-misc/sabayon-devkit"
    "app-admin/perl-cleaner"
    "sys-apps/grep"
    "sys-kernel/sabayon-sources"
    "app-misc/sabayon-version"
    "app-portage/layman"
    "app-portage/eix"
    "net-misc/rsync"
    "app-crypt/gnupg"
    "sys-devel/gcc"
    "sys-devel/base-gcc"
    "dev-vcs/git"
    "app-portage/gentoolkit"
    "net-misc/openssh"
    "sys-devel/automake"
    "app-admin/enman"
    "sys-devel/distcc"
)

rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept

# upgrading machine
equo up && equo u

# Handling install/removal of packages specified in env
equo rm --deep --configfiles --force-system "${PACKAGES_TO_REMOVE[@]}"
equo i "${PACKAGES_TO_ADD[@]}"

# Configuring layman
mkdir /etc/portage/repos.conf/
mkdir /var/lib/layman/
layman-updater -R

# Configuring repoman
mkdir -p /usr/portage/distfiles/ && wget http://www.gentoo.org/dtd/metadata.dtd -O /usr/portage/distfiles/metadata.dtd

# Upgrading kernel to latest version
kernel_target_pkg="sys-kernel/linux-sabayon"

available_kernel=$(equo match "${kernel_target_pkg}" -q --showslot)
echo
echo "@@ Upgrading kernel to ${available_kernel}"
echo
kernel-switcher switch "${available_kernel}" || exit 1

# now delete stale files in /lib/modules
for slink in $(find /lib/modules/ -type l); do
    if [ ! -e "${slink}" ]; then
        echo "Removing broken symlink: ${slink}"
        rm "${slink}" # ignore failure, best effort
        # check if parent dir is empty, in case, remove
        paren_slink=$(dirname "${slink}")
        paren_children=$(find "${paren_slink}")
        if [ -z "${paren_children}" ]; then
            echo "${paren_slink} is empty, removing"
            rmdir "${paren_slink}" # ignore failure, best effort
        fi
    fi
done

# Merging defaults configurations
echo -5 | equo conf update

pushd /opt/sabayon-build/conf/intel/portage

rm -rfv make.conf
ln -s make.conf.amd64 make.conf

popd

# Writing package list file
equo q list installed -qv > /etc/sabayon-pkglist

# Cleaning equo package cache
equo cleanup

# Cleanup Perl cruft
perl-cleaner --ph-clean

# remove SSH keys
rm -rf /etc/ssh/*_key*

# Configuring for build
echo "*" > /etc/eix-sync.conf
emerge-webrsync
eix-sync
echo "y" | layman -f -a sabayon
echo "y" | layman -f -a sabayon-distro

# remove LDAP keys
rm -f /etc/openldap/ssl/ldap.pem /etc/openldap/ssl/ldap.key \
/etc/openldap/ssl/ldap.csr /etc/openldap/ssl/ldap.crt

# Remove scripts
rm -rf /post-upgrade.sh

# Cleanup
rm -rf "${FILES_TO_REMOVE[@]}"
