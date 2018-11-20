#!/bin/bash

source /var/vcap/jobs/service-fabric/helpers/ctl_utils.sh
source /var/vcap/packages/sfctl/bosh/runtime.env
export PATH=/var/vcap/packages/jq/bin:$PATH
PACKAGE_DIR=/var/vcap/packages/service-fabric/apt/cache/archives

SECONDS=0
RETRY_DELAY=30
RETRY_COUNT=40

FABRIC_VERSION=$(cat $PACKAGE_DIR/servicefabric.version)

echo "*** Trying to target cluster - ${SECONDS}s"
retry select_cluster

echo "*** Waiting for healthy cluster - ${SECONDS}s"
RETRY_FAIL_COMMAND="echo Custer Health State: \"$(sfctl cluster health -o json | jq -r '.aggregatedHealthState')\" - ${SECONDS}s"
RETRY_BAIL_COMMAND="echo \"Cluster at http(s)://<%= link("service-fabric").instances[0].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %> remained unhealthy after ${SECONDS}\""
retry check_health_status

<% if spec.bootstrap == true %>
if [[ $(sfctl cluster code-versions) == "[]" ]]; then
    echo "*** Running Baseline Upgrade - ${SECONDS}s"
    mkdir -p /tmp/service-fabric-upgrade
    cp $PACKAGE_DIR/servicefabric_${FABRIC_VERSION}_amd64.deb /tmp/service-fabric-upgrade/servicefabric_${FABRIC_VERSION}.deb
    sfctl cluster manifest | jq -r .manifest > /tmp/service-fabric-upgrade/ClusterManifest.xml
    pushd /tmp
        sfctl application upload --path service-fabric-upgrade --show-progress
        sfctl cluster provision --cluster-manifest-file-path service-fabric-upgrade/ClusterManifest.xml --code-file-path service-fabric-upgrade/servicefabric_${FABRIC_VERSION}.deb
    popd
    rm -rf /tmp/service-fabric-upgrade

    sfctl cluster upgrade --code-version ${FABRIC_VERSION} --config-version 1.0

    RETRY_BAIL_COMMAND="echo \"Baseline Upgrade for cluster at http://<%= spec.address %>:<%= p("HttpGatewayEndpoint") %>\" failed or timed-out after ${SECONDS}s"
    RETRY_FAIL_COMMAND=upgrade_status
    RETRY_DELAY=30
    RETRY_COUNT=960
    retry check_cluster_upgrade
fi
<% end %>

echo "$(sfctl cluster health -o json | jq -r ".aggregatedHealthState") - ${SECONDS}s"
exit 0