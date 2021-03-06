resource "azurerm_resource_group" "cluster" {
    name     = var.cluster_name
    location = var.region
}

# Virtual Network
resource "azurerm_virtual_network" "network" {
    resource_group_name = azurerm_resource_group.cluster.name
    name                = var.cluster_name
    address_space       = [var.host_cidr]
    location            = azurerm_resource_group.cluster.location

}

# Subnet for control plane
resource "azurerm_subnet" "node" {
    resource_group_name    = azurerm_resource_group.cluster.name
    name                   = var.cluster_name
    virtual_network_name   = azurerm_virtual_network.network.name
    address_prefixes       = [cidrsubnet(var.host_cidr, 1, 1)]
}

resource "azurerm_subnet_network_security_group_association" "node" {
  subnet_id                 = azurerm_subnet.node.id
  network_security_group_id = azurerm_network_security_group.node.id
}