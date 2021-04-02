
output "vm_ids" {
  description = "Virtual machine ids created."
  value       = azurerm_linux_virtual_machine.nodes.*.id
}

output "network_security_group_id" {
  description = "id of the security group provisioned"
  value       = azurerm_network_security_group.node.id
}

output "network_security_group_name" {
  description = "name of the security group provisioned"
  value       = azurerm_network_security_group.node.name
}

output "network_interface_ids" {
  description = "ids of the vm nics provisoned."
  value       = azurerm_network_interface.nodes.*.id
}

output "network_interface_private_ip" {
  description = "private ip addresses of the vm nics"
  value       = azurerm_network_interface.nodes.*.private_ip_address
}

output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = azurerm_public_ip.nodes.*.ip_address
}
/*
*/