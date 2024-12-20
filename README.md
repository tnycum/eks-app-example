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

## Create KMS key

First get the OIDC issuer ID:

```sh
export OIDC_PROVIDER=$(aws eks describe-cluster --name tnycum-basic-cluster --query "cluster.identity.oidc.issuer" --output text | awk -F'//' '{print $2}')
```

Terraform to create KMS key and IAM Role.

```sh
tf init
tf plan -var oidc_provider=$OIDC_PROVIDER
```

## Flux

First, make sure the `kustomize-controller` can decrypt secrets.

```sh
export SOPS_DECRYPT_ROLE_ARN=$(tf output -raw sops_decrypt_role_arn)
eksctl create iamserviceaccount --config-file=eks/cluster.yaml --name kustomize-controller --namespace flux-system --attach-policy-arn=$SOPS_DECRYPT_ROLE_ARN
```

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

Force a refresh on the cluster with this command after a `git push` to avoid waiting for the poll interval:

```sh
flux reconcile kustomization apps -n flux-system
```

## Wiz Scan

Initiate an on-demand scan going to `Settings > Deployments`, finding the options next to the AWS Connector, and initiating a rescan of the cloud and workloads.