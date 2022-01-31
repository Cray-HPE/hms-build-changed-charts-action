#! /usr/bin/env bash

#
# MIT License
#
# (C) Copyright [2021] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

set -xeo pipefail

CHART_PATH=$1
if [[ -z "$CHART_PATH" ]]; then
    echo "Error: Chart path not provided"
    exit 1
fi

helm dep up $CHART_PATH
HELM_PACKAGE_OPTS=""

if [[ -n "$UNSTABLE_BUILD_SUFFIX" ]]; then
    echo "Performing unstable chart build!"
    CHART_VERSION=$(helm show chart ${CHART_PATH} | grep -e '^version:' | sed 's/^version: //g')
    HELM_PACKAGE_OPTS="--version ${CHART_VERSION}${UNSTABLE_BUILD_SUFFIX}"
fi

helm package $CHART_PATH -d .packaged ${HELM_PACKAGE_OPTS}