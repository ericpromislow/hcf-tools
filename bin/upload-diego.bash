#!/bin/bash

set -ex

# 2016-02-24:
# $0 v231 v0.1454.0 36 v0.333.0

CF_RELEASE=$1
DIEGO_RELEASE=$2
ETCD_RELEASE=$3
GARDEN_LINUX_RELEASE=$4

if [ -z "$GARDEN_LINUX_RELEASE" ] ; then
    echo "Usage $(dirname $0) cf-release diego-release etcd-release garden-linux-release"
    exit 1
fi

cd $HOME/git/cloudfoundry/cf-release
# Set this var for diego-release:scripts/generate-bosh-lite-manifests
export CF_RELEASE_DIR=$PWD
git checkout $CF_RELEASE
scripts/update
scripts/generate-bosh-lite-dev-manifest
bosh create release --force
bosh upload release
bosh -n deploy

bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release?v=$GARDEN_LINUX_RELEASE

bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/etcd-release?v=$ETCD_RELEASE

cd $HOME/git/cloudfoundry-incubator/diego-release
git checkout $DIEGO_RELEASE
scripts/update
git clean -ffd
DIEGO_RELEASE_DIR=$PWD scripts/generate-bosh-lite-manifests
bosh deployment bosh-lite/deployments/diego.yml
bosh create release --force
bosh upload release
bosh -n deploy
