FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /workdir

# Installing the required tools (https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/gs_installing.html#installing-the-required-tools)
# Install dependencies (https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/zephyr/getting_started/index.html#install-dependencies)
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
        git \
        cmake \
        ninja-build \
        gperf \
        ccache \
        dfu-util \
        device-tree-compiler \
        wget \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-tk \
        python3-wheel \
        xz-utils \
        file \
        make \
        gcc \
        gcc-multilib \
        g++-multilib \
        libsdl2-dev \
        libncurses5 \
        libncurses5-dev

# Installing the toolchain (https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/gs_installing.html#installing-the-toolchain)
RUN mkdir /opt/gnuarmemb && \
    wget -qO- "https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2" | tar xj --directory /opt/gnuarmemb --strip-components=1
ENV ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/gnuarmemb
RUN echo "\n\
export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb\n\
export GNUARMEMB_TOOLCHAIN_PATH=/opt/gnuarmemb\n\
" >> ~/.zephyrrc

# Getting the nRF Connect SDK code (https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/gs_installing.html#installing-the-toolchain)
# Installing west
RUN pip3 install -U west

# Cloning the repositories
WORKDIR /workdir/ncs
RUN west init -m https://github.com/nrfconnect/sdk-nrf --mr master
RUN west update
RUN west zephyr-export

# Updating the repositories
WORKDIR /workdir/ncs/nrf
# nRF Connect SDK version latest
RUN git fetch origin
RUN git checkout origin/master
RUN west update

# Installing additional Python dependencies (https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/gs_installing.html#installing-additional-python-dependencies)
WORKDIR /workdir/ncs
RUN pip3 install -r zephyr/scripts/requirements.txt
RUN pip3 install -r nrf/scripts/requirements.txt
RUN pip3 install -r bootloader/mcuboot/scripts/requirements.txt

# Setting up the command line build environment (https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/gs_installing.html#installing-the-toolchain)
RUN echo "\n\
source /workdir/ncs/zephyr/zephyr-env.sh\n\
" >> ~/.bashrc

# Setting up the command line build environment (https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF-Command-Line-Tools)
WORKDIR /workdir
RUN mkdir tmp && cd tmp && \
    wget -qO- https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-10-0-v2/nRFCommandLineTools10100Linuxamd64tar.gz | tar xz && \
    dpkg -i --force-overwrite *.deb && \
    cd .. && rm -rf tmp
