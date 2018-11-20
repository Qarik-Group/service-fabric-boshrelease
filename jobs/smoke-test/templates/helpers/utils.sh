# Helper functions used by SF jobs
function bail {
  echo "The command has failed after $n attempts."
  exit $1
}

function retry {
  local n=1
  if [[ ! ${RETRY_BAIL_COMMAND-} ]]; then
	  local RETRY_BAIL_COMMAND="bail 1"
  fi
  if [[ ! ${RETRY_FAIL_COMMAND-} ]]; then
	  local RETRY_FAIL_COMMAND=:
  fi
  if [[ ! ${RETRY_SUCCESS_COMMAND-} ]]; then
	  local RETRY_SUCCESS_COMMAND=:
  fi
  if [[ ! ${RETRY_DELAY-} ]]; then
	  local RETRY_DELAY=0
  fi
  if [[ ! ${RETRY_COUNT-} ]]; then
	  local RETRY_COUNT=5
  fi

  while true; do
    $@ && break || {
      if [[ $n -lt $RETRY_COUNT ]]; then
        echo "Attempt $n/$RETRY_COUNT: failed"
        $RETRY_FAIL_COMMAND
        ((n++))
        sleep $RETRY_DELAY;
      else
        echo "Attempt $n/$RETRY_COUNT: failed"
        $RETRY_BAIL_COMMAND
        exit 1
      fi
    }
  done
  $RETRY_SUCCESS_COMMAND
}

function check_health_status {
  if [[ "$(sfctl cluster health -o json | jq -r ".aggregatedHealthState")" == "Ok" ]]
  then
    return 0
  fi
  return 1
}

function check_cluster_upgrade {
	if [[ -n $(sfctl cluster upgrade-status | jq -r .upgradeState | grep Completed) ]]
  then
		return 0
  fi
	return 1
}

function upgrade_status {
  echo "UpgradeDomains: $(sfctl cluster upgrade-status | jq -r ".upgradeDomains") - ${SECONDS}s"
  echo "UpgradeState: $(sfctl cluster upgrade-status | jq -r ".upgradeState") - ${SECONDS}s"
}

function check_node_deactivation {
	if [[ "$(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeStatus")" == "Disabled" ]] && \
	   [[ "$(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeDeactivationInfo.nodeDeactivationStatus")" == "Completed" ]];
  then
		return 0
  fi
	return 1
}

function check_node_activation {
  if [[ "$(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeStatus")" == "Up" ]] && \
     [[ "$(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeDeactivationInfo.nodeDeactivationStatus")" == "None" ]];
  then
    return 0
  fi
  return 1
}

function deactivation_status {
  echo "NodeStatus: $(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeStatus") - ${SECONDS}s"
  echo "DeactivationStatus: $(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeDeactivationInfo.nodeDeactivationStatus") - ${SECONDS}s"
}

<%-
cluster_certs = Array.new
primary_thumbprint = ""
secondary_thumbprint = ""
if link('service-fabric').p("TLS.enable") == true
  link("service-fabric").p("TLS.cluster_certificates") do |pem|
    pem.each do |name, cert|
      if !cert.has_key? "certificate" or !cert.has_key? "key"
        raise "Certificate or Key not provided for '#{name}'"
      end
      cert.each do |type, value|
        pem_block = value.strip
        File.write("/tmp/service-fabric.crt", pem_block, mode: 'a')
        thumbprint = `openssl x509 -in /tmp/service-fabric.crt -out /dev/stdout -outform der | sha1sum | awk '{printf "%s", toupper($1)}'`
        File.delete("/tmp/service-fabric.crt")
        if type == "certificate"
          if name == "primary"
            primary_thumbprint = thumbprint
          end
          if name == "secondary"
            secondary_thumbprint = thumbprint
          end
          cluster_certs << thumbprint
        end
      end
    end
      cluster_certs.uniq!
  end
end
%>

function select_sf_cluster {
  <% if link('service-fabric').p("TLS.enable") == true %>
    echo "Attempting to target cluster at https://$1 using Cert with thumbprint: <%= primary_thumbprint %>.crt"
    sfctl cluster select --endpoint https://$1 --cert /var/lib/sfcerts/<%= primary_thumbprint %>.crt --key /var/lib/sfcerts/<%= primary_thumbprint %>.prv --no-verify <% if secondary_thumbprint != "" %> || \
    echo "Attempting to target cluster at https://$1 using Cert with thumbprint: <%= secondary_thumbprint %>.crt" && \
    sfctl cluster select --endpoint https://$1 --cert /var/lib/sfcerts/<%= secondary_thumbprint %>.crt --key /var/lib/sfcerts/<%= secondary_thumbprint %>.prv --no-verify
    <% end %>
  <% else %>
    sfctl cluster select --endpoint http://$1
  <% end %>
}

function select_cluster {
  set +eu
  # Attempt connecting to the localhost node, and failing that - the first 3 nodes in the cluster
  select_sf_cluster <%= link("service-fabric").instances[0].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %> || \
  select_sf_cluster <%= link("service-fabric").instances[1].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %> || \
  select_sf_cluster <%= link("service-fabric").instances[2].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %>
}