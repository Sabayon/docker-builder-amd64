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

## Example

The -v flag can furthermore exploited and chained to obtain more fine-grained tweaks

You can of course customize it further, and replace all the configuration that's already been setup on the Docker Image.

- custom.unmask: will contain your unmasks
- custom.mask: will contain your masks
- custom.use: will contain your use flags
- custom.env: will contain your env specifications
- custom.keywords: will contain your keywords

Exporting those files to your container is a matter of adding an argument to your docker run command.

**Example. Exporting your custom.unmask:**

    -v /my/path/custom.unmask:/opt/sabayon-build/conf/intel/portage/package.unmask/custom.unmask


**Example. Exporting your custom.mask:**

      -v /my/path/custom.mask:/opt/sabayon-build/conf/intel/portage/package.mask/custom.mask


**Example. Exporting your custom.use:**


    -v /my/path/custom.use:/opt/sabayon-build/conf/intel/portage/package.use/custom.use


**Example. Exporting your custom.env:**


    -v /my/path/custom.env:/opt/sabayon-build/conf/intel/portage/package.env/custom.env


**Example. Exporting your custom.keywords:**


    -v /my/path/custom.keywords:/opt/sabayon-build/conf/intel/portage/package.keywords/custom.keywords


In this way you tell to docker to mount your custom.* file inside /opt/sabayon-build/conf/intel/portage/package.*/custom.* inside the container.

Keep in mind that the container have the portage directory located at /opt/sabayon-build/conf/intel/portage/ ; the /etc/portage folder is then symlinked to it.

**Attention!** Remember also to use absolute paths or docker will fail to mount your files in the container.


## ENVIRONMENT VARIABLES

You can tweak the default behavior of the script setting those env variables with docker.

- **BUILDER_PROFILE**: Sets the profile for compilation, you can select it using the number or the name
- **BUILDER_JOBS**: How much jobs emerge will have assigned (-j option)
- **PRESERVED_REBUILD**: 1/0 to Enable/Disable preserved rebuild compilation
- **EMERGE_DEFAULTS_ARGS**: a list of commands that you might want to specify
- **FEATURES**: you can override default FEATURES (like in Portage's make.conf)
- **ARTIFACTS_DIR**: Copy emerge output files in this directory inside the container after all went as expected

Sabayon related:
- **USE_EQUO: 1/0** Enable/Disable equo for installing the package dependencies (if you plan to use a pure gentoo repository, set it to 0, but the compilation process would be much longer)
- **EQUO_INSTALL_ATOMS**: Install the latest version of the dependency packages
- **EQUO_INSTALL_VERSION**: Install the specific version of the dependency packages
- **EQUO_SPLIT_INSTALL**: Install all the packages separately one by one

You can pass the ENV options to docker with the **-e** flag


    docker run -e "EQUO_INSTALL_VERSION=1" -e "EQUO_INSTALL_ATOMS=0" -ti --rm -v "$PWD"/artifacts:/usr/portage/packages sabayon/builder-amd64 app-text/tree

**Note**: If you want to keep your container, remove the **--rm** option.
