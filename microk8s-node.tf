resource "random_id" "cluster_token" {
  byte_length = 16
}

# Controller public IPv4 addresses
resource "azurerm_public_ip" "nodes" {
    resource_group_name = azurerm_resource_group.cluster.name
    count               = var.node_count
    name                = "microk8s-${var.cluster_name}-node-${count.index}"
    location            = azurerm_resource_group.cluster.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

# Controller NICs with public and private IPv4
resource "azurerm_network_interface" "nodes" {
    count               = var.node_count
    resource_group_name = azurerm_resource_group.cluster.name

    name     = "microk8s-${var.cluster_name}-node-${count.index}"
    location = azurerm_resource_group.cluster.location

    ip_configuration {
        name                          = "ip0"
        subnet_id                     = azurerm_subnet.node.id
        private_ip_address_allocation = "Dynamic"
        # instance public IPv4
        public_ip_address_id = azurerm_public_ip.nodes.*.id[count.index]
    }
}

# Associate microk8s node network interface with security group
resource "azurerm_network_interface_security_group_association" "nodes" {
    count                     = var.node_count
    network_interface_id      = azurerm_network_interface.nodes[count.index].id
    network_security_group_id = azurerm_network_security_group.node.id
}

# Node instances
resource "azurerm_linux_virtual_machine" "nodes" {
    resource_group_name = azurerm_resource_group.cluster.name
    count               = var.node_count
    depends_on          = [azurerm_network_interface_security_group_association.nodes]
    name                = "microk8s-${var.cluster_name}-node-${count.index}"
    location            = azurerm_resource_group.cluster.location
    
    size                = var.node_type
    custom_data         = base64encode(data.template_file.node_config.rendered)

    tags = {
      environment = "microk8s-cluster"
    }
    # storage
    os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }
    
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "latest"
    }

    # network
    network_interface_ids = [
        element(azurerm_network_interface.nodes.*.id, count.index)
    ]

    # Azure requires setting admin_ssh_key, though Ignition custom_data handles it too
    admin_username = "ubuntu"
    disable_password_authentication = true


    admin_ssh_key {
        username       = "ubuntu"
        public_key     = file(pathexpand(var.ssh_public_key))
    }
}

# microk8s node user-config
data "template_file" "node_config" {
  template = file("${path.module}/templates/node.yaml.tmpl")
  vars = {
    microk8s_channel = var.microk8s_channel
  }
}

resource "null_resource" "set_node_sudo" {
    count           = var.node_count
    depends_on      = [azurerm_linux_virtual_machine.nodes]
    triggers = {
      rerun = random_id.cluster_token.hex
    }
    connection {
      type    = "ssh"
      host    = azurerm_public_ip.nodes.*.ip_address[count.index]
      user    = "ubuntu"
      timeout = "15m"
    }         

    provisioner "remote-exec" {
        inline = [
            "sudo usermod -a -G microk8s ubuntu",         
        ]
    }
}

# setup_token must be done only on the main node.
# Then prepare for the join nodes by creating the sequence token in /tmp/current_joining_node.txt
resource "null_resource" "setup_tokens" {
    depends_on = [null_resource.set_node_sudo]
    triggers = {
      rerun = random_id.cluster_token.hex
    }
    connection {
      type    = "ssh"
      host    = azurerm_public_ip.nodes[0].ip_address
      user    = "ubuntu"
      timeout = "15m"
    }  

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "echo \"1\" > /tmp/current_joining_node.txt"
    }

    provisioner "file" {
        content     = templatefile("${path.module}/templates/add-node.sh", 
            {
                main_node = azurerm_public_ip.nodes[0].ip_address
                cluster_token = random_id.cluster_token.hex
                cluster_token_ttl_seconds = var.cluster_token_ttl_seconds
            })
        destination = "/tmp/add-node.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sh /tmp/add-node.sh",
        ]
    }
}

# Joining nodes must be done in sequence.  
# The first and last provisioners is to make sure that joining nodes is not done in parallel.
resource "null_resource" "join_nodes" {
    count           = var.node_count - 1 < 1 ? 0 : var.node_count - 1
    depends_on      = [null_resource.set_node_sudo, null_resource.setup_tokens]
    triggers = {
      rerun = random_id.cluster_token.hex
    }
    connection {
      type    = "ssh"
      host    = element(azurerm_public_ip.nodes.*.ip_address, count.index + 1)
      user    = "ubuntu"
      timeout = "15m"
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "while [[ $(cat /tmp/current_joining_node.txt) != \"${count.index +1}\" ]]; do echo \"${count.index +1} is waiting...\";sleep 5;done"
    }

    provisioner "file" {
        content     = templatefile("${path.module}/templates/join.sh", 
            {
                cluster_token = random_id.cluster_token.hex
                main_node = azurerm_linux_virtual_machine.nodes[0].private_ip_address
            })
        destination = "/tmp/join.sh"
    }    

    provisioner "remote-exec" {
        inline = [   
            "sh /tmp/join.sh",        
        ]
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "echo \"${count.index+2}\" > /tmp/current_joining_node.txt"
    }
}



resource "null_resource" "get_kubeconfig" {
    depends_on = [null_resource.setup_tokens]    

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_public_key}  ubuntu@${azurerm_public_ip.nodes[0].ip_address}:/tmp/config/client.config /tmp/"
    }
}