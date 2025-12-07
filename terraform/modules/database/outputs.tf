output "server_id" {
  description = "ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "database_id" {
  description = "ID of the database"
  value       = azurerm_postgresql_flexible_server_database.main.id
}

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
  sensitive   = true
}

output "administrator_login" {
  description = "Database administrator username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "administrator_password" {
  description = "Database administrator password"
  value       = var.db_password != null ? var.db_password : random_password.db_password[0].result
  sensitive   = true
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (if created)"
  value       = var.subnet_id != null ? azurerm_private_endpoint.postgres[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the endpoint (if created)"
  value       = var.subnet_id != null ? azurerm_private_endpoint.postgres[0].private_ip_address : null
}

