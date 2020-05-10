# Controller public IPv4 addresses
resource "azurerm_public_ip" "workers" {
    resource_group_name = azurerm_resource_group.cluster.name
    count               = var.worker_count
    name                = "microk8s-${var.cluster_name}-worker-${count.index}"
    location            = azurerm_resource_group.cluster.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

# Controller NICs with public and private IPv4
resource "azurerm_network_interface" "workers" {
    count               = var.worker_count
    resource_group_name = azurerm_resource_group.cluster.name

    name     = "microk8s-${var.cluster_name}-workers-${count.index}"
    location = azurerm_resource_group.cluster.location

    ip_configuration {
        name                          = "ip0"
        subnet_id                     = azurerm_subnet.worker.id
        private_ip_address_allocation = "Dynamic"
        # instance public IPv4
        public_ip_address_id = azurerm_public_ip.workers.*.id[count.index]
    }
}

# Associate controller network interface with controller security group
resource "azurerm_network_interface_security_group_association" "workers" {
    count                     = var.worker_count
    network_interface_id      = azurerm_network_interface.workers[count.index].id
    network_security_group_id = azurerm_network_security_group.worker.id
}

# Control plane VM
# Controller instances
resource "azurerm_linux_virtual_machine" "workers" {
    resource_group_name = azurerm_resource_group.cluster.name
    count               = var.worker_count
    depends_on          = [azurerm_network_interface_security_group_association.workers]
    name                = "microk8s-${var.cluster_name}-worker-${count.index}"
    location            = var.region
    
    size                = var.worker_type
    custom_data         = base64encode(data.template_file.worker_config.rendered)
    # storage
    os_disk {
        name                 = "microk8s-${var.cluster_name}-worker-${count.index}"
        caching              = "None"
        storage_account_type = "Premium_LRS"
    }

    
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    # network
    network_interface_ids = [
        azurerm_network_interface.workers.*.id[count.index]
    ]

    # Azure requires setting admin_ssh_key, though Ignition custom_data handles it too
    admin_username = "ubuntu"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "ubuntu"
        public_key     = file(pathexpand("${var.ssh_public_key}"))
    }

    lifecycle {
        ignore_changes = [
        os_disk,
        custom_data,
        ]
    }
}

# controller node user-config
data "template_file" "worker_config" {
  template = file("${path.module}/templates/worker.yaml.tmpl")
  vars = {
    microk8s_channel = "${var.microk8s_channel}"
    controller_private_ip_address = "${azurerm_linux_virtual_machine.controllers.private_ip_address}"
    cluster_token = "${var.cluster_token}"
  }
}

resource "null_resource" "set_worker_sudo" {
    count           = "${var.worker_count}"
    depends_on      = [azurerm_linux_virtual_machine.workers, null_resource.setup_tokens]

    connection {
      type    = "ssh"
      host    = azurerm_public_ip.workers.*.ip_address[count.index]
      user    = "ubuntu"
      timeout = "15m"
    }         

    provisioner "remote-exec" {
        inline = [
            "sudo usermod -a -G microk8s ubuntu",         
        ]
    }
}


resource "null_resource" "join_nodes" {
    count           = "${var.worker_count}"
    depends_on      = [null_resource.set_worker_sudo]

    connection {
      type    = "ssh"
      host    = azurerm_public_ip.workers.*.ip_address[count.index]
      user    = "ubuntu"
      timeout = "15m"
    }         

    provisioner "remote-exec" {
        inline = [           
            "until /snap/bin/microk8s.status --wait-ready; do sleep 1; echo \"waiting for worker status..\"; done",
            "/snap/bin/microk8s.join ${azurerm_linux_virtual_machine.controllers.private_ip_address}:25000/${var.cluster_token}",
        ]
    }
}