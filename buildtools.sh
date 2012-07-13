#!/bin/bash

# Refresh
apt-get update
apt-get upgrade

# Install my default thingies
apt-get -y install nano fail2ban screen wget aptitude git

# Install stuff needed to build my own debs and compile etc
apt-get install autoconf gcc g++ install-sh libtool shtool autogen automake m4 pkg-config checkinstall

# Instructions to compile from source
# 1. Obtain source trough git/tarball
# 2. ./autogen.sh if needed (github mostly)
# 3. ./configure
# 4. make or make -j4 (if 4 cpu cores)
# 5. make install to install or checkinstall to create .deb
# 6. $$$ Profit?
