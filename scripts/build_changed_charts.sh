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

BUILD_TYPE="stable"
if [[ -n "$UNSTABLE_BUILD_SUFFIX" ]]; then
    BUILD_TYPE="unstable"
fi


CHANGED_CHARTS=$(${SCRIPT_DIR}/detect_changed_charts.sh "$CHARTS_BASE" "$TARGET_BRANCH" | jq -r @base64)

for CHANGED_CHART in $CHANGED_CHARTS; do
    CHART_PATH=$(echo "$CHANGED_CHART" | base64 -d | jq -r .Path)
    EXPECTED_GIT_TAG=$(echo "$CHANGED_CHART" | base64 -d | jq -r .ExpectedGitTag)
    EXPECTED_GIT_TAG_EXISTS=$(echo "$CHANGED_CHART" | base64 -d | jq -r .ExpectedGitTagExists)

    echo
    echo "----------------------------------------"
    echo "Building $CHART_PATH"
    echo "----------------------------------------"
    echo "Build type:              $BUILD_TYPE"
    echo "Expected git tag:        $EXPECTED_GIT_TAG"
    echo "Expected git tag exists: $EXPECTED_GIT_TAG_EXISTS"
    echo

    # For unstable builds, we will build all changed charts as each changed chart will get its own unique version
    if [[ "$BUILD_TYPE" == "stable" ]] && [[ "$EXPECTED_GIT_TAG_EXISTS" == "true" ]]; then
        # On stable chart builds refuse to build a chart if its version did not change
        echo "Refusing to build $CHART_PATH as the Git tag $EXPECTED_GIT_TAG already exists!"
        continue
    fi

    ${SCRIPT_DIR}/build_chart.sh "${CHART_PATH}"

done