#!/bin/bash -e
# Copyright 2019. IBM All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BASEDIR="$(dirname "$0")"
# shellcheck disable=SC1090
source ${BASEDIR}/env.sh

echo "INFO: Set up installation directory (/opt/h2o/)"
mkdir /opt/h2o/
cd /opt/h2o/

echo "INFO: Load the Driverless AI docker image"
docker load < ${RAMDISK}/dai-docker-centos7-ppc64le-*.tar.gz

echo "INFO: Set up the data, log, license, and tmp directories on the host machine"
mkdir data
mkdir log
mkdir license
mkdir tmp

echo "INFO: H2O.ai Driverless AI installed successfully!"
