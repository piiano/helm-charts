# Piiano Helm Charts repository for Kubernetes

This repository contains Helm Charts for different Piiano products.

## Supported Charts

| Chart                                 | Description                                                                          |
| ------------------------------------- | ------------------------------------------------------------------------------------ |
| [pvault-server](charts/pvault-server) | [Piiano Vault](https://piiano.com/pii-data-privacy-vault/) Server edition Helm Chart |

## Adding Piiano Helm Repo

Piiano Helm repository can be added using the `helm repo add` command, like
in the following example:

```console
$ helm repo add piiano https://piiano.github.io/helm-charts
"piiano" has been added to your repositories
```