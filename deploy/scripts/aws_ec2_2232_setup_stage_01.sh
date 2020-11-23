#!/bin/bash
###############################################################################
# SPDX-License-Identifier: Apache-2.0
# Stage 1 instance configuration setup script.
###############################################################################
set -x

function init_setup()
{
    sudo mkdir /datastore
    sudo chown ubuntu:ubuntu /datastore/
    pushd /datastore/

    sudo apt update
    sudo apt -y install docker.io
    sudo apt -y install emacs
    sudo apt -y install docker-compose
    sudo apt -y install emacs

    sudo groupadd docker
    sudo usermod -aG docker ${USER}
}

init_setup

