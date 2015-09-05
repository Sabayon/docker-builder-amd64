FROM sabayon/spinbase-amd64

MAINTAINER mudler <mudler@sabayonlinux.org>

# Perform post-upgrade tasks (mirror sorting, updating repository db)
ADD ./script/post-upgrade.sh /post-upgrade.sh
RUN /bin/bash /post-upgrade.sh  && rm -rf /post-upgrade.sh

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Adding our builder script that will run also as entrypoint
ADD ./script/builder /builder

# Define standard volumes
VOLUME ["/usr/portage", "/usr/portage/distfiles", "/usr/portage/packages", "/var/lib/entropy/client/packages"]

# Define default command.
#CMD ["/usr/bin/emerge"]
CMD ["/builder"]
