#!/bin/bash

source /var/vcap/jobs/service-fabric/helpers/ctl_utils.sh

<% if link("service-fabric").instances.size < 5 %>
(>&2 echo "ERROR: service-fabric requires 5 instances or more")
exit 1
<% end %>

if [ ! -d "/var/lib/sfcerts" ]; then
  mkdir /var/lib/sfcerts
fi

<% if p("TLS.enable") == true %>
export PATH=$PATH:/var/vcap/packages/ttar/bin
mkdir -p /var/vcap/jobs/service-fabric/config/certs/
ttar < /var/vcap/jobs/service-fabric/config/certs/certs.ttar

cp /var/vcap/jobs/service-fabric/config/certs/*.crt /var/lib/sfcerts/
cp /var/vcap/jobs/service-fabric/config/certs/*.prv /var/lib/sfcerts/
<% end %>

PACKAGE_DIR=/var/vcap/packages/service-fabric/apt/cache/archives
force_package_installation=<%= p("dev.force_package_installation") %>
if [[ "$force_package_installation" == "true" || -n $(dpkg-query -s servicefabric 2>&1 | grep "not installed") ]]; then
  store_dir=/var/vcap/store
  if [[ $(findmnt -m "$store_dir") ]]; then
    echo "Persistent Storage Mounted"
  else
    echo "Persistent Storage Not mounted -> Defaulting to Ephemeral Storage"
    store_dir=/var/vcap/data
  fi
  rmdir /opt/microsoft
  mkdir -p $store_dir/microsoft
  ln -s $store_dir/microsoft /opt/microsoft

  rmdir /var/lib/docker
  mkdir -p $store_dir/docker
  ln -s $store_dir/docker /var/lib/docker

  #Avoid issues with dotnet2.0 writing to /tmp and ignoring $TMPDIR
  chmod 1777 /tmp

  echo "servicefabric servicefabric/accepted-eula-ga select true" | debconf-set-selections
  echo "servicefabricsdkcommon servicefabricsdkcommon/accepted-eula-ga select true" | debconf-set-selections

  set -x

  # set up local apt repo
  if [[ ! $(cat /etc/apt/sources.list 2>&1 | grep "$PACKAGE_DIR") ]]; then
    echo "deb file:$PACKAGE_DIR ./" >> /etc/apt/sources.list
  fi

  apt-get update --fix-missing
  installed_version=$(dpkg-query --showformat='${Version}' --show servicefabric)
  available_version=$(cat $PACKAGE_DIR/servicefabric.version)
  if [[ "$installed_version" != "$available_version" || "$force_package_installation" == "true" ]]; then
    #Uninstall existing version (if applicable and version differs) - allows for downgreades
    apt-get remove -y servicefabric
  fi

  #Install is idempotent and will upgrade if a newer version is provided
  apt-get install -y --allow-unauthenticated servicefabricsdkcommon=$(cat $PACKAGE_DIR/servicefabricsdkcommon.version) servicefabric=$(cat $PACKAGE_DIR/servicefabric.version)
fi