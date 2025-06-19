# RDS Module

This module provisions an Amazon RDS instance using the official terraform-aws-modules/rds/aws module.

## Features
- Creates a managed RDS database instance
- Supports engine, version, instance class, and subnet group configuration
- Secure by default (not publicly accessible, skips final snapshot for demo)

## Usage
```hcl
module "rds" {
  source = "./modules/rds"
  db_identifier         = var.db_identifier
  db_engine             = var.db_engine
  db_engine_version     = var.db_engine_version
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  tags                  = var.tags
}
```

## Variables
- `db_identifier` (string): RDS instance identifier
- `db_engine` (string): Database engine (e.g., postgres, mysql)
- `db_engine_version` (string): Engine version
- `db_instance_class` (string): Instance class
- `db_allocated_storage` (number): Storage size (GB)
- `db_name` (string): Database name
- `db_username` (string): Master username
- `db_password` (string): Master password
- `vpc_security_group_ids` (list(string)): Security group IDs
- `db_subnet_group_name` (string): Subnet group name
- `tags` (map(string)): Resource tags

## Outputs
- `db_instance_endpoint`: RDS endpoint
- `db_instance_identifier`: RDS instance identifier

## Best Practices
- Use secrets management for passwords
- Restrict security groups to application subnets only 