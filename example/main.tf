module "az-microk8s" {
    //source = "git::https://github.com/balchua/az-microk8s"
    source = "../"
    region = "southeastasia"
    cluster_name = "hades"
    host_cidr = "10.0.0.0/16" 
    node_type = "Standard_A1_v2"
    node_count = "3"
    microk8s_channel = "latest/edge"
    cluster_token_ttl_seconds = 3600    
}