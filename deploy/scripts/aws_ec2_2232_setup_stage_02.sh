#!/bin/bash
###############################################################################
# SPDX-License-Identifier: Apache-2.0
# Stage 2 instance configuration setup script.
###############################################################################
set -x

# Start the docker service if not already started.
sudo service docker start

# Configure the github private key.
chmod 400 ~/.ssh/id_ed25519
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Populate known_hosts with github so git clone proceeds non-interactively.
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Clone the repo
pushd /datastore
git clone git@github.com:simonderekhughes/stbotolphs-sqh
pushd stbotolphs-sqh

# checkout the the build tag for building.
git checkout sdh_cu_instance_build_tag

docker-compose build --pull

# Wait for the database to come up.
sleep 420

# Spin up the container.
nohup docker-compose up &

# Give some time for the service to come up prior to adding user.
sleep 60

# Create a webapp user.
docker-compose exec webapp ./manage.py createsuperuser --email ada.lovelace@gmail.com --noinput --username webapp
