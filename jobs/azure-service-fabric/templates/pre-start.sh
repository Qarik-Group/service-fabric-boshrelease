#!/bin/bash

ls -alhS /var/vcap/packages/service-fabric-debs/apt/cache/archives/*.deb

echo "servicefabric servicefabric/accepted-eula-ga select true" | debconf-set-selections
echo "servicefabricsdkcommon servicefabricsdkcommon/accepted-eula-ga select true" | debconf-set-selections

dpkg -i /var/vcap/packages/service-fabric-debs/apt/cache/archives/python*.deb
dpkg -i /var/vcap/packages/service-fabric-debs/apt/cache/archives/dotnet*.deb

dpkg -i /var/vcap/packages/service-fabric-debs/apt/cache/archives/*.deb