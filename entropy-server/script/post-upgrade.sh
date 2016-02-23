#!/bin/bash

PACKAGES_TO_REMOVE=(
)

FILES_TO_REMOVE=(
   "/.viminfo"
   "/.history"
   "/.zcompdump"
   "/var/log/emerge.log"
   "/var/log/emerge-fetch.log"
)

PACKAGES_TO_ADD=(
    "sys-apps/entropy-server"
    "app-crypt/gnupg"
)

rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept

# upgrading machine
equo up && equo u

# Handling install/removal of packages specified in env
equo i "${PACKAGES_TO_ADD[@]}"

# Merging defaults configurations
echo -5 | equo conf update

# Writing package list file
equo q list installed -qv > /etc/sabayon-pkglist

# Cleaning equo package cache
equo cleanup

# Remove scripts
rm -rf /post-upgrade.sh

# Cleanup
rm -rf "${FILES_TO_REMOVE[@]}"
