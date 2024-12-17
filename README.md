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

Test change
