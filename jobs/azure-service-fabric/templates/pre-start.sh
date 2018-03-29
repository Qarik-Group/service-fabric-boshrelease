#!/bin/bash

package=service-fabric-debs

ls -alhS /var/vcap/packages/${package}/apt/cache/archives/*.deb

echo "servicefabric servicefabric/accepted-eula-ga select true" | debconf-set-selections
echo "servicefabricsdkcommon servicefabricsdkcommon/accepted-eula-ga select true" | debconf-set-selections

dpkg -i /var/vcap/packages/${package}/apt/cache/archives/*.deb