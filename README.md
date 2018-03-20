# BOSH release for azure-service-fabric

This BOSH release and deployment manifest deploy a cluster of azure-service-fabric.

## Usage

This repository includes base manifests and operator files. They can be used for initial deployments and subsequently used for updating your deployments:

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=azure-service-fabric
git clone https://github.com/cloudfoundry-community/azure-service-fabric-boshrelease.git
bosh deploy azure-service-fabric-boshrelease/manifests/azure-service-fabric.yml
```

If your BOSH does not have Credhub/Config Server, then remember `--vars-store` to allow generation of passwords and certificates.

### Update

When new versions of `azure-service-fabric-boshrelease` are released the `manifests/azure-service-fabric.yml` file will be updated. This means you can easily `git pull` and `bosh deploy` to upgrade.

```
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=azure-service-fabric
cd azure-service-fabric-boshrelease
git pull
cd -
bosh deploy azure-service-fabric-boshrelease/manifests/azure-service-fabric.yml
```
