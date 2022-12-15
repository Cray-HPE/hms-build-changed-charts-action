#! /usr/bin/env bash

#
# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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

function requires() {
    while [[ $# -gt 0 ]]; do
        COMMAND_PATH=$(command -v "$1")
        if [[ $? -eq 0 ]]; then
            echo "Found ${1} at ${COMMAND_PATH}"
        else 
            echo "Error command not found: ${1}"
            exit 1
        fi 
        shift
    done
}

echo "----------------------------------------"
echo "Verifying required tooling is installed"
echo "----------------------------------------"
requires git kubectl helm ct yamale

echo
echo "----------------------------------------"
echo "Verifying cray-algol60 helm repo is configured"
echo "----------------------------------------"
if helm repo list | grep --quiet cray-algol60; then
    echo "Helm repo cray-algol60 exists."
else
    echo
    echo "Error Helm repo cray-algol60 does not exist."
    echo "Create Helm repo without authentication:"
    echo "  helm repo add cray-algol60 https://artifactory.algol60.net/artifactory/csm-helm-charts"
    echo
    echo "Create Helm repo with authentication:"
    echo "  helm repo add cray-algol60 https://artifactory.algol60.net/artifactory/csm-helm-charts --username username --password password"
    exit 1
fi

echo
echo "----------------------------------------"
echo "Verifying access to cray-algol60 repo"
echo "----------------------------------------"
if helm repo update cray-algol60; then
    echo
    echo "Helm repo cray-algol60 successfully updated."
else 
    echo
    echo "Error failed to update helm repo cray-algol60. Are the repository credentials correct?"
    exit 1
fi
