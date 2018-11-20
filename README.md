# BOSH release for azure-service-fabric

This BOSH release and deployment manifest deploy a linux based standalone cluster of
azure-service-fabric.

# Deployment

This repository includes base manifests and operator files. They can be used for
initial deployments and subsequently used for updating your deployments.

## Setting up a BOSH director
For those not familiar with BOSH or who do not have a running BOSH director,
check out the guides on bosh.io for setting up the CLI and directors on
[AWS](https://bosh.io/docs/init-aws/),
[Azure](https://bosh.io/docs/init-azure/),
[GCP](https://bosh.io/docs/init-google/),
[vSphere](https://bosh.io/docs/init-vsphere/), and more.

## Stemcells

The ServiceFabric bosh-release requires the use of the newer Xenial (Ubuntu
18.04) stemcells. Other stemcells are currently not supported but may be
considered in future releases. TO upload a stemcell, target and authenticate
with your BOSH environment and upload a Xenial stemcell which are available
[here](https://bosh.io/stemcells#ubuntu-xenial). Ensure you grab the latest
`Full Stemcell` for your IaaS of choice. 

Examples for vSphere, Azure, and AWS are:

```bash
export BOSH_ENVIRONMENT=<bosh-alias>
bosh upload-stemcell https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-xenial-go_agent?v=97.16
bosh upload-stemcell https://bosh.io/d/stemcells/bosh-azure-hyperv-ubuntu-xenial-go_agent?v=97.16
bosh upload-stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent?v=97.16
```
## Cloud-Config

The base manifest assumes you have a `service-fabric` network defined as well as
a `service-fabric` vm_type in your cloud-config as shown below with snippets
from AWS and vSphere cloud-configs.

AWS specfic:
```yaml
networks:
- name: service-fabric
  subnets:
  - azs:
    - z1
    - z2
    - z3
    cloud_properties:
      subnet: subnet-032d1aeeac2006243
    dns:
    - 8.8.8.8
    - 8.8.4.4
    gateway: 172.16.1.1
    range: 172.16.0.0/17
    reserved:
    - 172.16.0.0-172.16.0.10
vm_types:
- cloud_properties:
    ephemeral_disk:
      size: 20480
    instance_type: m4.xlarge
    root_disk:
      size: 51200
  name: service-fabric
```

vSphere Specific:
```yaml
- name: service-fabric
  subnets:
  - azs:
    - z1
    - z2
    - z3
    cloud_properties:
      name: VMNetwork
    dns:
    - 8.8.8.8
    - 8.8.4.4
    gateway: 172.16.1.1
    range: 172.16.0.0/17
    reserved:
    - 172.16.0.0-172.16.0.10
  type: manual

vm_types:
- cloud_properties:
    cpu: 2
    disk: 51200
    ram: 8192
  name: service-fabric
```
Note: The above examples are just snippets, not complete cloud configs.

While the above snippets are mostly the same, the IaaS dependent properties
listed under `cloud_properties` are what differentiate most cloud-configs from
one another. For more information on the specific `cloud_properties` youll need
to reference for your IaaS of choice, visit the cloud-config documentation 
[here](https://bosh.io/docs/terminology/) under the `Cloud Providers` section for
[AWS](https://bosh.io/docs/aws-cpi/),
[Azure](https://bosh.io/docs/azure-cpi/),
[GCP](https://bosh.io/docs/google-cpi/),
[vSphere](https://bosh.io/docs/vsphere-cpi/), and more. For each IaaS be sure to
look at the `Example Cloud Config` to base yours off of and ensure you have all
of the required sections.

## Deploying ServiceFabric

To deploy ServiceFabric, the easiest menthod would be to use the base manifest
provided in this repo and customize it to fit your needs. The base manifest will
deploy a 5 node cluster without authentication.

An example of a manifest including all of the valid properties is shown below
with descriptions of all of the parameters and their default values (if
applicable) below that.

```yaml
---
name: azure-service-fabric

instance_groups:
- name: service-fabric
  azs: [z1,z2,z3]
  instances: 5
  vm_type: service-fabric
  stemcell: default
  networks: [{name: service-fabric}]
  env:
    bosh:
      ipv6: {enable: true}
      swap_size: 0
  jobs:
  - name: service-fabric
    release: azure-service-fabric
    properties:
      PrimaryAccountNTLMPasswordSecret: Secret-1
      SecondaryAccountNTLMPasswordSecret: Secret-2
      ClientConnectionEndpoint: 19000
      LeaseDriverEndpoint: 19001
      ClusterConnectionEndpoint: 19002
      ServiceConnectionEndpoint: 19006
      HttpGatewayEndpoint: 19080
      HttpApplicationGatewayEndpoint: 19081
      ApplicationEndpoints:
        Start: 22001
        End: 23000
      CpuPercentageNodeCapacity: 0.8
      MemoryPercentageNodeCapacity: 0.8
      MinLoadBalancingInterval: 5
      TargetReplicaSetSize: 4
      MinReplicaSetSize: 3
      SeedNodes: 5
      TLS:
        enable: true
        cluster_certificates:
          primary:
            certificate: |
              -----BEGIN CERTIFICATE-----
              -----END CERTIFICATE-----
            key: |
              -----BEGIN RSA PRIVATE KEY-----
              -----END RSA PRIVATE KEY-----
          secondary:
            certificate: |
              -----BEGIN CERTIFICATE-----
              -----END CERTIFICATE-----
            key: |
              -----BEGIN RSA PRIVATE KEY-----
              -----END RSA PRIVATE KEY-----
        admin_client_certificates:
          name-of-admin-user:
            certificate: |
              -----BEGIN CERTIFICATE-----
              -----END CERTIFICATE-----
        client_certificates:
          name-of-read-only-user:
            certificate: |
              -----BEGIN CERTIFICATE-----
              -----END CERTIFICATE-----
  - name: repair
    release: azure-service-fabric
    properties: {}

- name: smoke-test
  azs: [z1]
  instances: 1
  lifecycle: errand
  vm_type: small
  stemcell: default
  networks: [{name: service-fabric}]
  env:
    bosh:
      ipv6: {enable: true}
  jobs:
  - name: smoke-test
    release: azure-service-fabric

- name: upgrade
  azs: [z1]
  instances: 1
  lifecycle: errand
  vm_type: small
  stemcell: default
  networks: [{name: service-fabric}]
  env:
    bosh:
      ipv6: {enable: true}
  jobs:
  - name: upgrade
    release: azure-service-fabric
    properties:
      FabricCodeVersion: 6.3.129.1
```

| Property        | Description           | Default  |
| ------------- |:-------------:| :-------: |
| PrimaryAccountNTLMPasswordSecret | The password secret which used as seed to generate a password when using NTLM authentication. | Generated in Manifest |
| SecondaryAccountNTLMPasswordSecret | The password secret which used as seed to generate a password when using NTLM authentication. | Generated in Manifest |
| ClientConnectionEndpoint | Port to listen on for Client Connections | 19000 |
| LeaseDriverEndpoint | Port to listen on for Lease Driver Connections | 19001 |
| ClusterConnectionEndpoint | Port to listen on for Cluster Connections | 19002 |
| ServiceConnectionEndpoint | Port to listen on for Service Connections | 19006 |
| HttpGatewayEndpoint | Port to listen on for HTTP API connections | 19080 |
| HttpApplicationGatewayEndpoint | Port for the HTTP Application Gateway (reverse proxy) to listen on - not currently supported on linux clusters but included for future implementation | 19081 |
| ApplicationEndpoints.Start | Starting port for applications | 22001 |
| ApplicationEndpoints.End | Ending port for applications | 23000 |
| TLS.enable | Enable x509 certificate authentication for service-fabric | false |
| TLS.cluster_certificates | TLS private key (PEM encoded), used for intra Cluster communication, HTTPS API, and Web UI. Each element in the array is an object containing the field 'certificate', each of which supports a PEM block. | N/A |
| TLS.admin_client_certificates | Array of Certificates used by clients in admin role. Each element in the array is an object containing the field 'certificate', each of which supports a PEM block. | N/A |
| TLS.client_certificates | Array of Certificates used by clients in read-only role. Each element in the array is an object containing the field 'certificate', each of which supports a PEM block. | N/A |
| CpuPercentageNodeCapacity | Percentage of Node CPU Service Fabric  processes are allowed to use. | 0.8 |
| MemoryPercentageNodeCapacity | Percentage of Node Memory Service Fabric processes are allowed to use. | 0.8 |
| MinLoadBalancingInterval | Defines the minimum amount of time that must pass before two consecutive balancing rounds. | 5 |
| TargetReplicaSetSize | The number of replica sets for each partition. Increasing the number of replica sets increases the level of reliability for information; decreasing the chance that the information will be lost as a result of node failures; at a cost of increased load on Service Fabric and the amount of time it takes to perform updates. | #ofNodes-1 (up to 7 nodes) |
| MinReplicaSetSize | Defines the minimum number of replicas required to write into to complete an update. This value should never be more than the TargetReplicaSetSize. | 3 or 5 depending on Cluster Size |
| SeedNodes | Defines the number of seed nodes to be created with the cluster. By default this is 5 and the recommended value is up to 11. Note: If you plan on scaling down ensure that half+1 of the seed nodes remain in order to maintain quorum and avoid cluster collapse. | 5 |

Finally after filling out the manifest according to your needs, `bosh deploy` the manifest via the following:

```bash
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=azure-service-fabric
git clone https://github.com/cloudfoundry-community/azure-service-fabric-boshrelease.git
bosh deploy azure-service-fabric-boshrelease/manifests/azure-service-fabric.yml
```

# Smoke Tests

An errand called `smoke-test` is provided to test core functionality once the
cluster is deployed. The tests include deploying a Java, C# .NET Core, and
Docker conatiner app and ensuring that they come up in a healthy state.
__NOTE__:The container smoke test will fail if inside an air-gapped network or
one which requires a proxy to access the internet. This is due to attempting to
pull an image from dockerhub.

To run the smoke-test errand execute the following commmands:
```bash
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=azure-service-fabric
bosh run-errand smoke-test
```
# Service Fabric Upgrades

To upgrade ServiceFabric to a new version, there is also an included errand
called `upgrade` that by default will try to update the cluster to the newest
available FabricCodeVersion. Depending on cluster size, this process can take a
lot of time and can be monitored from the ServiceFabric WebUI.


To upgrade ServiceFabric to a specific version instead of the latest, you must
update the upgrade errand job in the manifest and redeploy before running the
errand.

Example configration for a specific version is shown below (Specifically the
`FabricCodeVersion` property):
```yaml
- name: upgrade
  azs: [z1]
  instances: 1
  lifecycle: errand
  vm_type: small
  stemcell: default
  networks: [{name: service-fabric}]
  env:
    bosh:
      ipv6: {enable: true}
  jobs:
  - name: upgrade
    release: azure-service-fabric
    properties:
      FabricCodeVersion: 6.3.129.1
```

To run the upgrade errand execute the following commmands:
```bash
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=azure-service-fabric
bosh run-errand upgrade
```

# Bosh Upgrades

When new versions of `azure-service-fabric-boshrelease` are released the
`manifests/azure-service-fabric.yml` file will be updated. This means you can
easily `git pull` and `bosh deploy` to upgrade to a new version of the
bosh-release. New versions of the release will include updates for new stemcell
versions as well as the most recent version of ServiceFabric.

```bash
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=azure-service-fabric
cd azure-service-fabric-boshrelease
git pull
bosh deploy manifests/azure-service-fabric.yml
```
