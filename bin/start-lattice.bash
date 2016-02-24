#!/bin/bash

set -ex

cd $HOME/git/cloudfoundry-samples/lattice-app

cf login -a api.bosh-lite.com -u admin -p admin --skip-ssl-validation
cf enable-feature-flag diego_docker
cf create-org org1
cf target -o org1
cf create-space space1
cf create-space tcp-lattice
cf target -o "org1" -s "tcp-lattice"
cf p lattice  --no-start --no-route -c 'lattice-app --ports=7777,8888'
cf enable-diego lattice

app_guid=$(cf app lattice --guid)
echo app_guid=$app_guid
space_guid=$(cf space tcp-lattice --guid)
echo space_guid=$space_guid

cf curl /v2/apps/$app_guid -X PUT -d '{"ports":[7777,8888]}'
cf start lattice

cf create-domain org1 superman.bosh-lite.com
cf create-route tcp-lattice superman.bosh-lite.com -n lattice

route_guid=$(cf curl /v2/routes?q=host:lattice | jq --raw-output '.["resources"][0]["metadata"]["guid"]')
echo route_guid=$route_guid
domain_guid=$(cf curl /v2/routes?q=host:lattice | jq --raw-output '.["resources"][0]["entity"]["domain_guid"]')
# Alternatively (but deprecated):
domain_guid=$(cf curl /v2/domains?q=name:superman.bosh-lite.com | jq --raw-output '.["resources"][0]["metadata"]["guid"]')
echo domain_guid=$domain_guid

cf curl /v2/route_mappings -X POST -d '{"route_guid":"'$route_guid'","app_guid":"'$app_guid'","app_port":7777}'

# This should be '7777'
curl lattice.superman.bosh-lite.com/port && echo ''
# ===> 7777

cf curl /v2/routes -X POST -d '{"space_guid":"'$space_guid'","domain_guid":"'$domain_guid'","port":60004}'
# ==> error 21001 "The route is invalid: Port is supported for domains of TCP router groups only."

cf curl /v2/route_mappings -X POST -d '{"route_guid":"'$route_guid'","app_guid":"'$app_guid'","app_port":8888}'

# => guid 338aa9a5-5de0-4a85-8f15-4c4d4537126e
# This doesn't work:
curl tcp.superman.bosh-lite.com:60004/port

curl lattice.superman.bosh-lite.com/port && echo ''
# ===> 8888
