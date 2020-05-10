# Controller security group

resource "azurerm_network_security_group" "controller" {
  resource_group_name = azurerm_resource_group.cluster.name

  name     = "${var.cluster_name}-controller"
  location = azurerm_resource_group.cluster.location
}

resource "azurerm_network_security_rule" "controller-ssh" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-ssh"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2000"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.controller.address_prefix
}

resource "azurerm_network_security_rule" "controller-http" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-http"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2005"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.controller.address_prefix
}

resource "azurerm_network_security_rule" "controller-https" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-https"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2010"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.controller.address_prefix
}

resource "azurerm_network_security_rule" "controller-etcd" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-etcd"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2015"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "12379"
  source_address_prefix       = azurerm_subnet.controller.address_prefix
  destination_address_prefix  = azurerm_subnet.controller.address_prefix
}


resource "azurerm_network_security_rule" "controller-kube-metrics" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-kube-metrics"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2020"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "10259"
  source_address_prefix       = azurerm_subnet.worker.address_prefix
  destination_address_prefix  = azurerm_subnet.controller.address_prefix
}

resource "azurerm_network_security_rule" "controller-apiserver" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-apiserver"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2025"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "16443"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.controller.address_prefix
}

# Allow apiserver to access kubelet's for exec, log, port-forward
resource "azurerm_network_security_rule" "controller-kubelet" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-kubelet"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2030"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "10250"
  source_address_prefixes    = [azurerm_subnet.controller.address_prefix, azurerm_subnet.worker.address_prefix]
  destination_address_prefix = azurerm_subnet.controller.address_prefix
}

resource "azurerm_network_security_rule" "controller-cluster-agent" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-clusteragent"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "2040"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25000"
  source_address_prefixes       = [azurerm_subnet.controller.address_prefix, azurerm_subnet.worker.address_prefix]
  destination_address_prefix  = "*"
}

# Override Azure AllowVNetInBound and AllowAzureLoadBalancerInBound
# https://docs.microsoft.com/en-us/azure/virtual-network/security-overview#default-security-rules

resource "azurerm_network_security_rule" "controller-allow-loadblancer" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-loadbalancer"
  network_security_group_name = azurerm_network_security_group.controller.name
  priority                    = "3000"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
}

# Worker security group

resource "azurerm_network_security_group" "worker" {
  resource_group_name = azurerm_resource_group.cluster.name

  name     = "${var.cluster_name}-worker"
  location = azurerm_resource_group.cluster.location
}

resource "azurerm_network_security_rule" "worker-ssh" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-ssh"
  network_security_group_name = azurerm_network_security_group.worker.name
  priority                    = "2000"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.worker.address_prefix
}

resource "azurerm_network_security_rule" "worker-http" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-http"
  network_security_group_name = azurerm_network_security_group.worker.name
  priority                    = "2005"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.worker.address_prefix
}

resource "azurerm_network_security_rule" "worker-https" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-https"
  network_security_group_name = azurerm_network_security_group.worker.name
  priority                    = "2010"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_subnet.worker.address_prefix
}


# Allow apiserver to access kubelet's for exec, log, port-forward
resource "azurerm_network_security_rule" "worker-kubelet" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-kubelet"
  network_security_group_name = azurerm_network_security_group.worker.name
  priority                    = "2025"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "10250"

  # allow Prometheus to scrape kubelet metrics too
  source_address_prefixes    = [azurerm_subnet.controller.address_prefix, azurerm_subnet.worker.address_prefix]
  destination_address_prefix = azurerm_subnet.worker.address_prefix
}

resource "azurerm_network_security_rule" "worker-cluster-agent" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-clusteragent"
  network_security_group_name = azurerm_network_security_group.worker.name
  priority                    = "2040"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25000"
  source_address_prefixes       = [azurerm_subnet.controller.address_prefix, azurerm_subnet.worker.address_prefix]
  destination_address_prefix  = "*"
}

# Override Azure AllowVNetInBound and AllowAzureLoadBalancerInBound
# https://docs.microsoft.com/en-us/azure/virtual-network/security-overview#default-security-rules

resource "azurerm_network_security_rule" "worker-allow-loadblancer" {
  resource_group_name = azurerm_resource_group.cluster.name

  name                        = "allow-loadbalancer"
  network_security_group_name = azurerm_network_security_group.worker.name
  priority                    = "3000"
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
}
