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

# TODO On release builds build all changed charts
# - This script can also be used as an merge check to verify that the chart version has been incrermented if a chart has changed.

set -eo pipefail

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)

CHARTS_BASE=$1
if [[ -z "$CHARTS_BASE" ]]; then
    echo "Error: Chart base path not provided"
    exit 1
fi

TARGET_BRANCH=$2
if [[ -z "$TARGET_BRANCH" ]]; then
    echo  "Error: Target branch not provided"
    exit 1
fi

CHANGED_CHARTS=$(${SCRIPT_DIR}/detect_changed_charts.sh "$CHARTS_BASE" "$TARGET_BRANCH" | jq -r @base64)

for CHANGED_CHART in $CHANGED_CHARTS; do
    CHART_PATH=$(echo "$CHANGED_CHART" | base64 -d | jq -r .Path)

    echo
    echo "----------------------------------------"
    echo "Verifying $CHART_PATH"
    echo "----------------------------------------"
    echo

    ${SCRIPT_DIR}/verify_chart_application_versions.sh "${CHART_PATH}"
done