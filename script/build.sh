#!/bin/bash
set -o nounset
set -o errexit


docker build -t sabayon/builder-amd64 .
docker run sabayon/builder-amd64 true || true
docker export $( docker ps -aq | xargs echo | cut -d ' ' -f 1) | docker import - sabayon/builder-amd64-tmp


mkdir -p ~/image
mkdir -p ~/imagesquashed

cat <<- 'EOF' > ~/image/Dockerfile
FROM sabayon/builder-amd64-tmp
MAINTAINER mudler <mudler@sabayonlinux.org>
# Define standard volumes
VOLUME ["/usr/portage", "/usr/portage/distfiles", "/usr/portage/packages", "/var/lib/entropy/client/packages"]

# Define default command.
ENTRYPOINT ["/builder"]
EOF

cp -rfv ~/image/Dockerfile ~/imagesquashed

docker build -t sabayon/builder-amd64 ~/image
docker build -t sabayon/builder-amd64-squashed ~/imagesquashed
