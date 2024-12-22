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
cd terraform/
terraform init
terraform apply
```

Check access:

```sh
kubectl version
```

If seeing an error related to TLS validation, this is because of the Netskope proxy. Temporary workaround is to comment out the line with `certificate-authority-data` and insert a line above it with `insecure-skip-tls-verify: true`. If you see a new TLS validation error, just retry until it works.

## Flux

First, make sure the `kustomize-controller` can decrypt secrets.


```sh
flux bootstrap github \
    --token-auth \
    --context=$(kubectl config current-context) \
    --owner=${GITHUB_USER} \
    --repository=${GITHUB_REPO} \
    --branch=main \
    --personal \
    --path=clusters/dev
```

### Flux tips

Force a refresh on the cluster with this command after a `git push` to avoid waiting for the poll interval:

```sh
flux reconcile kustomization apps -n flux-system
```

## Wiz Scan

Initiate an on-demand scan going to `Settings > Deployments`, finding the options next to the AWS Connector, and initiating a rescan of the cloud and workloads.

## MKAT Scan

Check permissions using DataDog's tool [MKAT](https://github.com/DataDog/managed-kubernetes-auditing-toolkit).

Show IAM role relationships in the cluster (this can sort of be seen in the EKS console too, under the Access tab):

```sh
mkat eks find-role-relationships
```

Find hardcoded AWS creds:

```sh
mkat eks find-secrets
```

Find access to IMDS (both IMDSv1 and IMDSv2):

```sh
# This requires creation of Pods
mkat eks test-imds-access
```

## SOPS

Encrypt secret:

```sh
sops -e -i my-k8s-secret.yaml
```

Decrypt secret:

```sh
sops -d my-k8s-secret.yaml
```

## Ideas

- Enable EKS Secrets Encryption at rest
- Add certificate to game ingress