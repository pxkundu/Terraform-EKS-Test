output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = azurerm_subnet.private[*].id
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = azurerm_subnet.public[*].name
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = azurerm_subnet.private[*].name
}

output "public_nsg_id" {
  description = "ID of the public Network Security Group"
  value       = azurerm_network_security_group.public.id
}

output "private_nsg_id" {
  description = "ID of the private Network Security Group"
  value       = azurerm_network_security_group.private.id
}

