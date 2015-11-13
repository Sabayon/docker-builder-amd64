# Sabayon Builder: a Docker Project #

[![Circle CI](https://circleci.com/gh/Sabayon/docker-builder-amd64.svg?style=svg)](https://circleci.com/gh/Sabayon/docker-builder-amd64)

Attention! It's under strong development

State: Alpha

The purpose of this project is to provide an image of Sabayon docker-capable builder.
It is just a [Sabayon base](https://github.com/mudler/docker-sabayon-base) with upgrades and compilation tools.

Images are also on Docker Hub [sabayon/builder-amd64](https://registry.hub.docker.com/u/sabayon/builder-amd64/) [sabayon/builder-amd64-squashed](https://registry.hub.docker.com/u/sabayon/builder-amd64-squashed/).

## What is

The docker container serves as a out-of-the-box builder for Sabayon.

The image will run a script that will check that all the deps of your specified atom are available on entropy, and installs them before compiling the actual package; then, it will emerge and build the packages and it's dependency that are not already available on the official sabayon repository

## How to use

### 1) start docker

Ensure to have the daemon started and running:

    sudo systemctl start docker

### 2) build your packages

The container expect as arguments the commands to be executed to emerge, it acts like a wrapper with few enhancements.

For example, if you want to build app-text/tree

    docker run -ti --rm sabayon/builder-amd64 app-text/tree

Or a package available in an overlay

    docker run -ti --rm sabayon/builder-amd64 plasma-meta --layman kde

## Check the volumes for your output

you can inspect the volumes mounted by docker, or mounting externally the output directories (in such case /usr/portage/distfiles)

    docker run -ti --rm -v "$PWD"/artifacts:/usr/portage/packages sabayon/builder-amd64 app-text/tree

e.g. now you can find your tbz2 in your current directory, inside the "artifacts" folder
