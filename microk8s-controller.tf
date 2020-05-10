# Controller public IPv4 addresses
resource "azurerm_public_ip" "controllers" {
    resource_group_name = azurerm_resource_group.cluster.name

    name                = "microk8s-${var.cluster_name}-controller"
    location            = azurerm_resource_group.cluster.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

# Controller NICs with public and private IPv4
resource "azurerm_network_interface" "controllers" {
    resource_group_name = azurerm_resource_group.cluster.name

    name     = "microk8s-${var.cluster_name}-controller"
    location = azurerm_resource_group.cluster.location

    ip_configuration {
      name                          = "ip0"
      subnet_id                     = azurerm_subnet.controller.id
      private_ip_address_allocation = "Dynamic"
      # instance public IPv4
      public_ip_address_id = azurerm_public_ip.controllers.id
    }
}

# Associate controller network interface with controller security group
resource "azurerm_network_interface_security_group_association" "controllers" {
    network_interface_id      = azurerm_network_interface.controllers.id
    network_security_group_id = azurerm_network_security_group.controller.id
}

# Control plane VM
# Controller instances
resource "azurerm_linux_virtual_machine" "controllers" {
    resource_group_name = azurerm_resource_group.cluster.name
    depends_on          = [azurerm_network_interface_security_group_association.controllers]
    name                = "microk8s-${var.cluster_name}-controller"
    location            = var.region
    
    size                = var.controller_type
    custom_data         = base64encode(data.template_file.controller_config.rendered)

    # storage
    os_disk {
      name                 = "microk8s-${var.cluster_name}-controller"
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
      azurerm_network_interface.controllers.id
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
data "template_file" "controller_config" {
    template = file("${path.module}/templates/master.yaml.tmpl")
    vars = {
      microk8s_channel = "${var.microk8s_channel}"
    }
}

resource "null_resource" "set_controller_sudo" {
    count           = "${var.worker_count}"
    depends_on      = [azurerm_linux_virtual_machine.controllers]

    connection {
      type    = "ssh"
      host    = azurerm_public_ip.controllers.ip_address
      user    = "ubuntu"
      timeout = "15m"
    }         

    provisioner "remote-exec" {
        inline = [
            "sudo usermod -a -G microk8s ubuntu",          
        ]
    }
}

resource "null_resource" "setup_tokens" {
    depends_on = [null_resource.set_controller_sudo]
    connection {
      type    = "ssh"
      host    = azurerm_public_ip.controllers.ip_address
      user    = "ubuntu"
      timeout = "15m"
    }  
    

    provisioner "remote-exec" {
        inline = [
            "mkdir -p /tmp/config",
            "until /snap/bin/microk8s.status --wait-ready; do sleep 1; echo \"waiting for status..\"; done",
            "/snap/bin/microk8s.kubectl label node ${azurerm_linux_virtual_machine.controllers.name} node-role.kubernetes.io/master=master",            
            "/snap/bin/microk8s.add-node --token \"${var.cluster_token}\" --token-ttl ${var.cluster_token_ttl_seconds}",
            "/snap/bin/microk8s.kubectl config view --raw > /tmp/config/client.config",
            "/snap/microk8s/current/bin/sed -i 's/127.0.0.1/${azurerm_public_ip.controllers.ip_address}/g' /tmp/config/client.config",
            "/snap/microk8s/current/bin/sed -i 's/#MOREIPS/IP.99 = ${azurerm_public_ip.controllers.ip_address}\\n#MOREIPS/g' /var/snap/microk8s/current/certs/csr.conf.template",
            "/snap/bin/microk8s.kubectl cordon microk8s-${var.cluster_name}-controller",
        ]
    }
}

resource "null_resource" "get_kubeconfig" {
    depends_on = [null_resource.setup_tokens]    

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_public_key}  ubuntu@${azurerm_public_ip.controllers.ip_address}:/tmp/config/client.config /tmp/"
    }
}