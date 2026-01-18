# WordPress Helm Chart - Quick Start Guide

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume provisioner (for storage)
- (Optional) Ingress controller (e.g., nginx-ingress)
- (Optional) cert-manager (for TLS certificates)

## Installation Steps

### 1. Clone or Download the Chart

```bash
git clone https://github.com/DavideTriso/wordpress-helm.git
cd wordpress-helm
```

### 2. Review and Customize Values

**For Development/Testing:**
```bash
# Use default values (WARNING: insecure passwords!)
helm install my-wordpress ./wordpress
```

**For Production:**
```bash
# Generate secure passwords
ROOT_PASS=$(openssl rand -base64 32)
DB_PASS=$(openssl rand -base64 32)

# Create custom values file
cat > my-values.yaml << EOF
wordpress:
  config:
    siteUrl: "https://yourdomain.com"

mysql:
  auth:
    rootPassword: "$ROOT_PASS"
    password: "$DB_PASS"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: yourdomain-tls
      hosts:
        - yourdomain.com
EOF

# Install with custom values
helm install my-wordpress ./wordpress -f my-values.yaml
```

### 3. Access WordPress

**If using Ingress:**
```bash
# Wait for ingress to be ready
kubectl get ingress

# Access at your configured domain
# https://yourdomain.com
```

**If using port-forward (development):**
```bash
kubectl port-forward svc/my-wordpress 8080:80
# Access at http://localhost:8080
```

### 4. Complete WordPress Setup

1. Open WordPress in your browser
2. Select your language
3. Create admin account
4. Start blogging!

## Common Operations

### View Pod Status
```bash
kubectl get pods -l app.kubernetes.io/name=wordpress
```

### View Logs
```bash
# WordPress logs
kubectl logs -l app.kubernetes.io/name=wordpress -c wordpress -f

# Nginx logs
kubectl logs -l app.kubernetes.io/name=wordpress -c nginx -f

# MySQL logs
kubectl logs -l app.kubernetes.io/component=database -f
```

### Use WP-CLI
```bash
# Get WordPress pod name
POD=$(kubectl get pods -l app.kubernetes.io/name=wordpress -o jsonpath='{.items[0].metadata.name}')

# Run WP-CLI commands
kubectl exec -it $POD -c wordpress -- /usr/local/bin/wp --info
kubectl exec -it $POD -c wordpress -- /usr/local/bin/wp plugin list
kubectl exec -it $POD -c wordpress -- /usr/local/bin/wp theme list
```

### Scale WordPress
```bash
# Manual scaling
kubectl scale deployment my-wordpress --replicas=3

# Or enable autoscaling in values.yaml:
# autoscaling:
#   enabled: true
#   minReplicas: 2
#   maxReplicas: 10
```

### Backup Data

**WordPress Content:**
```bash
# Get PVC name
kubectl get pvc -l app.kubernetes.io/name=wordpress

# Create backup (example using kubectl cp)
POD=$(kubectl get pods -l app.kubernetes.io/name=wordpress -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -c wordpress -- tar czf /tmp/wp-content-backup.tar.gz /var/www/html/wp-content
kubectl cp $POD:/tmp/wp-content-backup.tar.gz ./wp-content-backup.tar.gz -c wordpress
```

**MySQL Database:**
```bash
# Get MySQL pod
MYSQL_POD=$(kubectl get pods -l app.kubernetes.io/component=database -o jsonpath='{.items[0].metadata.name}')

# Get MySQL root password
MYSQL_ROOT_PASSWORD=$(kubectl get secret my-wordpress-mysql -o jsonpath='{.data.mysql-root-password}' | base64 -d)

# Create database backup
kubectl exec -it $MYSQL_POD -- mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress > wordpress-backup.sql
```

### Upgrade WordPress

```bash
# Update values if needed
vim my-values.yaml

# Upgrade the release
helm upgrade my-wordpress ./wordpress -f my-values.yaml

# Rollback if needed
helm rollback my-wordpress
```

### Uninstall

```bash
# Delete the release
helm uninstall my-wordpress

# Delete PVCs (if you want to remove data)
kubectl delete pvc -l app.kubernetes.io/instance=my-wordpress
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name> -c wordpress
kubectl logs <pod-name> -c nginx
```

### Database Connection Issues

```bash
# Verify MySQL is running
kubectl get pods -l app.kubernetes.io/component=database

# Check MySQL logs
kubectl logs <mysql-pod-name>

# Test connection from WordPress pod
POD=$(kubectl get pods -l app.kubernetes.io/name=wordpress -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -c wordpress -- nc -zv my-wordpress-mysql 3306
```

### Permission Issues

```bash
# Check security context
kubectl get pod <pod-name> -o yaml | grep -A 10 securityContext

# Exec into pod and check permissions
kubectl exec -it <pod-name> -c wordpress -- ls -la /var/www/html/
```

## Security Best Practices

1. **Always change default passwords** in production
2. **Use strong passwords** (32+ characters, random)
3. **Enable HTTPS** with valid TLS certificates
4. **Keep WordPress updated** (plugins, themes, core)
5. **Implement backups** regularly
6. **Use network policies** to restrict traffic
7. **Monitor logs** for suspicious activity
8. **Use secrets** for sensitive data (not plain text in values)

## Next Steps

- Configure automatic backups
- Set up monitoring (Prometheus, Grafana)
- Configure CDN for static assets
- Implement Redis/Memcached for caching
- Set up staging environment
- Configure CI/CD for deployments

## Support

- **Issues**: https://github.com/DavideTriso/wordpress-helm/issues
- **Documentation**: See README.md
- **WordPress**: https://wordpress.org/documentation/
- **Kubernetes**: https://kubernetes.io/docs/

## License

This chart is licensed under the MIT License.
