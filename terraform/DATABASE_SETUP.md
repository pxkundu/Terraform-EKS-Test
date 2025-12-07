# Azure Database for PostgreSQL Setup Guide

## Overview

This guide explains the Azure Database for PostgreSQL configuration in the infrastructure, including setup, security, and best practices.

## Architecture

The database module provides:
- **Azure Database for PostgreSQL Flexible Server**: Managed PostgreSQL service
- **Private Endpoints**: Secure connectivity from VNet
- **High Availability**: Optional zone-redundant configuration
- **Automated Backups**: Configurable retention
- **Monitoring**: Integration with Log Analytics
- **Firewall Rules**: Network-based access control

## Features

### Security
- Private endpoint connectivity
- Azure AD authentication
- Network firewall rules
- Encrypted connections (TLS)
- Managed identity integration

### High Availability
- Zone-redundant storage
- Optional high availability mode
- Automated failover

### Backup & Recovery
- Automated backups
- Point-in-time restore
- Geo-redundant backup option
- Configurable retention

### Monitoring
- Diagnostic settings
- Log Analytics integration
- Performance metrics

## Configuration

### Basic Configuration

In `main.tf`, the database is configured with:

```hcl
module "database" {
  source = "./modules/database"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.cluster_name
  environment         = var.environment
  vnet_id             = module.vnet.vnet_id
  subnet_id           = module.vnet.private_subnets[1]
  
  database_name    = "appdb"
  db_username      = "dbadmin"
  postgres_version = "15"
  sku_name         = "B_Standard_B1ms"
}
```

### Environment-Specific Configuration

#### Development

```hcl
database_sku                    = "B_Standard_B1ms"  # Burstable, 1 vCore
database_storage_mb             = 32768              # 32 GB
database_backup_retention_days  = 7
database_geo_redundant_backup   = false
```

#### Staging

```hcl
database_sku                    = "GP_Standard_D2s_v3"  # General Purpose, 2 vCores
database_storage_mb             = 131072                 # 128 GB
database_backup_retention_days  = 14
database_geo_redundant_backup   = true
```

#### Production

```hcl
database_sku                    = "GP_Standard_D4s_v3"  # General Purpose, 4 vCores
database_storage_mb             = 262144                 # 256 GB
database_backup_retention_days  = 35
database_geo_redundant_backup   = true
high_availability_mode         = "ZoneRedundant"
```

## SKU Selection Guide

### Burstable (B-series)
- **Use Case**: Development, testing, low-traffic applications
- **Examples**: `B_Standard_B1ms`, `B_Standard_B2s`
- **Cost**: Lower cost, suitable for variable workloads

### General Purpose (GP-series)
- **Use Case**: Most production workloads
- **Examples**: `GP_Standard_D2s_v3`, `GP_Standard_D4s_v3`
- **Cost**: Balanced performance and cost

### Memory Optimized (MO-series)
- **Use Case**: High-performance, memory-intensive workloads
- **Examples**: `MO_Standard_E4s_v3`, `MO_Standard_E8s_v3`
- **Cost**: Higher cost, maximum performance

## Connection from AKS

### Using Connection String

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  connection-string: "postgresql://dbadmin@<server-fqdn>:5432/appdb"
  password: "<password>"
```

### Using Managed Identity

1. **Enable AAD Authentication**:
   ```hcl
   enable_aad_auth = true
   ```

2. **Grant Access**:
   ```bash
   az postgres flexible-server ad-admin create \
     --resource-group <rg> \
     --server-name <server-name> \
     --display-name <aad-user> \
     --object-id <object-id>
   ```

## Network Configuration

### Private Endpoint

The database is deployed with a private endpoint by default:

```hcl
subnet_id = module.vnet.private_subnets[1]  # Dedicated subnet for database
```

### Firewall Rules

Configure allowed subnets:

```hcl
allowed_subnet_ids   = module.vnet.private_subnets
allowed_subnet_cidrs = var.private_subnets
```

### Custom IP Rules

```hcl
allowed_ip_ranges = {
  "office" = {
    start_ip = "203.0.113.0"
    end_ip   = "203.0.113.255"
  }
}
```

## Backup Configuration

### Automated Backups

- **Retention**: Configurable (7-35 days)
- **Frequency**: Continuous
- **Restore**: Point-in-time restore available

### Geo-Redundant Backup

Enable for production:

```hcl
database_geo_redundant_backup = true
```

### Manual Backup

```bash
az postgres flexible-server backup create \
  --resource-group <rg> \
  --server-name <server-name> \
  --backup-name <backup-name>
