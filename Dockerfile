FROM sabayon/spinbase-amd64

MAINTAINER mudler <mudler@sabayonlinux.org>

# Set locales to en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TINI_VERSION v0.17.0

# Perform post-upgrade tasks (mirror sorting, updating repository db)
ADD ./script/post-upgrade.sh /post-upgrade.sh
RUN /bin/bash /post-upgrade.sh  && rm -rf /post-upgrade.sh
ADD ./script/depcheck /usr/local/bin/depcheck
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --verify /tini.asc

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /

# Define standard volumes
VOLUME ["/usr/portage", "/usr/portage/distfiles", "/usr/portage/packages", "/var/lib/entropy/client/packages"]

# Define default command.
ENTRYPOINT ["/tini", "--", "/usr/sbin/builder"]
