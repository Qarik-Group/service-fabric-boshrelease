#!/bin/bash

package=service-fabric-deps

set -eux

debfiles=$(ls /var/vcap/packages/${package}/apt/cache/archives/*.deb)
for debfile in ${debfiles[@]}; do
  dpkg -x $debfile /
done