```

## High Availability

### Zone Redundant Configuration

```hcl
high_availability_mode = "ZoneRedundant"
standby_availability_zone = "2"
```

### Failover

Automatic failover is handled by Azure. Manual failover:

```bash
az postgres flexible-server restart \
  --resource-group <rg> \
  --name <server-name> \
  --failover
```

## Monitoring

### Diagnostic Settings

Automatically configured to send logs to Log Analytics:

```hcl
log_analytics_workspace_id = module.openai.log_analytics_workspace_id
```

### Key Metrics

Monitor these metrics:
- CPU percentage
- Memory percentage
- Storage percentage
- Active connections
- Failed connections
- Network I/O

### Query Logs

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DBFORPOSTGRESQL"
| where Category == "PostgreSQLLogs"
| project TimeGenerated, Message
| order by TimeGenerated desc
```

## Maintenance

### Maintenance Window

Configure in variables:

```hcl
maintenance_day  = 0  # Sunday
maintenance_hour = 2  # 2 AM
```

### Server Configurations

Customize PostgreSQL parameters:

```hcl
server_configurations = {
  "shared_preload_libraries" = "pg_stat_statements,pg_cron"
  "log_statement"            = "all"
  "log_min_duration_statement" = "1000"
  "max_connections"           = "100"
}
```

## Security Best Practices

1. **Use Private Endpoints**: Always for production
2. **Enable AAD Authentication**: For managed identity access
3. **Restrict Network Access**: Use firewall rules
4. **Rotate Passwords**: Regularly update admin password
5. **Enable SSL/TLS**: Enforced by default
6. **Use Key Vault**: Store credentials in Key Vault
7. **Audit Logging**: Enable diagnostic logging
8. **Least Privilege**: Grant minimum required permissions

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to database

**Solutions**:
1. Verify private endpoint is configured
2. Check firewall rules
3. Verify subnet configuration
4. Check DNS resolution

```bash
# Test connectivity
psql -h <server-fqdn> -U <username> -d <database>
```

### Performance Issues

**Problem**: Slow queries or high CPU

**Solutions**:
1. Check query performance: `EXPLAIN ANALYZE`
2. Review slow query logs
3. Consider scaling up SKU
4. Optimize indexes
5. Review connection pooling

### Backup Issues

**Problem**: Backup not available

**Solutions**:
1. Verify backup retention period
2. Check geo-redundant backup status
3. Review backup storage quota

## Cost Optimization

### Right-Sizing

- Start with smaller SKU and scale up as needed
- Use Burstable for dev/test
- Monitor metrics before scaling

### Storage Optimization

- Enable storage autogrow
- Regular cleanup of old data
- Archive old data to cheaper storage

### Backup Optimization

- Adjust retention based on requirements
- Use geo-redundant only for production
- Consider manual backups for long-term retention

## Cost Estimates

### Development (B_Standard_B1ms)
- Compute: ~$15/month
- Storage: ~$0.12/GB/month
- **Total**: ~$20/month

### Production (GP_Standard_D4s_v3)
- Compute: ~$400/month
- Storage: ~$0.12/GB/month
- Backup: ~$0.20/GB/month
- **Total**: ~$500-600/month

## Migration from Other Databases

### From AWS RDS

1. Export data from RDS
2. Import to Azure PostgreSQL
3. Update connection strings
4. Test and validate

### From On-Premises

1. Use Azure Database Migration Service
2. Or use `pg_dump` and `pg_restore`
3. Configure networking
4. Update applications

## Additional Resources

- [Azure Database for PostgreSQL Documentation](https://docs.microsoft.com/azure/postgresql/)
- [PostgreSQL Best Practices](https://www.postgresql.org/docs/current/admin.html)
- [Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html)
- [Performance Tuning](https://docs.microsoft.com/azure/postgresql/flexible-server/concepts-performance)

---

**Last Updated**: 2024  
**Version**: 1.0

