#!/bin/bash

package=service-fabric-debs

set -eu

ls -alhS /var/vcap/packages/${package}/apt/cache/archives/*.deb

echo "servicefabric servicefabric/accepted-eula-ga select true" | debconf-set-selections
echo "servicefabricsdkcommon servicefabricsdkcommon/accepted-eula-ga select true" | debconf-set-selections

debfiles=$(ls /var/vcap/packages/${package}/apt/cache/archives/*.deb)
for debfile in ${debfiles[@]}; do
  dpkg -x $debfile /
done
