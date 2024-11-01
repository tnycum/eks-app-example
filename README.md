# Runbook

## Set up AWS CLI

```sh
aws configure sso
# Set up profile called 'optiv-sso'
# Point to my AWS dev account

# Have AWS CLI point to my AWS dev account
export AWS_PROFILE=optiv-tnycum
```

## Build EKS cluster

```sh
cd terraform/
```

Create `terraform.tfvars`:

```
cluster_name = "myname"
```

```sh
terraform init
terraform apply
# 'y' at the prompt
```

Set up `kubeconfig` file for CLI access:

```sh
tf output -raw kubeconfig > kubeconfig
cp ~/.kube/config ~/.kube/config-bak
export KUBECONFIG=~/.kube/config:$(PWD)/kubeconfig
kubectl config view --flatten > all-in-one-config.yaml
mv all-in-one-config.yaml ~/.kube/config
rm kubeconfig
```

Use `kubectl config list-contexts` to show available contexts.

Use `kubectl config use-context <context>` to switch to a context. We want the context of our newly provisioned EKS cluster.

Validate that `kubectl get nodes` shows the expected nodes within our EKS cluster.