#!/bin/bash

source /var/vcap/jobs/service-fabric/helpers/ctl_utils.sh
source /var/vcap/packages/sfctl/bosh/runtime.env
export PATH=/var/vcap/packages/jq/bin:$PATH
PACKAGE_DIR=/var/vcap/packages/service-fabric/apt/cache/archives

# remove state of the node in case the node is being deprovisioned
RETRY_BAIL_COMMAND="bail 0" 
echo "*** Trying to target cluster - ${SECONDS}s"
retry select_cluster

echo "Removing Node State..."
RETRY_COUNT=10
RETRY_DELAY=30
RETRY_FAIL_COMMAND="echo Failed to remove node state."
retry sfctl node remove-state --node-name <%= spec.name %>-<%= spec.id %>

RETRY_FAIL_COMMAND=deactivation_status
retry check_node_state_removal
echo "Finished Removing node state"

exit 0