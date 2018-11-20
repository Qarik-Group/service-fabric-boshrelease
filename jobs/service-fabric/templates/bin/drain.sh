#!/bin/bash
set -eu

source /var/vcap/jobs/service-fabric/helpers/ctl_utils.sh
source /var/vcap/packages/sfctl/bosh/runtime.env
export PATH=/var/vcap/packages/jq/bin:$PATH

LOG_FILE=/var/vcap/sys/log/service-fabric/drain.log

# save stdout and stderr to file descriptors 3 and 4, then redirect them to "foo"
exec 3>&1 4>&2 >>$LOG_FILE 2>&1

SECONDS=0

echo "*** Trying to target cluster - ${SECONDS}s"
retry select_cluster

echo "*** Disabling node: <%= spec.name %>-<%= spec.id %> - ${SECONDS}s"
retry sfctl node disable --node-name <%= spec.name %>-<%= spec.id %> --deactivation-intent RemoveData

RETRY_BAIL_COMMAND="echo \"Unable to disable node <%= spec.name %>-<%= spec.id %> for cluster at http://<%= spec.address %>:<%= p("HttpGatewayEndpoint") %>\""
RETRY_FAIL_COMMAND=deactivation_status
RETRY_DELAY=30
RETRY_COUNT=10
retry check_node_deactivation

sleep 5

echo "*** Waiting for healthy cluster - ${SECONDS}s"
RETRY_FAIL_COMMAND="echo Custer Health State: \"$(sfctl cluster health -o json | jq -r '.aggregatedHealthState')\" - ${SECONDS}s"
RETRY_BAIL_COMMAND="echo \"Cluster at http://<%= spec.address %>:<%= p("HttpGatewayEndpoint") %> remained unhealthy after ${SECONDS}\""
retry check_health_status

echo "Cluster Health Status after drain: $(sfctl cluster health -o json | jq -r ".aggregatedHealthState") - ${SECONDS}s"

# restore stdout and stderr
exec 1>&3 2>&4

echo 0

exit 0