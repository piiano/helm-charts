# Piiano Vault Server

[Piiano Vault](https://piiano.com/pii-data-privacy-vault/) is a platform for safely storing and using customers' sensitive and personal data. This chart enables you to deploy Piiano Vault [Server](https://piiano.com/docs/architecture/editions) on your self-hosted or cloud backed Kubernetes cluster.

To see all the available configurations, please refer to [Piiano Vault documentation websiet](https://piiano.com/docs/guides/configure/environment-variables).

## Prerequisites

* Kubernetes 1.24+
* Helm 3.7.2+
* Postgres 14 instance running and accessible (*)
* [Piiano Vault license](https://piiano.com/docs/guides/get-started#install-piiano-vault)

(*) This prerequisite could be automatically satisfied by the installer. See installation flags.

These are the earliest versions that have been tested. Earlier versions may also work.
## Installing the Chart

Add the repository:
```console
helm repo add piiano https://piiano.github.io/helm-charts
```

Select your use case:

1. [**Simplest local installation**](#simplest-local-installation) - try out the Vault on a local K8S cluster with a naive default configuration. This will also install the dependent postgres server. This mode is only meant for testing purposes.
2. [**Controlled installation**](#controlled-installation) - try out the Vault on a K8S cluster and connect it to your database or optionally install a postgres first.
3. [**AWS installation**](#aws-installation) - Try out the Vault on AWS EKS, connecting to your RDS postgres database or optionally install a postgres first. 
4. [**Fully automated installation**](#fully-automated-installation) - Use this option when you have fully configured the values.yaml to fit your needs.


### Installing postgres

Before installing Piiano Vault Server, you will need a running instance of Postgres 14.
It is recommended to use a managed cloud provider Postgres installation such as RDS in AWS or CloudSQL in GCP. The simplest local installation mode will install Postgres for you (skip this step). 

:warning: This installation is provided for testing purposes and is not meant for production. It is not backed up, not encrypted at REST, etc.
The postgres is installed with ephemeral storage. We assume that most local experiments will be done with Docker Desktop and it has a limitation with PVC configuration. It implies that restarting the postgres will wipe its database and will require restarting the Vault as well.

 You can use the following Helm command to deploy Postgres to your cluster:

```console
helm repo add my-repo https://charts.bitnami.com/bitnami
helm upgrade --install db my-repo/postgresql --namespace postgres --create-namespace \
    --set-string image.tag=14.5.0 \
    --set-string auth.username=pvault \
    --set-string auth.password=pvault \
    --set-string auth.database=pvault \
    --set primary.persistence.enabled=false 
```

### Simplest local installation

Deploy Piiano Vault Server on your local Kubernetes cluster while also installing postgres as part of this process:

```console
helm upgrade --install pvault-server piiano/pvault-server --namespace pvault --create-namespace \
    --set-string db.user=pvault \
    --set-string db.password=pvault \
    --set-string db.name=pvault \
    --set-string db.hostname=db-postgresql.postgres.svc.cluster.local \
    --set-string app.license=${PVAULT_SERVICE_LICENSE} \
    --set devmode=true
```

Continue with [post installation](#post-installation) checks.

### Controlled installation

Use the following command line to deploy Piiano Vault Server on a typical Kubernetes cluster.

1. Set the parameters: `DB_USER`, `DB_PASS`, `DB_HOST` and `DB_NAME`.
2. Run:
  ```console
    helm upgrade --install \
      --set devmode=true \
      --set-string db.user=${DB_USER} \
      --set-string db.password=${DB_PASS} \
      --set-string db.hostname=${DB_HOST} \
      --set-string db.name=${DB_NAME} \
      --set-string app.license=${PVAULT_SERVICE_LICENSE} \
      --set-string log.customerIdentifier=my-company-name \
      my-release piiano/pvault-server --create-namespace --namespace pvault
  ```

Continue with [post installation](#post-installation) checks.


### AWS installation

This section describes how to deploy a Piiano Vault Server on AWS EKS.

1. Set the parameters: `RDS_USER`, `RDS_PASS`, `RDS_HOST` and `RDS_NAME`.
2. Set the parameter: `NODE_INSTANCE_TYPE` such as `m6g.large`. For testing purposes you can use an instance as small as a single core and 1GB of RAM.
3. Configure a role to use in the following command. IAM role should have `kms:Decrypt` and `kms:Encrypt` permissions to the KMS key in the configuration. In addition, the IAM role should be configured to be assumed by the Service Account. You can set the Service Account name by using the parameter `serviceAccount.name`.
4. Run:
    ```console
    helm upgrade --install \
      --set devmode=true \
      --set-string db.user=${RDS_USER} \
      --set-string db.password=${RDS_PASS} \
      --set-string db.hostname=${RDS_HOST} \
      --set-string db.name=${RDS_NAME} \
      --set-string app.license=${PVAULT_SERVICE_LICENSE} \
      --set-string kms.uri=aws-kms://${KMS_ARN} \
      --set-string log.customerIdentifier=my-company-name \
      --set-string serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::123456789012:role/pvault-server-role \
      --set-string nodeSelector."node\.kubernetes\.io/instance-type"=${NODE_INSTANCE_TYPE} \
      my-release piiano/pvault-server --create-namespace --namespace pvault
    ```

Continue with [post installation](#post-installation) checks.

### Fully automated installation

The following will take all the installation parameters from the [values.yaml](values.yaml) file.
Use this after you have fully configured the Vault to your environment:

```console
helm install piiano/pvault-server
```

Continue with [post installation](#post-installation) checks.


## Post installation

Piiano Vault Server is now running! 

Once the installation is complete, use the following command to expose the port for Piiano Vault Server:

```console
kubectl port-forward --namespace pvault svc/pvault-server 8123:8123
```

You can then use the [Piiano Vault CLI](https://piiano.com/docs/cli) to interact with the server, by running the following commands:

```sh
# For easier interaction with the containerized CLI, set an alias.
alias pvault="docker run --rm -i -v $(pwd):/pwd -w /pwd piiano/pvault-cli:1.0.2"

pvault status
```

The expected output should be:

```console
+------+---------+
| data | control |
+------+---------+
| pass | pass    |
+------+---------+
```

See the [Getting Started](https://piiano.com/docs/guides/get-started/) documentation page for more detailed walkthrough.

## Uninstalling the Chart

To uninstall/delete the `my-release` release:

```
$ helm delete my-release
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

## Disclaimers

* This chart is provided as Beta version and the usage may break (including values name changes).
* All parameters starting with `existingSecrets` are not yet supported by Vault as of version 1.0.2. 
It will be supported for the next release.


## Parameters

### Common parameters

| Name               | Description                                              | Value |
| ------------------ | -------------------------------------------------------- | ----- |
| `nameOverride`     | String to override the default chart name.               | `""`  |
| `fullnameOverride` | String to override the default fully qualified app name. | `""`  |


### Controller parameters

| Name                                            | Description                                                                          | Value                  |
| ----------------------------------------------- | ------------------------------------------------------------------------------------ | ---------------------- |
| `replicaCount`                                  | Number of Piiano Vault Servers instances to run.                                     | `1`                    |
| `image.repository`                              | Piiano Vault Server image repositoryl                                                | `piiano/pvault-server` |
| `image.pullPolicy`                              | Piiano Vault Server image pull policy.                                               | `IfNotPresent`         |
| `image.tag`                                     | Piiano Vault Server image tag (immutable tags are recommended).                      | `1.0.2`                |
| `imagePullSecrets`                              | Specify image pull secrets.                                                          | `[]`                   |
| `serviceAccount.create`                         | Whether a service account should be created.                                         | `true`                 |
| `serviceAccount.annotations`                    | Annotations to add to the service account                                            | `{}`                   |
| `serviceAccount.name`                           | The name of the service account to use.                                              | `""`                   |
| `dnsPolicy`                                     | Default dnsPolicy setting                                                            | `ClusterFirst`         |
| `podAnnotations`                                | Add annotations to Piiano Vault Server pods.                                         | `{}`                   |
| `podSecurityContext`                            | Pod Security Context configuration.                                                  | `{}`                   |
| `securityContext`                               | Security Context configuration.                                                      | `{}`                   |
| `service.type`                                  | Kubernetes Service type. For example: ClusterIP / NodePort.                          | `ClusterIP`            |
| `service.port`                                  | Piiano Vault Server service port.                                                    | `8123`                 |
| `ingress.enabled`                               | Enable ingress generation.                                                           | `false`                |
| `ingress.className`                             | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)        | `""`                   |
| `ingress.annotations`                           | Additional custom annotations for the ingress record.                                | `{}`                   |
| `ingress.hosts`                                 | An array with additional hostname(s) to be covered with the ingress record.          | `nil`                  |
| `ingress.tls`                                   | TLS configuration for additional hostname(s) to be covered with this ingress record. | `[]`                   |
| `resources.limits`                              | The resources limits for the container.                                              | `{}`                   |
| `resources.requests`                            | The requested resources for the container.                                           | `{}`                   |
| `autoscaling.enabled`                           | Enable autoscaling for replicas.                                                     | `false`                |
| `autoscaling.minReplicas`                       | Minimum number of replicas.                                                          | `1`                    |
| `autoscaling.maxReplicas`                       | Maximum number of replicas.                                                          | `100`                  |
| `autoscaling.targetCPUUtilizationPercentage`    | Target CPU utilization percentage.                                                   | `80`                   |
| `autoscaling.targetMemoryUtilizationPercentage` | Target Memory utilization percentage.                                                | `undefined`            |
| `nodeSelector`                                  | Node labels for pod assignment.                                                      | `{}`                   |
| `tolerations`                                   | Tolerations for pod assignment.                                                      | `[]`                   |
| `affinity`                                      | Affinity for pod assignment.                                                         | `{}`                   |


### Piiano Vault parameters

| Name                               | Description                                                                                                                                                                                                    | Value        |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `db.user`                          | Username for the database. If `postgresql.enabled` is `true` then this value is ignored in favor of `postgresql.auth.username`.                                                                                | `pvault`     |
| `db.password`                      | Password for the database. If `postgresql.enabled` is `true` then this value is ignored in favor of `postgresql.auth.password`.                                                                                | `""`         |
| `db.existingPasswordSecret`        | The name of an existing secret containing the DB password.                                                                                                                                                     | `""`         |
| `db.existingPasswordSecretKey`     | The key in an existing secret that contains the DB password.                                                                                                                                                   | `""`         |
| `db.name`                          | Name of the database to connect to. If `postgresql.enabled` is `true` then this value is ignored in favor of `postgresql.primary.name`.                                                                        | `pvault`     |
| `db.hostname`                      | Hostname of the running database. If `postgresql.enabled` is `true` then this value is ignored.                                                                                                                | `""`         |
| `db.port`                          | Port of the running database.                                                                                                                                                                                  | `5432`       |
| `db.requireTLS`                    | Vault tries to connect to the database with TLS. Default is dependant on `devmode`.                                                                                                                            | `nil`        |
| `devmode`                          | Whether Vault runs in development mode.                                                                                                                                                                        | `false`      |
| `features.apiKeyHashing`           | Whether API keys for users are hashed when stored on the database.                                                                                                                                             | `true`       |
| `features.customTypesEnable`       | Whether Vault should read the pvault.types.toml file and apply the custom types, transformations and validators that it includes.                                                                              | `false`      |
| `features.encryption`              | This variable is ignored in production. In production, properties set as is_encrypted are always stored encrypted. When this variable is set to false (only in PVAULT_DEVMODE), properties stored unencrypted. | `true`       |
| `features.maskLicense`             | Whether Vault's service license will be masked while retrieving it.                                                                                                                                            | `false`      |
| `features.policyEnforcement`       | Whether policy management is enforced.                                                                                                                                                                         | `true`       |
| `app.adminAPIKey`                  | The admin API key for authentication.                                                                                                                                                                          | `pvaultauth` |
| `app.existingAdminAPIKeySecret`    | The name of an existing secret containing the admin API key.                                                                                                                                                   | `""`         |
| `app.existingAdminAPIKeySecretKey` | The key in an existing secret that contains the admin API key.                                                                                                                                                 | `""`         |
| `app.adminMayReadData`             | Whether Admin is allowed to read data. Default is dependant on `devmode`.                                                                                                                                      | `nil`        |
| `app.cacheRefreshIntervalSeconds`  | The refresh interval in seconds of the control data cache. If this value is zero the cache is disabled.                                                                                                        | `30`         |
| `app.defaultPageSize`              | The default page size for object queries when the page size is not specified. The page size is the maximum number of objects that may be requested in one call.                                                | `100`        |
| `app.maxPageSize`                  | The maximum page size that can be specified for a call. The page size is the maximum number of objects that may be requested in one call.                                                                      | `1000`       |
| `app.timeoutSeconds`               | Timeout in seconds for REST API calls.                                                                                                                                                                         | `30`         |
| `app.license`                      | A valid Piiano Vault license is required to start your Vault. The license is a string of characters.                                                                                                           | `""`         |
| `app.existingLicenseSecret`        | The name of an existing secret containing the license.                                                                                                                                                         | `""`         |
| `app.existingLicenseSecretKey`     | The key in an existing secret that contains the license.                                                                                                                                                       | `""`         |
| `kms.uri`                          | The KMS key URI used for property encryption.                                                                                                                                                                  | `""`         |
| `kms.seed`                         | Generate a local KMS using this seed (KMS_URI can be unset).                                                                                                                                                   | `""`         |
| `log.level`                        | Log level (supports `debug`, `info`, `warn`, and `error`).                                                                                                                                                     | `debug`      |
| `log.customerEnv`                  | Identifies the environment in all the observability platforms. Recommended values are `PRODUCTION`, `STAGING`, and `DEV`.                                                                                      | `unset`      |
| `log.customerIdentifier`           | Identifies the customer in all the observability platforms.                                                                                                                                                    | `unset`      |
| `log.datadogEnable`                | Enable Datadog logs and metrics.                                                                                                                                                                               | `false`      |
| `log.datadogEnv`                   | Controls env field of logs sent to Datadog.                                                                                                                                                                    | `dev`        |
| `log.datadogAPMEnable`             | Enable Datadog application performance monitoring (APM).                                                                                                                                                       | `false`      |
| `sentry.enable`                    | Enable Sentry telemetry logging.                                                                                                                                                                               | `false`      |
| `tls.enable`                       | Whether Vault listens on HTTPS (TLS). If `false`, Vault listens on HTTP. If PVAULT_TLS_SELFSIGNED is `true`, this setting is ignored and Vault listens on HTTPS. Default is dependant on `devmode`.            | `nil`        |
| `tls.selfsigned`                   | Whether Vault runs with a self-signed TLS key (valid for 24h).                                                                                                                                                 | `false`      |
| `tls.certFile`                     | Path to the TLS certificate file. Must be valid to enable listening on HTTPS (TLS).                                                                                                                            | `""`         |
| `tls.keyFile`                      | Path to the TLS key file. Must be valid to enable listening on HTTPS (TLS).                                                                                                                                    | `""`         |
| `extraEnvVars`                     | Overriding environment variables.                                                                                                                                                                              | `{}`         |


### Environment parameters

| Name                  | Description                                                                   | Value |
| --------------------- | ----------------------------------------------------------------------------- | ----- |
| `dbCARootCertificate` | Content of the CA certificate for the database TLS connection, in PEM format. | `nil` |


### Dependencies parameters

| Name                   | Description                                                                                                                                                     | Value    |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `postgresql.enabled`   | Whether or not to deploy a Postgres instance to the cluster. This is for experimentation purposes only and NOT for production. See ref for more configurations. | `false`  |
| `postgresql.image.tag` | Postgres image tag. Do not change.                                                                                                                              | `14.5.0` |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install my-release \
  --set db.requireTLS=true my-repo/pvault-server
```

The above command sets the Piiano Vault Server to require TLS connection to the database.

> NOTE: Once this chart is deployed, some of the configuration cannot be changed without restarting the server. Please refer to the documentation page for more information.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```console
$ helm install my-release -f values.yaml my-repo/pvault-server
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### Adding extra environment variables
Add extra [environment variables](https://piiano.com/docs/guides/configure/environment-variables) using the extraEnvVars property:

```console
extraEnvVars:
  - name: PVAULT_DB_MAX_OPEN_CONNS
    value: 200
```

## License

MIT
