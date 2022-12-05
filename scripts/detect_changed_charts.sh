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


CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Target branch:  $TARGET_BRANCH" 1>&2
echo "Current Branch: $CURRENT_BRANCH" 1>&2

# First, get the lastest tags from the upstream repo
echo "Fetching tags" 1>&2
git fetch --tags > /dev/null

if [[ "$CURRENT_BRANCH" == "$TARGET_BRANCH" ]]; then
    # This is kind of a hack, as we don't have an easy wasy to determine what charts changed
    # so we will put all charts up for consideration. If a chart already has a git tag, then 
    # it will not be built!
    echo "Current and target branches are the same!" 1>&2
    CHANGED_CHARTS=$(find $CHARTS_BASE -mindepth 2 -maxdepth 2)
else
    # Second identify any charts that have changed between this branch and the target branch
    echo "Using chart testing to determine changed charts" 1>&2
    pwd 1>&2
    CHANGED_CHARTS=$(ct list-changed --target-branch "$TARGET_BRANCH")
fi

echo "Charts to consider: $CHANGED_CHARTS" 1>&2

for CHART_PATH in $CHANGED_CHARTS; do
    echo "Checking changed chart: $CHART_PATH" 1>&2
    CHART_YAML_PATH="$CHART_PATH/Chart.yaml"
    if [[ ! -f "$CHART_YAML_PATH" ]]; then
        echo "Warning: $CHART_YAML_PATH does not exist, skipping potential chart: $CHART_PATH" 1>&2
        continue
    fi

    CHART_NAME=$(yq e .name "$CHART_YAML_PATH")
    CHART_VERSION=$(yq e .version "$CHART_YAML_PATH")
    EXPECTED_GIT_TAG="$CHART_NAME-$CHART_VERSION"
    EXPECTED_GIT_TAG_EXISTS="false"

    if git rev-parse -q --verify "refs/tags/$EXPECTED_GIT_TAG" > /dev/null; then
        EXPECTED_GIT_TAG_EXISTS="true"
    fi

    jq -n -c \
        --arg PATH "$CHART_PATH" \
        --arg NAME "$CHART_NAME" \
        --arg VERSION "$CHART_VERSION" \
        --arg EXPECTED_GIT_TAG "$EXPECTED_GIT_TAG" \
        --argjson EXPECTED_GIT_TAG_EXISTS "$EXPECTED_GIT_TAG_EXISTS" \
        '{Path: $PATH, Name: $NAME, Version: $VERSION, ExpectedGitTag: $EXPECTED_GIT_TAG, ExpectedGitTagExists: $EXPECTED_GIT_TAG_EXISTS}'
done
