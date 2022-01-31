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

# YQ Version 4 is required for this script

set -xeo pipefail

CHARTS_BASE=$1
if [[ -z "$CHARTS_BASE" ]]; then
    echo "Warning: Chart base path not provided, , defaulting to ./charts"
    CHARTS_BASE=charts
fi

if [[ -z "$CT_CONFIG" ]]; then
    echo "Warning: CT_CONFIG enviroment variable is not set, defaulting to ct.yaml"
    CT_CONFIG="ct.yaml"
fi

echo "Orginial chart testing configuration"
cat $CT_CONFIG

for CHART_VERSION_PATH in $CHARTS_BASE/v*; do
    echo "Adding chart version directory: ${CHART_VERSION_PATH}"
    export CHART_VERSION_PATH="$CHART_VERSION_PATH"
    yq eval --inplace -P '.chart-dirs |= . + [env(CHART_VERSION_PATH)]' "$CT_CONFIG"
done

echo "Customized chart testing configuration"
cat $CT_CONFIG