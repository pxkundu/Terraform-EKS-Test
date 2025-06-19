// RDS module using the official community module
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.db_identifier
  engine     = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  name     = var.db_name
  username = var.db_username
  password = var.db_password
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  skip_final_snapshot    = true
  publicly_accessible    = false
  tags = var.tags
} 