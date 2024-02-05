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

This package is compatible with Vault version 1.10.2

## Installing the Chart

Add the repository:
```console
helm repo add piiano https://piiano.github.io/helm-charts
```

Select your use case:

1. [**Simplest local installation**](#simplest-local-installation) - Try out the Vault on a local Kubernetes cluster with a naive default configuration. This will also install the dependent Postgres server. This mode is only meant for testing purposes.
2. [**Controlled installation**](#controlled-installation) - Try out the Vault on a Kubernetes cluster and connect it to your database or optionally install a Postgres first.
3. [**AWS installation**](#aws-installation) - Try out the Vault on AWS EKS, connecting to your RDS Postgres database or optionally install a Postgres first. 
4. [**Fully automated installation**](#fully-automated-installation) - Use this option when you have fully configured the values.yaml to fit your needs.


### Installing Postgres

Before installing Piiano Vault Server, you will need a running instance of Postgres 14.
It is recommended to use a managed cloud provider Postgres installation such as RDS in AWS or CloudSQL in GCP. The simplest local installation mode will install Postgres for you (skip this step). 

:warning: This installation is provided for testing purposes and is not meant for production. It is not backed up, not encrypted at REST, etc.

You can use the following Helm command to deploy Postgres to your cluster:

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install db bitnami/postgresql --namespace postgres --create-namespace \
    --set-string image.tag=14.5.0 \
    --set-string auth.username=pvault \
    --set-string auth.password=pvault \
    --set-string auth.database=pvault \
    --set primary.persistence.enabled=false 
```

Postgres will be available from within the cluster with the following hostname: `db-postgresql.postgres.svc.cluster.local`.

Note that the command line deploys the Postgres instance with ephemeral storage. It implies that restarting the Postgres will wipe the database and will require restarting the Vault as well.

### Simplest local installation

Deploy Piiano Vault Server on your local Kubernetes cluster while also installing Postgres as part of this process:

```console
helm upgrade --install pvault-server piiano/pvault-server --namespace pvault --create-namespace \
    --set pvault.devmode=true \
    --set-string pvault.app.license=${PVAULT_SERVICE_LICENSE} \
    --set-string pvault.log.customerIdentifier=my-company-name \
    --set postgresql.enabled=true
```

Please allow up to 15 seconds for the system startup to complete.

Continue with [post installation](#post-installation) checks.

### Controlled installation

Use the following command line to deploy Piiano Vault Server on a typical Kubernetes cluster.

1. Set the parameters: `DB_USER`, `DB_PASS`, `DB_HOST` and `DB_NAME`.
2. Run:
  ```console
    helm upgrade --install pvault-server piiano/pvault-server \ 
      --create-namespace --namespace pvault \
      --set pvault.devmode=true \
      --set-string pvault.db.user=${DB_USER} \
      --set-string pvault.db.password=${DB_PASS} \
      --set-string pvault.db.hostname=${DB_HOST} \
      --set-string pvault.db.name=${DB_NAME} \
      --set-string pvault.app.license=${PVAULT_SERVICE_LICENSE} \
      --set-string pvault.log.customerIdentifier=my-company-name
  ```

Continue with [post installation](#post-installation) checks.


### AWS installation

This section describes how to deploy a Piiano Vault Server on AWS EKS.

1. Set the parameters: `RDS_USER`, `RDS_PASS`, `RDS_HOST` and `RDS_NAME`.
2. Set the parameter: `NODE_INSTANCE_TYPE` such as `m6g.large`. For testing purposes you can use an instance as small as a single core and 1GB of RAM.
3. Configure an IAM role to use in the following command. IAM role should have `kms:Decrypt` and `kms:Encrypt` permissions to the KMS key in the configuration. In addition, the IAM role should be configured to be assumed by the Service Account (see [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)). You can set the Service Account name by using the parameter `serviceAccount.name`.
4. Run:
    ```console
    helm upgrade --install pvault-server piiano/pvault-server \
      --create-namespace --namespace pvault \
      --set pvault.devmode=true \
      --set-string pvault.db.user=${RDS_USER} \
      --set-string pvault.db.password=${RDS_PASS} \
      --set-string pvault.db.hostname=${RDS_HOST} \
      --set-string pvault.db.name=${RDS_NAME} \
      --set-string pvault.app.license=${PVAULT_SERVICE_LICENSE} \
      --set-string pvault.kms.uri=aws-kms://${KMS_ARN} \
      --set-string pvault.log.customerIdentifier=my-company-name \
      --set-string serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::123456789012:role/pvault-server-role \
      --set-string serviceAccount.name=pvault-sa \
      --set-string nodeSelector."node\.kubernetes\.io/instance-type"=${NODE_INSTANCE_TYPE}
    ```

Continue with [post installation](#post-installation) checks.

### Azure installation

This section describes how to deploy a Piiano Vault Server on Azure AKS.

1. Set the parameters (**NOTE:** if using [Vault Deployments - AKS Bicep Setup](https://github.com/piiano/vault-deployments/tree/main/azure-aks-setup-bicep), the values for those parameters are the outputs of the deployment):
   * DB: `DB_USER`, `DB_PASS`, `DB_HOST` and `DB_NAME`.
   * Key Vault: `KEYVAULT_URI`, `KEYVAULT_KEY_NAME`, `KEYVAULT_VERSION`.
   * Managed Identity: `MANAGED_IDENTITY_CLIENT_ID`.
2. Run:
    ```console
    helm upgrade --install pvault-server piiano/pvault-server \
      --create-namespace --namespace pvault \
      --set-string pvault.log.datadogEnable=none \
      --set pvault.devmode=true \
      --set-string pvault.db.user=${DB_USER} \
      --set-string pvault.db.password=${DB_PASS} \
      --set-string pvault.db.hostname=${DB_HOST} \
      --set-string pvault.db.name=${DB_NAME} \
      --set pvault.db.requireTLS=true \
      --set-string pvault.app.license=${PVAULT_SERVICE_LICENSE} \
      --set-string pvault.kms.uri=az-kms://${KEYVAULT_URI}/keys/${KEYVAULT_KEY_NAME}/${KEYVAULT_VERSION} \
      --set-string pvault.log.customerIdentifier=my-company-name \
      --set-string serviceAccount.annotations."azure\.workload\.identity/client-id"=${MANAGED_IDENTITY_CLIENT_ID} \
      --set-string serviceAccount.name=pvault-sa \
      --set-string podLabels."azure\.workload\.identity/use"=true \
      --set-string pvault.extraEnvVars.PVAULT_DB_MIGRATION_ENABLE_CLEAN_DATABASE_VALIDATION=false
    ```

**Note:** Cosmos DB for PostgresSQL uses [Citus](https://learn.microsoft.com/en-us/azure/cosmos-db/postgresql/introduction) which comes with built-in tables. The Piiano Vault migration will fail for "clean database validation" because of these tables. Setting the environment variable `PVAULT_DB_MIGRATION_ENABLE_CLEAN_DATABASE_VALIDATION` value to `false` will skip the validation and allow the migration to complete. If you are using other PostgresSQL setup, you can skip this configuration.

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
alias pvault="docker run --rm -i -v $(pwd):/pwd -w /pwd piiano/pvault-cli:1.1.2"

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

To uninstall/delete the `pvault-server` release:

```
$ helm delete pvault-server --namespace pvault
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

## Disclaimers

* This chart is provided as Beta version and the usage may break (including values name changes).

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
| `image.tag`                                     | Piiano Vault Server image tag (immutable tags are recommended).                      | `1.10.2`                |
| `imagePullSecrets`                              | Specify image pull secrets.                                                          | `[]`                   |
| `serviceAccount.create`                         | Whether a service account should be created.                                         | `true`                 |
| `serviceAccount.annotations`                    | Annotations to add to the service account                                            | `{}`                   |
| `serviceAccount.name`                           | The name of the service account to use.                                              | `""`                   |
| `dnsPolicy`                                     | Default dnsPolicy setting                                                            | `ClusterFirst`         |
| `podLabels`                                     | Add labels to Piiano Vault Server pods.                                              | `{}`                   |
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
| `additionalSecretsAnnotations`                  | Add annotations to the Kubernetes secret.                                            | `{}`                   |
| `additionalConfigMapAnnotations`                | Add annotations to the ConfigMaps.                                                   | `{}`                   |

### Piiano Vault parameters

| Name                                      | Description                                                                                                                                                                                                    | Value               |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `pvault.db.user`                          | Username for the database. If `postgresql.enabled` is `true` then this value is ignored in favor of `postgresql.auth.username`.                                                                                | `pvault`            |
| `pvault.db.password`                      | Password for the database. If `postgresql.enabled` is `true` then this value is ignored in favor of `postgresql.auth.password`.                                                                                | `""`                |
| `pvault.db.existingPasswordSecret`        | The name of an existing secret containing the DB password.                                                                                                                                                     | `""`                |
| `pvault.db.existingPasswordSecretKey`     | The key in an existing secret that contains the DB password.                                                                                                                                                   | `""`                |
| `pvault.db.name`                          | Name of the database to connect to. If `postgresql.enabled` is `true` then this value is ignored in favor of `postgresql.auth.database`.                                                                       | `pvault`            |
| `pvault.db.hostname`                      | Hostname of the running database. If `postgresql.enabled` is `true` then this value is ignored.                                                                                                                | `""`                |
| `pvault.db.port`                          | Port of the running database.                                                                                                                                                                                  | `5432`              |
| `pvault.db.requireTLS`                    | Vault tries to connect to the database with TLS. Default is dependant on `devmode`.                                                                                                                            | `nil`               |
| `pvault.devmode`                          | Whether Vault runs in development mode.                                                                                                                                                                        | `false`             |
| `pvault.features.apiKeyHashing`           | Whether API keys for users are hashed when stored on the database.                                                                                                                                             | `true`              |
| `pvault.features.customTypesEnable`       | Whether Vault should read the pvault.types.toml file and apply the custom types, transformations and validators that it includes.                                                                              | `false`             |
| `pvault.features.encryption`              | This variable is ignored in production. In production, properties set as is_encrypted are always stored encrypted. When this variable is set to false (only in PVAULT_DEVMODE), properties stored unencrypted. | `true`              |
| `pvault.features.maskLicense`             | Whether Vault's service license will be masked while retrieving it.                                                                                                                                            | `false`             |
| `pvault.features.policyEnforcement`       | Whether policy management is enforced.                                                                                                                                                                         | `true`              |
| `pvault.app.adminAPIKey`                  | The admin API key for authentication.                                                                                                                                                                          | `pvaultauth`        |
| `pvault.app.existingAdminAPIKeySecret`    | The name of an existing secret containing the admin API key.                                                                                                                                                   | `""`                |
| `pvault.app.existingAdminAPIKeySecretKey` | The key in an existing secret that contains the admin API key.                                                                                                                                                 | `""`                |
| `pvault.app.adminMayReadData`             | Whether Admin is allowed to read data. Default is dependant on `devmode`.                                                                                                                                      | `nil`               |
| `pvault.app.cacheRefreshIntervalSeconds`  | The refresh interval in seconds of the control data cache. If this value is zero the cache is disabled.                                                                                                        | `30`                |
| `pvault.app.defaultPageSize`              | The default page size for object queries when the page size is not specified. The page size is the maximum number of objects that may be requested in one call.                                                | `100`               |
| `pvault.app.maxPageSize`                  | The maximum page size that can be specified for a call. The page size is the maximum number of objects that may be requested in one call.                                                                      | `1000`              |
| `pvault.app.timeoutSeconds`               | Timeout in seconds for REST API calls.                                                                                                                                                                         | `30`                |
| `pvault.app.license`                      | A valid Piiano Vault license is required to start your Vault. The license is a string of characters.                                                                                                           | `""`                |
| `pvault.app.existingLicenseSecret`        | The name of an existing secret containing the license.                                                                                                                                                         | `""`                |
| `pvault.app.existingLicenseSecretKey`     | The key in an existing secret that contains the license.                                                                                                                                                       | `""`                |
| `pvault.app.setIAMOnStartOnly`            | Whether to load the IAM configuration file every time Vault starts.                                                                                                                                            | `false`             |
| `pvault.app.updateSchemaOnStart`          | Whether to update the collections schema every time Vault starts.                                                                                                                                              | `false`             |
| `pvault.kms.uri`                          | The KMS key URI used for property encryption.                                                                                                                                                                  | `""`                |
| `pvault.kms.seed`                         | Generate a local KMS using this seed (KMS_URI can be unset).                                                                                                                                                   | `""`                |
| `pvault.kms.exportUri`                    | The KMS key URI used for encryption by the Vault export procedure.                                                                                                                                             | `""`                |
| `pvault.kms.exportSeed`                   | The seed for generating a local KMS for the Vault export procedure (KMS_EXPORT_URI can be unset).                                                                                                              | `""`                |
| `pvault.kms.existingSeedSecret`           | The name of an existing secret containing the KMS seed.                                                                                                                                                        | `""`                |
| `pvault.kms.existingSeedSecretKey`        | The key in an existing secret that contains the KMS seed.                                                                                                                                                      | `""`                |
| `pvault.kms.existingExportSeedSecret`     | The name of an existing secret containing the KMS export seed.                                                                                                                                                 | `""`                |
| `pvault.kms.existingExportSeedSecretKey`  | The key in an existing secret that contains the KMS export seed.                                                                                                                                               | `""`                |
| `pvault.kms.allow_local`                  | Whether to allow a local KMS using a URI or seed. Default is dependant on `devmode`.                                                                                                                           | `nil`               |
| `pvault.log.level`                        | Log level (supports `debug`, `info`, `warn`, and `error`).                                                                                                                                                     | `debug`             |
| `pvault.log.customerEnv`                  | Identifies the environment in all the observability platforms. Recommended values are `prod`, `staging`, and `dev`.                                                                                            | `dev`               |
| `pvault.log.customerIdentifier`           | Identifies the customer in all the observability platforms.                                                                                                                                                    | `""`                |
| `pvault.log.datadogEnable`                | Enable Datadog logs and metrics.                                                                                                                                                                               | `logs,stats,config` |
| `pvault.log.datadogAPMEnable`             | Enable Datadog application performance monitoring (APM).                                                                                                                                                       | `false`             |
| `pvault.sentry.enable`                    | Enable Sentry telemetry logging.                                                                                                                                                                               | `true`              |
| `pvault.tls.enable`                       | Whether Vault listens on HTTPS (TLS). If `false`, Vault listens on HTTP. If PVAULT_TLS_SELFSIGNED is `true`, this setting is ignored and Vault listens on HTTPS. Default is dependant on `devmode`.            | `nil`               |
| `pvault.tls.selfsigned`                   | Whether Vault runs with a self-signed TLS key (valid for 24h).                                                                                                                                                 | `false`             |
| `pvault.tls.certFile`                     | Path to the TLS certificate file. Must be valid to enable listening on HTTPS (TLS).                                                                                                                            | `""`                |
| `pvault.tls.keyFile`                      | Path to the TLS key file. Must be valid to enable listening on HTTPS (TLS).                                                                                                                                    | `""`                |
| `pvault.startupIAMFile`                   | Vault startup file for IAM configuration.                                                                                                                                                                      | `""`                |
| `pvault.startupCollectionsFile`           | Vault startup file for schema configuration.                                                                                                                                                                   | `""`                |
| `pvault.startupDataTypesFile`             | Vault startup file for data types configuration.                                                                                                                                                               | `""`                |
| `pvault.extraEnvVars`                     | Overriding environment variables.                                                                                                                                                                              | `{}`                |

### Environment parameters

| Name                  | Description                                                                   | Value |
| --------------------- | ----------------------------------------------------------------------------- | ----- |
| `dbCARootCertificate` | Content of the CA certificate for the database TLS connection, in PEM format. | `nil` |

### Dependencies parameters

| Name                                     | Description                                                                                                                                                     | Value    |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `postgresql.enabled`                     | Whether or not to deploy a Postgres instance to the cluster. This is for experimentation purposes only and NOT for production. See ref for more configurations. | `false`  |
| `postgresql.image.tag`                   | Postgres image tag. Do not change.                                                                                                                              | `14.5.0` |
| `postgresql.auth.database`               | Name of the database. It is unlikely that you will need to change this parameter.                                                                               | `pvault` |
| `postgresql.auth.username`               | Postgres username. It is unlikely that you will need to change this parameter.                                                                                  | `pvault` |
| `postgresql.auth.password`               | Postgres password. It is unlikely that you will need to change this parameter.                                                                                  | `pvault` |
| `postgresql.primary.persistence.enabled` | Use ephemeral storage for Postgres. When `false`, a PVC is not created.                                                                                         | `false`  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install pvault-server \
  --set db.requireTLS=true piiano/pvault-server
```

The above command sets the Piiano Vault Server to require TLS connection to the database.

> NOTE: Once this chart is deployed, some of the configuration cannot be changed without restarting the server. Please refer to the documentation page for more information.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```console
$ helm install pvault-server -f values.yaml piiano/pvault-server
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
