# Runbook

## Set up AWS CLI

```sh
aws configure sso
# Set up profile and give it a name like 'optiv-sso'
# Point to my AWS dev account
aws sso login --profile <profile-name>

# Have AWS CLI point to my AWS dev account
export AWS_PROFILE=<profile-name>
```

## Create S3 Backend

```sh
cd terraform/remote-state
terraform init
terraform apply
```

## Create SOPS KMS Key

```sh
cd terraform/sops-kms
terraform init
terraform apply
```

## Build EKS cluster

```sh
cd terraform/
terraform init
terraform apply
```

Once terraform is applied, it will update your local `~/.kube/config` file to point to the new EKS cluster.

Sanity check to ensure access to cluster works:

```sh
kubectl version
```

If seeing an error related to TLS validation, this may be because of the Netskope proxy. Temporary workaround is to comment out the line with `certificate-authority-data` and insert a line above it with `insecure-skip-tls-verify: true`. If you see a new TLS validation error, just retry until it works. Obviously this is not a good practice overall and steps should be taken to have `kubectl` include the Netskope MitM certificate.

## Flux

FluxCD is used to deploy all of the cluster applications and Wiz runtime defense components.

**Note: This command will only work with GitHub.**

```sh
export GITHUB_USER=<github-username>
export GITHUB_REPO=<github-repo-name>
export GITHUB_TOKEN=<personal-access-token granting repo:* access>

flux bootstrap github \
    --token-auth \
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

To have Wiz show the new EKS cluster and associated findings, it must first rescan the AWS accounts (or wait a day and it'll appear).

Initiate an on-demand scan by logging into Wiz, going to `Settings > Deployments`, finding the options menu button next to the AWS Connector, and initiating a rescan of the cloud and workloads.

## SOPS

[SOPS](https://github.com/getsops/sops) is used to store Kubernetes secrets encrypted inside this git repository. The encryption and decryption is backed by a KMS key. The Terraform `sops.tf` file creates this KMS key and also grants a Flux service account permission to decrypt using this key.

To encrypt a new Kubernetes secret YAML file:

```sh
sops -e -i my-k8s-secret.yaml
```

Decrypt secret:

```sh
sops -d my-k8s-secret.yaml
```

### Creating the Wiz Secret

```sh
k create secret generic wiz-api-token --from-literal=clientId=<client-id> --from-literal=clientToken=<client-secret> -n wiz -o yaml --dry-run=client > wiz-api-token-secret.yaml
```

### Notes on Terraform as it relates to SOPS

Terraform sets up a `.sops.yaml` file within this project that instructs SOPS with how to encrypt new secrets so you don't have to pass as many command line arguments to the encryption command. Sometimes this file seems to get ignored and you'll need to add `--kms <key-arn>` to the encryption command.

Also, a `terraform destroy` will delete the encryption key used for this repository, which is not ideal because the encrypted secrets in this repository will not be able to be decrypted and will have to be re-created. Long-term, there should be a separate Terraform state to manage the KMS key lifecycle. For now, a workaround is to cancel the KMS key deletion after running `terraform destroy`. Then, before rebuilding the cluster run `tf import 'aws_kms_key.sops' '<kms-key-arn>'`.

## Other

This section contains some other interesting things you can do with the cluster.

### MKAT Scan

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

### Check Pod Security Admission violations

This command previews which resources would violate pod security best practices if higher pod security admission controls were applied.

```sh
kubectl label --dry-run=server --overwrite ns --all pod-security.kubernetes.io/enforce=restricted
```

### Future Ideas

- Move terraform state into S3 backend
- Use datasources remote state to pass KMS ARN to EKS cluster input
- Add certificate to game ingress
- Add instructions for others to stand up their own EKS clusters in their own AWS accounts