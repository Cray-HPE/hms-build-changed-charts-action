# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
# hms-build-environment
#
FROM artifactory.algol60.net/csm-docker/stable/docker.io/library/alpine:3.15 as build-environment

RUN set -eux \
    && apk -U upgrade --no-cache \
    && apk add --no-cache \
        bash \
        python3 \
        py3-pip \
        git \
        openssh \
        curl \
        jq \
        yamllint

RUN set -ex \
    && pip3 install yamale

ARG KUBECTL_VERSION=v1.19.15 
RUN wget -q https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

ARG HELM_VERSION=v3.10.0
RUN set -eux \
    && mkdir /tmp/helm \
    && cd /tmp/helm \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O ./helm.tar.gz \
    && tar -xvf ./helm.tar.gz \
    && mv ./linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rv /tmp/helm

ARG CHART_TESTING_VERSION=3.7.1
RUN set -eux \
    && mkdir /tmp/ct \
    && cd /tmp/ct \
    && wget https://github.com/helm/chart-testing/releases/download/v${CHART_TESTING_VERSION}/chart-testing_${CHART_TESTING_VERSION}_linux_amd64.tar.gz -O /tmp/ct/ct.tar.gz \
    && tar -xvf ./ct.tar.gz \
    && mv /tmp/ct/ct /usr/local/bin/ct \
    && mv /tmp/ct/etc /etc/ct \
    && rm -rv /tmp/ct

ARG YQ_VERSION=v4.14.1
RUN set -exu \
    && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /usr/bin/yq \
    && chmod +x /usr/bin/yq

RUN set -eux \
    && git config --global --add safe.directory /github/workspace

RUN set -eux \
    && mkdir ~/.ssh \
    && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

WORKDIR /workspace

#
# Final layer
#
FROM build-environment

COPY ./scripts/ /usr/local/bin/
WORKDIR /workspace
