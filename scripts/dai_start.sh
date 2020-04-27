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

echo "INFO: Start the Driverless AI Docker image with nvidia-docker"
docker run -d --pid=host --init --rm -u `id -u`:`id -g` -p 12345:12345 -v /opt/h2o/data:/data -v /opt/h2o/log:/log -v /opt/h2o/license:/license  -v /opt/h2o/tmp:/tmp h2oai/dai-centos7-ppc64le:1.8.5-cuda10.0
