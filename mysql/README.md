# MySQL Helm Chart

## Features

- StatefulSet with persistent storage
- Configurable resource limits and probes
- MySQL custom configuration support

## Prerequisites

**You must create a Kubernetes Secret before installing this chart.** The chart will not create secrets for you - this ensures credentials are never stored in values files or version control.

Secret keys:
* `mysql-root-password` (required)
* `mysql-password` (required if `mysql.user` is configured)

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secret.existingSecret` | Name of existing secret (required) | `""` |
| `mysql.database` | Database to create | `"myapp"` |
| `mysql.user` | User to create | `"myappuser"` |
| `mysql.config` | MySQL configuration | See values.yaml |
| `persistence.enabled` | Enable persistence | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `persistence.storageClass` | Storage class | `""` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.limits.cpu` | CPU limit | `1000m` |