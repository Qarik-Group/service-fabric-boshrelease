# Helper functions used by ctl scripts

# links a job file (probably a config file) into a package
# Example usage:
# link_job_file_to_package config/redis.yml [config/redis.yml]
# link_job_file_to_package config/wp-config.php wp-config.php
link_job_file_to_package() {
  source_job_file=$1
  target_package_file=${2:-$source_job_file}
  full_package_file=$WEBAPP_DIR/${target_package_file}

  link_job_file ${source_job_file} ${full_package_file}
}

# links a job file (probably a config file) somewhere
# Example usage:
# link_job_file config/bashrc /home/vcap/.bashrc
link_job_file() {
  source_job_file=$1
  target_file=$2
  full_job_file=$JOB_DIR/${source_job_file}

  echo link_job_file ${full_job_file} ${target_file}
  if [[ ! -f ${full_job_file} ]]
  then
    echo "file to link ${full_job_file} does not exist"
  else
    # Create/recreate the symlink to current job file
    # If another process is using the file, it won't be
    # deleted, so don't attempt to create the symlink
    mkdir -p $(dirname ${target_file})
    ln -nfs ${full_job_file} ${target_file}
  fi
}

# If loaded within monit ctl scripts then pipe output
# If loaded from 'source ../utils.sh' then normal STDOUT
redirect_output() {
  SCRIPT=$1
  mkdir -p /var/vcap/sys/log/monit
  exec 1>> /var/vcap/sys/log/monit/$SCRIPT.log 2>&1
}

pid_guard() {
  pidfile=$1
  name=$2

  if [ -f "$pidfile" ]; then
    pid=$(head -1 "$pidfile")

    if [ -n "$pid" ] && [ -e /proc/$pid ]; then
      echo "$name is already running, please stop it first"
      exit 1
    fi

    echo "Removing stale pidfile..."
    rm $pidfile
  fi
}

wait_pid() {
  pid=$1
  try_kill=$2
  timeout=${3:-0}
  force=${4:-0}
  countdown=$(( $timeout * 10 ))

  echo wait_pid $pid $try_kill $timeout $force $countdown
  if [ -e /proc/$pid ]; then
    if [ "$try_kill" = "1" ]; then
      echo "Killing $pidfile: $pid "
      kill $pid
    fi
    while [ -e /proc/$pid ]; do
      sleep 0.1
      [ "$countdown" != '0' -a $(( $countdown % 10 )) = '0' ] && echo -n .
      if [ $timeout -gt 0 ]; then
        if [ $countdown -eq 0 ]; then
          if [ "$force" = "1" ]; then
            echo -ne "\nKill timed out, using kill -9 on $pid... "
            kill -9 $pid
            sleep 0.5
          fi
          break
        else
          countdown=$(( $countdown - 1 ))
        fi
      fi
    done
    if [ -e /proc/$pid ]; then
      echo "Timed Out"
    else
      echo "Stopped"
    fi
  else
    echo "Process $pid is not running"
    echo "Attempting to kill pid anyway..."
    kill $pid || true
  fi
}

wait_pidfile() {
  pidfile=$1
  try_kill=$2
  timeout=${3:-0}
  force=${4:-0}
  countdown=$(( $timeout * 10 ))

  if [ -f "$pidfile" ]; then
    pid=$(head -1 "$pidfile")
    if [ -z "$pid" ]; then
      echo "Unable to get pid from $pidfile"
      exit 1
    fi

    wait_pid $pid $try_kill $timeout $force

    rm -f $pidfile
  else
    echo "Pidfile $pidfile doesn't exist"
  fi
}

kill_and_wait() {
  pidfile=$1
  # Monit default timeout for start/stop is 30s
  # Append 'with timeout {n} seconds' to monit start/stop program configs
  timeout=${2:-25}
  force=${3:-1}
  if [[ -f ${pidfile} ]]
  then
    wait_pidfile $pidfile 1 $timeout $force
  else
    # TODO assume $1 is something to grep from 'ps ax'
    pid="$(ps auwwx | grep "$1" | awk '{print $2}')"
    wait_pid $pid 1 $timeout $force
  fi
}

check_nfs_mount() {
  opts=$1
  exports=$2
  mount_point=$3

  if grep -qs $mount_point /proc/mounts; then
    echo "Found NFS mount $mount_point"
  else
    echo "Mounting NFS..."
    mount $opts $exports $mount_point
    if [ $? != 0 ]; then
      echo "Cannot mount NFS from $exports to $mount_point, exiting..."
      exit 1
    fi
  fi
}

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

function check_node_state_removal {
	if [[ "$(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeStatus")" == "Invalid" ]] && \
	   [[ "$(sfctl node info --node-name <%= spec.name %>-<%= spec.id %> | jq -r ".nodeDeactivationInfo.nodeDeactivationStatus")" == "None" ]];
  then
		return 0
  fi
	return 1
}

<%-
cluster_certs = Array.new
primary_thumbprint = ""
secondary_thumbprint = ""
if_p("TLS.cluster_certificates") do |pem|
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
%>

function select_sf_cluster {
  <% if p("TLS.enable") == true %>
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
  select_sf_cluster <%= spec.address %>:<%= p("HttpGatewayEndpoint") %> || \
  select_sf_cluster <%= link("service-fabric").instances[0].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %> || \
  select_sf_cluster <%= link("service-fabric").instances[1].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %> || \
  select_sf_cluster <%= link("service-fabric").instances[2].address %>:<%= link("service-fabric").p("HttpGatewayEndpoint") %>
}