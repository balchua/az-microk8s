variable "region" {
    type        = string
    description = "The Azure region to use." 
    default     = "southeastasia"
}

variable "cluster_name" {
    type        = string
    description = "The name of the MicroK8s cluster."
    default     = "cetacean"
}

variable "host_cidr" {
  type        = string
  description = "CIDR IPv4 range to assign to instances"
  default     = "10.0.0.0/16"
}

variable "node_type" {
    type        = string
    description = "The VM size type for the MicroK8s node."
    default     = "Standard_DS2_v2"
}

variable "node_count" {
    type        = number
    description = "The number of MicroK8s nodes."
    default     = "3"
}

variable "microk8s_channel" {
    type        = string
    description = "The MicroK8s channel / version to use"
    default     = "edge"
}

variable "cluster_token_ttl_seconds" {
    type        = number
    default     = 3600
    description = "The cluster token ttl to use when joining a node, default 3600 seconds."
}

variable "cluster_token" {
    type        = string
    description = "The cluster token to use to join a node.  Must be 32 alphanumeric long." 
    default     = "qwertyuiopasdfghjklzxcvbnm1234567"
}

variable "ssh_public_key" {
    type        = string
    description = "Your public key location. usually located in ~/.ssh/id_rsa.pub"
    default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
    type        = string
    description = "Your private key location. usually located in ~/.ssh/id_rsa"
    default     = "~/.ssh/id_rsa"
}
