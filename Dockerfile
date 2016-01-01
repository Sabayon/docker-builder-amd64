FROM sabayon/spinbase-amd64

MAINTAINER mudler <mudler@sabayonlinux.org>

# Set locales to en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Perform post-upgrade tasks (mirror sorting, updating repository db)
ADD ./script/post-upgrade.sh /post-upgrade.sh
RUN /bin/bash /post-upgrade.sh  && rm -rf /post-upgrade.sh
ADD ./script/depcheck /usr/local/bin/depcheck
# Adding our builder script that will run also as entrypoint
ADD ./script/builder /builder
RUN chmod +x /builder

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /

# Define standard volumes
VOLUME ["/usr/portage", "/usr/portage/distfiles", "/usr/portage/packages", "/var/lib/entropy/client/packages"]

# Define default command.
ENTRYPOINT ["/builder"]
