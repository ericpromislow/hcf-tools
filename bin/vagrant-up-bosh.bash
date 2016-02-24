#!/bin/bash

set -ex

cd $HOME/git/cloudfoundry/bosh-lite
vagrant up

bosh target 192.168.50.4 lite # answer is admin/admin # or ...:
bosh login admin admin
# bin/add-route || true
bosh upload stemcell bosh-stemcell-3147-warden-boshlite-ubuntu-trusty-go_agent.tgz
