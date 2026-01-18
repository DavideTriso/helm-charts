# WordPress Helm Chart

A production-ready Helm chart for deploying WordPress on Kubernetes with PHP-FPM, Nginx, and MySQL.

## Features

- **WordPress with PHP-FPM**: Latest WordPress running on PHP-FPM for better performance
- **Nginx Web Server**: High-performance Nginx as a reverse proxy
- **MySQL Database**: Integrated MySQL database with persistent storage
- **Persistent Storage**: Separate persistent volumes for WordPress content and MySQL data
- **WP-CLI Support**: Pre-configured WP-CLI for command-line management
- **Security Hardening**: 
  - Non-root containers
  - Read-only root filesystems where possible
  - Security context constraints
  - Disabled file editing in WordPress admin
- **Modern Kubernetes APIs**: Uses latest stable Kubernetes APIs
- **Horizontal Pod Autoscaling**: Optional HPA for WordPress pods
- **Ingress Support**: Built-in ingress configuration with TLS support
- **Configurable**: Extensive configuration options via values.yaml

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (if using persistent storage)
- (Optional) Ingress controller for external access
- (Optional) cert-manager for automatic TLS certificate management

## Installation

### ⚠️ Important Security Notice

**Before deploying to production**, you MUST change the default passwords in `values.yaml`:

```yaml
mysql:
  auth:
    rootPassword: "changeme"  # ← Change this!
    password: "wordpress"      # ← Change this!
```

The default passwords are intentionally weak for development/testing purposes only. For production:

1. Generate strong, random passwords:
   ```bash
   # Example using openssl
   ROOT_PASS=$(openssl rand -base64 32)
   DB_PASS=$(openssl rand -base64 32)
   ```

2. Create a values file with secure passwords:
   ```bash
   cat > secure-values.yaml << EOF
   mysql:
     auth:
       rootPassword: "$ROOT_PASS"
       password: "$DB_PASS"
   EOF
   ```

3. Install using the secure values:
   ```bash
   helm install my-wordpress ./wordpress -f secure-values.yaml
   ```

Alternatively, use Kubernetes Secrets to manage passwords separately.

### Quick Start

Install with default values:

```bash
helm install my-wordpress ./wordpress
```

### Install with Custom Values

The chart includes example values files for common scenarios:

- `values-production.yaml` - Production configuration with HA, autoscaling, and security best practices
- `values-external-db.yaml` - Configuration for using an external MySQL database

Use an example file as a starting point:

```bash
# Copy and customize for your needs
cp wordpress/values-production.yaml my-values.yaml
# Edit my-values.yaml with your configuration
# Install with your custom values
helm install my-wordpress ./wordpress -f my-values.yaml
```

Or create a custom values file from scratch:

```yaml
wordpress:
  config:
    siteUrl: "https://myblog.example.com"

mysql:
  auth:
    rootPassword: "my-secure-root-password"
    password: "my-secure-password"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: myblog.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myblog-tls
      hosts:
        - myblog.example.com
```

Install with custom values:

```bash
helm install my-wordpress ./wordpress -f custom-values.yaml
```

### Install with External Database

If you want to use an external MySQL database instead of the bundled one:

```yaml
mysql:
  enabled: false

externalDatabase:
  host: "mysql.example.com"
  port: 3306
  database: "wordpress"
  username: "wordpress"
  password: "secure-password"
```

## Configuration

The following table lists the main configurable parameters of the WordPress chart and their default values.

### WordPress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wordpress.image.repository` | WordPress image repository | `wordpress` |
| `wordpress.image.tag` | WordPress image tag | `6.7-php8.3-fpm-alpine` |
| `wordpress.config.siteUrl` | WordPress site URL | `https://chart-example.local` |
| `wordpress.config.tablePrefix` | Database table prefix | `wp_` |
| `wordpress.persistence.enabled` | Enable persistent storage | `true` |
| `wordpress.persistence.size` | Size of persistent volume | `10Gi` |
| `wordpress.resources.requests.memory` | Memory request | `256Mi` |
| `wordpress.resources.limits.memory` | Memory limit | `512Mi` |

### Nginx Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nginx.image.repository` | Nginx image repository | `nginx` |
| `nginx.image.tag` | Nginx image tag | `1.27-alpine` |
| `nginx.resources.requests.memory` | Memory request | `64Mi` |
| `nginx.resources.limits.memory` | Memory limit | `128Mi` |

### MySQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mysql.enabled` | Enable MySQL deployment | `true` |
| `mysql.image.repository` | MySQL image repository | `mysql` |
| `mysql.image.tag` | MySQL image tag | `8.4` |
| `mysql.auth.rootPassword` | MySQL root password | `changeme` |
| `mysql.auth.database` | WordPress database name | `wordpress` |
| `mysql.auth.username` | WordPress database user | `wordpress` |
| `mysql.auth.password` | WordPress database password | `wordpress` |
| `mysql.persistence.enabled` | Enable persistent storage | `true` |
| `mysql.persistence.size` | Size of persistent volume | `10Gi` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts` | Ingress hosts | `[{host: chart-example.local, paths: [{path: /, pathType: Prefix}]}]` |
| `ingress.tls` | TLS configuration | See values.yaml |

For a complete list of configuration parameters, see [values.yaml](./wordpress/values.yaml).

## Accessing WordPress

After installation, follow the instructions in the NOTES output to access your WordPress site.

### Port Forward (for testing)

```bash
kubectl port-forward svc/my-wordpress 8080:80
```

Then access http://localhost:8080

### Using Ingress

If ingress is enabled, access your site at the configured hostname (e.g., https://myblog.example.com)

## Using WP-CLI

WP-CLI is available in the WordPress container:

```bash
# Get pod name
export POD_NAME=$(kubectl get pods -l "app.kubernetes.io/name=wordpress,app.kubernetes.io/instance=my-wordpress" -o jsonpath="{.items[0].metadata.name}")

# Run WP-CLI commands
kubectl exec -it $POD_NAME -c wordpress -- /usr/local/bin/wp --info
kubectl exec -it $POD_NAME -c wordpress -- /usr/local/bin/wp plugin list
kubectl exec -it $POD_NAME -c wordpress -- /usr/local/bin/wp theme list
```

## Upgrading

To upgrade your release:

```bash
helm upgrade my-wordpress ./wordpress -f custom-values.yaml
```

## Uninstalling

To uninstall/delete the deployment:

```bash
helm uninstall my-wordpress
```

**Note**: This command will not delete the PersistentVolumeClaims. To delete them:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=my-wordpress
```

## Architecture

The chart deploys the following components:

```
┌─────────────────────────────────────────┐
│            Kubernetes Cluster            │
│                                         │
│  ┌────────────┐      ┌──────────────┐  │
│  │  Ingress   │──────▶│   Service    │  │
│  └────────────┘      └──────────────┘  │
│                            │            │
│                    ┌───────▼────────┐   │
│                    │  WordPress Pod  │   │
│                    │                │   │
│                    │  ┌──────────┐  │   │
│                    │  │  Nginx   │  │   │
│                    │  │  :8080   │  │   │
│                    │  └────┬─────┘  │   │
│                    │       │        │   │
│                    │  ┌────▼──────┐ │   │
│                    │  │WordPress  │ │   │
│                    │  │ PHP-FPM   │ │   │
│                    │  │  :9000    │ │   │
│                    │  └───────────┘ │   │
│                    └────────────────┘   │
│                            │            │
│                    ┌───────▼────────┐   │
│                    │ MySQL Service  │   │
│                    └───────┬────────┘   │
│                            │            │
│                    ┌───────▼────────┐   │
│                    │ MySQL Pod      │   │
│                    │   :3306        │   │
│                    └────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Persistent Volumes             │   │
│  │  - WordPress wp-content         │   │
│  │  - MySQL data                   │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Components

1. **Init Container**: Copies WordPress source files to a shared emptyDir volume
2. **WordPress Container**: Runs PHP-FPM and serves WordPress application
3. **Nginx Container**: Acts as a web server and reverse proxy to PHP-FPM
4. **MySQL StatefulSet**: Provides database persistence
5. **Persistent Volumes**: Store wp-content and MySQL data

## Security Considerations

1. **Change Default Passwords**: Always change the default MySQL passwords in production
2. **Use Secrets**: Store sensitive data in Kubernetes Secrets
3. **TLS/HTTPS**: Enable TLS for production deployments
4. **Regular Updates**: Keep WordPress, plugins, and themes updated
5. **Backups**: Implement regular backup strategy for persistent volumes
6. **Network Policies**: Consider implementing network policies to restrict traffic

## Troubleshooting

### Pod is not starting

Check pod status and logs:

```bash
kubectl get pods -l app.kubernetes.io/name=wordpress
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c wordpress
kubectl logs <pod-name> -c nginx
```

### Database connection errors

Verify MySQL is running:

```bash
kubectl get pods -l app.kubernetes.io/component=database
kubectl logs <mysql-pod-name>
```

### Permission issues

Check the security context and volume permissions:

```bash
kubectl exec -it <pod-name> -c wordpress -- ls -la /var/www/html/wp-content
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [WordPress-Nginx-Helm-Chart](https://github.com/fiveoclock/WordPress-Nginx-Helm-Chart)
- WordPress official Docker images
- Kubernetes and Helm communities
