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
