#!/bin/bash
export ACCEPT_LICENSE=*
export ETP_NONINTERACTIVE=1

PACKAGES_TO_REMOVE=(
    "x11-libs/gtk+:3"
    "x11-libs/gtk+:2"
    "dev-db/mariadb"
    "sys-fs/ntfs3g"
    "app-accessibility/at-spi2-core"
    "app-accessibility/at-spi2-atk"
    "net-print/cups"
    "dev-util/gtk-update-icon-cache"
    "dev-qt/qtscript"
    # Remove qtchooser force removing of entropy. I disable it for now
    #"dev-qt/qtchooser"
    #"dev-qt/qtcore"
    "app-shells/zsh"
    "app-shells/zsh-pol-config"
    "dev-db/mysql-init-scripts"
    "dev-lang/ruby"
    "app-editors/vim"
    "dev-util/gtk-doc-am"
    "x11-apps/xset"
    "x11-themes/hicolor-icon-theme"
    "media-libs/tiff"
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
    "app-misc/sabayon-sark"
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
    "sys-apps/entropy-server"
)


check_brokenlinks () {

  wget https://raw.githubusercontent.com/Sabayon/devkit/develop/sabayon-brokenlinks -O /usr/bin/sabayon-brokenlinks
  chmod a+x /usr/bin/sabayon-brokenlinks

  sabayon-brokenlinks --force

  rm /usr/bin/sabayon-brokenlinks
}

update_mirrors_list () {

  wget https://raw.githubusercontent.com/Sabayon/sbi-tasks/master/infra/mirrors.yml -O /tmp/mirrors.yml
  wget https://raw.githubusercontent.com/Sabayon/sbi-tasks/master/infra/scripts/sabayon-repo-generator -O /tmp/sabayon-repo-generator
  chmod a+x /tmp/sabayon-repo-generator

  local f=""
  local descr=""
  local name=""
  local reposdir="/etc/entropy/repositories.conf.d"
  local repofiles=(
    "entropy_sabayon-limbo"
    "entropy_sabayonlinux.org"
    "entropy_sabayon-weekly"
  )

  for repo in ${repofiles[@]} ; do
    if [ -e "${reposdir}/${repo}" ] ; then
      f=${reposdir}/${repo}
    else
      f=${reposdir}/_${repo}
    fi

    if [[ ${repo} =~ .*limbo* ]] ; then
      descr="Sabayon Limbo Testing Repository"
    else
      descr="Sabayon Linux Official Repository"
    fi

    name=${repo//entropy_/}

    /tmp/sabayon-repo-generator --mirror-file /tmp/mirrors.yml --descr "${descr}" --name "${name}" --to "${f}"

  done

  rm -v /tmp/sabayon-repo-generator
  rm -v /tmp/mirrors.yml
}

update_mirrors_list

# Install enman for devel repo
equo i enman

# Add scr devel repository
enman add devel

# upgrading machine
equo up && equo u

# Handling install/removal of packages specified in env
for i in "${PACKAGES_TO_REMOVE[@]}"
do
	echo "===== Remove $i ====="
    equo rm --deep --configfiles --force-system "$i"
done

equo i "${PACKAGES_TO_ADD[@]}"

# Configuring layman
mkdir /etc/portage/repos.conf/
mkdir /var/lib/layman/
layman-updater -R

# Configuring repoman
mkdir -p /usr/portage/distfiles/ && wget http://www.gentoo.org/dtd/metadata.dtd -O /usr/portage/distfiles/metadata.dtd
chown -R root:portage /usr/portage/distfiles/
chmod g+w /usr/portage/distfiles/
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

check_brokenlinks

pushd /etc/portage
git fetch --all
git checkout master
git reset --hard origin/master

rm -rfv make.conf
ln -sf make.conf.amd64 make.conf

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
