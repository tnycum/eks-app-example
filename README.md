# Runbook

## Set up AWS CLI

```sh
aws configure sso
# Set up profile called 'optiv-sso'
# Point to my AWS dev account
aws sso login --profile optiv-tnycum

# Have AWS CLI point to my AWS dev account
export AWS_PROFILE=optiv-tnycum
```

## Build EKS cluster (eksctl)

```sh
eksctl create cluster --config-file eks/basic-cluster.yaml
```

Cleanup:

```sh
eksctl delete cluster --config-file eks/basic-cluster.yaml --disable-nodegroup
```

## Flux

```sh
flux bootstrap github \                                                                                                                   <aws:optiv-tnycum>
    --token-auth \
    --context=$(kubectl config current-context) \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/dev
```

## Wiz Scan

Initiate an on-demand scan going to `Settings > Deployments`, finding the options next to the AWS Connector, and initiating a rescan of the cloud and workloads.