#!/bin/bash

source /var/vcap/jobs/service-fabric/helpers/ctl_utils.sh
source /var/vcap/packages/sfctl/bosh/runtime.env
export PATH=/var/vcap/packages/jq/bin:$PATH

SECONDS=0
RETRY_COUNT=3
RETRY_BAIL_COMMAND="bail 0" 
echo "*** Trying to target cluster - ${SECONDS}s"
retry select_cluster

RETRY_DELAY=10
echo "*** Enabling node: <%= spec.name %>-<%= spec.id %> - ${SECONDS}s"
retry timeout 10 sfctl node enable --node-name <%= spec.name %>-<%= spec.id %>

RETRY_COUNT=60
RETRY_BAIL_COMMAND="echo \"Unable to select cluster at http(s)://<%= spec.address %>:<%= p("HttpGatewayEndpoint") %>\""
RETRY_FAIL_COMMAND=deactivation_status
retry check_node_activation

exit 0